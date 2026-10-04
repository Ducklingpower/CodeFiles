clc
close all
clear
% vehicle model - bicycle and dual track, the MATLAB reference for the on-vehicle vehicle_model package
% every equation, parameter, gate and flag the package uses is here, in the order the node runs it:
%   input conditioning -> shared stateless functions -> BicycleModel step -> DualTrackModel step
% the two models share no state and never read each other's outputs
% after the models: comparisons that are NOT in the package (references, older methods), the save for the research
% scripts, then the plots
% block diagrams, message fields and the build plan: observer_block_diagrams.html, README.md section 2a

%% settings

dataFile      = "/home/elijah/PurdueRacing/bags/lagoona/comp2/compition_bags/2026-09-03_121638_merged.csv";
engineMapFile = "/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/control/acceleration_interface/config/engine_map_30psi.csv";
ackermannFile = "/home/elijah/code/CodeFiles/Research/VD/yaw_moment/ackerman_sweep_50.xlsx";   % road_deg, left_deg, right_deg

timeWindow = [0 inf];   % [s] from start of recording

% Laguna Seca, fastest lap tab: lap timed at the C11 reference point, corners by position (odom x, y in m)
lapRef    = [100 144];
turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];

saveFitData = false;    % write fitDataFile for tire_fit.m, tire_fz_plots.m, debug scripts, run with timeWindow = [0 Inf]
fitDataFile = "/home/elijah/code/CodeFiles/Research/VD/Vehicle_modeling/tire_fit_data.mat";

%% load file

data  = readtable(dataFile);
t_all = data.time_s - data.time_s(1);
Ts    = median(diff(t_all));   % sample period (s)

% engine map: rows rpm, columns throttle fraction from the header (acceleration_interface engine_map_30psi.csv)
mapLines    = readlines(engineMapFile);
mapThrottle = str2double(split(mapLines(1), ","))';
mapThrottle = mapThrottle(2:end);
engineMap   = readmatrix(engineMapFile, "NumHeaderLines", 1);

engineTorque = griddedInterpolant({engineMap(:,1), mapThrottle}, engineMap(:,2:end), "linear", "nearest");

% Ackermann lookup table: road wheel angle (deg) -> left, right road wheel angle (deg)
ackLut = readmatrix(ackermannFile);

%% vehicle parameters (the package params.yaml)

% filters
vehicleParams.fc         = 3;       % (Hz) first order Tustin low pass, every input
vehicleParams.fcObsModel = 0.3;     % (Hz) load model inputs (vx, vy, yaw rate, a_x, roll, pitch)
vehicleParams.fcObsGage  = 0.5;     % (Hz) strain gages, and the load model copy compared with them

% gates
vehicleParams.vxMin        = 4;     % (m/s) kinematic slip angles NaN below this
vehicleParams.vxMinRatio   = 1;     % (m/s) slip ratios and kappa NaN below this (dualtrack yaml vx_min_ratio)
vehicleParams.vwMin        = 1;     % (m/s) slip ratio denominator floor (dualtrack yaml vw_min)
vehicleParams.slipRatioMax = 1;     % slip ratios clamped to +/- this (dualtrack yaml slip_ratio_max)
vehicleParams.kappaLock    = -0.5;  % kappa below this is a locked wheel
vehicleParams.fzLift       = 300;   % (N) observed load below this is a lifted tire (debug)

% chassis
vehicleParams.m           = 815;            % mass (kg)
vehicleParams.wheelbase   = 2.9718;         % (m)
vehicleParams.w_dist_f    = 0.42;           % front static weight share (-), lf = 0.58 L, lr = 0.42 L (URDF base_link = CG)
vehicleParams.t_f         = 1.638762;       % front track (m)
vehicleParams.t_r         = 1.5239686;      % rear track (m)
vehicleParams.cg_z        = 0.35;           % CG height (m) - MEASURE THIS
vehicleParams.rc_f        = 0.1202436;      % roll center front (m)
vehicleParams.rc_r        = 0.0016628;      % roll center rear (m)
vehicleParams.wheelRate_f = 2.985553732e5;  % (N/m)
vehicleParams.wheelRate_r = 2.941321827e5;  % (N/m)
vehicleParams.ARB_f       = 0;              % (Nm/rad) TBD
vehicleParams.ARB_r       = 0;              % (Nm/rad) no rear bar
vehicleParams.Iz          = 1000;           % yaw inertia (kg m^2) TBD
vehicleParams.staticCornerLoad = [1679, 1679, 2318.6, 2318.6];   % [FL FR RL RR] (N) - corner scales

% steering, road wheel angle = steerOffset + steer / steerRatio, then the Ackermann table and static toe
vehicleParams.steerRatio  = 15.015;         % steering wheel -> road wheel
vehicleParams.steerOffset = 0.333;          % road wheel angle offset (deg)
vehicleParams.toe_f       = 0;              % static toe (deg, - = out), yaw_moment.m has -0.451, 0 until confirmed
vehicleParams.toe_r       = 0;

% aero
vehicleParams.ClA         = 0.58;           % downforce area*coef (m^2)
vehicleParams.CdA         = 1.33;           % drag area*coef (m^2)
vehicleParams.aeroBal_f   = 0.33;           % front share of downforce (-)
vehicleParams.rho         = 1.225;          % air density (kg/m^3)

% brakes, acceleration_interface params.yaml, T_wheel = P*A*mu*R/1000
vehicleParams.A_caliper   = 4486;           % (mm^2)
vehicleParams.mu_pad      = 0.444;          % pad kinetic friction (-), fit to force balance (yaml 0.4)
vehicleParams.R_brake     = 0.134;          % effective rotor radius (m)

% driveline, acceleration_interface params.yaml
vehicleParams.gearRatio   = [2.9167, 1.8667, 1.3750, 1.1111, 0.9524, 0.8889];
vehicleParams.gearEff     = [0.91,   0.91,   0.91,   0.96,   0.96,   0.96  ];
vehicleParams.diffRatio   = 3.0;
vehicleParams.diffEff     = 0.99;
vehicleParams.throttleClosed = 0.05;        % throttle fraction at or below this is closed (map 0 column)

% rotating inertia, tires from the tire files
vehicleParams.m_tire_f    = 6.852;          % (kg) 275 wide
vehicleParams.m_tire_r    = 8.323;          % (kg) 385 wide
vehicleParams.R0_f        = 0.3006;         % unloaded radius (m)
vehicleParams.R0_r        = 0.3132;         % unloaded radius (m)
vehicleParams.R_rim       = 0.1905;         % rim radius (m)
vehicleParams.I_rest      = 0.25;           % rim + rotor + hub per wheel (kg m^2) TODO
vehicleParams.I_engine    = 0.15;           % crank + flywheel + clutch + gearbox input (kg m^2) TODO
vehicleParams.R_logger_f  = 0.30;           % radius the logger uses for the front wheel speed (params.yaml)

% locked wheel sliding friction, braking best guess (brake_anylisis/brake_bias_schedule.m)
vehicleParams.muX_f       = 0.95;
vehicleParams.muX_r       = 1.35;

% normal force observer
vehicleParams.fzObs.K     = 1.1;            % gain on (gage rate - model rate)
vehicleParams.fzObs.tau   = 8.0;            % (s) correction decays back to the model

% tire model: MPC brush (fbl_mpc_controller config/vehicle_model_param.yaml) with a load sensitive Ca per tire
vehicleParams.obs.mu     = [1.6 1.6];           % friction_coefficient [front rear]
vehicleParams.obs.Ca     = [174000 290000];     % axle cornering stiffness (N/rad) at Fz0, per tire Ca / 2
vehicleParams.obs.pCa    = [0.76 0.78];         % Ca_i = Ca/2 (Fz_i / Fz0)^pCa, rig MF 6.2 Ky(Fz) secant 800-3000 N
vehicleParams.obs.Fz0    = [1679 2318.6];       % (N) per tire reference load = static corner load [front rear]
vehicleParams.obs.smallA = deg2rad(0.1);        % (rad) slip floor of the secant stiffness

% slip observers and understeer gradient
vehicleParams.obs.tauB   = 0.2;                 % (s) bicycle observer pull time to the tire model
vehicleParams.obs.tauD   = 0.2;                 % (s) dual track observer pull time
vehicleParams.obs.vMin   = 10;                  % (m/s) observers run above this, v_y reset to 0 below
vehicleParams.obs.kAyMin = 4;                   % (m/s^2) understeer gradient only where |vx r| is above this
vehicleParams.obs.sigA   = 200;                 % (N) Fy split correction: prior floor of each tire's brush force
vehicleParams.obs.sigR   = 0.2;                 % (-) Fy split correction: prior fraction of each tire's brush force
vehicleParams.obs.dtWeights = false;            % dual track tire weights, false (package): all 1; true: comparison only
vehicleParams.obs.dtPow  = 2;                   % comparison only: weight = conditioning^dtPow * load share

g = 9.81;
fc = vehicleParams.fc;  fcObsModel = vehicleParams.fcObsModel;  fcObsGage = vehicleParams.fcObsGage;
vxMin = vehicleParams.vxMin;

%% calibrations (offline here, parameters on the vehicle; printed below for the yaml)
% wheel speed calibration on free rolling (zero slip, each wheel speed must read ground speed)

vx_cal = lpf(data.odom_vx_mps, fc, Ts);

