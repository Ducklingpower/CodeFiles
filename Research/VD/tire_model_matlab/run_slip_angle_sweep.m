
clear; close all; clc

%% ------------------------------ CONFIG ---------------------------------
axle        = 'rear';      % 'front' | 'rear' | path to a PAIRSIM_config JSON,
                            % e.g. '~/PAIRSIM_config/Parameters/FrontAxleTireParams.json'
                            % (the JSON is what the sim actually runs -- see README)

FzList      = [1000 1700 2500 3400 5100];   % [N] normal loads to sweep
alphaMaxDeg = 15;           % [deg] slip-angle sweep half-range
nAlpha      = 601;          % samples across the sweep

kappaMax    = 0.30;         % [-] slip-ratio sweep half-range
kappaCombo  = [0 0.02 0.05 0.10 0.20];  % slip ratios for the combined-slip plot
FzCombo     = [];           % [N] load for combined plots ([] -> use FzNom)

useThermal  = false;        % mirrors IsThermalTyre in the sim's vehicle setup
tyreTempC   = 70;           % [degC] tyre temperature when useThermal is true

exportCsv   = true;
csvFile     = 'tire_curves_slip_angle.csv';

% --- measured-data overlay (figure 3) ------------------------------------
% Longitudinal only for now. The CSVs come from the "export the fig S8
% longitudinal slip data" section of ../brake_anylisis/notmal_force_estimation.m,
% one row per sample per tire, both tires of an axle concatenated.
overlayMeasured  = true;
measuredFront    = 'measured_slip_ratio_front.csv';
measuredRear     = 'measured_slip_ratio_rear.csv';

% Which slip-ratio column to plot the data against. The log computes
% (Vw - Vx)/Vw; the model's sx is (Vw - Vx)/|Vx|. They agree for small slip
% and diverge as it grows, so 'slip_ratio_vx_ref' is the like-for-like
% comparison and 'slip_ratio' is what fig S8 shows.
measuredSlipCol  = 'slip_ratio_vx_ref';   % or 'slip_ratio'

% Zero-slip offset subtracted from the measured slip ratio, [front rear].
% A rolling-radius or wheel-speed trim that is slightly off puts a constant
% slip on a tire that is only rolling, which slides the whole cloud sideways;
% this slides it back. Applied to the plot only - the CSV keeps the raw
% measurement, so this stays visible as a correction rather than becoming part
% of the data.
measuredSlipOffset = [0.005 0];

% Model curves are drawn at these percentiles of the measured Fz, so the band
% brackets the loads the data was actually taken at.
measuredFzPct    = [0.10 0.50 0.90];

% Draw the previous parameter set alongside the current one. Same colour per
% load, dashed instead of solid, so a pair of curves in one colour is the same
% load under the two models.
overlayOldModel  = true;
oldModelSpecs    = {'front_old', 'rear_old'};

%% --------------------------- BUILD PARAMS ------------------------------
p            = tire_params(axle);
p.useThermal = useThermal;

if isempty(FzCombo), FzCombo = p.FzNom; end

alphaDeg = linspace(-alphaMaxDeg, alphaMaxDeg, nAlpha).';
syRad    = deg2rad(alphaDeg);            % this is 'sy' in the sim
kappa    = linspace(-kappaMax, kappaMax, nAlpha).';

nFz   = numel(FzList);
lbl   = arrayfun(@(f) sprintf('F_z = %g N', f), FzList, 'UniformOutput', false);
cols  = lines(max(nFz, numel(kappaCombo)));

%% ----------------------- PURE-SLIP SWEEPS ------------------------------
FyPure = zeros(nAlpha, nFz);    % lateral, sx = 0
FxPure = zeros(nAlpha, nFz);    % longitudinal, sy = 0
Cal    = zeros(1, nFz);         % cornering stiffness [N/rad]
DyEff  = zeros(1, nFz);

for k = 1:nFz
    [~, FyPure(:,k), infoY] = tire_forces(p, syRad, 0, FzList(k), tyreTempC);
    FxPure(:,k)             = tire_forces(p, 0, kappa, FzList(k), tyreTempC);
    Cal(k)                  = infoY.Cy_alpha;
    DyEff(k)                = infoY.DyEff;
end

