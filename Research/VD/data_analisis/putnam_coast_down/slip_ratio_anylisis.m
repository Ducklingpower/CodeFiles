clc
close all
clear

%%
data = readtable('/home/elijah/bag_files/VD/laguna/comp/2025-07-24_175839_merged.csv');

tStart = 250;
tCut   = 850;

tRel = data.time_s - data.time_s(1);
data = data(tRel >= tStart & tRel <= tCut, :);

mm = 15;
vx_min_slip_angle = 10;
vx_min_slip_ratio = 0.001;

onlyAccelerating = false; 

useBankCorrection = true;
pitchSign = -1;

% Steering calibration
steeringRatio = 15.015;
steeringBias_deg = 0.333;

% Tire rolling radii
Rw_f = 0.30;   % [m]
Rw_r = 0.31;   % [m]

wheelSpeedIsKmh = true;
brakePressureMin_kPa = 200;
defaultFrontBrakeBias = 0.53; 

% Longitudinal force deadband
Fx_deadband_N = 50;

%% =========================
%  Vehicle Parameters
% =========================

vehicleParams.L       = 2.9718;   % [m] wheelbase
vehicleParams.wDistF  = 0.42;     % static front weight distribution
vehicleParams.m       = 815;      % [kg]
vehicleParams.Iz      = 1000;     % [kg m^2]
vehicleParams.hCG     = 0.275;    % [m]
vehicleParams.CdA     = 1.33;     % [m^2]
vehicleParams.rho     = 1.225;    % [kg/m^3]
vehicleParams.g       = 9.81;     % [m/s^2]

L  = vehicleParams.L;
m  = vehicleParams.m;
Iz = vehicleParams.Iz;
g  = vehicleParams.g;

% IMPORTANT:
% For a bicycle model:
% lf = CG to front axle
% lr = CG to rear axle
%
% Static front load fraction = lr / L
lr = vehicleParams.wDistF * L;    % CG to rear axle
lf = L - lr;                      % CG to front axle

%% filtered signals


t = data.time_s(:);
t = t - t(1);

ax = movmean(data.a_x, mm);
ay_meas = movmean(data.a_y, mm);

vx = movmean(data.odom_vx_mps, mm);
vy = movmean(data.odom_vy_mps, mm);

r = movmean(data.odom_wz_rads, mm);   % yaw rate

% yaw acceleration
dt = gradient(t);
dt(dt <= 0) = median(dt(dt > 0));

rdot = gradient(r) ./ dt;
rdot = movmean(rdot, mm);

% Steering
steering_wheel_deg = movmean(data.steer_wheel_ang_deg, mm);
delta_deg = steeringBias_deg + steering_wheel_deg ./ steeringRatio;
delta = deg2rad(delta_deg);

% Brake pressures
Pf = movmean(data.front_brake_pressure_kpa, mm);
Pr = movmean(data.rear_brake_pressure_kpa, mm);

% Driver-input based accelerating / braking classification.
throttle_pct   = movmean(data.throttle_pct, mm);
isAccelerating = throttle_pct > 15;           % throttle > 15% => on power
isBraking      = (Pf > 1000) | (Pr > 1000);   % brake pressure > 1000 kPa => braking

% Optional filter applied to ALL data (see onlyAccelerating).
if onlyAccelerating
    accelKeep = isAccelerating;
else
    accelKeep = true(size(ax));
end

% Position
x_pos = data.odom_px_m;
y_pos = data.odom_py_m;

% Distance traveled
V = sqrt(vx.^2 + vy.^2);
ds = [0; cumsum(0.5 .* (V(1:end-1) + V(2:end)) .* diff(t))];

%%
%  Pitch / Roll


qx = movmean(data.odom_qx, mm);
qy = movmean(data.odom_qy, mm);
qz = movmean(data.odom_qz, mm);
qw = movmean(data.odom_qw, mm);

q = [qw qx qy qz];
eul = quat2eul(q, 'ZYX');   % [yaw pitch roll]

