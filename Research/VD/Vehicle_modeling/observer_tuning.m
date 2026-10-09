clc
close all
clear
% observer tuning - grid search of the normal force observer filters and gain (fcObsModel, fcObsGage, K, tau)
% same load model and observer as vehicle_model.m (dual track, per tire), run on the whole log
% no true Fz is logged, the reference is the raw strain gage low passed forward and backward (zero phase),
% so it is smooth and has no delay, which is what the causal observer should get close to
% scores per setting, averaged over the four tires and both logs (moving samples, v > 10 m/s):
%   err    std of (observer - reference), lag and noise both raise it (the mean offset of the gage is removed)
%   hf     rms of the observer above 5 Hz, smoothness
%   lag    delay behind the reference in the 0.3 - 3 Hz body motion band (cross correlation)

%% settings

logFiles = ["/home/elijah/PurdueRacing/bags/lagoona/comp2/compition_bags/2026-09-03_121638_merged.csv", ...
            "/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv"];
here      = fileparts(mfilename("fullpath"));
cacheFile = fullfile(here, "observer_tuning_data.mat");
paramFile = fullfile(here, "tire_fit_data_2026.mat");   % vehicleParams saved by vehicle_model.m

fcGrid   = [1.3 2 3 5 8];            % (Hz) fcObsModel
fgGrid   = [0.5 1 1.5 2 3 5];        % (Hz) fcObsGage
KGrid    = [0.5 1 1.5 2 3 4];        % gain on (gage rate - model rate)
tauGrid  = [0.5 1 2 4 8];            % (s) correction decay
fcRef    = 4;                        % (Hz) zero phase reference cutoff
fcHf     = 5;                        % (Hz) smoothness band starts here
hfWeight = 1;                        % score = err + hfWeight * hf

current = [3 1 2 1];                 % vehicle_model.m now: [fcObsModel fcObsGage K tau]
old     = [1.3 1.3 1 1];             % before the observer filters were split

g = 9.81;

%% load the channels (cached after the first run)

if isfile(cacheFile)
    S = load(cacheFile).S;
else
    ch = ["time_s", "odom_vx_mps", "odom_vy_mps", "odom_wz_rads", "a_x", "odom_qw", "odom_qx", "odom_qy", "odom_qz", ...
          "fl_load_n", "fr_load_n", "rl_load_n", "rr_load_n"];
    S = struct([]);
    for k = 1:numel(logFiles)
        o = detectImportOptions(logFiles(k));
        o.SelectedVariableNames = ch;
        T = readtable(logFiles(k), o);
        S(k).t    = T.time_s - T.time_s(1);
        S(k).vx   = T.odom_vx_mps;
        S(k).vy   = T.odom_vy_mps;
        S(k).wz   = T.odom_wz_rads;
        S(k).ax   = T.a_x;
        S(k).q    = [T.odom_qw, T.odom_qx, T.odom_qy, T.odom_qz];
        S(k).gage = [T.fl_load_n, T.fr_load_n, T.rl_load_n, T.rr_load_n];
        fprintf("loaded %s (%d samples)\n", logFiles(k), height(T));
    end
    save(cacheFile, "S");
end
vp = load(paramFile, "vehicleParams").vehicleParams;

%% grid search

[A, B, C, Dg] = ndgrid(fcGrid, fgGrid, KGrid, tauGrid);
cfg = [A(:), B(:), C(:), Dg(:)];
cfg = unique([cfg; current; old], "rows", "stable");
nC  = size(cfg, 1);

err = zeros(nC, numel(S)); hf = err; lag = err;
for k = 1:numel(S)
    Ts   = median(diff(S(k).t));
    fs   = 1 / Ts;
    mov  = fillmissing(S(k).vx, "nearest") > 10;
    gage = fillmissing(S(k).gage, "nearest");

    [bR, aR] = butter(2, fcRef / (fs/2));
    ref      = filtfilt(bR, aR, gage);                    % zero phase reference
    [bH, aH] = butter(2, fcHf / (fs/2), "high");
    [bL, aL] = butter(2, [0.3 3] / (fs/2), "bandpass");
    refBand  = filter(bL, aL, ref - mean(ref));           % same causal band filter on both, so it adds no relative lag

    models = cell(numel(fcGrid), 1);                      % load model per fcObsModel
    for i = 1:numel(fcGrid)
        models{i} = loadModel(S(k), fcGrid(i), Ts, vp, g);
    end
    gages = cell(numel(fgGrid), 1);                       % gage per fcObsGage
    for j = 1:numel(fgGrid)
        gages{j} = lpf(gage, fgGrid(j), Ts);
    end

    for c = 1:nC
        [inM, iM] = ismember(cfg(c,1), fcGrid);
        [inG, iG] = ismember(cfg(c,2), fgGrid);
        if inM, mdl = models{iM}; else, mdl = loadModel(S(k), cfg(c,1), Ts, vp, g); end
        if inG, gf  = gages{iG};  else, gf  = lpf(gage, cfg(c,2), Ts); end

        obs = observer(mdl, lpf(mdl, cfg(c,2), Ts), gf, cfg(c,3), cfg(c,4), Ts);

        e  = obs(mov,:) - ref(mov,:);
        h  = filtfilt(bH, aH, obs);
        ob = filter(bL, aL, obs - mean(obs));
        lg = zeros(1, 4);
        for i = 1:4
            [xc, l] = xcorr(ob(mov,i), refBand(mov,i), round(0.3 * fs), "coeff");
            [~, m]  = max(xc);
            lg(i)   = l(m) * Ts * 1000;
        end
        err(c,k) = mean(std(e));
        hf(c,k)  = mean(rms(h(mov,:)));
        lag(c,k) = mean(lg);
    end
    fprintf("log %d done\n", k);