%% --------------------------- SUMMARY -----------------------------------
if useThermal
    kTnow      = lut1d_nonlinear(p.numPointsFrictionMap, p.thermalFrictionMapInput, ...
                                 p.thermalFrictionMapOutput, tyreTempC);
    thermalTag = sprintf('ON, T = %g degC, k_T = %.4f', tyreTempC, kTnow);
else
    thermalTag = 'OFF';
end
fprintf('\nTyre parameter set: %s   (thermal %s)\n', p.name, thermalTag);
fprintf('Dy=%.3f Dy2=%.3f Cy=%.3f syPeak=%.5f rad (%.2f deg)  ->  By=%.3f\n', ...
        p.Dy, p.Dy2, p.Cy, p.syPeak, rad2deg(p.syPeak), tan(pi/(2*p.Cy))/p.syPeak);
fprintf('Dx=%.3f Dx2=%.3f Cx=%.3f sxPeak=%.5f            ->  Bx=%.3f\n\n', ...
        p.Dx, p.Dx2, p.Cx, p.sxPeak, tan(pi/(2*p.Cx))/p.sxPeak);

fprintf('%10s %9s %11s %11s %9s %13s\n', ...
        'Fz [N]', 'Dy_eff', 'Fy_peak[N]', 'a_peak[deg]', 'mu_y', 'C_alpha[N/deg]');
fprintf('%s\n', repmat('-', 1, 68));
for k = 1:nFz
    pos            = alphaDeg >= 0;
    [FyMax, iPeak] = max(FyPure(pos,k));
    aPos           = alphaDeg(pos);
    fprintf('%10.0f %9.3f %11.1f %11.2f %9.3f %13.1f\n', ...
            FzList(k), DyEff(k), FyMax, aPos(iPeak), FyMax/FzList(k), Cal(k)*pi/180);
end
fprintf('\n');

%% ---------------------- FIGURE 1: pure slip ----------------------------
figure();

subplot(2,2,1); hold on; grid on; box on
for k = 1:nFz
    plot(alphaDeg, FyPure(:,k), 'LineWidth', 1.6, 'Color', cols(k,:));
end
plot(rad2deg(p.syPeak)*[1 1], ylim, 'k--', 'HandleVisibility', 'off');
xlabel('slip angle \alpha = s_y [deg]'); ylabel('F_y [N]');
title('Lateral force vs slip angle (s_x = 0)');
legend(lbl, 'Location', 'southeast'); legend boxoff

subplot(2,2,2); hold on; grid on; box on
for k = 1:nFz
    plot(alphaDeg, FyPure(:,k)/FzList(k), 'LineWidth', 1.6, 'Color', cols(k,:));
end
xlabel('slip angle \alpha [deg]'); ylabel('F_y / F_z [-]');
title('Normalised -- shows the load sensitivity D_{y2}');

subplot(2,2,3); hold on; grid on; box on
for k = 1:nFz
    plot(kappa, FxPure(:,k), 'LineWidth', 1.6, 'Color', cols(k,:));
end
plot(p.sxPeak*[1 1], ylim, 'k--', 'HandleVisibility', 'off');
xlabel('slip ratio s_x [-]'); ylabel('F_x [N]');
title('Longitudinal force vs slip ratio (s_y = 0)');

subplot(2,2,4); hold on; grid on; box on
Tv = linspace(0, 160, 400);
kT = lut1d_nonlinear(p.numPointsFrictionMap, p.thermalFrictionMapInput, ...
                     p.thermalFrictionMapOutput, Tv);
