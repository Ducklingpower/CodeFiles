clc
close all
clear




%% csv

% data = readtable('FastLaps.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/putnam/oversteer/2026-04-28_150159_merged.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv');
data = readtable('/home/elijah/bag_files/VD/laguna/comp/2025-07-24_175839_merged.csv');


corner_plot_1  = 0;   % C1
corner_plot_2  = 1;   % C2
corner_plot_3  = 1;   % C3
corner_plot_4  = 1;   % C4
corner_plot_5  = 0;   % C5
corner_plot_6  = 0;   % C6
corner_plot_7  = 0;   % C7-8_corkscrew
corner_plot_8  = 0;   % C9
corner_plot_9  = 0;   % C10
corner_plot_10 = 1;   % C11

tStart = 250;
tCut   = 850;
tRel   = data.time_s - data.time_s(1);
data   = data(tRel >= tStart & tRel <= tCut, :);


%% filtered data  (unchanged filtering strategy)

mm = 15;
Ft = movmean(data.time_s,mm);

Fax = movmean(data.a_x,mm);
% 
% % ax masking
% Fax(Fax<=0) = NaN;

Fay = movmean(data.a_y,mm);
Faz = movmean(data.a_z,mm);

Ffz_fr = movmean(data.fr_load_n,mm);
Ffz_fl = movmean(data.fl_load_n,mm);
Ffz_rr = movmean(data.rr_load_n,mm);
Ffz_rl = movmean(data.rl_load_n,mm);
% 
% Ffz_fr =data.fr_load_n;
% Ffz_fl =data.fl_load_n;
% Ffz_rr =data.rr_load_n;
% Ffz_rl =data.rl_load_n;

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

% front and rear brake pressures (raw, NOT filtered)
brake_pressure_f = data.front_brake_pressure_kpa;
brake_pressure_r = data.rear_brake_pressure_kpa;

% brake_pressure_ratio removed: it was unused and produced Inf when the
% rear brake pressure was zero (divide-by-zero).



%% getting yaw, pitch, and roll curvature  

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
vehicleParams.m           = 815;         % vehicle mass (kg)  [base vehicle mass]
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


%% front/rear longitudinal force estimate  (valid for ANY a_x)


rho = 1.225;
A   = vehicleParams.frontalArea;
Cd  = 1.33;           

Fair         = 0.5 * rho * A * Cd .* Fvx.^2; 
Fpitch_force = m * g .* sin(theta);           % gravity component along body-x
Fbody        = m .* Fax;                        % m * longitudinal acceleration

Fx_total = Fbody + Fair + Fpitch_force;         % total longitudinal force [N]

Pf = brake_pressure_f;   % front brake pressure [kPa]
Pr = brake_pressure_r;   % rear  brake pressure [kPa]


brakeThresh = 200;                      % [kPa]
isBraking   = (Pf + Pr) > brakeThresh;

% front share of brake effort, per sample (0 where not braking)
biasF = zeros(size(Pf));
biasF(isBraking) = Pf(isBraking) ./ (Pf(isBraking) + Pr(isBraking));


Fxf = zeros(size(Fx_total));
Fxr = zeros(size(Fx_total));

Fxr(~isBraking) = Fx_total(~isBraking);
Fxf(~isBraking) = 0;


Fxf(isBraking) =  biasF(isBraking)       .* Fx_total(isBraking);
Fxr(isBraking) = (1 - biasF(isBraking))  .* Fx_total(isBraking);

% Global valid mask
valid = isfinite(alpha_f_deg) & isfinite(alpha_r_deg) & ...
        isfinite(Fyf) & isfinite(Fyr) & ...
        abs(Fvx) > vx_min;



% normal force calc 

% front axle offset 
Fz_front = Ffz_fl + Ffz_fr - 4168.3223;
Fz_rear  = Ffz_rl + Ffz_rr - 3885.9196;

