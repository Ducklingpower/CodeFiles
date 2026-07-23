clc
close all
clear

%% data
%data = readtable('/home/elijah/PurdueRacing/bags/putnum/oversteer/2026-04-28_150159_merged.csv');
data = readtable('/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/lagoona/october/spin_out/csv_output/2025-10-28_180511_merged.csv'); % october testing oversteer
% 
%data = readtable("/home/elijah/PurdueRacing/bags/lvms/hard_braking/csv_output/2025-04-10_120110_merged.csv");
data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_19_full_test/csv_output/2026-07-19_133128_merged.csv");

tRel = data.time_s - data.time_s(1);
t0 = data.time_s(1);          
% tStart = 1215;
% tCut   = 1229;
tStart = 0;
tCut   = length(tRel);
data = data(tRel >= tStart & tRel <= tCut, :);

plot_modeled = false;

%% corner highlight 

highlightOn     = false;     
highlightCorner = 'C2';    

%% params
mm = 22;
vx_min_slip_angle = 2;
vx_min_slip_ratio = 0.001;
onlyAccelerating = false;
useBankCorrection = true;
pitchSign = -1;
steeringRatio = 15.015;
steeringBias_deg = 0.333;
Rw_f = 0.30;
Rw_r = 0.31;
wheelSpeedIsKmh = true;
brakePressureMin_kPa = 75;
defaultFrontBrakeBias = 0.53;
Fx_deadband_N = 50;
throttleAccel_pct = 7;

vehicleParams.L      = 2.9718;
vehicleParams.wDistF = 0.42;
vehicleParams.m      = 815;
vehicleParams.Iz     = 1000;
vehicleParams.hCG    = 0.35;
vehicleParams.CdA    = 1.33;
vehicleParams.rho    = 1.225;
vehicleParams.g      = 9.81;

% dual-track load-transfer params 
vehicleParams.tF        = 1.638762;    
vehicleParams.tR        = 1.5239686;    
vehicleParams.wheelRateF = 2.985553732e5;
vehicleParams.wheelRateR = 3.941321827e5; 
vehicleParams.ARBf      = 0;            
vehicleParams.ARBr      = 0;             
vehicleParams.rcF       = 0.1202436;     
vehicleParams.rcR       = 0.0016628;     
vehicleParams.ACdLift   = 0.58;          
vehicleParams.aeroBal   = 0.33;          
vehicleParams.azScalar  = 2;           

L  = vehicleParams.L;
m  = vehicleParams.m;
Iz = vehicleParams.Iz;
g  = vehicleParams.g;
hcg = vehicleParams.hCG;

lr = vehicleParams.wDistF * L;
lf = L - lr;
front_track = 1.68;
rear_track  = 1.52;

%% filtered signals
t = data.time_s(:);
t = t - t(1);
tAbs = data.time_s(:) - t0;   % absolute time (relative to recording start) for colorbars

ax = movmean(data.a_x, mm);
ay_meas = movmean(data.a_y, mm);
vx = movmean(data.odom_vx_mps, mm);
vy = movmean(data.odom_vy_mps, mm);
r  = movmean(data.odom_wz_rads, mm);
wy = -movmean(data.odom_wy_rads, mm);   % pitch rate, signed to match theta

dt = gradient(t);
dt(dt <= 0) = median(dt(dt > 0));
rdot = gradient(r) ./ dt;
rdot = movmean(rdot, mm);

steering_wheel_deg = movmean(data.steer_wheel_ang_deg, mm);
delta_deg = steeringBias_deg + steering_wheel_deg ./ steeringRatio;
delta = deg2rad(delta_deg);

Pf = movmean(data.front_brake_pressure_kpa, mm);
Pr = movmean(data.rear_brake_pressure_kpa, mm);
throttle_pct = movmean(data.throttle_pct, mm);
cmd_throttle = movmean(data.joy_accelerator_cmd, mm);
isAccelerating = throttle_pct > throttleAccel_pct;
isBraking = (Pf > 1000) | (Pr > 1000);

if onlyAccelerating
    accelKeep = isAccelerating;
else
    accelKeep = true(size(ax));
end

x_pos = data.odom_px_m;
y_pos = data.odom_py_m;

V = sqrt(vx.^2 + vy.^2);
ds = [0; cumsum(0.5 .* (V(1:end-1) + V(2:end)) .* diff(t))];

%% pitch roll
qx = movmean(data.odom_qx, mm);
qy = movmean(data.odom_qy, mm);
qz = movmean(data.odom_qz, mm);
qw = movmean(data.odom_qw, mm);

q = [qw qx qy qz];
eul = quat2eul(q, 'ZYX');
pitch = eul(:,2);
roll  = eul(:,3);
theta = pitchSign .* pitch;
phi   = roll;

%% lat accel
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


%% slip angles
vx_safe_angle = vx;
vx_safe_angle(abs(vx_safe_angle) < vx_min_slip_angle) = NaN;

vy_front = vy + lf .* r;
vy_rear  = vy - lr .* r;

alpha_f = delta - atan2(vy_front, vx_safe_angle);
alpha_r =       - atan2(vy_rear,  vx_safe_angle);
alpha_f_deg = rad2deg(alpha_f);
alpha_r_deg = rad2deg(alpha_r);

Fyf = (m .* lr .* ay_tire + Iz .* rdot) ./ L;
Fyr = (m .* lf .* ay_tire - Iz .* rdot) ./ L;

%% Fx calc
rho = vehicleParams.rho;
CdA = vehicleParams.CdA;

Fdrag  = 0.5 .* rho .* CdA .* vx .* abs(vx);
Fgrade = m .* g .* sin(theta);
Fx_total = m .* ax + Fdrag + Fgrade + Fyf.*sin(delta);



%% normal loads
Fz_front_offset_N = 3700;
Fz_rear_offset_N  = 3050;

Fz_fl = movmean(data.fl_load_n,mm) - Fz_front_offset_N/2; 
Fz_fr = movmean(data.fr_load_n,mm) - Fz_front_offset_N/2; 
Fz_rl = movmean(data.rl_load_n,mm) - Fz_rear_offset_N/2; 
Fz_rr = movmean(data.rr_load_n,mm) - Fz_rear_offset_N/2; 

Fz_front = Fz_fl + Fz_fr;
Fz_rear  = Fz_rl + Fz_rr;

%% normal loads

