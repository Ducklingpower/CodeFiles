clc
close all
clear
% tire fit - match the .tir files to our tires, then fit the Pacejka 1987 simplified formula (tires.pdf)
% 1) data from vehicle_model.m (saveFitData = true, timeWindow = [0 Inf])
% 2) lateral: LMUY, LKY per axle to the measured axle Fy, profiled over PDY2 (load sensitivity)
% 3) longitudinal: LMUX, LKX per axle to the per wheel Fx (wheel dynamics)
% 4) write adjusted .tir, sweep Fz x alpha and Fz x kappa, fit Pacejka 1987 coefficients for C++

%% settings

fitDataFile = "/home/elijah/code/Research/VD/Vehicle_modeling/tire_fit_data.mat";
tireDir     = "/home/elijah/code/Research/VD/Vehicle_modeling/tires";
adjDir      = "/home/elijah/code/Research/VD/Vehicle_modeling/tires/adjusted";
mfevalDir   = "/home/elijah/MATLAB Add-Ons/Toolboxes/MFeval";
coefFile    = "/home/elijah/code/Research/VD/Vehicle_modeling/tire_coeffs.csv";
figDir      = "/home/elijah/code/Research/VD/Vehicle_modeling/report_figs";
exportFigs  = true;

tireFiles = ["2024003_Firestone_Firehawk Left Front SC_RC__275_40R15_MF62_UM4.tir", ...
             "2024003_Firestone_Firehawk Right Front SC_RC__275_40R15_MF62_UM4.tir", ...
             "2024003_Firestone_Firehawk Left Rear SC_RC__385_30R15_MF62_UM4.tir", ...
             "2024003_Firestone_Firehawk Right Rear SC_RC_385_30R15_MF62_UM4.tir"];   % [FL FR RL RR]

nFitMax  = 6000;                          % samples per axle in each fit (stride subsample)
pdy2Grid = [-1 -0.5 0 0.25 0.5 0.75 1 1.25 1.5 2];   % load sensitivity scales profiled, < 0 is unphysical
pdy2Use  = [1 1];                         % scale used per axle, [] = best from the profile

FzGrid    = 250:250:8000;                 % (N) sweep
alphaGrid = -8:0.25:8;                    % (deg) sweep, .tir fit range ALPMAX = 8 deg
kappaGrid = -0.2:0.005:0.2;               % (-) sweep, .tir fit range KPUMAX = 0.2
FzPlot    = 1000:1000:6000;               % (N) loads drawn in the fit plots

cMeas  = [0.165 0.471 0.839];             % blue, measured
cModel = [0.922 0.408 0.204];             % orange, model
cAlt   = [0.106 0.686 0.478];             % aqua, alternative (no load sensitivity)
cCloud = [0.82 0.82 0.82];                % grey, sample cloud
cSeq   = [0.525 0.714 0.937; 0.333 0.596 0.906; 0.165 0.471 0.839; ...
          0.110 0.361 0.671; 0.063 0.259 0.506; 0.051 0.212 0.420];   % sequential blue, FzPlot

%% load data
% ASSUMPTION: Kalman filter axle Fy and wheel dynamics Fx are the measurements
% ASSUMPTION: MF gets -alpha (ISO-W), ours has alpha > 0 -> Fy > 0

addpath(genpath(mfevalDir));
d = load(fitDataFile);

Fz     = d.Fz_dual_obs;                                          % (N) [FL FR RL RR]
alpha  = [d.alpha_fl, d.alpha_fr, d.alpha_rl, d.alpha_rr];       % (rad)
kappa  = [d.kappa_fl, d.kappa_fr, d.kappa_rl, d.kappa_rr];       % (-)
Vx     = [d.Vx_tire_fl, d.Vx_tire_fr, d.Vx_tire_rl, d.Vx_tire_rr];
FxW    = [d.Fx_fl, d.Fx_fr, d.Fx_rl, d.Fx_rr];                    % (N) wheel dynamics
locked = [d.locked_fl, d.locked_fr, d.locked_rl, d.locked_rr];
S      = [d.Fyf_kf, d.Fyr_kf];                                    % (N) measured axle Fy

Fz_ax    = [Fz(:,1) + Fz(:,2), Fz(:,3) + Fz(:,4)];
alpha_ax = rad2deg([d.alpha_f, d.alpha_r]);
llt      = [abs(Fz(:,1) - Fz(:,2)) ./ Fz_ax(:,1), abs(Fz(:,3) - Fz(:,4)) ./ Fz_ax(:,2)];

