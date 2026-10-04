clc
close all
clear
% vehicle model - bicycle and dual track, the MATLAB reference for the on-vehicle vehicle_model package
% outputs: observed normal load per tire and axle, kinematic slip ratios, slip angles from the MPC brush v_y observers
% (bicycle and dual track), Fx per tire (wheel dynamics), Fy per axle (force balance) and per tire (normal load split and
% normal load split + tire model correction), understeer gradient (bicycle and dual track, the MPC's formula)
% road wheel angles: Ackermann lookup table (yaw_moment/ackerman_sweep_50.xlsx) + static toe
% block diagrams and the on-vehicle build plan: observer_block_diagrams.html
% model reference: brake_anylisis/notmal_force_estimation.m

%% settings

% dataFile      =
% "/home/elijah/bag_files/VD/laguna/comp/2025-07-24_175839_merged.csv"; %
% laptop file location old comp
%dataFile = "/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv"; % same data file laptop old comp
dataFile = "/home/elijah/PurdueRacing/bags/lagoona/comp2/compition_bags/2026-09-03_121638_merged.csv"; % fastes lap data recent comp

%engineMapFile = "/home/elijah/PurdueRacing/on-vehicle/on-vehicle/src/control/acceleration_interface/config/engine_map_30psi.csv"; % laptop engine map path
engineMapFile = "/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/control/acceleration_interface/config/engine_map_30psi.csv";
ackermannFile = "/home/elijah/code/CodeFiles/Research/VD/yaw_moment/ackerman_sweep_50.xlsx";   % road_deg, left_deg, right_deg

fc         = 3;       % low pass cutoff [Hz], first order Tustin, used by every signal except the normal force observer
fcObsModel = 0.3;       % [Hz] observer only: load model inputs (vx, vy, yaw rate, a_x, roll, pitch)
fcObsGage  = 0.5;       % [Hz] observer only: strain gages, the load model is passed through the same filter before the rates are compared
timeWindow = [0 inf];   % [s] from start of recording
vxMin      = 4;         % [m/s] slip is NaN below this speed

saveFitData    = false; % write fitDataFile for tire_fit.m, run with timeWindow = [0 Inf]
% fitDataFile    = "/home/elijah/code/Research/VD/Vehicle_modeling/tire_fit_data.mat"; % for laptop path
fitDataFile = "/home/elijah/code/CodeFiles/Research/VD/Vehicle_modeling/tire_fit_data.mat";


%% load file

data  = readtable(dataFile);
t_all = data.time_s - data.time_s(1);
Ts    = median(diff(t_all));   % sample period (s)

% engine map: rows rpm, columns throttle fraction from the header
mapLines    = readlines(engineMapFile);
mapThrottle = str2double(split(mapLines(1), ","))';
mapThrottle = mapThrottle(2:end);
engineMap   = readmatrix(engineMapFile, "NumHeaderLines", 1);

engineTorque = griddedInterpolant({engineMap(:,1), mapThrottle}, engineMap(:,2:end), "linear", "nearest");

% Ackermann lookup table: road wheel angle (deg) -> left, right road wheel angle (deg)
ackLut = readmatrix(ackermannFile);

%% vehicle parameters

vehicleParams.m           = 815;            % mass (kg)
vehicleParams.wheelbase   = 2.9718;         % (m)
vehicleParams.w_dist_f    = 0.42;           % front static weight share (-)
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
% R_r from engine speed, R_f from the front wheel speed channel (see calibration)

vehicleParams.steerRatio  = 15.015;         % steering wheel -> road wheel
vehicleParams.steerOffset = 0.333;          % road wheel angle offset (deg)

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

% rotating inertia
% tires, from the tire files
vehicleParams.m_tire_f    = 6.852;          % (kg) 275 wide
vehicleParams.m_tire_r    = 8.323;          % (kg) 385 wide
vehicleParams.R0_f        = 0.3006;         % unloaded radius (m)
vehicleParams.R0_r        = 0.3132;         % unloaded radius (m)
vehicleParams.R_rim       = 0.1905;         % rim radius (m)

vehicleParams.I_rest      = 0.25;           % rim + rotor + hub per wheel (kg m^2) TODO
vehicleParams.R_logger_f  = 0.30;           % radius the logger uses for the front wheel speed (params.yaml)
vehicleParams.I_engine    = 0.15;           % crank + flywheel + clutch + gearbox input (kg m^2) TODO

% tire friction best guesses, axle level (brake_anylisis/brake_bias_schedule.m)
vehicleParams.muY_f       = 1.50;           % lateral (-), log p95 reads 1.385
vehicleParams.muY_r       = 1.75;           % lateral (-), log p95 reads 1.531
vehicleParams.muX_f       = 0.95;           % braking (-)
vehicleParams.muX_r       = 1.35;           % braking (-)

% tire model, Pacejka 1987 (tires.pdf) fitted by tire_fit.m, c = [C a1 ... a8]
% refit 2026-09-30 on the 2025 comp log with the current observer (fcObsModel 0.3, fcObsGage 0.5, K 1.1, tau 8)
% Fz in kN, Fy: alpha in deg, Fx: kappa in %
vehicleParams.pacFy_f = [1.38674 -126.23 1932.29 2160.01 1.77721 0.234871 -1.61212e-05 -0.0966109 -0.522512];
vehicleParams.pacFy_r = [1.34461 -92.2527 1910.84 3000.88 1.48429 0.25844 0.000450439 0.136008 -2.1887];
vehicleParams.pacFx_f = [1.65707 -50.7594 1098.59 -63.5599 1011.01 -0.0111115 -0.00104252 0.0857887 -0.380883];
vehicleParams.pacFx_r = [1.53503 -66.5514 1621.09 52.8069 883.302 0.0865917 -0.00203071 -0.0268577 0.12542];

vehicleParams.staticCornerLoad = [1679, 1679, 2318.6, 2318.6];   % [FL FR RL RR] (N) - corner scales

% static toe per wheel (deg, - = out), yaw_moment.m has -0.451 front and rear, 0 until confirmed on the car
vehicleParams.toe_f = 0;
vehicleParams.toe_r = 0;

% slip observers and understeer gradient, MPC brush tire (fbl_mpc_controller config/vehicle_model_param.yaml)
vehicleParams.obs.mu     = [1.6 1.6];           % friction_coefficient [front rear]
vehicleParams.obs.Ca     = [174000 290000];     % ca, axle cornering stiffness (N/rad), per tire Ca / 2
vehicleParams.obs.tauB   = 0.2;                 % (s) bicycle observer pull time to the tire model (full trust)
vehicleParams.obs.tauD   = 0.2;                 % (s) dual track observer pull time
vehicleParams.obs.dtPow  = 2;                   % dual track weight = conditioning^dtPow * load share
vehicleParams.obs.vMin   = 10;                  % (m/s) observers run above this speed, v_y reset to 0 below
vehicleParams.obs.kAyMin = 4;                   % (m/s^2) understeer gradient only where |vx r| is above this

g = 9.81;

%% wheel speed calibration (full recording, free rolling)
% free rolling wheel has zero slip, so each wheel speed must read ground speed

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

%% brake pressure zero (full recording, throttle on so no braking)

throttleOn = lpf(data.throttle_pct, fc, Ts) > 20;
Pf_all     = lpf(data.front_brake_pressure_kpa, fc, Ts);
Pr_all     = lpf(data.rear_brake_pressure_kpa,  fc, Ts);

Pf_zero = median(Pf_all(throttleOn));
Pr_zero = median(Pr_all(throttleOn));

%% strain gage zero (full recording)

gageZero = lpf([data.fl_load_n, data.fr_load_n, data.rl_load_n, data.rr_load_n], fc, Ts);
gageZero = gageZero(min(100, height(data)), :);

gageOffset = gageZero - vehicleParams.staticCornerLoad;

%% time window

keep = t_all >= timeWindow(1) & t_all <= timeWindow(2);
data = data(keep, :);
t    = t_all(keep);

%% filtered signals

Fvx   = lpf(data.odom_vx_mps,  fc, Ts);
Fvy   = lpf(data.odom_vy_mps,  fc, Ts);   % localization v_y: load model input and the reference for the slip observers
Fwz   = lpf(data.odom_wz_rads, fc, Ts);

Fax   = lpf(data.a_x, fc, Ts);
Fay   = lpf(data.a_y, fc, Ts);            % IMU lateral acceleration (gravity compensated), slip observer input
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

Fz_fl_meas = lpf(data.fl_load_n, fcObsGage, Ts) - gageOffset(1);   % observer only, see fcObsGage
Fz_fr_meas = lpf(data.fr_load_n, fcObsGage, Ts) - gageOffset(2);
Fz_rl_meas = lpf(data.rl_load_n, fcObsGage, Ts) - gageOffset(3);
Fz_rr_meas = lpf(data.rr_load_n, fcObsGage, Ts) - gageOffset(4);

Fq    = lpf([data.odom_qw, data.odom_qx, data.odom_qy, data.odom_qz], fc, Ts);
Feul  = quat2eul(Fq, "ZYX");   % [yaw pitch roll]
pitch = -Feul(:,2);
roll  =  Feul(:,3);

% observer only: load model inputs, filtered at fcObsModel
Fvx_o   = lpf(data.odom_vx_mps,  fcObsModel, Ts);
Fvy_o   = lpf(data.odom_vy_mps,  fcObsModel, Ts);
Fwz_o   = lpf(data.odom_wz_rads, fcObsModel, Ts);
Fax_o   = lpf(data.a_x,          fcObsModel, Ts);
Feul_o  = quat2eul(lpf([data.odom_qw, data.odom_qx, data.odom_qy, data.odom_qz], fcObsModel, Ts), "ZYX");
pitch_o = -Feul_o(:,2);
roll_o  =  Feul_o(:,3);

%% geometry

m   = vehicleParams.m;
L   = vehicleParams.wheelbase;
lf  = (1 - vehicleParams.w_dist_f) * L;   % CG -> front axle (long one, car is rear heavy), 1.724 m
lr  = vehicleParams.w_dist_f * L;         % CG -> rear axle, 1.248 m (URDF base_link = CG)
h   = vehicleParams.cg_z;
ft  = vehicleParams.t_f;
rt  = vehicleParams.t_r;
Iz  = vehicleParams.Iz;
R_f = vehicleParams.R_f;
R_r = vehicleParams.R_r;
rho = vehicleParams.rho;

%% road wheel angles, Ackermann lookup table and static toe
% delta_road = steerOffset + steer / steerRatio (deg), the lookup table maps it to the left and right road wheel angle
% (yaw_moment/ackerman_sweep_50.xlsx, road_deg -> left_deg, right_deg, delta > 0 = left turn, the outer wheel steers more)
% static toe (deg, - = out): FL = delta_l - toe_f, FR = delta_r + toe_f, RL = -toe_r, RR = toe_r (YMD_calc.m convention)
% delta (bicycle) = mean of the two front wheels, the static toe cancels in it

delta_road = vehicleParams.steerOffset + steer ./ vehicleParams.steerRatio;      % (deg)
delta_fl   = deg2rad(interp1(ackLut(:,1), ackLut(:,2), delta_road, "linear", "extrap") - vehicleParams.toe_f);
delta_fr   = deg2rad(interp1(ackLut(:,1), ackLut(:,3), delta_road, "linear", "extrap") + vehicleParams.toe_f);
delta_rl   = deg2rad(-vehicleParams.toe_r) * ones(size(t));
delta_rr   = deg2rad( vehicleParams.toe_r) * ones(size(t));
dW         = [delta_fl, delta_fr, delta_rl, delta_rr];                           % road wheel angle per tire (rad)
delta      = 0.5 .* (delta_fl + delta_fr);                                       % bicycle road wheel angle (rad)

%% accelerations at the tires
% a_x, a_y channels are gravity compensated, gravity is added back here
% a_z channel not used (wheel hop), normal accel from attitude and yaw rate

dt = [Ts; diff(t)];
dt(dt <= 0) = Ts;
ddt = @(x) [0; diff(x)] ./ dt;          % backward difference of the filtered signal, causal

dvy_dt = ddt(Fvy);
rdot   = ddt(Fwz);

g_y_body = -g .* cos(pitch) .* sin(roll);

ay_tire  = Fvx .* Fwz + dvy_dt - g_y_body;          % lateral, bank corrected
ax_long  = Fax + g .* sin(pitch);                   % longitudinal, grade included
az_road  = g .* cos(pitch) .* cos(roll) - Fvx .* Fwz .* sin(roll);   % normal, gravity + bank centripetal

%% tire frame velocities and kinematic slip angles (localization v_y, the reference)
% dual track: corner speeds vx -/+ r t/2, lateral speed vy + lf r (front) / vy - lr r (rear), rotated into each wheel's
% frame by its own road wheel angle (Ackermann + toe), alpha = -atan2(Vy_tire, Vx_tire)

Vx = Fvx;
Vx(abs(Vx) < vxMin) = NaN;

[VxT, VyT] = tireKin(Vx, Fvy, Fwz, dW, lf, lr, ft, rt);
Vx_tire_fl = VxT(:,1);  Vx_tire_fr = VxT(:,2);  Vx_tire_rl = VxT(:,3);  Vx_tire_rr = VxT(:,4);
Vy_tire_fl = VyT(:,1);  Vy_tire_fr = VyT(:,2);  Vy_tire_rl = VyT(:,3);  Vy_tire_rr = VyT(:,4);

alphaKin = -atan2(VyT, VxT);
alpha_fl = alphaKin(:,1);  alpha_fr = alphaKin(:,2);  alpha_rl = alphaKin(:,3);  alpha_rr = alphaKin(:,4);

% bicycle, per axle
Vy_front_c = Fvy + Fwz .* lf;
Vy_rear_c  = Fvy - Fwz .* lr;
alpha_f = delta - atan2(Vy_front_c, Vx);
alpha_r =       - atan2(Vy_rear_c,  Vx);

%% slip ratios sx sy (wheel speed referenced), kinematic

Vw_front = 0.5 .* (Vw_fl + Vw_fr);
Vw_rear  = 0.5 .* (Vw_rl + Vw_rr);

sx_fl = (Vw_fl - Vx_tire_fl) ./ Vw_fl;
sx_fr = (Vw_fr - Vx_tire_fr) ./ Vw_fr;
sx_rl = (Vw_rl - Vx_tire_rl) ./ Vw_rl;
sx_rr = (Vw_rr - Vx_tire_rr) ./ Vw_rr;

sy_fl = -Vy_tire_fl ./ Vw_fl;
sy_fr = -Vy_tire_fr ./ Vw_fr;
sy_rl = -Vy_tire_rl ./ Vw_rl;
sy_rr = -Vy_tire_rr ./ Vw_rr;

% bicycle, per axle
sx_f = (Vw_front - Vx) ./ Vw_front;
sx_r = (Vw_rear  - Vx) ./ Vw_rear;

%% longitudinal slip kappa (MF definition) and lockup
% kappa = (Vw - Vx)/|Vx|, -1 = locked, stays finite at lock where sx blows up
% ASSUMPTION: a wheel below half of its ground speed (kappa < -0.5) is locked

kappa_fl = (Vw_fl - Vx_tire_fl) ./ abs(Vx_tire_fl);
kappa_fr = (Vw_fr - Vx_tire_fr) ./ abs(Vx_tire_fr);
kappa_rl = (Vw_rl - Vx_tire_rl) ./ abs(Vx_tire_rl);
kappa_rr = (Vw_rr - Vx_tire_rr) ./ abs(Vx_tire_rr);

locked_fl = kappa_fl < -0.5;
locked_fr = kappa_fr < -0.5;
locked_rl = kappa_rl < -0.5;
locked_rr = kappa_rr < -0.5;

%% normal forces bicycle model
% ASSUMPTION: rigid body pitch transfer, m*ax*h/L, no suspension dynamics
% ASSUMPTION: CG height 0.35 m (past ~0.5 m the axle that runs out of grip first flips)
% ASSUMPTION: aero balance fixed at 33% front, no ride height or speed shift
% ASSUMPTION: no aero drag pitching moment
% ASSUMPTION: no crest/dip term, pitch rate too noisy and a_z is wheel hop
% ASSUMPTION: bank centripetal term -vx*r*sin(roll), odom roll is negative on a favourable bank
% TODO: measure cg_z and aero balance
% the load model only feeds the observer, so it runs on the observer inputs (_o, fcObsModel)

ay_tire_o = Fvx_o .* Fwz_o + ddt(Fvy_o) + g .* cos(pitch_o) .* sin(roll_o);                % same as ay_tire
ax_long_o = Fax_o + g .* sin(pitch_o);                                                     % same as ax_long
az_road_o = g .* cos(pitch_o) .* cos(roll_o) - Fvx_o .* Fwz_o .* sin(roll_o);             % same as az_road

downforce = 0.5 .* rho .* vehicleParams.ClA .* Fvx_o.^2;
aeroBal_f = vehicleParams.aeroBal_f;

Fz_f = m .* az_road_o .* lr ./ L - m .* ax_long_o .* h ./ L +      aeroBal_f  .* downforce;
Fz_r = m .* az_road_o .* lf ./ L + m .* ax_long_o .* h ./ L + (1 - aeroBal_f) .* downforce;

%% normal forces dual track model
% ASSUMPTION: steady state roll, no roll damping or roll inertia
% ASSUMPTION: roll stiffness from wheel rates at 0 mm travel, no ARB yet
% ASSUMPTION: lateral transfer scales with ay only, not with aero or bank/crest load
% ASSUMPTION: axle split left/right by static corner loads (currently symmetric, not measured)
% TODO: corner scales for staticCornerLoad (cross weight)
% TODO: front ARB rate in Nm/rad

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
share_fr = cornerLoad(2) / (cornerLoad(1) + cornerLoad(2));
share_rl = cornerLoad(3) / (cornerLoad(3) + cornerLoad(4));
share_rr = cornerLoad(4) / (cornerLoad(3) + cornerLoad(4));

Fz_fl = Fz_f .* share_fl - latTransfer_f;
Fz_fr = Fz_f .* share_fr + latTransfer_f;
Fz_rl = Fz_r .* share_rl - latTransfer_r;
Fz_rr = Fz_r .* share_rr + latTransfer_r;

%% normal force observers (derivative term)
% model sets the level, strain gages only add their rate
% the gage (fcObsGage) is compared with the model passed through the same filter, so the correction only
% carries what the gage sees and the model misses below fcObsGage, the model's faster content (fcObsModel) passes as is
% ASSUMPTION: gage bias drifts slowly, so its rate is trustworthy but its level is not

K   = 1.1;   % gain on (gage rate - model rate)
tau = 8.0;   % (s) correction decays back to the model

Fz_bike_meas  = [Fz_fl_meas + Fz_fr_meas, Fz_rl_meas + Fz_rr_meas];
Fz_bike_model = [Fz_f, Fz_r];
Fz_bike_obs   = fzDerivativeObserver(Fz_bike_model, lpf(Fz_bike_model, fcObsGage, Ts), Fz_bike_meas, t, K, tau);

Fz_dual_meas  = [Fz_fl_meas, Fz_fr_meas, Fz_rl_meas, Fz_rr_meas];
Fz_dual_model = [Fz_fl, Fz_fr, Fz_rl, Fz_rr];
Fz_dual_obs   = fzDerivativeObserver(Fz_dual_model, lpf(Fz_dual_model, fcObsGage, Ts), Fz_dual_meas, t, K, tau);

% loads for the tire models: a lifted tire carries 0 (the observer itself is not clamped), axles are the tire sums
FzT  = max(Fz_dual_obs, 0);
FzAx = [FzT(:,1) + FzT(:,2), FzT(:,3) + FzT(:,4)];

%% force calcs per wheel Fx (wheel dynamics, Rezaeian eq 1)
% Iw*omega_dot = Td - Tb - R*Fx  ->  Fx = (Td - Tb - Iw*omega_dot) / R
% ASSUMPTION: same caliper, pad and rotor front/rear, left = right
% ASSUMPTION: pad mu constant (0.444, fit on Laguna comp log), no temperature or speed effect
% ASSUMPTION: open diff, equal drive torque left/right, no diff friction
% ASSUMPTION: tire inertia as a uniform thick ring (tire file mass), rim + rotor + hub is a guess
% ASSUMPTION: front wheel speed channel is built with R = 0.30 (params.yaml), rear with 0.31
% ASSUMPTION: engine + gearbox inertia reflected to the diff by G^2, acts on the rear average
% ASSUMPTION: clutch engaged whenever in gear, no drive torque in neutral
% ASSUMPTION: efficiency multiplies drive torque, divides motoring torque (power wheel -> engine)
% ASSUMPTION: throttle below 5% (after removing the idle reading) is closed, map 0 column
% ASSUMPTION: map 0 throttle column is the true motoring torque
% ASSUMPTION: no rolling resistance
% TODO: weigh rim, rotor, hub for I_rest, find I_engine
% TODO: pad mu vs temperature, check sum of Fx against Fx_total each session

% tire as a thick ring between rim and tread, plus rim/rotor/hub
Iw_f = 0.5 * vehicleParams.m_tire_f * (vehicleParams.R0_f^2 + vehicleParams.R_rim^2) + vehicleParams.I_rest;
Iw_r = 0.5 * vehicleParams.m_tire_r * (vehicleParams.R0_r^2 + vehicleParams.R_rim^2) + vehicleParams.I_rest;

domega_fl = ddt(Vw_fl ./ R_f);
domega_fr = ddt(Vw_fr ./ R_f);
domega_rl = ddt(Vw_rl ./ R_r);
domega_rr = ddt(Vw_rr ./ R_r);

domega_rear = 0.5 .* (domega_rl + domega_rr);

% brake torque per wheel
brakeGain = vehicleParams.A_caliper * vehicleParams.mu_pad * vehicleParams.R_brake / 1000;   % (Nm/kPa)

Tb_f = brakeGain .* Pf;
Tb_r = brakeGain .* Pr;

% drive torque at the rear axle
throttleIdle  = prctile(Fthrottle, 1);
throttle_frac = max(0, (Fthrottle - throttleIdle) ./ (100 - throttleIdle));
throttle_frac(throttle_frac <= 0.05) = 0;

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

% longitudinal force per wheel
Fx_fl = (              - Tb_f - Iw_f .* domega_fl) ./ R_f;
Fx_fr = (              - Tb_f - Iw_f .* domega_fr) ./ R_f;
Fx_rl = (Td_axle ./ 2  - Tb_r - Iw_r .* domega_rl) ./ R_r;
Fx_rr = (Td_axle ./ 2  - Tb_r - Iw_r .* domega_rr) ./ R_r;

% locked wheel: pressure only sets brake capacity, so Fx is limited to sliding friction
% ASSUMPTION: sliding mu = braking mu best guess
Fx_fl(locked_fl) = max(Fx_fl(locked_fl), -vehicleParams.muX_f .* FzT(locked_fl,1));
Fx_fr(locked_fr) = max(Fx_fr(locked_fr), -vehicleParams.muX_f .* FzT(locked_fr,2));
Fx_rl(locked_rl) = max(Fx_rl(locked_rl), -vehicleParams.muX_r .* FzT(locked_rl,3));
Fx_rr(locked_rr) = max(Fx_rr(locked_rr), -vehicleParams.muX_r .* FzT(locked_rr,4));

%% force calcs bicycle model
% ASSUMPTION: left and right tires on an axle lumped into one axle force, the front axle force in the frame of the
%             mean front road wheel angle delta (the Ackermann difference between the two front frames is ignored here)
% ASSUMPTION: Iz = 1000 is a placeholder, rdot term scales directly with it
% TODO: measure Iz, CdA

% longitudinal, axle sums of the wheel forces (tire frame)
Fxf = Fx_fl + Fx_fr;
Fxr = Fx_rl + Fx_rr;

% lateral, yaw moment balance (vehicle frame) -> front into the steered tire frame
% Fyf, Fyr are THE axle lateral forces used downstream (slip observers, tire_fit.m, tire_fz_plots.m)
Fyf_vehicle = (m .* lr .* ay_tire + Iz .* rdot) ./ L;
Fyr         = (m .* lf .* ay_tire - Iz .* rdot) ./ L;

Fyf = (Fyf_vehicle - Fxf .* sin(delta)) ./ cos(delta);

% check: wheel forces vs force balance (Rezaeian eq 10)
Fdrag    = 0.5 .* rho .* vehicleParams.CdA .* Fvx .* abs(Fvx);
Fgrade   = m .* g .* sin(pitch);
Fx_total = m .* Fax + Fdrag + Fgrade;

Fx_wheels = Fxf .* cos(delta) - Fyf .* sin(delta) + Fxr;

%% force balance split per tire (previous assumptions, comparison only)
% ASSUMPTION: drive (Fx_total > 0) all rear
% ASSUMPTION: braking, caliper share split by pressure bias, engine braking all rear
% ASSUMPTION: below 75 kPa (f + r) the bias is 0.53
% ASSUMPTION: each axle split evenly left/right

biasF = (Tb_f ./ R_f) ./ (Tb_f ./ R_f + Tb_r ./ R_r);
biasF(Pf + Pr < 75) = 0.53;

braking    = Fx_total < 0;
Fx_engine  = Td_axle ./ R_r;
Fx_caliper = Fx_total - Fx_engine;

overshoot = braking & Fx_caliper > 0;           % calipers can't push forward
Fx_caliper(overshoot) = 0;
Fx_engine(overshoot)  = Fx_total(overshoot);

Fxf_fb = zeros(size(Fx_total));
Fxr_fb = Fx_total;

Fxf_fb(braking) =      biasF(braking)  .* Fx_caliper(braking);
Fxr_fb(braking) = (1 - biasF(braking)) .* Fx_caliper(braking) + Fx_engine(braking);

Fx_fl_fb = Fxf_fb ./ 2;
Fx_fr_fb = Fxf_fb ./ 2;
Fx_rl_fb = Fxr_fb ./ 2;
Fx_rr_fb = Fxr_fb ./ 2;

%% slip observers: common inputs
% MPC brush tire (fbl_mpc_controller BrushTireModel), here at the observed load: per axle mu, Ca (N/rad), per tire
% Ca / 2; closed form both ways (identical to the controller's cubic inverse, checked to 1e-13 rad):
%   |Fy| = mu Fz (1 - (1 - x)^3), x = |tan(alpha)| / t_th, t_th = 3 mu Fz / Ca, mu Fz past t_th
%   alpha = atan(t_th (1 - (1 - |Fy| / (mu Fz))^(1/3)))
%   conditioning = slope / initial slope = (1 - x)^2, 0 at or past saturation
% IMU: dvy/dt = a_y - bias - vx r, bias = median(a_y - vx r) on straight running
% observers run where vx > obs.vMin, below it v_y is reset to 0

obs   = vehicleParams.obs;
obsOk = Fvx > obs.vMin & all(isfinite([Fyf, Fyr, FzT, Fwz, delta, Fay]), 2);
straight = obsOk & abs(Fwz) < 0.02 & abs(Fay) < 2;
ayBias   = median(Fay(straight) - Fvx(straight) .* Fwz(straight));
muB = obs.mu;   CaB = obs.Ca;                    % [front rear] axle brush

%% bicycle v_y observer (MPC brush at the observed axle load, full trust)
% 1 axle slip from the brush inverse at the axle Fy and observed axle Fz
% 2 v_y from each axle: vy_F = vx tan(delta - alpha_f) - lf r, vy_R = -vx tan(alpha_r) + lr r, tire model v_y = mean
% 3 predict vy(k) = vy(k-1) + (a_y - bias - vx r) Ts, correct vy = vy + (Ts / tau) (vy_T - vy), tau obs.tauB
% 4 axle slip alpha_f = delta - atan((vy + lf r)/vx), alpha_r = -atan((vy - lr r)/vx), per tire slip by dual track kinematics

aBin  = [brushInv(Fyf, FzAx(:,1), muB(1), CaB(1)), brushInv(Fyr, FzAx(:,2), muB(2), CaB(2))];
vyT_B = 0.5 .* ((Fvx .* tan(delta - aBin(:,1)) - lf .* Fwz) + (-Fvx .* tan(aBin(:,2)) + lr .* Fwz));
vy_bike_obs = vyObserver(vyT_B, ones(size(t)), obs.tauB, Fvx, Fwz, Fay, ayBias, Ts, obsOk);
alpha_f_obs = delta - atan((vy_bike_obs + lf .* Fwz) ./ max(Fvx, 1));
alpha_r_obs =       - atan((vy_bike_obs - lr .* Fwz) ./ max(Fvx, 1));
alpha_f_obs(~obsOk) = NaN;  alpha_r_obs(~obsOk) = NaN;
[VxB, VyB] = tireKin(Vx, vy_bike_obs, Fwz, dW, lf, lr, ft, rt);
alphaB = -atan2(VyB, VxB);                                % per tire slip from the bicycle observer (rad)
alphaB(~obsOk,:) = NaN;

%% lateral force per tire, two methods
% (1) normal load split (Rezaeian eqs 55-58): Fy_i = Fy_axle Fz_i / (Fz_L + Fz_R), 50 / 50 on an unloaded axle
% (2) normal load split + tire model correction: each tire's MPC brush (mu, Ca / 2, its observed Fz) at its slip from the
%     bicycle observer sets the left / right shape, the residual to the axle total is spread by the prior variance
%     (sigA + sigR |Fy_i|)^2 (axleCorrect, Jung & Choi 2018); the slip is the observer's, never the localization's
% (2) is the per tire Fy output and the input of the dual track slip observer
% ASSUMPTION: steady state, no relaxation length, no combined slip

fyShare_fl = FzT(:,1) ./ (FzT(:,1) + FzT(:,2));
fyShare_rl = FzT(:,3) ./ (FzT(:,3) + FzT(:,4));
fyShare_fl(~isfinite(fyShare_fl)) = 0.5;
fyShare_rl(~isfinite(fyShare_rl)) = 0.5;

Fy_fl = Fyf .*      fyShare_fl;
Fy_fr = Fyf .* (1 - fyShare_fl);
Fy_rl = Fyr .*      fyShare_rl;
Fy_rr = Fyr .* (1 - fyShare_rl);

Fy_b0 = zeros(numel(t), 4);                 % brush per tire at the bicycle observer slip, before the correction
for i = 1:4
    ax = ceil(i/2);
    Fy_b0(:,i) = brushFy(alphaB(:,i), FzT(:,i), muB(ax), CaB(ax) / 2);
end
Fy_b0(~isfinite(Fy_b0)) = 0;

sigA = 200;    % (N) prior uncertainty floor of each tire's brush force
sigR = 0.2;    % (-) prior uncertainty, fraction of each tire's brush force

[Fy_fl_tm, Fy_fr_tm] = axleCorrect(Fyf, Fy_b0(:,1), Fy_b0(:,2), sigA, sigR);
[Fy_rl_tm, Fy_rr_tm] = axleCorrect(Fyr, Fy_b0(:,3), Fy_b0(:,4), sigA, sigR);
Fy_tm = [Fy_fl_tm, Fy_fr_tm, Fy_rl_tm, Fy_rr_tm];
Fy_tm(~obsOk,:) = [Fy_fl(~obsOk), Fy_fr(~obsOk), Fy_rl(~obsOk), Fy_rr(~obsOk)];   % no observer slip: normal load split

%% dual track v_y observer (each tire's MPC brush at its own load)
% 1 per tire slip from the brush inverse (Ca / 2, its observed Fz) at its corrected Fy (method 2)
% 2 per tire v_y from its own kinematics: vy_i = Vx_i tan(delta_i - alpha_i) - x_i r, x_i = lf (front) or -lr (rear),
%   Vx_i = vx -/+ r t / 2, delta_i its road wheel angle (Ackermann + toe), the exact inverse of tireKin
% 3 weight w_i = conditioning_i^obs.dtPow * Fz_i / Fz_axle (a lifted or saturated tire carries no weight),
%   tire model v_y = sum(w_i vy_i) / sum(w_i), gain w_T = max over the axles of (w_L + w_R)
% 4 same IMU predict / correct as the bicycle observer with gain w_T, tau obs.tauD
% 5 per tire slip from the observed v_y through tireKin, axle slip = mean of the two tires

aTin = nan(numel(t), 4);  cTin = zeros(numel(t), 4);  vyTi = nan(numel(t), 4);  wTi = zeros(numel(t), 4);
VxC  = [Fvx - Fwz .* (ft/2), Fvx + Fwz .* (ft/2), Fvx - Fwz .* (rt/2), Fvx + Fwz .* (rt/2)];
xArm = [lf lf -lr -lr];
for i = 1:4
    ax = ceil(i/2);
    [aTin(:,i), cTin(:,i)] = brushInv(Fy_tm(:,i), FzT(:,i), muB(ax), CaB(ax) / 2);
    vyTi(:,i) = VxC(:,i) .* tan(dW(:,i) - aTin(:,i)) - xArm(i) .* Fwz;
    sh = FzT(:,i) ./ FzAx(:,ax);  sh(~isfinite(sh)) = 0.5;
    wTi(:,i) = cTin(:,i) .^ obs.dtPow .* sh;
end
vyT_D = sum(wTi .* vyTi, 2, "omitnan") ./ sum(wTi .* isfinite(vyTi), 2);
wT_D  = max([wTi(:,1) + wTi(:,2), wTi(:,3) + wTi(:,4)], [], 2);
vy_dual_obs = vyObserver(vyT_D, wT_D, obs.tauD, Fvx, Fwz, Fay, ayBias, Ts, obsOk);
[VxD, VyD] = tireKin(Vx, vy_dual_obs, Fwz, dW, lf, lr, ft, rt);
alpha_obs = -atan2(VyD, VxD);                             % observed slip angle per tire [FL FR RL RR] (rad)
alpha_obs(~obsOk,:) = NaN;
alpha_obs_ax = [mean(alpha_obs(:,1:2), 2), mean(alpha_obs(:,3:4), 2)];

%% understeer gradient (the MPC's formula), bicycle and dual track
% secant axle cornering stiffness C = |F_axle| / tan(|alpha_axle|) at the observer slip, then
% k_us = m (lr C_r - lf C_f) / (L C_f C_r), defined where vx > obs.vMin and |vx r| > obs.kAyMin
%   bicycle     axle brush (mu, Ca) at the bicycle observer axle slip and the observed axle Fz
%   dual track  each tire's brush (mu, Ca / 2) at its own observed slip and Fz, C_axle = (|F_L| + |F_R|) / tan(mean slip)
% measured reference: (alpha_f - alpha_r - offset) / a_y from the localization slips, offset = median on straights

kusOk = obsOk & abs(Fvx .* Fwz) > obs.kAyMin;
smallA = deg2rad(0.1);
C_bike = zeros(numel(t), 2);  C_dual = zeros(numel(t), 2);
aBk = [alpha_f_obs, alpha_r_obs];
for ax = 1:2
    a1 = max(abs(aBk(:,ax)), smallA);
    C_bike(:,ax) = abs(brushFy(a1, FzAx(:,ax), muB(ax), CaB(ax))) ./ tan(a1);
    aA = max(abs(alpha_obs_ax(:,ax)), smallA);
    Fs = zeros(numel(t), 1);
    for i = 2*ax-1:2*ax
        Fs = Fs + abs(brushFy(max(abs(alpha_obs(:,i)), smallA), FzT(:,i), muB(ax), CaB(ax) / 2));
    end
    C_dual(:,ax) = Fs ./ tan(aA);
end
kusFn = @(C) m .* (lr .* C(:,2) - lf .* C(:,1)) ./ (L .* C(:,1) .* C(:,2));
k_us_bike = kusFn(C_bike);  k_us_bike(~kusOk) = NaN;
k_us_dual = kusFn(C_dual);  k_us_dual(~kusOk) = NaN;
slipOff   = median(alpha_f(straight) - alpha_r(straight), "omitnan");
k_us_meas = (alpha_f - alpha_r - slipOff) ./ Fay;  k_us_meas(~kusOk) = NaN;

fprintf("slip observers (v > %g m/s), rms vs the localization: v_y bicycle %.3f, dual track %.3f m/s\n", obs.vMin, ...
    rms(vy_bike_obs(obsOk) - Fvy(obsOk), "omitnan"), rms(vy_dual_obs(obsOk) - Fvy(obsOk), "omitnan"));
fprintf("per tire slip rms vs localization slip (deg), dual track observer: %s\n", ...
    sprintf("%.2f ", rad2deg(rms(alpha_obs(obsOk,:) - alphaKin(obsOk,:), "omitnan"))));
fprintf("k_us (|vx r| > %g): median measured %.5f, bicycle %.5f, dual track %.5f; median |k - measured| bicycle %.5f, dual track %.5f\n", ...
    obs.kAyMin, median(k_us_meas, "omitnan"), median(k_us_bike, "omitnan"), median(k_us_dual, "omitnan"), ...
    median(abs(k_us_bike - k_us_meas), "omitnan"), median(abs(k_us_dual - k_us_meas), "omitnan"));

%% save data for the tire fit and the debug scripts (tire_fit.m, tire_fz_plots.m, debug_slip_angle.m, debug_slip_ratio.m)

if saveFitData
    save(fitDataFile, "t", "Fvx", "Fax", "Fay", "ay_tire", "az_road", "delta", "delta_fl", "delta_fr", "gear", "Pf", "Pr", "Fthrottle", ...
        "alpha_fl", "alpha_fr", "alpha_rl", "alpha_rr", "alpha_f", "alpha_r", ...
        "kappa_fl", "kappa_fr", "kappa_rl", "kappa_rr", ...
        "locked_fl", "locked_fr", "locked_rl", "locked_rr", ...
        "Vx_tire_fl", "Vx_tire_fr", "Vx_tire_rl", "Vx_tire_rr", ...
        "Fz_dual_obs", "Fz_dual_meas", "Fyf", "Fyr", ...
        "Fx_fl", "Fx_fr", "Fx_rl", "Fx_rr", "Fx_total", "Fx_fl_fb", "Fx_fr_fb", "Fx_rl_fb", "Fx_rr_fb", ...
        "Vw_fl", "Vw_fr", "Vw_rl", "Vw_rr", ...
        "vy_bike_obs", "vy_dual_obs", "alpha_f_obs", "alpha_r_obs", "alpha_obs", "Fy_tm", "k_us_bike", "k_us_dual", "k_us_meas", ...
        "vehicleParams");
    fprintf("tire fit data saved: %s (%d samples)\n", fitDataFile, numel(t));
end

%% plots, one window, one tab per plot

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
% leaky integral of (gage change - model change), added on top of the model
% Fz_cmp: the model filtered like the gage, used for the rate comparison

    Fz_model = fillmissing(Fz_model, "nearest");
    Fz_cmp   = fillmissing(Fz_cmp,   "nearest");
    Fz_meas  = fillmissing(Fz_meas,  "nearest");

    correction = zeros(size(Fz_model));

    for k = 2:numel(t)
        dt        = t(k) - t(k-1);
        rateError = (Fz_meas(k,:) - Fz_meas(k-1,:)) - (Fz_cmp(k,:) - Fz_cmp(k-1,:));

        correction(k,:) = tau / (tau + dt) .* (correction(k-1,:) + K .* rateError);
    end

    Fz_obs = Fz_model + correction;   % not clamped, a negative estimate is kept as the observer's true output
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


function vy = vyObserver(vyT, wT, tau, vx, r, ay, ayBias, Ts, ok)
% v_y observer: predict vy = vy + (a_y - bias - vx r) Ts, correct vy = vy + (Ts / tau) wT (vyT - vy)
% the correction uses the predicted value of the same sample; vy = 0 where ok is false (low speed or missing input)

    n  = numel(vx);
    vy = zeros(n, 1);
    for k = 2:n
        dv = (ay(k) - ayBias - vx(k) * r(k)) * Ts;
        if ~ok(k) || ~isfinite(dv), vy(k) = 0; continue, end
        vy(k) = vy(k-1) + dv;
        if isfinite(vyT(k)) && isfinite(wT(k))
            vy(k) = vy(k) + (Ts / tau) * wT(k) * (vyT(k) - vy(k));
        end
    end
    vy(~ok) = NaN;
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


function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact");
end
