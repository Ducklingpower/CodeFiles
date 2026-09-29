clc
close all
clear
%% plotting ax vs pos on fast lap

M = readmatrix("/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/planning/frenet_path_server/maps/laguna/laguna_mintime_p15.csv");

lat   = M(:,1);
lon   = M(:,2);
v     = M(:,3);   
kappa = M(:,4);    

N = numel(v);

%% arc length + local ENU position
s = (0:N-1)';      

R    = 6378137;                      
lat0 = mean(lat);
lon0 = mean(lon);
x = deg2rad(lon - lon0) * R * cosd(lat0);   
y = deg2rad(lat - lat0) * R;               

%% accelerations
% closed-lap central differences (wrap the ends), ds = 1 m
ip = [2:N, 1]';
im = [N, 1:N-1]';

dvds = (v(ip) - v(im)) / 2;    
ax   = v .* dvds;               
ay   = v.^2 .* kappa;           
at   = hypot(ax, ay);         

g = 9.81;

%% colormaps

pDiv = [0 0.11 0.22 0.33 0.45 0.50 0.55 0.67 0.78 0.89 1];

cAx = makeMap(spectral(), 256, pDiv);   % a_x
cAy = makeMap(spectral(), 256, pDiv);   % a_y
cAt = makeMap(turboMap(), 256);         % |a|   (R2020b+: turbo(256) works too)

%% figure 1: track map coloured by acceleration
figure('Name','Laguna Seca -- acceleration on track','Color','w', ...
       'Position',[80 80 1500 520]);
tl = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

trackTile(x, y, ax, cAx, true,  "Longitudinal a_x  (brake <-> accel)", "a_x  [m/s^2]");
trackTile(x, y, ay, cAy, true,  "Lateral a_y  (right <-> left)",       "a_y  [m/s^2]");
trackTile(x, y, at, cAt, false, "Combined |a|",                        "|a|  [m/s^2]");

title(tl, sprintf('Laguna Seca minimum-time lap  --  %d m, 1 m spacing, lap time %.2f s', ...
      N, sum(1./v)), 'FontWeight', 'bold');

%% figure 2: acceleration vs distance around the lap
figure('Name','Laguna Seca -- acceleration vs s','Color','w', ...
       'Position',[120 120 1200 800]);
tl2 = tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

axS = gobjects(3,1);

axS(1) = nexttile;
plot(s, ax, 'LineWidth', 2, 'Color', [0.196 0.533 0.741]);
yline(0, 'Color', [0.75 0.75 0.75], 'LineWidth', 1);
ylabel("a_x  [m/s^2]")
title('Longitudinal acceleration', 'FontWeight', 'normal')

axS(2) = nexttile;
plot(s, ay, 'LineWidth', 2, 'Color', [0.835 0.243 0.310]);
yline(0, 'Color', [0.75 0.75 0.75], 'LineWidth', 1);
ylabel("a_y  [m/s^2]")
title('Lateral acceleration', 'FontWeight', 'normal')

axS(3) = nexttile;
plot(s, at, 'LineWidth', 2, 'Color', [0.369 0.310 0.635]);
ylabel("|a|  [m/s^2]")
xlabel("s  [m]")
title('Combined acceleration magnitude', 'FontWeight', 'normal')

for k = 1:3
    grid(axS(k), "on");
    axS(k).GridAlpha = 0.15;
    axS(k).Box = "off";
    axS(k).XLim = [s(1) s(end)];
end
linkaxes(axS, "x");

title(tl2, 'Acceleration vs distance around the lap', 'FontWeight', 'bold');

%% brake bias from the clipped schedule
% The bias the car would run around this lap, taken from the table
% acceleration_interface loads: clipped_brake_bias_map_grid.csv, a front
% PRESSURE bias P_f / (P_f + P_r) over vehicle speed and deceleration.
%
% The table is defined over the whole speed/decel plane, so a lookup returns a
% number even where this lap is accelerating. That does not mean it is used
% there: off the brakes there is no split to command, so those points are drawn
% grey instead of coloured.
%
% a_x here is the minimum-time lap's own v*dv/ds, not a measurement, so this is
% what the schedule WOULD command on this line - not what any run recorded.

