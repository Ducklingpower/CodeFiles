clc
close all
clear
% tire fz plots - do the tire models get Fy vs Fz right on track?
% measured axle Fy (force balance) against the fitted Pacejka 1987 model and the MPC brush tire, both Laguna logs
% the Pacejka model was fitted on the 2025 log only, the 2026 log is an independent check
% first run builds the per-sample data by running vehicle_model.m on the full log (slow, once)

%% settings

here = fileparts(mfilename("fullpath"));

logFiles = ["/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv", ...        % old comp, used for the fit
            "/home/elijah/PurdueRacing/bags/lagoona/comp2/compition_bags/2026-09-03_121638_merged.csv"];   % new comp, not used for the fit
logNames = ["2025 (fit)", "2026 (check)"];
matFiles = fullfile(here, ["tire_fit_data_2025.mat", "tire_fit_data_2026.mat"]);

% Pacejka 1987 coefficients, same as vehicle_model.m, c = [C a1 ... a8], Fz in kN, alpha deg, kappa %
% refit 2026-09-30 on the 2025 comp log with the current observer (tire_fit.m)
pacFy = [1.38674 -126.23 1932.29 2160.01 1.77721 0.234871 -1.61212e-05 -0.0966109 -0.522512;   % front
         1.34461 -92.2527 1910.84 3000.88 1.48429 0.25844 0.000450439 0.136008 -2.1887];       % rear
pacFx = [1.65707 -50.7594 1098.59 -63.5599 1011.01 -0.0111115 -0.00104252 0.0857887 -0.380883;
         1.53503 -66.5514 1621.09 52.8069 883.302 0.0865917 -0.00203071 -0.0268577 0.12542];

% MPC brush tire, on-vehicle fbl_mpc_controller (UnicycleModel, BrushTireModel), config/vehicle_model_param.yaml
% per axle, Fz is the fixed static load in the controller (no downforce, no load transfer)
brushMu = [1.6 1.6];              % friction_coefficient [front rear]
brushFz = [3256 4615];            % normal_load (N)
brushCa = [174000 290000];        % ca, axle cornering stiffness (N/rad)

% MPC dynamic understeer gradient, same file and config (UnicycleModel, use_dynamic_understeer: true)
mpcP.m     = 815.0;               % vehicle_mass (kg)
mpcP.lf    = 1.6785;              % front_wheelbase, CG -> front axle (m)
mpcP.lr    = 1.2933;              % rear_wheelbase, CG -> rear axle (m)
mpcP.coh   = 0.275;               % CG height (m), only used with longitudinal acceleration (the controller passes 0)
mpcP.mu    = brushMu;
mpcP.Fz    = brushFz;
mpcP.Ca    = brushCa;
mpcP.kMax  = 0.0012;              % max_understeer_gradient (rad/(m/s^2)), clamp on when clamp_k_ug is set at the basestation
mpcP.kFix  = 0.00035;             % understeer_gradient, used when use_dynamic_understeer is false
mpcP.L     = 2.97;                % wheelbase (m)
fzFilterHz = 3;                   % (Hz) low pass on the observer output (per tire) before the tire models, understeer comparison

slipBins = [1 2 3 4];   % (deg) axle slip angles compared, +-0.25 deg
slipHalf = 0.25;
nMin     = 30;          % samples per bin before it is drawn

% per tire split (same as vehicle_model.m)
sigA     = 200;         % (N) prior uncertainty floor of each tire's model force
sigR     = 0.2;         % (-) prior uncertainty, fraction of each tire's model force
ayHigh   = 10;          % (m/s^2) hard cornering, for the inside tire share
splitLog = 2;           % log for the per tire time plot (2026 comp), its fastest lap is used
lapRef   = [100 144];   % (m) lap timing point at C11, laps counted between passes

% corners to compare, centre in the odom map frame (same frame in all Laguna logs)
% identified on the fastest 2026 lap from direction, speed and elevation (odom z):
% C8 (591,-281) -> C8A (546,-233) at 251 -> 241 m, left out: slow (19-27 m/s)
cornerXY     = [506 -67;     % C9, left, ~41 m/s, a_z road ~1.16 g (compression after C8), highest load
                260 -78;     % C10, right, ~38 m/s, a_z road ~1.08 g
                100 144];    % C11, left, ~20 m/s, a_z road ~1.01 g, flat, lowest load
cornerNames  = ["C9", "C10", "C11"];
cornerRadius = [80 70 80];   % (m) samples within this distance of the centre
cCorner      = [0.85 0.33 0.10; 0.60 0.20 0.60; 0.00 0.45 0.74];
nC           = numel(cornerNames);

% turn labels on the track map, from the fastest 2026 lap (direction, speed, height)
turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];

% extra Laguna logs, used only in the corner comparison (more passes through each corner)
% JULY_26 hard brake on straight left out, it barely goes through the corners
lagunaDir = "/home/elijah/PurdueRacing/bags/lagoona/";
cornerLogs = lagunaDir + ["comp/csv_output/2025-07-24_172638_merged.csv", ...                                    % 2025 comp, earlier session
                          "october/spin_out/csv_output/2025-10-28_180511_merged.csv", ...                        % October 2025
                          "control_test/JULY_19_full_test/csv_output/2026-07-19_133128_merged.csv", ...
                          "control_test/JULY_28_differnt_engine_map_test_acc/csv_output/2026-07-28_105253_merged.csv", ...
                          "control_test/JULY_28_fastlap_tireLocking_acc/csv_output/2026-07-28_153834_merged.csv", ...
                          "control_test/JULY_28_HardBraking_feedbackcontroller/csv_output/2026-07-28_130732_merged.csv"];
[~, cornerStem] = fileparts(cornerLogs);
cornerMats = fullfile(here, "tire_fit_data_" + erase(cornerStem, "_merged") + ".mat");

axleNames = ["Front axle", "Rear axle"];
tireNames = ["FL", "FR", "RL", "RR"];
cMeas  = [0.165 0.471 0.839];   % blue, measured
cPac   = [0.922 0.408 0.204];   % orange, Pacejka model
cLin   = [0.45 0.45 0.45];      % grey, no load sensitivity
cBrush = [0.00 0.39 0.00];      % dark green, MPC brush tire
cFzS   = [0.60 0.20 0.60];      % purple, normal load split
cRed   = [0.85 0.10 0.10];      % red, MPC brush tire fed the observed axle Fz

% models compared: field, legend name, colour, line style, drawn in the plots
% NOTE: brush per tire at measured Fz (FyBrT) is still computed and printed in the tables, just not plotted for now
% FyBrFz (red) is the MPC axle brush unchanged, only fed the observed axle Fz instead of the fixed load,
% drawn in the model error, slip curve per corner, per tire and understeer plots
Mall = struct("f",    {"FyPac",   "FyLin",               "FyBr",                   "FyBrT",                        "FyBrFz"}, ...
              "name", {"Pacejka", "no load sensitivity", "brush (MPC, fixed F_z)", "brush per tire, measured F_z", "brush (MPC), observed axle F_z"}, ...
              "c",    {cPac,      cLin,                  cBrush,                   cBrush,                         cRed}, ...
              "ls",   {"-",       ":",                   "-",                      "--",                           "-"}, ...
              "show", {true,      true,                  true,                     false,                          false});
M  = Mall([Mall.show]);                        % plotted everywhere
Mx = [M, Mall([Mall.f] == "FyBrFz")];    % plus the red brush, for the plots listed above
nM = numel(Mall);

%% build data (once per log)

allLogs = [logFiles, cornerLogs];
allMats = [matFiles, cornerMats];
for k = 1:numel(allLogs)
    if ~isfile(allMats(k))
        makeFitData(fullfile(here, "vehicle_model.m"), allLogs(k), allMats(k));
    end
    if ~ismember("pz", who("-file", allMats(k)))   % track position and height, for the corner comparison
        o = detectImportOptions(allLogs(k));
        o.SelectedVariableNames = ["odom_px_m", "odom_py_m", "odom_pz_m"];
        P  = readmatrix(allLogs(k), o);
        px = P(:,1);
        py = P(:,2);
        pz = P(:,3);
        save(allMats(k), "px", "py", "pz", "-append");
    end
end
close all

%% load data and model per sample
% near pure cornering samples and models per sample in latSamples (bottom of the file)
% ASSUMPTION: no combined slip correction there, ax is small in these samples

SP = struct([]);   % per tire split, all samples above 10 m/s
for k = 1:2
    d  = load(matFiles(k));
    Fz = d.Fz_dual_obs;
    aD = rad2deg([d.alpha_fl, d.alpha_fr, d.alpha_rl, d.alpha_rr]);

    ok  = all(isfinite([Fz, aD, d.Fyf, d.Fyr]), 2) & d.Fvx > 10;

    Dk = latSamples(d, pacFy, brushMu, brushFz, brushCa);
    Dk.pxAll = d.px;
    Dk.pyAll = d.py;
    Dk.tAll  = d.t;
    Dk.vAll  = d.Fvx;
    Dk.pzAll = d.pz;
    Dk.deltaAll = d.delta;     % road wheel angle (rad), steer offset included
    Dk.ayAll    = d.ay_tire;   % lateral acceleration at the tires (m/s^2), bank corrected
    Dk.FzAxAll  = [d.Fz_dual_obs(:,1) + d.Fz_dual_obs(:,2), d.Fz_dual_obs(:,3) + d.Fz_dual_obs(:,4)];   % observed axle Fz (N)
    Dk.FzTAll   = d.Fz_dual_obs;   % observed tire Fz [FL FR RL RR] (N)
    Dk.alphaAll = [d.alpha_fl, d.alpha_fr, d.alpha_rl, d.alpha_rr];   % tire slip angles (rad), alpha > 0 -> Fy > 0
    if k == 1, D = Dk; else, D(k) = Dk; end
    fprintf("%s: %d near pure cornering samples\n", logNames(k), numel(Dk.v));

    % per tire split of the force balance axle Fy, two methods: (1) normal load split, (2) tire model corrected split,
    % each tire's Pacejka force at its own slip and load sets the shape, axleCorrect brings the pair to the axle total
    % the brush forces below are forward model forces for the Fy debug tab, not splits
    % ASSUMPTION: no combined slip / friction ellipse for now (vehicle_model.m still has it), one change at a time
    sp  = ok;
    FzS = Fz(sp,:);
    aS  = aD(sp,:);
    Sx  = [d.Fyf(sp), d.Fyr(sp)];

    Fy0 = zeros(nnz(sp), 4, 3);   % [sample, tire, (Pacejka, brush measured Fz, brush MPC fixed Fz)]
    for i = 1:4
        ax = ceil(i/2);
        Fy0(:,i,1) = pac87Fy(pacFy(ax,:), aS(:,i), FzS(:,i)/1000);
        Fy0(:,i,2) = brushFy(aS(:,i), FzS(:,i), brushMu(ax), brushCa(ax)/2);
        Fy0(:,i,3) = brushFy(aS(:,i), brushFz(ax)/2, brushMu(ax), brushCa(ax)/2);
    end
    Fy0(~isfinite(Fy0)) = 0;

    FySplit = zeros(nnz(sp), 4, 2);   % [sample, tire, (normal load split, tire model corrected split)]
    for ax = 1:2
        L = 2*ax - 1;
        R = 2*ax;
        shareL = FzS(:,L) ./ (FzS(:,L) + FzS(:,R));
        shareL(~isfinite(shareL)) = 0.5;
        FySplit(:,L,1) = Sx(:,ax) .* shareL;
        FySplit(:,R,1) = Sx(:,ax) .* (1 - shareL);
        [FySplit(:,L,2), FySplit(:,R,2)] = axleCorrect(Sx(:,ax), Fy0(:,L,1), Fy0(:,R,1), sigA, sigR);
    end

    SP(k).t     = d.t(sp);
    SP(k).ay    = d.ay_tire(sp);
    SP(k).Fz    = FzS;
    SP(k).S     = Sx;
    SP(k).Fy    = FySplit;
    SP(k).uncor = Fy0;   % per tire model forces before the axle correction
    SP(k).alpha = aS;    % measured tire slip angles (deg)