tF        = vehicleParams.tF;
tR        = vehicleParams.tR;
wheelRateF = vehicleParams.wheelRateF;
wheelRateR = vehicleParams.wheelRateR;
ARBf      = vehicleParams.ARBf;
ARBr      = vehicleParams.ARBr;
rcF       = vehicleParams.rcF;
rcR       = vehicleParams.rcR;
ACdLift   = vehicleParams.ACdLift;
aeroBal   = vehicleParams.aeroBal;
azScalar  = vehicleParams.azScalar;

% aero downforce
front_aero = 0.5 .* rho .* ACdLift .* vx.^2 .* aeroBal;
rear_aero  = 0.5 .* rho .* ACdLift .* vx.^2 .* (1 - aeroBal);

% effective road-normal acceleration
az_road = g .* cos(theta) .* cos(phi) ...
        + vx .* r  .* sin(phi) ...
        + vx .* wy .* azScalar;

% longitudinal load-transfer acceleration (inertial + gravity along the slope)
long_transfer_accel = ax + g .* sin(theta);

% front/rear axle totals
Fz_front_model = lr .* (m .* az_road) ./ L ...
               - (m .* long_transfer_accel .* hcg) ./ L ...
               + front_aero;

Fz_rear_model  = lf .* (m .* az_road) ./ L ...
               + (m .* long_transfer_accel .* hcg) ./ L ...
               + rear_aero;

% lateral transfer gradients [N per g of lateral accel]
w_veh       = m * g;
cg2rollAxis = hcg - (rcF + (1 - vehicleParams.wDistF) * (rcR - rcF));
k_phi_f     = (wheelRateF * tF^2) / 2 + ARBf;
k_phi_r     = (wheelRateR * tR^2) / 2 + ARBr;

LAT_weightTransferGradient_f = (w_veh/tF) * ((cg2rollAxis * k_phi_f)/(k_phi_f + k_phi_r) + (lr * rcF / L));
LAT_weightTransferGradient_r = (w_veh/tR) * ((cg2rollAxis * k_phi_r)/(k_phi_f + k_phi_r) + (lf * rcR / L));


ay_model = ay_meas;

dFz_lat_f = LAT_weightTransferGradient_f .* (ay_model ./ g);
dFz_lat_r = LAT_weightTransferGradient_r .* (ay_model ./ g);

% per-tire loads
Fz_fl_model = Fz_front_model ./ 2 - dFz_lat_f +20 ;
Fz_fr_model = Fz_front_model ./ 2 + dFz_lat_f - 70;
Fz_rl_model = Fz_rear_model  ./ 2 - dFz_lat_r -100;
Fz_rr_model = Fz_rear_model  ./ 2 + dFz_lat_r + 120;

%% fig 0 - normal loads: measured vs dual-track model
figure('Name','Fig 0 - Normal Load: measured vs dual-track model');

ax0 = gobjects(4,1);
Fz_meas_all  = {Fz_fl, Fz_fr, Fz_rl, Fz_rr};
Fz_model_all = {Fz_fl_model, Fz_fr_model, Fz_rl_model, Fz_rr_model};
Fz_titles    = {'Front Left','Front Right','Rear Left','Rear Right'};

for iW = 1:4
    ax0(iW) = subplot(2,2,iW);
    plot(t, Fz_meas_all{iW}, 'LineWidth', 1);
    hold on;
    plot(t, Fz_model_all{iW}, 'LineWidth', 1.5);
    grid on;
    title(Fz_titles{iW});
    xlabel('Time [s]'); ylabel('F_z [N]');
    legend('measured','dual-track model','Location','best');
end

linkaxes(ax0, 'x');


%% engine model
rpm = data.engine_rpm;
throttle_raw = data.throttle_pct;
gear = data.current_gear;

vn = data.Properties.VariableNames;
hasBoost = all(ismember({'boost_aim_kpa','boost_pressure_kpa'}, vn));

if hasBoost
    boost_aim = data.boost_aim_kpa;
    boost_pressure = data.boost_pressure_kpa;
else
    boost_aim = nan(size(t));
    boost_pressure = nan(size(t));
    warning('slip_force_with_model:noBoost', 'No boost data; using est_drive_torque / Rw_r.');
end

diff_ratio = 3;
eff_diff   = 0.99;
gear_eff   = 0.91;
r_model    = 0.3;

gear_ratio = zeros(size(gear));
gear_ratio(gear == 2) = 1.8667;
gear_ratio(gear ~= 2) = 2.9167;
total_ratio = eff_diff * diff_ratio * gear_ratio * gear_eff;

map_boost_raw = readtable('engine_map_30psi.csv', 'VariableNamingRule','preserve');
map_boost_throttle_bp = [0.0, 0.3, 0.6, 1.0];
map_boost_rpm_bp = map_boost_raw{:, 1};
map_boost_torque = map_boost_raw{:, 2:end};
valid_rows_boost = isfinite(map_boost_rpm_bp);
map_boost_rpm_bp = map_boost_rpm_bp(valid_rows_boost);
map_boost_torque = map_boost_torque(valid_rows_boost, :);

map_noboost_raw = readtable('engine_map_no_boost.csv', 'VariableNamingRule','preserve');
map_noboost_throttle_bp = [0.0, 0.5, 1.0];
map_noboost_rpm_bp = map_noboost_raw{:, 1};
map_noboost_torque = map_noboost_raw{:, 2:end};
valid_rows_noboost = isfinite(map_noboost_rpm_bp);
map_noboost_rpm_bp = map_noboost_rpm_bp(valid_rows_noboost);
map_noboost_torque = map_noboost_torque(valid_rows_noboost, :);

throttle_norm = throttle_raw / 100;
rpm_clean = rpm;
throttle_clean = throttle_norm;
rpm_clean(~isfinite(rpm_clean)) = map_boost_rpm_bp(1);
throttle_clean(~isfinite(throttle_clean)) = 0;

rpm_clean_boost = min(max(rpm_clean, map_boost_rpm_bp(1)), map_boost_rpm_bp(end));
rpm_clean_noboost = min(max(rpm_clean, map_noboost_rpm_bp(1)), map_noboost_rpm_bp(end));
throttle_clean_boost = min(max(throttle_clean, map_boost_throttle_bp(1)), map_boost_throttle_bp(end));
throttle_clean_noboost = min(max(throttle_clean, map_noboost_throttle_bp(1)), map_noboost_throttle_bp(end));

T_map_boost = interp2(map_boost_throttle_bp, map_boost_rpm_bp, map_boost_torque, throttle_clean_boost, rpm_clean_boost, 'linear');
T_map_noboost = interp2(map_noboost_throttle_bp, map_noboost_rpm_bp, map_noboost_torque, throttle_clean_noboost, rpm_clean_noboost, 'linear');