biasFile = "clipped_brake_bias_map_grid.csv";
biasDir  = fullfile(fileparts(mfilename('fullpath')), '..', 'brake_anylisis', 'lut');
biasPath = fullfile(biasDir, biasFile);

decelMin = 0.2;                 % m/s^2, below this the car is coasting, not braking
greyCol  = [0.72 0.72 0.72];

if ~isfile(biasPath)
    warning("newline_plotting:noBiasLut", ...
        "%s not found; the brake bias figure is skipped.", biasPath);
else
    % The speed breakpoints live in the header text, which readmatrix drops, so
    % the header is read on its own first.
    fid = fopen(biasPath, 'r');
    hdr = fgetl(fid);
    fclose(fid);

    speedBP = str2double(strsplit(strtrim(hdr), ','));
    speedBP = speedBP(2:end);            % first cell names the decel column

    rawBias = readmatrix(biasPath);
    rawBias = rawBias(isfinite(rawBias(:,1)), :);

    decelBP  = rawBias(:,1);
    biasGrid = rawBias(:,2:end);

    if numel(speedBP) ~= size(biasGrid, 2)
        error("newline_plotting:biasLutShape", ...
            "%s has %d bias columns but %d speed breakpoints in its header.", ...
            biasPath, size(biasGrid,2), numel(speedBP));
    end

    decel   = -ax;                       % positive while slowing
    braking = decel > decelMin;

    bias = nan(N,1);
    bias(braking) = biasLookup(speedBP, decelBP, biasGrid, v(braking), decel(braking));

    cBias   = makeMap(turboMap(), 256);
    biasLim = [min(biasGrid(:)) max(biasGrid(:))];  % table range, so all three tiles share a scale

    figure('Name','Laguna Seca -- brake bias','Color','w', ...
           'Position',[160 160 1500 520]);
    tl3 = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

    % --- the track, coloured by the bias being commanded ---
    axB1 = nexttile;
    hold on
    scatter(x(~braking), y(~braking), 18, greyCol, "filled", ...
            'DisplayName', sprintf('not decelerating (< %g m/s^2)', decelMin));
    scatter(x(braking), y(braking), 18, bias(braking), "filled", ...
            'HandleVisibility', 'off');
    hold off
    colormap(axB1, cBias);
    clim(axB1, biasLim);
    cb1 = colorbar;
    cb1.Label.String = "front brake bias  P_f / (P_f + P_r)";
    axis equal
    grid on
    axB1.GridAlpha = 0.15;
    axB1.Box = "off";
    xlabel("east  [m]")
    ylabel("north [m]")
    legend('Location','best')
    title('Brake bias on track', 'FontWeight', 'normal')

    % --- the table itself, with this lap drawn on top of it ---
    % Both axes of the file are uniformly spaced, so imagesc places the cells
    % correctly from the end points alone.
    axB2 = nexttile;
    imagesc(speedBP, decelBP, biasGrid);
    set(axB2, 'YDir', 'normal');         % imagesc counts rows downward by default
    hold on
    scatter(v(braking), decel(braking), 8, "k", "filled", ...
            'MarkerFaceAlpha', 0.25, 'DisplayName', 'braking points this lap');
    hold off
    colormap(axB2, cBias);
    clim(axB2, biasLim);
    cb2 = colorbar;
    cb2.Label.String = "front brake bias  P_f / (P_f + P_r)";
    grid on
    axB2.GridAlpha = 0.15;
    axB2.Box = "off";
    xlabel("speed  [m/s]")
    ylabel("deceleration  [m/s^2]")
    legend('Location','northeast')
    title(biasFile, 'FontWeight', 'normal', 'Interpreter', 'none')

    % --- bias around the lap ---
    % The grey samples have no bias to sit at, so they are pinned just under the
    % colour band purely to keep the off-brake stretches readable as a lap.
    greyLevel = biasLim(1) - 0.04 * diff(biasLim);

    axB3 = nexttile;
    hold on
    scatter(s(~braking), greyLevel * ones(sum(~braking), 1), 8, greyCol, "filled", ...
            'DisplayName', sprintf('not decelerating (< %g m/s^2)', decelMin));
    scatter(s(braking), bias(braking), 8, bias(braking), "filled", ...
            'HandleVisibility', 'off');
    hold off
    colormap(axB3, cBias);
    clim(axB3, biasLim);
    grid on
    axB3.GridAlpha = 0.15;
    axB3.Box = "off";
    axB3.XLim = [s(1) s(end)];
    xlabel("s  [m]")
    ylabel("front brake bias  [-]")
    legend('Location','best')
    title('Bias commanded around the lap', 'FontWeight', 'normal')

    title(tl3, sprintf('Scheduled brake bias, clipped LUT  --  %d of %d points decelerating above %g m/s^2', ...
          sum(braking), N, decelMin), 'FontWeight', 'bold');