pitch = eul(:,2);
roll  = eul(:,3);

theta = pitchSign .* pitch;
phi   = roll;

%% lat acel derived

kappa_yaw = nan(size(V));

validCurv = isfinite(V) & V > 2.0 & isfinite(r);
kappa_yaw(validCurv) = r(validCurv) ./ V(validCurv);

ay_inertial = V.^2 .* kappa_yaw;


g_y_body = -g .* cos(theta) .* sin(phi);

if useBankCorrection
    ay_tire = ay_inertial - g_y_body;
else
    ay_tire = ay_inertial;
end

ay_tire(~validCurv) = NaN;

%% 
%  Bicycle Model Slip Angles


vx_safe_angle = vx;
vx_safe_angle(abs(vx_safe_angle) < vx_min_slip_angle) = NaN;

vy_front = vy + lf .* r;
vy_rear  = vy - lr .* r;

alpha_f = delta - atan2(vy_front, vx_safe_angle);
alpha_r =       - atan2(vy_rear,  vx_safe_angle);

alpha_f_deg = rad2deg(alpha_f);
alpha_r_deg = rad2deg(alpha_r);

%% 
%  Bicycle Model Lateral Forces


Fyf = (m .* lr .* ay_tire + Iz .* rdot) ./ L;
Fyr = (m .* lf .* ay_tire - Iz .* rdot) ./ L;

%% FX total
rho = vehicleParams.rho;
CdA = vehicleParams.CdA;

Fdrag = 0.5 .* rho .* CdA .* vx .* abs(vx);      % sign-aware drag compensation
Fgrade = m .* g .* sin(theta);                   % positive uphill

Fx_total = m .* ax + Fdrag + Fgrade;

%%
%  Front / Rear Longitudinal Force Split


brakePressureTotal = Pf + Pr;

biasF = defaultFrontBrakeBias .* ones(size(Fx_total));

hasBrakePressure = brakePressureTotal > brakePressureMin_kPa;
biasF(hasBrakePressure) = Pf(hasBrakePressure) ./ brakePressureTotal(hasBrakePressure);

% Clamp for safety
biasF = max(0, min(1, biasF));

driveMode = Fx_total >  Fx_deadband_N;
brakeMode = Fx_total < -Fx_deadband_N;
coastMode = ~driveMode & ~brakeMode;

Fxf = zeros(size(Fx_total));
Fxr = zeros(size(Fx_total));

% Acceleration: rear axle only
Fxf(driveMode) = 0;
Fxr(driveMode) = Fx_total(driveMode);

% Braking: split by front brake bias
Fxf(brakeMode) = biasF(brakeMode) .* Fx_total(brakeMode);
Fxr(brakeMode) = (1 - biasF(brakeMode)) .* Fx_total(brakeMode);

% Coasting / deadband: both zero
Fxf(coastMode) = 0;
Fxr(coastMode) = 0;

% Diagnostic: this should match Fx_total outside the deadband
Fx_reconstructed = Fxf + Fxr;

%%
%  Normal Loads

useMeasuredFz = true;

Fz_front_offset_N = -4168.3223;
Fz_rear_offset_N  = -3885.9196;

if useMeasuredFz
    Fz_front = movmean(data.fl_load_n + data.fr_load_n, mm) + Fz_front_offset_N;
    Fz_rear  = movmean(data.rl_load_n + data.rr_load_n, mm) + Fz_rear_offset_N;
else
    Fz_front = m .* g .* cos(theta) .* cos(phi) .* lr ./ L ...
             - m .* ax .* vehicleParams.hCG ./ L;

    Fz_rear  = m .* g .* cos(theta) .* cos(phi) .* lf ./ L ...
             + m .* ax .* vehicleParams.hCG ./ L;
end

muXf = Fxf ./ Fz_front;
muYf = Fyf ./ Fz_front;

muXr = Fxr ./ Fz_rear;
muYr = Fyr ./ Fz_rear;