if hasBoost
    alpha = zeros(size(t));
    boost_cmd_idx = boost_aim > 0 & isfinite(boost_aim) & isfinite(boost_pressure);
    alpha(boost_cmd_idx) = boost_pressure(boost_cmd_idx) ./ boost_aim(boost_cmd_idx);
    alpha(~isfinite(alpha)) = 0;
    alpha = min(max(alpha, 0), 1);
    T_map = (1 - alpha) .* T_map_noboost + alpha .* T_map_boost;
    T_map(throttle_norm <= 0.06) = 0;
    tau = 0.153;
    K = (T_map .* total_ratio) ./ r_model;
    F_tire_model = data.est_drive_torque_nm ./ Rw_r;
else
    if ~ismember('est_drive_torque_nm', vn)
        error('slip_force_with_model:noDriveTorque', 'No boost data and no est_drive_torque_nm column.');
    end
    F_tire_model = data.est_drive_torque_nm ./ Rw_r;
end

%% brake model
A_caliper = 4486.0;
mue_k = 0.4;
R_lever = 0.134;
breaking_force_calc_front = - (Pf * (A_caliper * mue_k * R_lever)/1000) ./ Rw_f;
breaking_force_calc_rear  = - (Pr * (A_caliper * mue_k * R_lever)/1000) ./ Rw_r;

%% Fx split measured
brakePressureTotal = Pf + Pr;
biasF = defaultFrontBrakeBias .* ones(size(Fx_total));
hasBrakePressure = brakePressureTotal > brakePressureMin_kPa;
biasF(hasBrakePressure) = Pf(hasBrakePressure) ./ brakePressureTotal(hasBrakePressure);
biasF = max(0, min(1, biasF));

driveMode = Fx_total >  Fx_deadband_N;
brakeMode = Fx_total < -Fx_deadband_N;
coastMode = ~driveMode & ~brakeMode;

Fxf = zeros(size(Fx_total));
Fxr = zeros(size(Fx_total));
Fxf(driveMode) = 0;
Fxr(driveMode) = Fx_total(driveMode);
Fxf(brakeMode) = biasF(brakeMode) .* Fx_total(brakeMode);
Fxr(brakeMode) = (1 - biasF(brakeMode)) .* Fx_total(brakeMode);
Fxf(coastMode) = 0;
Fxr(coastMode) = 0;

fx_fl = zeros(size(Fx_total));
fx_fr = zeros(size(Fx_total));
fx_rl = zeros(size(Fx_total));
fx_rr = zeros(size(Fx_total));

fx_rl(driveMode) = Fxr(driveMode)/2;
fx_rr(driveMode) = Fxr(driveMode)/2;
fx_fl(driveMode) = 0;
fx_fr(driveMode) = 0;

fx_rl(brakeMode) = Fxr(brakeMode)/2;
fx_rr(brakeMode) = Fxr(brakeMode)/2;
fx_fl(brakeMode) = Fxf(brakeMode)/2;
fx_fr(brakeMode) = Fxf(brakeMode)/2;

fx_rr(coastMode) = Fxr(coastMode);
fx_rl(coastMode) = Fxr(coastMode);
fx_fr(coastMode) = Fxf(coastMode);
fx_fl(coastMode) = Fxf(coastMode);

%% Fx split measured - by normal-load distribution
% Same axle forces (Fxf / Fxr), but shared between left/right tires by each
% tire's normal-load fraction instead of 50/50. Fxf/Fxr already encode the
% axle split per mode, so this holds across drive/brake/coast.
fx_fl_load = Fxf .* (Fz_fl ./ Fz_front);
fx_fr_load = Fxf .* (Fz_fr ./ Fz_front);
fx_rl_load = Fxr .* (Fz_rl ./ Fz_rear);
fx_rr_load = Fxr .* (Fz_rr ./ Fz_rear);

%% Fx split modeled
driveMode_m = isAccelerating;
brakeMode_m = hasBrakePressure & ~driveMode_m;
coastMode_m = ~driveMode_m & ~brakeMode_m;

Fxf_model = zeros(size(Fx_total));
Fxr_model = zeros(size(Fx_total));
Fxf_model(brakeMode_m) = 2 .* breaking_force_calc_front(brakeMode_m);
Fxr_model(brakeMode_m) = 2 .* breaking_force_calc_rear(brakeMode_m);
Fxf_model(driveMode_m) = 0;
Fxr_model(driveMode_m) = F_tire_model(driveMode_m);

fx_fl_model = zeros(size(Fx_total));
fx_fr_model = zeros(size(Fx_total));
fx_rl_model = zeros(size(Fx_total));
fx_rr_model = zeros(size(Fx_total));
fx_fl_model(brakeMode_m) = breaking_force_calc_front(brakeMode_m);
fx_fr_model(brakeMode_m) = breaking_force_calc_front(brakeMode_m);
fx_rl_model(brakeMode_m) = breaking_force_calc_rear(brakeMode_m);
fx_rr_model(brakeMode_m) = breaking_force_calc_rear(brakeMode_m);
fx_rl_model(driveMode_m) = F_tire_model(driveMode_m)/2;
fx_rr_model(driveMode_m) = F_tire_model(driveMode_m)/2;
fx_fl_model(driveMode_m) = 0;
fx_fr_model(driveMode_m) = 0;

Fxr_model_drive = zeros(size(Fx_total));
Fxr_model_brake = zeros(size(Fx_total));
Fxr_model_drive(driveMode_m) = F_tire_model(driveMode_m);
Fxr_model_brake(brakeMode_m) = 2 .* breaking_force_calc_rear(brakeMode_m);
Fxr_model_combined = Fxr_model_drive + Fxr_model_brake;

%% wheel speeds
Vw_fl = movmean(data.fl_speed_kmh, mm) ./ 3.61 - 0.1;
Vw_fr = movmean(data.fr_speed_kmh, mm) ./ 3.61 - 0.1;
Vw_rl = movmean(data.rl_speed_kmh, mm) ./ 3.61 - 0.1;
Vw_rr = movmean(data.rr_speed_kmh, mm) ./ 3.61 - 0.1;
Vw_front = 0.5 .* (Vw_fl + Vw_fr);
Vw_rear  = 0.5 .* (Vw_rl + Vw_rr);

ft = front_track;
rt = rear_track;
Vx_fl_c = vx - r .* (ft/2);
Vx_fr_c = vx + r .* (ft/2);
Vx_rl_c = vx - r .* (rt/2);
Vx_rr_c = vx + r .* (rt/2);
Vy_front_c = vy + r .* lf;
Vy_rear_c  = vy - r .* lr;

