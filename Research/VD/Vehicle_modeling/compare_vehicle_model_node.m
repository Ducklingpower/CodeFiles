% compare_vehicle_model_node - the on-vehicle vehicle_model node against vehicle_model.m on the comp2 log
% 1 vehicle_model.m runs on its dataFile (comp2 merged CSV = rosbag2_merged_2026-09-03_121638), plots off
% 2 the node output CSV is read and interpolated onto the same time base (absolute time_s)
% 3 every output is scored (rms and p99 of node - MATLAB, best lag) and plotted, one tab per group
% making the node CSV (README section 2a, observer_block_diagrams.html section 7.6 phase 3):
%   ros2 bag play rosbag2_merged_2026-09-03_121638 --clock 200 (1x, input topics only), node with use_sim_time:=true
%   ros2 bag record --use-sim-time -s mcap /control/vehicle_model/bicycle/state /control/vehicle_model/bicycle/debug
%       /control/vehicle_model/dualtrack/state /control/vehicle_model/dualtrack/debug /control/vehicle_model/errors
%   python3 merge_rosbag2_folder_to_csv_v3.py -i <recording> -o <out> -t 0.01 --time-mode union
%       --topics-file vehicle_model_node_topics.yaml          (no -f: that filter is zero phase)
% the column names come from vehicle_model_node_topics.yaml; MATLAB NaN (not moving, observer off) is left out

setenv("VM_NO_PLOTS", "1");
run("vehicle_model.m");          % clears the workspace, then computes every package output on dataFile
setenv("VM_NO_PLOTS", "");

%% settings

nodeCsv = "/home/elijah/PurdueRacing/bags/lagoona/comp2/node_replay/rec_vehicle_model_node_merged.csv";   % converted recording
maxLag  = 0.5;    % (s) lag search range node vs MATLAB

%% node outputs on the MATLAB time base

N    = readtable(nodeCsv);
tAbs = data.time_s;                       % absolute time of the vehicle_model.m samples (bag time)
tN   = N.time_s;
fprintf("node CSV: %d rows, %.1f to %.1f s; MATLAB: %.1f to %.1f s (bag time)\n", height(N), tN(1), tN(end), tAbs(1), tAbs(end));

r2d = 180 / pi;
tireS = ["fl", "fr", "rl", "rr"];  tireN = ["FL", "FR", "RL", "RR"];
axS   = ["f", "r"];                axN   = ["front", "rear"];

% signal list: group, name, MATLAB value, node column, plot scale, unit, flag
S = struct("group", {}, "name", {}, "m", {}, "col", {}, "scale", {}, "unit", {}, "flag", {});
addSig  = @(S, g, nm, mv, col, sc, un) [S, struct("group", g, "name", nm, "m", double(mv), "col", col, "scale", sc, "unit", un, "flag", false)];
addFlag = @(S, g, nm, mv, col)         [S, struct("group", g, "name", nm, "m", double(mv), "col", col, "scale", 1,  "unit", "-", "flag", true)];

S = addSig(S, "Road wheel angles", "bicycle delta", delta, "bike_delta", r2d, "deg");
for i = 1:4, S = addSig(S, "Road wheel angles", "delta " + tireN(i), dW(:,i), "dual_delta_" + tireS(i), r2d, "deg"); end

aKinAx = [alpha_f, alpha_r];  sxAx = [sx_f, sx_r];
for a = 1:2, S = addSig(S, "Kinematic slip angles", "alpha " + axN(a), aKinAx(:,a), "bike_slip_angle_kin_" + axS(a), r2d, "deg"); end
for i = 1:4, S = addSig(S, "Kinematic slip angles", "alpha " + tireN(i), alphaKin(:,i), "dual_slip_angle_kin_" + tireS(i), r2d, "deg"); end