freeRolling = abs(lpf(data.a_x, fc, Ts))                 < 0.6 ...
            & abs(lpf(data.a_y, fc, Ts))                 < 0.5 ...
            & abs(lpf(data.steer_wheel_ang_deg, fc, Ts)) < 2   ...
            & lpf(data.front_brake_pressure_kpa, fc, Ts) < 60  ...
            & lpf(data.rear_brake_pressure_kpa,  fc, Ts) < 60  ...
            & vx_cal > 12;

wheelCh  = ["fl_speed_kmh", "fr_speed_kmh", "rl_speed_kmh", "rr_speed_kmh"];
wheelCal = ones(1,4);

if sum(freeRolling) >= 300
    for i = 1:4
        vw = lpf(data.(wheelCh(i)), fc, Ts) ./ 3.6;
        wheelCal(i) = mean(vw(freeRolling) ./ vx_cal(freeRolling), "omitnan");
    end
else
    warning("only %d free rolling samples, wheel speeds left uncalibrated", sum(freeRolling));
end

% rear rolling radius from engine speed, free rolling in gear: R = V*G/omega_engine
gearCal = round(data.current_gear);
inGearCal = freeRolling & gearCal >= 1 & gearCal <= 6 & abs(data.current_gear - gearCal) < 0.01;

G_cal = zeros(height(data), 1);
G_cal(inGearCal) = vehicleParams.gearRatio(gearCal(inGearCal)) .* vehicleParams.diffRatio;

omega_engine_cal  = lpf(data.engine_rpm, fc, Ts) .* 2*pi/60;
vehicleParams.R_r = median(vx_cal(inGearCal) .* G_cal(inGearCal) ./ omega_engine_cal(inGearCal), "omitnan");
vehicleParams.R_f = vehicleParams.R_logger_f / mean(wheelCal(1:2));   % logger uses 0.30 f / 0.31 r, not one radius

% brake pressure zero (throttle on, so no braking)
throttleOn = lpf(data.throttle_pct, fc, Ts) > 20;
Pf_all  = lpf(data.front_brake_pressure_kpa, fc, Ts);
Pr_all  = lpf(data.rear_brake_pressure_kpa,  fc, Ts);
Pf_zero = median(Pf_all(throttleOn));
Pr_zero = median(Pr_all(throttleOn));

% throttle idle reading
throttleIdle = prctile(lpf(data.throttle_pct, fc, Ts), 1);

% strain gage zero: gage at sample 100 minus the static corner load (on vehicle: at startup, car at rest)
gageZero   = lpf([data.fl_load_n, data.fr_load_n, data.rl_load_n, data.rr_load_n], fc, Ts);
gageOffset = gageZero(min(100, height(data)), :) - vehicleParams.staticCornerLoad;

fprintf("calibration: wheelCal %s, R_f %.4f, R_r %.4f m, brake zero %.1f / %.1f kPa, throttle idle %.2f %%, gage offset %s N\n", ...
    sprintf("%.4f ", wheelCal), vehicleParams.R_f, vehicleParams.R_r, Pf_zero, Pr_zero, throttleIdle, sprintf("%.0f ", gageOffset));

%% time window

keep = t_all >= timeWindow(1) & t_all <= timeWindow(2);
data = data(keep, :);
t    = t_all(keep);

%% input conditioning: units, calibrations, filters

Fvx   = lpf(data.odom_vx_mps,  fc, Ts);
Fvy   = lpf(data.odom_vy_mps,  fc, Ts);   % localization v_y: dv_y/dt in the force balance, kinematic (reference) slips
Fwz   = lpf(data.odom_wz_rads, fc, Ts);

Fax   = lpf(data.a_x, fc, Ts);
Fay   = lpf(data.a_y, fc, Ts);            % accel_filtered, gravity and bias removed upstream
steer = lpf(data.steer_wheel_ang_deg, fc, Ts);
Pf    = max(lpf(data.front_brake_pressure_kpa, fc, Ts) - Pf_zero, 0);
Pr    = max(lpf(data.rear_brake_pressure_kpa,  fc, Ts) - Pr_zero, 0);
gear  = round(data.current_gear);   % integer, not filtered

Frpm      = lpf(data.engine_rpm,   fc, Ts);
Fthrottle = lpf(data.throttle_pct, fc, Ts);

Vw_fl = lpf(data.fl_speed_kmh, fc, Ts) ./ 3.6 ./ wheelCal(1);
Vw_fr = lpf(data.fr_speed_kmh, fc, Ts) ./ 3.6 ./ wheelCal(2);
Vw_rl = lpf(data.rl_speed_kmh, fc, Ts) ./ 3.6 ./ wheelCal(3);
Vw_rr = lpf(data.rr_speed_kmh, fc, Ts) ./ 3.6 ./ wheelCal(4);

Fz_fl_meas = lpf(data.fl_load_n, fcObsGage, Ts) - gageOffset(1);
Fz_fr_meas = lpf(data.fr_load_n, fcObsGage, Ts) - gageOffset(2);
Fz_rl_meas = lpf(data.rl_load_n, fcObsGage, Ts) - gageOffset(3);
Fz_rr_meas = lpf(data.rr_load_n, fcObsGage, Ts) - gageOffset(4);

Fq    = lpf([data.odom_qw, data.odom_qx, data.odom_qy, data.odom_qz], fc, Ts);
Feul  = quat2eul(Fq, "ZYX");   % [yaw pitch roll]
pitch = -Feul(:,2);
roll  =  Feul(:,3);

% load model inputs, filtered at fcObsModel
Fvx_o   = lpf(data.odom_vx_mps,  fcObsModel, Ts);
Fvy_o   = lpf(data.odom_vy_mps,  fcObsModel, Ts);
Fwz_o   = lpf(data.odom_wz_rads, fcObsModel, Ts);
Fax_o   = lpf(data.a_x,          fcObsModel, Ts);
Feul_o  = quat2eul(lpf([data.odom_qw, data.odom_qx, data.odom_qy, data.odom_qz], fcObsModel, Ts), "ZYX");
pitch_o = -Feul_o(:,2);
roll_o  =  Feul_o(:,3);

px = data.odom_px_m;   % position, plots only (fastest lap, corner marks)
py = data.odom_py_m;

%% geometry

m   = vehicleParams.m;
L   = vehicleParams.wheelbase;
lf  = (1 - vehicleParams.w_dist_f) * L;   % CG -> front axle, 1.724 m
lr  = vehicleParams.w_dist_f * L;         % CG -> rear axle, 1.248 m
h   = vehicleParams.cg_z;
ft  = vehicleParams.t_f;
rt  = vehicleParams.t_r;
Iz  = vehicleParams.Iz;
R_f = vehicleParams.R_f;
R_r = vehicleParams.R_r;
rho = vehicleParams.rho;
obs = vehicleParams.obs;
muB = obs.mu;   CaB = obs.Ca;

%% SHARED, STATELESS: road wheel angles (Ackermann lookup table + static toe)
% FL = delta_l - toe_f, FR = delta_r + toe_f, RL = -toe_r, RR = toe_r (YMD_calc.m convention), delta > 0 = left turn
% bicycle delta = mean of the two front wheels

delta_road = vehicleParams.steerOffset + steer ./ vehicleParams.steerRatio;      % (deg)
delta_fl   = deg2rad(interp1(ackLut(:,1), ackLut(:,2), delta_road, "linear", "extrap") - vehicleParams.toe_f);
delta_fr   = deg2rad(interp1(ackLut(:,1), ackLut(:,3), delta_road, "linear", "extrap") + vehicleParams.toe_f);
delta_rl   = deg2rad(-vehicleParams.toe_r) * ones(size(t));
delta_rr   = deg2rad( vehicleParams.toe_r) * ones(size(t));
dW         = [delta_fl, delta_fr, delta_rl, delta_rr];
delta      = 0.5 .* (delta_fl + delta_fr);

%% SHARED, STATELESS: accelerations
% a_z channel not used (wheel hop), normal accel from attitude and yaw rate

dt = [Ts; diff(t)];
dt(dt <= 0) = Ts;
ddt = @(x) [0; diff(x)] ./ dt;          % backward difference of the filtered signal

dvy_dt = ddt(Fvy);
rdot   = ddt(Fwz);

ay_tire  = Fvx .* Fwz + dvy_dt + g .* cos(pitch) .* sin(roll);       % lateral, bank corrected
az_road  = g .* cos(pitch) .* cos(roll) - Fvx .* Fwz .* sin(roll);   % normal, gravity + bank centripetal

%% SHARED, STATELESS: tire kinematics, kinematic slip angles (localization v_y, the reference)
% corner speeds vx -/+ r t/2, lateral vy + lf r (front) / vy - lr r (rear), rotated by each tire's road wheel angle

[VxT, VyT] = tireKin(Fvx, Fvy, Fwz, dW, lf, lr, ft, rt);
Vx_tire_fl = VxT(:,1);  Vx_tire_fr = VxT(:,2);  Vx_tire_rl = VxT(:,3);  Vx_tire_rr = VxT(:,4);

moving      = Fvx > vxMin;
movingRatio = Fvx > vehicleParams.vxMinRatio;
Vx = Fvx;  Vx(~moving) = NaN;

alphaKin = -atan2(VyT, VxT);  alphaKin(~moving,:) = NaN;
alpha_fl = alphaKin(:,1);  alpha_fr = alphaKin(:,2);  alpha_rl = alphaKin(:,3);  alpha_rr = alphaKin(:,4);

