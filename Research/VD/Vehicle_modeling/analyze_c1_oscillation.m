clc
close all
clear
% analyze_c1_oscillation - why the steering oscillates through C1 in the sim at race pace
% passes through C1 (Frenet s 0 to 450) with the vehicle model bicycle k_us at speed scale 0.80, 0.95 and 1.00 overlaid,
% plus the MPC's own k_us pass that left the track at 0.85 (k_ay_min 4 run)
% data: the sim runs merged with sim_c1_topics.yaml
% colors: 0.80 green, 0.95 orange, 1.00 red, MPC own at 0.85 (left the track) black, raw / reference grey

%% settings

csvNew = "/home/elijah/PurdueRacing/bags/sim_kus_test/sim_kus_2026-10-06_150618_kay0p1_c1csv/sim_kus_2026-10-06_150618_kay0p1_merged.csv";
csvOld = "/home/elijah/PurdueRacing/bags/sim_kus_test/sim_kus_2026-10-06_143608_c1csv/2026-10-06_143608_merged.csv";
figDir = "/home/elijah/code/CodeFiles/Research/VD/Vehicle_modeling/c1_oscillation_figs";

% passes: CSV, start time (s from the start of the recording, the pass begins at the first Frenet s < 450 after it), label
passes = {csvNew,  229, "0.80 VM bicycle";
          csvNew,  823, "0.95 VM bicycle";
          csvNew, 1367, "1.00 VM bicycle";
          csvOld,  733, "0.85 MPC own (left the track)"};
cP   = [0.20 0.60 0.20; 0.95 0.55 0.10; 0.85 0.10 0.10; 0.10 0.10 0.10];
cRaw = [0.62 0.62 0.62];
sMax = 450;
r2d  = 180 / pi;

%% passes on Frenet s

P = struct([]);
cache = containers.Map();
for k = 1:size(passes, 1)
    f = passes{k,1};
    if ~isKey(cache, f)
        D = readtable(f);
        D = fillmissing(D, "previous");
        D.t = D.time_s - D.time_s(1);
        cache(f) = D;
    end
    D = cache(f);
    i0 = find(D.t >= passes{k,2} & D.frenet_s > 0 & D.frenet_s < 60, 1);
    I  = i0 - 1 + find(D.frenet_s(i0:min(i0 + 2500, height(D))) < sMax & D.frenet_s(i0:min(i0 + 2500, height(D))) > 0);
    gap = find(diff(I) > 1, 1);                                                        % first contiguous run
    if ~isempty(gap), I = I(1:gap); end
    e  = find(abs(D.lat_err(I)) > 3, 1);   if ~isempty(e), I = I(1:e); end            % stop at the track exit
    P(k).name = passes{k,3};  P(k).s = D.frenet_s(I);  P(k).t = D.t(I) - D.t(I(1));
    P(k).vx = D.vx(I);  P(k).ax = movmean(D.ax(I), 10);  P(k).ay = D.ay(I);
    P(k).r = D.wz(I);  P(k).r_des = D.r_des(I);
    P(k).fz = D.dual_fz_fl(I) + D.dual_fz_fr(I) + D.dual_fz_rl(I) + D.dual_fz_rr(I);
    P(k).fz_f = D.dual_fz_fl(I) + D.dual_fz_fr(I);  P(k).fz_r = D.dual_fz_rl(I) + D.dual_fz_rr(I);
    P(k).gage = D.gage_fl(I) + D.gage_fr(I) + D.gage_rl(I) + D.gage_rr(I);
    P(k).p_front = D.p_front(I);  P(k).throttle = D.throttle(I);
    P(k).steer = D.steer_cmd_deg(I);  P(k).fb = D.steer_fb(I) * r2d;
    P(k).kus = D.kus_used(I);
    P(k).sx = min([D.sx_fl(I), D.sx_fr(I), D.sx_rl(I), D.sx_rr(I)], [], 2);
    P(k).a_f = D.bike_alpha_kin_f(I) * r2d;  P(k).a_r = D.bike_alpha_kin_r(I) * r2d;
    P(k).lat_err = D.lat_err(I);
