clc
close all
clear
% analyze_sim_kus_fast - sim test of the fbl_mpc k_us switch at race pace (2026-10-06 14:36 run):
% speed scale 0.80 and 0.85, one lap each with the MPC's own k_us, the vehicle model bicycle k_us and the
% vehicle model dual track k_us, laps aligned on Frenet s (/planning/current_frenet_s)
% each scale is compared only over the Frenet s window where every lap had its intended source and the same scale
% colors: MPC own black, bicycle blue, dual track red, raw / reference grey

%% settings

csvFile = "/home/elijah/PurdueRacing/bags/sim_kus_test/sim_kus_2026-10-06_143608_csv/2026-10-06_143608_merged.csv";
figDir  = "/home/elijah/code/CodeFiles/Research/VD/Vehicle_modeling/sim_kus_fast_figs";

% laps (time from the start of the recording, s) and the Frenet s window compared for each scale
%          t0     t1     scale  source (0 MPC, 1 bicycle, 2 dual track)
lapTab = [ 109.9  217.3  0.80   0
           217.3  324.2  0.80   1
           324.2  431.0  0.80   2
           431.1  532.0  0.85   2
           532.0  633.0  0.85   1
           633.0  733.9  0.85   0 ];
sWin   = containers.Map({'0.80', '0.85'}, {[0 3378], [352 3388]});

% Laguna Seca corners by position (odom x, y in m), placed on Frenet s from the first lap
turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];

srcNames = ["MPC own", "VM bicycle", "VM dual track"];
cSrc     = [0.10 0.10 0.10; 0.10 0.35 0.85; 0.85 0.10 0.10];
cRaw     = [0.62 0.62 0.62];
r2d      = 180 / pi;

%% load

D = readtable(csvFile);
t = D.time_s - D.time_s(1);
for c = ["frenet_s", "kus_src", "speed_scale", "kus_used", "kus_mpc", "kus_bike", "kus_dual", "steer_cmd_deg", "steer_fb", "r_des", "lat_err"]
    D.(c) = fillmissing(D.(c), "previous");
end

% corners on Frenet s
I1 = t >= lapTab(1,1) & t < lapTab(1,2);
sTurn = nan(numel(turnNames), 1);
for c = 1:numel(turnNames)
    d2 = hypot(D.px - turnXY(c,1), D.py - turnXY(c,2));  d2(~I1) = inf;
    [dmin, j] = min(d2);
    if dmin < 40, sTurn(c) = D.frenet_s(j); end
end

% Frenet s grid (1 m) per lap, only the samples with the lap's intended source and scale
sg = (0:1:3597)';
fields = ["vx", "ay", "kus_used", "kus_mpc", "kus_bike", "kus_dual", "lat_err", "steer_cmd_deg", "steer_fb", "r_des", "wz", ...
          "bike_alpha_f", "bike_alpha_r", "bike_alpha_kin_f", "bike_alpha_kin_r"];
laps = struct([]);
for k = 1:size(lapTab, 1)
    I  = find(t >= lapTab(k,1) & t < lapTab(k,2));
    ok = round(D.kus_src(I)) == lapTab(k,4) & abs(D.speed_scale(I) - lapTab(k,3)) < 0.002 & D.frenet_s(I) > 0;
    I  = I(ok);
    [s, iu] = unique(D.frenet_s(I));  I = I(iu);
    laps(k).scale = lapTab(k,3);  laps(k).src = lapTab(k,4);  laps(k).t = t(I);
    laps(k).name  = sprintf("%.2f %s", lapTab(k,3), srcNames(lapTab(k,4) + 1));
    for f = fields
        laps(k).(f) = interp1(s, D.(f)(I), sg, "linear", NaN);
    end
    laps(k).r_err = laps(k).r_des - laps(k).wz;
    laps(k).steer_rate = gradient(interp1(t(I), D.steer_cmd_deg(I), t(I), "previous"), t(I));
    laps(k).steer_rate_s = interp1(s, laps(k).steer_rate, sg, "linear", NaN);
end

%% metrics over each scale's common window

fprintf("\n%-20s %10s %9s %9s %10s %10s %11s %11s %11s %9s\n", "lap", "window s", "|e| rms", "|e| max", "r err rms", "fb steer", "steer rate", "k_us med", "k_us max", "a_y max");
for k = 1:numel(laps)
    w  = sWin(sprintf("%.2f", laps(k).scale));
    in = sg >= w(1) & sg <= w(2);
    cor = in & abs(laps(k).vx .* laps(k).wz) > 4;
    laps(k).m = [rms(laps(k).lat_err(in), "omitnan"), max(abs(laps(k).lat_err(in))), rms(laps(k).r_err(in), "omitnan"), ...
                 rms(laps(k).steer_fb(in), "omitnan") * r2d, rms(laps(k).steer_rate_s(in), "omitnan"), ...
                 median(laps(k).kus_used(cor), "omitnan"), max(laps(k).kus_used(in)), max(abs(laps(k).ay(in)))];
    fprintf("%-20s %4.0f-%4.0f %9.3f %9.3f %10.4f %10.3f %11.2f %11.5f %11.5f %9.1f\n", laps(k).name, w, laps(k).m);