alpha_f = delta - atan2(Fvy + Fwz .* lf, Vx);
alpha_r =       - atan2(Fvy - Fwz .* lr, Vx);

%% SHARED, STATELESS: slip ratios (wheel speed referenced, the ABS input) and kappa
% s_x = (Vw - Vx_t) / max(|Vw|, vwMin), s_y = -Vy_t / max(|Vw|, vwMin), clamped to +/- slipRatioMax
% kappa = (Vw - Vx_t) / |Vx_t| (MF definition, -1 = locked)

Vw4  = [Vw_fl, Vw_fr, Vw_rl, Vw_rr];
den4 = max(abs(Vw4), vehicleParams.vwMin);
sMax = vehicleParams.slipRatioMax;
sx4  = min(max((Vw4 - VxT) ./ den4, -sMax), sMax);   sx4(~movingRatio,:) = NaN;
sy4  = min(max(-VyT ./ den4, -sMax), sMax);          sy4(~movingRatio,:) = NaN;
sx_fl = sx4(:,1);  sx_fr = sx4(:,2);  sx_rl = sx4(:,3);  sx_rr = sx4(:,4);
sy_fl = sy4(:,1);  sy_fr = sy4(:,2);  sy_rl = sy4(:,3);  sy_rr = sy4(:,4);

Vw_front = 0.5 .* (Vw_fl + Vw_fr);
Vw_rear  = 0.5 .* (Vw_rl + Vw_rr);
sx_f = min(max((Vw_front - Fvx) ./ max(abs(Vw_front), vehicleParams.vwMin), -sMax), sMax);  sx_f(~movingRatio) = NaN;
sx_r = min(max((Vw_rear  - Fvx) ./ max(abs(Vw_rear),  vehicleParams.vwMin), -sMax), sMax);  sx_r(~movingRatio) = NaN;

kappa4 = (Vw4 - VxT) ./ abs(VxT);  kappa4(~movingRatio,:) = NaN;
kappa_fl = kappa4(:,1);  kappa_fr = kappa4(:,2);  kappa_rl = kappa4(:,3);  kappa_rr = kappa4(:,4);
locked4  = kappa4 < vehicleParams.kappaLock;
locked_fl = locked4(:,1);  locked_fr = locked4(:,2);  locked_rl = locked4(:,3);  locked_rr = locked4(:,4);

%% SHARED, STATELESS: load model, axle (bicycle) and per tire (dual track)
% ASSUMPTION: rigid body pitch transfer m ax h / L, no suspension dynamics, CG height 0.35 m
% ASSUMPTION: aero balance fixed at 33 % front, no drag pitching moment, no crest/dip term
% ASSUMPTION: steady state roll, roll stiffness from wheel rates (no ARB yet), left/right by static corner loads
% runs on the fcObsModel inputs

ay_tire_o = Fvx_o .* Fwz_o + ddt(Fvy_o) + g .* cos(pitch_o) .* sin(roll_o);
ax_long_o = Fax_o + g .* sin(pitch_o);
az_road_o = g .* cos(pitch_o) .* cos(roll_o) - Fvx_o .* Fwz_o .* sin(roll_o);

downforce = 0.5 .* rho .* vehicleParams.ClA .* Fvx_o.^2;
aeroBal_f = vehicleParams.aeroBal_f;

Fz_f = m .* az_road_o .* lr ./ L - m .* ax_long_o .* h ./ L +      aeroBal_f  .* downforce;
Fz_r = m .* az_road_o .* lf ./ L + m .* ax_long_o .* h ./ L + (1 - aeroBal_f) .* downforce;

rc_f = vehicleParams.rc_f;
rc_r = vehicleParams.rc_r;
k_phi_f = vehicleParams.wheelRate_f * ft^2 / 2 + vehicleParams.ARB_f;
k_phi_r = vehicleParams.wheelRate_r * rt^2 / 2 + vehicleParams.ARB_r;
rollShare_f = k_phi_f / (k_phi_f + k_phi_r);
h_roll = h - (rc_f + (rc_r - rc_f) * lf / L);   % CG -> roll axis

latTransfer_f = m .* ay_tire_o ./ ft .* (h_roll *      rollShare_f  + lr * rc_f / L);
latTransfer_r = m .* ay_tire_o ./ rt .* (h_roll * (1 - rollShare_f) + lf * rc_r / L);

cornerLoad = vehicleParams.staticCornerLoad;
share_fl = cornerLoad(1) / (cornerLoad(1) + cornerLoad(2));
share_rl = cornerLoad(3) / (cornerLoad(3) + cornerLoad(4));

Fz_fl = Fz_f .*      share_fl  - latTransfer_f;
Fz_fr = Fz_f .* (1 - share_fl) + latTransfer_f;
Fz_rl = Fz_r .*      share_rl  - latTransfer_r;
Fz_rr = Fz_r .* (1 - share_rl) + latTransfer_r;

Fz_bike_model = [Fz_f, Fz_r];
Fz_dual_model = [Fz_fl, Fz_fr, Fz_rl, Fz_rr];

%% SHARED, STATELESS: Fx per wheel (wheel dynamics, Rezaeian eq 1), Fx = (Td - Tb - Iw omega_dot) / R
% ASSUMPTION: same caliper, pad and rotor front/rear, pad mu constant, open diff (equal drive torque left/right)
% ASSUMPTION: tire inertia as a thick ring + rim/rotor/hub, engine inertia reflected by G^2 on the rear average
% ASSUMPTION: clutch engaged in gear, efficiency multiplies drive and divides motoring torque, no rolling resistance
% a locked wheel is capped at the sliding force muX * the load MODEL Fz (stateless, so both models share it)

Iw_f = 0.5 * vehicleParams.m_tire_f * (vehicleParams.R0_f^2 + vehicleParams.R_rim^2) + vehicleParams.I_rest;
Iw_r = 0.5 * vehicleParams.m_tire_r * (vehicleParams.R0_r^2 + vehicleParams.R_rim^2) + vehicleParams.I_rest;

domega_fl = ddt(Vw_fl ./ R_f);
domega_fr = ddt(Vw_fr ./ R_f);
domega_rl = ddt(Vw_rl ./ R_r);
domega_rr = ddt(Vw_rr ./ R_r);
domega_rear = 0.5 .* (domega_rl + domega_rr);

brakeGain = vehicleParams.A_caliper * vehicleParams.mu_pad * vehicleParams.R_brake / 1000;   % (Nm/kPa)
Tb_f = brakeGain .* Pf;
Tb_r = brakeGain .* Pr;

throttle_frac = max(0, (Fthrottle - throttleIdle) ./ (100 - throttleIdle));
throttle_frac(throttle_frac <= vehicleParams.throttleClosed) = 0;
T_engine = engineTorque(Frpm, throttle_frac);

inGear = gear >= 1 & gear <= 6;
G   = zeros(size(t));
eta = ones(size(t));
G(inGear)   = vehicleParams.gearRatio(gear(inGear))' .* vehicleParams.diffRatio;
eta(inGear) = vehicleParams.gearEff(gear(inGear))'   .* vehicleParams.diffEff;

Td_axle = G .* T_engine .* eta;
motoring = T_engine < 0;
Td_axle(motoring) = G(motoring) .* T_engine(motoring) ./ eta(motoring);
Td_axle = Td_axle - vehicleParams.I_engine .* G.^2 .* domega_rear;

Fx_fl = (              - Tb_f - Iw_f .* domega_fl) ./ R_f;
Fx_fr = (              - Tb_f - Iw_f .* domega_fr) ./ R_f;
Fx_rl = (Td_axle ./ 2  - Tb_r - Iw_r .* domega_rl) ./ R_r;
Fx_rr = (Td_axle ./ 2  - Tb_r - Iw_r .* domega_rr) ./ R_r;

FzM = max(Fz_dual_model, 0);
Fx_fl(locked_fl) = max(Fx_fl(locked_fl), -vehicleParams.muX_f .* FzM(locked_fl,1));
Fx_fr(locked_fr) = max(Fx_fr(locked_fr), -vehicleParams.muX_f .* FzM(locked_fr,2));
Fx_rl(locked_rl) = max(Fx_rl(locked_rl), -vehicleParams.muX_r .* FzM(locked_rl,3));
Fx_rr(locked_rr) = max(Fx_rr(locked_rr), -vehicleParams.muX_r .* FzM(locked_rr,4));

Fxf = Fx_fl + Fx_fr;
Fxr = Fx_rl + Fx_rr;

%% SHARED, STATELESS: axle Fy (force and yaw moment balance), front in its tire frame
% ASSUMPTION: Iz = 1000 placeholder; front axle in the frame of the mean front road wheel angle

Fyf_vehicle = (m .* lr .* ay_tire + Iz .* rdot) ./ L;
Fyr         = (m .* lf .* ay_tire - Iz .* rdot) ./ L;
Fyf         = (Fyf_vehicle - Fxf .* sin(delta)) ./ cos(delta);

%% SHARED, STATELESS: tire model
% MPC brush, closed form both ways (brushFy, brushInv), one load sensitive Ca per tire everywhere:
% Ca_i = Ca/2 (Fz_i / Fz0)^pCa (brushCa); a bicycle axle is two such tires at half the axle load

