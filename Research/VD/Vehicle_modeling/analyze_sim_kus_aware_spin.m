clc
close all
clear
% analyze_sim_kus_aware_spin - the near spins of the dual track model MPC at speed scale 1.10 (sim, 2026-10-08 15:55 run):
% events found automatically (|side slip| above betaEvent while moving), each plotted over time around its peak, and the
% laps through C9 overlaid on Frenet s with the 0.98 laps of the 15:27 run as the reference
% data: bags in bags/sim_kus_aware_test merged with sim_kus_aware_topics.yaml (--time-mode union)
% colors: event laps by order (red, orange), reference native black, reference dual track model MPC grey red

%% settings

csvFile   = "/home/elijah/PurdueRacing/bags/sim_kus_aware_test/sim_kus_aware_2026-10-08_155500_union_csv/2026-10-08_155500_merged.csv";
csvRef    = "/home/elijah/PurdueRacing/bags/sim_kus_aware_test/sim_kus_aware_2026-10-08_152743_union_csv/2026-10-08_152743_merged.csv";
refScale  = 0.98;  % reference laps from csvRef
figDir    = "/home/elijah/code/CodeFiles/Research/VD/Vehicle_modeling/sim_kus_aware_spin_figs";
betaEvent = 5;     % (deg) side slip that counts as a near spin
tWin      = [-8 6];   % (s) around the side slip peak
sWin      = [2350 3150];  % (m) Frenet s for the overlay (C8 to C10)
steerRatio = 15.015;

turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];
cEv  = [0.85 0.10 0.10; 0.95 0.55 0.05; 0.55 0.10 0.65];
cRef = [0.10 0.10 0.10; 0.85 0.60 0.60];
r2d  = 180 / pi;

%% events

D = loadRun(csvFile, steerRatio);
moving = D.vx > 10;
hot = moving & abs(D.beta) > betaEvent;
edges = find(diff([0; hot]) == 1);
ev = [];
for e = edges'
    I = e:min(numel(hot), e + 500);
    [~, j] = max(abs(D.beta(I)) .* hot(I));
    k = I(j);
    if isempty(ev) || D.t(k) - D.t(ev(end)) > 20, ev(end+1) = k; end %#ok<AGROW>
end
fprintf("%d near spin events (|beta| > %g deg)\n", numel(ev), betaEvent);
fprintf("%-6s %7s %7s %6s %6s %6s %8s %8s %8s %8s %8s %8s %6s %6s\n", "event", "t [s]", "s [m]", "model", "scale", "vx", "beta", "r", "r_des", "lat err", "k_us law", "c", "u_f", "u_r");
for n = 1:numel(ev)
    k = ev(n);
    fprintf("%-6d %7.1f %7.0f %6d %6.2f %6.1f %8.1f %8.3f %8.3f %8.2f %8.5f %8.3f %6.2f %6.2f\n", n, D.t(k), D.frenet_s(k), D.mpc_model(k), ...
        D.speed_scale(k), D.vx(k), D.beta(k), D.wz(k), D.r_des(k), D.lat_err(k), D.kus_law(k), D.c(k), D.u_f(k), D.u_r(k));
end

%% figures

if exist(figDir, "dir"), delete(fullfile(figDir, "*.png")); else, mkdir(figDir); end
fig = figure("Name", "Dual track model MPC near spins", "Position", [40 40 1600 1000]);
theme(fig, "light");
tg = uitabgroup(fig);