end
fprintf("lateral error (m), yaw rate error r_des - r (rad/s), yaw rate feedback steering (deg road wheel rms), steering command rate (deg/s rms),\n");
fprintf("k_us used: median where |vx r| > 4 and max (rad/(m/s^2)), max |a_y| (m/s^2), all inside the window\n");

%% figures

if ~exist(figDir, "dir"), mkdir(figDir); end
fig = figure("Name", "Sim k_us switch test at race pace", "Position", [40 40 1600 1000]);
theme(fig, "light");
tg = uitabgroup(fig);
mark = @(ax) xline(ax, sTurn(isfinite(sTurn)), ":", turnNames(isfinite(sTurn)), "Color", [0.45 0.45 0.45], ...
    "LabelVerticalAlignment", "top", "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");

for scale = [0.80 0.85]
    K = find([laps.scale] == scale);
    w = sWin(sprintf("%.2f", scale));

    % overlay: speed, a_y, k_us used, lateral error, steering, feedback steering
    tl = newTab(tg, sprintf("%.2f laps", scale), 6, 1);
    ax = gobjects(6,1);
    pf = ["vx", "ay", "kus_used", "lat_err", "steer_cmd_deg", "steer_fb"];
    yl = ["v_x [m/s]", "a_y [m/s^2]", "k_{us} used", "lateral error [m]", "steering cmd [deg]", "fb steering [deg]"];
    tt = ["Speed", "Lateral acceleration", "Understeer gradient the MPC used", "MPC lateral error", ...
          "Steering wheel command", "Yaw rate feedback steering (road wheel)"];
    for p = 1:6
        ax(p) = nexttile(tl);  hold on
        for k = K
            y = laps(k).(pf(p));  if pf(p) == "steer_fb", y = y * r2d; end
            plot(sg, y, "-", "Color", cSrc(laps(k).src + 1, :), "LineWidth", 1.1, "DisplayName", srcNames(laps(k).src + 1));
        end
        xregion(ax(p), [0 w(1)], "FaceColor", [0.9 0.9 0.9], "HandleVisibility", "off");
        xregion(ax(p), [w(2) 3597], "FaceColor", [0.9 0.9 0.9], "HandleVisibility", "off");
        grid on;  ylabel(yl(p));  title(tt(p) + sprintf(" (scale %.2f, grey = outside the compared window)", scale));  mark(ax(p));
    end
    legend(ax(1), "Location", "eastoutside");
    xlabel(tl, "Frenet s [m]");  linkaxes(ax, "x");  xlim(ax(1), [0 3597]);

    % k_us candidates on each lap
    tl = newTab(tg, sprintf("%.2f k_us candidates", scale), numel(K), 1);
    for k = K
        a = nexttile(tl);  hold on
        plot(sg, laps(k).kus_mpc, "-", "Color", cSrc(1,:));
        plot(sg, laps(k).kus_bike, "-", "Color", cSrc(2,:));
        plot(sg, laps(k).kus_dual, "-", "Color", cSrc(3,:));
        plot(sg, laps(k).kus_used, ":", "Color", [0.9 0.6 0], "LineWidth", 2);
        yline(0.0012, ":", "old clamp 0.0012", "Color", cRaw);
        grid on;  ylabel("k_{us}");  title(laps(k).name + " in use (dotted orange = used)");  mark(a);
    end
    legend(nexttile(tl, 1), "MPC own", "VM bicycle", "VM dual track", "used", "Location", "eastoutside");
    xlabel(tl, "Frenet s [m]");
end

% observer slip vs the sim's own kinematic slip (0.85 bicycle lap)
kb = find([laps.scale] == 0.85 & [laps.src] == 1, 1);
tl = newTab(tg, "Sim slips", 2, 1);
b1 = nexttile(tl);  hold on
plot(sg, r2d * laps(kb).bike_alpha_kin_f, "-", "Color", cRaw, "LineWidth", 1.4);
plot(sg, r2d * laps(kb).bike_alpha_f, "-", "Color", cSrc(3,:));
grid on;  ylabel("\alpha_f [deg]");  title("Front axle slip: sim localization kinematic (grey) vs vehicle model observed, 0.85 bicycle lap");  mark(b1);
b2 = nexttile(tl);  hold on
plot(sg, r2d * laps(kb).bike_alpha_kin_r, "-", "Color", cRaw, "LineWidth", 1.4);
plot(sg, r2d * laps(kb).bike_alpha_r, "-", "Color", cSrc(2,:));
grid on;  ylabel("\alpha_r [deg]");  title("Rear axle slip: sim localization kinematic (grey) vs vehicle model observed");  mark(b2);
xlabel(tl, "Frenet s [m]");  linkaxes([b1 b2], "x");

% summary bars
tl = newTab(tg, "Summary", 2, 3);
mNames = ["|lateral error| rms [m]", "|lateral error| max [m]", "yaw rate error rms [rad/s]", ...
          "feedback steering rms [deg]", "steering rate rms [deg/s]", "median k_us used in corners"];
for p = 1:6
    nexttile(tl);  hold on
    for k = 1:numel(laps)
        bar(k, laps(k).m(p), "FaceColor", cSrc(laps(k).src + 1, :));
    end
    xticks(1:numel(laps));  xticklabels([laps.name]);  xtickangle(30);  grid on;  title(mNames(p));
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