CaAx = @(Fz, ax) 2 .* brushCa(Fz ./ 2, CaB(ax) / 2, obs.Fz0(ax), obs.pCa(ax));   % bicycle axle
CaTr = @(Fz, ax)      brushCa(Fz,      CaB(ax) / 2, obs.Fz0(ax), obs.pCa(ax));   % one tire
smallA = obs.smallA;
kusFn  = @(C) m .* (lr .* C(:,2) - lf .* C(:,1)) ./ (L .* C(:,1) .* C(:,2));     % the MPC's formula
running = Fvx > obs.vMin & all(isfinite([Fyf, Fyr, Fwz, delta, Fay]), 2);       % observer gate, both models

%% BICYCLE MODEL: axle normal force observer
% c(k) = tau / (tau + dt) (c(k-1) + K u(k)), u = gage change - model change (model through the gage filter)
% Fz_obs = max(model + c, 0)

Fz_bike_meas = [Fz_fl_meas + Fz_fr_meas, Fz_rl_meas + Fz_rr_meas];
Fz_bike_obs  = fzDerivativeObserver(Fz_bike_model, lpf(Fz_bike_model, fcObsGage, Ts), Fz_bike_meas, t, ...
                                    vehicleParams.fzObs.K, vehicleParams.fzObs.tau);
FzB    = Fz_bike_obs;
obsOkB = running & all(isfinite(FzB), 2);

%% BICYCLE MODEL: v_y observer (MPC brush at the observed axle load, full trust) and axle slips
% 1 axle slip from the brush inverse at the axle Fy and observed axle Fz
% 2 vy_F = vx tan(delta - alpha_f) - lf r, vy_R = -vx tan(alpha_r) + lr r, tire model v_y = mean
% 3 predict vy = vy + (a_y - vx r) Ts, correct vy = vy + (Ts / tauB) (vy_T - vy), vy = 0 while not running
% 4 alpha_f = delta - atan((vy + lf r)/vx), alpha_r = -atan((vy - lr r)/vx)

[aB_f, cB_f] = brushInv(Fyf, FzB(:,1), muB(1), CaAx(FzB(:,1), 1));
[aB_r, cB_r] = brushInv(Fyr, FzB(:,2), muB(2), CaAx(FzB(:,2), 2));
aBin  = [aB_f, aB_r];  cBin = [cB_f, cB_r];
vyT_B = 0.5 .* ((Fvx .* tan(delta - aBin(:,1)) - lf .* Fwz) + (-Fvx .* tan(aBin(:,2)) + lr .* Fwz));
vy_bike_obs = vyObserver(vyT_B, ones(size(t)), obs.tauB, Fvx, Fwz, Fay, Ts, obsOkB);
alpha_f_obs = delta - atan((vy_bike_obs + lf .* Fwz) ./ max(Fvx, 1));
alpha_r_obs =       - atan((vy_bike_obs - lr .* Fwz) ./ max(Fvx, 1));
alpha_f_obs(~obsOkB) = NaN;  alpha_r_obs(~obsOkB) = NaN;

%% BICYCLE MODEL: understeer gradient
% secant axle stiffness C = |brush(alpha_obs, Fz_axle)| / tan|alpha_obs|, k_us = m (lr C_r - lf C_f) / (L C_f C_r)
% valid where the observer runs and |vx r| > kAyMin

kusOkB = obsOkB & abs(Fvx .* Fwz) > obs.kAyMin;
aBk = [alpha_f_obs, alpha_r_obs];
C_bike = zeros(numel(t), 2);
for ax = 1:2
    a1 = max(abs(aBk(:,ax)), smallA);
    C_bike(:,ax) = abs(brushFy(a1, FzB(:,ax), muB(ax), CaAx(FzB(:,ax), ax))) ./ tan(a1);
end
k_us_bike = kusFn(C_bike);  k_us_bike(~kusOkB) = NaN;

%% BICYCLE MODEL: debug flags (bicycle/debug)

dbgB = struct( ...
    "moving",           moving, ...
    "slipAngleValid",   moving & isfinite(alpha_f) & isfinite(alpha_r), ...
    "slipRatioValid",   movingRatio & [abs(Vw_front), abs(Vw_rear)] >= vehicleParams.vwMin, ...
    "observerRunning",  obsOkB, ...
    "fzObserverActive", all(isfinite(Fz_bike_meas), 2), ...
    "kusValid",         kusOkB, ...
    "brushSlip",        aBin, ...
    "conditioning",     cBin, ...
    "saturated",        obsOkB & cBin == 0, ...
    "vyTireModel",      vyT_B);

%% DUAL TRACK MODEL: per tire normal force observer (same observer, per tire)

Fz_dual_meas = [Fz_fl_meas, Fz_fr_meas, Fz_rl_meas, Fz_rr_meas];
Fz_dual_obs  = fzDerivativeObserver(Fz_dual_model, lpf(Fz_dual_model, fcObsGage, Ts), Fz_dual_meas, t, ...
                                    vehicleParams.fzObs.K, vehicleParams.fzObs.tau);
FzT    = Fz_dual_obs;
FzAx   = [FzT(:,1) + FzT(:,2), FzT(:,3) + FzT(:,4)];
obsOkD = running & all(isfinite(FzT), 2);

%% DUAL TRACK MODEL: lateral force per tire, two methods
% (1) normal load split: Fy_i = Fy_axle Fz_i / (Fz_L + Fz_R), 50 / 50 on an unloaded axle
% (2) normal load split + tire model correction, inside dualTrackObserver: each tire's brush at its own slip of the
%     previous sample, the residual to the axle total spread by (sigA + sigR |Fy_i|)^2 (axleCorrect, Jung & Choi 2018)
% (2) is the per tire Fy output and the input of the dual track observer; (1) where the observer is not running
% ASSUMPTION: steady state, no relaxation length, no combined slip

fyShare_fl = FzT(:,1) ./ FzAx(:,1);  fyShare_fl(~isfinite(fyShare_fl)) = 0.5;
fyShare_rl = FzT(:,3) ./ FzAx(:,2);  fyShare_rl(~isfinite(fyShare_rl)) = 0.5;

Fy_fl = Fyf .*      fyShare_fl;
Fy_fr = Fyf .* (1 - fyShare_fl);
Fy_rl = Fyr .*      fyShare_rl;
Fy_rr = Fyr .* (1 - fyShare_rl);

