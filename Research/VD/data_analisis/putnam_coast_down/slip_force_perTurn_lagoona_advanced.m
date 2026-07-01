clc
close all
clear

%% csv

% data = readtable('FastLaps.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/putnam/oversteer/2026-04-28_150159_merged.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv');
data = readtable('/home/elijah/bag_files/VD/laguna/comp/2025-07-24_175839_merged.csv');



tStart = 250;                                 
tCut   = 850;                                 
tRel   = data.time_s - data.time_s(1);
data   = data(tRel >= tStart & tRel <= tCut, :);


%% filtered data  (unchanged filtering strategy)

mm = 20;
Ft = movmean(data.time_s,mm);

Fax = movmean(data.a_x,mm);
Fay = movmean(data.a_y,mm);
Faz = movmean(data.a_z,mm);

Ffz_fr = movmean(data.fr_load_n,mm);
Ffz_fl = movmean(data.fl_load_n,mm);
Ffz_rr = movmean(data.rr_load_n,mm);
Ffz_rl = movmean(data.rl_load_n,mm);

Fvx = movmean(data.odom_vx_mps,mm);
Fvy = movmean(data.odom_vy_mps,mm);

Frpm = movmean(data.engine_rpm,mm);
throttle = data.throttle_pct;                          % throttle [%] (raw, as original)
Fgear = movmean(data.current_gear,mm);
FT_e = movmean(data.est_drive_torque_nm,mm);
Fbrake = movmean(data.front_brake_pressure_kpa,mm);    % front brake pressure [kPa]

steering_wheel = movmean(data.steer_wheel_ang_deg,mm);
toe_angle = 0.333+(steering_wheel)/15.015;
toe_rad = toe_angle*(pi/180);

Fqx = movmean(data.odom_qx,mm);
Fqy = movmean(data.odom_qy,mm);
Fqz = movmean(data.odom_qz,mm);
Fqw = movmean(data.odom_qw,mm);

Fwz = movmean(data.odom_wz_rads,mm);
Fwx = movmean(data.odom_wx_rads,mm);
Fwy = movmean(data.odom_wy_rads,mm);

Fq = [Fqw Fqx Fqy Fqz];
Feul = quat2eul(Fq, 'ZYX');   % [yaw pitch roll]

Fyaw   = Feul(:,1);
Fpitch = Feul(:,2);
Froll  = Feul(:,3);

yaw_u   = unwrap(Fyaw);
pitch_u = unwrap(Fpitch);
roll_u  = unwrap(Froll);

yaw_dot   = Fwz;
pitch_dot = Fwy;
roll_dot  = Fwx;

yaw_unwrapped = unwrap(Fyaw);

x_pos = data.odom_px_m;
y_pos = data.odom_py_m;

% tire temp
fr_T_0 = data.fr_temp_1;
fr_T_1 = data.fr_temp_2;
fr_T_2 = data.fr_temp_3;
fr_T_3 = data.fr_temp_4;


%% getting yaw, pitch, and roll curvature  (unchanged)

t = data.time_s(:);
t = t - t(1);

V = sqrt(Fvx.^2 + Fvy.^2);
ds = [0; cumsum(0.5 * (V(1:end-1) + V(2:end)) .* diff(t))];   % distance travelled [m]

v_min_curv = 2.0;

% Curvature
kappa_yaw   = nan(size(V));
kappa_pitch = nan(size(V));
kappa_roll  = nan(size(V));

curv_valid = isfinite(V) & V > v_min_curv;

kappa_yaw(curv_valid)   = yaw_dot(curv_valid)   ./ V(curv_valid);
kappa_pitch(curv_valid) = pitch_dot(curv_valid) ./ V(curv_valid);
kappa_roll(curv_valid)  = roll_dot(curv_valid)  ./ V(curv_valid);


%% vehicle parameters  (unchanged physics)

vehicleParams.wheelbase   = 2.9718;      % wheelbase (m)  [2971.8 mm]
vehicleParams.w_dist_f    = 0.42;        % front weight distribution [42%]
vehicleParams.m           = 787;         % vehicle mass (kg)  [base vehicle mass]
vehicleParams.frontalArea = 1 ;          % frontal area (m^2) TBD
vehicleParams.inertia     = 1000;

L  = vehicleParams.wheelbase;
b  = vehicleParams.w_dist_f * L;
a  = L - b;

m  = vehicleParams.m;
Iz = vehicleParams.inertia;

roh = 1.22;
Acd = 1.33;


%% slip angles  (unchanged bicycle-model kinematics)