end

% no load sensitivity model: Fy = Fz * (Pacejka Fy/Fz at the median tire load), one grip scale fitted on 2025
FzRef    = [median(D(1).FzT(:,1:2), "all"), median(D(1).FzT(:,3:4), "all")];
D1       = noLoadSens(D(1), pacFy, FzRef, [1 1]);
linScale = [D1.FyLin(:,1) \ D1.Fy(:,1), D1.FyLin(:,2) \ D1.Fy(:,2)];
[D.FyLin] = deal([]);
for k = 1:2
    D(k) = noLoadSens(D(k), pacFy, FzRef, linScale);
end

A = struct();   % both logs together
for f = ["alpha", "Fz", "Fy", "FyPac", "FyLin", "FyBr", "FyBrFz", "FyBrT", "v", "az", "px", "py", "sAx"]
    A.(f) = [D(1).(f); D(2).(f)];
end
logId = [ones(numel(D(1).v), 1); 2 * ones(numel(D(2).v), 1)];

%% numbers: axle Fy error per model

fprintf("\naxle Fy rms error on near pure cornering samples (N)\n");
fprintf("%-13s %-10s %9s %9s %12s %14s %14s\n", "log", "axle", "Pacejka", "no LS", "brush (MPC)", "brush axle Fz", "brush tire Fz");
for k = 1:2
    in = logId == k;
    for ax = 1:2
        e = A.Fy(in,ax) - [A.FyPac(in,ax), A.FyLin(in,ax), A.FyBr(in,ax), A.FyBrFz(in,ax), A.FyBrT(in,ax)];
        fprintf("%-13s %-10s %9.0f %9.0f %12.0f %14.0f %14.0f\n", logNames(k), axleNames(ax), rms(e));
    end
end

%% numbers: slope of Fy against Fz at a fixed slip angle
% a load sensitive tire has a smaller slope than Fy/Fz (the line through zero)

slope = nan(numel(slipBins), 2, nM + 1, 3);   % [slip, axle, (measured, models), (2025 2026 both)]
sets  = {D(1), D(2), A};
setNames = [logNames, "both"];

fprintf("\nslope dFy/dFz at fixed slip angle (N/N)\n");
fprintf("%-13s %-10s %6s %6s %8s %8s %8s %8s %8s %8s %8s\n", "log", "axle", "alpha", "n", "Fz span", "meas", "Pacejka", "no LS", "brMPC", "brTire", "brObsFz");
for k = 1:3
    for ax = 1:2
        for b = 1:numel(slipBins)
            in = abs(sets{k}.alpha(:,ax) - slipBins(b)) < slipHalf;
            if nnz(in) < 10*nMin, continue, end
            X = [ones(nnz(in),1), sets{k}.Fz(in,ax)];
            Y = sets{k}.Fy(in,ax);
            for m = 1:nM
                Y = [Y, sets{k}.(Mall(m).f)(in,ax)]; %#ok<AGROW>
            end
            p = X \ Y;
            slope(b,ax,:,k) = p(2,:);
            fprintf("%-13s %-10s %6.1f %6d %8.0f" + join(repmat(" %8.2f", 1, nM + 1), "") + "\n", setNames(k), axleNames(ax), slipBins(b), nnz(in), ...
                diff(prctile(sets{k}.Fz(in,ax), [5 95])), p(2,:));
        end
    end
end

%% numbers: per tire split, inside tire share in hard cornering

splitNames = ["normal load split", "tire model corrected split"];
fprintf("\ninside tire share of axle Fy, |ay| > %d m/s^2 (median)\n", ayHigh);
fprintf("%-13s %-6s %12s %12s\n", "log", "axle", "normal load", "tire model");
for k = 1:2
    for ax = 1:2
        [shIn, hard] = insideShare(SP(k), ax, ayHigh);
        fprintf("%-13s %-6s %11.1f%% %11.1f%%\n", logNames(k), extractBefore(axleNames(ax), " "), 100 * median(shIn(hard,:)));
    end
end

fprintf("\nsum of per tire model Fy before correction vs force balance axle Fy, |ay| > 2 m/s^2 (rms N)\n");
for k = 1:2
    in = abs(SP(k).ay) > 2;
    for ax = 1:2
        e = SP(k).S(in,ax) - squeeze(sum(SP(k).uncor(in, 2*ax-1:2*ax, :), 2));
        fprintf("%-13s %-10s Pacejka %5.0f, brush measured Fz %5.0f, brush MPC fixed Fz %5.0f\n", logNames(k), axleNames(ax), rms(e));
    end
end

%% numbers: the two models side by side

fprintf("\npeak mu_y from the Pacejka model (D/Fz), brush is %.1f at every load\n", brushMu(1));
for ax = 1:2
    FzkN = 1:6;
    fprintf("%-10s %s\n", axleNames(ax), sprintf("%dkN %.2f  ", [FzkN; (pacFy(ax,2) .* FzkN + pacFy(ax,3)) / 1000]));
end
for ax = 1:2
    pacCa = 2 * pacFy(ax,4) * sin(pacFy(ax,5) * atan(pacFy(ax,6) * brushFz(ax) / 2000)) * 180/pi;   % two tires at Fz/2
    fprintf("%s at the MPC load %.0f N: cornering stiffness Pacejka %.0f N/rad, brush %.0f N/rad (saturates at %.1f deg)\n", ...
        axleNames(ax), brushFz(ax), pacCa, brushCa(ax), atand(3 * brushMu(ax) * brushFz(ax) / brushCa(ax)));
end

%% plots, all in one window, one tab per plot

fig = figure("Name", "Tire Fz plots", "Position", [50 50 1400 1000]);
tg  = uitabgroup(fig);

%% plot 1: Fy vs Fz at fixed slip angle
% one tile per slip angle, dots measured median in each Fz bin, lines the models binned the same way

FzEdges = 0:250:12000;

tl = newTab(tg, "Fy vs Fz at fixed slip angle", 2, numel(slipBins));
for ax = 1:2
    for b = 1:numel(slipBins)
        nexttile(tl);
        in = abs(A.alpha(:,ax) - slipBins(b)) < slipHalf;
        if isempty(binMed(A.Fz(in,ax), A.Fy(in,ax), FzEdges, nMin))
            axis off
            text(0.5, 0.5, sprintf("%s, %d deg: not enough samples", axleNames(ax), slipBins(b)), "HorizontalAlignment", "center");
            continue
        end
        drawVsX(A, in, ax, A.Fz(in,ax), FzEdges, 1, M, cMeas, nMin);
        title(sprintf("%s, %d deg", axleNames(ax), slipBins(b)));
        xlabel("axle F_z [N]");
        ylabel("axle F_y [N]");
    end
end
legend(nexttile(tl, 1), ["measured", M.name], "Location", "northwest");
title(tl, "F_y vs F_z at fixed slip angle");

%% plot 2: Fy/Fz vs Fz at fixed slip angle
% flat = grip does not change with load, falling = load sensitive

tl = newTab(tg, "Fy/Fz vs Fz at fixed slip angle", 2, numel(slipBins));
for ax = 1:2
    for b = 1:numel(slipBins)
        nexttile(tl);
        in = abs(A.alpha(:,ax) - slipBins(b)) < slipHalf;
        if isempty(binMed(A.Fz(in,ax), A.Fy(in,ax), FzEdges, nMin))
            axis off
            text(0.5, 0.5, sprintf("%s, %d deg: not enough samples", axleNames(ax), slipBins(b)), "HorizontalAlignment", "center");
            continue
        end
        drawVsX(A, in, ax, A.Fz(in,ax), FzEdges, A.Fz(in,ax), M, cMeas, nMin);
        title(sprintf("%s, %d deg", axleNames(ax), slipBins(b)));
        xlabel("axle F_z [N]");
        ylabel("axle F_y / F_z [-]");
    end
end
legend(nexttile(tl, 1), ["measured", M.name], "Location", "southwest");
title(tl, "F_y/F_z vs F_z at fixed slip angle");

%% plot 3: slope of Fy vs Fz at each slip angle
% how much axle Fy grows per N of axle Fz at a fixed slip angle

tl = newTab(tg, "Slope dFy/dFz", 1, 2);
for ax = 1:2
    nexttile(tl);
    hold on
    plot(slipBins, slope(:,ax,1,1), "o", "Color", cMeas, "MarkerFaceColor", cMeas, "MarkerSize", 8);
    plot(slipBins, slope(:,ax,1,2), "s", "Color", cMeas, "MarkerSize", 8, "LineWidth", 1.5);
    for m = find([Mall.show])
        plot(slipBins, slope(:,ax,m+1,3), Mall(m).ls, "Color", Mall(m).c, "LineWidth", 2);
    end
    grid on
    xlim([0.5 4.5]);
    ylim([-0.2 1.6]);
    title(axleNames(ax));
    xlabel("axle slip angle [deg]");
    ylabel("dF_y / dF_z [N/N]");
    legend(["measured " + logNames, M.name], "Location", "northwest");
end
title(tl, "Extra F_y per extra F_z at fixed slip angle");

%% plot 4: axle slip curve, Fy and Fy/Fz vs slip angle

aEdges = -6:0.25:6;

tl = newTab(tg, "Axle slip curve", 2, 2);
for row = 1:2
    for ax = 1:2
        nexttile(tl);
        nz = 1;
        if row == 2, nz = A.Fz(:,ax); end
        drawVsX(A, true(size(A.v)), ax, A.alpha(:,ax) .* A.sAx(:,ax), aEdges, nz, M, cMeas, nMin, A.sAx(:,ax), true);
        xlim([-6 6]);
        title(axleNames(ax));
        xlabel("axle slip angle [deg]");
        if row == 1, ylabel("axle F_y [N]"); else, ylabel("axle F_y / F_z [-]"); end
    end
end
legend(nexttile(tl, 1), ["measured median", M.name], "Location", "southeast");
title(tl, "Axle slip curve, both logs (light dots every sample, dots median per 0.25 deg)");

%% plot 5: model error vs axle load
% median (measured - model) in each Fz bin, a model that handles load stays flat at zero

tl = newTab(tg, "Model error vs axle load", 1, 2);
for ax = 1:2
    nexttile(tl);
    hold on
    for m = 1:numel(Mx)
        [x, y] = binMed(A.Fz(:,ax), A.Fy(:,ax) - A.(Mx(m).f)(:,ax), FzEdges, nMin);
        plot(x, y, Mx(m).ls, "Color", Mx(m).c, "LineWidth", 2);
    end
    yline(0, "k-");
    grid on
    title(axleNames(ax));
    xlabel("axle F_z [N]");
    ylabel("measured - model F_y [N]");
    legend(Mx.name, "Location", "southwest");
end
title(tl, "Model error vs axle load");

%% plot 6: measured vs predicted axle Fy

show = [1 3];   % Pacejka, brush MPC (index into the plotted models M)

tl = newTab(tg, "Measured vs model axle Fy", 2, numel(show));
for ax = 1:2
    lim = [0 prctile(A.Fy(:,ax), 99.9)];
    for j = 1:numel(show)
        m = show(j);
        nexttile(tl);
        hold on
        plot(A.(M(m).f)(:,ax), A.Fy(:,ax), ".", "Color", M(m).c, "MarkerSize", 3);
        plot(lim, lim, "k-");
        r = corrcoef(A.Fy(:,ax), A.(M(m).f)(:,ax));
        grid on
        axis equal
        xlim(lim); ylim(lim);
        title(sprintf("%s, %s (r = %.3f)", axleNames(ax), M(m).name, r(1,2)));
        xlabel("model F_y [N]");
        ylabel("measured F_y [N]");
    end