%% DUAL TRACK MODEL: v_y observer (each tire's brush at its own load), one sample at a time
% per sample (dualTrackObserver):
% 0 Fy_i = method (2) with the tire slips of the previous sample (0 after a reset)
% 1 per tire slip from the brush inverse at Fy_i, its observed Fz and Ca_i
% 2 vy_i = Vx_c,i tan(delta_i - alpha_i) - x_i r (x_i = lf front, -lr rear, Vx_c,i = vx -/+ r t/2), inverse of tireKin
% 3 tire model v_y = mean of the four tires, gain 1 (equal weights)
% 4 predict / correct as the bicycle observer, tauD
% 5 tire slips from the observed v_y through tireKin, kept for step 0 of the next sample

dtGeo = struct("lf", lf, "lr", lr, "ft", ft, "rt", rt, "xArm", [lf lf -lr -lr], "mu", muB, "Ca", CaB, "Fz0", obs.Fz0, ...
               "pCa", obs.pCa, "sigA", obs.sigA, "sigR", obs.sigR, "tau", obs.tauD, "dtPow", obs.dtPow, ...
               "useWeights", obs.dtWeights);
[vy_dual_obs, Fy_tm, cTin] = dualTrackObserver(Fyf, Fyr, FzT, Vx, Fvx, Fwz, Fay, dW, Ts, obsOkD, dtGeo);
Fy_tm(~obsOkD,:) = [Fy_fl(~obsOkD), Fy_fr(~obsOkD), Fy_rl(~obsOkD), Fy_rr(~obsOkD)];
[VxD, VyD] = tireKin(Vx, vy_dual_obs, Fwz, dW, lf, lr, ft, rt);
alpha_obs = -atan2(VyD, VxD);  alpha_obs(~obsOkD,:) = NaN;            % observed slip angle per tire (rad)
alpha_obs_ax = [mean(alpha_obs(:,1:2), 2), mean(alpha_obs(:,3:4), 2)];

%% DUAL TRACK MODEL: understeer gradient
% C_axle = (|brush(alpha_L, Fz_L)| + |brush(alpha_R, Fz_R)|) / tan(mean slip), same k_us formula

kusOkD = obsOkD & abs(Fvx .* Fwz) > obs.kAyMin;
C_dual = dualStiffness(alpha_obs, FzT, muB, CaTr, smallA);
k_us_dual = kusFn(C_dual);  k_us_dual(~kusOkD) = NaN;

%% DUAL TRACK MODEL: debug flags (dualtrack/debug)

dbgD = struct( ...
    "moving",           moving, ...
    "slipAngleValid",   moving & isfinite(alphaKin), ...
    "slipRatioValid",   movingRatio & abs(Vw4) >= vehicleParams.vwMin, ...
    "observerRunning",  obsOkD, ...
    "fzObserverActive", all(isfinite(Fz_dual_meas), 2), ...
    "kusValid",         kusOkD, ...
    "lifted",           FzT < vehicleParams.fzLift, ...
    "locked",           locked4, ...
    "saturated",        obsOkD & cTin == 0, ...
    "conditioning",     cTin);

%% NOT IN THE PACKAGE: references and comparisons for the plots and the research scripts

% per tire slip from the bicycle observer v_y (comparison)
[VxB, VyB] = tireKin(Vx, vy_bike_obs, Fwz, dW, lf, lr, ft, rt);
alphaB = -atan2(VyB, VxB);  alphaB(~obsOkB,:) = NaN;

% dual track observer with the old conditioning^dtPow x load share weights (comparison)
dtGeoWt = dtGeo;  dtGeoWt.useWeights = true;
vy_dual_wt = dualTrackObserver(Fyf, Fyr, FzT, Vx, Fvx, Fwz, Fay, dW, Ts, obsOkD, dtGeoWt);
[VxN, VyN] = tireKin(Vx, vy_dual_wt, Fwz, dW, lf, lr, ft, rt);
alpha_wt = -atan2(VyN, VxN);  alpha_wt(~obsOkD,:) = NaN;
alpha_wt_ax = [mean(alpha_wt(:,1:2), 2), mean(alpha_wt(:,3:4), 2)];
k_us_dual_wt = kusFn(dualStiffness(alpha_wt, FzT, muB, CaTr, smallA));  k_us_dual_wt(~kusOkD) = NaN;

% measured k_us from the localization slips, steering offset (median on straights) removed (reference)
straight  = running & abs(Fwz) < 0.02 & abs(Fay) < 2;
slipOff   = median(alpha_f(straight) - alpha_r(straight), "omitnan");
k_us_meas = (alpha_f - alpha_r - slipOff) ./ Fay;  k_us_meas(~(kusOkB & kusOkD)) = NaN;

% Fx check: sum of the wheel forces vs the IMU force balance (Rezaeian eq 10)
Fdrag     = 0.5 .* rho .* vehicleParams.CdA .* Fvx .* abs(Fvx);
Fx_total  = m .* Fax + Fdrag + m .* g .* sin(pitch);
Fx_wheels = Fxf .* cos(delta) - Fyf .* sin(delta) + Fxr;

% Fx force balance split per tire (previous method): drive all rear, braking by the caliper pressure bias (0.53 below
% 75 kPa), engine braking rear, each axle 50 / 50
biasF = (Tb_f ./ R_f) ./ (Tb_f ./ R_f + Tb_r ./ R_r);
biasF(Pf + Pr < 75) = 0.53;
braking    = Fx_total < 0;
Fx_engine  = Td_axle ./ R_r;
Fx_caliper = Fx_total - Fx_engine;
overshoot  = braking & Fx_caliper > 0;
Fx_caliper(overshoot) = 0;
Fx_engine(overshoot)  = Fx_total(overshoot);
Fxf_fb = zeros(size(Fx_total));
Fxr_fb = Fx_total;
Fxf_fb(braking) =      biasF(braking)  .* Fx_caliper(braking);
Fxr_fb(braking) = (1 - biasF(braking)) .* Fx_caliper(braking) + Fx_engine(braking);
Fx_fl_fb = Fxf_fb ./ 2;  Fx_fr_fb = Fxf_fb ./ 2;
Fx_rl_fb = Fxr_fb ./ 2;  Fx_rr_fb = Fxr_fb ./ 2;

fprintf("v_y rms vs the localization (v > %g m/s): bicycle %.3f, dual track %.3f m/s (with the old weights %.3f)\n", obs.vMin, ...
    rms(vy_bike_obs(obsOkB) - Fvy(obsOkB), "omitnan"), rms(vy_dual_obs(obsOkD) - Fvy(obsOkD), "omitnan"), ...
    rms(vy_dual_wt(obsOkD) - Fvy(obsOkD), "omitnan"));
fprintf("per tire slip rms vs the localization slip (deg), dual track: %s\n", ...
    sprintf("%.2f ", rad2deg(rms(alpha_obs(obsOkD,:) - alphaKin(obsOkD,:), "omitnan"))));
fprintf("k_us (|vx r| > %g): median measured %.5f, bicycle %.5f, dual track %.5f; median |k - measured| bicycle %.5f, dual track %.5f\n", ...
    obs.kAyMin, median(k_us_meas, "omitnan"), median(k_us_bike, "omitnan"), median(k_us_dual, "omitnan"), ...
    median(abs(k_us_bike - k_us_meas), "omitnan"), median(abs(k_us_dual - k_us_meas), "omitnan"));
fprintf("debug: moving %.1f %%, observers running %.1f / %.1f %%, a tire saturated %.2f %%\n", ...
    100 * mean(moving), 100 * mean(obsOkB), 100 * mean(obsOkD), 100 * mean(any(dbgD.saturated, 2)));

%% save for the research scripts (tire_fit.m, tire_fz_plots.m, debug_slip_angle.m, debug_slip_ratio.m)
% Pacejka 1987 (tires.pdf) fitted by tire_fit.m, c = [C a1 ... a8], Fz in kN, Fy: alpha in deg, Fx: kappa in %
% (refit 2026-09-30 on the 2025 comp log), not used by the package

if saveFitData
    vehicleParams.pacFy_f = [1.38674 -126.23 1932.29 2160.01 1.77721 0.234871 -1.61212e-05 -0.0966109 -0.522512];
    vehicleParams.pacFy_r = [1.34461 -92.2527 1910.84 3000.88 1.48429 0.25844 0.000450439 0.136008 -2.1887];
    vehicleParams.pacFx_f = [1.65707 -50.7594 1098.59 -63.5599 1011.01 -0.0111115 -0.00104252 0.0857887 -0.380883];
    vehicleParams.pacFx_r = [1.53503 -66.5514 1621.09 52.8069 883.302 0.0865917 -0.00203071 -0.0268577 0.12542];
    save(fitDataFile, "t", "Fvx", "Fax", "Fay", "ay_tire", "az_road", "delta", "delta_fl", "delta_fr", "gear", "Pf", "Pr", "Fthrottle", ...
        "alpha_fl", "alpha_fr", "alpha_rl", "alpha_rr", "alpha_f", "alpha_r", ...
        "kappa_fl", "kappa_fr", "kappa_rl", "kappa_rr", ...
        "locked_fl", "locked_fr", "locked_rl", "locked_rr", ...
        "Vx_tire_fl", "Vx_tire_fr", "Vx_tire_rl", "Vx_tire_rr", ...
        "Fz_dual_obs", "Fz_dual_meas", "Fyf", "Fyr", ...
        "Fx_fl", "Fx_fr", "Fx_rl", "Fx_rr", "Fx_total", "Fx_fl_fb", "Fx_fr_fb", "Fx_rl_fb", "Fx_rr_fb", ...
        "Vw_fl", "Vw_fr", "Vw_rl", "Vw_rr", ...
        "vy_bike_obs", "vy_dual_obs", "alpha_f_obs", "alpha_r_obs", "alpha_obs", "Fy_tm", "k_us_bike", "k_us_dual", "k_us_meas", ...
        "Fz_bike_obs", "dbgB", "dbgD", ...
        "vehicleParams");
    fprintf("tire fit data saved: %s (%d samples)\n", fitDataFile, numel(t));
end

%% plots, one window, one tab per plot
% compare_vehicle_model_node.m runs this script with VM_NO_PLOTS=1 and only needs the results
if getenv("VM_NO_PLOTS") == "1", return, end

cFz  = [0.85 0.33 0.10];   % orange, normal load split
cTm  = [0.47 0.67 0.19];   % green, tire model corrected split
cRef = [0.60 0.20 0.60];   % purple, localization (reference)
cBk  = [0.00 0.45 0.74];   % blue, bicycle observer
cDt  = [1 1 1];            % white, dual track observer
cRaw = [0.75 0.75 0.75];   % grey, raw gage
cMdl = [0.85 0.10 0.10];   % red, load model alone
tireN = ["FL", "FR", "RL", "RR"];

fig = figure("Name", "Vehicle model", "Position", [50 50 1500 1100]);
tg  = uitabgroup(fig);

% tab: axle forces
tl = newTab(tg, "Axle forces", 2, 1);
axF = gobjects(2,1);
axF(1) = nexttile(tl);
hold on
plot(t, Fxf);  plot(t, Fxr);  plot(t, Fx_wheels);  plot(t, Fx_total);
grid on
title("Longitudinal");
ylabel("F_x [N]");
legend("front", "rear", "sum of wheels", "force balance", "Location", "best");
axF(2) = nexttile(tl);
hold on
plot(t, Fyf);  plot(t, Fyr);
grid on
title("Lateral, force and yaw moment balance (front in its tire frame)");
ylabel("F_y [N]");
legend("front", "rear", "Location", "best");
xlabel(tl, "Time [s]");
linkaxes(axF, "x");

% tab: tire Fx, wheel dynamics vs force balance split
fxNames = ["FL", "FR", "RL", "RR", "Front axle (FL + FR)", "Rear axle (RL + RR)"];
Fx_wd   = [Fx_fl,    Fx_fr,    Fx_rl,    Fx_rr,    Fxf,    Fxr   ];
Fx_fb   = [Fx_fl_fb, Fx_fr_fb, Fx_rl_fb, Fx_rr_fb, Fxf_fb, Fxr_fb];
tl = newTab(tg, "Tire Fx", 3, 2);
axX = gobjects(6,1);
for i = 1:6
    axX(i) = nexttile(tl);
    hold on
    plot(t, Fx_wd(:,i));  plot(t, Fx_fb(:,i));  plot(t, Fx_wd(:,i) - Fx_fb(:,i));
    grid on
    title(fxNames(i));
    ylabel("F_x [N]");
end
legend(axX(1), "wheel dynamics", "force balance split", "difference", "Location", "best");
xlabel(tl, "Time [s]");
linkaxes(axX, "x");

% tab: tire Fy, normal load split vs tire model corrected split
Fy_fz_all = [Fy_fl, Fy_fr, Fy_rl, Fy_rr];
tl = newTab(tg, "Tire Fy", 2, 2);
axY = gobjects(4,1);
for i = 1:4
    axY(i) = nexttile(tl);
    hold on
    plot(t, Fy_fz_all(:,i), "Color", cFz);
    plot(t, Fy_tm(:,i),     "Color", cTm);
    grid on
    title(tireN(i));
    ylabel("F_y [N]");
end
legend(axY(1), "normal load split", "normal load split + tire model correction", "Location", "best");
xlabel(tl, "Time [s]");
linkaxes(axY, "x");

% tab: lateral velocity
tl = newTab(tg, "Lateral velocity", 1, 1);
nexttile(tl);
hold on
plot(t, Fvy, "-", "Color", cRef, "LineWidth", 1.5);
plot(t, vy_bike_obs, "-", "Color", cBk, "LineWidth", 1.0);
plot(t, vy_dual_obs, "-", "Color", cDt, "LineWidth", 1.0);
grid on
ylim([-3 3]);
xlabel("Time [s]");
ylabel("v_y [m/s]");
title("Lateral velocity at the CG");
legend("localization (reference)", "bicycle observer", "dual track observer", "Location", "best");

% tab: slip angles per tire
tl = newTab(tg, "Slip angles", 2, 2);
axA = gobjects(4,1);
for i = 1:4
    axA(i) = nexttile(tl);
    hold on
    plot(t, rad2deg(alphaKin(:,i)),  "-", "Color", cRef, "LineWidth", 1.5);
    plot(t, rad2deg(alphaB(:,i)),    "-", "Color", cBk,  "LineWidth", 1.0);
    plot(t, rad2deg(alpha_obs(:,i)), "-", "Color", cDt,  "LineWidth", 1.0);
    grid on
    ylim([-8 8]);
    title(tireN(i));
    ylabel("\alpha [deg]");
end
legend(axA(1), "localization kinematics (reference)", "bicycle observer, dual track kinematics", "dual track observer", "Location", "best");
xlabel(tl, "Time [s]");
linkaxes(axA, "x");

% tab: understeer gradient
tl = newTab(tg, "Understeer gradient", 2, 1);
axK = gobjects(2,1);
axK(1) = nexttile(tl);
hold on
plot(t, k_us_meas, "-", "Color", cRef, "LineWidth", 1.5);
plot(t, k_us_bike, "-", "Color", cBk,  "LineWidth", 1.0);
plot(t, k_us_dual, "-", "Color", cDt,  "LineWidth", 1.0);
yline(0.0012, "w--", "MPC clamp");
grid on
ylim([-0.002 0.005]);
ylabel("k_{us} [rad/(m/s^2)]");
title(sprintf("Understeer gradient, |v_x r| > %g m/s^2", obs.kAyMin));
legend("measured from the localization slips, steering offset removed", "bicycle (MPC brush, observed axle F_z, observer slip)", ...
    "dual track (MPC brush per tire, observed tire F_z, observer slip)", "Location", "best");
axK(2) = nexttile(tl);
plot(t, Fvx .* Fwz, "w-");
grid on
xlabel("Time [s]");
ylabel("v_x r [m/s^2]");
title("Lateral acceleration");
linkaxes(axK, "x");

% tab: slip ratio vs Fx per tire
sx_all = [sx_fl, sx_fr, sx_rl, sx_rr];
Fx_wd4 = [Fx_fl, Fx_fr, Fx_rl, Fx_rr];
Fx_fb4 = [Fx_fl_fb, Fx_fr_fb, Fx_rl_fb, Fx_rr_fb];
tl = newTab(tg, "Slip ratio vs Fx", 2, 2);
axSx = gobjects(4,1);
for i = 1:4
    axSx(i) = nexttile(tl);
    hold on
    plot(sx_all(:,i), Fx_fb4(:,i), ".", "Color", cFz);
    plot(sx_all(:,i), Fx_wd4(:,i), ".", "Color", cBk);
    grid on
    xlim(prctile(sx_all(:,i), [0.5 99.5]));
    title(tireN(i));
    xlabel("s_x [-]");
    ylabel("F_x [N]");
end
legend(axSx(1), "force balance split (F = ma)", "wheel dynamics", "Location", "best");

% tab: slip angle (dual track observer) vs Fy per tire
tl = newTab(tg, "Slip angle vs Fy", 2, 2);
for i = 1:4
    nexttile(tl);
    hold on
    plot(rad2deg(alpha_obs(:,i)), Fy_fz_all(:,i), ".", "Color", cFz);
    plot(rad2deg(alpha_obs(:,i)), Fy_tm(:,i),     ".", "Color", cTm);
    grid on
    xlim([-8 8]);
    title(tireN(i));
    xlabel("observed \alpha [deg]");
    ylabel("F_y [N]");
    if i == 1, legend("normal load split", "normal load split + tire model correction", "Location", "best"); end
end

% tab: normalized slip curves, Fx/Fz and Fy/Fz (observed Fz, tires under 200 N left out)
Fz_norm = Fz_dual_obs;
Fz_norm(Fz_norm < 200) = NaN;
tl = newTab(tg, "Normalized slip curves", 2, 4);
for i = 1:4
    nexttile(tl);
    hold on
    plot(sx_all(:,i), Fx_fb4(:,i) ./ Fz_norm(:,i), ".", "Color", cFz);
    plot(sx_all(:,i), Fx_wd4(:,i) ./ Fz_norm(:,i), ".", "Color", cBk);
    grid on
    xlim(prctile(sx_all(:,i), [0.5 99.5]));
    title(tireN(i) + ", F_x / F_z");
    xlabel("s_x [-]");
    ylabel("F_x / F_z [-]");
    if i == 1, legend("force balance split", "wheel dynamics", "Location", "best"); end
end
for i = 1:4
    nexttile(tl);
    hold on
    plot(rad2deg(alpha_obs(:,i)), Fy_fz_all(:,i) ./ Fz_norm(:,i), ".", "Color", cFz);
    plot(rad2deg(alpha_obs(:,i)), Fy_tm(:,i)     ./ Fz_norm(:,i), ".", "Color", cTm);
    grid on
    xlim([-8 8]);
    title(tireN(i) + ", F_y / F_z");
    xlabel("observed \alpha [deg]");
    ylabel("F_y / F_z [-]");
    if i == 1, legend("normal load split", "tire model corrected", "Location", "best"); end
end

% tab: observed loads (dual track and bicycle) vs raw gage, raw shifted by its median offset to the observer
names   = ["FL", "FR", "RL", "RR", "Front axle", "Rear axle"];
rawGage = [data.fl_load_n, data.fr_load_n, data.rl_load_n, data.rr_load_n];
rawGage = [rawGage, rawGage(:,1) + rawGage(:,2), rawGage(:,3) + rawGage(:,4)];
obsDual = [Fz_dual_obs, Fz_dual_obs(:,1) + Fz_dual_obs(:,2), Fz_dual_obs(:,3) + Fz_dual_obs(:,4)];
rawShift = median(obsDual - rawGage, "omitnan");
mdlDual = [Fz_dual_model, Fz_bike_model];
tl = newTab(tg, "Observed loads", 3, 2);
axZ = gobjects(6,1);
for i = 1:6
    axZ(i) = nexttile(tl);
    hold on
    plot(t, rawGage(:,i) + rawShift(i), "Color", cRaw);
    plot(t, mdlDual(:,i), "Color", cMdl, "LineWidth", 1.0);
    plot(t, obsDual(:,i), "Color", cBk,  "LineWidth", 1.2);
    if i > 4
        plot(t, Fz_bike_obs(:,i-4), "--", "Color", cFz, "LineWidth", 1.2);
    end
    grid on
    title(names(i));
    ylabel("F_z [N]");
end
legend(axZ(1), "raw gage (shifted)", "dual track model", "dual track observer", "Location", "northeast");
legend(axZ(5), "raw gage (shifted)", "bicycle model", "dual track observer (sum)", "bicycle observer", "Location", "northwest");
xlabel(tl, "Time [s]");
linkaxes(axZ, "x");

% tab: fastest lap, the model outputs with the corners marked
lapWin = fastestLap(t, px, py, Fvx, lapRef);
lap    = t >= lapWin(1) & t <= lapWin(2);
tLap   = t(lap) - lapWin(1);
tTurn  = zeros(numel(turnNames), 1);
for c = 1:numel(turnNames)
    [~, j] = min(hypot(px(lap) - turnXY(c,1), py(lap) - turnXY(c,2)));
    tTurn(c) = tLap(j);
end
cTire = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19; 0.93 0.69 0.13];   % FL, FR, RL, RR
tl = newTab(tg, "Fastest lap", 7, 1);
axL = gobjects(7,1);
axL(1) = nexttile(tl);
hold on
for i = 1:4, plot(tLap, Fz_dual_obs(lap,i), "-", "Color", cTire(i,:)); end
grid on;  ylabel("F_z [N]");  title("Observed normal load per tire (dual track)");
legend(tireN, "Location", "eastoutside");
axL(2) = nexttile(tl);
hold on
for i = 1:4, plot(tLap, Fy_tm(lap,i), "-", "Color", cTire(i,:)); end
grid on;  ylabel("F_y [N]");  title("Lateral force per tire, normal load split + tire model correction");
legend(tireN, "Location", "eastoutside");
axL(3) = nexttile(tl);
hold on
plot(tLap, Fvy(lap), "-", "Color", cRef, "LineWidth", 1.5);
plot(tLap, vy_bike_obs(lap), "-", "Color", cBk);
plot(tLap, vy_dual_obs(lap), "-", "Color", cDt);
grid on;  ylabel("v_y [m/s]");  title("Lateral velocity");
legend("localization (reference)", "bicycle observer", "dual track observer", "Location", "eastoutside");
axNm = ["Front", "Rear"];
for ax = 1:2
    axL(3 + ax) = nexttile(tl);
    hold on
    aRefAx = [alpha_f, alpha_r];  aBikeAx = [alpha_f_obs, alpha_r_obs];
    plot(tLap, rad2deg(aRefAx(lap,ax)), "-", "Color", cRef, "LineWidth", 1.5);
    plot(tLap, rad2deg(aBikeAx(lap,ax)), "-", "Color", cBk);
    plot(tLap, rad2deg(alpha_obs_ax(lap,ax)), "-", "Color", cDt);
    grid on;  ylabel("\alpha [deg]");  title(axNm(ax) + " axle slip angle");
    legend("localization kinematics (reference)", "bicycle observer", "dual track observer (mean of the tires)", "Location", "eastoutside");
