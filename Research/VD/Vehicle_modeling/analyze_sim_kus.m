clc
close all
clear
% analyze_sim_kus - sim test of the fbl_mpc k_us switch: one lap each with the MPC's own k_us, the vehicle model
% bicycle k_us and the vehicle model dual track k_us (base station "k_us source"), laps overlaid on distance
% data: the sim bag recorded during the test, merged with sim_kus_topics.yaml
% colors: MPC own black (second MPC lap dark grey), bicycle blue, dual track red, raw / reference grey

%% settings

csvFile = "/home/elijah/PurdueRacing/bags/sim_kus_test/sim_kus_2026-10-06_141428_csv/2026-10-06_141428_merged.csv";
figDir  = "/home/elijah/code/CodeFiles/Research/VD/Vehicle_modeling/sim_kus_figs";

% Laguna Seca: lap timed at the C11 reference point, corners by position (odom x, y in m)
lapRef    = [100 144];
turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];

srcNames = ["MPC own", "vehicle model bicycle", "vehicle model dual track"];
cSrc     = [0.10 0.10 0.10; 0.10 0.35 0.85; 0.85 0.10 0.10];   % MPC, bicycle, dual track
cMpc2    = [0.50 0.50 0.50];                                    % second MPC lap
cRaw     = [0.62 0.62 0.62];
cT       = [0.55 0.00 0.00; 1.00 0.45 0.45; 0.00 0.20 0.60; 0.40 0.70 1.00];   % FL, FR, RL, RR
tireN    = ["FL", "FR", "RL", "RR"];
r2d      = 180 / pi;

%% load, laps, distance

D  = readtable(csvFile);
t  = D.time_s - D.time_s(1);
D.kus_src = fillmissing(D.kus_src, "previous");

near = hypot(D.px - lapRef(1), D.py - lapRef(2)) < 20 & D.vx > 5;
tp   = t(diff([0; near]) == 1);
tp   = tp([true; diff(tp) > 40]);
lapLen = median(diff(tp));
tp   = tp([diff(tp) < 1.2 * lapLen; false] | [false; diff(tp) < 1.2 * lapLen]);   % complete laps only

laps = struct("t0", {}, "t1", {}, "src", {}, "idx", {}, "s", {}, "name", {}, "color", {});
nMpc = 0;
for k = 1:numel(tp) - 1
    idx = find(t >= tp(k) & t < tp(k+1));
    if max(abs(D.lat_err(idx)), [], "omitnan") > 20, continue, end          % sim reset / teleport
    src = mode(round(D.kus_src(idx)));
    if src == 0
        nMpc = nMpc + 1;
        col = cSrc(1,:);  if nMpc > 1, col = cMpc2; end
        nm  = srcNames(1) + " (lap " + nMpc + ")";
    else
        col = cSrc(src + 1, :);
        nm  = srcNames(src + 1);
    end
    s = cumtrapz(t(idx), fillmissing(D.vx(idx), "linear"));
    laps(end+1) = struct("t0", tp(k), "t1", tp(k+1), "src", src, "idx", idx, "s", s, "name", nm, "color", col); %#ok<SAGROW>
end
fprintf("%d complete laps\n", numel(laps));

% corners on the first lap's distance
L1 = laps(1);
sTurn = nan(numel(turnNames), 1);
for c = 1:numel(turnNames)
    [dmin, j] = min(hypot(D.px(L1.idx) - turnXY(c,1), D.py(L1.idx) - turnXY(c,2)));
    if dmin < 40, sTurn(c) = L1.s(j); end
end

% per lap metrics
fprintf("\n%-28s %8s %8s %9s %9s %10s %10s %11s %11s\n", "lap", "time s", "vx max", "|e| rms", "|e| max", "r err rms", "fb steer", "steer rate", "k_us used");
for k = 1:numel(laps)
    I = laps(k).idx;
    rErr  = D.r_des(I) - D.wz(I);
    sRate = gradient(fillmissing(D.steer_cmd_deg(I), "previous"), t(I));
    corner = abs(D.vx(I) .* D.wz(I)) > 4;
    laps(k).m = [laps(k).t1 - laps(k).t0, max(D.vx(I)), rms(D.lat_err(I), "omitnan"), max(abs(D.lat_err(I))), ...
                 rms(rErr, "omitnan"), rms(D.steer_fb(I), "omitnan") * r2d, rms(sRate, "omitnan"), median(D.kus_used(I(corner)), "omitnan")];
    fprintf("%-28s %8.1f %8.1f %9.3f %9.3f %10.4f %10.3f %11.2f %11.5f\n", laps(k).name, laps(k).m);