plot(Tv, kT, 'LineWidth', 1.6);
plot(p.thermalFrictionMapInput, p.thermalFrictionMapOutput, 'ko', 'MarkerFaceColor', 'w');
if useThermal
    plot(tyreTempC, kTnow, 'rp', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
    mapState = 'ACTIVE';
else
    mapState = 'inactive';
end
xlabel('tyre temperature [degC]'); ylabel('grip scaling k_T [-]');
title(sprintf('Thermal friction map (%s)', mapState));

%% -------------------- FIGURE 2: combined slip --------------------------
figure();

subplot(1,2,1); hold on; grid on; box on
lblK = cell(1, numel(kappaCombo));
for k = 1:numel(kappaCombo)
    [~, FyC] = tire_forces(p, syRad, kappaCombo(k), FzCombo, tyreTempC);
    plot(alphaDeg, FyC, 'LineWidth', 1.6, 'Color', cols(k,:));
    lblK{k} = sprintf('s_x = %.2f', kappaCombo(k));
end
xlabel('slip angle \alpha [deg]'); ylabel('F_y [N]');
title(sprintf('Lateral force lost to s_x  (F_z = %g N)', FzCombo));
legend(lblK, 'Location', 'southeast'); legend boxoff

subplot(1,2,2); hold on; grid on; box on
Slevels = [0.02 0.05 0.10 0.20 0.40];
theta   = linspace(0, 2*pi, 721);
for k = 1:numel(Slevels)
    syE = Slevels(k)*sin(theta);
    sxE = Slevels(k)*cos(theta);
    [FxE, FyE] = tire_forces(p, syE, sxE, FzCombo, tyreTempC);
    plot(FxE, FyE, 'LineWidth', 1.4, 'Color', cols(min(k,size(cols,1)),:));
end
axis equal; xlabel('F_x [N]'); ylabel('F_y [N]');
title('Friction ellipse: constant |S| loci');
legend(arrayfun(@(s) sprintf('|S| = %.2f', s), Slevels, 'UniformOutput', false), ...
       'Location', 'eastoutside'); legend boxoff

%% ------------- FIGURE 3: model over the measured slip data --------------
% Normalised on both sides: the data is Fx/Fz per sample, the model is
% Fx(sx, Fz)/Fz at a few loads. Fx/Fz is not one curve for the model - Dx_eff
% carries the load sensitivity Dx2 - so the three curves show the band the
% measured loads span rather than a single line to fit against.

if overlayMeasured

    measuredFiles = {measuredFront, measuredRear};
    measuredAxles = {'front', 'rear'};

    % The CSVs are written next to this script, so resolve against its own
    % folder rather than whatever the current directory happens to be.
    scriptDir = fileparts(mfilename('fullpath'));

    if isempty(scriptDir)
        scriptDir = pwd;
    end

    figure();

    axMeas = gobjects(1,2);

    for iAxle = 1:2

        f = fullfile(scriptDir, measuredFiles{iAxle});

        if exist(f, 'file') ~= 2
            warning('run_slip_angle_sweep:noMeasuredCsv', ...
                ['%s not found. Run the "export the fig S8 longitudinal slip ' ...
                 'data" section of notmal_force_estimation.m first.'], f);
            continue
        end

        M = readtable(f);

        if ~ismember(measuredSlipCol, M.Properties.VariableNames)
            error('run_slip_angle_sweep:noSlipColumn', ...
                  '%s has no column %s.', f, measuredSlipCol);
        end

        kappaMeas = M.(measuredSlipCol) - measuredSlipOffset(iAxle);
        ratioMeas = M.Fx_over_Fz;
        FzMeas    = M.Fz_N;

        good      = isfinite(kappaMeas) & isfinite(ratioMeas) & isfinite(FzMeas);
        kappaMeas = kappaMeas(good);
        ratioMeas = ratioMeas(good);
        FzMeas    = FzMeas(good);

        if isempty(kappaMeas)
            warning('run_slip_angle_sweep:emptyMeasuredCsv', ...
                    '%s has no usable rows.', f);
            continue
        end

        % Model at the loads the data was actually taken at.
        FzSorted  = sort(FzMeas);
        FzLevels  = FzSorted(max(1, round(measuredFzPct * numel(FzSorted))));
        FzLevels  = unique(round(FzLevels));

        pAxle     = tire_params(measuredAxles{iAxle});
        pAxle.useThermal = useThermal;

        if overlayOldModel
            pOld = tire_params(oldModelSpecs{iAxle});
            pOld.useThermal = useThermal;
        end

        kappaModel = linspace(-kappaMax, kappaMax, nAlpha).';

        axMeas(iAxle) = subplot(1, 2, iAxle);
        hold on; grid on; box on

        if measuredSlipOffset(iAxle) == 0
            measLabel = 'measured';
        else
            measLabel = sprintf('measured', -measuredSlipOffset(iAxle));
        end

        scatter(kappaMeas, ratioMeas, 8, [0.60 0.60 0.60], 'filled', ...
                'MarkerFaceAlpha', 0.25, 'DisplayName', measLabel);

        for k = 1:numel(FzLevels)

            colK = cols(min(k, size(cols,1)),:);

            FxModel = tire_forces(pAxle, 0, kappaModel, FzLevels(k), tyreTempC);
            plot(kappaModel, FxModel / FzLevels(k), 'LineWidth', 1.8, ...
                 'Color', colK, ...
                 'DisplayName', sprintf('new, F_z = %g N', FzLevels(k)));

            if overlayOldModel
                FxOld = tire_forces(pOld, 0, kappaModel, FzLevels(k), tyreTempC);
                plot(kappaModel, FxOld / FzLevels(k), '--', 'LineWidth', 1.4, ...
                     'Color', colK, ...
                     'DisplayName', sprintf('old, F_z = %g N', FzLevels(k)));
            end
        end

        xline(0, 'k--', 'HandleVisibility', 'off');
        yline(0, 'k--', 'HandleVisibility', 'off');

        xlabel(sprintf('slip ratio %s [-]', strrep(measuredSlipCol, '_', '\_')));
        ylabel('F_x / F_z [-]');
        title(sprintf('%s axle  (%d samples, F_z %.0f-%.0f N)', ...
              measuredAxles{iAxle}, numel(kappaMeas), min(FzMeas), max(FzMeas)));
        legend('Location', 'best'); legend boxoff

        xlim([-kappaMax kappaMax]);

        fprintf(['%5s measured: %6d samples, slip offset %+.4f, ' ...
                 'kappa %.3f..%.3f, Fx/Fz %.2f..%.2f, model drawn at Fz = %s N\n'], ...
                measuredAxles{iAxle}, numel(kappaMeas), ...
                -measuredSlipOffset(iAxle), ...
                min(kappaMeas), max(kappaMeas), ...
                min(ratioMeas), max(ratioMeas), ...
                strjoin(string(FzLevels(:).'), ', '));

        % Peak mu_x at the median measured load: the one number the two
        % parameter sets are really being judged on against this data.
        FzMid         = median(FzMeas);
        FxNewMid      = tire_forces(pAxle, 0, kappaModel, FzMid, tyreTempC);
        [muNew, iNew] = max(abs(FxNewMid) / FzMid);

        if overlayOldModel
            FxOldMid      = tire_forces(pOld, 0, kappaModel, FzMid, tyreTempC);
            [muOld, iOld] = max(abs(FxOldMid) / FzMid);

            fprintf(['%5s peak mu_x at median F_z = %.0f N:  %s %.3f at |s_x| = %.3f' ...
                     '   |   %s %.3f at |s_x| = %.3f\n'], ...
                    measuredAxles{iAxle}, FzMid, ...
                    pAxle.name, muNew, abs(kappaModel(iNew)), ...
                    pOld.name,  muOld, abs(kappaModel(iOld)));
        else
            fprintf('%5s peak mu_x at median F_z = %.0f N:  %s %.3f at |s_x| = %.3f\n', ...
                    measuredAxles{iAxle}, FzMid, ...
                    pAxle.name, muNew, abs(kappaModel(iNew)));
        end
    end

    if overlayOldModel
        sgtitle(['Tyre model over measured longitudinal slip (pure s_x, s_y = 0)' ...
                 '   -   solid = current params, dashed = old params']);
    else
        sgtitle('Tyre model over measured longitudinal slip (pure s_x, s_y = 0)');
    end
end

%% ----------------------------- EXPORT ----------------------------------
if exportCsv
    fid = fopen(csvFile, 'w');
    fprintf(fid, 'alpha_deg,alpha_rad');
    fprintf(fid, ',Fy_N_Fz%g', FzList);
    fprintf(fid, ',slip_ratio');
    fprintf(fid, ',Fx_N_Fz%g', FzList);
    fprintf(fid, '\n');
    M = [alphaDeg, syRad, FyPure, kappa, FxPure];
    fmt = [repmat('%.6g,', 1, size(M,2)-1) '%.6g\n'];
    fprintf(fid, fmt, M.');
    fclose(fid);
    fprintf('Wrote %s  (%d rows)\n', fullfile(pwd, csvFile), size(M,1));
end
