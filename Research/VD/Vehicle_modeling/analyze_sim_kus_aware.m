clc
close all
clear
% analyze_sim_kus_aware - sim comparison of the fbl_mpc controllers (branch Elijah-MPC-undertseer-coef):
%   native MPC with its own k_us, with the vehicle model bicycle k_us, with the vehicle model dual track k_us
%   (base station "k_us source"), and the K_us aware bicycle / dual track model MPCs (base station "MPC model")
% laps aligned on Frenet s (/planning/current_frenet_s) and found automatically (Frenet s wrap, majority combination
% and speed scale); each scale is compared only over the Frenet s range every one of its laps covers; a lap that leaves
% the track (|lateral error| > offTrack) is kept up to that point and the range ends there
% data: the bag in bags/sim_kus_aware_test merged with sim_kus_aware_topics.yaml
% vehicle model k_us vs predicted: the vehicle_model package's bicycle / dual track k_us (where its k_us_valid is true)
% against the same models at the measured state on every moving sample, and against the law's plan K_us
% K_us measured vs model: the bicycle (S3) and dual track (S9b) tire models of fbl_mpc_controller kus_aware, ported below
% and checked against the spec test vectors, evaluated at the measured state of every sample where the learner's level
% gate passes (v >= 15, |a_t| >= 5, quasi steady): measured K_us = (delta(t - 0.08) - L r / v - b_hat) / a_t (learner)
% colors: native black / light blue / light red, bicycle model MPC blue, dual track model MPC red

%% settings

csvFile  = "/home/elijah/PurdueRacing/bags/sim_kus_aware_test/sim_kus_aware_2026-10-08_152743_vm_csv/2026-10-08_152743_merged.csv";
figDir   = "/home/elijah/code/CodeFiles/Research/VD/Vehicle_modeling/sim_kus_aware_figs";
runLabel = "K_{us} aware MPC";
offTrack = 3;      % (m) lateral error that counts as off the track
offPad   = 50;     % (m) Frenet s compared before the off track point
plotScales = [];   % speed scales analyzed and plotted (empty: all)
mapFile  = "/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/control/fbl_mpc_controller/config/laguna_sim_track_map.csv";

% K_us aware model parameters (fbl_mpc_controller config/param.yaml, KusAware.*)
P = struct("m", 815, "L", 2.9718, "lf", 1.724, "lr", 1.248, "h", 0.35, "cla", 0.58, "af", 0.33, "rho", 1.225, ...
           "muF", 1.6, "muR", 1.6, "caF", 174000, "caR", 290000, "gF", 105.2836, "gR", 73.9660, "pF", 0.85, "pR", 0.90, ...
           "fzRefF", 1628, "fzRefR", 2307.5, "tF", 1.638762, "cL", 0.9928, "cR", 1.0072, "fzMin", 100, "aFloor", 2, ...
           "kusMin", 0, "kusMax", 0.0015, "learnHz", 2, "dt", 0.01);
checkModels(P);

turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];

% combination code: 0..2 native MPC with k_us source 0..2, 3 bicycle model MPC, 4 dual track model MPC
comboNames = ["native, MPC k_us", "native, VM bicycle k_us", "native, VM dual k_us", "bicycle model MPC", "dual track model MPC"];
cCombo     = [0.10 0.10 0.10; 0.45 0.65 1.00; 1.00 0.55 0.55; 0.10 0.30 0.85; 0.80 0.10 0.10];
lwCombo    = [1.1 1.1 1.1 1.6 1.6];
cRaw       = [0.62 0.62 0.62];
r2d        = 180 / pi;
sg         = (0:1:3600)';

%% laps

[laps, sTurn] = findLaps(csvFile, offTrack, sg, turnXY, turnNames, comboNames, P, mapFile);
if ~isempty(plotScales)
    laps = laps(ismember(round([laps.scale] * 100), round(plotScales * 100)));
end
scales = unique([laps.scale]);
fprintf("%d laps\n", numel(laps));

% per scale comparison range (common Frenet s coverage, ends offPad before an off track point)
win = zeros(numel(scales), 2);
for q = 1:numel(scales)
    K = find([laps.scale] == scales(q));
    win(q,:) = [max([laps(K).s0]), min([laps(K).s1])];
    for k = K
        if isfinite(laps(k).sOff), win(q,2) = min(win(q,2), laps(k).sOff - offPad); end
    end
end

fprintf("\n%-34s %10s %8s %8s %9s %8s %10s %10s %10s %7s %8s %8s\n", "lap", "window s", "|e| rms", "|e| max", "r err rms", ...
        "fb steer", "steer rate", "k_us med", "k_us max", "|a_y|", "pred 0.3", "pred 0.6");
for q = 1:numel(scales)
    for k = find([laps.scale] == scales(q))
        laps(k).m = lapMetrics(laps(k), sg, win(q,:));
        fprintf("%-34s %4.0f-%4.0f %8.3f %8.3f %9.4f %8.3f %10.2f %10.5f %10.5f %7.1f %8.3f %8.3f%s\n", laps(k).name, win(q,:), laps(k).m, ...
            ternary(isfinite(laps(k).sOff), sprintf("  OFF TRACK at s %.0f", laps(k).sOff), ""));
    end
end
fprintf("lateral error (m), yaw rate error r_des - r (rad/s), yaw rate feedback steering (deg road wheel rms), steering command rate (deg/s rms),\n");
fprintf("k_us the steering law used: median where |vx r| > 0.1 and max, max |a_y| (m/s^2),\n");
fprintf("pred: rms of the rollout's predicted lateral error at knot 5 / 10 minus the lateral error 0.3 / 0.6 s later (m), all inside the scale's window\n");

%% figures

