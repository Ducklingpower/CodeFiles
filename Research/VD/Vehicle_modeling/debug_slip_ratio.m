clc
close all
clear
% debug slip ratio - per wheel Fx observer from the wheel torque model and the brush tire at the measured slip ratio
%
% measured slip ratio  kappa = (Vw - Vx_tire)/|Vx|, vehicle_model.m, every input low passed at 1.3 Hz
%                      (the raw slip ratio is rebuilt here from the unfiltered channels for comparison)
% slip ratio bias     the wheel speed / effective rolling radius gives the measured slip an offset (+0.5 to +1.6 %, the
%                      2026 log is not wheel speed calibrated); kappa_c = kappa_meas - b, b learned per wheel where the
%                      brush is steep (weight (1 - |k|/k_th)^(2 wPow)), frozen near the peak and at lock up:
%                        load / speed  th0 + th1 Fz[kN] + th2 (vx/50)^2, recursive least squares, forgetting lamRLS
%                        time bias     what is left, pulled to (kappa_meas - load part - kappa_brush) with tauB
%                      the brush inverse uses the wheel torque Fx (nothing from the force balance)
% tire model           Fz sensitive brush, Fx = mu Fz (1 - (1 - |kappa|/k_th)^3) sign(kappa), mu Fz past
%                      k_th = 3 mu Fz / C_kappa; C_kappa(Fz) from the Pacejka load dependence (100 BCD),
%                      mu_x(Fz) per axle refit as mu0 (Fz/Fz0)^q from the muPct percentile of |Fx|/Fz in load bins
% Fx observer          per wheel and sample, inverse variance fusion of
%                        wheel torque  Fx_tq (vehicle_model.m wheel dynamics), sigma_tq = sigA + sigR |Fx_tq|
%                        brush         Fx_b = brush(kappa_c, Fz) at the bias corrected slip, sigma_b = |dFx/dkappa| sigK + sigMu |Fx_b|,
%                                      dFx/dkappa = C_kappa (1 - |kappa|/k_th)^2, 0 past k_th
%                      so the brush counts near the peak (flat curve) and hardly in the linear range (steep curve)
% scored on the vehicle frame sum of the wheel forces against the force balance Fx_total = m a_x + drag + grade,
% which nothing in the observer uses: mu_x and the slip bias are learned from the wheel torque Fx only, so the score
% is independent (learning them from Fx corrected to Fx_total scored 950 N instead of 1094 N, i.e. optimistic)
% for comparison, the IMU force balance split of vehicle_model.m (Fx_*_fb): Fx_total = m a_x + drag + grade split per
% tire, drive all rear, braking front / rear by the caliper pressure bias (0.53 below 75 kPa) with engine braking on the
% rear, each axle 50 / 50 left / right; it sums to Fx_total by construction, so it is not scored against it
% ASSUMPTION: pure longitudinal brush, no combined slip (one change at a time)

%% settings

here    = fileparts(mfilename("fullpath"));
matFile = fullfile(here, "tire_fit_data_2026.mat");   % vehicle_model.m output, 2026 comp log
csvFile = "/home/elijah/PurdueRacing/bags/lagoona/comp2/compition_bags/2026-09-03_121638_merged.csv";   % same log, raw channels
rawFile = fullfile(here, "debug_slip_ratio_data.mat");  % raw channel cache, read from the CSV once

vMin   = 10;          % (m/s) samples used
sigA   = 100;         % (N) wheel torque Fx uncertainty floor
sigR   = 0.2;         % (-) wheel torque Fx uncertainty, fraction of its force
sigK   = 0.002;       % (-) bias corrected slip ratio uncertainty
tauB   = 2.0;         % (s) time bias pull time
lamRLS = 0.99995;     % RLS forgetting factor per (weighted) sample, memory ~ 200 s at 100 Hz
wPow   = 2;           % bias weight = conditioning^wPow
fzMin  = 300;         % (N) no bias update on a wheel below this load, and the mu_x plot leaves it out
sigMu  = 0.10;        % (-) brush uncertainty, fraction of its force
muPct  = 98;          % percentile of |Fx|/Fz taken as the peak in each load bin (mu_x refit)

lapRef    = [100 144];
turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];
wNames    = ["FL", "FR", "RL", "RR"];