ok  = all(isfinite([Fz, alpha, kappa, Vx, S]), 2) & d.Fvx > 10;
lat = ok & abs(d.Fax) < 2 & abs(d.ay_tire) > 2;                  % near pure cornering
lon = ok & abs(d.ay_tire) < 2;                                   % near pure longitudinal

fprintf("samples %d, pure cornering %d, pure longitudinal %d\n", numel(d.t), nnz(lat), nnz(lon));

%% base tires (symmetric)
% ASSUMPTION: the mirrored L/R offsets are a toe offset in the files, removed

tir = cell(1, 4);
for i = 1:4
    tir{i} = mfeval.readTIR(char(fullfile(tireDir, tireFiles(i))));
    for c = ["PHY1", "PHY2", "PVY1", "PVY2", "PEY3"]
        tir{i}.(c) = 0;
    end
end

wState = warning("off", "all");   % MFeval warns every time an input is clamped to the fit range
opts   = optimoptions("lsqnonlin", "Display", "off");

%% lateral fit per axle (LMUY, LKY) with load sensitivity profile
% for each PDY2 scale, fit grip (LMUY) and cornering stiffness (LKY) to the axle force
% the scale with the lowest error is what the data supports

rmsProfile = nan(numel(pdy2Grid), 2);
xProfile   = nan(numel(pdy2Grid), 2, 2);   % [scale, (LMUY LKY), axle]
selLat     = strideSample(lat, nFitMax);

for ax = 1:2
    idx = [2*ax - 1, 2*ax];
    for j = 1:numel(pdy2Grid)
        p = tir(idx);
        for k = 1:2
            p{k}.PDY2 = pdy2Grid(j) * tir{idx(k)}.PDY2;
        end
        res = @(x) S(selLat,ax) - axleFyMF(p, x, selLat, idx, Fz, kappa, alpha, Vx);
        x   = lsqnonlin(res, [0.85, 1], [0.3, 0.3], [1.5, 2], opts);

        xProfile(j,:,ax) = x;
        rmsProfile(j,ax) = rms(res(x));
    end
end

[~, jBest] = min(rmsProfile);
jMin    = jBest;
pdy2Sel = pdy2Grid(jBest);
if ~isempty(pdy2Use)
    pdy2Sel = pdy2Use;
    jBest   = arrayfun(@(v) find(pdy2Grid == v, 1), pdy2Use);
end

tirAdj = tir;
for i = 1:4
    ax = ceil(i/2);
    tirAdj{i}.PDY2 = pdy2Sel(ax) * tir{i}.PDY2;
    tirAdj{i}.LMUY = xProfile(jBest(ax),1,ax);
    tirAdj{i}.LKY  = xProfile(jBest(ax),2,ax);
end

for ax = 1:2
    fprintf("axle %d: profile min at PDY2 x%.2f (rms %.0f N), x0 %.0f N, x1 %.0f N -> using x%.2f, LMUY %.3f, LKY %.3f\n", ax, ...
        pdy2Grid(jMin(ax)), rmsProfile(jMin(ax),ax), rmsProfile(pdy2Grid == 0,ax), rmsProfile(pdy2Grid == 1,ax), ...
        pdy2Sel(ax), tirAdj{2*ax}.LMUY, tirAdj{2*ax}.LKY);
end

%% longitudinal fit per axle (LMUX, LKX)
% grip from the upper edge of the data, slip stiffness from low slip
% least squares through noisy kappa flattens the peak, so LMUX is not fitted by least squares
% ASSUMPTION: peak mu_x = 97.5th percentile of |Fx|/Fz where 1% < |kappa| < 5%
% ASSUMPTION: unlocked wheels with Fz > 500 N, slip stiffness from |kappa| < 1%