%% 
%  Wheel Speeds

if wheelSpeedIsKmh
    Vw_fl = movmean(data.fl_speed_kmh, mm) ./ 3.6;
    Vw_fr = movmean(data.fr_speed_kmh, mm) ./ 3.6;
    Vw_rl = movmean(data.rl_speed_kmh, mm) ./ 3.6;
    Vw_rr = movmean(data.rr_speed_kmh, mm) ./ 3.6;
else
    Vw_fl = movmean(data.fl_speed_radps, mm) .* Rw_f;
    Vw_fr = movmean(data.fr_speed_radps, mm) .* Rw_f;
    Vw_rl = movmean(data.rl_speed_radps, mm) .* Rw_r;
    Vw_rr = movmean(data.rr_speed_radps, mm) .* Rw_r;
end

Vw_front = 0.5 .* (Vw_fr + Vw_fr);
Vw_rear  = 0.5 .* (Vw_rl + Vw_rr);

%%
%  Tire Longitudinal Velocity


Vx_front_tire = vx .* cos(delta) + vy_front .* sin(delta);
Vx_rear_tire  = vx;

Vx_front_tire(abs(vx) < vx_min_slip_ratio) = NaN;
Vx_rear_tire(abs(vx)  < vx_min_slip_ratio) = NaN;

%%
%  Slip Ratio

slip_ratio_f = (Vw_front - Vx_front_tire) ./ Vw_front;
slip_ratio_r = (Vw_rear  - Vx_rear_tire)  ./ Vw_rear;

%% =========================
%  Valid Plot Masks
% =========================

validFront = isfinite(alpha_f_deg) & isfinite(Fyf) & ...
             isfinite(slip_ratio_f) & isfinite(Fxf) & ...
             isfinite(ds) & ...
             abs(vx) > vx_min_slip_angle & ...
             abs(alpha_f_deg) < 20 & ...
             abs(slip_ratio_f) < 1.0 & ...
             accelKeep;

validRear = isfinite(alpha_r_deg) & isfinite(Fyr) & ...
            isfinite(slip_ratio_r) & isfinite(Fxr) & ...
            isfinite(ds) & ...
            abs(vx) > vx_min_slip_angle & ...
            abs(alpha_r_deg) < 20 & ...
            abs(slip_ratio_r) < 1.0 & ...
            accelKeep;

%% plotting

figure('Name','Fx Force Split Sanity Check');

plot(ds, Fx_total);
hold on;
plot(ds, Fx_reconstructed, '--');
plot(ds, Fxf);
plot(ds, Fxr);

grid on;
xlabel('Distance around lap [m]');
ylabel('Longitudinal force [N]');
title('Longitudinal Force Split Sanity Check');
legend('Fx total', 'Fxf + Fxr', 'Fxf front axle', 'Fxr rear axle', 'Location', 'best');

yline(0, 'k--');

%% =========================
%  Front and Rear Tire Force Plots
% =========================

figure('Name','Bicycle Model Forces vs Slip');

subplot(2,2,1)
scatter(alpha_f_deg(validFront), Fyf(validFront), 18, ds(validFront), 'filled');
grid on;
xlabel('Front slip angle \alpha_f [deg]');
ylabel('Front lateral force F_{y,f} [N]');
title('Front F_y vs Front Slip Angle');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

subplot(2,2,2)
scatter(slip_ratio_f(validFront), Fxf(validFront), 18, ds(validFront), 'filled');
grid on;
xlabel('Front slip ratio \kappa_f [-]');
ylabel('Front longitudinal force F_{x,f} [N]');
title('Front F_x vs Front Slip Ratio');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

subplot(2,2,3)
scatter(alpha_r_deg(validRear), Fyr(validRear), 18, ds(validRear), 'filled');
grid on;
xlabel('Rear slip angle \alpha_r [deg]');
ylabel('Rear lateral force F_{y,r} [N]');
title('Rear F_y vs Rear Slip Angle');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