t = data.time_s(:);
t = t - t(1);

r = Fwz;
rdot = gradient(r, t);
rdot = movmean(rdot, mm);   % filtered yaw acceleration

dt = gradient(t);
dt(dt <= 0) = median(dt(dt > 0));

steeringRatio = 1;
delta = toe_rad;

vx_min = 10.0;
vx_safe = Fvx;
vx_safe(abs(vx_safe) < vx_min) = 0;

alpha_f = delta - atan2(Fvy + a .* r, vx_safe);
alpha_r =       - atan2(Fvy - b .* r, vx_safe);

alpha_f_deg = rad2deg(alpha_f);
alpha_r_deg = rad2deg(alpha_r);


% derived lateral acceleration  (curvature method, NOT raw a_y)

g = 9.81;

theta = -Fpitch;
phi   = Froll;

V = sqrt(Fvx.^2 + Fvy.^2);

v_min_curv = 5.0;

% Curvature acceleration terms
v2_kappa_yaw   = V.^2 .* kappa_yaw;
v2_kappa_pitch = V.^2 .* kappa_pitch;
v2_kappa_roll  = V.^2 .* kappa_roll;

% Remove low speed 
curv_valid = isfinite(V) & V > v_min_curv & ...
             isfinite(kappa_yaw) & isfinite(theta) & isfinite(phi);

v2_kappa_yaw(~curv_valid)   = nan;
v2_kappa_pitch(~curv_valid) = nan;
v2_kappa_roll(~curv_valid)  = nan;

% lateral acceleration demand from tires 
ay_inertial = v2_kappa_yaw;
g_y_body = -g .* cos(theta) .* sin(phi);
ay_tire = ay_inertial - g_y_body * 0;


%% front/rear bicycle lateral force split  (uses derived ay_tire)

Fyf = (b .* m .* ay_tire + Iz .* rdot) ./ L;
Fyr = (a .* m .* ay_tire - Iz .* rdot) ./ L;


Fair     = 0.5 * roh * Acd .* Fvx.^2;
FF_pitch = m * g .* sin(theta);   % pitch from quat2eul is in radians
Fbody    = m .* Fax;               % force from longitudinal acceleration
Fxr = Fbody + Fair + FF_pitch; % rear axle force

% Global valid mask
valid = isfinite(alpha_f_deg) & isfinite(alpha_r_deg) & ...
        isfinite(Fyf) & isfinite(Fyr) & ...
        abs(Fvx) > vx_min;


%% corner section boxes  
% Format: name, xmin, xmax, ymin, ymax

cornerBoxes = {
    "C1",        -200,  -140,   -400,  -200;
    "C2",        -220,  -50,   -540,  -400;
    "C3",          -140,   50,   -400,  -250;
    "C4",    50,   200,   -550,  -250;
    "C5",        50,   380,   -850,  -550;
    "C6",     380,   600,   -850,  -450;
    "C7-8_corkscrew",        500,   610,   -450,  -160;
    "C9",          380,   610,   -160,   -20;
    "C10",          150,   380,   -125,   20;
    "C11",        0,   200,    20,   160;
};

numCorners = size(cornerBoxes,1);


%% track map with corner boxes 

figure
plot(x_pos, y_pos, 'b')
hold on
grid on
xlabel("xpos")
ylabel("ypos")
title("Track Map with Corner Sections")

for i = 1:numCorners
    name = cornerBoxes{i,1};

    xmin = cornerBoxes{i,2};
    xmax = cornerBoxes{i,3};
    ymin = cornerBoxes{i,4};
    ymax = cornerBoxes{i,5};

    rectangle('Position', [xmin, ymin, xmax-xmin, ymax-ymin], ...
              'EdgeColor', 'r');

    text(xmin, ymax, name, ...
         'Color', 'r', ...
         'FontSize', 9, ...
         'Interpreter', 'none');
end

setSquareTopView(gca, ...
    [min(x_pos,[],'omitnan') max(x_pos,[],'omitnan')], ...
    [min(y_pos,[],'omitnan') max(y_pos,[],'omitnan')])   


%% corner masks  

cornerMasks = false(length(x_pos), numCorners);

for i = 1:numCorners
    xmin = cornerBoxes{i,2};
    xmax = cornerBoxes{i,3};
    ymin = cornerBoxes{i,4};
    ymax = cornerBoxes{i,5};

    cornerMasks(:,i) = x_pos >= xmin & x_pos <= xmax & ...
                       y_pos >= ymin & y_pos <= ymax & ...
                       valid;