% friction usage = tire force / axle normal load.  Captured here because
% Fz_rear is later reused (no-offset) as a loop variable further down.
muXf = Fxf ./ Fz_front;   % front longitudinal friction usage
muYf = Fyf ./ Fz_front;   % front lateral      friction usage
muXr = Fxr ./ Fz_rear;    % rear  longitudinal friction usage
muYr = Fyr ./ Fz_rear;    % rear  lateral      friction usage




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


%% track map with corner boxes  (own figure)

figMap = figure('WindowStyle', 'docked');
plot(x_pos, y_pos, 'b')
hold on
grid on
xlabel("xpos")
ylabel("ypos")
title("Track Map with Corner Sections (rear-accel analysis)")

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


%% plotting lap six

targetPass = 6;           

plotAllAx = true;
if plotAllAx
    accelMask = true(size(Fax));   % plot every sample (any a_x)
    gateLabel = 'all a_x';
else
    accelMask = Fax > 0;           % acceleration zone only (filtered a_x)
    gateLabel = 'a_x > 0';
end

minPassLen    = 8;        
maxGapSamples = 5;         

Fz_rear = Ffz_rl + Ffz_rr;   % Fz_RL + Fz_RR  (filtered)

% per-corner toggles assembled in loop order (index c -> corner row)
cornerPlotFlags = [corner_plot_1  corner_plot_2  corner_plot_3  corner_plot_4  corner_plot_5 ...
                   corner_plot_6  corner_plot_7  corner_plot_8  corner_plot_9  corner_plot_10];