subplot(2,2,4)
scatter(slip_ratio_r(validRear), Fxr(validRear), 18, ds(validRear), 'filled');
grid on;
xlabel('Rear slip ratio \kappa_r [-]');
ylabel('Rear longitudinal force F_{x,r} [N]');
title('Rear F_x vs Rear Slip Ratio');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

sgtitle('Bicycle Model Force vs Slip Analysis');

%% 

figure('Name','Bicycle Model Normalized Forces vs Slip');

subplot(2,2,1)
scatter(alpha_f_deg(validFront), muYf(validFront), 18, ds(validFront), 'filled');
grid on;
xlabel('Front slip angle \alpha_f [deg]');
ylabel('Front normalized lateral force F_{y,f}/F_{z,f} [-]');
title('Front F_y/F_z vs Front Slip Angle');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

subplot(2,2,2)
scatter(slip_ratio_f(validFront), muXf(validFront), 18, ds(validFront), 'filled');
grid on;
xlabel('Front slip ratio \kappa_f [-]');
ylabel('Front normalized longitudinal force F_{x,f}/F_{z,f} [-]');
title('Front F_x/F_z vs Front Slip Ratio');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

subplot(2,2,3)
scatter(alpha_r_deg(validRear), muYr(validRear), 18, ds(validRear), 'filled');
grid on;
xlabel('Rear slip angle \alpha_r [deg]');
ylabel('Rear normalized lateral force F_{y,r}/F_{z,r} [-]');
title('Rear F_y/F_z vs Rear Slip Angle');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

subplot(2,2,4)
scatter(slip_ratio_r(validRear), muXr(validRear), 18, ds(validRear), 'filled');
grid on;
xlabel('Rear slip ratio \kappa_r [-]');
ylabel('Rear normalized longitudinal force F_{x,r}/F_{z,r} [-]');
title('Rear F_x/F_z vs Rear Slip Ratio');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

sgtitle('Bicycle Model Normalized (F/F_z) Force vs Slip Analysis');

%% 

figure('Name','Axle Friction Usage');

subplot(1,2,1)
scatter(muXf(validFront), muYf(validFront), 18, ds(validFront), 'filled');
grid on;
xlabel('\mu_{x,f} = F_{x,f}/F_{z,f}');
ylabel('\mu_{y,f} = F_{y,f}/F_{z,f}');
title('Front Axle Friction Usage');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');
axis equal;

subplot(1,2,2)
scatter(muXr(validRear), muYr(validRear), 18, ds(validRear), 'filled');
grid on;
xlabel('\mu_{x,r} = F_{x,r}/F_{z,r}');
ylabel('\mu_{y,r} = F_{y,r}/F_{z,r}');
title('Rear Axle Friction Usage');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');
axis equal;

sgtitle('Front and Rear Axle Friction Usage');

%%

figure('Name','Track Map');

scatter(x_pos, y_pos, 18, ds, 'filled');
grid on;
axis equal;
xlabel('X position [m]');
ylabel('Y position [m]');
title('Track Map (Position Colored by Distance Around Lap)');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');


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

% Basic per-sample validity for geometric corner selection.
valid = isfinite(x_pos) & isfinite(y_pos);

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


cornerNames = string(cornerBoxes(:,1));
iC11    = find(cornerNames == "C11", 1);
maskC11 = cornerMasks(:, iC11);

% Apply the global accel-only filter (see onlyAccelerating / accelKeep).
maskC11 = maskC11 & accelKeep;

% Combine the geometric corner mask with the force-validity masks.
frontC11 = maskC11 & validFront;
rearC11  = maskC11 & validRear;

%% Corner 11: Fx vs slip ratio

figure('Name','Corner 11 - Fx vs Slip Ratio');

subplot(1,2,1)
scatter(slip_ratio_f(frontC11), Fxf(frontC11), 18, ds(frontC11), 'filled');
grid on;
xlabel('Front slip ratio \kappa_f [-]');
ylabel('Front longitudinal force F_{x,f} [N]');
title('C11 Front F_x vs Slip Ratio');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