end

E = mean(err, 2); H = mean(hf, 2); Lg = mean(lag, 2);
score = E + hfWeight * H;
[~, order] = sort(score);

%% results

row = @(c) fprintf("%7.1f %7.1f %5.1f %5.1f | %7.0f %7.0f %7.0f %7.0f\n", cfg(c,:), E(c), H(c), Lg(c), score(c));
fprintf("\n%7s %7s %5s %5s | %7s %7s %7s %7s\n", "fcModel", "fcGage", "K", "tau", "err [N]", "hf [N]", "lag[ms]", "score");
fprintf("best 10\n");
for c = order(1:10)', row(c); end
fprintf("current vehicle_model.m\n"); row(find(ismember(cfg, current, "rows"), 1));
fprintf("old (all 1.3 Hz, K 1)\n");   row(find(ismember(cfg, old, "rows"), 1));

% best per K, to see what a high gain buys
fprintf("best per K\n");
for Kv = KGrid
    idx = find(cfg(:,3) == Kv);
    [~, m] = min(score(idx));
    row(idx(m));
end

%% plots

fig = figure("Name", "Observer tuning", "Position", [50 50 1400 800]);
tl  = tiledlayout(fig, 2, 2, "TileSpacing", "compact");

nexttile(tl);
scatter(H, E, 12, cfg(:,3), "filled");
hold on
plot(H(order(1)), E(order(1)), "rp", "MarkerSize", 14, "MarkerFaceColor", "r");
c0 = find(ismember(cfg, current, "rows"), 1);
c1 = find(ismember(cfg, old, "rows"), 1);
plot(H(c0), E(c0), "ks", "MarkerSize", 10, "LineWidth", 1.5);
plot(H(c1), E(c1), "kd", "MarkerSize", 10, "LineWidth", 1.5);
cb = colorbar; cb.Label.String = "K";
grid on
xlabel("hf: rms above 5 Hz [N]");
ylabel("err: std of observer - zero phase gage [N]");
title("Every setting, lower left is better");
legend("settings", "best score", "current", "old", "Location", "northeast");

nexttile(tl);
scatter(Lg, E, 12, cfg(:,3), "filled");
hold on
plot(Lg(order(1)), E(order(1)), "rp", "MarkerSize", 14, "MarkerFaceColor", "r");
plot(Lg(c0), E(c0), "ks", "MarkerSize", 10, "LineWidth", 1.5);
plot(Lg(c1), E(c1), "kd", "MarkerSize", 10, "LineWidth", 1.5);
cb = colorbar; cb.Label.String = "K";
grid on
xlabel("lag behind the zero phase gage, 0.3 - 3 Hz [ms]");
ylabel("err [N]");
title("Delay vs error");

% score vs K and fcObsGage at the best fcObsModel and tau
nexttile(tl);
hold on
bb = cfg(order(1),:);
for fg = fgGrid
    idx = cfg(:,1) == bb(1) & cfg(:,2) == fg & cfg(:,4) == bb(4);
    plot(cfg(idx,3), score(idx), "-o", "LineWidth", 1.2);
end
grid on
xlabel("K");
ylabel("score = err + hf [N]");
title(sprintf("Score vs K, fcObsModel %.1f Hz, tau %.1f s", bb(1), bb(4)));
legend(compose("fcObsGage %.1f Hz", fgGrid), "Location", "best");