end
fprintf("columns: lateral error (m), yaw rate error r_des - r (rad/s), yaw rate feedback steering (deg rms), steering command rate (deg/s rms), median k_us used where |vx r| > 4\n");

%% figures

if ~exist(figDir, "dir"), mkdir(figDir); end
fig = figure("Name", "Sim k_us switch test", "Position", [40 40 1600 1000]);
theme(fig, "light");
tg = uitabgroup(fig);
mark = @(ax) xline(ax, sTurn(isfinite(sTurn)), ":", turnNames(isfinite(sTurn)), "Color", [0.45 0.45 0.45], ...
    "LabelVerticalAlignment", "top", "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");

% 1 laps overlaid: speed, a_y, k_us used, lateral error, steering
tl = newTab(tg, "Laps overlaid", 5, 1);
ax = gobjects(5,1);
lbl = ["v_x [m/s]", "a_y [m/s^2]", "k_{us} used [rad/(m/s^2)]", "lateral error [m]", "steering command [deg]"];
ttl = ["Speed", "Lateral acceleration (accel\_filtered)", "Understeer gradient the MPC used", ...
       "MPC lateral error", "Steering wheel command"];
for p = 1:5
    ax(p) = nexttile(tl);  hold on
    for k = 1:numel(laps)
        I = laps(k).idx;
        y = {D.vx(I), D.ay(I), D.kus_used(I), D.lat_err(I), D.steer_cmd_deg(I)};
        plot(laps(k).s, y{p}, "-", "Color", laps(k).color, "LineWidth", 1.1, "DisplayName", laps(k).name);
    end
    grid on;  ylabel(lbl(p));  title(ttl(p));  mark(ax(p));
end
legend(ax(1), "Location", "eastoutside");
xlabel(tl, "Distance along the lap [m]");
linkaxes(ax, "x");  xlim(ax(1), [0 max(L1.s)]);

% 2 tracking quality
tl = newTab(tg, "Tracking", 3, 1);
ax = gobjects(3,1);
for p = 1:3
    ax(p) = nexttile(tl);  hold on
    for k = 1:numel(laps)
        I = laps(k).idx;
        y = {D.r_des(I) - D.wz(I), D.steer_fb(I) * r2d, D.steer_fbk_deg(I) - D.steer_cmd_deg(I)};
        plot(laps(k).s, y{p}, "-", "Color", laps(k).color, "LineWidth", 1.0, "DisplayName", laps(k).name);
    end
    grid on;  mark(ax(p));
end
ylabel(ax(1), "r_{des} - r [rad/s]");          title(ax(1), "Yaw rate error (MPC desired minus localization)");
ylabel(ax(2), "[deg road wheel]");              title(ax(2), "Yaw rate feedback steering (the correction the steering law needed)");
ylabel(ax(3), "[deg]");                         title(ax(3), "Measured minus commanded steering wheel angle");
legend(ax(1), "Location", "eastoutside");  xlabel(tl, "Distance along the lap [m]");
linkaxes(ax, "x");  xlim(ax(1), [0 max(L1.s)]);

% 3 the three k_us candidates on each lap
tl = newTab(tg, "k_us candidates", numel(laps), 1);
for k = 1:numel(laps)
    I = laps(k).idx;
    a = nexttile(tl);  hold on
    plot(laps(k).s, D.kus_mpc(I), "-", "Color", cSrc(1,:), "LineWidth", 1.0);
    plot(laps(k).s, D.kus_bike(I), "-", "Color", cSrc(2,:), "LineWidth", 1.0);
    plot(laps(k).s, D.kus_dual(I), "-", "Color", cSrc(3,:), "LineWidth", 1.0);
    plot(laps(k).s, D.kus_used(I), ":", "Color", [0.9 0.6 0], "LineWidth", 2.0);
    yline(0.0012, ":", "old clamp 0.0012", "Color", cRaw);
    grid on;  ylabel("k_{us}");  title("Lap " + k + ": " + laps(k).name + " in use (dotted orange = used)");
    mark(a);
end
legend(nexttile(tl, 1), "MPC own", "vehicle model bicycle", "vehicle model dual track", "used", "Location", "eastoutside");
xlabel(tl, "Distance along the lap [m]");