for a = 1:2, S = addSig(S, "Slip ratio s_x", "s_x " + axN(a), sxAx(:,a), "bike_slip_ratio_" + axS(a), 1, "-"); end
for i = 1:4, S = addSig(S, "Slip ratio s_x", "s_x " + tireN(i), sx4(:,i), "dual_slip_ratio_x_" + tireS(i), 1, "-"); end
for i = 1:4, S = addSig(S, "Slip ratio s_y, kappa", "s_y " + tireN(i), sy4(:,i), "dual_slip_ratio_y_" + tireS(i), 1, "-"); end
for i = 1:4, S = addSig(S, "Slip ratio s_y, kappa", "kappa " + tireN(i), kappa4(:,i), "dual_kappa_" + tireS(i), 1, "-"); end

for a = 1:2, S = addSig(S, "Normal load", "F_z model " + axN(a), Fz_bike_model(:,a), "bike_fz_model_" + axS(a), 1, "N"); end
for a = 1:2, S = addSig(S, "Normal load", "F_z observed " + axN(a), Fz_bike_obs(:,a), "bike_fz_obs_" + axS(a), 1, "N"); end
for i = 1:4, S = addSig(S, "Normal load", "F_z model " + tireN(i), Fz_dual_model(:,i), "dual_fz_model_" + tireS(i), 1, "N"); end
for i = 1:4, S = addSig(S, "Normal load", "F_z observed " + tireN(i), Fz_dual_obs(:,i), "dual_fz_obs_" + tireS(i), 1, "N"); end

FxAx = [Fxf, Fxr];  FyAx = [Fyf, Fyr];  FyNL = [Fy_fl, Fy_fr, Fy_rl, Fy_rr];  Fx4 = [Fx_fl, Fx_fr, Fx_rl, Fx_rr];
for a = 1:2, S = addSig(S, "Forces", "F_x " + axN(a), FxAx(:,a), "bike_fx_" + axS(a), 1, "N"); end
for i = 1:4, S = addSig(S, "Forces", "F_x " + tireN(i), Fx4(:,i), "dual_fx_" + tireS(i), 1, "N"); end
for a = 1:2, S = addSig(S, "Forces", "F_y " + axN(a), FyAx(:,a), "bike_fy_" + axS(a), 1, "N"); end
for i = 1:4, S = addSig(S, "F_y per tire", "F_y load split " + tireN(i), FyNL(:,i), "dual_fy_load_split_" + tireS(i), 1, "N"); end
for i = 1:4, S = addSig(S, "F_y per tire", "F_y corrected " + tireN(i), Fy_tm(:,i), "dual_fy_corrected_" + tireS(i), 1, "N"); end

aObsAx = [alpha_f_obs, alpha_r_obs];
S = addSig(S, "Observers", "v_y bicycle", vy_bike_obs, "bike_vy_obs", 1, "m/s");
S = addSig(S, "Observers", "v_y dual track", vy_dual_obs, "dual_vy_obs", 1, "m/s");
for a = 1:2, S = addSig(S, "Observers", "alpha observed " + axN(a), aObsAx(:,a), "bike_slip_angle_obs_" + axS(a), r2d, "deg"); end
for i = 1:4, S = addSig(S, "Observers", "alpha observed " + tireN(i), alpha_obs(:,i), "dual_slip_angle_obs_" + tireS(i), r2d, "deg"); end

S = addSig(S, "Understeer gradient", "k_us bicycle", k_us_bike, "bike_k_us", 1, "rad/(m/s^2)");
S = addSig(S, "Understeer gradient", "k_us dual track", k_us_dual, "dual_k_us", 1, "rad/(m/s^2)");

S = addSig(S, "Debug values", "bicycle v_y tire model", dbgB.vyTireModel, "bikedbg_vy_tire_model", 1, "m/s");
for a = 1:2, S = addSig(S, "Debug values", "brush slip " + axN(a), dbgB.brushSlip(:,a), "bikedbg_brush_slip_" + axS(a), r2d, "deg"); end
for a = 1:2, S = addSig(S, "Debug values", "conditioning " + axN(a), dbgB.conditioning(:,a), "bikedbg_conditioning_" + axS(a), 1, "-"); end
for i = 1:4, S = addSig(S, "Debug values", "conditioning " + tireN(i), dbgD.conditioning(:,i), "dualdbg_conditioning_" + tireS(i), 1, "-"); end