for ax = 1:2
    idx = [2*ax - 1, 2*ax];
    good = lon & ~locked(:,idx) & Fz(:,idx) > 500;

    band  = good & abs(kappa(:,idx)) > 0.01 & abs(kappa(:,idx)) < 0.05;
    ratio = abs(FxW(:,idx) ./ Fz(:,idx));
    muEnv = prctile(ratio(band), 97.5);

    FzMed = median(Fz(good(:,1),idx(1)));
    out   = mfeval(tirAdj{idx(1)}, [FzMed, 0.03, 0, 0, 0, 30], 121);   % LMUX = 1, col 17 = peak mu_x
    lmux  = muEnv / out(17);

    selW = cell(1, 2);
    for k = 1:2
        selW{k} = strideSample(good(:,k) & abs(kappa(:,idx(k))) < 0.01 & abs(FxW(:,idx(k))) > 100, nFitMax/2);
    end
    res = @(x) [FxW(selW{1},idx(1)) - wheelFxMF(tirAdj{idx(1)}, [lmux, x], selW{1}, idx(1), Fz, kappa, alpha, Vx); ...
                FxW(selW{2},idx(2)) - wheelFxMF(tirAdj{idx(2)}, [lmux, x], selW{2}, idx(2), Fz, kappa, alpha, Vx)];
    lkx = lsqnonlin(res, 1, 0.1, 3, opts);

    for k = 1:2
        tirAdj{idx(k)}.LMUX = lmux;
        tirAdj{idx(k)}.LKX  = lkx;
    end
    fprintf("axle %d: envelope mu_x %.2f -> LMUX %.3f, LKX %.3f (low slip rms %.0f N)\n", ax, muEnv, lmux, lkx, rms(res(lkx)));
end

%% write adjusted .tir files

if ~isfolder(adjDir), mkdir(adjDir); end

for i = 1:4
    changes = struct("PHY1", 0, "PHY2", 0, "PVY1", 0, "PVY2", 0, "PEY3", 0, "PDY2", tirAdj{i}.PDY2, ...
                     "LMUY", tirAdj{i}.LMUY, "LKY", tirAdj{i}.LKY, "LMUX", tirAdj{i}.LMUX, "LKX", tirAdj{i}.LKX);
    writeTir(fullfile(tireDir, tireFiles(i)), fullfile(adjDir, "adjusted_" + tireFiles(i)), changes);
end

%% sweep adjusted MF (pure slip)
% left tire of each axle, left and right are the same once symmetric

[FzA, aA] = ndgrid(FzGrid, alphaGrid);
[FzK, kK] = ndgrid(FzGrid, kappaGrid);
FyS = zeros([size(FzA), 2]);
FxS = zeros([size(FzK), 2]);

for ax = 1:2
    p = mfeval.readTIR(char(fullfile(adjDir, "adjusted_" + tireFiles(2*ax - 1))));   % read back what was written
    n = numel(FzA);
    out = mfeval(p, [FzA(:), zeros(n,1), -deg2rad(aA(:)), zeros(n,2), 30*ones(n,1)], 121);
    FyS(:,:,ax) = reshape(out(:,2), size(FzA));
    n = numel(FzK);
    out = mfeval(p, [FzK(:), kK(:), zeros(n,3), 30*ones(n,1)], 121);
    FxS(:,:,ax) = reshape(out(:,1), size(FzK));

    pR  = mfeval.readTIR(char(fullfile(adjDir, "adjusted_" + tireFiles(2*ax))));
    outR = mfeval(pR, [FzA(:), zeros(numel(FzA),1), -deg2rad(aA(:)), zeros(numel(FzA),2), 30*ones(numel(FzA),1)], 121);
    fprintf("axle %d: left vs right pure Fy max difference %.1f N\n", ax, max(abs(outR(:,2) - reshape(FyS(:,:,ax), [], 1))));
end

%% fit Pacejka 1987 coefficients (tires.pdf)
% Fy: D = a1 Fz^2 + a2 Fz, BCD = a3 sin(a4 atan(a5 Fz)), E = a6 Fz^2 + a7 Fz + a8, alpha in deg
% Fx: D = a1 Fz^2 + a2 Fz, BCD = (a3 Fz^2 + a4 Fz) exp(-a5 Fz), E = a6 Fz^2 + a7 Fz + a8, kappa in %
% F = D sin(C atan(B phi)), phi = (1 - E) s + E/B atan(B s), B = BCD / (C D), Fz in kN
% ASSUMPTION: C is fitted too (pdf fixes 1.30 / 1.65, the .tir PCY1 is 1.34-1.38)
% ASSUMPTION: no camber terms (a9-a13 = 0), no shifts, symmetric curves

lsqOpts = optimoptions("lsqcurvefit", "Display", "off", "MaxFunctionEvaluations", 2e4, "MaxIterations", 2e3);
FzkN = FzGrid' / 1000;
i0y  = find(alphaGrid == 0);
i0x  = find(kappaGrid == 0);