% 4 vehicle model inputs in the sim: gages and observed loads (first vehicle model lap)
kv = find([laps.src] > 0, 1);  if isempty(kv), kv = 1; end
I  = laps(kv).idx;
tl = newTab(tg, "Sim loads", 3, 1);
a1 = nexttile(tl);  hold on
gage = [D.gage_fl(I), D.gage_fr(I), D.gage_rl(I), D.gage_rr(I)];
for i = 1:4, plot(laps(kv).s, fillmissing(gage(:,i), "previous"), "-", "Color", cT(i,:)); end
grid on;  ylabel("F_z [N]");  title("Sim strain gages (tire\_report) per tire, lap " + kv);  legend(tireN, "Location", "eastoutside");  mark(a1);
a2 = nexttile(tl);  hold on
fzh = [D.dual_fz_fl(I), D.dual_fz_fr(I), D.dual_fz_rl(I), D.dual_fz_rr(I)];
for i = 1:4, plot(laps(kv).s, fzh(:,i), "-", "Color", cT(i,:)); end
grid on;  ylabel("F_{z,hat} [N]");  title("Observed load per tire (dual track)");  legend(tireN, "Location", "eastoutside");  mark(a2);
a3 = nexttile(tl);  hold on
plot(laps(kv).s, D.bike_fz_model_f(I), "--", "Color", cSrc(3,:));  plot(laps(kv).s, D.bike_fz_f(I), "-", "Color", cSrc(3,:));
plot(laps(kv).s, D.bike_fz_model_r(I), "--", "Color", cSrc(2,:));  plot(laps(kv).s, D.bike_fz_r(I), "-", "Color", cSrc(2,:));
grid on;  ylabel("F_z [N]");  title("Axle load: load model (dashed) vs observed (bicycle)");
legend("front model", "front observed", "rear model", "rear observed", "Location", "eastoutside");  mark(a3);
xlabel(tl, "Distance along the lap [m]");
linkaxes([a1 a2 a3], "x");

% 5 vehicle model slip and v_y in the sim against the sim's localization
tl = newTab(tg, "Sim slips", 3, 1);
b1 = nexttile(tl);  hold on
plot(laps(kv).s, D.vy(I), "-", "Color", cRaw, "LineWidth", 1.4);  plot(laps(kv).s, D.bike_vy(I), "-", "Color", cSrc(2,:));
grid on;  ylabel("v_y [m/s]");  title("Lateral velocity: sim localization (grey) vs bicycle observer");  mark(b1);
b2 = nexttile(tl);  hold on
plot(laps(kv).s, r2d * D.bike_alpha_kin_f(I), "-", "Color", cRaw, "LineWidth", 1.4);  plot(laps(kv).s, r2d * D.bike_alpha_f(I), "-", "Color", cSrc(3,:));
grid on;  ylabel("\alpha_f [deg]");  title("Front axle slip: kinematic from localization (grey) vs observed");  mark(b2);
b3 = nexttile(tl);  hold on
plot(laps(kv).s, r2d * D.bike_alpha_kin_r(I), "-", "Color", cRaw, "LineWidth", 1.4);  plot(laps(kv).s, r2d * D.bike_alpha_r(I), "-", "Color", cSrc(2,:));
grid on;  ylabel("\alpha_r [deg]");  title("Rear axle slip: kinematic from localization (grey) vs observed");  mark(b3);
xlabel(tl, "Distance along the lap [m]");
linkaxes([b1 b2 b3], "x");

% 6 summary bars
tl = newTab(tg, "Summary", 2, 3);
mNames = ["lap time [s]", "", "|lateral error| rms [m]", "|lateral error| max [m]", "yaw rate error rms [rad/s]", ...
          "feedback steering rms [deg]", "steering rate rms [deg/s]", "median k_us used in corners"];
for p = [3 4 5 6 7 8]
    nexttile(tl);  hold on
    for k = 1:numel(laps)
        bar(k, laps(k).m(p), "FaceColor", laps(k).color);
    end
    xticks(1:numel(laps));  xticklabels("lap " + (1:numel(laps)));  grid on;  title(mNames(p));
end

tabs = tg.Children;
for k = 1:numel(tabs)
    tg.SelectedTab = tabs(k);
    drawnow;
    exportgraphics(tabs(k), fullfile(figDir, sprintf("%02d_%s.png", k, regexprep(tabs(k).Title, "[^A-Za-z0-9]+", "_"))), "Resolution", 130);
end
fprintf("figures written to %s\n", figDir);


%% local functions

function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact", "Padding", "compact");
end