S = addFlag(S, "Debug flags", "bicycle moving", dbgB.moving, "bikedbg_moving");
S = addFlag(S, "Debug flags", "bicycle slip angle valid", dbgB.slipAngleValid, "bikedbg_slip_angle_valid");
for a = 1:2, S = addFlag(S, "Debug flags", "bicycle slip ratio valid " + axN(a), dbgB.slipRatioValid(:,a), "bikedbg_slip_ratio_valid_" + axS(a)); end
S = addFlag(S, "Debug flags", "bicycle observer running", dbgB.observerRunning, "bikedbg_observer_running");
S = addFlag(S, "Debug flags", "bicycle F_z observer active", dbgB.fzObserverActive, "bikedbg_fz_observer_active");
S = addFlag(S, "Debug flags", "bicycle k_us valid", dbgB.kusValid, "bikedbg_k_us_valid");
for a = 1:2, S = addFlag(S, "Debug flags", "bicycle saturated " + axN(a), dbgB.saturated(:,a), "bikedbg_saturated_" + axS(a)); end
S = addFlag(S, "Debug flags", "dual track moving", dbgD.moving, "dualdbg_moving");
S = addFlag(S, "Debug flags", "dual track observer running", dbgD.observerRunning, "dualdbg_observer_running");
S = addFlag(S, "Debug flags", "dual track F_z observer active", dbgD.fzObserverActive, "dualdbg_fz_observer_active");
S = addFlag(S, "Debug flags", "dual track k_us valid", dbgD.kusValid, "dualdbg_k_us_valid");
for i = 1:4
    S = addFlag(S, "Debug flags", "slip angle valid " + tireN(i), dbgD.slipAngleValid(:,i), "dualdbg_slip_angle_valid_" + tireS(i));
    S = addFlag(S, "Debug flags", "slip ratio valid " + tireN(i), dbgD.slipRatioValid(:,i), "dualdbg_slip_ratio_valid_" + tireS(i));
    S = addFlag(S, "Debug flags", "lifted " + tireN(i), dbgD.lifted(:,i), "dualdbg_lifted_" + tireS(i));
    S = addFlag(S, "Debug flags", "locked " + tireN(i), dbgD.locked(:,i), "dualdbg_locked_" + tireS(i));
    S = addFlag(S, "Debug flags", "saturated " + tireN(i), dbgD.saturated(:,i), "dualdbg_saturated_" + tireS(i));
end

%% score every signal: node - MATLAB where both are finite, best lag within +/- maxLag

nLag = round(maxLag / Ts);
for k = 1:numel(S)
    S(k).found = any(string(N.Properties.VariableNames) == S(k).col);
    S(k).n = nan(numel(tAbs), 1);
    if ~S(k).found
        S(k).ok = false(numel(tAbs), 1);  S(k).rmsD = NaN;  S(k).p99 = NaN;  S(k).rel = NaN;  S(k).lag = NaN;  S(k).rmsLag = NaN;  S(k).dis = NaN;
        continue
    end
    if S(k).flag
        S(k).n = interp1(tN, N.(S(k).col), tAbs, "previous", NaN);
    else
        S(k).n = interp1(tN, N.(S(k).col), tAbs, "linear", NaN);
    end
    S(k).ok = isfinite(S(k).m) & isfinite(S(k).n);
    d = S(k).n(S(k).ok) - S(k).m(S(k).ok);
    if S(k).flag
        S(k).dis = 100 * mean(d ~= 0);
        S(k).rmsD = NaN;  S(k).p99 = NaN;  S(k).rel = NaN;  S(k).lag = NaN;  S(k).rmsLag = NaN;
        continue
    end
    S(k).dis  = NaN;
    S(k).rmsD = rms(d);
    S(k).p99  = prctile(abs(d), 99);
    S(k).rel  = S(k).rmsD / max(rms(S(k).m(S(k).ok)), eps);
    mk = S(k).m;  nk = S(k).n;  mk(~S(k).ok) = NaN;  nk(~S(k).ok) = NaN;
    [kLag, S(k).rmsLag] = bestLag(mk, nk, nLag);
    S(k).lag  = kLag * Ts;