cRaw  = [0.55 0.55 0.55];   % grey, raw
cMeas = [0.60 0.20 0.60];   % purple, 1.3 Hz measured
cMdl  = [0.92 0.41 0.20];   % orange, brush
cTq   = [0.00 0.45 0.74];   % blue, wheel torque model
cFus  = [0.95 0.75 0.10];   % yellow, fused
cFb   = [0.85 0.10 0.10];   % red, force balance
cImu  = [0.47 0.67 0.19];   % green, IMU force balance split per tire

%% data

d  = load(matFile);
vp = d.vehicleParams;
t  = d.t;
Ts = median(diff(t));
n  = numel(t);
dl = d.delta;
Fz = max(d.Fz_dual_obs, 0);
kM = [d.kappa_fl, d.kappa_fr, d.kappa_rl, d.kappa_rr];      % measured slip ratio, 1.3 Hz (-)
Fx = [d.Fx_fl, d.Fx_fr, d.Fx_rl, d.Fx_rr];                  % wheel torque model Fx (N)
FxI = [d.Fx_fl_fb, d.Fx_fr_fb, d.Fx_rl_fb, d.Fx_rr_fb];     % IMU force balance split per tire (N)
lk = [d.locked_fl, d.locked_fr, d.locked_rl, d.locked_rr];
ok = d.Fvx > vMin & all(isfinite([kM, Fx, Fz, d.Fx_total, d.Fyf, dl]), 2);
fprintf("samples %d, used (v > %d m/s) %d\n", n, vMin, nnz(ok));

toVeh = @(F) (F(:,1) + F(:,2)) .* cos(dl) - d.Fyf .* sin(dl) + F(:,3) + F(:,4);   % vehicle frame sum of the wheel Fx
sel   = @(x, m) x(m);                                                          % index a full length result

%% raw slip ratio: same kinematics as vehicle_model.m on the unfiltered channels
% wheel speed calibration: the saved Vw = lpf(raw)/3.6/wheelCal, so wheelCal = median(lpf(raw)/3.6 / Vw)

if isfile(rawFile)
    R = load(rawFile).R;
else
    o = detectImportOptions(csvFile);
    o.SelectedVariableNames = ["fl_speed_kmh", "fr_speed_kmh", "rl_speed_kmh", "rr_speed_kmh", ...
                               "odom_vx_mps", "odom_vy_mps", "odom_wz_rads", "steer_wheel_ang_deg"];
    o = setvartype(o, o.SelectedVariableNames, "double");
    T = readtable(csvFile, o);
    R.ws = [T.fl_speed_kmh, T.fr_speed_kmh, T.rl_speed_kmh, T.rr_speed_kmh] / 3.6;
    R.vx = T.odom_vx_mps;  R.vy = T.odom_vy_mps;  R.wz = T.odom_wz_rads;  R.steer = T.steer_wheel_ang_deg;
    save(rawFile, "R");
end
R.ws = fillmissing(R.ws, "previous");  R.vx = fillmissing(R.vx, "previous");  R.vy = fillmissing(R.vy, "previous");
R.wz = fillmissing(R.wz, "previous");  R.steer = fillmissing(R.steer, "previous");
Vw   = [d.Vw_fl, d.Vw_fr, d.Vw_rl, d.Vw_rr];
wCal = median(lpfT(R.ws, 1.3, Ts) ./ Vw, "omitnan");
kR   = slipKin(R.ws ./ wCal, R.vx, R.vy, R.wz, deg2rad(vp.steerOffset + R.steer ./ vp.steerRatio), vp);
kR(~ok,:) = NaN;
fprintf("wheel speed calibration in the 2026 data: %s (1 = not calibrated)\n", sprintf("%.4f ", wCal));

%% brush: C_kappa from the Pacejka load dependence, mu_x refit from the data envelope
% the envelope uses the wheel torque Fx; Fx_total is never used to fit or learn anything (it is only the score)

pac  = [vp.pacFx_f; vp.pacFx_f; vp.pacFx_r; vp.pacFx_r];
Ckap = @(i, z) 100 .* (pac(i,4) .* (z/1000).^2 + pac(i,5) .* z/1000) .* exp(-pac(i,6) .* z/1000);   % (N per unit slip)