end

%% corner comparison, high load C9 / C10 vs flat C11
% same slip curve from corners with different axle load
% ASSUMPTION: the load difference comes from road geometry (a_z road) and downforce (speed) together

% the two main logs plus the extra Laguna logs
cf    = ["alpha", "Fz", "Fy", "FyPac", "FyLin", "FyBr", "FyBrFz", "FyBrT", "v", "az", "px", "py", "sAx"];
C     = A;
srcId = logId;   % which log each sample came from, 1-2 main logs, 3+ extra logs
for k = 1:numel(cornerMats)
    Dk = noLoadSens(latSamples(load(cornerMats(k)), pacFy, brushMu, brushFz, brushCa), pacFy, FzRef, linScale);
    for f = cf
        C.(f) = [C.(f); Dk.(f)];
    end
    srcId = [srcId; (k + 2) * ones(numel(Dk.v), 1)]; %#ok<AGROW>
end

inC = false(numel(C.v), nC);
for c = 1:nC
    inC(:,c) = hypot(C.px - cornerXY(c,1), C.py - cornerXY(c,2)) < cornerRadius(c);
end

fprintf("\ncorner comparison, %d Laguna logs\n", numel(cornerMats) + 2);
fprintf("%-15s %6s %8s %8s %9s %9s\n", "corner", "n", "v [m/s]", "az [g]", "Fz f [N]", "Fz r [N]");
for c = 1:nC
    fprintf("%-15s %6d %8.1f %8.3f %9.0f %9.0f\n", cornerNames(c), nnz(inC(:,c)), median(C.v(inC(:,c))), ...
        median(C.az(inC(:,c))) / 9.81, median(C.Fz(inC(:,c),:)));
end
srcNames = [logNames, extractBefore(extractAfter(cornerMats, "tire_fit_data_"), ".mat")];
for k = 1:numel(srcNames)
    fprintf("   %-18s samples %s\n", srcNames(k), strjoin(compose("%s %5d", cornerNames', sum(inC & srcId == k)'), "  "));
end