end

% oscillation frequency of the feedback steering (zero crossings after the brakes come on)
for k = 1:numel(P)
    w = P(k).s > 230 & P(k).s < 400;
    x = P(k).fb(w) - mean(P(k).fb(w));
    zc = find(diff(sign(x)) ~= 0);
    if numel(zc) > 3
        P(k).f_osc = (numel(zc) - 1) / 2 / (P(k).t(find(w, 1) - 1 + zc(end)) - P(k).t(find(w, 1) - 1 + zc(1)));
    else
        P(k).f_osc = NaN;
    end
    fprintf("%-30s oscillation %.2f Hz, feedback steering std %.2f deg (s 230-400)\n", P(k).name, P(k).f_osc, std(P(k).fb(w)));
end

%% figure

if exist(figDir, "dir"), delete(fullfile(figDir, "*.png")); else, mkdir(figDir); end
fig = figure("Name", "C1 oscillation", "Position", [40 40 1600 1100]);
theme(fig, "light");
tg = uitabgroup(fig);

rowsA = {"vx", "v_x [m/s]", "Speed";
         "fz", "\Sigma F_{z} [N]", "Total observed normal load (raw gage sum grey): the crest before C1";
         "p_front", "front brake [kPa]", "Front brake pressure";
         "ax", "a_x [m/s^2]", "Longitudinal acceleration";
         "sx", "min s_x [-]", "Most negative wheel slip ratio (a lockup is < -0.2)"};
rowsB = {"ay", "a_y [m/s^2]", "Lateral acceleration";
         "r", "r [rad/s]", "Yaw rate (dashed: MPC desired)";
         "fb", "fb steering [deg]", "Yaw rate feedback steering (road wheel)";
         "steer", "steering cmd [deg]", "Steering wheel command";
         "kus", "k_{us} used", "Understeer gradient the MPC used";
         "a_r", "\alpha_r [deg]", "Rear axle slip angle (sim localization kinematics)"};

for tab = 1:2
    rows = ternary(tab == 1, rowsA, rowsB);
    tl = newTab(tg, ternary(tab == 1, "Crest and braking", "Yaw response"), size(rows, 1), 1);
    ax = gobjects(size(rows, 1), 1);
    for p = 1:size(rows, 1)
        ax(p) = nexttile(tl);  hold on
        for k = 1:numel(P)
            if rows{p,1} == "fz", plot(P(k).s, P(k).gage, "-", "Color", [cRaw 0.35], "HandleVisibility", "off"); end
            plot(P(k).s, P(k).(rows{p,1}), "-", "Color", cP(k,:), "LineWidth", 1.2, "DisplayName", P(k).name);
            if rows{p,1} == "r", plot(P(k).s, P(k).r_des, "--", "Color", cP(k,:), "HandleVisibility", "off"); end
        end
        grid on;  ylabel(rows{p,2});  title(rows{p,3});
        xline(ax(p), 190, ":", "C1", "Color", [0.45 0.45 0.45], "HandleVisibility", "off");
    end
    legend(ax(1), "Location", "eastoutside");
    xlabel(tl, "Frenet s [m]");  linkaxes(ax, "x");  xlim(ax(1), [0 sMax]);
end

tabs = tg.Children;
for k = 1:numel(tabs)
    tg.SelectedTab = tabs(k);
    drawnow;
    exportgraphics(tabs(k), fullfile(figDir, sprintf("%02d_%s.png", k, regexprep(tabs(k).Title, "[^A-Za-z0-9]+", "_"))), "Resolution", 130);
end
fprintf("figures written to %s\n", figDir);


%% local functions

function v = ternary(c, a, b)
% a if c, else b

    if c, v = a; else, v = b; end
end


function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact", "Padding", "compact");
end