end


%% derived lateral-acceleration diagnostics 

figure
tiledlayout(4,1)

nexttile
plot(t, ay_inertial)
grid on
ylabel("a_{y,inertial} [m/s^2]")
title("Lateral Acceleration from Yaw Curvature")

nexttile
plot(t, g_y_body)
grid on
ylabel("g_y body [m/s^2]")
title("Gravity Lateral Component from Bank/Roll")

nexttile
plot(t, ay_tire)
grid on
ylabel("a_{y,tire} [m/s^2]")
title("Tire Lateral Acceleration Demand")

nexttile
plot(t, Fay)
hold on
plot(t, ay_tire)
grid on
xlabel("time [s]")
ylabel("a_y [m/s^2]")
legend("ay", "curvature method")
title("IMU vs Curvature-Based Tire Lateral Acceleration")


%% corner-by-corner front/rear slip-force scatter 

nCols = 3;
nRows = ceil(numCorners / nCols);

figure
tl = tiledlayout(nRows, nCols, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

% Time normalization
tValid = Ft(valid & isfinite(Ft));
tMin = min(tValid);
tMax = max(tValid);

if tMax == tMin
    tMax = tMin + 1;
end

% Different color maps
frontMap = winter(256);   % blue/green style for front
rearMap  = autumn(256);   % red/yellow style for rear

% Convert every time sample into a color index
tNorm = (Ft - tMin) ./ (tMax - tMin);
tNorm = max(0, min(1, tNorm));

tIdx = round(1 + tNorm * 255);
tIdx(~isfinite(tIdx)) = 1;

frontColors = frontMap(tIdx, :);
rearColors  = rearMap(tIdx, :);

for i = 1:numCorners
    nexttile
    mask = cornerMasks(:,i);

    hold on

    % Front: blue/green time gradient
    scatter(alpha_f_deg(mask), Fyf(mask), ...
        14, frontColors(mask,:), ...
        'o', 'filled', ...
        'MarkerFaceAlpha', 0.75, ...
        'MarkerEdgeAlpha', 0.15)

    % Rear: red/yellow time gradient
    scatter(alpha_r_deg(mask), Fyr(mask), ...
        14, rearColors(mask,:), ...
        's', 'filled', ...
        'MarkerFaceAlpha', 0.75, ...
        'MarkerEdgeAlpha', 0.15)

    grid on
    xlabel("\alpha deg")
    ylabel("F_y N")
    title(cornerBoxes{i,1}, 'Interpreter', 'none')

    % Dummy points only for legend
    hF = scatter(nan, nan, 40, [0 0.45 1], 'o', 'filled', ...
        'DisplayName', 'Front');
    hR = scatter(nan, nan, 40, [1 0.25 0], 's', 'filled', ...
        'DisplayName', 'Rear');

    legend([hF hR], 'Location', 'best')
end

title(tl, "Front and Rear Lateral Force vs Slip Angle by Corner")




minPassLen    = 8;   % deg
maxGapSamples = 5;   % deg
plotCols      = 3;   % 3 cols


%% (1a) throttle behaviour through each corner  

plotPerCornerProgression( ...
    throttle, [], ...
    'throttle [%]', ...
    'Throttle Through Each Corner (lap-by-lap, red = apex)', ...
    {'throttle'}, ...
    cornerBoxes, cornerMasks, ds, kappa_yaw, ...
    plotCols, minPassLen, maxGapSamples);


%% (1b) brake behaviour through each corner  

plotPerCornerProgression( ...
    Fbrake, [], ...
    'front brake [kPa]', ...
    'Brake Pressure Through Each Corner (lap-by-lap, red = apex)', ...
    {'brake'}, ...
    cornerBoxes, cornerMasks, ds, kappa_yaw, ...
    plotCols, minPassLen, maxGapSamples);


%% progression through each corner


plotPerCornerProgression( ...
    alpha_f_deg, alpha_r_deg, ...
    '\alpha [deg]', ...
    'Front/Rear Slip Angle Through Each Corner (lap-by-lap, red = apex)', ...
    {'front \alpha','rear \alpha'}, ...
    cornerBoxes, cornerMasks, ds, kappa_yaw, ...
    plotCols, minPassLen, maxGapSamples);


%% front/rear lateral-force through each corner 


plotPerCornerProgression( ...
    Fyf, Fyr, ...
    'F_y [N]', ...
    'Front/Rear Lateral Force Through Each Corner (lap-by-lap, red = apex)', ...
    {'front F_y','rear F_y'}, ...
    cornerBoxes, cornerMasks, ds, kappa_yaw, ...
    plotCols, minPassLen, maxGapSamples);



%%

cmapThrot = linearColormap([0 0.80 0.20], [0 0.80 1.00], 256);  
cmapBrake = linearColormap([1 0.80 0.40], [0.85 0 0], 256);     
throtLim  = [0 100];         

bSorted = sort(Fbrake(any(cornerMasks,2) & isfinite(Fbrake)));
if isempty(bSorted)
    brakeHi = 1;
else
    brakeHi = bSorted(max(1, ceil(0.99*numel(bSorted))));
end
brakeLim    = [0 max(brakeHi, 1)];
brakeThresh = 0.05 * brakeLim(2);   



%% full track plot thorttle and brake

figure('Position', [100 100 1000 900])
axAll = axes('Parent', gcf, 'Position', [0.07 0.09 0.72 0.84]);
hold(axAll, 'on'); grid(axAll, 'on')

plot(axAll, x_pos, y_pos, '-', 'Color', [0.85 0.85 0.85])   % faint full path

allIdx = (1:numel(x_pos))';
drawDriverInputsXY(axAll, allIdx, x_pos, y_pos, throttle, Fbrake, ...
    brakeThresh, cmapThrot, cmapBrake, throtLim, brakeLim);

% mark every corner apex 
for i = 1:numCorners
    mask   = fillSmallGaps(cornerMasks(:,i), maxGapSamples);
    passes = findPasses(mask, minPassLen);
    for k = 1:numel(passes)
        idx  = passes{k};
        aLoc = apexIndexInPass(idx, kappa_yaw);
        if ~isempty(aLoc)
            plot(axAll, x_pos(idx(aLoc)), y_pos(idx(aLoc)), 'o', ...
                'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 7)
        end
    end
end

xlabel(axAll, 'x [m]'); ylabel(axAll, 'y [m]')
title(axAll, 'Full-Track Throttle & Brake (red = apex)')
setSquareTopView(axAll, ...
    [min(x_pos,[],'omitnan') max(x_pos,[],'omitnan')], ...
    [min(y_pos,[],'omitnan') max(y_pos,[],'omitnan')])   % square view, fixed box
addThrottleBrakeColorbars(gcf, cmapThrot, throtLim, cmapBrake, brakeLim);


%% full track f/r slip angles
slipBoth = abs([alpha_f_deg(valid); alpha_r_deg(valid)]);
slipBoth = slipBoth(isfinite(slipBoth));
if isempty(slipBoth)
    slipAbsMax = 4;
else
    slipAbsMax = max(4, ceil(max(slipBoth)));
end

% Figure 9
plotFullMapSlip( ...
    alpha_f_deg, 'front slip angle \alpha_f [deg]', ...
    'Full-Track Front Axle Slip (red = apex)', slipAbsMax, ...
    x_pos, y_pos, valid, cornerBoxes, cornerMasks, kappa_yaw, ...
    minPassLen, maxGapSamples);

% Figure 10
plotFullMapSlip( ...
    alpha_r_deg, 'rear slip angle \alpha_r [deg]', ...
    'Full-Track Rear Axle Slip (red = apex)', slipAbsMax, ...
    x_pos, y_pos, valid, cornerBoxes, cornerMasks, kappa_yaw, ...
    minPassLen, maxGapSamples);


Fz_FL_raw = data.fl_load_n;   Fz_FR_raw = data.fr_load_n;
Fz_RL_raw = data.rl_load_n;   Fz_RR_raw = data.rr_load_n;

Fz_FL = Ffz_fl;   Fz_FR = Ffz_fr;     % filtered (black overlay)
Fz_RL = Ffz_rl;   Fz_RR = Ffz_rr;


%% lap 6 corner plots loop

targetPass = 6;

for c = 1:numCorners
    cName = char(cornerBoxes{c, 1});

    cMask   = fillSmallGaps(cornerMasks(:, c), maxGapSamples);
    cPasses = findPasses(cMask, minPassLen);
    nC      = numel(cPasses);

    if nC < targetPass
        warning('Skipping %s because fewer than %d passes were detected.', cName, targetPass);
        continue
    end

    idx  = cPasses{targetPass};
    prog = cornerProgressPct(idx, ds);     % 0..100 % corner progress

    if isempty(prog)
        warning('Skipping %s pass %d because corner progress was empty.', cName, targetPass);
        continue
    end

    aLoc    = apexIndexInPass(idx, kappa_yaw);   % existing apex definition
    hasApex = ~isempty(aLoc);

    cXmin = cornerBoxes{c, 2};
    cXmax = cornerBoxes{c, 3};
    cYmin = cornerBoxes{c, 4};
    cYmax = cornerBoxes{c, 5};

    figure('Position', [80 80 1200 950])
    tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('Corner %s', cName), 'Interpreter', 'none')

    
    ax1 = nexttile;
    hold(ax1, 'on'); grid(ax1, 'on')
    plot(ax1, x_pos, y_pos, '-', 'Color', [0.85 0.85 0.85])     % faint full track
    scatter(ax1, x_pos(idx), y_pos(idx), 18, prog, 'filled')    % path by progress
    colormap(ax1, parula); caxis(ax1, [0 100])
    cb1 = colorbar(ax1); cb1.Label.String = 'corner progress [%]';
    if hasApex
        plot(ax1, x_pos(idx(aLoc)), y_pos(idx(aLoc)), 'o', ...
            'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 7)
        text(ax1, x_pos(idx(aLoc)), y_pos(idx(aLoc)), '  apex', ...
            'Color', 'r', 'FontWeight', 'bold', 'FontSize', 11)
    end
    xlabel(ax1, 'x [m]'); ylabel(ax1, 'y [m]')
    title(ax1, 'corner path')
    axis(ax1, 'equal')   % fully zoomed out: show full map, no fixed xlim/ylim

   
    ax2 = nexttile;
    hold(ax2, 'on'); grid(ax2, 'on')
    hF = plot(ax2, prog, Fyf(idx), '-', 'Color', [0 0.45 1]);
    hR = plot(ax2, prog, Fyr(idx), '-', 'Color', [1 0.25 0]);
    if hasApex
        hA = plot(ax2, prog(aLoc), Fyf(idx(aLoc)), 'o', ...
            'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 6);
        plot(ax2, prog(aLoc), Fyr(idx(aLoc)), 'o', ...
            'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 6)
        xline(ax2, prog(aLoc), '--k', 'apex', 'LabelOrientation', 'horizontal')
        legend(ax2, [hF hR hA], {'F_{yf} front', 'F_{yr} rear', 'apex'}, 'Location', 'best')
    else
        legend(ax2, [hF hR], {'F_{yf} front', 'F_{yr} rear'}, 'Location', 'best')
    end
    xlabel(ax2, 'corner progress [%]'); ylabel(ax2, 'F_y [N]')
    title(ax2, 'Calculated lateral force through corner'); xlim(ax2, [0 100])

    
    ax3 = nexttile;
    hold(ax3, 'on'); grid(ax3, 'on')
    hFL = plot(ax3, prog, Fz_FL_raw(idx),                  '-', 'Color', [0 0.45 1]);
    hFR = plot(ax3, prog, Fz_FR_raw(idx),                  '-', 'Color', [1 0.25 0]);
    hFT = plot(ax3, prog, Fz_FR_raw(idx) - Fz_FL_raw(idx), '-', 'Color', [0 0.6 0.2]);
    hFK = plot(ax3, prog, Fz_FL(idx),                      '-', 'Color', 'k');   % filtered
          plot(ax3, prog, Fz_FR(idx),                      '-', 'Color', 'k');
          plot(ax3, prog, Fz_FR(idx) - Fz_FL(idx),         '-', 'Color', 'k');
    if hasApex
        xline(ax3, prog(aLoc), '--k', 'apex', 'LabelOrientation', 'horizontal')
    end
    xlabel(ax3, 'corner progress [%]'); ylabel(ax3, 'normal force [N]')
    title(ax3, 'front axle')
    legend(ax3, [hFL hFR hFT hFK], ...
        {'F_z FL', 'F_z FR', 'delta', 'filtered'}, 'Location', 'best')
    xlim(ax3, [0 100])

    
    ax4 = nexttile;
    hold(ax4, 'on'); grid(ax4, 'on')
    hRL = plot(ax4, prog, Fz_RL_raw(idx),                  '-', 'Color', [0 0.45 1]);
    hRR = plot(ax4, prog, Fz_RR_raw(idx),                  '-', 'Color', [1 0.25 0]);
    hRT = plot(ax4, prog, Fz_RR_raw(idx) - Fz_RL_raw(idx), '-', 'Color', [0 0.6 0.2]);
    hRK = plot(ax4, prog, Fz_RL(idx),                      '-', 'Color', 'k');   % filtered
          plot(ax4, prog, Fz_RR(idx),                      '-', 'Color', 'k');
          plot(ax4, prog, Fz_RR(idx) - Fz_RL(idx),         '-', 'Color', 'k');
    if hasApex
        xline(ax4, prog(aLoc), '--k', 'apex', 'LabelOrientation', 'horizontal')
    end
    xlabel(ax4, 'corner progress [%]'); ylabel(ax4, 'normal force [N]')
    title(ax4, 'rear axle')
    legend(ax4, [hRL hRR hRT hRK], ...
        {'F_z RL', 'F_z RR', 'delta', 'filtered'}, 'Location', 'best')
    xlim(ax4, [0 100])
end


%% normal load pot 
t_raw = data.time_s - data.time_s(1);

figure('Position', [100 100 1100 800])
tlN = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tlN, 'Tire Normal Force: Raw (color) with Filtered Overlay (black)')

% front axle: FL and FR
axNf = nexttile;
hold(axNf, 'on'); grid(axNf, 'on')
hfl = plot(axNf, t_raw, data.fl_load_n, '-');
hfr = plot(axNf, t_raw, data.fr_load_n, '-');
hfk = plot(axNf, t_raw, Ffz_fl, '-', 'Color', 'k');   % filtered overlay
      plot(axNf, t_raw, Ffz_fr, '-', 'Color', 'k');
xlabel(axNf, 'time [s]'); ylabel(axNf, 'Normal Force [N]')
title(axNf, 'Front axle (FL, FR)')
legend(axNf, [hfl hfr hfk], {'FL raw', 'FR raw', 'filtered'}, 'Location', 'best')

% rear axle: RL and RR
axNr = nexttile;
hold(axNr, 'on'); grid(axNr, 'on')
hrl = plot(axNr, t_raw, data.rl_load_n, '-');
hrr = plot(axNr, t_raw, data.rr_load_n, '-');
hrk = plot(axNr, t_raw, Ffz_rl, '-', 'Color', 'k');   % filtered overlay
      plot(axNr, t_raw, Ffz_rr, '-', 'Color', 'k');
xlabel(axNr, 'time [s]'); ylabel(axNr, 'Normal Force [N]')
title(axNr, 'Rear axle (RL, RR)')
legend(axNr, [hrl hrr hrk], {'RL raw', 'RR raw', 'filtered'}, 'Location', 'best')



function plotPerCornerProgression(y1, y2, yLabelStr, titleStr, legNames, ...
        cornerBoxes, cornerMasks, ds, kappa_yaw, nCols, minPassLen, maxGapSamples)

    numCorners = size(cornerBoxes,1);
    nRows = ceil(numCorners / nCols);

    figure
    tl = tiledlayout(nRows, nCols, ...
        'TileSpacing', 'compact', ...
        'Padding', 'compact');

    cmap = parula(256);
    axFirst = [];

    for i = 1:numCorners
        ax = nexttile;
        hold(ax, 'on')
        grid(ax, 'on')
        if isempty(axFirst)
            axFirst = ax;
        end

        % Bridge short gaps, then split this corner into per-lap passes
        mask   = fillSmallGaps(cornerMasks(:,i), maxGapSamples);
        passes = findPasses(mask, minPassLen);
        nP     = numel(passes);

        for k = 1:nP
            idx = passes{k};

            s0 = ds(idx(1));
            s1 = ds(idx(end));
            if s1 <= s0
                continue   % degenerate pass, skip
            end

           
            prog = (ds(idx) - s0) / (s1 - s0);

           
            if nP > 1
                ci = round(1 + (k-1)/(nP-1) * 255);
            else
                ci = 256;
            end
            col = cmap(ci, :);

            plot(ax, prog, y1(idx), '-', 'Color', col)
            if ~isempty(y2)
                plot(ax, prog, y2(idx), '--', 'Color', col)
            end

        
            aLoc = apexIndexInPass(idx, kappa_yaw);
            if ~isempty(aLoc)
                plot(ax, prog(aLoc), y1(idx(aLoc)), 'o', ...
                    'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', ...
                    'MarkerSize', 6)
                if ~isempty(y2)
                    plot(ax, prog(aLoc), y2(idx(aLoc)), 'o', ...
                        'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', ...
                        'MarkerSize', 6)
                end
            end
        end

        xlabel(ax, 'corner progress (0 = entry, 1 = exit)')
        ylabel(ax, yLabelStr)
        title(ax, cornerBoxes{i,1}, 'Interpreter', 'none')
        xlim(ax, [0 1])
        caxis(ax, [0 1])
    end

    % Legend (front/rear + apex) placed in the first tile
    if ~isempty(axFirst)
        hold(axFirst, 'on')
        if ~isempty(y2)
            h1 = plot(axFirst, nan, nan, 'k-');
            h2 = plot(axFirst, nan, nan, 'k--');
            hA = plot(axFirst, nan, nan, 'o', ...
                'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k');
            legend(axFirst, [h1 h2 hA], [legNames {'apex'}], 'Location', 'best')
        else
            hA = plot(axFirst, nan, nan, 'o', ...
                'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k');
            legend(axFirst, hA, {'apex'}, 'Location', 'best')
        end
    end

 
    colormap(cmap);
    cb = colorbar;
    cb.Layout.Tile  = 'east';
    cb.Ticks        = [0 1];
    cb.TickLabels   = {'early laps', 'late laps'};
    cb.Label.String = 'lap order';

    title(tl, titleStr)
end


function plotFullMapSlip(cvar, cLabelStr, titleStr, slipAbsMax, ...
        x_pos, y_pos, valid, cornerBoxes, cornerMasks, kappa_yaw, ...
        minPassLen, maxGapSamples)

    figure('Position', [100 100 1000 900])
    ax = axes('Parent', gcf, 'Position', [0.07 0.09 0.72 0.84]);
    hold(ax, 'on'); grid(ax, 'on')

    % faint full path for context
    plot(ax, x_pos, y_pos, '-', 'Color', [0.85 0.85 0.85])

    % slip-colored samples (valid speed only, to avoid low-speed junk).
    % Real slip in degrees, linear color axis over the full +/- range.
    m = valid & isfinite(cvar);
    scatter(ax, x_pos(m), y_pos(m), 12, cvar(m), 'filled')

    % high-contrast colormap so small slip-angle changes are easy to see
    if exist('turbo', 'file')
        cmapSlip = turbo(256);
    else
        % turbo-like fallback: dark blue -> cyan -> green -> yellow -> orange -> red
        cmapSlip = [linearColormap([0.20 0.05 0.55], [0.00 0.45 1.00], 43); ...
                    linearColormap([0.00 0.45 1.00], [0.00 1.00 1.00], 43); ...
                    linearColormap([0.00 1.00 1.00], [0.30 1.00 0.20], 43); ...
                    linearColormap([0.30 1.00 0.20], [1.00 1.00 0.00], 43); ...
                    linearColormap([1.00 1.00 0.00], [1.00 0.50 0.00], 43); ...
                    linearColormap([1.00 0.50 0.00], [0.70 0.00 0.00], 43)];
    end
    colormap(ax, cmapSlip)
    caxis(ax, [-slipAbsMax slipAbsMax])

    % mark every corner apex (one red dot per lap pass)
    for i = 1:size(cornerBoxes,1)
        mask   = fillSmallGaps(cornerMasks(:,i), maxGapSamples);
        passes = findPasses(mask, minPassLen);
        for k = 1:numel(passes)
            idx  = passes{k};
            aLoc = apexIndexInPass(idx, kappa_yaw);
            if ~isempty(aLoc)
                plot(ax, x_pos(idx(aLoc)), y_pos(idx(aLoc)), 'o', ...
                    'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 7)
            end
        end
    end

    xlabel(ax, 'x [m]'); ylabel(ax, 'y [m]')
    title(ax, titleStr)
    setSquareTopView(ax, ...
        [min(x_pos,[],'omitnan') max(x_pos,[],'omitnan')], ...
        [min(y_pos,[],'omitnan') max(y_pos,[],'omitnan')])

    % colorbar: linear, evenly spaced ticks in real slip-angle degrees
    cb = colorbar(ax);
    cb.Label.String = cLabelStr;
    if slipAbsMax > 12
        tickStep = 4;
    else
        tickStep = 2;
    end
    posTicks = tickStep:tickStep:slipAbsMax;
    cb.Ticks = unique([-fliplr(posTicks), 0, posTicks]);
end


function drawDriverInputsXY(ax, idx, x_pos, y_pos, throttle, Fbrake, ...
        brakeThresh, cmapThrot, cmapBrake, throtLim, brakeLim)


    idx = idx(:);
    isBrake = Fbrake(idx) > brakeThresh;

    bIdx = idx(isBrake);
    if ~isempty(bIdx)
        cB = valueToRGB(Fbrake(bIdx), brakeLim, cmapBrake);
        scatter(ax, x_pos(bIdx), y_pos(bIdx), 12, cB, 'filled')
    end

    tIdx = idx(~isBrake);
    if ~isempty(tIdx)
        cT = valueToRGB(throttle(tIdx), throtLim, cmapThrot);
        scatter(ax, x_pos(tIdx), y_pos(tIdx), 12, cT, 'filled')
    end
end


function addThrottleBrakeColorbars(fig, cmapThrot, throtLim, cmapBrake, brakeLim)

    % throttle colorbar (top right)
    axCbT = axes('Parent', fig, 'Position', [0.83 0.54 0.022 0.34], 'Visible', 'off');
    colormap(axCbT, cmapThrot);
    caxis(axCbT, throtLim);
    cbT = colorbar(axCbT, 'Position', [0.83 0.54 0.022 0.34]);
    cbT.Label.String = 'throttle [%]';

    % brake colorbar (bottom right)
    axCbB = axes('Parent', fig, 'Position', [0.83 0.10 0.022 0.34], 'Visible', 'off');
    colormap(axCbB, cmapBrake);
    caxis(axCbB, brakeLim);
    cbB = colorbar(axCbB, 'Position', [0.83 0.10 0.022 0.34]);
    cbB.Label.String = 'front brake pressure [kPa]';
end


function setSquareTopView(ax, xLim, yLim)


    xc = mean(xLim);
    yc = mean(yLim);

    halfSpan = 0.5 * max(diff(xLim), diff(yLim));   % use the larger span
    if ~(halfSpan > 0)
        halfSpan = 1;                               % guard degenerate region
    end

    xlim(ax, [xc - halfSpan, xc + halfSpan])
    ylim(ax, [yc - halfSpan, yc + halfSpan])

    ax.PlotBoxAspectRatio     = [1 1 1];    
    ax.PlotBoxAspectRatioMode = 'manual';   
    ax.DataAspectRatioMode    = 'auto';     
end


function cmap = linearColormap(c1, c2, n)


    t = linspace(0, 1, n)';
    cmap = (1 - t) .* c1 + t .* c2;
    cmap = max(0, min(1, cmap));
end


function rgb = valueToRGB(vals, lim, cmap)


    vals = vals(:);
    lo = lim(1);
    hi = lim(2);
    if hi <= lo
        hi = lo + 1;
    end

    f = (vals - lo) ./ (hi - lo);
    f = max(0, min(1, f));

    n = size(cmap, 1);
    rowIdx = round(1 + f * (n - 1));
    rowIdx(~isfinite(rowIdx)) = 1;

    rgb = cmap(rowIdx, :);
end


function aLoc = apexIndexInPass(idx, kappa_yaw)


    k = abs(kappa_yaw(idx));
    n = numel(k);
    if n == 0
        aLoc = [];
        return
    end

    win = max(3, round(0.08 * n));
    k = movmean(k, win, 'omitnan');
    k(~isfinite(k)) = -inf;


    guard = max(1, round(0.10 * n));
    lo = 1;
    hi = n;
    if n > 2*guard + 1
        lo = guard + 1;
        hi = n - guard;
    end

    kSearch = -inf(size(k));
    kSearch(lo:hi) = k(lo:hi);
    [bestVal, aLoc] = max(kSearch);

    if ~isfinite(bestVal)
        aLoc = [];
    end
end


function maskFilled = fillSmallGaps(mask, maxGap)


    mask = logical(mask(:));
    maskFilled = mask;
    n = numel(mask);

    i = 1;
    while i <= n
        if ~mask(i)
            j = i;
            while j <= n && ~mask(j)
                j = j + 1;
            end
      
            gapLen = j - i;
            if i > 1 && j <= n && gapLen <= maxGap
                maskFilled(i:j-1) = true;
            end
            i = j;
        else
            i = i + 1;
        end
    end
end


function passes = findPasses(mask, minLen)


    mask = logical(mask(:));
    d = diff([0; mask; 0]);
    startIdx = find(d == 1);
    endIdx   = find(d == -1) - 1;

    keep = (endIdx - startIdx + 1) >= minLen;
    startIdx = startIdx(keep);
    endIdx   = endIdx(keep);

    passes = cell(numel(startIdx), 1);
    for k = 1:numel(startIdx)
        passes{k} = (startIdx(k):endIdx(k))';
    end
end


function prog = cornerProgressPct(idx, ds)


    s0 = ds(idx(1));
    s1 = ds(idx(end));
    if ~(s1 > s0)
        prog = [];
        return
    end
    prog = 100 * (ds(idx) - s0) ./ (s1 - s0);
end