if exist(figDir, "dir"), delete(fullfile(figDir, "*.png")); else, mkdir(figDir); end
fig = figure("Name", "Sim K_us aware MPC comparison", "Position", [40 40 1600 1000]);
theme(fig, "light");
tg = uitabgroup(fig);
mark = @(ax) xline(ax, sTurn(isfinite(sTurn)), ":", turnNames(isfinite(sTurn)), "Color", [0.45 0.45 0.45], ...
    "LabelVerticalAlignment", "top", "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
shade = @shadeOutside;

% main comparison, one figure per scale: total observed normal load, steering, k_us of the law, lateral error
for q = 1:numel(scales)
    K = find([laps.scale] == scales(q));
    pf = ["fz_total", "steer_cmd_deg", "kus_law", "lat_err"];
    yl = ["\Sigma F_{z,hat} [N]", "steering cmd [deg]", "k_{us} law", "lateral error [m]"];
    tt = ["Total observed normal load (dual track, sum of the four tires)", "Steering command (road wheel)", ...
          "Understeer gradient the steering law used", "MPC lateral error"];
    ax = lapTiles(newTab(tg, sprintf("%.2f main compare", scales(q)), 4, 1), laps(K), pf, yl, tt, sg, cCombo, lwCombo, comboNames, win(q,:), shade, mark);
    ylim(ax(4), [-2 2]);
    title(ax(1).Parent, sprintf("%s, speed scale %.2f (grey = outside the compared window)", runLabel, scales(q)));
end

% metrics against speed scale, one line per combination
tl = newTab(tg, "Summary vs scale", 2, 4);
mNames = ["|lateral error| rms [m]", "|lateral error| max [m]", "yaw rate error rms [rad/s]", "yaw rate feedback steering rms [deg]", ...
          "steering command rate rms [deg/s]", "max k_us law [rad/(m/s^2)]", "prediction error 0.3 s rms [m]", "prediction error 0.6 s rms [m]"];
mIdx = [1 2 3 4 5 7 9 10];
for p = 1:numel(mIdx)
    nexttile(tl);  hold on
    for cb = unique([laps.combo])
        K = find([laps.combo] == cb);
        [~, o] = sort([laps(K).scale]);  K = K(o);
        y = arrayfun(@(k) laps(k).m(mIdx(p)), K);
        plot([laps(K).scale], y, "-o", "Color", cCombo(cb+1,:), "MarkerFaceColor", cCombo(cb+1,:), "LineWidth", 1.4, "DisplayName", comboNames(cb+1));
        off = isfinite([laps(K).sOff]);
        plot([laps(K(off)).scale], y(off), "x", "Color", cCombo(cb+1,:), "MarkerSize", 14, "LineWidth", 2.5, "HandleVisibility", "off");
    end
    grid on;  xlabel("speed scale");  title(mNames(p));
end
legend(nexttile(tl, 1), "Location", "northwest");
title(tl, runLabel + ": each scale over its common Frenet s window (x = the lap left the track after the window)");

for q = 1:numel(scales)
    K = find([laps.scale] == scales(q));

    % the laps in detail
    pf = ["vx", "ay", "kus_law", "lat_err", "steer_cmd_deg", "steer_fb_deg"];
    yl = ["v_x [m/s]", "a_y [m/s^2]", "k_{us} law", "lateral error [m]", "steering cmd [deg]", "fb steering [deg]"];
    tt = ["Speed", "Lateral acceleration", "Understeer gradient the steering law used", "MPC lateral error", ...
          "Steering command (road wheel)", "Yaw rate feedback steering (road wheel)"];
    ax = lapTiles(newTab(tg, sprintf("%.2f laps", scales(q)), 6, 1), laps(K), pf, yl, tt, sg, cCombo, lwCombo, comboNames, win(q,:), shade, mark);
    ylim(ax(4), [-2 2]);

    % the model MPCs' learners: level c and offset b_hat of both models in every lap (solid: the model that steers)
    tl = newTab(tg, sprintf("%.2f learners", scales(q)), 4, 1);
    ax = gobjects(4,1);
    pf = ["c_bike", "c_dual", "b_bike_deg", "b_dual_deg"];
    tt = ["bicycle model: K_{us} level c", "dual track model: K_{us} level c", "bicycle model: steering offset b_{hat} [deg]", "dual track model: steering offset b_{hat} [deg]"];
    for p = 1:4
        ax(p) = nexttile(tl);  hold on
        for k = K
            own = (laps(k).combo == 3 && contains(pf(p), "bike")) || (laps(k).combo == 4 && contains(pf(p), "dual"));
            plot(sg, laps(k).(pf(p)), ternary(own, "-", ":"), "Color", cCombo(laps(k).combo + 1, :), "LineWidth", ternary(own, 1.6, 1.1), ...
                 "DisplayName", comboNames(laps(k).combo + 1));
        end
        grid on;  title(tt(p));  mark(ax(p));
    end
    yline(ax(1), [0.4 2.0], "--", "Color", cRaw, "HandleVisibility", "off");
    yline(ax(2), [0.4 2.0], "--", "Color", cRaw, "HandleVisibility", "off");
    legend(ax(1), "Location", "eastoutside");
    xlabel(tl, "Frenet s [m]");  linkaxes(ax, "x");  xlim(ax(1), [0 3600]);
    title(tl, sprintf("Learners at scale %.2f (solid: the model that steers in that lap, dotted: shadow; dashed: c bounds)", scales(q)));

    % k_us candidates: what each law would have used in every lap, and the measured K_us
    tl = newTab(tg, sprintf("%.2f k_us candidates", scales(q)), numel(K), 1);
    for k = K
        a = nexttile(tl);  hold on
        plot(sg, laps(k).kus_mpc, "-", "Color", cCombo(1,:));
        plot(sg, laps(k).kus_bike, "-", "Color", cCombo(2,:));
        plot(sg, laps(k).kus_dual, "-", "Color", cCombo(3,:));
        plot(sg, laps(k).kus_law_bike, "-", "Color", cCombo(4,:), "LineWidth", 1.3);
        plot(sg, laps(k).kus_law_dual, "-", "Color", cCombo(5,:), "LineWidth", 1.3);
        gapLine(laps(k).g_s, laps(k).g_meas, cRaw, 1.1, "-", "measured (learner)");
        plot(sg, laps(k).kus_law, ":", "Color", [0.9 0.6 0], "LineWidth", 2);
        grid on;  ylabel("k_{us}");  title(laps(k).name + " (dotted orange = used)");  mark(a);
    end
    legend(nexttile(tl, 1), "native MPC own", "VM bicycle", "VM dual track", "bicycle model law", "dual track model law", ...
           "measured (learner)", "used", "Location", "eastoutside");
    xlabel(tl, "Frenet s [m]");
end

% K_us measured vs both tire models at the measured state
G = struct("at", vertcat(laps.g_at), "ax", vertcat(laps.g_ax), "v", vertcat(laps.g_v), "meas", vertcat(laps.g_meas), ...
           "bike", vertcat(laps.g_bike), "dual", vertcat(laps.g_dual), "uf_b", vertcat(laps.g_uf_bike), "uf_d", vertcat(laps.g_uf_dual));
cBike = median(G.meas ./ G.bike, "omitnan");   cDual = median(G.meas ./ G.dual, "omitnan");
fprintf("\nK_us at the measured state, %d gated samples (v >= 15, |a_t| >= 5, quasi steady), all laps:\n", numel(G.meas));
fprintf("  median  measured %.5f   bicycle model %.5f   dual track model %.5f\n", median(G.meas, "omitnan"), median(G.bike, "omitnan"), median(G.dual, "omitnan"));
fprintf("  level c that fits (median measured / model): bicycle %.2f, dual track %.2f (the learner's floor is 0.4)\n", cBike, cDual);
fprintf("  rms(measured - c model): bicycle %.2e at c 0.4, %.2e at its fit; dual %.2e at c 0.4, %.2e at its fit\n", ...
        rms(G.meas - 0.4 * G.bike, "omitnan"), rms(G.meas - cBike * G.bike, "omitnan"), rms(G.meas - 0.4 * G.dual, "omitnan"), rms(G.meas - cDual * G.dual, "omitnan"));
edgesA = 5:1:24;
fprintf("\n  %-10s %8s %10s %10s %10s %8s %8s\n", "|a_t| bin", "samples", "measured", "bicycle", "dual", "u_f bike", "u_f dual");
for e = 1:numel(edgesA) - 1
    in = abs(G.at) >= edgesA(e) & abs(G.at) < edgesA(e+1);
    if nnz(in) < 20, continue, end
    fprintf("  %4.0f-%-5.0f %8d %10.5f %10.5f %10.5f %8.2f %8.2f\n", edgesA(e), edgesA(e+1), nnz(in), median(G.meas(in), "omitnan"), ...
            median(G.bike(in), "omitnan"), median(G.dual(in), "omitnan"), median(G.uf_b(in), "omitnan"), median(G.uf_d(in), "omitnan"));
end
edgesX = -10:2:6;
fprintf("\n  %-10s %8s %10s %10s %10s   (|a_t| 8 to 16)\n", "a_x bin", "samples", "measured", "bicycle", "dual");
for e = 1:numel(edgesX) - 1
    in = G.ax >= edgesX(e) & G.ax < edgesX(e+1) & abs(G.at) >= 8 & abs(G.at) < 16;
    if nnz(in) < 20, continue, end
    fprintf("  %4.0f-%-5.0f %8d %10.5f %10.5f %10.5f\n", edgesX(e), edgesX(e+1), nnz(in), median(G.meas(in), "omitnan"), median(G.bike(in), "omitnan"), median(G.dual(in), "omitnan"));
end

tl = newTab(tg, "k_us vs demand", 2, 2);
ax1 = nexttile(tl);  hold on
binLine(abs(G.at), G.meas, edgesA, [0.3 0.3 0.3], "measured");  binLine(abs(G.at), G.bike, edgesA, cCombo(4,:), "bicycle model");  binLine(abs(G.at), G.dual, edgesA, cCombo(5,:), "dual track model");
yline([P.kusMin P.kusMax], ":", ["kus\_min", "kus\_max"], "Color", cRaw, "HandleVisibility", "off");
grid on;  xlabel("|a_t| tire demand [m/s^2]");  ylabel("K_{us} [rad/(m/s^2)]");  ylim([-0.002 0.003]);
title("Model K_{us} (unscaled) at the measured state vs measured (bin median, band 25 to 75 %)");  legend("Location", "northwest");
nexttile(tl);  hold on
binLine(abs(G.at), G.meas, edgesA, [0.3 0.3 0.3], "measured");  binLine(abs(G.at), 0.4 * G.bike, edgesA, cCombo(4,:), "0.4 x bicycle");  binLine(abs(G.at), 0.4 * G.dual, edgesA, cCombo(5,:), "0.4 x dual track");
grid on;  xlabel("|a_t| tire demand [m/s^2]");  ylabel("K_{us} [rad/(m/s^2)]");  ylim([-0.001 0.0015]);
title("As the MPCs used it: scaled by the level c at its floor 0.4");  legend("Location", "northwest");
nexttile(tl);  hold on
in = abs(G.at) >= 8 & abs(G.at) < 16;
binLine(G.ax(in), G.meas(in), edgesX, [0.3 0.3 0.3], "measured");  binLine(G.ax(in), G.bike(in), edgesX, cCombo(4,:), "bicycle model");  binLine(G.ax(in), G.dual(in), edgesX, cCombo(5,:), "dual track model");
grid on;  xlabel("a_x [m/s^2] (< 0 braking)");  ylabel("K_{us} [rad/(m/s^2)]");  ylim([-0.002 0.003]);
title("K_{us} vs longitudinal acceleration, |a_t| 8 to 16 m/s^2");  legend("Location", "northwest");
nexttile(tl);  hold on
binLine(abs(G.at), G.uf_b, edgesA, cCombo(4,:), "bicycle front");  binLine(abs(G.at), G.uf_d, edgesA, cCombo(5,:), "dual track front");
grid on;  xlabel("|a_t| tire demand [m/s^2]");  ylabel("|F_y| / peak");  ylim([0 1.05]);
title("Front axle utilisation in each model at the measured state");  legend("Location", "northwest");
title(tl, sprintf("Measured K_{us} vs the two tire models, %d gated samples of every lap (fit: c bicycle %.2f, c dual %.2f)", numel(G.meas), cBike, cDual));

for q = 1:numel(scales)
    K = find([laps.scale] == scales(q));
    tl = newTab(tg, sprintf("%.2f k_us measured vs model", scales(q)), numel(K), 1);
    for k = K
        a = nexttile(tl);  hold on
        L = laps(k);
        gapLine(L.g_s, L.g_meas, [0.35 0.35 0.35], 1.4, "-", "measured");
        gapLine(L.g_s, L.g_c_bike .* L.g_bike, cCombo(4,:), 1.4, "-", "bicycle model x c");
        gapLine(L.g_s, L.g_c_dual .* L.g_dual, cCombo(5,:), 1.4, "-", "dual track model x c");
        gapLine(L.g_s, L.g_bike, cCombo(2,:), 0.9, "--", "bicycle model (unscaled)");
        gapLine(L.g_s, L.g_dual, cCombo(3,:), 0.9, "--", "dual track model (unscaled)");
        grid on;  ylabel("k_{us}");  ylim([-0.002 0.003]);  title(L.name + ": at the measured state, gated samples only");  mark(a);
    end
    legend(nexttile(tl, 1), "Location", "eastoutside");
    xlabel(tl, "Frenet s [m]");  linkaxes(findall(tl, "Type", "axes"), "x");  xlim(a, [0 3600]);
end

% vehicle model k_us (measured by the vehicle_model package) against what the model MPCs predict
H = struct("at", vertcat(laps.h_at), "ax", vertcat(laps.h_ax), "vmb", vertcat(laps.h_vmb), "vmd", vertcat(laps.h_vmd), ...
           "mb", vertcat(laps.h_mb), "md", vertcat(laps.h_md));
cVB = median(H.vmb ./ H.mb, "omitnan");  cVD = median(H.vmd ./ H.md, "omitnan");
fprintf("\nvehicle_model k_us vs the model MPCs' tire models at the same state, %d samples (k_us valid, |a_t| >= 5, v >= 15):\n", numel(H.at));
fprintf("  median  VM bicycle %.5f   bicycle model %.5f   (VM / model %.2f)\n", median(H.vmb, "omitnan"), median(H.mb, "omitnan"), cVB);
fprintf("  median  VM dual    %.5f   dual track model %.5f   (VM / model %.2f)\n", median(H.vmd, "omitnan"), median(H.md, "omitnan"), cVD);
fprintf("  learner measured (gated): %.5f\n", median(G.meas, "omitnan"));
fprintf("\n  %-10s %8s %10s %10s %10s %10s\n", "|a_t| bin", "samples", "VM bike", "bike model", "VM dual", "dual model");
for e = 1:numel(edgesA) - 1
    in = abs(H.at) >= edgesA(e) & abs(H.at) < edgesA(e+1);
    if nnz(in) < 20, continue, end
    fprintf("  %4.0f-%-5.0f %8d %10.5f %10.5f %10.5f %10.5f\n", edgesA(e), edgesA(e+1), nnz(in), median(H.vmb(in), "omitnan"), ...
            median(H.mb(in), "omitnan"), median(H.vmd(in), "omitnan"), median(H.md(in), "omitnan"));
end
fprintf("\n  %-10s %8s %10s %10s %10s %10s   (|a_t| 8 to 16)\n", "a_x bin", "samples", "VM bike", "bike model", "VM dual", "dual model");
for e = 1:numel(edgesX) - 1
    in = H.ax >= edgesX(e) & H.ax < edgesX(e+1) & abs(H.at) >= 8 & abs(H.at) < 16;
    if nnz(in) < 20, continue, end
    fprintf("  %4.0f-%-5.0f %8d %10.5f %10.5f %10.5f %10.5f\n", edgesX(e), edgesX(e+1), nnz(in), median(H.vmb(in), "omitnan"), ...
            median(H.mb(in), "omitnan"), median(H.vmd(in), "omitnan"), median(H.md(in), "omitnan"));
end

cVm = [0.10 0.10 0.10];   % vehicle model k_us
tl = newTab(tg, "VM k_us vs model vs demand", 2, 2);
nexttile(tl);  hold on
binLine(abs(H.at), H.vmb, edgesA, cVm, "VM bicycle k_us");
binLine(abs(H.at), H.mb, edgesA, cCombo(4,:), "bicycle model");
binLine(abs(H.at), 0.4 * H.mb, edgesA, cCombo(2,:), "0.4 x bicycle model");
binLine(abs(G.at), G.meas, edgesA, cRaw, "learner measured");
grid on;  xlabel("|a_t| tire demand [m/s^2]");  ylabel("K_{us} [rad/(m/s^2)]");  ylim([-0.001 0.002]);
title("Bicycle: vehicle model k_us vs the bicycle model at the same state");  legend("Location", "northwest");
nexttile(tl);  hold on
binLine(abs(H.at), H.vmd, edgesA, cVm, "VM dual track k_us");
binLine(abs(H.at), H.md, edgesA, cCombo(5,:), "dual track model");
binLine(abs(H.at), 0.4 * H.md, edgesA, cCombo(3,:), "0.4 x dual track model");
binLine(abs(G.at), G.meas, edgesA, cRaw, "learner measured");
grid on;  xlabel("|a_t| tire demand [m/s^2]");  ylabel("K_{us} [rad/(m/s^2)]");  ylim([-0.001 0.002]);
title("Dual track: vehicle model k_us vs the dual track model at the same state");  legend("Location", "northwest");
nexttile(tl);  hold on
in = abs(H.at) >= 8 & abs(H.at) < 16;
binLine(H.ax(in), H.vmb(in), edgesX, cVm, "VM bicycle k_us");
binLine(H.ax(in), H.mb(in), edgesX, cCombo(4,:), "bicycle model");
binLine(H.ax(in), 0.4 * H.mb(in), edgesX, cCombo(2,:), "0.4 x bicycle model");
grid on;  xlabel("a_x [m/s^2] (< 0 braking)");  ylabel("K_{us} [rad/(m/s^2)]");  ylim([-0.001 0.002]);
title("Bicycle vs longitudinal acceleration, |a_t| 8 to 16 m/s^2");  legend("Location", "northwest");
nexttile(tl);  hold on
binLine(H.ax(in), H.vmd(in), edgesX, cVm, "VM dual track k_us");
binLine(H.ax(in), H.md(in), edgesX, cCombo(5,:), "dual track model");
binLine(H.ax(in), 0.4 * H.md(in), edgesX, cCombo(3,:), "0.4 x dual track model");
grid on;  xlabel("a_x [m/s^2] (< 0 braking)");  ylabel("K_{us} [rad/(m/s^2)]");  ylim([-0.001 0.002]);
title("Dual track vs longitudinal acceleration, |a_t| 8 to 16 m/s^2");  legend("Location", "northwest");
title(tl, sprintf("Vehicle model k_us (measured) vs the model MPCs' tire models, %d samples of every lap (VM / model: bicycle %.2f, dual %.2f)", numel(H.at), cVB, cVD));

for q = 1:numel(scales)
    K = find([laps.scale] == scales(q));
    tl = newTab(tg, sprintf("%.2f VM k_us vs predicted", scales(q)), 2 * numel(K), 1);
    ax = gobjects(0);
    for k = K
        L = laps(k);
        for model = ["bike", "dual"]
            a = nexttile(tl);  hold on;  ax(end+1) = a; %#ok<AGROW>
            if model == "bike"
                cS = cCombo(4,:);  cU = cCombo(2,:);  nm = "bicycle";  c = L.c_bike;
            else
                cS = cCombo(5,:);  cU = cCombo(3,:);  nm = "dual track";  c = L.c_dual;
            end
            plot(sg, L.("vm_" + model), "-", "Color", cVm, "LineWidth", 1.4, "DisplayName", "VM " + nm + " k_us (measured)");
            plot(sg, c .* L.("kus_model_" + model), "-", "Color", cS, "LineWidth", 1.4, "DisplayName", nm + " model x c at the measured state");
            plot(sg, L.("kus_model_" + model), "--", "Color", cU, "LineWidth", 0.9, "DisplayName", nm + " model unscaled");
            plot(sg, L.("kus_law_" + model), ":", "Color", cS, "LineWidth", 1.6, "DisplayName", nm + " law K_{us} (plan, 0.1 s ahead)");
            gapLine(L.g_s, L.g_meas, cRaw, 0.9, "-", "learner measured");
            grid on;  ylabel("k_{us}");  ylim([-0.002 0.003]);  mark(a);
            title(L.name + ": " + nm);
            legend(a, "Location", "eastoutside");
        end
    end
    xlabel(tl, "Frenet s [m]");  linkaxes(ax, "x");  xlim(ax(1), [0 3600]);
    title(tl, sprintf("Vehicle model k_us vs what the model MPCs predict, speed scale %.2f", scales(q)));
end

tabs = tg.Children;
for k = 1:numel(tabs)
    tg.SelectedTab = tabs(k);
    drawnow;
    exportgraphics(tabs(k), fullfile(figDir, sprintf("%02d_%s.png", k, regexprep(tabs(k).Title, "[^A-Za-z0-9]+", "_"))), "Resolution", 130);
end
fprintf("figures written to %s\n", figDir);


%% local functions

function [laps, sTurn] = findLaps(csvFile, offTrack, sg, turnXY, turnNames, comboNames, P, mapFile)
% laps from the Frenet s wraps; per lap the majority controller combination and speed scale, the samples with both
% kept, resampled on Frenet s; per scale and combination the lap with the most coverage

    D = readtable(csvFile);
    t = D.time_s - D.time_s(1);
    hold_cols = ["frenet_s", "mpc_model", "kus_src", "speed_scale", "kus_used", "kus_mpc", "kus_bike", "kus_dual", ...
                 "steer_cmd_deg", "steer_fb", "r_des", "lat_err", "lat_err_k5", "lat_err_k10", ...
                 "ka_bike_kus_law", "ka_bike_c", "ka_bike_b", "ka_bike_a_t", "ka_dual_kus_law", "ka_dual_c", "ka_dual_b"];
    for c = hold_cols
        D.(c) = fillmissing(D.(c), "previous");
    end
    s     = movmedian(D.frenet_s, 5);   % drops the single sample Frenet s glitches
    model = round(D.mpc_model);
    combo = model + 2;                           % 3 bicycle, 4 dual track model MPC
    combo(model == 0) = round(D.kus_src(model == 0));   % native: its k_us source 0..2
    sc    = round(D.speed_scale, 2);
    b     = [1; find(diff(s) < -1000) + 1; numel(s) + 1];

    % k_us the steering law used: the native MPC's, or the active model MPC's plan scheduled K_us
    kusLaw = D.kus_used;
    kusLaw(model == 1) = D.ka_bike_kus_law(model == 1);
    kusLaw(model == 2) = D.ka_dual_kus_law(model == 2);
    D.kus_law = kusLaw;

    % the rollout's predicted lateral error against the one measured 0.3 / 0.6 s later (time based)
    [tu, iu] = unique(t);
    D.pred_err5  = D.lat_err_k5  - interp1(tu, D.lat_err(iu), t + 0.3, "linear", NaN);
    D.pred_err10 = D.lat_err_k10 - interp1(tu, D.lat_err(iu), t + 0.6, "linear", NaN);

    % model K_us at the measured state on every moving sample (the learner's level gate is a subset of it):
    % the learner's 2 Hz filtered speed and a_x, its tire demand a_t, the track map road at Frenet s
    gam = 1 - exp(-2 * pi * P.learnHz * P.dt);
    lp  = @(x) filter(gam, [1, gam - 1], fillmissing(fillmissing(x, "previous"), "next"), (1 - gam) * x(find(isfinite(x), 1)));
    vF  = lp(D.vx);  axF = lp(D.ax);
    move = isfinite(D.ka_bike_a_t) & vF >= 10;
    gate = move & isfinite(D.ka_bike_kus_meas) & abs(D.ka_bike_a_t) >= 5;
    M = readtable(mapFile);
    sw = mod(s, M.s(end) + 1);
    road.bank  = interp1([M.s; M.s(end) + 1], [M.bank_rad; M.bank_rad(1)], sw);
    road.pitch = interp1([M.s; M.s(end) + 1], [M.pitch_rad; M.pitch_rad(1)], sw);
    road.az    = interp1([M.s; M.s(end) + 1], [M.az_road; M.az_road(1)], sw);
    sub = @(r, I) struct("bank", r.bank(I), "pitch", r.pitch(I), "az", r.az(I));
    [kb, ~, ~, ufb] = kusBicycle(D.ka_bike_a_t(move), vF(move), axF(move), sub(road, move), P);
    [kd, ~, ~, ufd] = kusDualTrack(D.ka_bike_a_t(move), vF(move), axF(move), sub(road, move), P);
    D.kus_model_bike = nan(height(D), 1);  D.kus_model_bike(move) = kb;
    D.kus_model_dual = nan(height(D), 1);  D.kus_model_dual(move) = kd;
    D.uf_model_bike  = nan(height(D), 1);  D.uf_model_bike(move) = ufb;
    D.uf_model_dual  = nan(height(D), 1);  D.uf_model_dual(move) = ufd;
    D.v_learn = vF;  D.ax_learn = axF;

    % the vehicle_model package k_us where it is valid (else it publishes the static fallback)
    vmB = fillmissing(D.vm_kus_bike, "previous");  vmBok = fillmissing(D.vm_kus_bike_valid, "previous") > 0.5;
    vmD = fillmissing(D.vm_kus_dual, "previous");  vmDok = fillmissing(D.vm_kus_dual_valid, "previous") > 0.5;
    vmB(~vmBok) = NaN;  vmD(~vmDok) = NaN;
    D.vm_bike = vmB;  D.vm_dual = vmD;
    hgate = move & vmBok & vmDok & abs(D.ka_bike_a_t) >= 5 & vF >= 15;

    fields = ["vx", "ay", "wz", "kus_law", "kus_mpc", "kus_bike", "kus_dual", "lat_err", "steer_cmd_deg", "steer_fb", "r_des", ...
              "dual_fz_fl", "dual_fz_fr", "dual_fz_rl", "dual_fz_rr", "pred_err5", "pred_err10", ...
              "vm_bike", "vm_dual", "kus_model_bike", "kus_model_dual"];
    extra  = ["ka_bike_kus_law", "kus_law_bike"; "ka_dual_kus_law", "kus_law_dual"; "ka_bike_c", "c_bike"; "ka_dual_c", "c_dual"; ...
              "ka_bike_b", "b_bike"; "ka_dual_b", "b_dual"];
    all = struct([]);
    for i = 1:numel(b) - 1
        I = (b(i):b(i+1) - 1)';
        if numel(I) < 3000, continue, end
        lapCombo = mode(combo(I));  lapSc = mode(sc(I));
        I = I(combo(I) == lapCombo & abs(D.speed_scale(I) - lapSc) < 0.002 & s(I) > 0);
        if isempty(I), continue, end
        % drop the wrap glitch: keep the longest run of increasing Frenet s
        brk = [0; find(diff(s(I)) < -50); numel(I)];
        [~, r] = max(diff(brk));  I = I(brk(r) + 1:brk(r + 1));
        if numel(I) < 3000 || max(s(I)) - min(s(I)) < 1500, continue, end
        off = find(abs(D.lat_err(I)) > offTrack, 1);
        sOff = NaN;
        if ~isempty(off), sOff = s(I(off));  I = I(1:off); end
        [su, iu] = unique(s(I));  I = I(iu);
        L = struct();
        L.scale = lapSc;  L.combo = lapCombo;  L.t0 = t(I(1));  L.s0 = su(1);  L.s1 = su(end);  L.sOff = sOff;
        L.name  = sprintf("%.2f %s", lapSc, comboNames(lapCombo + 1));
        for f = fields
            L.(f) = interp1(su, D.(f)(I), sg, "linear", NaN);
        end
        for e = 1:size(extra, 1)
            L.(extra(e,2)) = interp1(su, D.(extra(e,1))(I), sg, "linear", NaN);
        end
        % the gated samples as they are (not resampled: they are sparse)
        Ig = I(gate(I));
        L.g_s = s(Ig);  L.g_at = D.ka_bike_a_t(Ig);  L.g_ax = D.ax_learn(Ig);  L.g_v = D.v_learn(Ig);  L.g_meas = D.ka_bike_kus_meas(Ig);
        L.g_bike = D.kus_model_bike(Ig);  L.g_dual = D.kus_model_dual(Ig);  L.g_uf_bike = D.uf_model_bike(Ig);  L.g_uf_dual = D.uf_model_dual(Ig);
        L.g_c_bike = D.ka_bike_c(Ig);  L.g_c_dual = D.ka_dual_c(Ig);
        % vehicle model k_us samples (valid, |a_t| >= 5, v >= 15) with the models at the same state
        Ih = I(hgate(I));
        L.h_at = D.ka_bike_a_t(Ih);  L.h_ax = D.ax_learn(Ih);  L.h_vmb = D.vm_bike(Ih);  L.h_vmd = D.vm_dual(Ih);
        L.h_mb = D.kus_model_bike(Ih);  L.h_md = D.kus_model_dual(Ih);
        L.b_bike_deg   = L.b_bike * 180 / pi;
        L.b_dual_deg   = L.b_dual * 180 / pi;
        L.steer_fb_deg = L.steer_fb * 180 / pi;
        L.r_err    = L.r_des - L.wz;
        L.fz_total = L.dual_fz_fl + L.dual_fz_fr + L.dual_fz_rl + L.dual_fz_rr;   % total observed normal load
        rate = gradient(D.steer_cmd_deg(I), t(I));
        L.steer_rate = interp1(su, rate, sg, "linear", NaN);
        L.m = [];
        all = [all, L]; %#ok<AGROW>
    end
    if isempty(all), error("no complete laps in %s", csvFile); end

    % one lap per scale and combination: the most coverage
    laps = struct([]);
    keys = round([all.scale] * 100) * 10 + [all.combo];
    for key = unique(keys)
        K = find(keys == key);
        [~, j] = max([all(K).s1] - [all(K).s0]);
        laps = [laps, all(K(j))]; %#ok<AGROW>
    end
    [~, o] = sortrows([[laps.scale]', [laps.combo]']);  laps = laps(o);

    % corners on Frenet s, from the first lap's positions
    I1 = find(t >= laps(1).t0, 1):numel(t);
    sTurn = nan(numel(turnNames), 1);
    for c = 1:numel(turnNames)
        d2 = hypot(D.px(I1) - turnXY(c,1), D.py(I1) - turnXY(c,2));
        [dmin, j] = min(d2(1:min(end, 12000)));
        if dmin < 40, sTurn(c) = s(I1(j)); end
    end
end


function m = lapMetrics(L, sg, w)
% metrics inside the Frenet s window w

    in  = sg >= w(1) & sg <= w(2);
    cor = in & abs(L.vx .* L.wz) > 0.1;
    m = [rms(L.lat_err(in), "omitnan"), max(abs(L.lat_err(in))), rms(L.r_err(in), "omitnan"), rms(L.steer_fb_deg(in), "omitnan"), ...
         rms(L.steer_rate(in), "omitnan"), median(L.kus_law(cor), "omitnan"), max(L.kus_law(in)), max(abs(L.ay(in))), ...
         rms(L.pred_err5(in), "omitnan"), rms(L.pred_err10(in), "omitnan")];
end


function ax = lapTiles(tl, laps, pf, yl, tt, sg, cCombo, lwCombo, comboNames, w, shade, mark)
% one tile per field, every lap of the scale overlaid on Frenet s

    ax = gobjects(numel(pf), 1);
    for p = 1:numel(pf)
        ax(p) = nexttile(tl);  hold on
        for k = 1:numel(laps)
            plot(sg, laps(k).(pf(p)), "-", "Color", cCombo(laps(k).combo + 1, :), "LineWidth", lwCombo(laps(k).combo + 1), ...
                 "DisplayName", comboNames(laps(k).combo + 1));
            if isfinite(laps(k).sOff), xline(ax(p), laps(k).sOff, "-", "off track", "Color", cCombo(laps(k).combo + 1, :), "HandleVisibility", "off"); end
        end
        shade(ax(p), w);
        grid on;  ylabel(yl(p));  title(tt(p));  mark(ax(p));
    end
    legend(ax(1), "Location", "eastoutside");
    linkaxes(ax, "x");  xlim(ax(1), [0 3600]);
    xlabel(tl, "Frenet s [m]");
end


function binLine(x, y, edges, color, name)
% median of y in bins of x as a line, the 25 to 75 % band shaded

    n = numel(edges) - 1;
    xm = nan(n, 1);  ym = xm;  lo = xm;  hi = xm;
    for e = 1:n
        in = x >= edges(e) & x < edges(e+1) & isfinite(y);
        if nnz(in) >= 20
            xm(e) = (edges(e) + edges(e+1)) / 2;
            q = prctile(y(in), [25 50 75]);  lo(e) = q(1);  ym(e) = q(2);  hi(e) = q(3);
        end
    end
    ok = isfinite(xm);
    fill([xm(ok); flipud(xm(ok))], [lo(ok); flipud(hi(ok))], color, "FaceAlpha", 0.15, "EdgeColor", "none", "HandleVisibility", "off");
    plot(xm(ok), ym(ok), "-", "Color", color, "LineWidth", 2.2, "DisplayName", name);
end


function gapLine(s, y, color, width, style, name)
% y against Frenet s as a line, broken where the gated samples are more than 5 m apart

    y = y(:);  s = s(:);
    brk = [false; diff(s) > 5];
    s(brk) = NaN;  y(brk) = NaN;   % the sample after a gap starts a new segment
    plot(s, y, style, "Color", color, "LineWidth", width, "DisplayName", name);
end


function F = brushF(alpha, fz, mu, ca)
% brush tire force, positive slip gives a positive force (kus_aware brushForce), elementwise

    fz  = max(fz, 100);
    t   = tan(alpha);
    tsl = 3 * mu .* fz ./ ca;
    F   = ca .* t - ca.^2 ./ (3 * mu .* fz) .* abs(t) .* t + ca.^3 ./ (27 * mu.^2 .* fz.^2) .* t.^3;
    sat = abs(t) > tsl;
    Fs  = mu .* fz .* (1 - 2 * (alpha < 0)) .* ones(size(F));
    F(sat) = Fs(sat);
end


function alpha = brushInv(F, fz, mu, ca)
% closed form brush inverse, the peak slip at or above the peak force (kus_aware brushInverse)

    fz    = max(fz, 100);
    u     = min(abs(F) ./ (mu .* fz), 1);
    tsl   = 3 * mu .* fz ./ ca;
    alpha = (1 - 2 * (F < 0)) .* atan(tsl .* (1 - nthroot(1 - u, 3)));
end


function [fzF, fzR] = axleLoads(v, alon, road, P)
% axle loads at a point (kus_aware axleLoads, S2)

    gn  = 9.81 * cos(road.bank) .* cos(road.pitch) + road.az;
    dfc = 0.5 * P.rho * P.cla * v.^2;
    tr  = P.m * alon * P.h / P.L;
    fzF = P.m * gn * P.lr / P.L - tr + P.af * dfc;
    fzR = P.m * gn * P.lf / P.L + tr + (1 - P.af) * dfc;
end


function [kus, aF, aR, uF] = kusBicycle(at, v, alon, road, P)
% bicycle model K_us at a steady tire demand (kus_aware understeerBicycle, S3), unclipped and unscaled

    at  = (1 - 2 * (at < 0)) .* max(abs(at), P.aFloor);
    fyF = P.m * P.lr * at / P.L;
    fyR = P.m * P.lf * at / P.L;
    [fzF, fzR] = axleLoads(v, alon, road, P);
    aF  = brushInv(fyF, fzF, P.muF, P.caF);
    aR  = brushInv(fyR, fzR, P.muR, P.caR);
    kus = (aF - aR) ./ at;
    uF  = min(abs(fyF) ./ (P.muF * max(fzF, 100)), 1);
end


function [kus, aF, aR, uF] = kusDualTrack(at, v, alon, road, P)
% dual track model K_us by the per tire 5 pass fixed point (kus_aware understeerDualTrack, S9b), vectorized over samples

    at   = (1 - 2 * (at < 0)) .* max(abs(at), P.aFloor);
    a    = abs(at);
    left = at > 0;
    cin  = P.cL * left + P.cR * ~left;   cout = P.cR * left + P.cL * ~left;
    [fzF, fzR] = axleLoads(v, alon, road, P);
    fFin = max(0.5 * fzF - P.gF * a, P.fzMin);  fFout = max(0.5 * fzF + P.gF * a, P.fzMin);
    fRin = max(0.5 * fzR - P.gR * a, P.fzMin);  fRout = max(0.5 * fzR + P.gR * a, P.fzMin);
    caT  = @(ca, fz, ref, p) 0.5 * ca * (fz / ref).^p;
    cFin = caT(P.caF, fFin, P.fzRefF, P.pF);  cFout = caT(P.caF, fFout, P.fzRefF, P.pF);
    cRin = caT(P.caR, fRin, P.fzRefR, P.pR);  cRout = caT(P.caR, fRout, P.fzRefR, P.pR);

    kin   = P.L * a ./ max(v, 7).^2;
    delta = kin + 0.0005 * a;
    dM    = zeros(size(a));
    grid  = 0.0025 * (1:60);
    for pass = 1:5
        fyF = (P.m * P.lr * a - dM) / P.L;
        fyR = (P.m * P.lf * a + dM) / P.L;
        Gf = @(x) brushF(x + (cin - 1) .* delta, fFin, P.muF, cFin) .* cos(cin .* delta) ...
                + brushF(x + (cout - 1) .* delta, fFout, P.muF, cFout) .* cos(cout .* delta);
        Gr = @(x) brushF(x, fRin, P.muR, cRin) + brushF(x, fRout, P.muR, cRout);
        [aF, pkF] = invertAxle(Gf, fyF, -0.02, grid);
        [aR, ~]   = invertAxle(Gr, fyR, 0, grid);
        delta = kin + aF - aR;
        dM = P.tF / 2 * (brushF(aF + (cin - 1) .* delta, fFin, P.muF, cFin) .* sin(cin .* delta) ...
                       - brushF(aF + (cout - 1) .* delta, fFout, P.muF, cFout) .* sin(cout .* delta));
    end
    kus = (aF - aR) ./ a;
    uF  = min(fyF ./ pkF, 1);
end


function [x, peak] = invertAxle(G, F, low, grid)
% slip where G(x) = F on [low, peak slip], the peak slip once saturated (grid peak, then 50 bisection steps)

    [peak, j] = max(G(grid), [], 2);   % first maximum wins
    xPk = grid(j)';
    lo  = low * ones(size(F));  hi = xPk;
    for i = 1:50
        mid = 0.5 * (lo + hi);
        below = G(mid) < F;
        lo(below) = mid(below);  hi(~below) = mid(~below);
    end
    x = 0.5 * (lo + hi);
    sat = F >= peak;
    x(sat) = xPk(sat);
end


function checkModels(P)
% the port against the spec test vectors (mpc_implementation_spec.html S3 / S9b)

    rows = [3 40 0 0 0.0003622506 0.0003442825; 8 40 0 0 0.0004253232 0.0004372612; 14 40 0 0 0.0006199377 0.0008434542;
            20 40 0 0 0.000730197 0.001; 14 37 0 5 0.0004455456 0.0003641891; 12 60 -6 0 0.0002194924 -0.0001703581];
    road = struct("bank", zeros(6,1), "pitch", zeros(6,1), "az", rows(:,4));
    kb = kusBicycle(rows(:,1), rows(:,2), rows(:,3), road, P);
    kd = kusDualTrack(rows(:,1), rows(:,2), rows(:,3), road, P);
    err = max(abs([kb - rows(:,5); kd - rows(:,6)]) ./ max(abs([rows(:,5); rows(:,6)]), 1e-9));
    assert(err < 1e-5, "K_us model port does not match the spec vectors (max relative error %.2e)", err);
    fprintf("K_us model port matches the spec vectors (max relative error %.1e)\n", err);
end


function shadeOutside(ax, w)
% grey outside the compared Frenet s window w

    if w(1) > 0, xregion(ax, [0 w(1)], "FaceColor", [0.9 0.9 0.9], "HandleVisibility", "off"); end
    xregion(ax, [w(2) 3600], "FaceColor", [0.9 0.9 0.9], "HandleVisibility", "off");
end


function v = ternary(c, a, b)
% a if c, else b

    if c, v = a; else, v = b; end
end


function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact", "Padding", "compact");
end
