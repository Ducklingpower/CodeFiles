%% =====================================================================
%  ENGINE MAP ANALYSIS  -  0-30-100 vs 0-30-60-100 knot comparison (3D)
%
%  Loads:
%    1) no-boost engine map   (csv:  rpm , throttle columns -> torque Nm)
%    2) new dyno data         (xlsx: many (PSI, throttle) torque sweeps)
%
%  Produces (for one PSI = psi_to_plot):
%    measured points (black) vs the 0-30-100 surface (dark red)
%    vs the 0-30-60-100 surface (dark green)  -  the undershoot, in 3D.
%  ====================================================================

clear; clc; close all;

% ----------------------- FILES (edit paths here) ----------------------
file_no_boost   = '/home/elijah/PurdueRacing/on-vehicle/on-vehicle/src/control/acceleration_interface/config/engine_map_no_boost.csv';        % 1: no-boost (0 boost) map
file_full_boost = '/home/elijah/PurdueRacing/on-vehicle/on-vehicle/src/control/acceleration_interface/config/engine_map_boosted_reduced.csv'; % 2: 100-boost map
file_new_data   = '/home/elijah/Downloads/Dyno.xlsx'; % 3: all-PSI dyno data
new_data_sheet  = 'Combined_1RPM';

% Generated engine-map CSVs from Claude/final LUT build.
% Only edit file_map_24psi if the config directory moves; the other
% generated CSVs are assumed to live in the same folder.
file_map_24psi  = '/home/elijah/PurdueRacing/on-vehicle/on-vehicle/src/control/acceleration_interface/config/engine_map_24psi.csv';
generated_map_dir = fileparts(file_map_24psi);

file_map_06psi_A = fullfile(generated_map_dir, 'engine_map_06psi_test-A_spine-from-noboost.csv');
file_map_06psi_B = fullfile(generated_map_dir, 'engine_map_06psi_test-B_spine-from-12psi.csv');
file_map_06psi_C = fullfile(generated_map_dir, 'engine_map_06psi.csv');
file_map_30psi  = fullfile(generated_map_dir, 'engine_map_30psi.csv');

% NOTE:
% The new overlay section below loads the three 6 psi generated maps and
% the 30 psi generated map.  The 24 psi path above is only used to locate
% the shared config directory.

% ----------------------- ANALYSIS SETTINGS ---------------------------
psi_to_plot   = 30;                 % which boost level to dissect
knots_current = [0.00 0.30 1.00];   % the existing scheme
knots_propose = [0.00 0.30 0.60 1.00]; % the proposed scheme
rg            = (3000:50:7250).';   % common rpm grid for the new-data maps
thrFine       = linspace(0,1,101);  % fine throttle axis for smooth surfaces

%% ===================== LOAD THE TWO CSV MAPS =========================
[rpm_nb, thr_nb, T_nb] = loadMapCSV(file_no_boost);    % 0 boost
[rpm_fb, thr_fb, T_fb] = loadMapCSV(file_full_boost);  % 100 boost
fprintf('No-boost map : %d rpm rows, throttle = [%s]\n', ...
        numel(rpm_nb), num2str(thr_nb));
fprintf('Full-boost   : %d rpm rows, throttle = [%s]\n', ...
        numel(rpm_fb), num2str(thr_fb));


%% ===================== LOAD GENERATED CSV MAPS =======================
% These are the final/generated engine maps that live in the config folder.
% They are separate from the raw dyno xlsx data above.
%
% For the requested overlay figures, only the 6 psi generated maps are
% loaded.  The 24 psi path above is only used to locate the shared config
% directory.
checkRequiredFiles({file_no_boost, file_full_boost, file_new_data, ...
                    file_map_06psi_A, file_map_06psi_B, file_map_06psi_C, file_map_30psi});

[rpm_06A, thr_06A, T_06A] = loadMapCSV(file_map_06psi_A);
[rpm_06B, thr_06B, T_06B] = loadMapCSV(file_map_06psi_B);
[rpm_06C, thr_06C, T_06C] = loadMapCSV(file_map_06psi_C);
[rpm_30,  thr_30,  T_30]  = loadMapCSV(file_map_30psi);

fprintf('Generated CSV maps loaded from: %s\n', generated_map_dir);
fprintf('   6 psi A throttle = [%s]\n', num2str(thr_06A));
fprintf('   6 psi B throttle = [%s]\n', num2str(thr_06B));
fprintf('   6 psi C throttle = [%s]\n', num2str(thr_06C));
fprintf('   30 psi throttle  = [%s]\n\n', num2str(thr_30));