muR = zeros(2, 2);   % [mu0 q] per axle
z0  = [mean(vp.staticCornerLoad(1:2)), mean(vp.staticCornerLoad(3:4))];
for ax = 1:2
    ii = 2*ax-1:2*ax;
    zz = reshape(Fz(ok,ii), [], 1);  rr = reshape(abs(Fx(ok,ii)) ./ max(Fz(ok,ii), 1), [], 1);
    keep = zz > 500;  zz = zz(keep);  rr = rr(keep);
    edges = prctile(zz, 0:10:100);  zb = [];  mb = [];
    for k = 1:numel(edges) - 1
        sb = zz >= edges(k) & zz < edges(k+1);
        if nnz(sb) > 200, zb(end+1,1) = median(zz(sb)); mb(end+1,1) = prctile(rr(sb), muPct); end %#ok<AGROW>
    end
    pm = [ones(numel(zb),1), log(zb / z0(ax))] \ log(mb);
    muR(ax,:) = [exp(pm(1)), pm(2)];
end
muX = @(i, z) muR(ceil(i/2),1) .* (max(z, 500) / z0(ceil(i/2))).^muR(ceil(i/2),2);
fprintf("brush per wheel at the static load: C_kappa (N per %% slip), mu_x refit (%d th percentile), slip at the peak k_th (%%)\n", muPct);
for i = 1:4
    z = vp.staticCornerLoad(i);
    fprintf("  %s  %5.0f   %.2f   %.2f\n", wNames(i), Ckap(i, z) / 100, muX(i, z), 100 * 3 * muX(i, z) * z / Ckap(i, z));
end

%% slip ratio bias correction

kB = nan(n, 4);  cnd = zeros(n, 4);
for i = 1:4
    [kB(:,i), cnd(:,i)] = brushInverseX(Fx(:,i), Fz(:,i), muX(i, Fz(:,i)), Ckap(i, Fz(:,i)));
end
cnd(lk | Fz < fzMin | ~ok) = 0;
regX = @(i) [ones(n,1), Fz(:,i) / 1000, (d.Fvx / 50).^2];
bLM  = zeros(n, 4);  thEnd = zeros(3, 4);
for i = 1:4
    [bLM(:,i), thEnd(:,i)] = rlsBias(regX(i), kM(:,i) - kB(:,i), cnd(:,i) .^ wPow, lamRLS);
end
bT   = timeBias(kM - bLM, kB, cnd .^ wPow, tauB, Ts);
bias = bLM + bT;
kC   = kM - bias;   kC(~ok,:) = NaN;                      % bias corrected slip ratio
fprintf("\nslip ratio bias, load / speed part at the end of the log (%%) = th0 + th1 Fz[kN] + th2 (vx/50)^2, total bias 5-95 %%\n");
for i = 1:4
    fprintf("  %s  th0 %+.3f   th1 %+.3f per kN   th2 %+.3f   bias %+.3f to %+.3f %%\n", wNames(i), 100 * thEnd(:,i), 100 * prctile(bias(ok,i), [5 95]));
end

%% Fx observer

Fb = zeros(n, 4);  sb = zeros(n, 4);  util = zeros(n, 4);
for i = 1:4
    mu  = muX(i, Fz(:,i));  C = Ckap(i, Fz(:,i));
    Fb(:,i) = brushFx(kC(:,i), Fz(:,i), mu, C);
    kth = 3 .* mu .* max(Fz(:,i), 100) ./ C;
    sb(:,i) = C .* (1 - min(abs(kC(:,i)) ./ kth, 1)).^2 .* sigK + sigMu .* abs(Fb(:,i)) + 1;
    util(:,i) = abs(Fx(:,i)) ./ (mu .* max(Fz(:,i), 100));
end
st2  = (sigA + sigR .* abs(Fx)).^2;
FxF  = (Fx ./ st2 + Fb ./ sb.^2) ./ (1 ./ st2 + 1 ./ sb.^2);   % fused Fx per wheel
wBr  = (1 ./ sb.^2) ./ (1 ./ st2 + 1 ./ sb.^2);              % weight on the brush

brk  = ok & d.Fax < -5;
pure = ok & abs(d.ay_tire) < 2;
hiU  = ok & max(util, [], 2) > 0.7;
sets = {ok, pure, brk, hiU};  setN = ["all", "|a_y| < 2 (pure longitudinal)", "braking a_x < -5", "a wheel above 70 % of its peak"];
fprintf("\nvehicle frame Fx sum vs force balance Fx_total, rms (N)\n%-34s %14s %14s %10s\n", "", "wheel torque", "brush", "fused");
for m = 1:numel(sets)
    s = sets{m};
    r = @(F) rms(d.Fx_total(s) - sel(toVeh(F), s), "omitnan");
    fprintf("%-34s %14.0f %14.0f %10.0f   (%d samples)\n", setN(m), r(Fx), r(Fb), r(FxF), nnz(s));
