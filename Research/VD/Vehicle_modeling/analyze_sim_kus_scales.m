clc
close all
clear
% analyze_sim_kus_scales - sim test of the fbl_mpc k_us switch over speed scales: at each speed scale one lap
% each with the MPC's own k_us, the vehicle model bicycle k_us and the vehicle model dual track k_us, laps aligned
% on Frenet s (/planning/current_frenet_s) and found automatically (Frenet s wrap, majority source and scale)
% each scale is compared only over the Frenet s range every one of its laps covers with its own source and scale;
% a lap that leaves the track (|lateral error| > offTrack) is kept up to that point and the range ends there
% colors: MPC own black, bicycle blue, dual track red, raw / reference grey

%% settings

csvFile  = "/home/elijah/PurdueRacing/bags/sim_kus_test/sim_kus_2026-10-06_150618_kay0p1_csv/sim_kus_2026-10-06_150618_kay0p1_merged.csv";
csvOld   = "/home/elijah/PurdueRacing/bags/sim_kus_test/sim_kus_2026-10-06_143608_csv/2026-10-06_143608_merged.csv";   % k_ay_min 4 run
figDir   = "/home/elijah/code/CodeFiles/Research/VD/Vehicle_modeling/sim_kus_scales_figs";
runLabel = "k\_ay\_min 0.1";
offTrack = 3;      % (m) lateral error that counts as off the track
offPad   = 50;     % (m) Frenet s compared before the off track point
plotScales = [0.80 0.95 1.00];   % speed scales analyzed and plotted (empty: all)

turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];

srcNames = ["MPC own", "VM bicycle", "VM dual track"];
cSrc     = [0.10 0.10 0.10; 0.10 0.35 0.85; 0.85 0.10 0.10];
cRaw     = [0.62 0.62 0.62];
r2d      = 180 / pi;
sg       = (0:1:3600)';

%% laps

[laps, sTurn] = findLaps(csvFile, offTrack, sg, turnXY, turnNames, srcNames);
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

fprintf("\n%-26s %10s %9s %9s %10s %10s %11s %11s %11s %8s\n", "lap", "window s", "|e| rms", "|e| max", "r err rms", "fb steer", "steer rate", "k_us med", "k_us max", "|a_y|max");
for q = 1:numel(scales)
    for k = find([laps.scale] == scales(q))
        laps(k).m = lapMetrics(laps(k), sg, win(q,:));
        fprintf("%-26s %4.0f-%4.0f %9.3f %9.3f %10.4f %10.3f %11.2f %11.5f %11.5f %8.1f%s\n", laps(k).name, win(q,:), laps(k).m, ...
            ternary(isfinite(laps(k).sOff), sprintf("  OFF TRACK at s %.0f", laps(k).sOff), ""));
    end
end
fprintf("lateral error (m), yaw rate error r_des - r (rad/s), yaw rate feedback steering (deg road wheel rms), steering command rate (deg/s rms),\n");
fprintf("k_us used: median where |vx r| > 0.1 and max, max |a_y| (m/s^2), all inside the scale's window\n");

% the same scale in the k_ay_min 4 run, for the threshold change
lapsOld = findLaps(csvOld, offTrack, sg, turnXY, turnNames, srcNames);
common  = intersect(scales, unique([lapsOld.scale]));
for sc = common
    fprintf("\nscale %.2f, k_ay_min 4 vs 0.1 (each run's own common window):\n", sc);
    for run = 1:2
        L = ternary(run == 1, lapsOld, laps);
        K = find([L.scale] == sc);
        w = [max([L(K).s0]), min([L(K).s1])];
        for k = K
            m = lapMetrics(L(k), sg, w);
            fprintf("  %-12s %-22s |e| rms %.3f max %.3f, r err %.4f, fb %.3f deg, steer rate %.2f deg/s\n", ...
                ternary(run == 1, "k_ay_min 4", "k_ay_min 0.1"), L(k).name, m(1:5));
        end
    end
end

%% figures

if exist(figDir, "dir"), delete(fullfile(figDir, "*.png")); else, mkdir(figDir); end
fig = figure("Name", "Sim k_us switch over speed scales", "Position", [40 40 1600 1000]);
theme(fig, "light");
tg = uitabgroup(fig);
mark = @(ax) xline(ax, sTurn(isfinite(sTurn)), ":", turnNames(isfinite(sTurn)), "Color", [0.45 0.45 0.45], ...
    "LabelVerticalAlignment", "top", "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");

