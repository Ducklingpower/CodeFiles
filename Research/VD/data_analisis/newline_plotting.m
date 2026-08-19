clc
close all
clear
%% plotting ax vs pos on fast lap

M = readmatrix("laguna_mintime_p15.csv");

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

%% summary
fprintf("lap length      : %d m\n", N);
fprintf("lap time        : %.2f s\n", sum(1./v));
fprintf("speed           : %.1f - %.1f m/s\n", min(v), max(v));
fprintf("a_x             : %.2f g braking / %.2f g accel\n", min(ax)/g, max(ax)/g);
fprintf("a_y             : %.2f g right / %.2f g left\n", min(ay)/g, max(ay)/g);
fprintf("peak |a|        : %.2f g\n", max(at)/g);

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