end
fprintf("per wheel rms difference to the IMU force balance split (N): wheel torque / brush / fused\n");
for i = 1:4
    fprintf("  %s  %5.0f / %5.0f / %5.0f\n", wNames(i), rms(Fx(ok,i) - FxI(ok,i)), rms(Fb(ok,i) - FxI(ok,i), "omitnan"), rms(FxF(ok,i) - FxI(ok,i), "omitnan"));
end
fprintf("median weight on the brush per wheel: all / braking a_x < -5 / a wheel above 70 %% of its peak\n");
for i = 1:4
    fprintf("  %s  %.2f / %.2f / %.2f\n", wNames(i), median(wBr(ok,i)), median(wBr(brk,i)), median(wBr(hiU,i)));
end

%% fastest lap

lapWin = fastestLap(t, d.px, d.py, d.Fvx, lapRef);
lap  = t >= lapWin(1) & t <= lapWin(2);
tl0  = t(lap) - lapWin(1);
tTurn = zeros(numel(turnNames), 1);
for c = 1:numel(turnNames)
    [~, m] = min(hypot(d.px(lap) - turnXY(c,1), d.py(lap) - turnXY(c,2)));
    tTurn(c) = tl0(m);
end

%% plots, one window, one tab per plot

fig = figure("Name", "Debug slip ratio", "Position", [50 50 1500 1100]);
tg  = uitabgroup(fig);

% tab: Fx observer, fastest lap
tl = newTab(tg, "Fx observer", 6, 1);
axO = gobjects(6, 1);
axO(1) = nexttile(tl);
hold on
plot(tl0, d.Fx_total(lap),      "-", "Color", cFb,  "LineWidth", 2);
plot(tl0, sel(toVeh(Fx), lap),  "-", "Color", cTq,  "LineWidth", 1.0);
plot(tl0, sel(toVeh(Fb), lap),  "-", "Color", cMdl, "LineWidth", 1.0);
plot(tl0, sel(toVeh(FxF), lap), "-", "Color", cFus, "LineWidth", 1.5);
grid on
ylabel("F_x [N]");
title("Vehicle frame Fx sum (the force balance is not an input to the observer)");
legend("force balance m a_x + drag + grade", "wheel torque model", "brush at the bias corrected slip ratio", "fused", "Location", "northwest", "FontSize", 7);
for i = 1:4
    axO(1+i) = nexttile(tl);
    hold on
    plot(tl0, Fx(lap,i),  "-", "Color", cTq,  "LineWidth", 1.0);
    plot(tl0, Fb(lap,i),  "-", "Color", cMdl, "LineWidth", 1.0);
    plot(tl0, FxI(lap,i), "-", "Color", cImu, "LineWidth", 1.2);
    plot(tl0, FxF(lap,i), "-", "Color", cFus, "LineWidth", 1.5);
    ylabel("F_x [N]");
    grid on
    title(wNames(i) + " Fx");
    if i == 1, legend("wheel torque model", "brush at the bias corrected slip ratio (refit mu_x)", "IMU force balance split (brake bias, 50 / 50)", ...
            "fused", "Location", "northwest", "FontSize", 7); end