% main comparison, one figure per scale: total observed normal load, steering, k_us used, lateral error
pf = ["fz_total", "steer_cmd_deg", "kus_used", "lat_err"];
yl = ["\Sigma F_{z,hat} [N]", "steering cmd [deg]", "k_{us} used", "lateral error [m]"];
tt = ["Total observed normal load (dual track, sum of the four tires)", "Steering wheel command", "Understeer gradient the MPC used", "MPC lateral error"];
for q = 1:numel(scales)
    K = find([laps.scale] == scales(q));
    w = win(q,:);
    tl = newTab(tg, sprintf("%.2f main compare", scales(q)), 4, 1);
    axM = gobjects(4,1);
    for p = 1:4
        axM(p) = nexttile(tl);  hold on
        for k = K
            plot(sg, laps(k).(pf(p)), "-", "Color", cSrc(laps(k).src + 1, :), "LineWidth", 1.1, "DisplayName", srcNames(laps(k).src + 1));
            if isfinite(laps(k).sOff), xline(axM(p), laps(k).sOff, "-", "off track", "Color", cSrc(laps(k).src + 1, :), "HandleVisibility", "off"); end
        end
        if w(1) > 0, xregion(axM(p), [0 w(1)], "FaceColor", [0.9 0.9 0.9], "HandleVisibility", "off"); end
        xregion(axM(p), [w(2) 3600], "FaceColor", [0.9 0.9 0.9], "HandleVisibility", "off");
        grid on;  ylabel(yl(p));  title(tt(p));  mark(axM(p));
    end
    ylim(axM(4), [-2 2]);
    legend(axM(1), "Location", "eastoutside");
    linkaxes(axM, "x");  xlim(axM(1), [0 3600]);
    xlabel(tl, "Frenet s [m]");
    title(tl, sprintf("%s, speed scale %.2f: MPC own vs vehicle model k_{us} (grey = outside the compared window)", runLabel, scales(q)));
end

% metrics against speed scale, one line per source
tl = newTab(tg, "Summary vs scale", 2, 3);
mNames = ["|lateral error| rms [m]", "|lateral error| max [m]", "yaw rate error rms [rad/s]", ...
          "yaw rate feedback steering rms [deg]", "steering command rate rms [deg/s]", "max k_us used [rad/(m/s^2)]"];
mIdx = [1 2 3 4 5 7];
for p = 1:6
    nexttile(tl);  hold on
    for src = 0:2
        K = find([laps.src] == src);
        [~, o] = sort([laps(K).scale]);  K = K(o);
        y = arrayfun(@(k) laps(k).m(mIdx(p)), K);
        plot([laps(K).scale], y, "-o", "Color", cSrc(src+1,:), "MarkerFaceColor", cSrc(src+1,:), "LineWidth", 1.4, "DisplayName", srcNames(src+1));
        off = isfinite([laps(K).sOff]);
        plot([laps(K(off)).scale], y(off), "x", "Color", cSrc(src+1,:), "MarkerSize", 14, "LineWidth", 2.5, "HandleVisibility", "off");
    end
    grid on;  xlabel("speed scale");  title(mNames(p));
end
legend(nexttile(tl, 1), "Location", "northwest");
title(tl, runLabel + ": each scale over its common Frenet s window (x = the lap left the track after the window)");

for q = 1:numel(scales)
    K = find([laps.scale] == scales(q));
    w = win(q,:);
    tl = newTab(tg, sprintf("%.2f laps", scales(q)), 6, 1);
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
            if isfinite(laps(k).sOff), xline(ax(p), laps(k).sOff, "-", "off track", "Color", cSrc(laps(k).src + 1, :), "HandleVisibility", "off"); end
        end
        if w(1) > 0, xregion(ax(p), [0 w(1)], "FaceColor", [0.9 0.9 0.9], "HandleVisibility", "off"); end
        xregion(ax(p), [w(2) 3600], "FaceColor", [0.9 0.9 0.9], "HandleVisibility", "off");
        grid on;  ylabel(yl(p));  title(tt(p) + sprintf(" (%s, scale %.2f, grey = outside the compared window)", runLabel, scales(q)));  mark(ax(p));
    end
    legend(ax(1), "Location", "eastoutside");
    xlabel(tl, "Frenet s [m]");  linkaxes(ax, "x");  xlim(ax(1), [0 3600]);
    ylim(ax(4), [-2 2]);

    tl = newTab(tg, sprintf("%.2f k_us candidates", scales(q)), numel(K), 1);
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