% each event over time: what the car did, what the controller asked for, and what it believed
for n = 1:numel(ev)
    k = ev(n);
    I = find(D.t >= D.t(k) + tWin(1) & D.t <= D.t(k) + tWin(2));
    tt = D.t(I) - D.t(k);
    tl = newTab(tg, sprintf("event %d (t %.0f s)", n, D.t(k)), 4, 2);

    nexttile(tl);  hold on
    plot(tt, D.vx(I), "k-", "LineWidth", 1.2, "DisplayName", "v_x");
    yyaxis right;  plot(tt, D.ay(I), "-", "Color", [0.1 0.3 0.85], "DisplayName", "a_y");  ylabel("a_y [m/s^2]");
    yyaxis left;  ylabel("v_x [m/s]");  grid on;  title("Speed and lateral acceleration");  legend("Location", "best");

    nexttile(tl);  hold on
    plot(tt, D.wz(I), "k-", "LineWidth", 1.2, "DisplayName", "r measured");
    plot(tt, D.r_des(I), "--", "Color", cEv(1,:), "LineWidth", 1.2, "DisplayName", "r desired (a_{lat} / v)");
    grid on;  ylabel("yaw rate [rad/s]");  title("Yaw rate");  legend("Location", "best");

    nexttile(tl);  hold on
    plot(tt, D.beta(I), "k-", "LineWidth", 1.2, "DisplayName", "side slip (odometry)");
    plot(tt, D.beta_obs(I), "-", "Color", [0.1 0.3 0.85], "DisplayName", "side slip (VM v_y observer)");
    yline([-betaEvent betaEvent], ":", "Color", [0.6 0.6 0.6], "HandleVisibility", "off");
    grid on;  ylabel("\beta [deg]");  title("Side slip");  legend("Location", "best");

    nexttile(tl);  hold on
    plot(tt, D.steer_cmd_deg(I), "-", "Color", cEv(1,:), "LineWidth", 1.2, "DisplayName", "command");
    plot(tt, D.steer_fbk_road(I), "k-", "DisplayName", "feedback");
    plot(tt, D.steer_fb(I) * r2d, "-", "Color", [0.1 0.6 0.3], "DisplayName", "yaw rate feedback part");
    grid on;  ylabel("road wheel [deg]");  title("Steering");  legend("Location", "best");

    nexttile(tl);  hold on
    plot(tt, D.lat_err(I), "k-", "LineWidth", 1.2, "DisplayName", "now");
    plot(tt, D.lat_err_k10(I), "-", "Color", cEv(2,:), "DisplayName", "predicted at knot 10 (0.6 s)");
    grid on;  ylabel("lateral error [m]");  title("Lateral error");  legend("Location", "best");

    nexttile(tl);  hold on
    plot(tt, D.kus_law(I) * 1e3, "-", "Color", cEv(1,:), "LineWidth", 1.2, "DisplayName", "K_{us} law");
    plot(tt, D.kus10(I) * 1e3, "-", "Color", cEv(2,:), "DisplayName", "K_{us} knot 10");
    plot(tt, D.kus_meas(I) * 1e3, ".", "Color", [0.5 0.5 0.5], "DisplayName", "K_{us} measured (learner)");
    yyaxis right;  plot(tt, D.c(I), "-", "Color", [0.1 0.6 0.3], "DisplayName", "level c");  ylabel("c");  ylim([0 2.1]);
    yyaxis left;  ylabel("K_{us} [1e-3 rad/(m/s^2)]");  grid on;  title("Understeer gradient (active model)");  legend("Location", "best");

    nexttile(tl);  hold on
    plot(tt, D.u_f(I), "-", "Color", cEv(1,:), "LineWidth", 1.2, "DisplayName", "front");
    plot(tt, D.u_r(I), "-", "Color", [0.1 0.3 0.85], "LineWidth", 1.2, "DisplayName", "rear");
    yline(1, ":", "saturated", "Color", [0.6 0.6 0.6], "HandleVisibility", "off");
    grid on;  ylabel("|F| / peak");  ylim([0 1.1]);  title("Brush utilisation at the law's preview point (model)");  legend("Location", "best");

    nexttile(tl);  hold on
    plot(tt, D.fz_total(I), "k-", "LineWidth", 1.2, "DisplayName", "\Sigma F_z observed");
    plot(tt, D.dual_fz_fl(I) + D.dual_fz_fr(I), "-", "Color", cEv(1,:), "DisplayName", "front");
    plot(tt, D.dual_fz_rl(I) + D.dual_fz_rr(I), "-", "Color", [0.1 0.3 0.85], "DisplayName", "rear");
    yyaxis right;  plot(tt, D.accel_cmd(I), "-", "Color", [0.1 0.6 0.3], "DisplayName", "accel command");  ylabel("a_x cmd [m/s^2]");
    yyaxis left;  ylabel("F_z [N]");  grid on;  title("Observed normal loads and the acceleration command");  legend("Location", "best");

    xlabel(tl, "time from the side slip peak [s]");
    title(tl, sprintf("Event %d: model %d (2 = dual track model MPC), speed scale %.2f, Frenet s %.0f m, peak side slip %.1f deg", ...
                      n, D.mpc_model(k), D.speed_scale(k), D.frenet_s(k), D.beta(k)));
end

% the event laps and the 0.98 reference laps through C8 to C10 on Frenet s
R = loadRun(csvRef, steerRatio);
sTurn = cornersOnS(D, turnXY);
tl = newTab(tg, "C8 to C10 on Frenet s", 5, 1);
ax = gobjects(5,1);
pf = ["vx", "steer_cmd_deg", "beta", "lat_err", "kus_law"];
yl = ["v_x [m/s]", "steering cmd [deg]", "\beta [deg]", "lateral error [m]", "K_{us} law"];
for p = 1:5
    ax(p) = nexttile(tl);  hold on
    for n = 1:numel(ev)
        I = lapAround(D, ev(n));
        plot(D.frenet_s(I), D.(pf(p))(I), "-", "Color", cEv(n,:), "LineWidth", 1.4, "DisplayName", sprintf("event %d lap (scale %.2f, model %d)", n, D.speed_scale(ev(n)), D.mpc_model(ev(n))));
    end
    for m = [0 2]
        I = refLap(R, refScale, m);
        if ~isempty(I)
            plot(R.frenet_s(I), R.(pf(p))(I), "-", "Color", cRef(1 + (m == 2), :), "LineWidth", 1.1, ...
                 "DisplayName", sprintf("reference %.2f, model %d", refScale, m));
        end
    end
    xline(ax(p), sTurn(isfinite(sTurn)), ":", turnNames(isfinite(sTurn)), "Color", [0.45 0.45 0.45], "HandleVisibility", "off");
    grid on;  ylabel(yl(p));