end

fprintf("\n%-24s %-32s %8s %12s %12s %9s %8s %12s\n", "group", "signal", "samples", "rms diff", "p99 |diff|", "rms/rms", "lag (s)", "rms at lag");
for k = 1:numel(S)
    if ~S(k).found
        fprintf("%-24s %-32s   column %s not in the node CSV\n", S(k).group, S(k).name, S(k).col);
    elseif S(k).flag
        fprintf("%-24s %-32s %8d   disagree %.3f %% of samples\n", S(k).group, S(k).name, nnz(S(k).ok), S(k).dis);
    else
        fprintf("%-24s %-32s %8d %12.4g %12.4g %9.4f %8.3f %12.4g\n", S(k).group, S(k).name, nnz(S(k).ok), ...
            S(k).rmsD * S(k).scale, S(k).p99 * S(k).scale, S(k).rel, S(k).lag, S(k).rmsLag * S(k).scale);
    end
end

%% node accuracy against the references, the same scores vehicle_model.m prints

nodeOf = @(name) S(string({S.name}) == name).n;
vyB = nodeOf("v_y bicycle");  vyD = nodeOf("v_y dual track");
okB = obsOkB & isfinite(vyB);  okD = obsOkD & isfinite(vyD);
fprintf("\nv_y rms vs the localization (v > %g m/s): node bicycle %.3f, dual track %.3f m/s; vehicle_model.m %.3f, %.3f\n", obs.vMin, ...
    rms(vyB(okB) - Fvy(okB)), rms(vyD(okD) - Fvy(okD)), rms(vy_bike_obs(okB) - Fvy(okB)), rms(vy_dual_obs(okD) - Fvy(okD)));
kB = nodeOf("k_us bicycle");     kB(~kusOkB) = NaN;
kD = nodeOf("k_us dual track");  kD(~kusOkD) = NaN;
fprintf("k_us median |k - measured| (|vx r| > %g): node bicycle %.5f, dual track %.5f; vehicle_model.m %.5f, %.5f\n\n", obs.kAyMin, ...
    median(abs(kB - k_us_meas), "omitnan"), median(abs(kD - k_us_meas), "omitnan"), ...
    median(abs(k_us_bike - k_us_meas), "omitnan"), median(abs(k_us_dual - k_us_meas), "omitnan"));

%% plots, one window, one tab per group

cMat  = [1 1 1];              % white, vehicle_model.m
cNode = [0.93 0.69 0.13];     % yellow, node
cDiff = [0.85 0.33 0.10];     % orange, node - MATLAB
cRaw  = [0.75 0.75 0.75];     % grey, corner marks

fig = figure("Name", "vehicle_model node vs vehicle_model.m", "Position", [50 50 1600 1100]);
tg  = uitabgroup(fig);
tRel = tAbs - tAbs(1);

% tab: summary
cont = find([S.found] & ~[S.flag]);
flg  = find([S.found] &  [S.flag]);
tl = newTab(tg, "Summary", 1, 2);
nexttile(tl);
barh(max([S(cont).rel], 1e-6), "FaceColor", cNode);
set(gca, "XScale", "log", "YTick", 1:numel(cont), "YTickLabel", [S(cont).name], "YDir", "reverse", "FontSize", 7);
grid on
xlabel("rms(node - MATLAB) / rms(MATLAB)");
title("Continuous outputs");
nexttile(tl);
barh([S(flg).dis], "FaceColor", cDiff);
set(gca, "YTick", 1:numel(flg), "YTickLabel", [S(flg).name], "YDir", "reverse", "FontSize", 7);
grid on
xlabel("samples where the flags disagree [%]");
title("Debug flags");