subplot(1,2,2)
scatter(slip_ratio_r(rearC11), Fxr(rearC11), 18, ds(rearC11), 'filled');
grid on;
xlabel('Rear slip ratio \kappa_r [-]');
ylabel('Rear longitudinal force F_{x,r} [N]');
title('C11 Rear F_x vs Slip Ratio');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

sgtitle('Corner 11 Longitudinal Force vs Slip Ratio');

%% Corner 11: time histories

% NaN-mask the signals so only the C11 segments are drawn (breaks lines
% between separate laps / visits).
ax_c11    = ax;                ax_c11(~maskC11)    = NaN;
slipR_c11 = slip_ratio_r;      slipR_c11(~maskC11) = NaN;
Vw_fl_c11 = Vw_fl;             Vw_fl_c11(~maskC11) = NaN;
Vw_fr_c11 = Vw_fr;             Vw_fr_c11(~maskC11) = NaN;
Vw_rl_c11 = Vw_rl;             Vw_rl_c11(~maskC11) = NaN;
Vw_rr_c11 = Vw_rr;             Vw_rr_c11(~maskC11) = NaN;
Fz_fl_c11 = movmean(data.fl_load_n, mm); Fz_fl_c11(~maskC11) = NaN;
Fz_fr_c11 = movmean(data.fr_load_n, mm); Fz_fr_c11(~maskC11) = NaN;
Fz_rl_c11 = movmean(data.rl_load_n, mm); Fz_rl_c11(~maskC11) = NaN;
Fz_rr_c11 = movmean(data.rr_load_n, mm); Fz_rr_c11(~maskC11) = NaN;
thr_c11   = throttle_pct;                thr_c11(~maskC11)   = NaN;

figure('Name','Corner 11 - Time Series');

axC11 = gobjects(5,1);

axC11(1) = subplot(5,1,1);
plot(t, ax_c11);
grid on;
xlabel('Time [s]');
ylabel('a_x [m/s^2]');
title('Corner 11: Longitudinal Acceleration vs Time');
yline(0,'k--');

axC11(2) = subplot(5,1,2);
plot(t, slipR_c11);
grid on;
xlabel('Time [s]');
ylabel('Rear slip ratio \kappa_r [-]');
title('Corner 11: Rear Slip Ratio vs Time');
yline(0,'k--');

axC11(3) = subplot(5,1,3);
plot(t, Vw_fl_c11);
hold on;
plot(t, Vw_fr_c11);
plot(t, Vw_rl_c11);
plot(t, Vw_rr_c11);
grid on;
xlabel('Time [s]');
ylabel('Wheel speed [m/s]');
title('Corner 11: Wheel Speeds vs Time');
legend('FL','FR','RL','RR','Location','best');

axC11(4) = subplot(5,1,4);
plot(t, Fz_fl_c11);
hold on;
plot(t, Fz_fr_c11);
plot(t, Fz_rl_c11);
plot(t, Fz_rr_c11);
grid on;
xlabel('Time [s]');
ylabel('Normal load [N]');
title('Corner 11: Tire Normal Loads vs Time');
legend('FL','FR','RL','RR','Location','best');

axC11(5) = subplot(5,1,5);
plot(t, thr_c11);
grid on;
xlabel('Time [s]');
ylabel('Throttle [%]');
title('Corner 11: Throttle vs Time');

linkaxes(axC11, 'x');

sgtitle('Corner 11 Time Histories');

%% =========================
%  Local Functions
% =========================

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



%% figure

figure
plot(t,data.fl_pressure_mbar)
hold on
plot(t,data.fr_pressure_mbar)
hold on
plot(t,data.rl_pressure_mbar)
hold on
plot(t,data.fr_pressure_mbar)

hold on

plot(t,data.front_brake_pressure_kpa,"r")