end

%% summary
fprintf("lap length      : %d m\n", N);
fprintf("lap time        : %.2f s\n", sum(1./v));
fprintf("speed           : %.1f - %.1f m/s\n", min(v), max(v));
fprintf("a_x             : %.2f g braking / %.2f g accel\n", min(ax)/g, max(ax)/g);
fprintf("a_y             : %.2f g right / %.2f g left\n", min(ay)/g, max(ay)/g);
fprintf("peak |a|        : %.2f g\n", max(at)/g);

if exist('bias', 'var') && any(braking)
    fprintf("braking         : %d of %d m above %g m/s^2, peak %.2f g\n", ...
            sum(braking), N, decelMin, max(decel)/g);
    fprintf("brake bias      : %.3f - %.3f, median %.3f  (table spans %.3f - %.3f)\n", ...
            min(bias(braking)), max(bias(braking)), median(bias(braking)), ...
            biasLim(1), biasLim(2));
end

%% ------------------------------------------------------------------
function trackTile(x, y, c, cmap, symmetric, ttl, cbLabel)
    axh = nexttile;
    scatter(x, y, 18, c, "filled");
    colormap(axh, cmap);
    if symmetric
        lim = max(abs(c));
        caxis(axh, [-lim lim]);      % keep 0 on the neutral midpoint
    else
        caxis(axh, [0 max(c)]);
    end
    cb = colorbar;
    cb.Label.String = cbLabel;
    axis equal
    grid on
    axh.GridAlpha = 0.15;
    axh.Box = "off";
    xlabel("east  [m]")
    ylabel("north [m]")
    title(ttl, 'FontWeight', 'normal')
end

function bias = biasLookup(speedBP, decelBP, biasGrid, speed, decel)
    % Front bias off the schedule at a speed and a deceleration.
    %
    % Both axes are clamped onto the grid rather than extrapolated: the table
    % already holds its edge values, and extrapolating a bias would be free to
    % leave [0 1], which is not a bias.
    speed = min(max(speed, speedBP(1)),  speedBP(end));
    decel = min(max(decel, decelBP(1)),  decelBP(end));

    bias = interp2(speedBP, decelBP, biasGrid, speed, decel, "linear");
end

function c = makeMap(anchors, n, pos)
    % interpolate an m-by-3 anchor list up to an n-by-3 colormap.
    % pos (optional) places the anchors on [0 1]; default is even spacing.
    if nargin < 3 || isempty(pos)
        pos = linspace(0, 1, size(anchors, 1));
    end
    c = interp1(pos(:), anchors, linspace(0, 1, n)');
    c = min(max(c, 0), 1);
end

function a = spectral()
    % ColorBrewer Spectral, reversed: cool (negative) -> pale -> warm (positive)
    a = [0.369 0.310 0.635
         0.196 0.533 0.741
         0.400 0.761 0.647
         0.671 0.867 0.643
         0.902 0.961 0.596
         1.000 1.000 0.749
         0.996 0.878 0.545
         0.992 0.682 0.380
         0.957 0.427 0.263
         0.835 0.243 0.310
         0.620 0.004 0.259];
end

function a = turboMap()
    % Google's turbo: rainbow sweep with far better lightness behaviour than jet
    a = [0.190 0.072 0.232
         0.265 0.323 0.760
         0.275 0.559 0.994
         0.126 0.774 0.876
         0.144 0.915 0.617
         0.526 0.994 0.326
         0.839 0.902 0.194
         0.990 0.604 0.135
         0.898 0.245 0.041
         0.480 0.016 0.011];
end