fprintf("\naxle Fy (N) at fixed slip angle, %s\n", strjoin(cornerNames, " / "));
fprintf("%-10s %6s %19s %19s %19s %19s %19s\n", "axle", "alpha", "measured", "Pacejka", "no LS", "brush MPC", "brush tire");
for ax = 1:2
    for b = 1:numel(slipBins)
        r = nan(5, nC);
        for c = 1:nC
            in = inC(:,c) & abs(C.alpha(:,ax) - slipBins(b)) < slipHalf;
            if nnz(in) < nMin, continue, end
            r(:,c) = median([C.Fy(in,ax), C.FyPac(in,ax), C.FyLin(in,ax), C.FyBr(in,ax), C.FyBrT(in,ax)])';
        end
        if all(isnan(r(:))), continue, end
        fprintf("%-10s %6.1f %s\n", axleNames(ax), slipBins(b), sprintf(" %5.0f/%5.0f/%5.0f ", r'));
    end
end

%% plot 7: track map with the corners, and height and speed over the fastest lap

[lapWin, lapTimes] = fastestLap(D(splitLog).tAll, D(splitLog).pxAll, D(splitLog).pyAll, D(splitLog).vAll, lapRef);
fprintf("\n%s lap times (s): %s\nfastest lap %.1f s, %.0f to %.0f s\n", logNames(splitLog), sprintf("%.1f ", lapTimes), ...
    diff(lapWin), lapWin);
Dl  = D(splitLog);
lap = Dl.tAll >= lapWin(1) & Dl.tAll <= lapWin(2);

tl = newTab(tg, "Track map, corners compared", 2, 2);
nexttile(tl, 1, [2 1]);
hold on
plot(Dl.pxAll(lap), Dl.pyAll(lap), "-", "Color", [0.7 0.7 0.7]);
for c = 1:nC
    plot(C.px(inC(:,c)), C.py(inC(:,c)), ".", "Color", cCorner(c,:), "MarkerSize", 6);
end
plot(turnXY(:,1), turnXY(:,2), "k.", "MarkerSize", 10, "HandleVisibility", "off");
text(turnXY(:,1) + 12, turnXY(:,2), turnNames, "FontSize", 9, "FontWeight", "bold");
grid on
axis equal
title("Corners compared");
xlabel("x [m]");
ylabel("y [m]");
legend(["fastest lap", cornerNames], "Location", "southwest");

% height and speed along the lap, turns marked where the car passes closest to each label
tLap = Dl.tAll(lap) - lapWin(1);
iLap = find(lap);
tTurn = zeros(numel(turnNames), 1);
for j = 1:numel(turnNames)
    [~, m] = min(hypot(Dl.pxAll(lap) - turnXY(j,1), Dl.pyAll(lap) - turnXY(j,2)));
    tTurn(j) = tLap(m);
end
axH = nexttile(tl, 2);
plot(tLap, Dl.pzAll(iLap), "k-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
ylabel("height [m]");
title(sprintf("Fastest lap %.1f s, %s", diff(lapWin), logNames(splitLog)));
axV = nexttile(tl, 4);
plot(tLap, Dl.vAll(iLap), "k-");
xline(tTurn, ":");
grid on
xlabel("time in lap [s]");
ylabel("speed [m/s]");
linkaxes([axH axV], "x");

%% plot 8: slip curve per corner

aEdgesC = -5:0.25:5;

tl = newTab(tg, "Slip curve per corner", 2, nC);
for ax = 1:2
    for c = 1:nC
        nexttile(tl);
        in = inC(:,c);
        drawVsX(C, in, ax, C.alpha(in,ax) .* C.sAx(in,ax), aEdgesC, 1, Mx, cMeas, nMin, C.sAx(in,ax), true);
        xlim([-5 5]);
        title(sprintf("%s, %s, F_z %.0f N", axleNames(ax), cornerNames(c), median(C.Fz(inC(:,c),ax))));
        xlabel("axle slip angle [deg]");
        ylabel("axle F_y [N]");
    end
end
legend(nexttile(tl, 1), ["measured median", Mx.name], "Location", "northwest");
title(tl, sprintf("High load C9, C10 vs flat C11, %d Laguna logs (light dots every sample, dots median per 0.25 deg)", numel(cornerMats) + 2));

%% plot 9: per tire split, inside tire share vs lateral load transfer
% more load transfer should move force to the outside tire, how much depends on the tire model

ltEdges = 0:0.05:1;
cSplit  = [cFzS; cPac];
lsSplit = ["-", "-"];
splitShow = [true true];

tl = newTab(tg, "Per tire split, inside share", 1, 2);
for ax = 1:2
    nexttile(tl);
    hold on
    shIn = []; lt = [];
    for k = 1:2
        [s, hard, l] = insideShare(SP(k), ax, ayHigh);
        shIn = [shIn; s(hard,:)]; %#ok<AGROW>
        lt   = [lt; l(hard)];     %#ok<AGROW>
    end
    for m = find(splitShow)
        [x, y] = binMed(lt, shIn(:,m), ltEdges, nMin);
        plot(x, 100 * y, lsSplit(m), "Color", cSplit(m,:), "LineWidth", 2);
    end
    grid on
    title(axleNames(ax));
    xlabel("load transfer |F_{zL} - F_{zR}| / F_z axle [-]");
    ylabel("inside tire share of axle F_y [%]");
    legend(splitNames(splitShow), "Location", "southwest");
end
title(tl, sprintf("Per tire split, |a_y| > %d m/s^2, both logs", ayHigh));

%% plot 10: per tire split over time

inW = SP(splitLog).t >= lapWin(1) & SP(splitLog).t <= lapWin(2);

tl = newTab(tg, "Per tire Fy split over time", 2, 2);
axT = gobjects(4, 1);
for i = 1:4
    axT(i) = nexttile(tl);
    hold on
    for m = find(splitShow)
        plot(SP(splitLog).t(inW), SP(splitLog).Fy(inW,i,m), lsSplit(m), "Color", cSplit(m,:), "LineWidth", 1.2);
    end
    % the tire models on their own, at each tire's slip and load, before any correction to the axle total
    plot(SP(splitLog).t(inW), SP(splitLog).uncor(inW,i,1), ":", "Color", cPac,   "LineWidth", 1.5);
    plot(SP(splitLog).t(inW), SP(splitLog).uncor(inW,i,3), "-", "Color", cBrush, "LineWidth", 1.0);
    plot(SP(splitLog).t(inW), SP(splitLog).uncor(inW,i,2), "-", "Color", cRed,   "LineWidth", 1.0);
    grid on
    title(tireNames(i));
    ylabel("F_y [N]");
end
legend(axT(1), [splitNames(splitShow), "Pacejka alone (no correction)", "brush MPC alone (fixed F_z)", "brush MPC alone (observed tire F_z)"], "Location", "southwest");
xlabel(tl, "time [s], " + logNames(splitLog));
linkaxes(axT, "x");
xlim(axT(1), lapWin);
title(tl, sprintf("Per tire F_y split, fastest lap %.1f s", diff(lapWin)));

%% plot 10b: understeer gradient over the fastest lap, MPC vs the same calculation with observed Fz and with our Pacejka
% exact port of UnicycleModelLogic::linearization_law -> under_steer_coefficient -> effective_stiffness
% (fbl_mpc_controller/src/vehicle_model/unicycle_model.cpp), see mpcUndersteer at the bottom
% green: exactly as the MPC, fixed static axle loads
% red:   same MPC code and brush tire, fed the observed axle Fz at each sample
% orange: same steps with our fitted Pacejka in place of the brush (mfUndersteer), observed axle Fz
% ASSUMPTION: the MPC lateral acceleration command is not logged, the achieved v*r stands in for it
% ASSUMPTION: heading error 0, the controller passes max(v, 10) as the speed and 0 longitudinal acceleration

if ~ismember("wz", who("-file", matFiles(splitLog)))   % yaw rate, filtered like vehicle_model.m
    o  = detectImportOptions(logFiles(splitLog));
    o.SelectedVariableNames = ["time_s", "odom_wz_rads"];
    P  = readmatrix(logFiles(splitLog), o);
    wz = lpf(P(:,2), 1.3, median(diff(P(:,1))));
    save(matFiles(splitLog), "wz", "-append");
end
wz = load(matFiles(splitLog), "wz").wz;

if ~ismember("gageRaw", who("-file", matFiles(splitLog)))   % raw strain gages, unfiltered
    o = detectImportOptions(logFiles(splitLog));
    o.SelectedVariableNames = ["fl_load_n", "fr_load_n", "rl_load_n", "rr_load_n"];
    gageRaw = fillmissing(readmatrix(logFiles(splitLog), o), "nearest");
    save(matFiles(splitLog), "gageRaw", "-append");
end
gageRaw = load(matFiles(splitLog), "gageRaw").gageRaw;

vL   = Dl.vAll(lap);
rL   = wz(lap);
aL   = vL .* rL;                            % lateral acceleration command stand in (m/s^2)
FzL  = Dl.FzAxAll(lap,:);                   % observed axle loads [front rear] (N)
vIn  = max(vL, 10);                         % fbl_mpc.cpp: linearization_law(..., max(v, 10), ...)
yawIn = aL ./ (max(vIn, 5) .* cos(0));      % linearization_law: yaw_rate = a_lat / (max(v, 5) cos(heading error))

% observer output low passed per tire (causal, same first order Tustin as vehicle_model.m), then summed per axle
% filtered on the whole log so the lap starts with the filter settled
FzTf = lpf(Dl.FzTAll, fzFilterHz, median(diff(Dl.tAll)));
FzLf = [FzTf(lap,1) + FzTf(lap,2), FzTf(lap,3) + FzTf(lap,4)];

n = numel(vL);
kUs = zeros(n, 1); kRaw = kUs; CfE = kUs; CrE = kUs;   % MPC, fixed load
kObs = kUs; CfO = kUs; CrO = kUs;                        % MPC brush, observed load
kMf  = kUs; CfM = kUs; CrM = kUs;                        % Pacejka, observed load
aSlip = zeros(n, 6);   % axle slip angles from the inverse models (rad): [MPC f r, brush observed f r, Pacejka f r]
Pobs = mpcP;
for j = 1:n
    [kUs(j), kRaw(j), CfE(j), CrE(j), aSlip(j,1), aSlip(j,2)] = mpcUndersteer(yawIn(j), vIn(j), 0.0, mpcP, true);
    Pobs.Fz = FzL(j,:);
    [~, kObs(j), CfO(j), CrO(j), aSlip(j,3), aSlip(j,4)] = mpcUndersteer(yawIn(j), vIn(j), 0.0, Pobs, false);
    [kMf(j), CfM(j), CrM(j), aSlip(j,5), aSlip(j,6)]     = mfUndersteer(yawIn(j), vIn(j), FzL(j,:), mpcP, pacFy);
end

kObsF = zeros(n, 1); kMfF = kObsF;                       % same, filtered observed load
for j = 1:n
    Pobs.Fz = FzLf(j,:);
    [~, kObsF(j)] = mpcUndersteer(yawIn(j), vIn(j), 0.0, Pobs, false);
    kMfF(j)       = mfUndersteer(yawIn(j), vIn(j), FzLf(j,:), mpcP, pacFy);
end

% measured understeer gradient from the tire slip angles, steady state bicycle:
% delta = L/R + (alpha_f - alpha_r)  ->  k_us = (alpha_f - alpha_r) / a_y
% alpha_f - alpha_r equals delta - L r / v exactly (kinematics), so this is also (delta - L/R) / a_y
% ASSUMPTION: axle slip = mean of its two tires, a_y = v r (same as the MPC input), undefined near straight running
aTL   = Dl.alphaAll(lap,:);
kMeas = (mean(aTL(:,1:2), 2) - mean(aTL(:,3:4), 2)) ./ aL;
kMeas(abs(aL) < 4) = NaN;

hard = abs(aL) > 4;
fprintf("\nundersteer gradient on the fastest lap (rad/(m/s^2)), |v r| > 4 m/s^2, median / max\n");
fprintf("MPC fixed Fz       clamped %.5f, unclamped %.5f / %.5f, clamp active %.0f%% of the time\n", ...
    median(kUs(hard)), median(kRaw(hard)), max(kRaw), 100 * mean(kRaw(hard) > mpcP.kMax));
fprintf("MPC observed Fz    %.5f / %.5f, above the clamp %.0f%% of the time\n", median(kObs(hard)), max(kObs), 100 * mean(kObs(hard) > mpcP.kMax));
fprintf("Pacejka observed Fz %.5f / %.5f, above the clamp %.0f%% of the time\n", median(kMf(hard)), max(kMf), 100 * mean(kMf(hard) > mpcP.kMax));
fprintf("measured (alpha_f - alpha_r)/a_y  median %.5f, 10-90%% %.5f to %.5f\n", median(kMeas(hard), "omitnan"), prctile(kMeas(hard), [10 90]));

% how much the filter takes out: rms of the sample to sample change (high frequency content) and above 5 Hz
hfFz = @(x) rms(diff(x));
fprintf("\nobserver output filtered at %.1f Hz (per tire, before the tire models), fastest lap\n", fzFilterHz);
fprintf("axle Fz sample to sample change rms (N): front %.1f -> %.1f, rear %.1f -> %.1f\n", ...
    hfFz(FzL(:,1)), hfFz(FzLf(:,1)), hfFz(FzL(:,2)), hfFz(FzLf(:,2)));
fprintf("k_us sample to sample change rms, |v r| > 4: brush %.2e -> %.2e, Pacejka %.2e -> %.2e (MPC fixed Fz %.2e)\n", ...
    rms(diff(kObs(hard))), rms(diff(kObsF(hard))), rms(diff(kMf(hard))), rms(diff(kMfF(hard))), rms(diff(kRaw(hard))));
fprintf("k_us median, |v r| > 4: brush %.5f -> %.5f, Pacejka %.5f -> %.5f\n", median(kObs(hard)), median(kObsF(hard)), median(kMf(hard)), median(kMfF(hard)));
fprintf("filter time constant %.0f ms\n", 1000 / (2 * pi * fzFilterHz));

% raw gage per axle and total, shifted by the median offset to the observer over the lap so they overlap
rawAx  = [gageRaw(lap,1) + gageRaw(lap,2), gageRaw(lap,3) + gageRaw(lap,4)];
rawAx  = rawAx + median(FzL - rawAx);
rawTot = sum(rawAx, 2);

tl  = newTab(tg, "MPC understeer gradient", 7, 1);
axU = gobjects(7, 1);
axU(1) = nexttile(tl);
hold on
plot(tLap, kRaw, "-", "Color", cBrush * 0.5 + 0.5, "LineWidth", 1);
plot(tLap, kUs,  "-", "Color", cBrush, "LineWidth", 1.5);
plot(tLap, kObs, "-", "Color", cRed,   "LineWidth", 1.5);
plot(tLap, kMf,  "-", "Color", cPac,   "LineWidth", 1.5);
plot(tLap, kMeas, "-", "Color", cFzS,  "LineWidth", 1.5);
yline(mpcP.kMax, "k--", "clamp");
yline(mpcP.kFix, "k:", "fixed gradient");
grid on
ylim([-0.001 0.0035]);
ylabel("k_{us} [rad/(m/s^2)]");
title("Understeer gradient");
legend("MPC unclamped (fixed F_z)", "MPC clamped (fixed F_z)", "MPC brush, observed axle F_z", "Pacejka (fitted), observed axle F_z", ...
    "measured (\alpha_f - \alpha_r) / a_y, |a_y| > 4", ...
    "Location", "northwest");

axU(2) = nexttile(tl);
hold on
plot(tLap, CfE / 1000, "-", "Color", cBrush, "LineWidth", 1.2);
plot(tLap, CfO / 1000, "-", "Color", cRed,   "LineWidth", 1.2);
plot(tLap, CfM / 1000, "-", "Color", cPac,   "LineWidth", 1.2);
grid on
ylabel("C_{eff,f} [kN/rad]");
title("Front axle effective cornering stiffness F_y / tan(\alpha)");
legend("MPC (fixed F_z)", "brush, observed F_z", "Pacejka, observed F_z", "Location", "northwest");

axU(3) = nexttile(tl);
hold on
plot(tLap, CrE / 1000, "-", "Color", cBrush, "LineWidth", 1.2);
plot(tLap, CrO / 1000, "-", "Color", cRed,   "LineWidth", 1.2);
plot(tLap, CrM / 1000, "-", "Color", cPac,   "LineWidth", 1.2);
grid on
ylabel("C_{eff,r} [kN/rad]");
title("Rear axle effective cornering stiffness F_y / tan(\alpha)");
legend("MPC (fixed F_z)", "brush, observed F_z", "Pacejka, observed F_z", "Location", "northwest");

cRawG = [0.82 0.82 0.82];   % light grey, raw gage
axU(4) = nexttile(tl);
hold on
plot(tLap, rawAx(:,1), "-", "Color", cRawG, "LineWidth", 0.8);
plot(tLap, FzL(:,1), "-", "Color", cMeas, "LineWidth", 1.2);
yline(mpcP.Fz(1), "--", "Color", cBrush, "LineWidth", 1.5);
grid on
ylabel("F_{z,f} [N]");
title("Front axle normal load");
legend("raw gage (shifted)", "observed (used by red and orange)", "MPC fixed load (green)", "Location", "northwest");

axU(5) = nexttile(tl);
hold on
plot(tLap, rawAx(:,2), "-", "Color", cRawG, "LineWidth", 0.8);
plot(tLap, FzL(:,2), "-", "Color", cMeas, "LineWidth", 1.2);
yline(mpcP.Fz(2), "--", "Color", cBrush, "LineWidth", 1.5);
grid on
ylabel("F_{z,r} [N]");
title("Rear axle normal load");
legend("raw gage (shifted)", "observed (used by red and orange)", "MPC fixed load (green)", "Location", "northwest");

axU(6) = nexttile(tl);
hold on
plot(tLap, rawTot, "-", "Color", cRawG, "LineWidth", 0.8);
plot(tLap, sum(FzL, 2), "-", "Color", cMeas, "LineWidth", 1.2);
yline(sum(mpcP.Fz), "--", "Color", cBrush, "LineWidth", 1.5);
grid on
ylabel("F_{z,f} + F_{z,r} [N]");
title("Total normal load, front + rear");
legend("raw gage (shifted)", "observed", "MPC fixed load", "Location", "northwest");

axU(7) = nexttile(tl);
plot(tLap, aL, "k-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axU, "x");
xlim(axU(1), [0 diff(lapWin)]);
title(tl, sprintf("Understeer gradient, fastest lap %.1f s, %s", diff(lapWin), logNames(splitLog)));

%% plot 10d: slip angle debug, measured vs backed out of the tire models
% if the measured slip angles (vy based) are close to reality, a tire model that gives the right understeer gradient
% must also give slip angles close to the measured ones, axle by axle
% axle: the slip angles inside the understeer calculations above (same force demand m a_y split by lf, lr)
% tire: the axle demand split per tire by observed normal load, each tire's own model inverted at its own load
% ASSUMPTION: normal load split per tire (Fy_i = Fy_axle Fz_i / Fz_axle), negative observed Fz counts as 0 for the split
% ASSUMPTION: a tire asked for more than its peak sits at its peak slip angle (as the MPC)

FyAxDem = mpcP.m .* aL .* [mpcP.lr, mpcP.lf] ./ (mpcP.lr + mpcP.lf);   % axle force demand (N), uncapped
FzTp    = max(Dl.FzTAll(lap,:), 0);
aTire   = nan(n, 4, 2);   % [sample, tire, (Pacejka, brush)] (rad)
for i = 1:4
    ax  = ceil(i/2);
    pr  = 2*ax - 1 + (mod(i, 2) == 1);   % the other tire on the axle
    FyT = FyAxDem(:,ax) .* FzTp(:,i) ./ (FzTp(:,i) + FzTp(:,pr));
    for j = 1:n
        if ~isfinite(FyT(j)) || abs(aL(j)) < 0.5, continue, end
        aTire(j,i,1) = pacInverse(pacFy(ax,:), FyT(j), FzTp(j,i) / 1000);
        aTire(j,i,2) = -inverseBrush(FyT(j), FzTp(j,i), brushMu(ax), brushCa(ax) / 2);
    end
end

aMeasAx = [mean(aTL(:,1:2), 2), mean(aTL(:,3:4), 2)];
fprintf("\nslip angle, backed out of the tire models vs measured, fastest lap, |a_y| > 4 (rms deg)\n");
fprintf("%-8s %10s %14s %10s\n", "", "MPC fixed", "brush obs Fz", "Pacejka");
for ax = 1:2
    e = rad2deg(aSlip(hard, [ax, ax+2, ax+4]) - aMeasAx(hard,ax));
    fprintf("%-8s %10.2f %14.2f %10.2f\n", extractBefore(axleNames(ax), " "), rms(e, "omitnan"));
end
fprintf("%-8s %10s %14s %10s\n", "", "", "brush obs Fz", "Pacejka");
for i = 1:4
    fprintf("%-8s %10s %14.2f %10.2f\n", tireNames(i), "", rms(rad2deg(aTire(hard,i,2) - aTL(hard,i)), "omitnan"), ...
        rms(rad2deg(aTire(hard,i,1) - aTL(hard,i)), "omitnan"));
end

tl  = newTab(tg, "Slip angle debug", 4, 2);
axS = gobjects(7, 1);
for ax = 1:2
    axS(ax) = nexttile(tl);
    hold on
    plot(tLap, rad2deg(aMeasAx(:,ax)), "-", "Color", cFzS, "LineWidth", 1.8);
    plot(tLap, rad2deg(aSlip(:,ax)),   "-", "Color", cBrush, "LineWidth", 1.0);
    plot(tLap, rad2deg(aSlip(:,ax+2)), "-", "Color", cRed,   "LineWidth", 1.0);
    plot(tLap, rad2deg(aSlip(:,ax+4)), "-", "Color", cPac,   "LineWidth", 1.0);
    grid on
    ylabel("\alpha [deg]");
    title(axleNames(ax) + " slip angle");
    legend("measured (mean of the two tires)", "MPC brush, fixed F_z", "MPC brush, observed F_z", "Pacejka, observed F_z", ...
        "Location", "northwest");
end
for i = 1:4
    axS(2+i) = nexttile(tl);
    hold on
    plot(tLap, rad2deg(aTL(:,i)),       "-", "Color", cFzS, "LineWidth", 1.8);
    plot(tLap, rad2deg(aTire(:,i,2)),   "-", "Color", cRed, "LineWidth", 1.0);
    plot(tLap, rad2deg(aTire(:,i,1)),   "-", "Color", cPac, "LineWidth", 1.0);
    grid on
    ylabel("\alpha [deg]");
    title(tireNames(i) + " slip angle (axle demand split by normal load)");
    legend("measured", "brush, own observed F_z", "Pacejka, own observed F_z", "Location", "northwest");
end
axS(7) = nexttile(tl, [1 2]);
plot(tLap, aL, "k-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axS, "x");
set(axS(1:6), "YLim", [-8 8]);
xlim(axS(1), [0 diff(lapWin)]);
title(tl, sprintf("Slip angle debug, measured vs inverse tire models, fastest lap %.1f s, %s", diff(lapWin), logNames(splitLog)));

%% plot 10e: Fy debug, estimated lateral force vs the tire models run forward on measured slip and load
% estimated: bicycle = force balance axle Fy (vehicle_model.m), dual track = that axle Fy split per tire by normal load
% forward: measured tire slip angle + observed tire Fz through our Pacejka and the brush (per tire, Ca/2), summed per axle
% also the steady state demand m a_y lr/L, lf/L the understeer calculation uses
% ASSUMPTION: pure lateral, no combined slip, same as the per tire split above

sp  = SP(splitLog);
inW = sp.t >= lapWin(1) & sp.t <= lapWin(2);
tW  = sp.t(inW) - lapWin(1);
FyE = sp.Fy(inW,:,1);                 % dual track estimate, normal load split [FL FR RL RR]
FyP = sp.uncor(inW,:,1);              % Pacejka forward
FyB = sp.uncor(inW,:,2);              % brush forward, observed tire Fz
FyBf = sp.uncor(inW,:,3);             % brush forward, MPC fixed Fz
SxW = sp.S(inW,:);                    % bicycle (force balance) axle Fy
FyDem = mpcP.m .* sp.ay(inW) .* [mpcP.lr, mpcP.lf] ./ (mpcP.lr + mpcP.lf);
dFz   = [sp.Fz(inW,1) - sp.Fz(inW,2), sp.Fz(inW,3) - sp.Fz(inW,4)];   % left - right (N)
axSum = @(F) [F(:,1) + F(:,2), F(:,3) + F(:,4)];
FyPax = axSum(FyP); FyBax = axSum(FyB); FyBfax = axSum(FyBf);

fprintf("\nFy debug, fastest lap, |a_y| > 4: rms of (model forward - estimate) (N), and correlation of |error| with |load transfer|\n");
hw = abs(sp.ay(inW)) > 4;
for ax = 1:2
    eP = FyPax(:,ax) - SxW(:,ax);
    eB = FyBax(:,ax) - SxW(:,ax);
    fprintf("%-10s Pacejka %5.0f (r %.2f)   brush obs Fz %5.0f (r %.2f)   KF vs m a_y l/L %5.0f\n", axleNames(ax), ...
        rms(eP(hw)), pearson(abs(eP(hw)), abs(dFz(hw,ax))), rms(eB(hw)), pearson(abs(eB(hw)), abs(dFz(hw,ax))), rms(SxW(hw,ax) - FyDem(hw,ax)));
end
for i = 1:4
    ax = ceil(i/2);
    eP = FyP(:,i) - FyE(:,i);
    eB = FyB(:,i) - FyE(:,i);
    fprintf("%-10s Pacejka %5.0f (r %.2f)   brush obs Fz %5.0f (r %.2f)\n", tireNames(i), ...
        rms(eP(hw)), pearson(abs(eP(hw)), abs(dFz(hw,ax))), rms(eB(hw)), pearson(abs(eB(hw)), abs(dFz(hw,ax))));
end

tl  = newTab(tg, "Fy debug", 6, 2);
axD = gobjects(12, 1);
for ax = 1:2
    axD(ax) = nexttile(tl);
    hold on
    plot(tW, SxW(:,ax),    "-",  "Color", cMeas,  "LineWidth", 1.8);
    plot(tW, FyDem(:,ax),  "--", "Color", [0 0 0], "LineWidth", 1.0);
    plot(tW, FyPax(:,ax),  "-",  "Color", cPac,   "LineWidth", 1.0);
    plot(tW, FyBax(:,ax),  "-",  "Color", cRed,   "LineWidth", 1.0);
    plot(tW, FyBfax(:,ax), "-",  "Color", cBrush, "LineWidth", 1.0);
    grid on
    ylabel("F_y [N]");
    title(axleNames(ax) + " F_y");
    legend("bicycle estimate (force balance)", "m a_y l/L (understeer calc demand)", "Pacejka on measured \alpha, F_z", ...
        "brush on measured \alpha, observed F_z", "brush on measured \alpha, MPC fixed F_z", "Location", "northwest");
end
for i = 1:4
    axD(2+i) = nexttile(tl);
    hold on
    plot(tW, FyE(:,i), "-", "Color", cFzS, "LineWidth", 1.8);
    plot(tW, FyP(:,i), "-", "Color", cPac, "LineWidth", 1.0);
    plot(tW, FyB(:,i), "-", "Color", cRed, "LineWidth", 1.0);
    grid on
    ylabel("F_y [N]");
    title(tireNames(i) + " F_y");
    legend("dual track estimate (axle Fy split by normal load)", "Pacejka on measured \alpha, F_z", ...
        "brush on measured \alpha, observed F_z", "Location", "northwest");
end
% tire normal load: raw gage (shifted to overlap, as elsewhere) behind the observer output
FzTLap  = Dl.FzTAll(lap,:);
rawTire = gageRaw(lap,:) + median(FzTLap - gageRaw(lap,:));
for i = 1:4
    axD(6+i) = nexttile(tl);
    hold on
    plot(tLap, rawTire(:,i), "-", "Color", [0.75 0.75 0.75], "LineWidth", 0.8);
    plot(tLap, FzTLap(:,i),  "-", "Color", cMeas, "LineWidth", 1.2);
    yline(0, "k:");
    grid on
    ylabel("F_z [N]");
    title(tireNames(i) + " normal load");
    legend("raw gage (shifted)", "observer", "Location", "northwest");
end

axD(11) = nexttile(tl);
hold on
plot(tW, dFz(:,1), "-", "Color", cMeas);
plot(tW, dFz(:,2), "--", "Color", cMeas);
grid on
xlabel("time in lap [s]");
ylabel("F_{zL} - F_{zR} [N]");
title("Lateral load transfer (observed)");
legend("front", "rear", "Location", "northwest");
axD(12) = nexttile(tl);
plot(tLap, aL, "k-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axD, "x");
xlim(axD(1), [0 diff(lapWin)]);
title(tl, sprintf("F_y debug, estimated vs tire models on measured slip and load, fastest lap %.1f s, %s", diff(lapWin), logNames(splitLog)));

%% plot 10f: Fz debug, normal load backed out of the tire models from measured slip and lateral force
% at each sample, find the Fz at which the tire model at the measured slip angle gives the estimated Fy
% axle: force balance axle Fy and axle slip = mean of its two tires, Pacejka as two tires at Fz/2, MPC brush per axle
%       (independent of the observer: the force balance axle Fy does not use Fz)
% tire: dual track Fy (axle Fy split by observed normal load, so partly circular) and the tire's own slip
% ASSUMPTION: rising side in Fz (more load, more force), no solution (NaN) when the force is out of reach at that slip
% ASSUMPTION: only where the tire is doing work, |a_y| > 4 and |alpha| > 0.5 deg, Fz is not identifiable near zero force
% NOTE: the brush force hardly depends on Fz below saturation (fixed Ca), so its Fz is poorly defined there

aSW  = sp.alpha(inW,:);                          % measured slip per tire (deg)
aAxW = [mean(aSW(:,1:2), 2), mean(aSW(:,3:4), 2)];
FzW  = sp.Fz(inW,:);                             % observed tire Fz
FzAxW = axSum(FzW);
use  = abs(sp.ay(inW)) > 4;

FzInvAx = nan(nnz(inW), 2, 2);   % [sample, axle, (Pacejka, brush)]
FzInvT  = nan(nnz(inW), 4, 2);   % [sample, tire, (Pacejka, brush)]
gAx = (100:50:16000)';
gT  = (50:25:9000)';
for j = find(use)'
    for ax = 1:2
        if abs(aAxW(j,ax)) > 0.5
            FzInvAx(j,ax,1) = fzInverse(@(z) 2 * pac87Fy(pacFy(ax,:), aAxW(j,ax), z / 2000), SxW(j,ax), gAx);
            FzInvAx(j,ax,2) = fzInverse(@(z) brushFy(aAxW(j,ax), z, brushMu(ax), brushCa(ax)), SxW(j,ax), gAx);
        end
    end
    for i = 1:4
        ax = ceil(i/2);
        if abs(aSW(j,i)) > 0.5
            FzInvT(j,i,1) = fzInverse(@(z) pac87Fy(pacFy(ax,:), aSW(j,i), z / 1000), FyE(j,i), gT);
            FzInvT(j,i,2) = fzInverse(@(z) brushFy(aSW(j,i), z, brushMu(ax), brushCa(ax) / 2), FyE(j,i), gT);
        end
    end
end

fprintf("\nFz debug, fastest lap, |a_y| > 4: model Fz from measured slip and Fy vs observed Fz\n");
fprintf("%-10s %22s %22s\n", "", "Pacejka: rms / solved", "brush: rms / solved");
for ax = 1:2
    eP = FzInvAx(use,ax,1) - FzAxW(use,ax);  eB = FzInvAx(use,ax,2) - FzAxW(use,ax);
    fprintf("%-10s %14.0f N / %3.0f%% %14.0f N / %3.0f%%\n", axleNames(ax), rms(eP, "omitnan"), 100 * mean(isfinite(eP)), ...
        rms(eB, "omitnan"), 100 * mean(isfinite(eB)));
end
for i = 1:4
    eP = FzInvT(use,i,1) - FzW(use,i);  eB = FzInvT(use,i,2) - FzW(use,i);
    fprintf("%-10s %14.0f N / %3.0f%% %14.0f N / %3.0f%%\n", tireNames(i), rms(eP, "omitnan"), 100 * mean(isfinite(eP)), ...
        rms(eB, "omitnan"), 100 * mean(isfinite(eB)));
end

tl  = newTab(tg, "Fz debug", 4, 2);
axZ = gobjects(7, 1);
rawAxW = axSum(rawTire);
for ax = 1:2
    axZ(ax) = nexttile(tl);
    hold on
    plot(tLap, rawAxW(:,ax), "-", "Color", [0.8 0.8 0.8], "LineWidth", 0.8);
    plot(tW, FzAxW(:,ax), "-", "Color", cMeas, "LineWidth", 1.5);
    plot(tW, FzInvAx(:,ax,1), ".", "Color", cPac, "MarkerSize", 4);
    plot(tW, FzInvAx(:,ax,2), ".", "Color", cRed, "MarkerSize", 4);
    grid on
    ylim([0 16000]);
    ylabel("F_z [N]");
    title(axleNames(ax) + " normal load, from force balance axle F_y and axle slip");
    legend("raw gage (shifted)", "observer", "Pacejka inverse", "MPC brush inverse", "Location", "northwest");
end
for i = 1:4
    axZ(2+i) = nexttile(tl);
    hold on
    plot(tLap, rawTire(:,i), "-", "Color", [0.8 0.8 0.8], "LineWidth", 0.8);
    plot(tW, FzW(:,i), "-", "Color", cMeas, "LineWidth", 1.5);
    plot(tW, FzInvT(:,i,1), ".", "Color", cPac, "MarkerSize", 4);
    plot(tW, FzInvT(:,i,2), ".", "Color", cRed, "MarkerSize", 4);
    grid on
    ylim([-1000 9000]);
    ylabel("F_z [N]");
    title(tireNames(i) + " normal load, from dual track F_y (split by observed F_z) and tire slip");
    legend("raw gage (shifted)", "observer", "Pacejka inverse", "brush inverse (Ca/2)", "Location", "northwest");
end
axZ(7) = nexttile(tl, [1 2]);
plot(tLap, aL, "k-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axZ, "x");
xlim(axZ(1), [0 diff(lapWin)]);
title(tl, sprintf("F_z debug, tire models inverted for normal load from measured slip and F_y, fastest lap %.1f s, %s", ...
    diff(lapWin), logNames(splitLog)));

%% plot 10g: slip offset debug, measured slip on straight running should be ~0
% straight running: v > 15 m/s, |a_y| < 1 m/s^2, |r| < 0.02 rad/s, the tires make ~no lateral force, so the median
% measured slip there is an offset (front: steering offset, both axles: vy bias, rear would show a vy bias alone)
% the offset is estimated on the whole split log and taken out of every tire, then the checks above are redone
% ASSUMPTION: constant offset per tire (checked: the front offset does not change with speed, so it is not a vy bias)

stAll = Dl.vAll > 15 & abs(Dl.ayAll) < 1 & abs(wz) < 0.02 & all(isfinite(Dl.alphaAll), 2);
aOff  = median(Dl.alphaAll(stAll,:));   % (rad) per tire
fprintf("\nslip offset on straight running (%d samples): FL %.3f, FR %.3f, RL %.3f, RR %.3f deg\n", nnz(stAll), rad2deg(aOff));

aTLc   = aTL - aOff;                                                   % corrected slip, lap (rad)
kMeasC = (mean(aTLc(:,1:2), 2) - mean(aTLc(:,3:4), 2)) ./ aL;
kMeasC(abs(aL) < 4) = NaN;
aMeasAxC = [mean(aTLc(:,1:2), 2), mean(aTLc(:,3:4), 2)];

aSWc  = sp.alpha(inW,:) - rad2deg(aOff);                               % corrected slip, Fy debug time base (deg)
FyPc  = zeros(size(aSWc));
for i = 1:4
    FyPc(:,i) = pac87Fy(pacFy(ceil(i/2),:), aSWc(:,i), sp.Fz(inW,i) / 1000);
end
FyPaxC = axSum(FyPc);

lt = aL > 4; rtn = aL < -4;
fprintf("measured k_us median, left / right turns: before %.5f / %.5f, after %.5f / %.5f\n", ...
    median(kMeas(lt), "omitnan"), median(kMeas(rtn), "omitnan"), median(kMeasC(lt), "omitnan"), median(kMeasC(rtn), "omitnan"));
for ax = 1:2
    fprintf("%-10s slip vs Pacejka inverse rms: %.2f -> %.2f deg,   Pacejka forward Fy vs force balance rms: %.0f -> %.0f N\n", ...
        axleNames(ax), rms(rad2deg(aSlip(hard,ax+4) - aMeasAx(hard,ax)), "omitnan"), rms(rad2deg(aSlip(hard,ax+4) - aMeasAxC(hard,ax)), "omitnan"), ...
        rms(FyPax(hw,ax) - SxW(hw,ax)), rms(FyPaxC(hw,ax) - SxW(hw,ax)));
end

cPurL = cFzS * 0.4 + 0.6;   % light purple, before
tl  = newTab(tg, "Slip offset debug", 5, 2);
axO = gobjects(8, 1);
for ax = 1:2
    axO(ax) = nexttile(tl);
    hold on
    aSt = rad2deg(mean(Dl.alphaAll(stAll, 2*ax-1:2*ax), 2));
    plot(Dl.vAll(stAll), aSt, ".", "Color", cFzS, "MarkerSize", 3);
    yline(rad2deg(mean(aOff(2*ax-1:2*ax))), "k-", sprintf("median %.2f deg", rad2deg(mean(aOff(2*ax-1:2*ax)))), "LineWidth", 1.5);
    yline(0, "k:");
    grid on
    ylim([-1.5 1.5]);
    xlabel("speed [m/s]");
    ylabel("\alpha [deg]");
    title(axleNames(ax) + " measured slip on straight running, whole log");
end
axO(3) = nexttile(tl, [1 2]);
hold on
plot(tLap, kMeas,  "-", "Color", cPurL, "LineWidth", 1.2);
plot(tLap, kMeasC, "-", "Color", cFzS,  "LineWidth", 1.6);
plot(tLap, kMf,    "-", "Color", cPac,  "LineWidth", 1.0);
plot(tLap, kUs,    "-", "Color", cBrush, "LineWidth", 1.0);
yline(mpcP.kMax, "k--", "clamp");
grid on
ylim([-0.002 0.0035]);
ylabel("k_{us} [rad/(m/s^2)]");
title("Understeer gradient, measured before / after the offset");
legend("measured, raw slip", "measured, offset removed", "Pacejka, observed F_z", "MPC clamped", "Location", "northwest");
for ax = 1:2
    axO(3+ax) = nexttile(tl);
    hold on
    plot(tLap, rad2deg(aMeasAx(:,ax)),  "-", "Color", cPurL, "LineWidth", 1.2);
    plot(tLap, rad2deg(aMeasAxC(:,ax)), "-", "Color", cFzS,  "LineWidth", 1.6);
    plot(tLap, rad2deg(aSlip(:,ax+4)),  "-", "Color", cPac,  "LineWidth", 1.0);
    grid on
    ylim([-8 8]);
    ylabel("\alpha [deg]");
    title(axleNames(ax) + " slip, measured vs Pacejka inverse");
    legend("measured, raw", "measured, offset removed", "Pacejka inverse, observed F_z", "Location", "northwest");
end
for ax = 1:2
    axO(5+ax) = nexttile(tl);
    hold on
    plot(tW, SxW(:,ax),    "-", "Color", cMeas, "LineWidth", 1.6);
    plot(tW, FyPax(:,ax),  "-", "Color", cPac * 0.4 + 0.6, "LineWidth", 1.0);
    plot(tW, FyPaxC(:,ax), "-", "Color", cPac,  "LineWidth", 1.2);
    grid on
    ylabel("F_y [N]");
    title(axleNames(ax) + " F_y, force balance vs Pacejka on measured slip");
    legend("force balance", "Pacejka, raw slip", "Pacejka, offset removed", "Location", "northwest");
end
axO(8) = nexttile(tl, [1 2]);
plot(tLap, aL, "k-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axO(3:8), "x");
xlim(axO(3), [0 diff(lapWin)]);
title(tl, sprintf("Slip offset debug, fastest lap %.1f s, %s", diff(lapWin), logNames(splitLog)));

%% plot 10c: understeer gradient with raw vs low passed observer load

cRawL = [0.75 0.75 0.75];   % light grey, raw observer

tl  = newTab(tg, "Understeer gradient, filtered Fz", 5, 1);
axF = gobjects(5, 1);
axF(1) = nexttile(tl);
hold on
plot(tLap, kObs,  "-", "Color", cRed * 0.4 + 0.6, "LineWidth", 1);
plot(tLap, kObsF, "-", "Color", cRed, "LineWidth", 1.5);
plot(tLap, kUs,   "-", "Color", cBrush, "LineWidth", 1.2);
yline(mpcP.kMax, "k--", "clamp");
grid on
ylim([-0.001 0.0035]);
ylabel("k_{us} [rad/(m/s^2)]");
title("MPC brush, observed axle F_z");
legend("raw observer F_z", sprintf("observer F_z low passed %.0f Hz", fzFilterHz), "MPC fixed F_z (clamped)", "Location", "northwest");

axF(2) = nexttile(tl);
hold on
plot(tLap, kMf,  "-", "Color", cPac * 0.4 + 0.6, "LineWidth", 1);
plot(tLap, kMfF, "-", "Color", cPac, "LineWidth", 1.5);
plot(tLap, kUs,  "-", "Color", cBrush, "LineWidth", 1.2);
yline(mpcP.kMax, "k--", "clamp");
grid on
ylim([-0.001 0.0035]);
ylabel("k_{us} [rad/(m/s^2)]");
title("Pacejka (fitted), observed axle F_z");
legend("raw observer F_z", sprintf("observer F_z low passed %.0f Hz", fzFilterHz), "MPC fixed F_z (clamped)", "Location", "northwest");

axF(3) = nexttile(tl);
hold on
plot(tLap, FzL(:,1),  "-", "Color", cRawL, "LineWidth", 1);
plot(tLap, FzLf(:,1), "-", "Color", cMeas, "LineWidth", 1.3);
yline(mpcP.Fz(1), "--", "Color", cBrush, "LineWidth", 1.5);
grid on
ylabel("F_{z,f} [N]");
title("Front axle normal load (sum of the filtered tires)");
legend("raw observer", sprintf("low passed %.0f Hz", fzFilterHz), "MPC fixed load", "Location", "northwest");

axF(4) = nexttile(tl);
hold on
plot(tLap, FzL(:,2),  "-", "Color", cRawL, "LineWidth", 1);
plot(tLap, FzLf(:,2), "-", "Color", cMeas, "LineWidth", 1.3);
yline(mpcP.Fz(2), "--", "Color", cBrush, "LineWidth", 1.5);
grid on
ylabel("F_{z,r} [N]");
title("Rear axle normal load (sum of the filtered tires)");
legend("raw observer", sprintf("low passed %.0f Hz", fzFilterHz), "MPC fixed load", "Location", "northwest");

axF(5) = nexttile(tl);
plot(tLap, aL, "k-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axF, "x");
xlim(axF(1), [0 diff(lapWin)]);
title(tl, sprintf("Understeer gradient, raw vs %.0f Hz low passed observer F_z, fastest lap %.1f s", fzFilterHz, diff(lapWin)));

%% plot 11: Pacejka vs MPC brush tire, model curves
% axle force at the MPC static load, Pacejka is two tires at half the axle load each

aLine  = 0:0.05:8;
FzAxle = 1000:100:12000;

tl = newTab(tg, "Pacejka vs MPC brush tire", 2, 2);
for ax = 1:2
    nexttile(tl);
    hold on
    plot(aLine, 2 * pac87Fy(pacFy(ax,:), aLine, brushFz(ax) / 2000), "Color", cPac, "LineWidth", 2);
    plot(aLine, brushFy(aLine, brushFz(ax), brushMu(ax), brushCa(ax)), "Color", cBrush, "LineWidth", 2);
    grid on
    title(sprintf("%s, F_z = %.0f N (MPC load)", axleNames(ax), brushFz(ax)));
    xlabel("axle slip angle [deg]");
    ylabel("axle F_y [N]");
    legend("Pacejka (fitted)", "brush (MPC)", "Location", "southeast");
end
for ax = 1:2
    nexttile(tl);
    hold on
    plot(FzAxle, (pacFy(ax,2) .* FzAxle / 2000 + pacFy(ax,3)) / 1000, "Color", cPac, "LineWidth", 2);
    plot(FzAxle, brushMu(ax) * ones(size(FzAxle)), "Color", cBrush, "LineWidth", 2);
    xline(brushFz(ax), ":", "MPC load");
    grid on
    ylim([1 2]);
    title(axleNames(ax) + ", peak friction");
    xlabel("axle F_z [N]");
    ylabel("\mu_y peak [-]");
    legend("Pacejka (fitted)", "brush (MPC)", "Location", "northeast");
end

%% plot 12: Pacejka model, Fy vs slip angle at several loads

FzPlot = 1:6;   % (kN)
aPlot  = 0:0.1:8;
kPlot  = -20:0.2:20;
cSeq   = parula(numel(FzPlot) + 1);

tl = newTab(tg, "Pacejka Fy", 1, 2);
for ax = 1:2
    nexttile(tl);
    hold on
    for j = 1:numel(FzPlot)
        plot(aPlot, pac87Fy(pacFy(ax,:), aPlot, FzPlot(j)), "Color", cSeq(j,:), "LineWidth", 1.5);
    end
    grid on
    title(axleNames(ax) + " tire");
    xlabel("slip angle [deg]");
    ylabel("F_y [N]");
    legend(compose("F_z = %d kN", FzPlot), "Location", "northwest");
end

%% plot 13: Pacejka model, Fx vs slip ratio at several loads

tl = newTab(tg, "Pacejka Fx", 1, 2);
for ax = 1:2
    nexttile(tl);
    hold on
    for j = 1:numel(FzPlot)
        plot(kPlot, pac87Fx(pacFx(ax,:), kPlot, FzPlot(j)), "Color", cSeq(j,:), "LineWidth", 1.5);
    end
    grid on
    title(axleNames(ax) + " tire");
    xlabel("slip ratio [%]");
    ylabel("F_x [N]");
    legend(compose("F_z = %d kN", FzPlot), "Location", "northwest");
end

%% plot 14: Pacejka model, peak friction and cornering stiffness vs load

FzLine = 0.25:0.05:8;

tl = newTab(tg, "Pacejka load dependence", 1, 2);
nexttile(tl);
hold on
for ax = 1:2
    plot(FzLine, (pacFy(ax,2) .* FzLine + pacFy(ax,3)) / 1000, "LineWidth", 1.5);
end
grid on
title("Peak lateral friction");
xlabel("tire F_z [kN]");
ylabel("\mu_y peak [-]");
legend("front", "rear");

nexttile(tl);
hold on
for ax = 1:2
    plot(FzLine, pacFy(ax,4) .* sin(pacFy(ax,5) .* atan(pacFy(ax,6) .* FzLine)), "LineWidth", 1.5);
end
grid on
title("Cornering stiffness");
xlabel("tire F_z [kN]");
ylabel("C_\alpha [N/deg]");
legend("front", "rear", "Location", "southeast");


function Dk = latSamples(d, pacFy, brushMu, brushFz, brushCa)
% near pure cornering samples of one log, measured axle Fy and every model at each sample
% ASSUMPTION: near pure cornering, |ax| < 2, |ay| > 2 m/s^2, v > 10 m/s (same as tire_fit.m)
% ASSUMPTION: brush per tire = MPC brush with half the axle cornering stiffness, at the tire's own slip and load

    Fz  = d.Fz_dual_obs;
    aD  = rad2deg([d.alpha_fl, d.alpha_fr, d.alpha_rl, d.alpha_rr]);
    ok  = all(isfinite([Fz, aD, d.Fyf, d.Fyr]), 2) & d.Fvx > 10;
    lat = ok & abs(d.Fax) < 2 & abs(d.ay_tire) > 2;

    aAx = rad2deg([d.alpha_f, d.alpha_r]);
    s   = sign(aAx);   % fold left and right turns together
    Dk.alpha = abs(aAx(lat,:));
    Dk.Fz    = [Fz(lat,1) + Fz(lat,2), Fz(lat,3) + Fz(lat,4)];
    Dk.Fy    = [d.Fyf(lat), d.Fyr(lat)] .* s(lat,:);
    Dk.FzT   = Fz(lat,:);
    Dk.aT    = aD(lat,:);
    Dk.sT    = [s(lat,1), s(lat,1), s(lat,2), s(lat,2)];
    Dk.sAx   = s(lat,:);   % axle slip sign, to unfold the plots to +- slip angle
    Dk.v     = d.Fvx(lat);
    Dk.az    = d.az_road(lat);
    Dk.px    = d.px(lat);
    Dk.py    = d.py(lat);

    Dk.FyPac  = zeros(nnz(lat), 2);
    Dk.FyBrT  = zeros(nnz(lat), 2);
    Dk.FyBr   = zeros(nnz(lat), 2);
    Dk.FyBrFz = zeros(nnz(lat), 2);
    for ax = 1:2
        for i = 2*ax-1:2*ax
            Dk.FyPac(:,ax) = Dk.FyPac(:,ax) + Dk.sT(:,i) .* pac87Fy(pacFy(ax,:), Dk.aT(:,i), Dk.FzT(:,i) / 1000);
            Dk.FyBrT(:,ax) = Dk.FyBrT(:,ax) + Dk.sT(:,i) .* brushFy(Dk.aT(:,i), Dk.FzT(:,i), brushMu(ax), brushCa(ax) / 2);
        end
        Dk.FyBr(:,ax)   = brushFy(Dk.alpha(:,ax), brushFz(ax), brushMu(ax), brushCa(ax));   % exactly as the MPC
        Dk.FyBrFz(:,ax) = brushFy(Dk.alpha(:,ax), Dk.Fz(:,ax), brushMu(ax), brushCa(ax));   % MPC axle brush, measured load
    end
end


function Dk = noLoadSens(Dk, pacFy, FzRef, scale)
% no load sensitivity model: Fy = Fz * scale * (Pacejka Fy/Fz at the reference tire load)

    Dk.FyLin = zeros(size(Dk.Fy));
    for ax = 1:2
        for i = 2*ax-1:2*ax
            Dk.FyLin(:,ax) = Dk.FyLin(:,ax) + Dk.sT(:,i) .* Dk.FzT(:,i) ./ FzRef(ax) ...
                .* pac87Fy(pacFy(ax,:), Dk.aT(:,i), FzRef(ax) / 1000);
        end
        Dk.FyLin(:,ax) = Dk.FyLin(:,ax) * scale(ax);
    end
end


function [win, lapTimes] = fastestLap(t, px, py, v, ref)
% laps timed between passes of the reference point (within 20 m, moving), fastest complete lap

    near = hypot(px - ref(1), py - ref(2)) < 20 & v > 5;
    tp   = t(diff([0; near]) == 1);
    tp   = tp([true; diff(tp) > 40]);   % one pass per lap
    lapTimes = diff(tp);
    [~, j]   = min(lapTimes);
    win      = [tp(j), tp(j+1)];
end


function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact");
end


function drawVsX(A, in, ax, x, edges, nz, M, cMeas, nMin, sg, raw)
% measured median dots and each model's median line, binned on x, divided by nz (1 or Fz)
% sg: sign per sample (1, or the axle slip sign to unfold to +- slip), raw: also draw every measured sample

    hold on
    if nargin < 10, sg = 1; end
    if nargin < 11, raw = false; end
    if isscalar(nz), nz = ones(nnz(in), 1) * nz; end
    if isscalar(sg), sg = ones(nnz(in), 1) * sg; end
    if raw
        plot(x, sg .* A.Fy(in,ax) ./ nz, ".", "Color", [0.80 0.86 0.95], "MarkerSize", 2, "HandleVisibility", "off");
    end
    [xm, y] = binMed(x, sg .* A.Fy(in,ax) ./ nz, edges, nMin);
    plot(xm, y, "o", "Color", cMeas, "MarkerFaceColor", cMeas, "MarkerSize", 4);
    for m = 1:numel(M)
        [xm, y] = binMed(x, sg .* A.(M(m).f)(in,ax) ./ nz, edges, nMin);
        plot(xm, y, M(m).ls, "Color", M(m).c, "LineWidth", 1.5);
    end
    grid on
end


function [shIn, hard, lt] = insideShare(sp, ax, ayHigh)
% share of the axle Fy on the inside (lighter) tire for each split method, and the load transfer ratio

    L = 2*ax - 1;
    R = 2*ax;
    inL  = sp.Fz(:,L) < sp.Fz(:,R);
    FyIn = squeeze(sp.Fy(:,L,:)) .* inL + squeeze(sp.Fy(:,R,:)) .* ~inL;
    shIn = FyIn ./ sp.S(:,ax);
    lt   = abs(sp.Fz(:,L) - sp.Fz(:,R)) ./ (sp.Fz(:,L) + sp.Fz(:,R));
    hard = abs(sp.ay) > ayHigh;
end


function [fL, fR] = axleCorrect(S, fL, fR, sigA, sigR)
% spread the axle residual S - (fL + fR) by each tire's prior variance (same as vehicle_model.m)

    PL = (sigA + sigR .* abs(fL)).^2;
    PR = (sigA + sigR .* abs(fR)).^2;
    r  = S - (fL + fR);

    fL = fL + r .* PL ./ (PL + PR);
    fR = fR + r .* PR ./ (PL + PR);
end


function [k_us, k_raw, Cf, Cr, af, ar] = mpcUndersteer(yaw_rate, velocity, acceleration, P, clampOn)
% UnicycleModelLogic::under_steer_coefficient + effective_stiffness, line for line
% P: m, lf, lr, coh, mu [f r], Fz [f r] (normal_load), Ca [f r], kMax
% af, ar: the axle slip angles the inverse brush gives (rad, our sign alpha > 0 -> Fy > 0), for debugging, not in the C++

    Fz_f = P.Fz(1) - P.m * acceleration * P.coh / (P.lr + P.lf);
    Fz_r = P.Fz(2) + P.m * acceleration * P.coh / (P.lr + P.lf);
    if velocity < 0.1 || abs(yaw_rate) < 0.00001
        % singular case, should return to the gradient near zero
        small_slip = 0.001;
        Cf = brushTireForce(small_slip, Fz_f, P.mu(1), P.Ca(1)) / small_slip;
        Cr = brushTireForce(small_slip, Fz_r, P.mu(2), P.Ca(2)) / small_slip;
        af = 0;
        ar = 0;
    else
        Fy_target = P.m * velocity * yaw_rate;
        % need to check which tire will saturate first here
        max_fyf = P.mu(1) * Fz_f;
        max_fyr = P.mu(2) * Fz_r;
        if abs(max_fyf * P.lf / P.lr) > abs(max_fyr)
            % rear saturate first, check rear first
            Fyr = max(min(Fy_target * P.lf / (P.lr + P.lf), max_fyr), -max_fyr);
            Fyf = Fyr * P.lr / P.lf;
        else
            % front saturate first, check front first
            Fyf = max(min(Fy_target * P.lr / (P.lr + P.lf), max_fyf), -max_fyf);
            Fyr = Fyf * P.lf / P.lr;
        end
        alpha_f = inverseBrush(Fyf, Fz_f, P.mu(1), P.Ca(1));
        alpha_r = inverseBrush(Fyr, Fz_r, P.mu(2), P.Ca(2));
        Cf = Fyf / tan(alpha_f);
        Cr = Fyr / tan(alpha_r);
        af = -alpha_f;   % controller slip angle is ours negated
        ar = -alpha_r;
    end
    Cf = abs(Cf);
    Cr = abs(Cr);

    k_us  = (P.m * (P.lr * Cr - P.lf * Cf)) / ((P.lr + P.lf) * Cf * Cr);
    k_raw = k_us;
    if clampOn && P.kMax > 0 && k_us > P.kMax
        k_us = P.kMax;
    end
end


function [k_us, Cf, Cr, af, ar] = mfUndersteer(yaw_rate, velocity, FzAx, P, pacFy)
% same steps as the MPC effective_stiffness / under_steer_coefficient, with our fitted Pacejka in place of the brush
% ASSUMPTION: each axle is two tires at half the observed axle load, no left/right load transfer (as the MPC bicycle)
% ASSUMPTION: past the peak the axle sits at the peak slip angle (the MPC does the same with the brush threshold)

    aGrid = (0:0.01:15)';   % (deg)
    Fax = zeros(numel(aGrid), 2);
    for ax = 1:2
        Fax(:,ax) = 2 * pac87Fy(pacFy(ax,:), aGrid, FzAx(ax) / 2000);
    end
    [Fpk, ipk] = max(Fax);

    if velocity < 0.1 || abs(yaw_rate) < 0.00001
        small = 0.001;   % (rad)
        Cf = 2 * pac87Fy(pacFy(1,:), rad2deg(small), FzAx(1) / 2000) / small;
        Cr = 2 * pac87Fy(pacFy(2,:), rad2deg(small), FzAx(2) / 2000) / small;
        af = 0;
        ar = 0;
    else
        Fy_target = P.m * velocity * yaw_rate;
        if abs(Fpk(1) * P.lf / P.lr) > abs(Fpk(2))
            Fyr = max(min(Fy_target * P.lf / (P.lr + P.lf), Fpk(2)), -Fpk(2));
            Fyf = Fyr * P.lr / P.lf;
        else
            Fyf = max(min(Fy_target * P.lr / (P.lr + P.lf), Fpk(1)), -Fpk(1));
            Fyr = Fyf * P.lf / P.lr;
        end
        F = [Fyf, Fyr];
        C = zeros(1, 2);
        for ax = 1:2
            if abs(F(ax)) >= Fpk(ax)
                a = aGrid(ipk(ax));
            else
                a = interp1(Fax(1:ipk(ax),ax), aGrid(1:ipk(ax)), abs(F(ax)));   % inverse on the rising side
            end
            C(ax) = abs(F(ax)) / tan(deg2rad(a));
            A(ax) = sign(F(ax)) * deg2rad(a);   %#ok<AGROW> signed axle slip angle (rad)
        end
        Cf = C(1);
        Cr = C(2);
        af = A(1);
        ar = A(2);
    end

    k_us = (P.m * (P.lr * Cr - P.lf * Cf)) / ((P.lr + P.lf) * Cf * Cr);
end


function Fz = fzInverse(fy, Fy, grid)
% normal load where fy(Fz) (the tire model at a fixed slip angle) equals Fy, on the rising side of fy in Fz
% NaN when the force is out of reach at this slip angle or has the wrong sign

    Fg = fy(grid);
    s  = sign(Fg(end));
    if sign(Fy) ~= s || s == 0, Fz = NaN; return, end
    Fg = s * Fg;
    [~, ipk] = max(Fg);
    j = find(Fg(1:ipk) >= abs(Fy), 1);
    if isempty(j) || j == 1, Fz = NaN; return, end
    Fz = grid(j-1) + (abs(Fy) - Fg(j-1)) / (Fg(j) - Fg(j-1)) * (grid(j) - grid(j-1));
end


function r = pearson(x, y)
% Pearson correlation without the statistics toolbox

    c = corrcoef(x, y);
    r = c(1, 2);
end


function a = pacInverse(c, F, FzkN)
% slip angle (rad, signed like F) where the Pacejka tire gives force F at load FzkN, rising side of the curve,
% past the peak the tire sits at its peak slip angle

    aGrid = (0:0.01:15)';
    Fg = pac87Fy(c, aGrid, FzkN);
    [Fpk, ipk] = max(Fg);
    if abs(F) >= Fpk
        a = aGrid(ipk);
    else
        a = interp1(Fg(1:ipk), aGrid(1:ipk), abs(F));
    end
    a = sign(F) * deg2rad(a);
end


function alpha_out = inverseBrush(Fy_target, Fz, mu, Ca)
% UnicycleModelLogic::inverse_brush_tire_slip, line for line (slip angle in rad, controller sign)

    Fz     = max(100.0, Fz);
    Fy_max = mu * Fz;
    if Ca > 0 && mu > 0 && Fz > 0, a_th = 3.0 * Fy_max / Ca; else, a_th = 0.0; end

    if abs(Fy_target) >= Fy_max || a_th <= 0.0
        sgn_alpha = -1.0 * (Fy_target > 0.0) + 1.0 * (Fy_target < 0.0);
        alpha_out = atan(sgn_alpha * a_th);
        return
    end

    s  = -1.0 * (Fy_target > 0.0) + 1.0 * (Fy_target < 0.0);   % slip angle sign
    k1 = Ca;
    k2 = (Ca * Ca) / (3.0 * mu * Fz);
    k3 = (Ca * Ca * Ca) / (27.0 * mu * mu * Fz * Fz);

    % solve: k3*a^3 - s*k2*a^2 + k1*a + Fy = 0
    A = k3; B = -s * k2; C = k1; D = Fy_target;
    a = B / A; b = C / A; c = D / A;

    % depressed cubic y^3 + p y + q = 0 with a = y - a/3
    a_over_3 = a / 3.0;
    p = b - a * a_over_3;
    q = 2.0 * a_over_3^3 - a_over_3 * b + c;
    disc = 0.25 * q * q + (p * p * p) / 27.0;

    if disc >= 0.0
        sqrt_disc = sqrt(disc);
        u = nthroot(-0.5 * q + sqrt_disc, 3);
        v = nthroot(-0.5 * q - sqrt_disc, 3);
        cand = u + v - a_over_3;
    else
        r   = 2.0 * sqrt(-p / 3.0);
        phi = acos((-0.5 * q) / sqrt(-(p * p * p) / 27.0));
        cand = r * cos((phi + 2.0 * pi * (0:2)) / 3.0) - a_over_3;
    end

    % pick the root with correct sign and inside [0, a_th]
    sb = @(x) x < 0 || (x == 0 && 1 / x < 0);   % std::signbit
    best = cand(1);
    best_cost = 1e300;
    for aa = cand
        cost = 0.0;
        if sb(aa) ~= sb(s), cost = cost + 1e3; end
        if abs(aa) > a_th, cost = cost + (abs(aa) - a_th) * 100.0; end
        cost = cost + abs(abs(aa) - min(abs(aa), a_th));
        if cost < best_cost, best_cost = cost; best = aa; end
    end
    alpha = min(abs(best), a_th);
    if sb(s), alpha = -alpha; end                % std::copysign
    alpha_out = atan(alpha);
end


function y = lpf(x, fc, Ts)
% first order low pass, Tustin with prewarp (same as vehicle_model.m)

    K  = tan(pi * fc * Ts);
    a1 = (1 - K) / (1 + K);
    b  =      K  / (1 + K);

    x = fillmissing(x, "previous");
    y = x;
    for k = 2:size(x, 1)
        y(k,:) = a1 .* y(k-1,:) + b .* (x(k,:) + x(k-1,:));
        reset = ~isfinite(y(k,:));
        y(k,reset) = x(k,reset);
    end
end


function Fy = brushFy(alpha, Fz, mu, Ca)
% MPC brush tire, exact port of brush_tire_force (fbl_mpc_controller unicycle_model.cpp / bicycle_model.cpp)
% alpha in deg with our sign (alpha > 0 -> Fy > 0), the controller slip angle is ours negated, Fy has the same sign

    Fy = brushTireForce(-deg2rad(alpha), Fz, mu, Ca);
end


function Fy = brushTireForce(slip_angle, Fz, mu, Ca)
% line for line from the C++, vectorised

    Fz       = max(100.0, Fz);
    Fy_max   = mu .* Fz;
    alpha    = tan(slip_angle);
    a_thresh = 3.0 .* Fy_max ./ Ca;

    term1 = -Ca .* alpha;
    term2 = (Ca .* Ca) ./ (3.0 .* mu .* Fz) .* abs(alpha) .* alpha;
    term3 = -(Ca .* Ca .* Ca) ./ (27.0 .* mu .* mu .* Fz .* Fz) .* alpha .* alpha .* alpha;
    Fy    = term1 + term2 + term3;

    sat     = abs(alpha) > a_thresh;                          % saturation
    sgn     = 2 .* (slip_angle >= 0.0) - 1;
    Fy_sat  = -Fy_max .* sgn;
    Fy(sat) = Fy_sat(sat);
end

function makeFitData(modelFile, dataFile, outFile)
% run vehicle_model.m on the full log with saveFitData on, from a temporary copy

    fprintf("building %s from %s (full vehicle_model.m run)\n", outFile, dataFile);
    src = fileread(modelFile);
    src = regexprep(src, "^(clc|close all|clear)\s*$", "", "lineanchors");   % keep this function's workspace
    src = regexprep(src, "^\s*dataFile\s*=.*?$",    "dataFile = """ + dataFile + """;", "lineanchors", "dotexceptnewline");
    src = regexprep(src, "^\s*timeWindow\s*=.*?$",  "timeWindow = [0 Inf];",            "lineanchors", "dotexceptnewline");
    src = regexprep(src, "^\s*saveFitData\s*=.*?$", "saveFitData = true;",              "lineanchors", "dotexceptnewline");
    src = regexprep(src, "^\s*fitDataFile\s*=.*?$", "fitDataFile = """ + outFile + """;", "lineanchors", "dotexceptnewline");

    tmp = fullfile(tempdir, "vehicle_model_fitdata_tmp.m");
    writelines(src, tmp);
    cleanup = onCleanup(@() delete(tmp));

    figVis = get(0, "DefaultFigureVisible");
    set(0, "DefaultFigureVisible", "off");
    run(tmp);
    set(0, "DefaultFigureVisible", figVis);
    close all
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


function Fy = pac87Fy(c, alpha, Fz)
% Bakker, Nyborg, Pacejka 1987 (tires.pdf), alpha in deg, Fz in kN, c = [C a1 ... a8]

    Fz  = max(Fz, 0.01);
    D   = c(2) .* Fz.^2 + c(3) .* Fz;
    BCD = c(4) .* sin(c(5) .* atan(c(6) .* Fz));
    B   = BCD ./ (c(1) .* D);
    E   = c(7) .* Fz.^2 + c(8) .* Fz + c(9);
    phi = (1 - E) .* alpha + E ./ B .* atan(B .* alpha);
    Fy  = D .* sin(c(1) .* atan(B .* phi));
end


function Fx = pac87Fx(c, kappa, Fz)
% Bakker, Nyborg, Pacejka 1987 (tires.pdf), kappa in %, Fz in kN, c = [C a1 ... a8]

    Fz  = max(Fz, 0.01);
    D   = c(2) .* Fz.^2 + c(3) .* Fz;
    BCD = (c(4) .* Fz.^2 + c(5) .* Fz) .* exp(-c(6) .* Fz);
    B   = BCD ./ (c(1) .* D);
    E   = c(7) .* Fz.^2 + c(8) .* Fz + c(9);
    phi = (1 - E) .* kappa + E ./ B .* atan(B .* kappa);
    Fx  = D .* sin(c(1) .* atan(B .* phi));
end
