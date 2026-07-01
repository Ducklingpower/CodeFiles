clc
close all
clear

%% csv

% data = readtable('FastLaps.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/putnam/oversteer/2026-04-28_150159_merged.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv');
data = readtable('/home/elijah/bag_files/VD/laguna/comp/2025-07-24_175839_merged.csv');
tStart = 0;                                 
tCut   = 900;                                 
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



%% rear axle Fy vs slip angle and Fx vs slip ratio
% Add this AFTER the muXr / muYr section

% ------------------------------------------------------------
% rear wheel speed column names
% CHANGE THESE IF YOUR CSV USES DIFFERENT NAMES
% ------------------------------------------------------------

rr_wheel_col = 'rr_wheel_speed_radps';
rl_wheel_col = 'rl_wheel_speed_radps';

omega_rr = movmean(data.rl_speed_kmh, mm) * 0.277778;   % rear-right wheel angular speed [rad/s]
omega_rl = movmean(data.rr_speed_kmh, mm) * 0.277778;   % rear-left  wheel angular speed [rad/s]

omega_r = 0.5 .* (omega_rr + omega_rl);        % rear axle average wheel speed [rad/s]

% ------------------------------------------------------------
% rear axle slip ratio using the method from the paper
% ------------------------------------------------------------

Rw_r = 0.31;       % rear tire rolling radius [m]
Lr   = b;          % CG to rear axle distance [m]
delta_r = 0;       % rear steer angle [rad], assumed zero

vx = Fvx;
vy = Fvy;
r  = Fwz;

vx_safe = vx;
vx_safe(abs(vx_safe) < vx_min) = NaN;

% Rear axle lateral velocity term
vy_r = vy - Lr .* r;

% Rear tire velocity magnitude
Vtr = sqrt(vy_r.^2 + vx_safe.^2);

% Rear slip angle using the paper convention
alpha_r_paper = atan2(vy_r, vx_safe) - delta_r;

% Current code convention was alpha_r = -atan2(...)
% For plotting against your existing force sign convention, keep your original alpha_r_deg
alpha_r_plot_deg = alpha_r_deg;

% Rear tire longitudinal velocity along tire direction
v_axr = Vtr .* cos(alpha_r_paper);

% Rear slip ratio from paper:
% S_ar = (v_axr - omega_r * Rw) / v_axr
slip_ratio_r = (v_axr - omega_r .* Rw_r) ./ v_axr;

% Optional: if you want positive slip during throttle, uncomment this:
% slip_ratio_r = -slip_ratio_r;

% ------------------------------------------------------------
% valid plotting mask
% ------------------------------------------------------------

validRear = isfinite(alpha_r_plot_deg) & ...
            isfinite(Fyr) & ...
            isfinite(Fxr) & ...
            isfinite(slip_ratio_r) & ...
            isfinite(ds) & ...
            abs(vx) > vx_min;

% Optional cleanup to remove crazy wheel-speed spikes
validRear = validRear & abs(alpha_r_plot_deg) < 20 & abs(slip_ratio_r) < 1.0;

% ------------------------------------------------------------
% plots
% ------------------------------------------------------------

figure;

subplot(1,2,1)
scatter(alpha_r_plot_deg(validRear), Fyr(validRear), 18, ds(validRear), 'filled');
grid on;
xlabel('Rear slip angle \alpha_r [deg]');
ylabel('Rear lateral force F_{y,r} [N]');
title('Rear F_y vs Rear Slip Angle');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');

subplot(1,2,2)
scatter(slip_ratio_r(validRear), Fxr(validRear), 18, ds(validRear), 'filled');
grid on;
xlabel('Rear slip ratio S_{ar} [-]');
ylabel('Rear longitudinal force F_{x,r} [N]');
title('Rear F_x vs Rear Slip Ratio');
cb = colorbar;
ylabel(cb, 'Distance around lap [m]');
xline(0,'k--');
yline(0,'k--');