end
legend(ax(1), "Location", "eastoutside");
linkaxes(ax, "x");  xlim(ax(1), sWin);
xlabel(tl, "Frenet s [m]");
title(tl, "The near spin laps against the 0.98 laps of the 15:27 run (model 0 native, 2 dual track model MPC)");

tabs = tg.Children;
for k = 1:numel(tabs)
    tg.SelectedTab = tabs(k);
    drawnow;
    exportgraphics(tabs(k), fullfile(figDir, sprintf("%02d_%s.png", k, regexprep(tabs(k).Title, "[^A-Za-z0-9]+", "_"))), "Resolution", 130);
end
fprintf("figures written to %s\n", figDir);


%% local functions

function D = loadRun(csvFile, steerRatio)
% the merged run with the held signals, side slip, and the active model MPC's debug values

    D = readtable(csvFile);
    D.t = D.time_s - D.time_s(1);
    hold_cols = ["frenet_s", "mpc_model", "speed_scale", "kus_used", "r_des", "steer_cmd_deg", "steer_fb", "accel_cmd", ...
                 "lat_err", "lat_err_k10", "ka_bike_kus_law", "ka_bike_c", "ka_bike_kus10", "ka_bike_kus_meas", "ka_bike_u_f", "ka_bike_u_r", ...
                 "ka_dual_kus_law", "ka_dual_c", "ka_dual_kus10", "ka_dual_kus_meas", "ka_dual_u_f", "ka_dual_u_r", "bike_vy"];
    for c = hold_cols
        D.(c) = fillmissing(D.(c), "previous");
    end
    D.frenet_s  = movmedian(D.frenet_s, 5);
    D.mpc_model = round(D.mpc_model);
    D.beta      = atan2d(D.vy, max(D.vx, 1));
    D.beta_obs  = atan2d(D.bike_vy, max(D.vx, 1));
    D.steer_fbk_road = D.steer_fbk_deg / steerRatio;
    D.fz_total  = D.dual_fz_fl + D.dual_fz_fr + D.dual_fz_rl + D.dual_fz_rr;

    % the active model MPC's values (the bicycle model's while native: its shadow)
    dual = D.mpc_model == 2;
    pick = @(b, d) b .* ~dual + d .* dual;
    D.kus_law  = pick(D.ka_bike_kus_law, D.ka_dual_kus_law);
    D.kus_law(D.mpc_model == 0) = D.kus_used(D.mpc_model == 0);
    D.c        = pick(D.ka_bike_c, D.ka_dual_c);
    D.kus10    = pick(D.ka_bike_kus10, D.ka_dual_kus10);
    D.kus_meas = pick(D.ka_bike_kus_meas, D.ka_dual_kus_meas);
    D.u_f      = pick(D.ka_bike_u_f, D.ka_dual_u_f);
    D.u_r      = pick(D.ka_bike_u_r, D.ka_dual_u_r);
end


function I = lapAround(D, k)
% the samples of the lap that contains sample k (between the Frenet s wraps)

    b = [1; find(diff(D.frenet_s) < -1000) + 1; height(D) + 1];
    j = find(b <= k, 1, "last");
    I = (b(j):b(j+1) - 1)';
end


function I = refLap(R, scale, model)
% the reference lap with the most samples at this speed scale and MPC model

    b = [1; find(diff(R.frenet_s) < -1000) + 1; height(R) + 1];
    I = [];
    for j = 1:numel(b) - 1
        J = (b(j):b(j+1) - 1)';
        J = J(abs(R.speed_scale(J) - scale) < 0.002 & R.mpc_model(J) == model);
        if numel(J) > numel(I), I = J; end
    end
end


function sTurn = cornersOnS(D, turnXY)
% corners placed on Frenet s by position

    sTurn = nan(size(turnXY, 1), 1);
    ok = D.vx > 5;
    for c = 1:size(turnXY, 1)
        d2 = hypot(D.px - turnXY(c,1), D.py - turnXY(c,2));
        d2(~ok) = inf;
        [dmin, j] = min(d2);
        if dmin < 40, sTurn(c) = D.frenet_s(j); end
    end
end


function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact", "Padding", "compact");
end