Vx_tire_fl =  Vx_fl_c .* cos(delta) + Vy_front_c .* sin(delta);
Vx_tire_fr =  Vx_fr_c .* cos(delta) + Vy_front_c .* sin(delta);
Vx_tire_rl =  Vx_rl_c;
Vx_tire_rr =  Vx_rr_c;
Vy_tire_fl = -Vx_fl_c .* sin(delta) + Vy_front_c .* cos(delta);
Vy_tire_fr = -Vx_fr_c .* sin(delta) + Vy_front_c .* cos(delta);
Vy_tire_rl =  Vy_rear_c;
Vy_tire_rr =  Vy_rear_c;

mask = abs(vx) < vx_min_slip_ratio;
Vx_tire_fl(mask) = 0;  Vy_tire_fl(mask) = 0;
Vx_tire_fr(mask) = 0;  Vy_tire_fr(mask) = 0;
Vx_tire_rl(mask) = 0;  Vy_tire_rl(mask) = 0;
Vx_tire_rr(mask) = 0;  Vy_tire_rr(mask) = 0;

%% slip ratios
slip_ratio_x_fl = (Vw_fl - Vx_tire_fl) ./ Vw_fl;
slip_ratio_x_fr = (Vw_fr - Vx_tire_fr) ./ Vw_fr;
slip_ratio_x_rl = (Vw_rl - Vx_tire_rl) ./ Vw_rl;
slip_ratio_x_rr = (Vw_rr - Vx_tire_rr) ./ Vw_rr;

Vx_front_axle = vx;
Vx_rear_axle  = vx;
slip_ratio_f = (Vw_front - Vx_front_axle) ./ Vw_front;
slip_ratio_r = (Vw_rear  - Vx_rear_axle)  ./ Vw_rear;

%% masks
validFront = isfinite(alpha_f_deg) & isfinite(Fyf) & isfinite(slip_ratio_f) & isfinite(ds) & abs(vx) > vx_min_slip_angle & abs(alpha_f_deg) < 20 & abs(slip_ratio_f) < 1.0 & accelKeep;
validRear = isfinite(alpha_r_deg) & isfinite(Fyr) & isfinite(slip_ratio_r) & isfinite(ds) & abs(vx) > vx_min_slip_angle & abs(alpha_r_deg) < 20 & abs(slip_ratio_r) < 1.0 & accelKeep;

validTire = @(sr) isfinite(sr) & isfinite(ds) & abs(vx) > vx_min_slip_angle & abs(sr) < 1.0 & accelKeep;
validFL = validTire(slip_ratio_x_fl);
validFR = validTire(slip_ratio_x_fr);
validRL = validTire(slip_ratio_x_rl);
validRR = validTire(slip_ratio_x_rr);

%% corner boxes + highlight mask
% Format: name, xmin, xmax, ymin, ymax
cornerBoxes = {
    "C1",             -200,  -140,   -400,  -200;
    "C2",             -220,   -50,   -540,  -400;
    "C3",             -140,    50,   -400,  -250;
    "C4",               50,   200,   -550,  -250;
    "C5",               50,   380,   -850,  -550;
    "C6",              380,   600,   -850,  -450;
    "C7-8_corkscrew",  500,   610,   -450,  -160;
    "C9",              380,   610,   -160,   -20;
    "C10",             150,   380,   -125,    20;
    "C11",               0,   200,     20,   160;
};

numCorners  = size(cornerBoxes,1);
cornerNames = string(cornerBoxes(:,1));

% Per-corner geometric membership mask (one column per corner).
posValid    = isfinite(x_pos) & isfinite(y_pos);
cornerMasks = false(numel(x_pos), numCorners);
for iC = 1:numCorners
    xmin = cornerBoxes{iC,2};  xmax = cornerBoxes{iC,3};
    ymin = cornerBoxes{iC,4};  ymax = cornerBoxes{iC,5};
    cornerMasks(:,iC) = posValid & ...
        x_pos >= xmin & x_pos <= xmax & y_pos >= ymin & y_pos <= ymax;
end

% Highlight mask: samples in the selected corner (empty if highlight is off
% or the name is not found). Used by scatterHi / plotPaper to draw red points.
cornerHi = false(numel(x_pos), 1);
if highlightOn
    iSel = find(cornerNames == highlightCorner, 1);
    if isempty(iSel)
        warning('slip_force_with_model:badCorner', ...
                'highlightCorner "%s" not found in cornerBoxes; nothing highlighted.', highlightCorner);
    else
        cornerHi = cornerMasks(:, iSel);
    end
end

%% fig 1 - Fy vs slip angle
figure('Name','Fig 1 - Slip Angle vs Fy (per axle)');

subplot(1,2,1)
scatterHi(alpha_f_deg(validFront), Fyf(validFront), tAbs(validFront), cornerHi(validFront));
grid on;
xlabel('Front slip angle \alpha_f [deg]');
ylabel('Front lateral force F_{y,f} [N]');
cb = colorbar; ylabel(cb, 'Time [s]');
xline(0,'k--'); yline(0,'k--');

subplot(1,2,2)
scatterHi(alpha_r_deg(validRear), Fyr(validRear), tAbs(validRear), cornerHi(validRear));
grid on;
xlabel('Rear slip angle \alpha_r [deg]');
ylabel('Rear lateral force F_{y,r} [N]');
cb = colorbar; ylabel(cb, 'Time [s]');
xline(0,'k--'); yline(0,'k--');

%% fig 2 - Fx vs slip ratio (axle, measured)
figure('Name','Fig 2 - Slip Ratio vs Fx (per axle, measured)');

subplot(1,2,1)
scatterHi(slip_ratio_f(validFront), Fxf(validFront), tAbs(validFront), cornerHi(validFront));
grid on;
xlabel('Front slip ratio \kappa_f [-]');
ylabel('Front longitudinal force F_{x,f} [N]');
cb = colorbar; ylabel(cb, 'Time [s]');
xline(0,'k--'); yline(0,'k--');

subplot(1,2,2)
scatterHi(slip_ratio_r(validRear), Fxr(validRear), tAbs(validRear), cornerHi(validRear));
grid on;
xlabel('Rear slip ratio \kappa_r [-]');
ylabel('Rear longitudinal force F_{x,r} [N]');
cb = colorbar; ylabel(cb, 'Time [s]');
xline(0,'k--'); yline(0,'k--');