% one tab per group: overlay (left) and difference (right) for each signal
groups = unique(string({S([S.found]).group}), "stable");
for g = groups
    ks = find(string({S.group}) == g & [S.found]);
    tl = newTab(tg, g, numel(ks), 2);
    axG = gobjects(numel(ks), 2);
    for j = 1:numel(ks)
        k = ks(j);
        axG(j,1) = nexttile(tl);
        hold on
        if S(k).flag
            stairs(tRel, S(k).m, "-", "Color", cMat, "LineWidth", 1.5);
            stairs(tRel, S(k).n, "-", "Color", cNode);
            ylim([-0.2 1.2]);
        else
            plot(tRel, S(k).m * S(k).scale, "-", "Color", cMat, "LineWidth", 1.5);
            plot(tRel, S(k).n * S(k).scale, "-", "Color", cNode);
        end
        grid on
        ylabel(S(k).unit);
        title(S(k).name, "FontSize", 8);
        if j == 1, legend("vehicle\_model.m", "node", "Location", "northwest"); end
        axG(j,2) = nexttile(tl);
        dk = S(k).n - S(k).m;  dk(~S(k).ok) = NaN;
        plot(tRel, dk * S(k).scale, "-", "Color", cDiff);
        grid on
        ylabel(S(k).unit);
        if S(k).flag
            title(sprintf("node - MATLAB, disagree %.3f %%", S(k).dis), "FontSize", 8);
        else
            title(sprintf("node - MATLAB, rms %.3g (%.3g at the best lag %.3f s)", S(k).rmsD * S(k).scale, S(k).rmsLag * S(k).scale, S(k).lag), "FontSize", 8);
        end
    end
    xlabel(tl, "Time [s]");
    linkaxes(axG(:), "x");
end

% tab: fastest lap, the main outputs with the corners marked
lapWin = fastestLap(t, px, py, Fvx, lapRef);
lap    = t >= lapWin(1) & t <= lapWin(2);
tLap   = t(lap) - lapWin(1);
tTurn  = zeros(numel(turnNames), 1);
for c = 1:numel(turnNames)
    [~, j] = min(hypot(px(lap) - turnXY(c,1), py(lap) - turnXY(c,2)));
    tTurn(c) = tLap(j);
end
lapNames = ["v_y bicycle", "v_y dual track", "alpha observed front", "alpha observed FL", "F_z observed FL", ...
            "F_z observed FR", "k_us bicycle", "k_us dual track"];
tl = newTab(tg, "Fastest lap", numel(lapNames), 1);
axL = gobjects(numel(lapNames), 1);
for j = 1:numel(lapNames)
    k = find(string({S.name}) == lapNames(j), 1);
    axL(j) = nexttile(tl);
    hold on
    if ~isempty(k) && S(k).found
        plot(tLap, S(k).m(lap) * S(k).scale, "-", "Color", cMat, "LineWidth", 1.5);
        plot(tLap, S(k).n(lap) * S(k).scale, "-", "Color", cNode);
        ylabel(S(k).unit);
    end
    grid on
    title(lapNames(j), "FontSize", 8);
    if j == 1, legend("vehicle\_model.m", "node", "Location", "eastoutside"); end
    xline(tTurn, ":", "Color", cRaw, "HandleVisibility", "off");
end
xline(axL(1), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xlabel(tl, "time in lap [s]");
linkaxes(axL, "x");
xlim(axL(1), [0 diff(lapWin)]);
title(tl, sprintf("node vs vehicle\\_model.m, fastest lap %.1f s", diff(lapWin)));


function [k, best] = bestLag(m, n, nLag)
% shift of the node series (samples) that minimises rms(node - MATLAB), + = node lags; ties keep the smaller shift

    best = inf;  k = 0;
    for s = [0, reshape([1:nLag; -(1:nLag)], 1, [])]
        if s >= 0
            d = n(1+s:end) - m(1:end-s);
        else
            d = n(1:end+s) - m(1-s:end);
        end
        e = rms(d(isfinite(d)));
        if e < best * (1 - 1e-9), best = e;  k = s; end
    end
end


function win = fastestLap(t, px, py, v, ref)
% laps timed between passes of the reference point (within 20 m, moving), the fastest complete lap [start end] (s)

    near = hypot(px - ref(1), py - ref(2)) < 20 & v > 5;
    tp   = t(diff([0; near]) == 1);
    tp   = tp([true; diff(tp) > 40]);
    [~, j] = min(diff(tp));
    win  = [tp(j), tp(j+1)];
end


function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact");
end