end
axO(6) = nexttile(tl);
plot(tl0, d.Fax(lap), "w-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("a_x [m/s^2]");
title("Longitudinal acceleration");
linkaxes(axO, "x");
xlim(axO(1), [0 diff(lapWin)]);
title(tl, sprintf("Fx observer: wheel torque + brush at the bias corrected slip ratio, fastest lap %.1f s", diff(lapWin)));

% tab: measured slip ratio, raw and 1.3 Hz, fastest lap
tl = newTab(tg, "Slip ratio", 5, 1);
axS = gobjects(5, 1);
for i = 1:4
    axS(i) = nexttile(tl);
    hold on
    plot(tl0, 100 * kR(lap,i), "-", "Color", cRaw,  "LineWidth", 0.5);
    plot(tl0, 100 * kM(lap,i), "-", "Color", cMeas, "LineWidth", 1.5);
    plot(tl0, 100 * kC(lap,i), "-", "Color", [1 1 1], "LineWidth", 1.5);
    grid on
    ylim([-8 8]);
    ylabel("\kappa [%]");
    title(wNames(i) + " slip ratio");
    if i == 1, legend("raw (unfiltered channels)", "measured, 1.3 Hz (vehicle\_model.m)", "bias corrected (measured - learned bias)", "Location", "northwest", "FontSize", 7); end
end
axS(5) = nexttile(tl);
plot(tl0, d.Fax(lap), "w-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("a_x [m/s^2]");
title("Longitudinal acceleration");
linkaxes(axS, "x");
xlim(axS(1), [0 diff(lapWin)]);
title(tl, sprintf("Measured slip ratio per wheel, fastest lap %.1f s", diff(lapWin)));

% tab: slip ratio vs mu_x = Fx / Fz per tire and per axle, every Fz is the observed load of that sample
% four Fx: wheel torque model, IMU force balance split (vehicle_model.m Fx_*_fb), brush at the bias corrected slip ratio
% (at the observed Fz), fused (observer); each as a scatter and the median slip per mu_x bin
% near pure longitudinal samples (|a_y| < 2), no locked wheel, every wheel load above fzMin
% axle: slip = mean of the two wheels, mu_x = (Fx_L + Fx_R) / (Fz_L + Fz_R)
sv   = ok & abs(d.ay_tire) < 2 & ~any(lk, 2) & all(Fz > fzMin, 2);
iv   = find(sv);  iv = iv(1:3:end);
FzAx = [Fz(:,1) + Fz(:,2), Fz(:,3) + Fz(:,4)];
axS  = @(F) [F(:,1) + F(:,2), F(:,3) + F(:,4)] ./ FzAx;     % axle mu_x from per wheel Fx
kAx  = [mean(kC(:,1:2), 2), mean(kC(:,3:4), 2)];
muS  = {Fx ./ Fz, FxI ./ Fz, Fb ./ Fz, FxF ./ Fz};           % per tire
muSa = {axS(Fx), axS(FxI), axS(Fb), axS(FxF)};               % per axle
muN  = ["wheel torque", "IMU force balance split", "brush at the bias corrected slip ratio", "fused (observer)"];
muC  = [cTq; cImu; cMdl; cFus];
tl = newTab(tg, "Slip ratio vs mu_x", 2, 3);
pn = [wNames, "Front axle", "Rear axle"];
for p = 1:6
    nexttile(tl);
    hold on
    if p <= 4, x = kC(:,p);  else, x = kAx(:,p-4); end
    for m = 1:4
        if p <= 4, y = muS{m}(:,p); else, y = muSa{m}(:,p-4); end
        scatter(100 * x(iv), y(iv), 3, muC(m,:), "filled", "MarkerFaceAlpha", 0.2, "HandleVisibility", "off");
    end
    for m = 1:4
        if p <= 4, y = muS{m}(:,p); else, y = muSa{m}(:,p-4); end
        [bx, by] = binMed(y(sv), 100 * x(sv), -2:0.05:2, 30);
        plot(by, bx, "-", "Color", muC(m,:), "LineWidth", 2.5, "DisplayName", muN(m) + ", median slip per \mu_x bin");
    end
    grid on
    xlim([-8 8]);
    ylim([-2 2]);
    xlabel("bias corrected \kappa [%]");
    ylabel("\mu_x = F_x / F_z observed [-]");
    title(pn(p));
    if p == 1, legend("Location", "northwest", "FontSize", 7); end
end
title(tl, sprintf("Bias corrected slip ratio vs \\mu_x = F_x / F_z (observed), wheel torque, IMU split, brush and fused, |a_y| < 2 m/s^2, F_z > %d N, whole log", fzMin));


function [kap, cn] = brushInverseX(F, Fz, mu, C)
% closed form inverse of the Fz sensitive brush: kappa = k_th (1 - (1 - |F|/(mu Fz))^(1/3)), k_th = 3 mu Fz / C
% cn = (1 - kappa/k_th)^2 = (1 - u)^(2/3), local slope / initial slope, 0 at or past saturation (u = |F| / (mu Fz) >= 1)

    Fz  = max(Fz, 100);
    u   = abs(F) ./ (mu .* Fz);
    kap = sign(F) .* 3 .* mu .* Fz ./ C .* (1 - (1 - min(u, 1)).^(1/3));
    cn  = (1 - min(u, 1)).^(2/3);
    cn(u >= 1 | ~isfinite(cn)) = 0;
end


function [b, th] = rlsBias(X, y, w, lam)
% weighted recursive least squares of y = X th, weight w per sample (0 = no update), forgetting factor lam
% b(k) = X(k) th(k-1), the prediction before the sample is used (causal)

    [n, p] = size(X);
    th = zeros(p, 1);
    P  = 1e2 * eye(p);
    b  = zeros(n, 1);
    w(~isfinite(y) | any(~isfinite(X), 2)) = 0;
    for k = 1:n
        x    = X(k,:)';
        b(k) = x' * th;
        if w(k) > 0
            g  = P * x / (lam / w(k) + x' * P * x);
            th = th + g * (y(k) - x' * th);
            P  = (P - g * x' * P) / lam;
        end
    end
end


function b = timeBias(kM, kB, w, tau, Ts)
% slow bias per wheel: b pulled to (kappa_meas - kappa_brush) with weight w and time constant tau, held at w = 0

    inn = kM - kB;
    w(~isfinite(inn)) = 0;
    inn(~isfinite(inn)) = 0;
    b = zeros(size(kM));
    for k = 2:size(kM, 1)
        b(k,:) = b(k-1,:) + (Ts / tau) .* w(k,:) .* (inn(k,:) - b(k-1,:));
    end
end


function F = brushFx(kap, Fz, mu, C)
% Fz sensitive brush: F = mu Fz (1 - (1 - |kappa|/k_th)^3) sign(kappa), mu Fz past k_th = 3 mu Fz / C

    Fz  = max(Fz, 100);
    Fm  = mu .* Fz;
    kth = 3 .* Fm ./ C;
    F   = sign(kap) .* Fm .* (1 - (1 - min(abs(kap) ./ kth, 1)).^3);
end


function kap = slipKin(Vw, vx, vy, r, dl, vp)
% slip ratio per wheel, dual track kinematics as vehicle_model.m: corner speeds vx -/+ r t/2, front rotated by delta,
% kappa = (Vw - Vx_tire) / |Vx_tire|, NaN below 4 m/s

    L  = vp.wheelbase;  lf = (1 - vp.w_dist_f) * L;  ft = vp.t_f;  rt = vp.t_r;
    vx(abs(vx) < 4) = NaN;
    VyF = vy + r .* lf;
    VxC = [vx - r .* (ft/2), vx + r .* (ft/2), vx - r .* (rt/2), vx + r .* (rt/2)];
    VxT = [VxC(:,1) .* cos(dl) + VyF .* sin(dl), VxC(:,2) .* cos(dl) + VyF .* sin(dl), VxC(:,3), VxC(:,4)];
    kap = (Vw - VxT) ./ abs(VxT);
end


function y = lpfT(x, fc, Ts)
% first order Tustin low pass with prewarp, same as vehicle_model.m lpf (starts at the first sample)

    Kt = tan(pi * fc * Ts);
    a1 = (1 - Kt) / (1 + Kt);
    b  =      Kt  / (1 + Kt);
    y  = x;
    for k = 2:size(x, 1)
        y(k,:) = a1 .* y(k-1,:) + b .* (x(k,:) + x(k-1,:));
    end
end


function [win, lapTimes] = fastestLap(t, px, py, v, ref)
% laps timed between passes of the reference point (within 20 m, moving), fastest complete lap

    near = hypot(px - ref(1), py - ref(2)) < 20 & v > 5;
    tp   = t(diff([0; near]) == 1);
    tp   = tp([true; diff(tp) > 40]);
    lapTimes = diff(tp);
    [~, j]   = min(lapTimes);
    win      = [tp(j), tp(j+1)];
end


function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact");
end


function [mid, med] = binMed(x, y, edges, nMin)
% median of y in each bin of x, bins with fewer than nMin samples left out

    mid = 0.5 * (edges(1:end-1) + edges(2:end));
    med = nan(size(mid));
    for b = 1:numel(mid)
        s = x >= edges(b) & x < edges(b+1) & isfinite(y);
        if nnz(s) >= nMin
            med(b) = median(y(s));
        end
    end
    keep = isfinite(med);
    mid  = mid(keep);
    med  = med(keep);
end