%% fig 3 - Fx vs slip ratio (axle, modeled)
if plot_modeled
    figure('Name','Fig 3 - Slip Ratio vs Fx (per axle, modeled)');
    
    subplot(1,2,1)
    scatterHi(slip_ratio_f(validFront), Fxf_model(validFront), tAbs(validFront), cornerHi(validFront));
    grid on;
    xlabel('Front slip ratio \kappa_f [-]');
    ylabel('Front longitudinal force F_{x,f} [N]');
    cb = colorbar; ylabel(cb, 'Time [s]');
    xline(0,'k--'); yline(0,'k--');
    
    subplot(1,2,2)
    scatterHi(slip_ratio_r(validRear), Fxr_model(validRear), tAbs(validRear), cornerHi(validRear));
    grid on;
    xlabel('Rear slip ratio \kappa_r [-]');
    ylabel('Rear longitudinal force F_{x,r} [N]');
    cb = colorbar; ylabel(cb, 'Time [s]');
    xline(0,'k--'); yline(0,'k--');
end

%% fig 4 - Fx vs slip ratio (tire, measured)
figure('Name','Fig 4 - Slip Ratio vs Fx (per tire, measured)');

subplot(2,2,1)
scatterHi(slip_ratio_x_fl(validFL), fx_fl(validFL), tAbs(validFL), cornerHi(validFL));
grid on; xlabel('\kappa_{fl} [-]'); ylabel('F_{x,fl} [N]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,2)
scatterHi(slip_ratio_x_fr(validFR), fx_fr(validFR), tAbs(validFR), cornerHi(validFR));
grid on; xlabel('\kappa_{fr} [-]'); ylabel('F_{x,fr} [N]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,3)
scatterHi(slip_ratio_x_rl(validRL), fx_rl(validRL), tAbs(validRL), cornerHi(validRL));
grid on; xlabel('\kappa_{rl} [-]'); ylabel('F_{x,rl} [N]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,4)
scatterHi(slip_ratio_x_rr(validRR), fx_rr(validRR), tAbs(validRR), cornerHi(validRR));
grid on; xlabel('\kappa_{rr} [-]'); ylabel('F_{x,rr} [N]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

%% fig 5 - Fx/Fz vs slip ratio (per tire, measured)
figure('Name','Fig 5 - Slip Ratio vs Fx/Fz (per tire, measured)');

subplot(2,2,1)
scatterHi(slip_ratio_x_fl(validFL), fx_fl(validFL)./Fz_fl(validFL), tAbs(validFL), cornerHi(validFL));
grid on; xlabel('\kappa_{fl} [-]'); ylabel('F_{x,fl}/F_{z,fl} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,2)
scatterHi(slip_ratio_x_fr(validFR), fx_fr(validFR)./Fz_fr(validFR), tAbs(validFR), cornerHi(validFR));
grid on; xlabel('\kappa_{fr} [-]'); ylabel('F_{x,fr}/F_{z,fr} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,3)
scatterHi(slip_ratio_x_rl(validRL), fx_rl(validRL)./Fz_rl(validRL), tAbs(validRL), cornerHi(validRL));
grid on; xlabel('\kappa_{rl} [-]'); ylabel('F_{x,rl}/F_{z,rl} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,4)
scatterHi(slip_ratio_x_rr(validRR), fx_rr(validRR)./Fz_rr(validRR), tAbs(validRR), cornerHi(validRR));
grid on; xlabel('\kappa_{rr} [-]'); ylabel('F_{x,rr}/F_{z,rr} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');


%% fig 6 - Fx/Fz vs slip ratio (per tire, measured, load-distribution split)
figure('Name','Fig 6 - Slip Ratio vs Fx/Fz (per tire, measured, load-distribution split)');

subplot(2,2,1)
scatterHi(slip_ratio_x_fl(validFL), fx_fl_load(validFL)./Fz_fl(validFL), tAbs(validFL), cornerHi(validFL));
grid on; xlabel('\kappa_{fl} [-]'); ylabel('F_{x,fl}/F_{z,fl} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,2)
scatterHi(slip_ratio_x_fr(validFR), fx_fr_load(validFR)./Fz_fr(validFR), tAbs(validFR), cornerHi(validFR));
grid on; xlabel('\kappa_{fr} [-]'); ylabel('F_{x,fr}/F_{z,fr} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,3)
scatterHi(slip_ratio_x_rl(validRL), fx_rl_load(validRL)./Fz_rl(validRL), tAbs(validRL), cornerHi(validRL));
grid on; xlabel('\kappa_{rl} [-]'); ylabel('F_{x,rl}/F_{z,rl} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,4)
scatterHi(slip_ratio_x_rr(validRR), fx_rr_load(validRR)./Fz_rr(validRR), tAbs(validRR), cornerHi(validRR));
grid on; xlabel('\kappa_{rr} [-]'); ylabel('F_{x,rr}/F_{z,rr} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');


%% fig 7 - Fx/Fz vs Fy/Fz (per tire, measured, even Fx split)
% Per-tire lateral force: devide even across axle
Fy_fl = Fyf ./2;
Fy_fr = Fyf ./2;
Fy_rl = Fyr ./2;
Fy_rr = Fyr ./2;

figure('Name','Fig 7 - Fx/Fz vs Fy/Fz (per tire, measured, even Fx split)');

subplot(2,2,1)
scatterHi(fx_fl(validFL)./Fz_fl(validFL), Fy_fl(validFL)./Fz_fl(validFL), tAbs(validFL), cornerHi(validFL));
grid on; axis equal; xlabel('F_{x,fl}/F_{z,fl} [-]'); ylabel('F_{y,fl}/F_{z,fl} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,2)
scatterHi(fx_fr(validFR)./Fz_fr(validFR), Fy_fr(validFR)./Fz_fr(validFR), tAbs(validFR), cornerHi(validFR));
grid on; axis equal; xlabel('F_{x,fr}/F_{z,fr} [-]'); ylabel('F_{y,fr}/F_{z,fr} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,3)
scatterHi(fx_rl(validRL)./Fz_rl(validRL), Fy_rl(validRL)./Fz_rl(validRL), tAbs(validRL), cornerHi(validRL));
grid on; axis equal; xlabel('F_{x,rl}/F_{z,rl} [-]'); ylabel('F_{y,rl}/F_{z,rl} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,4)
scatterHi(fx_rr(validRR)./Fz_rr(validRR), Fy_rr(validRR)./Fz_rr(validRR), tAbs(validRR), cornerHi(validRR));
grid on; axis equal; xlabel('F_{x,rr}/F_{z,rr} [-]'); ylabel('F_{y,rr}/F_{z,rr} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

%% fig 8 - Fx/Fz vs Fy/Fz (per tire, measured, load-distribution Fx split)
figure('Name','Fig 8 - Fx/Fz vs Fy/Fz (per tire, measured, load-distribution Fx split)');

subplot(2,2,1)
scatterHi(fx_fl_load(validFL)./Fz_fl(validFL), Fy_fl(validFL)./Fz_fl(validFL), tAbs(validFL), cornerHi(validFL));
grid on; axis equal; xlabel('F_{x,fl}/F_{z,fl} [-]'); ylabel('F_{y,fl}/F_{z,fl} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,2)
scatterHi(fx_fr_load(validFR)./Fz_fr(validFR), Fy_fr(validFR)./Fz_fr(validFR), tAbs(validFR), cornerHi(validFR));
grid on; axis equal; xlabel('F_{x,fr}/F_{z,fr} [-]'); ylabel('F_{y,fr}/F_{z,fr} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,3)
scatterHi(fx_rl_load(validRL)./Fz_rl(validRL), Fy_rl(validRL)./Fz_rl(validRL), tAbs(validRL), cornerHi(validRL));
grid on; axis equal; xlabel('F_{x,rl}/F_{z,rl} [-]'); ylabel('F_{y,rl}/F_{z,rl} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,4)
scatterHi(fx_rr_load(validRR)./Fz_rr(validRR), Fy_rr(validRR)./Fz_rr(validRR), tAbs(validRR), cornerHi(validRR));
grid on; axis equal; xlabel('F_{x,rr}/F_{z,rr} [-]'); ylabel('F_{y,rr}/F_{z,rr} [-]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

%% fig 8b - Fx/Fz vs Fy/Fz (per tire, dual-track model Fz)
% Same as fig 8, but every normal load comes from the dual-track model instead
% of the strain gages: the L/R load-distribution split of Fxf/Fxr and Fyf/Fyr
% uses model Fz, and the normalization divides by model Fz. Fxf/Fxr/Fyf/Fyr
% themselves are unchanged - only the load distribution and denominator move.
% Fz_fl_model + Fz_fr_model == Fz_front_model by construction, so the axle
% totals are used directly as the split denominators.
fx_fl_load_mdl = Fxf .* (Fz_fl_model ./ Fz_front_model);
fx_fr_load_mdl = Fxf .* (Fz_fr_model ./ Fz_front_model);
fx_rl_load_mdl = Fxr .* (Fz_rl_model ./ Fz_rear_model);
fx_rr_load_mdl = Fxr .* (Fz_rr_model ./ Fz_rear_model);

Fy_fl_mdl = Fyf .* (Fz_fl_model ./ Fz_front_model);
Fy_fr_mdl = Fyf .* (Fz_fr_model ./ Fz_front_model);
Fy_rl_mdl = Fyr .* (Fz_rl_model ./ Fz_rear_model);
Fy_rr_mdl = Fyr .* (Fz_rr_model ./ Fz_rear_model);

% Same masks as fig 8, plus a positive-load guard: the model is unclamped, so a
% corner that unloads through zero would otherwise blow up the F/Fz ratios.
validFL_mdl = validFL & Fz_fl_model > 0;
validFR_mdl = validFR & Fz_fr_model > 0;
validRL_mdl = validRL & Fz_rl_model > 0;
validRR_mdl = validRR & Fz_rr_model > 0;

figure('Name','Fig 8b - Fx/Fz vs Fy/Fz (per tire, model Fz, load-distribution Fx split)');

subplot(2,2,1)
scatterHi(fx_fl_load_mdl(validFL_mdl)./Fz_fl_model(validFL_mdl), Fy_fl_mdl(validFL_mdl)./Fz_fl_model(validFL_mdl), tAbs(validFL_mdl), cornerHi(validFL_mdl));
grid on; axis equal; xlim([-3 3]); ylim([-3 3]);
xlabel('F_{x,fl}/F_{z,fl} [-]'); ylabel('F_{y,fl}/F_{z,fl} [-]');
title('Front Left (model F_z)');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,2)
scatterHi(fx_fr_load_mdl(validFR_mdl)./Fz_fr_model(validFR_mdl), Fy_fr_mdl(validFR_mdl)./Fz_fr_model(validFR_mdl), tAbs(validFR_mdl), cornerHi(validFR_mdl));
grid on; axis equal; xlim([-3 3]); ylim([-3 3]);
xlabel('F_{x,fr}/F_{z,fr} [-]'); ylabel('F_{y,fr}/F_{z,fr} [-]');
title('Front Right (model F_z)');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,3)
scatterHi(fx_rl_load_mdl(validRL_mdl)./Fz_rl_model(validRL_mdl), Fy_rl_mdl(validRL_mdl)./Fz_rl_model(validRL_mdl), tAbs(validRL_mdl), cornerHi(validRL_mdl));
grid on; axis equal; xlim([-3 3]); ylim([-3 3]);
xlabel('F_{x,rl}/F_{z,rl} [-]'); ylabel('F_{y,rl}/F_{z,rl} [-]');
title('Rear Left (model F_z)');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(2,2,4)
scatterHi(fx_rr_load_mdl(validRR_mdl)./Fz_rr_model(validRR_mdl), Fy_rr_mdl(validRR_mdl)./Fz_rr_model(validRR_mdl), tAbs(validRR_mdl), cornerHi(validRR_mdl));
grid on; axis equal; xlim([-3 3]); ylim([-3 3]);
xlabel('F_{x,rr}/F_{z,rr} [-]'); ylabel('F_{y,rr}/F_{z,rr} [-]');
title('Rear Right (model F_z)');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

%% fig 9 - Fx vs slip ratio (tire, modeled)

if plot_modeled
    figure('Name','Fig 9 - Slip Ratio vs Fx (per tire, modeled)');
    
    subplot(2,2,1)
    scatterHi(slip_ratio_x_fl(validFL), fx_fl_model(validFL), tAbs(validFL), cornerHi(validFL));
    grid on; xlabel('\kappa_{fl} [-]'); ylabel('F_{x,fl} [N]');
    cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');
    
    subplot(2,2,2)
    scatterHi(slip_ratio_x_fr(validFR), fx_fr_model(validFR), tAbs(validFR), cornerHi(validFR));
    grid on; xlabel('\kappa_{fr} [-]'); ylabel('F_{x,fr} [N]');
    cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');
    
    subplot(2,2,3)
    scatterHi(slip_ratio_x_rl(validRL), fx_rl_model(validRL), tAbs(validRL), cornerHi(validRL));
    grid on; xlabel('\kappa_{rl} [-]'); ylabel('F_{x,rl} [N]');
    cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');
    
    subplot(2,2,4)
    scatterHi(slip_ratio_x_rr(validRR), fx_rr_model(validRR), tAbs(validRR), cornerHi(validRR));
    grid on; xlabel('\kappa_{rr} [-]'); ylabel('F_{x,rr} [N]');
    cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');
end

%% fig 10 - Fx vs Fy (axle, measured)
figure('Name','Fig 10 - Fx vs Fy (per axle, measured)');

subplot(1,2,1)
scatterHi(Fxf(validFront), Fyf(validFront), tAbs(validFront), cornerHi(validFront));
grid on; axis equal;
xlabel('Front F_{x,f} [N]'); ylabel('Front F_{y,f} [N]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

subplot(1,2,2)
scatterHi(Fxr(validRear), Fyr(validRear), tAbs(validRear), cornerHi(validRear));
grid on; axis equal;
xlabel('Rear F_{x,r} [N]'); ylabel('Rear F_{y,r} [N]');
cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');

%% fig 11 - Fx vs Fy (axle, modeled)

if plot_modeled
    figure('Name','Fig 11 - Fx vs Fy (per axle, modeled)');
    
    subplot(1,2,1)
    scatterHi(Fxf_model(validFront), Fyf(validFront), tAbs(validFront), cornerHi(validFront));
    grid on; axis equal;
    xlabel('Front F_{x,f} [N]'); ylabel('Front F_{y,f} [N]');
    cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');
    
    subplot(1,2,2)
    scatterHi(Fxr_model(validRear), Fyr(validRear), tAbs(validRear), cornerHi(validRear));
    grid on; axis equal;
    xlabel('Rear F_{x,r} [N]'); ylabel('Rear F_{y,r} [N]');
    cb = colorbar; ylabel(cb,'Time [s]'); xline(0,'k--'); yline(0,'k--');
end
%% combined slip
Vw_min_paper = 1;
Fz_min_paper = 0;

den_fl = Vw_fl;  den_fl(abs(den_fl) < Vw_min_paper) = NaN;
den_fr = Vw_fr;  den_fr(abs(den_fr) < Vw_min_paper) = NaN;
den_rl = Vw_rl;  den_rl(abs(den_rl) < Vw_min_paper) = NaN;
den_rr = Vw_rr;  den_rr(abs(den_rr) < Vw_min_paper) = NaN;

S_fl = hypot((Vx_tire_fl - Vw_fl) ./ den_fl, Vy_tire_fl ./ den_fl);
S_fr = hypot((Vx_tire_fr - Vw_fr) ./ den_fr, Vy_tire_fr ./ den_fr);
S_rl = hypot((Vx_tire_rl - Vw_rl) ./ den_rl, Vy_tire_rl ./ den_rl);
S_rr = hypot((Vx_tire_rr - Vw_rr) ./ den_rr, Vy_tire_rr ./ den_rr);

%% combined load
Fz_fl_eff = Fz_fl ;
Fz_fr_eff = Fz_fr ;
Fz_rl_eff = Fz_rl ;
Fz_rr_eff = Fz_rr ;

% Per-tire lateral forces (Fy_fl ... Fy_rr) are computed above, before fig 7.

%% fig 12 - poop paper method 
figure('Name','Fig 12 - Paper Method (measured Fx)');

subplot(2,2,1)
plotPaper(S_fl, hypot(fx_fl, Fy_fl), Fz_fl_eff, tAbs, vx, Fz_min_paper, vx_min_slip_angle, cornerHi);
subplot(2,2,2)
plotPaper(S_fr, hypot(fx_fr, Fy_fr), Fz_fr_eff, tAbs, vx, Fz_min_paper, vx_min_slip_angle, cornerHi);
subplot(2,2,3)
plotPaper(S_rl, hypot(fx_rl, Fy_rl), Fz_rl_eff, tAbs, vx, Fz_min_paper, vx_min_slip_angle, cornerHi);
subplot(2,2,4)
plotPaper(S_rr, hypot(fx_rr, Fy_rr), Fz_rr_eff, tAbs, vx, Fz_min_paper, vx_min_slip_angle, cornerHi);

%% fig 13 - poop paper method 
if plot_modeled
    figure('Name','Fig 13 - Paper Method (modeled Fx)');
    
    subplot(2,2,1)
    plotPaper(S_fl, hypot(fx_fl_model, Fy_fl), Fz_fl_eff, tAbs, vx, Fz_min_paper, vx_min_slip_angle, cornerHi);
    subplot(2,2,2)
    plotPaper(S_fr, hypot(fx_fr_model, Fy_fr), Fz_fr_eff, tAbs, vx, Fz_min_paper, vx_min_slip_angle, cornerHi);
    subplot(2,2,3)
    plotPaper(S_rl, hypot(fx_rl_model, Fy_rl), Fz_rl_eff, tAbs, vx, Fz_min_paper, vx_min_slip_angle, cornerHi);
    subplot(2,2,4)
    plotPaper(S_rr, hypot(fx_rr_model, Fy_rr), Fz_rr_eff, tAbs, vx, Fz_min_paper, vx_min_slip_angle, cornerHi);
end

%% fig 14 - rear Fx measured vs modeled
figure('Name','Fig 14 - Rear Axle Fx: measured vs modeled');

ax14 = gobjects(4,1);

ax14(1) = subplot(4,1,1);
plot(t, Fxr, 'b', 'LineWidth', 1.5, 'DisplayName', 'F_{x,r} measured');
hold on;
plot(t, Fxr_model_combined, 'r', 'LineWidth', 1.5, 'DisplayName', 'F_{x,r} modeled (throttle + brake)');
plot(t, Fxr_model_drive, 'g--', 'LineWidth', 1.0, 'DisplayName', 'modeled throttle (engine map)');
plot(t, Fxr_model_brake, 'm--', 'LineWidth', 1.0, 'DisplayName', 'modeled brake (caliper)');
grid on;
xlabel('Time [s]');
ylabel('F_{x,r} [N]');
legend('Location', 'best');
yline(0, 'k--', 'HandleVisibility', 'off');

ax14(2) = subplot(4,1,2);
plot(t, Vx_tire_rl, 'b', 'LineWidth', 1.5, 'DisplayName', 'V_{x} rear-left tire');
hold on;
plot(t, Vw_rl, 'r', 'LineWidth', 1.5, 'DisplayName', 'wheel speed rear-left');
grid on;
xlabel('Time [s]');
ylabel('Speed [m/s]');
legend('Location', 'best');

ax14(3) = subplot(4,1,3);
plot(t, slip_ratio_x_rl, 'k', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]');
ylabel('slip ratio rear left');

ax14(4) = subplot(4,1,4);
plot(t, throttle_pct);
grid on;
xlabel('Time [s]');
ylabel('throttle');

linkaxes(ax14, 'x');

%% fig 15 - Interactive rear-tire combined loading (Fy/Fz & Fx/Fz)
% Four rear-tire scatter plots that share ONE sample set. Click a point on any
% subplot and the sample with the same timestamp is marked red on all four, so
% you can compare combined loading across the rear tires at a chosen instant.

% Per-rear-tire lateral slip angle (from each tire's own velocity vector) so
% the left/right plots differ - the axle-level alpha_r would be identical for
% both sides.
alpha_rl_deg = rad2deg(-atan2(Vy_tire_rl, Vx_tire_rl));
alpha_rr_deg = rad2deg(-atan2(Vy_tire_rr, Vx_tire_rr));

% Per-tire normalized signals.
%   Fx: even (Fxr/2) split, so Fx/Fz differs per tire (each tire's own load).
%   Fy: load-distribution split, so Fy/Fz reduces to the axle value Fyr/Fz_rear
%       (same for both tires) - kept this way intentionally.
muY_rl = Fy_rl ./ Fz_rl;
muY_rr = Fy_rr ./ Fz_rr;
muX_rl = fx_rl ./ Fz_rl;
muX_rr = fx_rr ./ Fz_rr;

% One shared validity mask so a given sample index is plotted on all four axes
% (required for the timestamp-linked cross-highlighting to line up).
maskRear = isfinite(alpha_rl_deg) & isfinite(alpha_rr_deg) & isfinite(Fyr) & ...
           isfinite(slip_ratio_x_rl) & isfinite(slip_ratio_x_rr) & ...
           Fz_rl > 0 & Fz_rr > 0 & abs(vx) > vx_min_slip_angle & ...
           abs(alpha_rl_deg) < 20 & abs(alpha_rr_deg) < 20 & ...
           abs(slip_ratio_x_rl) < 1 & abs(slip_ratio_x_rr) < 1 & accelKeep;
idxRear = find(maskRear);

% Per-subplot x / y data, restricted to the shared sample set.
Xr = { alpha_rl_deg(idxRear), alpha_rr_deg(idxRear), ...
       slip_ratio_x_rl(idxRear), slip_ratio_x_rr(idxRear) };
Yr = { muY_rl(idxRear), muY_rr(idxRear), muX_rl(idxRear), muX_rr(idxRear) };
xlabels = {'Rear-left slip angle \alpha_{rl} [deg]', 'Rear-right slip angle \alpha_{rr} [deg]', ...
           'Rear-left slip ratio \kappa_{rl} [-]',   'Rear-right slip ratio \kappa_{rr} [-]'};
ylabels = {'F_{y,rl}/F_{z,rl} [-]', 'F_{y,rr}/F_{z,rr} [-]', ...
           'F_{x,rl}/F_{z,rl} [-]', 'F_{x,rr}/F_{z,rr} [-]'};
titles  = {'RL: F_y/F_z vs slip angle', 'RR: F_y/F_z vs slip angle', ...
           'RL: F_x/F_z vs slip ratio', 'RR: F_x/F_z vs slip ratio'};

figRear = figure('Name','Fig 15 - Rear Tire Combined Loading (interactive)');
cR  = tAbs(idxRear);          % color = timestamp
axR = gobjects(4,1);
hlR = gobjects(4,1);          % red linked-selection markers

for a = 1:4
    axR(a) = subplot(2,2,a);
    sc = scatter(Xr{a}, Yr{a}, 18, cR, 'filled');
    sc.HitTest = 'off';       % clicks fall through to the axes
    hold on;
    hlR(a) = plot(nan, nan, 'o', 'MarkerSize', 12, 'MarkerEdgeColor', 'k', ...
                  'MarkerFaceColor', 'r', 'LineWidth', 1.5, 'HitTest', 'off');
    grid on;
    xlabel(xlabels{a}); ylabel(ylabels{a}); title(titles{a});
    cb = colorbar; ylabel(cb, 'Time [s]');
    xline(0,'k--'); yline(0,'k--');
    axR(a).ButtonDownFcn = @rearSelectClick;
end

sgt = sgtitle('Rear Tire Combined Loading - click any point to link the same timestamp across all four');

% Stash what the click callback needs.
S = struct();
S.ax = axR;  S.hl = hlR;  S.X = Xr;  S.Y = Yr;  S.t = tAbs(idxRear);  S.sgt = sgt;
guidata(figRear, S);

%% functions
function rearSelectClick(src, ~)
% Click handler for fig 15: find the nearest plotted point in the clicked
% axes, then mark that same sample index (same timestamp) on all four axes.
    figH = ancestor(src, 'figure');
    S = guidata(figH);
    a = find(S.ax == src, 1);
    if isempty(a); return; end

    cp = get(src, 'CurrentPoint');
    xc = cp(1,1);  yc = cp(1,2);

    % Nearest point in normalized axis units (x and y have different scales).
    xr = diff(xlim(src));  if xr == 0, xr = 1; end
    yr = diff(ylim(src));  if yr == 0, yr = 1; end
    d = ((S.X{a} - xc)./xr).^2 + ((S.Y{a} - yc)./yr).^2;
    [~, k] = min(d);
    if isempty(k); return; end

    for b = 1:4
        set(S.hl(b), 'XData', S.X{b}(k), 'YData', S.Y{b}(k));
    end
    set(S.sgt, 'String', sprintf(['Rear Tire Combined Loading - selected t = ' ...
        '%.2f s (red on all four)'], S.t(k)));
end

function scatterHi(x, y, c, hi)
% Scatter x vs y colored by c (all three already restricted to the plot's
% validity mask). hi is the same-length logical selecting highlighted-corner
% samples; those are re-drawn in red on top.
    scatter(x, y, 18, c, 'filled');
    if any(hi)
        hold on;
        scatter(x(hi), y(hi), 22, 'r', 'filled');
    end
end

function plotPaper(S, F, Fz_eff, tv, vx, Fz_min, vx_min, hi)
    Fn = F ./ Fz_eff;   % only used to gate non-physical mu values
    v = isfinite(S) & isfinite(Fn) & Fz_eff > Fz_min & abs(vx) > vx_min & S >= 0 & S < 0.6 & Fn >= 0 & Fn < 2.0;
    scatter(S(v), F(v), 12, tv(v), 'filled');
    grid on;
    hiv = v & hi;
    if any(hiv)
        hold on;
        scatter(S(hiv), F(hiv), 16, 'r', 'filled');
    end
    xlabel('Total slip S [-]');
    ylabel('|F| [N]');
    cb = colorbar; ylabel(cb, 'Time [s]');
end