% time trace, best vs current vs old, one tire on the 2026 log
nexttile(tl);
k = 1; i = 2;   % 2026, FR
Ts = median(diff(S(k).t));
gage = fillmissing(S(k).gage, "nearest");
[bR, aR] = butter(2, fcRef / (0.5 / Ts));
ref = filtfilt(bR, aR, gage);
win = S(k).t >= 1168 & S(k).t <= 1256;   % fastest lap
hold on
plot(S(k).t(win), gage(win,i) - median(gage(win,i) - ref(win,i)), "Color", [0.8 0.8 0.8]);
plot(S(k).t(win), ref(win,i), "k-", "LineWidth", 1.2);
sets = [cfg(c1,:); cfg(c0,:); cfg(order(1),:)];
cols = [0.47 0.67 0.19; 0.00 0.45 0.74; 0.85 0.10 0.10];
for j = 1:3
    mdl = loadModel(S(k), sets(j,1), Ts, vp, g);
    obs = observer(mdl, lpf(mdl, sets(j,2), Ts), lpf(gage, sets(j,2), Ts), sets(j,3), sets(j,4), Ts);
    off = median(obs(win,i) - ref(win,i));
    plot(S(k).t(win), obs(win,i) - off, "Color", cols(j,:), "LineWidth", 1.1);
end
grid on
xlabel("time [s], 2026 log fastest lap");
ylabel("F_z FR [N]");
title("FR, observer vs zero phase gage (offsets removed)");
legend("raw gage", sprintf("zero phase gage %.0f Hz (reference)", fcRef), ...
    sprintf("old: fcModel %.1f, fcGage %.1f, K %.1f, tau %.1f", cfg(c1,:)), sprintf("current: fcModel %.1f, fcGage %.1f, K %.1f, tau %.1f", cfg(c0,:)), ...
    sprintf("best: fcModel %.1f, fcGage %.1f, K %.1f, tau %.1f", cfg(order(1),:)), "Location", "best");


function Fz = loadModel(s, fcM, Ts, vp, g)
% dual track load model, same equations as vehicle_model.m (normal forces bicycle + dual track), inputs at fcM

    vx = lpf(fillmissing(s.vx, "nearest"), fcM, Ts);
    vy = lpf(fillmissing(s.vy, "nearest"), fcM, Ts);
    wz = lpf(fillmissing(s.wz, "nearest"), fcM, Ts);
    ax = lpf(fillmissing(s.ax, "nearest"), fcM, Ts);
    eu = quat2eul(lpf(fillmissing(s.q, "nearest"), fcM, Ts), "ZYX");
    pitch = -eu(:,2);
    roll  =  eu(:,3);

    m = vp.m; L = vp.wheelbase; lf = (1 - vp.w_dist_f) * L; lr = vp.w_dist_f * L; h = vp.cg_z;
    ft = vp.t_f; rt = vp.t_r;

    ay = vx .* wz + [0; diff(vy)] / Ts + g .* cos(pitch) .* sin(roll);
    axl = ax + g .* sin(pitch);
    az  = g .* cos(pitch) .* cos(roll) - vx .* wz .* sin(roll);
    df  = 0.5 .* vp.rho .* vp.ClA .* vx.^2;

    Fz_f = m .* az .* lr ./ L - m .* axl .* h ./ L +      vp.aeroBal_f  .* df;
    Fz_r = m .* az .* lf ./ L + m .* axl .* h ./ L + (1 - vp.aeroBal_f) .* df;

    k_f = vp.wheelRate_f * ft^2 / 2 + vp.ARB_f;
    k_r = vp.wheelRate_r * rt^2 / 2 + vp.ARB_r;
    sh  = k_f / (k_f + k_r);
    hr  = h - (vp.rc_f + (vp.rc_r - vp.rc_f) * lf / L);
    lt_f = m .* ay ./ ft .* (hr *      sh  + lr * vp.rc_f / L);
    lt_r = m .* ay ./ rt .* (hr * (1 - sh) + lf * vp.rc_r / L);

    cl = vp.staticCornerLoad;
    Fz = [Fz_f .* cl(1) / (cl(1) + cl(2)) - lt_f, Fz_f .* cl(2) / (cl(1) + cl(2)) + lt_f, ...
          Fz_r .* cl(3) / (cl(3) + cl(4)) - lt_r, Fz_r .* cl(4) / (cl(3) + cl(4)) + lt_r];
end


function obs = observer(mdl, cmp, gage, K, tau, Ts)
% fzDerivativeObserver of vehicle_model.m, constant sample time: c(k) = a (c(k-1) + K rate error(k))

    a  = tau / (tau + Ts);
    re = [zeros(1, size(gage, 2)); diff(gage) - diff(cmp)];
    c  = filter(a * K, [1 -a], re);
    obs = mdl + c;
end


function y = lpf(x, fc, Ts)
% first order Tustin low pass, same as vehicle_model.m, starts settled at the first sample

    Kt = tan(pi * fc * Ts);
    a1 = (1 - Kt) / (1 + Kt);
    b  =      Kt  / (1 + Kt);
    x  = fillmissing(x, "previous");
    x  = fillmissing(x, "next");
    y  = filter([b b], [1 -a1], x - x(1,:)) + x(1,:);
end