%% ===================== LOAD THE NEW DYNO DATA ========================
[rpm_new, PSI, THR, TQ] = loadNewData(file_new_data, new_data_sheet);
avail = unique(PSI(:)).';
fprintf('New data PSI levels: [%s]\n', num2str(avail));
for p = avail
    fprintf('   %2d PSI throttle: [%s]\n', p, num2str(sort(THR(PSI==p)).'));
end
fprintf('\n');

%% ====== MEASURED POINTS vs 0-30-100 vs 0-30-60-100 (3D) ==============
p = psi_to_plot;

% knot torque vectors on the common rpm grid -------------------------
%   borrowed (boost-independent) low-throttle knots come from the NA map
%   measured knots come from the new data at this PSI
getKnotTQ = @(kthr) buildKnotTQ(kthr, rg, p, ...
                    PSI,THR,TQ,rpm_new, rpm_nb,T_nb,thr_nb);

[knotTQ_cur, okCur] = getKnotTQ(knots_current);
[knotTQ_pro, okPro] = getKnotTQ(knots_propose);

if ~okCur || ~okPro
    warning('PSI %d lacks the throttle points needed for these knots.', p);
end

Zcur = surfFromKnots(knots_current, knotTQ_cur, thrFine);  % [thr x rpm]
Zpro = surfFromKnots(knots_propose, knotTQ_pro, thrFine);

figure('Name',sprintf('Fig 4 - %d PSI knot comparison',p));
[RRf,TTf] = meshgrid(rg, thrFine);

% common axis limits so the two panels are directly comparable
zlo = min([0; Zcur(:); Zpro(:)]);
zhi = max([Zcur(:); Zpro(:)]) * 1.05;

% --- panel 1: 0-30-100 (dark red) -----------------------------------
ax1 = subplot(1,2,1); hold(ax1,'on');
surf(ax1, RRf,TTf,Zcur,'FaceAlpha',0.55,'EdgeColor','none','FaceColor',[0.55 0.00 0.00]);
overlayMeasured(ax1, p, PSI,THR,TQ,rpm_new);
applyMapAxes(sprintf('0-30-100  (%d PSI)', p));
view(ax1,135,20); zlim(ax1,[zlo zhi]);

% --- panel 2: 0-30-60-100 (dark green) ------------------------------
ax2 = subplot(1,2,2); hold(ax2,'on');
surf(ax2, RRf,TTf,Zpro,'FaceAlpha',0.55,'EdgeColor','none','FaceColor',[0.00 0.40 0.00]);
overlayMeasured(ax2, p, PSI,THR,TQ,rpm_new);
applyMapAxes(sprintf('0-30-60-100  (%d PSI)', p));
view(ax2,135,20); zlim(ax2,[zlo zhi]);

% link the 3D rotation of the two panels (rotate one -> both follow)
hlink = linkprop([ax1 ax2], ...
        {'CameraPosition','CameraTarget','CameraUpVector','CameraViewAngle'});
setappdata(gcf,'camlink',hlink);   % keep the link object alive with the figure

%% ============== ZERO-BOOST STACKED OVER 100-BOOST (3D) ===============
% Both engine maps in one 3D axes: torque-vs-(rpm,throttle).  The 0-boost
% sheet sits on top of the 100-boost sheet so you can see the gap close up.
figure('Name','Boost comparison - 0 boost over 100 boost'); hold on;
[RRn,TTn] = meshgrid(rpm_nb, thr_nb);
[RRb,TTb] = meshgrid(rpm_fb, thr_fb);
sFB = surf(RRb, TTb, T_fb.', 'FaceColor',[0.85 0.35 0.10], ...   % 100 boost (bottom)
           'FaceAlpha',0.75, 'EdgeAlpha',0.15);
sNB = surf(RRn, TTn, T_nb.', 'FaceColor',[0.20 0.45 0.85], ...   % 0 boost   (top)
           'FaceAlpha',0.85, 'EdgeAlpha',0.15);
applyMapAxes('0 boost (blue) stacked over 100 boost (orange)');
view(135,25);
legend([sNB sFB], {'0 boost','100 boost'}, 'Location','best');

%% ============== GENERATED CSV ENGINE MAP OVERLAYS (3D) ===============
% These plots compare the final/generated CSV maps directly.  This is not
% raw dyno point overlay; this is surface-vs-surface comparison of the maps
% that will be used by the acceleration interface.

% Main comparison requested: A vs B vs C all in one 3D plot.
% Use this first to decide which 6 psi build method makes the most sense.
makeMapOverlay3D3( ...
    'Generated CSV overlay - 6 psi A vs B vs C', ...
    '6 psi generated maps: A vs B vs C', ...
    rpm_06A, thr_06A, T_06A, 'A: spine from no boost', [0.00 0.45 0.80], ...
    rpm_06B, thr_06B, T_06B, 'B: spine from 12 psi',   [0.85 0.35 0.10], ...
    rpm_06C, thr_06C, T_06C, 'C: actual 60% data',     [0.00 0.55 0.15]);

% The 60% throttle slice is the most important comparison because method C
% was created specifically from actual 6 psi / 60% throttle data.
makeThrottleSliceComparison( ...
    '6 psi A/B/C comparison - 60 percent throttle', ...
    '6 psi A/B/C torque at 60% throttle', ...
    0.60, ...
    rpm_06A, thr_06A, T_06A, 'A: spine from no boost', [0.00 0.45 0.80], ...
    rpm_06B, thr_06B, T_06B, 'B: spine from 12 psi',   [0.85 0.35 0.10], ...
    rpm_06C, thr_06C, T_06C, 'C: actual 60% data',     [0.00 0.55 0.15]);

% This shows how far A and B are from C at the actual-data 60% throttle
% slice.  Positive means C predicts more torque than the other method.
makeThrottleDeltaComparison( ...
    '6 psi method delta to C - 60 percent throttle', ...
    '6 psi C minus A/B at 60% throttle', ...
    0.60, ...
    rpm_06A, thr_06A, T_06A, 'C - A', ...
    rpm_06B, thr_06B, T_06B, 'C - B', ...
    rpm_06C, thr_06C, T_06C);

makeMapOverlay3D( ...
    'Generated CSV overlay - 6 psi A vs 6 psi B', ...
    '6 psi test A vs 6 psi test B generated maps', ...
    rpm_06A, thr_06A, T_06A, '6 psi A: spine from no boost', [0.00 0.45 0.80], ...
    rpm_06B, thr_06B, T_06B, '6 psi B: spine from 12 psi',  [0.85 0.35 0.10]);

makeMapOverlay3D( ...
    'Generated CSV overlay - 6 psi A vs no boost', ...
    '6 psi test A generated map vs no-boost map', ...
    rpm_nb,  thr_nb,  T_nb,  'no boost map',                  [0.20 0.45 0.85], ...
    rpm_06A, thr_06A, T_06A, '6 psi A: spine from no boost',   [0.85 0.10 0.10]);

makeMapOverlay3D( ...
    'Generated CSV overlay - 6 psi B vs no boost', ...
    '6 psi test B generated map vs no-boost map', ...
    rpm_nb,  thr_nb,  T_nb,  'no boost map',                  [0.20 0.45 0.85], ...
    rpm_06B, thr_06B, T_06B, '6 psi B: spine from 12 psi',     [0.85 0.10 0.10]);

makeMapOverlay3D( ...
    'Generated CSV overlay - 6 psi C vs no boost', ...
    '6 psi test C generated map vs no-boost map', ...
    rpm_nb,  thr_nb,  T_nb,  'no boost map',                  [0.20 0.45 0.85], ...
    rpm_06C, thr_06C, T_06C, '6 psi C: actual 60% data',       [0.00 0.55 0.15]);

makeMapOverlay3D( ...
    'Generated CSV overlay - 100 boost vs 30 psi', ...
    '100 boost map vs 30 psi generated map', ...
    rpm_fb, thr_fb, T_fb, 'fully boosted',        [0.85 0.35 0.10], ...
    rpm_30, thr_30, T_30, '30 psi', [0.00 0.55 0.15]);

%% ============== 6 PSI MEASURED DATA OVER ZERO-BOOST MAP (3D) =========
% The 0-boost engine map (surface) with the measured 6 PSI dyno sweeps
% (points) overlaid, so you can see how 6 PSI lifts off the NA baseline.
psi6 = 6;
if ~any(PSI==psi6)
    warning('No %d PSI data found in the dyno file; skipping that figure.', psi6);
else
    figure('Name',sprintf('%d PSI data over 0 boost map',psi6)); hold on;
    [RRn,TTn] = meshgrid(rpm_nb, thr_nb);
    sNB6 = surf(RRn, TTn, T_nb.', 'FaceColor',[0.20 0.45 0.85], ...   % 0 boost surface
                'FaceAlpha',0.55, 'EdgeAlpha',0.15);
    h6 = overlayMeasured(gca, psi6, PSI,THR,TQ,rpm_new, [0.85 0.10 0.10]); % 6 PSI points (red)
    applyMapAxes(sprintf('%d PSI measured (red) over 0-boost map (blue)', psi6));
    view(135,25);
    legend([sNB6 h6], {'0 boost map', sprintf('%d PSI measured',psi6)}, 'Location','best');
end

fprintf('Done. Change psi_to_plot / knots_* at the top to explore other cases.\n');

%% ========================= LOCAL FUNCTIONS ==========================

function [rpm, thr, T] = loadMapCSV(fname)
% Reads an engine map csv: header "rpm,<throttle>,<throttle>,...".
    if ~isfile(fname)
        error('loadMapCSV:FileNotFound', ...
              'Could not find CSV file:\n%s\nCheck the path/name at the top of the script.', fname);
    end

    fid = fopen(fname,'r');
    if fid < 0
        error('loadMapCSV:OpenFailed', ...
              'MATLAB could not open CSV file:\n%s\nCheck permissions or whether the file is locked.', fname);
    end
    hdr = fgetl(fid);
    fclose(fid);

    if ~ischar(hdr) && ~isstring(hdr)
        error('loadMapCSV:BadHeader', ...
              'CSV file exists, but the header could not be read:\n%s', fname);
    end

    parts = strsplit(strtrim(hdr), ',');
    thr   = str2double(parts(2:end));          % throttle fractions
    M     = readmatrix(fname);                 % numeric body (header dropped)
    rpm   = M(:,1);
    T     = M(:,2:end);                        % [nrpm x nthrottle], Nm
    keep  = isfinite(rpm);                     % drop header/footer/blank rows
    rpm   = rpm(keep);                         %   (readmatrix may leave a
    T     = T(keep, :);                        %    leading NaN header row)
    [rpm, rorder] = unique(rpm);               % distinct & ascending rpm
    T = T(rorder, :);
    [thr, order] = sort(thr(:).');             % ensure ascending throttle
    T = T(:, order);
end

function checkRequiredFiles(files)
% Print a clean error listing exactly which files are missing.
    missing = {};
    for i = 1:numel(files)
        if ~isfile(files{i})
            missing{end+1} = files{i}; %#ok<AGROW>
        end
    end

    if ~isempty(missing)
        msg = sprintf('Missing required file(s):\n');
        for i = 1:numel(missing)
            msg = sprintf('%s  - %s\n', msg, missing{i});
        end
        msg = sprintf('%s\nFix the file paths at the top of the script, or copy the CSVs into the config folder.', msg);
        error('checkRequiredFiles:MissingFiles', '%s', msg);
    end
end

function [rpm, PSI, THR, TQ] = loadNewData(fname, sheet)
% Reads the 2-header-row dyno xlsx and returns torque columns keyed by
% (PSI, throttle).  TQ is [nrpm x nCases], NaN where blank.
    raw    = readcell(fname, 'Sheet', sheet);
    names1 = string(raw(1,:));                  % case names row
    labels = string(raw(2,:));                  % "Power (hp)"/"Torque (Nm)"
    nrow   = size(raw,1);
    rpm    = arrayfun(@(i) getnum(raw{i,1}), (3:nrow).');
    tcols  = find(contains(labels, "Torque"));
    nc     = numel(tcols);
    PSI = zeros(nc,1);  THR = zeros(nc,1);  TQ = nan(nrow-2, nc);
    for k = 1:nc
        j   = tcols(k);
        nm  = names1(j-1);                      % name sits above the Power col
        tok = regexp(nm, '(\d+)PSI_(\d+)Throttle', 'tokens', 'once');
        if isempty(tok), continue; end
        PSI(k) = str2double(tok{1});
        THR(k) = str2double(tok{2})/100;
        for i = 3:nrow
            TQ(i-2,k) = getnum(raw{i,j});
        end
    end
end

function v = getnum(x)
% Convert a readcell entry to a number, NaN for blanks/missing/text.
    if isnumeric(x) && isscalar(x) && ~isempty(x)
        v = double(x);
    elseif ismissing(x)
        v = NaN;
    else
        v = str2double(string(x));
    end
end

function y = newTQvec(rq, psi, thr, PSI,THR,TQ,rpm_new)
% Measured torque-vs-rpm for one (psi, throttle), interpolated onto rq.
    k = find(PSI==psi & abs(THR-thr) < 1e-6, 1);
    if isempty(k), y = nan(size(rq)); return; end
    col = TQ(:,k);  good = isfinite(rpm_new(:)) & ~isnan(col);
    y = interp1(rpm_new(good), col(good), rq, 'linear', NaN);
end

function y = borrowVec(rq, thr, rpm_nb, T_nb, thr_nb)
% Boost-independent low-throttle knot, borrowed from the NA map.
    c = find(abs(thr_nb - thr) < 1e-6, 1);
    if isempty(c)                              % no matching throttle column
        y = nan(size(rq));  return;
    end
    x = rpm_nb(:);  v = T_nb(:,c);
    good = isfinite(x) & isfinite(v);          % interp1 needs finite samples
    y = interp1(x(good), v(good), rq, 'linear', 'extrap');
end

function [knotTQ, ok] = buildKnotTQ(kthr, rq, psi, ...
                          PSI,THR,TQ,rpm_new, rpm_nb,T_nb,thr_nb)
% Assemble torque at each knot throttle as a function of rpm.
%   knots at 0% / 30% are borrowed (boost independent); others measured.
    knotTQ = nan(numel(rq), numel(kthr));  ok = true;
    for c = 1:numel(kthr)
        t = kthr(c);
        if abs(t-0.00) < 1e-6 || abs(t-0.30) < 1e-6
            knotTQ(:,c) = borrowVec(rq, t, rpm_nb, T_nb, thr_nb);
        else
            knotTQ(:,c) = newTQvec(rq, psi, t, PSI,THR,TQ,rpm_new);
        end
        if all(isnan(knotTQ(:,c))), ok = false; end
    end
end

function h = overlayMeasured(ax, p, PSI,THR,TQ,rpm_new, col)
% Scatter the measured (rpm,throttle,torque) points for one PSI onto ax.
%   col is an optional marker color (default black); returns the last
%   scatter handle so it can be used as a single legend entry.
    if nargin < 7 || isempty(col), col = 'k'; end
    h = gobjects(0);
    thrList = sort(THR(PSI==p)).';
    for t = thrList
        y = newTQvec(rpm_new, p, t, PSI,THR,TQ,rpm_new);
        g = ~isnan(y);
        h = scatter3(ax, rpm_new(g), t*ones(sum(g),1), y(g), 8, col,'filled', ...
                     'MarkerFaceAlpha',0.5);
    end
end

function Z = surfFromKnots(kthr, knotTQ, thrFine)
% Piecewise-linear-in-throttle surface, Z is [numel(thrFine) x numel(rpm)].
    Z = nan(numel(thrFine), size(knotTQ,1));
    for i = 1:size(knotTQ,1)
        Z(:,i) = interp1(kthr, knotTQ(i,:), thrFine, 'linear');
    end
end

function makeMapOverlay3D3(figName, ttl, rpmA, thrA, TA, labelA, colA, ...
                                    rpmB, thrB, TB, labelB, colB, ...
                                    rpmC, thrC, TC, labelC, colC)
% Plot three generated CSV engine-map surfaces on one 3D axes.
    figure('Name', figName);
    ax = axes; hold(ax,'on');

    hA = plotEngineMapSurface(ax, rpmA, thrA, TA, colA, 0.42);
    hB = plotEngineMapSurface(ax, rpmB, thrB, TB, colB, 0.42);
    hC = plotEngineMapSurface(ax, rpmC, thrC, TC, colC, 0.60);

    applyMapAxes(ttl);
    view(ax,135,25);
    legend(ax, [hA hB hC], {labelA, labelB, labelC}, 'Location','best');

    zvals = [TA(:); TB(:); TC(:)];
    zvals = zvals(isfinite(zvals));
    if ~isempty(zvals)
        zlo = min([0; zvals]);
        zhi = max(zvals) * 1.05;
        zlim(ax, [zlo zhi]);
    end
end

function makeThrottleSliceComparison(figName, ttl, throttleToPlot, ...
                                     rpmA, thrA, TA, labelA, colA, ...
                                     rpmB, thrB, TB, labelB, colB, ...
                                     rpmC, thrC, TC, labelC, colC)
% Compare A/B/C at one throttle slice as normal 2D torque-vs-rpm curves.
    figure('Name', figName);
    ax = axes; hold(ax,'on');

    yA = torqueAtThrottle(TA, thrA, throttleToPlot);
    yB = torqueAtThrottle(TB, thrB, throttleToPlot);
    yC = torqueAtThrottle(TC, thrC, throttleToPlot);

    pA = plot(ax, rpmA, yA, 'LineWidth',1.0, 'Color',colA);
    pB = plot(ax, rpmB, yB, 'LineWidth',1.0, 'Color',colB);
    pC = plot(ax, rpmC, yC, 'LineWidth',1.5, 'Color',colC);

    xlabel(ax,'RPM');
    ylabel(ax,sprintf('torque at %.0f%% throttle (Nm)', throttleToPlot*100));
    title(ax, ttl);
    grid(ax,'on'); box(ax,'on');
    legend(ax, [pA pB pC], {labelA, labelB, labelC}, 'Location','best');
end

function makeThrottleDeltaComparison(figName, ttl, throttleToPlot, ...
                                     rpmA, thrA, TA, labelCA, ...
                                     rpmB, thrB, TB, labelCB, ...
                                     rpmC, thrC, TC)
% Plot C-A and C-B at one throttle slice on the C rpm grid.
    figure('Name', figName);
    ax = axes; hold(ax,'on');

    yA = torqueAtThrottle(TA, thrA, throttleToPlot);
    yB = torqueAtThrottle(TB, thrB, throttleToPlot);
    yC = torqueAtThrottle(TC, thrC, throttleToPlot);

    yA_on_C = interp1(rpmA, yA, rpmC, 'linear', NaN);
    yB_on_C = interp1(rpmB, yB, rpmC, 'linear', NaN);

    dCA = yC - yA_on_C;
    dCB = yC - yB_on_C;

    p1 = plot(ax, rpmC, dCA, 'LineWidth',1.0);
    p2 = plot(ax, rpmC, dCB, 'LineWidth',1.0);
    yline(ax,0,'k--','LineWidth',1.0);

    xlabel(ax,'RPM');
    ylabel(ax,sprintf('torque difference at %.0f%% throttle (Nm)', throttleToPlot*100));
    title(ax, ttl);
    grid(ax,'on'); box(ax,'on');
    legend(ax, [p1 p2], {labelCA, labelCB}, 'Location','best');
end

function y = torqueAtThrottle(T, thr, throttleToPlot)
% Extract/interpolate a throttle slice from a map.
% T is [nrpm x nthrottle], thr is [1 x nthrottle].
    y = nan(size(T,1),1);
    for i = 1:size(T,1)
        row = T(i,:);
        good = isfinite(thr) & isfinite(row);
        if nnz(good) >= 2
            y(i) = interp1(thr(good), row(good), throttleToPlot, 'linear', NaN);
        end
    end
end

function makeMapOverlay3D(figName, ttl, rpmA, thrA, TA, labelA, colA, ...
                                  rpmB, thrB, TB, labelB, colB)
% Plot two complete/generated CSV engine-map surfaces on the same 3D axes.
% Each map is torque-vs-(rpm, throttle).  Missing cells remain as holes in
% the surface, which is useful because it shows any blank map regions.
    figure('Name', figName); 
    ax = axes; hold(ax,'on');

    hA = plotEngineMapSurface(ax, rpmA, thrA, TA, colA, 0.55);
    hB = plotEngineMapSurface(ax, rpmB, thrB, TB, colB, 0.55);

    applyMapAxes(ttl);
    view(ax,135,25);
    legend(ax, [hA hB], {labelA, labelB}, 'Location','best');

    % Use common z-limits for a fair visual comparison.
    zvals = [TA(:); TB(:)];
    zvals = zvals(isfinite(zvals));
    if ~isempty(zvals)
        zlo = min([0; zvals]);
        zhi = max(zvals) * 1.05;
        zlim(ax, [zlo zhi]);
    end
end

function h = plotEngineMapSurface(ax, rpm, thr, T, col, faceAlpha)
% Helper for plotting one engine-map CSV as a 3D surface.
% Inputs:
%   rpm : [nrpm x 1]
%   thr : [1 x nthrottle], throttle fractions
%   T   : [nrpm x nthrottle], torque Nm
    [RR,TT] = meshgrid(rpm, thr);
    h = surf(ax, RR, TT, T.', ...
             'FaceColor', col, ...
             'FaceAlpha', faceAlpha, ...
             'EdgeAlpha', 0.12);
end

function applyMapAxes(ttl)
    xlabel('RPM'); ylabel('throttle'); zlabel('torque (Nm)');
    title(ttl); grid on; box on; axis tight;
end