tabs = tg.Children;
for k = 1:numel(tabs)
    tg.SelectedTab = tabs(k);
    drawnow;
    exportgraphics(tabs(k), fullfile(figDir, sprintf("%02d_%s.png", k, regexprep(tabs(k).Title, "[^A-Za-z0-9]+", "_"))), "Resolution", 130);
end
fprintf("figures written to %s\n", figDir);


%% local functions

function [laps, sTurn] = findLaps(csvFile, offTrack, sg, turnXY, turnNames, srcNames)
% laps from the Frenet s wraps; per lap the majority k_us source and speed scale, the samples with both kept,
% resampled on Frenet s; per scale and source the lap with the most coverage

    D = readtable(csvFile);
    t = D.time_s - D.time_s(1);
    for c = ["frenet_s", "kus_src", "speed_scale", "kus_used", "kus_mpc", "kus_bike", "kus_dual", "steer_cmd_deg", "steer_fb", "r_des", "lat_err"]
        D.(c) = fillmissing(D.(c), "previous");
    end
    s   = movmedian(D.frenet_s, 5);   % drops the single sample Frenet s glitches
    src = round(D.kus_src);
    sc  = round(D.speed_scale, 2);
    b   = [1; find(diff(s) < -1000) + 1; numel(s) + 1];

    fields = ["vx", "ay", "kus_used", "kus_mpc", "kus_bike", "kus_dual", "lat_err", "steer_cmd_deg", "steer_fb", "r_des", "wz", ...
              "dual_fz_fl", "dual_fz_fr", "dual_fz_rl", "dual_fz_rr"];
    all = struct([]);
    for i = 1:numel(b) - 1
        I = (b(i):b(i+1) - 1)';
        if numel(I) < 3000, continue, end
        lapSrc = mode(src(I));  lapSc = mode(sc(I));
        I = I(src(I) == lapSrc & abs(D.speed_scale(I) - lapSc) < 0.002 & s(I) > 0);
        % drop the wrap glitch: keep the longest run of increasing Frenet s
        brk = [0; find(diff(s(I)) < -50); numel(I)];
        [~, r] = max(diff(brk));  I = I(brk(r) + 1:brk(r + 1));
        if numel(I) < 3000 || max(s(I)) - min(s(I)) < 1500, continue, end
        off = find(abs(D.lat_err(I)) > offTrack, 1);
        sOff = NaN;
        if ~isempty(off), sOff = s(I(off));  I = I(1:off); end
        [su, iu] = unique(s(I));  I = I(iu);
        L.scale = lapSc;  L.src = lapSrc;  L.t0 = t(I(1));  L.s0 = su(1);  L.s1 = su(end);  L.sOff = sOff;
        L.name  = sprintf("%.2f %s", lapSc, srcNames(lapSrc + 1));
        for f = fields
            L.(f) = interp1(su, D.(f)(I), sg, "linear", NaN);
        end
        L.r_err = L.r_des - L.wz;
        L.fz_total = L.dual_fz_fl + L.dual_fz_fr + L.dual_fz_rl + L.dual_fz_rr;   % total observed normal load
        rate = gradient(D.steer_cmd_deg(I), t(I));
        L.steer_rate = interp1(su, rate, sg, "linear", NaN);
        L.m = [];
        all = [all, L]; %#ok<AGROW>
    end

    % one lap per scale and source: the most coverage
    laps = struct([]);
    keys = round([all.scale] * 100) * 10 + [all.src];
    for key = unique(keys)
        K = find(keys == key);
        [~, j] = max([all(K).s1] - [all(K).s0]);
        laps = [laps, all(K(j))]; %#ok<AGROW>
    end
    [~, o] = sortrows([[laps.scale]', -[laps.src]']);  laps = laps(o);

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
    m = [rms(L.lat_err(in), "omitnan"), max(abs(L.lat_err(in))), rms(L.r_err(in), "omitnan"), rms(L.steer_fb(in), "omitnan") * 180 / pi, ...
         rms(L.steer_rate(in), "omitnan"), median(L.kus_used(cor), "omitnan"), max(L.kus_used(in)), max(abs(L.ay(in)))];
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