cFy = zeros(2, 9);
cFx = zeros(2, 9);
fitErr = zeros(2, 2);   % rms error as % of peak, [axle, (Fy Fx)]

for ax = 1:2
    % Fy, start from the per load peak and stiffness
    Dy   = max(abs(FyS(:,:,ax)), [], 2);
    BCDy = (FyS(:,i0y+1,ax) - FyS(:,i0y-1,ax)) / (2 * 0.25);
    a12  = [FzkN.^2, FzkN] \ Dy;
    a345 = lsqcurvefit(@(a, z) a(1) .* sin(a(2) .* atan(a(3) .* z)), [max(BCDy), 1.5, 0.3], FzkN, BCDy, [], [], lsqOpts);
    c0   = [1.3, a12', a345, 0, 0, -0.5];

    X = [aA(:), FzA(:) / 1000];
    cFy(ax,:) = lsqcurvefit(@(c, X) pac87Fy(c, X(:,1), X(:,2)), c0, X, reshape(FyS(:,:,ax), [], 1), [], [], lsqOpts);
    fitErr(ax,1) = 100 * rms(pac87Fy(cFy(ax,:), X(:,1), X(:,2)) - reshape(FyS(:,:,ax), [], 1)) / max(abs(FyS(:,:,ax)), [], "all");

    % Fx
    Dx   = max(abs(FxS(:,:,ax)), [], 2);
    BCDx = (FxS(:,i0x+1,ax) - FxS(:,i0x-1,ax)) / (2 * 0.5);   % per % slip
    a12  = [FzkN.^2, FzkN] \ Dx;
    c0   = [1.65, a12', 0, mean(BCDx ./ FzkN), 0, 0, 0, -0.5];

    X = [100 * kK(:), FzK(:) / 1000];
    cFx(ax,:) = lsqcurvefit(@(c, X) pac87Fx(c, X(:,1), X(:,2)), c0, X, reshape(FxS(:,:,ax), [], 1), [], [], lsqOpts);
    fitErr(ax,2) = 100 * rms(pac87Fx(cFx(ax,:), X(:,1), X(:,2)) - reshape(FxS(:,:,ax), [], 1)) / max(abs(FxS(:,:,ax)), [], "all");

    fprintf("axle %d: Pacejka 87 fit rms error Fy %.2f%%, Fx %.2f%% of peak\n", ax, fitErr(ax,1), fitErr(ax,2));
end

%% export coefficients (C++)

coefNames = ["C", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8"];
coefTable = array2table([cFy; cFx], "VariableNames", coefNames, ...
    "RowNames", ["Fy_front", "Fy_rear", "Fx_front", "Fx_rear"]);
writetable(coefTable, coefFile, "WriteRowNames", true);

fprintf("\n%% paste into vehicle_model.m\n");
fprintf("vehicleParams.pacFy_f = %s;\n", mat2str(cFy(1,:), 6));
fprintf("vehicleParams.pacFy_r = %s;\n", mat2str(cFy(2,:), 6));
fprintf("vehicleParams.pacFx_f = %s;\n", mat2str(cFx(1,:), 6));
fprintf("vehicleParams.pacFx_r = %s;\n", mat2str(cFx(2,:), 6));

%% validation on the car data (axle level)
% model axle Fy at every pure cornering sample, file load sensitivity (x1) vs none (x0), and the Pacejka 87 fit

jVar  = [find(pdy2Grid == 1, 1), find(pdy2Grid == 0, 1)];   % [x1, x0]
FyAx  = zeros(numel(d.t), 2, 2);                            % [sample, axle, variant]
muAx  = nan(numel(d.t), 2, 2);
FyAx_pac = zeros(numel(d.t), 2);

for ax = 1:2
    idx = [2*ax - 1, 2*ax];
    muT = nan(numel(d.t), 2, 2);
    for v = 1:2
        for k = 1:2
            i = idx(k);
            p = tir{i};
            p.PDY2 = pdy2Grid(jVar(v)) * tir{i}.PDY2;
            p.LMUY = xProfile(jVar(v),1,ax);
            p.LKY  = xProfile(jVar(v),2,ax);
            out = mfeval(p, [Fz(lat,i), kappa(lat,i), -alpha(lat,i), zeros(nnz(lat),2), Vx(lat,i)], 121);
            FyAx(lat,ax,v) = FyAx(lat,ax,v) + out(:,2);
            muT(lat,k,v)   = out(:,18);
        end
        muAx(:,ax,v) = (muT(:,1,v) .* Fz(:,idx(1)) + muT(:,2,v) .* Fz(:,idx(2))) ./ Fz_ax(:,ax);
    end
    for k = 1:2
        FyAx_pac(lat,ax) = FyAx_pac(lat,ax) + pac87Fy(cFy(ax,:), rad2deg(alpha(lat,idx(k))), Fz(lat,idx(k)) / 1000);
    end
end

warning(wState);

for ax = 1:2
    fprintf("axle %d on %d samples: rms axle error x1 %.0f N, x0 %.0f N, Pacejka 87 %.0f N\n", ax, nnz(lat), ...
        rms(S(lat,ax) - FyAx(lat,ax,1)), rms(S(lat,ax) - FyAx(lat,ax,2)), rms(S(lat,ax) - FyAx_pac(lat,ax)));
end

%% plots load sensitivity profile

axleNames = ["Front axle", "Rear axle"];
figs = gobjects(0);

figs(end+1) = figure("Name", "fig1_pdy2_profile", "Position", [100 100 900 360]);
tl = tiledlayout(1, 2, "TileSpacing", "compact");
for ax = 1:2
    nexttile(tl);
    hold on
    xregion(min(pdy2Grid), 0, "FaceColor", cCloud);
    plot(pdy2Grid, rmsProfile(:,ax), "-o", "Color", cMeas);
    plot(pdy2Grid(jBest(ax)), rmsProfile(jBest(ax),ax), "o", "Color", cModel, "MarkerFaceColor", cModel);
    grid on
    title(axleNames(ax));
    xlabel("PDY2 scale (0 = none, 1 = .tir file, < 0 unphysical)");
    ylabel("axle F_y rms error [N]");
end

%% plots axle curve shape

aEdges = 0:0.5:6;

figs(end+1) = figure("Name", "fig2_axle_curve", "Position", [100 100 900 360]);
tl = tiledlayout(1, 2, "TileSpacing", "compact");
for ax = 1:2
    nexttile(tl);
    hold on
    plot(abs(alpha_ax(lat,ax)), abs(S(lat,ax)) ./ Fz_ax(lat,ax), ".", "Color", cCloud);
    [m, y] = binMed(abs(alpha_ax(lat,ax)), abs(S(lat,ax)) ./ Fz_ax(lat,ax), aEdges);
    plot(m, y, "-o", "Color", cMeas);
    [m, y] = binMed(abs(alpha_ax(lat,ax)), abs(FyAx(lat,ax,1)) ./ Fz_ax(lat,ax), aEdges);
    plot(m, y, "-s", "Color", cModel);
    [m, y] = binMed(abs(alpha_ax(lat,ax)), abs(FyAx_pac(lat,ax)) ./ Fz_ax(lat,ax), aEdges);
    plot(m, y, "--", "Color", cAlt);
    grid on
    xlim([0 6]);
    title(axleNames(ax));
    xlabel("axle slip angle |\alpha| [deg]");
    ylabel("|F_y| / F_z axle [-]");
    legend("samples", "measured median", "adjusted MF (x1)", "Pacejka 87 fit", "Location", "southeast");
end

%% plots residual vs load (Fy vs Fz check)
% flat at zero = the model gets Fy vs Fz right across load, bank and load transfer

xs     = {Fz_ax, repmat(d.az_road, 1, 2), llt};
xNames = ["axle F_z [N]", "a_z road [m/s^2]", "load transfer |F_{zL} - F_{zR}| / F_z [-]"];

figs(end+1) = figure("Name", "fig3_residual_vs_load", "Position", [100 100 1200 620]);
tl = tiledlayout(2, 3, "TileSpacing", "compact");
for ax = 1:2
    for q = 1:3
        nexttile(tl);
        hold on
        x = xs{q}(lat,ax);
        edges = prctile(x, 0:10:100);
        [m, y] = binMed(x, (S(lat,ax) - FyAx(lat,ax,1)) .* sign(S(lat,ax)) ./ Fz_ax(lat,ax), edges);
        plot(m, y, "-o", "Color", cModel);
        [m, y] = binMed(x, (S(lat,ax) - FyAx(lat,ax,2)) .* sign(S(lat,ax)) ./ Fz_ax(lat,ax), edges);
        plot(m, y, "-s", "Color", cAlt);
        yline(0, "k:");
        grid on
        title(axleNames(ax));
        xlabel(xNames(q));
        ylabel("(measured - model) / F_z [-]");
        if ax == 1 && q == 1
            legend(".tir load sensitivity (x1)", "no load sensitivity (x0)", "Location", "north");
        end
    end
end

%% plots saturated grip vs axle load

figs(end+1) = figure("Name", "fig4_saturated_grip", "Position", [100 100 900 360]);
tl = tiledlayout(1, 2, "TileSpacing", "compact");
for ax = 1:2
    nexttile(tl);
    hold on
    sat = lat & abs(alpha_ax(:,ax)) > 3;
    plot(Fz_ax(sat,ax), abs(S(sat,ax)) ./ Fz_ax(sat,ax), ".", "Color", cCloud);
    edges = prctile(Fz_ax(sat,ax), 0:20:100);
    edges(end) = edges(end) + 1;
    [m, y] = binMed(Fz_ax(sat,ax), abs(S(sat,ax)) ./ Fz_ax(sat,ax), edges, 15);
    plot(m, y, "-o", "Color", cMeas);
    [m, y] = binMed(Fz_ax(sat,ax), muAx(sat,ax,1), edges, 15);
    plot(m, y, "-s", "Color", cModel);
    [m, y] = binMed(Fz_ax(sat,ax), muAx(sat,ax,2), edges, 15);
    plot(m, y, "-^", "Color", cAlt);
    grid on
    title(axleNames(ax) + ", |\alpha| > 3 deg");
    xlabel("axle F_z [N]");
    ylabel("|F_y| / F_z axle [-]");
    legend("samples", "measured median", "peak, .tir load sensitivity (x1)", "peak, none (x0)", "Location", "southwest");
end

%% plots Pacejka 87 fit, lateral

figs(end+1) = figure("Name", "fig5_fit_Fy", "Position", [100 100 900 380]);
tl = tiledlayout(1, 2, "TileSpacing", "compact");
for ax = 1:2
    nexttile(tl);
    hold on
    for q = 1:numel(FzPlot)
        iz = find(FzGrid == FzPlot(q), 1);
        plot(alphaGrid(1:4:end), FyS(iz,1:4:end,ax), "o", "Color", cSeq(q,:), "HandleVisibility", "off");
        plot(alphaGrid, pac87Fy(cFy(ax,:), alphaGrid, FzPlot(q) / 1000), "-", "Color", cSeq(q,:), ...
            "DisplayName", sprintf("F_z %.0f kN", FzPlot(q) / 1000));
    end
    grid on
    title(axleNames(ax) + " F_y (dots adjusted MF, lines Pacejka 87)");
    xlabel("\alpha [deg]");
    ylabel("F_y [N]");
    legend("Location", "southeast");
end

%% plots load dependence of the fit

FzFine = linspace(0.25, 8, 100);

figs(end+1) = figure("Name", "fig6_load_dependence", "Position", [100 100 900 620]);
tl = tiledlayout(2, 2, "TileSpacing", "compact");
for ax = 1:2
    nexttile(tl, ax);
    hold on
    plot(FzkN, max(abs(FyS(:,:,ax)), [], 2) ./ (FzkN * 1000), "o", "Color", cMeas);
    plot(FzFine, (cFy(ax,2) .* FzFine.^2 + cFy(ax,3) .* FzFine) ./ (FzFine * 1000), "-", "Color", cModel);
    grid on
    title(axleNames(ax) + " peak \mu_y = D / F_z");
    xlabel("F_z [kN]");
    ylabel("\mu_y [-]");
    legend("adjusted MF", "Pacejka 87 fit", "Location", "northeast");

    nexttile(tl, ax + 2);
    hold on
    plot(FzkN, (FyS(:,i0y+1,ax) - FyS(:,i0y-1,ax)) / 0.5, "o", "Color", cMeas);
    plot(FzFine, cFy(ax,4) .* sin(cFy(ax,5) .* atan(cFy(ax,6) .* FzFine)), "-", "Color", cModel);
    grid on
    title(axleNames(ax) + " cornering stiffness BCD");
    xlabel("F_z [kN]");
    ylabel("C_\alpha [N/deg]");
end

%% plots Pacejka 87 fit, longitudinal

figs(end+1) = figure("Name", "fig7_fit_Fx", "Position", [100 100 900 380]);
tl = tiledlayout(1, 2, "TileSpacing", "compact");
for ax = 1:2
    nexttile(tl);
    hold on
    for q = 1:numel(FzPlot)
        iz = find(FzGrid == FzPlot(q), 1);
        plot(100 * kappaGrid(1:4:end), FxS(iz,1:4:end,ax), "o", "Color", cSeq(q,:), "HandleVisibility", "off");
        plot(100 * kappaGrid, pac87Fx(cFx(ax,:), 100 * kappaGrid, FzPlot(q) / 1000), "-", "Color", cSeq(q,:), ...
            "DisplayName", sprintf("F_z %.0f kN", FzPlot(q) / 1000));
    end
    grid on
    title(axleNames(ax) + " F_x (dots adjusted MF, lines Pacejka 87)");
    xlabel("\kappa [%]");
    ylabel("F_x [N]");
    legend("Location", "southeast");
end

%% plots longitudinal data check, per wheel

wheelNames = ["FL", "FR", "RL", "RR"];

figs(end+1) = figure("Name", "fig8_Fx_data", "Position", [100 100 900 620]);
tl = tiledlayout(2, 2, "TileSpacing", "compact");
for i = 1:4
    ax = ceil(i/2);
    nexttile(tl);
    hold on
    selP = lon & ~locked(:,i) & Fz(:,i) > 200 & abs(kappa(:,i)) < 0.15;
    plot(100 * kappa(selP,i), FxW(selP,i) ./ Fz(selP,i), ".", "Color", cCloud);
    FzMed = median(Fz(selP,i)) / 1000;
    kk = linspace(-15, 15, 200);
    plot(kk, pac87Fx(cFx(ax,:), kk, FzMed) / (FzMed * 1000), "-", "Color", cModel);
    grid on
    xlim([-15 15]);
    title(sprintf("%s (model at median F_z %.1f kN)", wheelNames(i), FzMed));
    xlabel("\kappa [%]");
    ylabel("F_x / F_z [-]");
end

%% export figures

if exportFigs
    if ~isfolder(figDir), mkdir(figDir); end
    for f = figs
        theme(f, "light");
        exportgraphics(f, fullfile(figDir, f.Name + ".png"), "Resolution", 150);
    end
end


function sel = strideSample(mask, nMax)
% every n-th true sample of mask, at most nMax

    idx = find(mask);
    idx = idx(1:max(1, floor(numel(idx) / nMax)):end);
    sel = false(size(mask));
    sel(idx) = true;
end


function Fy = axleFyMF(p, x, sel, idx, Fz, kappa, alpha, Vx)
% MF axle Fy with LMUY = x(1), LKY = x(2) on both tires

    Fy = zeros(nnz(sel), 1);
    for k = 1:2
        i = idx(k);
        p{k}.LMUY = x(1);
        p{k}.LKY  = x(2);
        out = mfeval(p{k}, [Fz(sel,i), kappa(sel,i), -alpha(sel,i), zeros(nnz(sel),2), Vx(sel,i)], 121);
        Fy  = Fy + out(:,2);
    end
end


function Fx = wheelFxMF(p, x, sel, i, Fz, kappa, alpha, Vx)
% MF wheel Fx with LMUX = x(1), LKX = x(2)

    p.LMUX = x(1);
    p.LKX  = x(2);
    out = mfeval(p, [Fz(sel,i), kappa(sel,i), -alpha(sel,i), zeros(nnz(sel),2), Vx(sel,i)], 121);
    Fx  = out(:,1);
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


function writeTir(src, dst, changes)
% copy a .tir file with the listed parameters replaced

    L = readlines(src);
    names = string(fieldnames(changes));
    for k = 1:numel(names)
        hit = ~cellfun(@isempty, regexp(L, "^\s*" + names(k) + "\s*=", "once"));
        L(hit) = regexprep(L(hit), "=\s*[-+0-9.eE]+", "= " + sprintf("%.6g", changes.(names(k))), "once");
    end
    writelines(L, dst);
end


function [mid, med] = binMed(x, y, edges, nMin)
% median of y in each bin of x, bins with fewer than nMin samples (default 30) left out

    if nargin < 4, nMin = 30; end
    mid = 0.5 * (edges(1:end-1) + edges(2:end));
    med = nan(size(mid));
    for b = 1:numel(mid)
        s = x >= edges(b) & x < edges(b+1) & isfinite(y);
        if nnz(s) >= nMin
            med(b) = median(y(s));
        end
    end
end