for c = 1:numCorners
    if cornerPlotFlags(c) ~= 1   % skip this corner's 4-panel figure when its toggle is 0
        continue
    end

    cName = char(cornerBoxes{c, 1});

    cMask   = fillSmallGaps(cornerMasks(:, c), maxGapSamples);
    cPasses = findPasses(cMask, minPassLen);
    nC      = numel(cPasses);

    if nC < targetPass
        warning('Skipping %s because fewer than %d passes were detected.', cName, targetPass);
        continue
    end

    % ---- pass indexing first (do NOT destroy it with the accel mask) ----
    idx  = cPasses{targetPass};
    prog = cornerProgressPct(idx, ds);     % 0..100 % corner progress (full corner)

    if isempty(prog)
        warning('Skipping %s pass %d because corner progress was empty.', cName, targetPass);
        continue
    end

    % apex from the existing curvature-based definition
    aLoc    = apexIndexInPass(idx, kappa_yaw);
    hasApex = ~isempty(aLoc);

    
    idxAccelLocal = accelMask(idx) & isfinite(Fxr(idx)) & isfinite(Fyr(idx));
    idxAccel      = idx(idxAccelLocal);     
    progAccel     = prog(idxAccelLocal);    

    if isempty(idxAccel)
        warning('Skipping %s pass %d because no gated samples were found.', cName, targetPass);
        continue
    end

    % does the apex sample itself pass the plot gate?
    apexIsAccel = hasApex && idxAccelLocal(aLoc);

    FyrPass = Fyr(idx);     FyrPass(~idxAccelLocal) = NaN;
    FxrPass = Fxr(idx);     FxrPass(~idxAccelLocal) = NaN;
    FzrPass = Fz_rear(idx); FzrPass(~idxAccelLocal) = NaN;

    figure('WindowStyle', 'normal', 'Position', [80 80 1200 950])   % independent (not docked); many of these
    tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('Rear-axle combined loading (%s) - Corner %s, pass %d', ...
        gateLabel, cName, targetPass), 'Interpreter', 'none')


    ax1 = nexttile;
    hold(ax1, 'on'); grid(ax1, 'on')
    plot(ax1, x_pos, y_pos, '-', 'Color', [0.85 0.85 0.85])        % full track, faint
    plot(ax1, x_pos(idx), y_pos(idx), '-', 'Color', [0.6 0.6 0.6]) % selected pass path
    scatter(ax1, x_pos(idxAccel), y_pos(idxAccel), 22, progAccel, 'filled')  % gated, by progress
    colormap(ax1, parula); caxis(ax1, [0 100])
    cb1 = colorbar(ax1); cb1.Label.String = 'corner progress [%]';
    if hasApex
        plot(ax1, x_pos(idx(aLoc)), y_pos(idx(aLoc)), 'o', ...
            'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 7)
        text(ax1, x_pos(idx(aLoc)), y_pos(idx(aLoc)), '  apex', ...
            'Color', 'r', 'FontWeight', 'bold', 'FontSize', 11)
    end
    xlabel(ax1, 'x [m]'); ylabel(ax1, 'y [m]')
    title(ax1, sprintf('Selected corner/pass samples (%s)', gateLabel))
    setSquareTopView(ax1, ...
        [min(x_pos,[],'omitnan') max(x_pos,[],'omitnan')], ...
        [min(y_pos,[],'omitnan') max(y_pos,[],'omitnan')])


    ax2 = nexttile;
    hold(ax2, 'on'); grid(ax2, 'on')
    hFy = plot(ax2, prog, FyrPass, '-', 'Color', [1 0.25 0]);      % rear lateral
    hFx = plot(ax2, prog, FxrPass, '-', 'Color', [0 0.45 1]);      % rear longitudinal
    if hasApex
        hA = xline(ax2, prog(aLoc), '--k', 'apex', 'LabelOrientation', 'horizontal');
        legend(ax2, [hFy hFx hA], {'F_{yr} rear lateral', 'F_{xr} rear longitudinal', 'apex'}, ...
            'Location', 'best')
    else
        legend(ax2, [hFy hFx], {'F_{yr} rear lateral', 'F_{xr} rear longitudinal'}, ...
            'Location', 'best')
    end
    xlabel(ax2, 'corner progress [%]'); ylabel(ax2, 'force [N]')
    title(ax2, sprintf('Rear F_x/F_y through corner (%s)', gateLabel)); xlim(ax2, [0 100])


    ax3 = nexttile;
    hold(ax3, 'on'); grid(ax3, 'on')
    hFz = plot(ax3, prog, FzrPass, '-', 'Color', [0 0.6 0.2]);     % filtered Fz_RL + Fz_RR
    if hasApex
        xline(ax3, prog(aLoc), '--k', 'apex', 'LabelOrientation', 'horizontal')
    end
    xlabel(ax3, 'corner progress [%]'); ylabel(ax3, 'normal force [N]')
    title(ax3, sprintf('Rear axle normal load (%s)', gateLabel))
    legend(ax3, hFz, {'F_{z,rear} = F_z RL + F_z RR (filtered)'}, 'Location', 'best')
    xlim(ax3, [0 100])

    ax4 = nexttile;
    hold(ax4, 'on'); grid(ax4, 'on')
    scatter(ax4, Fxr(idxAccel), Fyr(idxAccel), 26, progAccel, 'filled')
    colormap(ax4, parula); caxis(ax4, [0 100])
    cb4 = colorbar(ax4); cb4.Label.String = 'corner progress [%]';
    if apexIsAccel
        plot(ax4, Fxr(idx(aLoc)), Fyr(idx(aLoc)), 'o', ...
            'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 8)
        text(ax4, Fxr(idx(aLoc)), Fyr(idx(aLoc)), '  apex', ...
            'Color', 'r', 'FontWeight', 'bold', 'FontSize', 11)
    end
    xlabel(ax4, 'Rear F_x [N]'); ylabel(ax4, 'Rear F_y [N]')
    title(ax4, 'Rear combined loading: F_y vs F_x')
end

%% whole-run combined loading
plotStride = 5;   % plotting only, increase to 10 or 20 if MATLAB still lags

accelAllF = accelMask & valid & isfinite(Fxf) & isfinite(Fyf);   % front-axle samples
accelAllR = accelMask & valid & isfinite(Fxr) & isfinite(Fyr);   % rear-axle samples

% plot-only downsampling: thins the scatter indices, never the data/calcs
idxF = find(accelAllF);
idxR = find(accelAllR);

idxF = idxF(1:plotStride:end);
idxR = idxR(1:plotStride:end);

figAxle = figure('WindowStyle', 'docked');
tlAxle  = tiledlayout(figAxle, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tlAxle, sprintf('Whole-run combined loading (%s): F_y vs F_x', gateLabel))

% font
axF = nexttile(tlAxle);
scatter(axF, Fxf(idxF), Fyf(idxF), 14, t(idxF), 'filled', 'MarkerEdgeColor', 'none')
grid(axF, 'on')
colormap(axF, parula)
cbF = colorbar(axF); cbF.Label.String = 'time [s]';
xlabel(axF, 'Front F_x [N]'); ylabel(axF, 'Front F_y [N]')
title(axF, 'Front axle: F_y vs F_x')

% rear
axR = nexttile(tlAxle);
scatter(axR, Fxr(idxR), Fyr(idxR), 14, t(idxR), 'filled', 'MarkerEdgeColor', 'none')
grid(axR, 'on')
colormap(axR, parula)
cbR = colorbar(axR); cbR.Label.String = 'time [s]';
xlabel(axR, 'Rear F_x [N]'); ylabel(axR, 'Rear F_y [N]')
title(axR, 'Rear axle: F_y vs F_x')

% same scale on both so front vs rear can be compared directly
linkaxes([axF axR], 'xy')

% plot-only limits: use percentiles so extreme force outliers don't blow
% up the linked axes (does not change any underlying force arrays)
fxAll = [Fxf(idxF); Fxr(idxR)];
fyAll = [Fyf(idxF); Fyr(idxR)];

xL = prctile(fxAll, [1 99]);
yL = prctile(fyAll, [1 99]);



%% figure 13  whole-run friction usage
FzMin = 500;     % N, plot-only safety threshold
muLim = 3;       % plot-only friction usage bound

% plot-only masks: drop tiny normal loads, non-finite, and extreme friction
% usage values so the scatter (and linked axes) stay well-behaved. The muXf /
% muYf / muXr / muYr arrays themselves are NOT modified.
accelMuF = accelMask & valid & ...
           Fz_front > FzMin & ...
           isfinite(muXf) & isfinite(muYf) & ...
           abs(muXf) < muLim & abs(muYf) < muLim;

accelMuR = accelMask & valid & ...
           Fz_rear > FzMin & ...
           isfinite(muXr) & isfinite(muYr) & ...
           abs(muXr) < muLim & abs(muYr) < muLim;

% plot-only downsampling of the masked indices
idxMuF = find(accelMuF);
idxMuR = find(accelMuR);

idxMuF = idxMuF(1:plotStride:end);
idxMuR = idxMuR(1:plotStride:end);

figMu = figure('WindowStyle', 'docked');
tlMu  = tiledlayout(figMu, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tlMu, sprintf('Whole-run friction usage (%s): \\mu_y vs \\mu_x', gateLabel))

% front
axMuF = nexttile(tlMu);
scatter(axMuF, muXf(idxMuF), muYf(idxMuF), 14, t(idxMuF), 'filled', 'MarkerEdgeColor', 'none')
grid(axMuF, 'on')
colormap(axMuF, parula)
cbMuF = colorbar(axMuF); cbMuF.Label.String = 'time [s]';
xlabel(axMuF, '\mu_x front (F_x / F_z)'); ylabel(axMuF, '\mu_y front (F_y / F_z)')
title(axMuF, 'Front axle: \mu_y vs \mu_x')

% rear
axMuR = nexttile(tlMu);
scatter(axMuR, muXr(idxMuR), muYr(idxMuR), 14, t(idxMuR), 'filled', 'MarkerEdgeColor', 'none')
grid(axMuR, 'on')
colormap(axMuR, parula)
cbMuR = colorbar(axMuR); cbMuR.Label.String = 'time [s]';
xlabel(axMuR, '\mu_x rear (F_x / F_z)'); ylabel(axMuR, '\mu_y rear (F_y / F_z)')
title(axMuR, 'Rear axle: \mu_y vs \mu_x')

% same scale on both so front vs rear can be compared directly
linkaxes([axMuF axMuR], 'xy')







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