end
axL(6) = nexttile(tl);
hold on
plot(tLap, k_us_meas(lap), "-", "Color", cRef, "LineWidth", 1.5);
plot(tLap, k_us_bike(lap), "-", "Color", cBk);
plot(tLap, k_us_dual(lap), "-", "Color", cDt);
yline(0.0012, "w--", "MPC clamp");
grid on;  ylim([-0.002 0.005]);  ylabel("k_{us} [rad/(m/s^2)]");  title(sprintf("Understeer gradient, |v_x r| > %g m/s^2", obs.kAyMin));
legend("measured", "bicycle", "dual track", "Location", "eastoutside");
axL(7) = nexttile(tl);
plot(tLap, Fvx(lap) .* Fwz(lap), "w-");
grid on;  ylabel("v_x r [m/s^2]");  title("Lateral acceleration");
legend("v_x r", "Location", "eastoutside");
for k = 2:6
    xline(axL(k), tTurn, ":", "Color", cRaw, "HandleVisibility", "off");
end
xline(axL(7), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xline(axL(1), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xlabel(tl, "time in lap [s]");
linkaxes(axL, "x");
xlim(axL(1), [0 diff(lapWin)]);
title(tl, sprintf("Fastest lap %.1f s", diff(lapWin)));

% tab: dual track observer with and without weights, fastest lap
cWt = [0.93 0.69 0.13];   % yellow, with weights (comparison)
nSat = sum(dbgD.saturated, 2);
tl = newTab(tg, "Weights vs no weights", 5, 1);
axW = gobjects(5,1);
axW(1) = nexttile(tl);
hold on
plot(tLap, Fvy(lap), "-", "Color", cRef, "LineWidth", 1.5);
plot(tLap, vy_dual_obs(lap), "-", "Color", cDt);
plot(tLap, vy_dual_wt(lap), "-", "Color", cWt);
grid on;  ylabel("v_y [m/s]");  title("Lateral velocity, dual track observer");
legend("localization (reference)", "without weights (used)", "with weights", "Location", "eastoutside");
for ax = 1:2
    axW(1 + ax) = nexttile(tl);
    hold on
    aRefAx = [alpha_f, alpha_r];
    plot(tLap, rad2deg(aRefAx(lap,ax)), "-", "Color", cRef, "LineWidth", 1.5);
    plot(tLap, rad2deg(alpha_obs_ax(lap,ax)), "-", "Color", cDt);
    plot(tLap, rad2deg(alpha_wt_ax(lap,ax)), "-", "Color", cWt);
    grid on;  ylabel("\alpha [deg]");  title(axNm(ax) + " axle slip angle");
    legend("localization kinematics (reference)", "without weights (used)", "with weights", "Location", "eastoutside");
end
axW(4) = nexttile(tl);
hold on
plot(tLap, vy_dual_obs(lap) - Fvy(lap), "-", "Color", cDt);
plot(tLap, vy_dual_wt(lap) - Fvy(lap), "-", "Color", cWt);
grid on;  ylabel("\Delta v_y [m/s]");  title("v_y error vs the localization");
legend(sprintf("without weights (used), rms %.3f m/s", rms(vy_dual_obs(lap) - Fvy(lap), "omitnan")), ...
       sprintf("with weights, rms %.3f m/s", rms(vy_dual_wt(lap) - Fvy(lap), "omitnan")), "Location", "eastoutside");
axW(5) = nexttile(tl);
stairs(tLap, nSat(lap), "w-");
grid on;  ylim([-0.2 4.2]);  ylabel("tires");  title("Saturated tires (weight 0 in the weighted version)");
legend("number saturated", "Location", "eastoutside");
for k = 2:4
    xline(axW(k), tTurn, ":", "Color", cRaw, "HandleVisibility", "off");
end
xline(axW(1), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xline(axW(5), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xlabel(tl, "time in lap [s]");
linkaxes(axW, "x");
xlim(axW(1), [0 diff(lapWin)]);
title(tl, sprintf("Dual track observer with and without weights, fastest lap %.1f s", diff(lapWin)));

% tab: dual track k_us with and without weights, fastest lap
kErr = @(k, m) median(abs(k(m) - k_us_meas(m)), "omitnan");
tl = newTab(tg, "k_us weights vs no weights", 2, 1);
axKw = gobjects(2,1);
axKw(1) = nexttile(tl);
hold on
plot(tLap, k_us_meas(lap),     "-", "Color", cRef, "LineWidth", 1.5);
plot(tLap, k_us_dual(lap),     "-", "Color", cDt);
plot(tLap, k_us_dual_wt(lap), "-", "Color", cWt);
yline(0.0012, "w--", "MPC clamp");
grid on;  ylim([-0.002 0.005]);  ylabel("k_{us} [rad/(m/s^2)]");
title(sprintf("Dual track understeer gradient, |v_x r| > %g m/s^2", obs.kAyMin));
legend("measured", sprintf("without weights (used), median |err| %.5f", kErr(k_us_dual, lap)), ...
       sprintf("with weights, median |err| %.5f", kErr(k_us_dual_wt, lap)), "MPC clamp", "Location", "eastoutside");
axKw(2) = nexttile(tl);
plot(tLap, Fvx(lap) .* Fwz(lap), "w-");
grid on;  ylabel("v_x r [m/s^2]");  title("Lateral acceleration");
legend("v_x r", "Location", "eastoutside");
xline(axKw(1), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xline(axKw(2), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xlabel(tl, "time in lap [s]");
linkaxes(axKw, "x");
xlim(axKw(1), [0 diff(lapWin)]);
title(tl, sprintf("Dual track k_{us} with and without weights, fastest lap %.1f s", diff(lapWin)));
fprintf("dual track k_us median |err|, fastest lap: without weights (used) %.5f, with %.5f (whole log %.5f / %.5f)\n", ...
    kErr(k_us_dual, lap), kErr(k_us_dual_wt, lap), kErr(k_us_dual, true(size(t))), kErr(k_us_dual_wt, true(size(t))));

% tab: road wheel angles (Ackermann + toe)
tl = newTab(tg, "Road wheel angles", 2, 1);
nexttile(tl);
hold on
plot(ackLut(:,1), ackLut(:,2), "-", "Color", cBk, "LineWidth", 1.5);
plot(ackLut(:,1), ackLut(:,3), "-", "Color", cFz, "LineWidth", 1.5);
plot(ackLut(:,1), ackLut(:,1), "w:");
grid on
xlim([-10 10]);
xlabel("road wheel angle input [deg]");
ylabel("wheel angle [deg]");
title("Ackermann lookup table (ackerman\_sweep\_50.xlsx), zoomed to the driven range");
legend("left", "right", "1:1", "Location", "northwest");
nexttile(tl);
hold on
plot(t, rad2deg(delta_fl - delta_fr), "-", "Color", cBk);
grid on
xlabel("Time [s]");
ylabel("\delta_{FL} - \delta_{FR} [deg]");
title(sprintf("Left minus right front road wheel angle (static toe f %.3f, r %.3f deg)", vehicleParams.toe_f, vehicleParams.toe_r));


function Fz_obs = fzDerivativeObserver(Fz_model, Fz_cmp, Fz_meas, t, K, tau)
% leaky integral of (gage change - model change), added on top of the model, clamped at 0
% Fz_cmp: the model filtered like the gage; a missing gage sample gives a zero rate (the correction decays)

    correction = zeros(size(Fz_model));

    for k = 2:numel(t)
        dt        = t(k) - t(k-1);
        rateError = (Fz_meas(k,:) - Fz_meas(k-1,:)) - (Fz_cmp(k,:) - Fz_cmp(k-1,:));
        rateError(~isfinite(rateError)) = 0;

        correction(k,:) = tau / (tau + dt) .* (correction(k-1,:) + K .* rateError);
    end

    Fz_obs = max(Fz_model + correction, 0);   % a tire can not pull on the road: clamped at 0 (lifted tire)
end


function y = lpf(x, fc, Ts)
% first order low pass, Tustin with prewarp (same as acceleration_interface computeTustinLowPassCoeffs)
% causal, runs down each column, missing samples hold the last input

    K  = tan(pi * fc * Ts);
    a1 = (1 - K) / (1 + K);
    b  =      K  / (1 + K);

    x = fillmissing(x, "previous");
    y = x;

    for k = 2:size(x, 1)
        y(k,:) = a1 .* y(k-1,:) + b .* (x(k,:) + x(k-1,:));

        reset = ~isfinite(y(k,:));   % start once the signal first appears
        y(k,reset) = x(k,reset);
    end
end


function [fL, fR] = axleCorrect(S, fL, fR, sigA, sigR)
% spread the axle residual S - (fL + fR) by each tire's prior variance (weighted projection)

    PL = (sigA + sigR .* abs(fL)).^2;
    PR = (sigA + sigR .* abs(fR)).^2;
    r  = S - (fL + fR);

    fL = fL + r .* PL ./ (PL + PR);
    fR = fR + r .* PR ./ (PL + PR);
end


function [VxT, VyT] = tireKin(vx, vy, r, dW, lf, lr, ft, rt)
% contact patch velocity of each tire in its own wheel frame [FL FR RL RR]: corner speeds vx -/+ r t/2, lateral speed
% vy + lf r (front) / vy - lr r (rear), rotated by the tire's road wheel angle dW(:,i) (Ackermann + toe)
% slip angle alpha = -atan2(VyT, VxT), its inverse for v_y: vy = Vx_corner tan(delta_i - alpha) - x_i r

    VxC = [vx - r .* (ft/2), vx + r .* (ft/2), vx - r .* (rt/2), vx + r .* (rt/2)];
    VyC = [vy + r .* lf, vy + r .* lf, vy - r .* lr, vy - r .* lr];
    VxT =  VxC .* cos(dW) + VyC .* sin(dW);
    VyT = -VxC .* sin(dW) + VyC .* cos(dW);
end


function vy = vyObserver(vyT, wT, tau, vx, r, ay, Ts, ok)
% v_y observer: predict vy = vy + (a_y - vx r) Ts, correct vy = vy + (Ts / tau) wT (vyT - vy)
% the correction uses the predicted value of the same sample; vy = 0 where ok is false (low speed or missing input)

    n  = numel(vx);
    vy = zeros(n, 1);
    for k = 2:n
        dv = (ay(k) - vx(k) * r(k)) * Ts;
        if ~ok(k) || ~isfinite(dv), vy(k) = 0; continue, end
        vy(k) = vy(k-1) + dv;
        if isfinite(vyT(k)) && isfinite(wT(k))
            vy(k) = vy(k) + (Ts / tau) * wT(k) * (vyT(k) - vy(k));
        end
    end
    vy(~ok) = NaN;
end


function [vy, Fy, cT] = dualTrackObserver(Fyf, Fyr, FzT, Vx, vx, r, ay, dW, Ts, ok, p)
% dual track v_y observer, one sample at a time (the on-vehicle DualTrackModel::step):
% Fy split corrected at the tire slips of the previous sample, brush inverse per tire, tire model v_y = mean of the
% four tires (p.useWeights true: conditioning^dtPow x load share, comparison only), IMU predict / correct

    n  = numel(vx);
    vy = nan(n, 1);  Fy = zeros(n, 4);  cT = zeros(n, 4);
    vyk = 0;  aPrev = zeros(1, 4);
    ax = [1 1 2 2];
    for k = 2:n
        if ~ok(k), vyk = 0; aPrev = zeros(1, 4); continue, end
        CaK = brushCa(FzT(k,:), p.Ca(ax) / 2, p.Fz0(ax), p.pCa(ax));
        F0 = zeros(1, 4);
        for i = 1:4, F0(i) = brushFy(aPrev(i), FzT(k,i), p.mu(ax(i)), CaK(i)); end
        [Fy(k,1), Fy(k,2)] = axleCorrect(Fyf(k), F0(1), F0(2), p.sigA, p.sigR);
        [Fy(k,3), Fy(k,4)] = axleCorrect(Fyr(k), F0(3), F0(4), p.sigA, p.sigR);
        VxC = [vx(k) - r(k) * p.ft / 2, vx(k) + r(k) * p.ft / 2, vx(k) - r(k) * p.rt / 2, vx(k) + r(k) * p.rt / 2];
        FzAx = [FzT(k,1) + FzT(k,2), FzT(k,3) + FzT(k,4)];
        vyi = nan(1, 4);  wI = ones(1, 4);
        for i = 1:4
            [ai, cT(k,i)] = brushInv(Fy(k,i), FzT(k,i), p.mu(ax(i)), CaK(i));
            vyi(i) = VxC(i) * tan(dW(k,i) - ai) - p.xArm(i) * r(k);
            if p.useWeights
                sh = FzT(k,i) / FzAx(ax(i));  if ~isfinite(sh), sh = 0.5; end
                wI(i) = cT(k,i) ^ p.dtPow * sh;
            end
        end
        vT = sum(wI .* vyi, "omitnan") / sum(wI .* isfinite(vyi));
        wT = 1;
        if p.useWeights, wT = max(wI(1) + wI(2), wI(3) + wI(4)); end
        vyk = vyk + (ay(k) - vx(k) * r(k)) * Ts;
        if isfinite(vT), vyk = vyk + (Ts / p.tau) * wT * (vT - vyk); end
        vy(k) = vyk;
        [vxt, vyt] = tireKin(Vx(k), vyk, r(k), dW(k,:), p.lf, p.lr, p.ft, p.rt);
        aPrev = -atan2(vyt, vxt);  aPrev(~isfinite(aPrev)) = 0;
    end
end


function C = dualStiffness(alpha, FzT, mu, CaTr, smallA)
% dual track secant axle stiffness: C_axle = (|brush(alpha_L)| + |brush(alpha_R)|) / tan(max(|mean slip|, smallA))

    C = zeros(size(alpha, 1), 2);
    for ax = 1:2
        Fs = zeros(size(alpha, 1), 1);
        for i = 2*ax-1:2*ax
            Fs = Fs + abs(brushFy(max(abs(alpha(:,i)), smallA), FzT(:,i), mu(ax), CaTr(FzT(:,i), ax)));
        end
        C(:,ax) = Fs ./ tan(max(abs(mean(alpha(:,2*ax-1:2*ax), 2)), smallA));
    end
end


function Fy = brushTireForce(slip_angle, Fz, mu, Ca)
% fbl_mpc_controller brush_tire_force, line for line, vectorised (controller sign: slip > 0 -> Fy < 0)

    Fz       = max(100.0, Fz);
    Fy_max   = mu .* Fz;
    alpha    = tan(slip_angle);
    a_thresh = 3.0 .* Fy_max ./ Ca;

    term1 = -Ca .* alpha;
    term2 = (Ca .* Ca) ./ (3.0 .* mu .* Fz) .* abs(alpha) .* alpha;
    term3 = -(Ca .* Ca .* Ca) ./ (27.0 .* mu .* mu .* Fz .* Fz) .* alpha .* alpha .* alpha;
    Fy    = term1 + term2 + term3;

    sat     = abs(alpha) > a_thresh;
    sgn     = 2 .* (slip_angle >= 0.0) - 1;
    Fy_sat  = -Fy_max .* sgn;
    Fy(sat) = Fy_sat(sat);
end


function Ca = brushCa(Fz, Ca0, Fz0, p)
% load sensitive cornering stiffness of one tire: Ca = Ca0 (Fz / Fz0)^p, Fz floored at 100 N as the brush

    Ca = Ca0 .* (max(Fz, 100) ./ Fz0) .^ p;
end


function Fy = brushFy(alpha, Fz, mu, Ca)
% brush force with our slip sign (alpha > 0 -> Fy > 0)

    Fy = brushTireForce(-alpha, Fz, mu, Ca);
end


function [alpha, cn] = brushInv(Fy, Fz, mu, Ca)
% closed form inverse of the brush (our sign), identical to the controller's inverse_brush_tire_slip cubic:
% alpha = atan(t_th (1 - (1 - u)^(1/3))), u = |Fy| / (mu Fz), t_th = 3 mu Fz / Ca, alpha = atan(t_th) for u >= 1
% cn = (1 - u)^(2/3) = local slope / initial slope, 0 at or past saturation, Fz floored at 100 N as the controller

    Fz = max(Fz, 100);
    Fm = mu .* Fz;
    tth = 3 .* Fm ./ Ca;
    u  = abs(Fy) ./ Fm;
    us = min(u, 1);
    alpha = sign(Fy) .* atan(tth .* (1 - (1 - us).^(1/3)));
    cn = (1 - us).^(2/3);
    cn(u >= 1 | ~isfinite(cn)) = 0;
end


function win = fastestLap(t, px, py, v, ref)
% laps timed between passes of the reference point (within 20 m, moving), the fastest complete lap [start end] (s)

    near = hypot(px - ref(1), py - ref(2)) < 20 & v > 5;
    tp   = t(diff([0; near]) == 1);
    tp   = tp([true; diff(tp) > 40]);
    [~, j] = min(diff(tp));
    win  = [tp(j), tp(j+1)];
end


function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact");
end
