clc
close all
clear
% vehicle model foundation - bicycle and dual track
% model reference: brake_anylisis/notmal_force_estimation.m

%% settings

dataFile      = "/home/elijah/bag_files/VD/laguna/comp/2025-07-24_175839_merged.csv";
engineMapFile = "/home/elijah/PurdueRacing/on-vehicle/on-vehicle/src/control/acceleration_interface/config/engine_map_30psi.csv";

mm         = 15;        % moving average window [samples], used by every signal
timeWindow = [0 Inf];   % [s] from start of recording
vxMin      = 4;         % [m/s] slip is NaN below this speed

%% load file

data  = readtable(dataFile);
t_all = data.time_s - data.time_s(1);

% engine map: rows rpm, columns throttle fraction from the header
mapLines    = readlines(engineMapFile);
mapThrottle = str2double(split(mapLines(1), ","))';
mapThrottle = mapThrottle(2:end);
engineMap   = readmatrix(engineMapFile, "NumHeaderLines", 1);

engineTorque = griddedInterpolant({engineMap(:,1), mapThrottle}, engineMap(:,2:end), "linear", "nearest");

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
vehicleParams.R_f         = 0.30;           % front loaded radius (m), R_r from wheel speeds

vehicleParams.steerRatio  = 15.015;         % steering wheel -> road wheel
vehicleParams.steerOffset = 0.333;          % road wheel angle offset (deg)

vehicleParams.ClA         = 0.58;           % downforce area*coef (m^2)
vehicleParams.CdA         = 1.33;           % drag area*coef (m^2)
vehicleParams.aeroBal_f   = 0.33;           % front share of downforce (-)
vehicleParams.rho         = 1.225;          % air density (kg/m^3)

vehicleParams.brakeGain_f = 1.0;            % axle brake torque per kPa, only f/r ratio matters
vehicleParams.brakeGain_r = 1.0;
vehicleParams.brakeBias_default   = 0.53;   % front force bias when pressure is too low to read
vehicleParams.brakePressureMin    = 75;     % (kPa) f + r

vehicleParams.staticCornerLoad = [1679, 1679, 2318.6, 2318.6];   % [FL FR RL RR] (N) - corner scales

g = 9.81;

%% wheel speed calibration (full recording, free rolling)
% free rolling wheel has zero slip, so each wheel speed must read ground speed

vx_cal = movmean(data.odom_vx_mps, mm);

freeRolling = abs(movmean(data.a_x, mm))                 < 0.6 ...
            & abs(movmean(data.a_y, mm))                 < 0.5 ...
            & abs(movmean(data.steer_wheel_ang_deg, mm)) < 2   ...
            & movmean(data.front_brake_pressure_kpa, mm) < 60  ...
            & movmean(data.rear_brake_pressure_kpa,  mm) < 60  ...
            & vx_cal > 12;

wheelCh  = ["fl_speed_kmh", "fr_speed_kmh", "rl_speed_kmh", "rr_speed_kmh"];
wheelCal = ones(1,4);

if sum(freeRolling) >= 300
    for i = 1:4
        vw = movmean(data.(wheelCh(i)), mm) ./ 3.6;
        wheelCal(i) = mean(vw(freeRolling) ./ vx_cal(freeRolling), "omitnan");
    end
else
    warning("only %d free rolling samples, wheel speeds left uncalibrated", sum(freeRolling));
end

vehicleParams.R_r = vehicleParams.R_f * mean(wheelCal(1:2)) / mean(wheelCal(3:4));

%% strain gage zero (full recording)

gageZero = movmean([data.fl_load_n, data.fr_load_n, data.rl_load_n, data.rr_load_n], mm);
gageZero = gageZero(min(100, height(data)), :);

gageOffset = gageZero - vehicleParams.staticCornerLoad;

%% time window

keep = t_all >= timeWindow(1) & t_all <= timeWindow(2);
data = data(keep, :);
t    = t_all(keep);

%% filtered signals

Fvx   = movmean(data.odom_vx_mps,  mm);
Fvy   = movmean(data.odom_vy_mps,  mm);
Fwz   = movmean(data.odom_wz_rads, mm);

Fax   = movmean(data.a_x, mm);
Faz   = movmean(data.a_z, mm);   
steer = movmean(data.steer_wheel_ang_deg, mm);
Pf    = movmean(data.front_brake_pressure_kpa, mm);
Pr    = movmean(data.rear_brake_pressure_kpa,  mm);

Frpm      = movmean(data.engine_rpm,   mm);
Fthrottle = movmean(data.throttle_pct, mm);

Vw_fl = movmean(data.fl_speed_kmh, mm) ./ 3.6 ./ wheelCal(1);
Vw_fr = movmean(data.fr_speed_kmh, mm) ./ 3.6 ./ wheelCal(2);
Vw_rl = movmean(data.rl_speed_kmh, mm) ./ 3.6 ./ wheelCal(3);
Vw_rr = movmean(data.rr_speed_kmh, mm) ./ 3.6 ./ wheelCal(4);

Fz_fl_meas = movmean(data.fl_load_n, mm) - gageOffset(1);
Fz_fr_meas = movmean(data.fr_load_n, mm) - gageOffset(2);
Fz_rl_meas = movmean(data.rl_load_n, mm) - gageOffset(3);
Fz_rr_meas = movmean(data.rr_load_n, mm) - gageOffset(4);

Fq    = movmean([data.odom_qw, data.odom_qx, data.odom_qy, data.odom_qz], mm);
Feul  = quat2eul(Fq, "ZYX");   % [yaw pitch roll]
pitch = -Feul(:,2);
roll  =  Feul(:,3);

%% geometry

m   = vehicleParams.m;
L   = vehicleParams.wheelbase;
lf  = (1 - vehicleParams.w_dist_f) * L;   % CG -> front axle (long one, car is rear heavy)
lr  = vehicleParams.w_dist_f * L;         % CG -> rear axle
h   = vehicleParams.cg_z;
ft  = vehicleParams.t_f;
rt  = vehicleParams.t_r;
Iz  = vehicleParams.Iz;
R_f = vehicleParams.R_f;
R_r = vehicleParams.R_r;
rho = vehicleParams.rho;

delta = deg2rad(vehicleParams.steerOffset + steer ./ vehicleParams.steerRatio);

%% accelerations at the tires
% a_x, a_y, a_z channels are gravity compensated, gravity is added back here

dt = gradient(t);
dt(dt <= 0) = median(dt(dt > 0));

dvy_dt = movmean(gradient(Fvy) ./ dt, mm);
rdot   = movmean(gradient(Fwz) ./ dt, mm);

g_y_body = -g .* cos(pitch) .* sin(roll);

ay_tire  = Fvx .* Fwz + dvy_dt - g_y_body;          % lateral, bank corrected
ax_long  = Fax + g .* sin(pitch);                   % longitudinal, grade included
az_road  = g .* cos(pitch) .* cos(roll) + Faz;      % normal, bank/grade + crest/dip

%% tire frame velocities

Vx = Fvx;
Vx(abs(Vx) < vxMin) = NaN;

Vw_front = 0.5 .* (Vw_fl + Vw_fr);
Vw_rear  = 0.5 .* (Vw_rl + Vw_rr);

Vx_fl_c = Vx - Fwz .* (ft/2);
Vx_fr_c = Vx + Fwz .* (ft/2);
Vx_rl_c = Vx - Fwz .* (rt/2);
Vx_rr_c = Vx + Fwz .* (rt/2);

Vy_front_c = Fvy + Fwz .* lf;
Vy_rear_c  = Fvy - Fwz .* lr;

% Front corners are rotated into the steered tire frame.
Vx_tire_fl =  Vx_fl_c .* cos(delta) + Vy_front_c .* sin(delta);
Vx_tire_fr =  Vx_fr_c .* cos(delta) + Vy_front_c .* sin(delta);
Vx_tire_rl =  Vx_rl_c;
Vx_tire_rr =  Vx_rr_c;

Vy_tire_fl = -Vx_fl_c .* sin(delta) + Vy_front_c .* cos(delta);
Vy_tire_fr = -Vx_fr_c .* sin(delta) + Vy_front_c .* cos(delta);
Vy_tire_rl =  Vy_rear_c;
Vy_tire_rr =  Vy_rear_c;

%% slip angles

alpha_fl = -atan2(Vy_tire_fl, Vx_tire_fl);
alpha_fr = -atan2(Vy_tire_fr, Vx_tire_fr);
alpha_rl = -atan2(Vy_tire_rl, Vx_tire_rl);
alpha_rr = -atan2(Vy_tire_rr, Vx_tire_rr);

% bicycle, per axle
alpha_f = delta - atan2(Vy_front_c, Vx);
alpha_r =       - atan2(Vy_rear_c,  Vx);

%% slip ratios sx sy (wheel speed referenced)

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

%% force calcs bicycle model
% ASSUMPTION: left and right tires on an axle lumped into one axle force
% ASSUMPTION: Iz = 1000 is a placeholder, rdot term scales directly with it
% ASSUMPTION: no rolling resistance
% ASSUMPTION: drive (Fx > 0) is all rear wheels, RWD
% ASSUMPTION: braking split by line pressure only, equal brake hardware f/r (brakeGain = 1)
% ASSUMPTION: below brakePressureMin the bias is a fixed default (0.53)
% ASSUMPTION: engine braking is all rear, only the caliper share is split by bias
% ASSUMPTION: engine torque -> rear force by power balance, lossless driveline
% ASSUMPTION: throttle below 5% (after removing the idle reading) is closed, map 0 column
% ASSUMPTION: map 0 throttle column is the true motoring torque
% TODO: zero pressure check, caliper force should be ~0 N at 0 kPa
% TODO: Fx_total ignores the Fyf*sin(delta) steered-front term (circular with Fyf, needs fixed point)
% TODO: measure Iz, brake gains, CdA

% lateral, yaw moment balance (vehicle frame)
Fyf_vehicle = (m .* lr .* ay_tire + Iz .* rdot) ./ L;
Fyr         = (m .* lf .* ay_tire - Iz .* rdot) ./ L;

% longitudinal, force balance
Fdrag    = 0.5 .* rho .* vehicleParams.CdA .* Fvx .* abs(Fvx);
Fgrade   = m .* g .* sin(pitch);
Fx_total = m .* Fax + Fdrag + Fgrade;

% brake bias, line pressure -> force at the ground
brakeForce_f = vehicleParams.brakeGain_f .* Pf ./ R_f;
brakeForce_r = vehicleParams.brakeGain_r .* Pr ./ R_r;

biasF = brakeForce_f ./ (brakeForce_f + brakeForce_r);
biasF(Pf + Pr < vehicleParams.brakePressureMin) = vehicleParams.brakeBias_default;
biasF = min(max(biasF, 0), 1);

% engine braking, T*omega_engine = F*Vw_rear
throttleIdle  = prctile(Fthrottle, 1);
throttle_frac = max(0, (Fthrottle - throttleIdle) ./ (100 - throttleIdle));
throttle_frac(throttle_frac <= 0.05) = 0;

T_engine  = engineTorque(Frpm, throttle_frac);
Fx_engine = T_engine .* (Frpm .* 2*pi/60) ./ Vw_rear;
Fx_engine(Vw_rear < 2 | ~isfinite(Fx_engine)) = 0;

% drive is all rear (RWD), braking: caliper split by bias, engine all rear
braking = Fx_total < 0;

Fx_caliper = Fx_total - Fx_engine;
engineOvershoot = braking & Fx_caliper > 0;     % calipers can't push forward
Fx_caliper(engineOvershoot) = 0;
Fx_engine(engineOvershoot)  = Fx_total(engineOvershoot);

Fxf = zeros(size(Fx_total));
Fxr = Fx_total;

Fxf(braking) =      biasF(braking)  .* Fx_caliper(braking);
Fxr(braking) = (1 - biasF(braking)) .* Fx_caliper(braking) + Fx_engine(braking);

% front lateral force into the steered tire frame
Fyf = (Fyf_vehicle - Fxf .* sin(delta)) ./ cos(delta);

%% normal forces bicycle model
% ASSUMPTION: rigid body pitch transfer, m*ax*h/L, no suspension dynamics
% ASSUMPTION: CG height 0.35 m (past ~0.5 m the axle that runs out of grip first flips)
% ASSUMPTION: aero balance fixed at 33% front, no ride height or speed shift
% ASSUMPTION: no aero drag pitching moment
% TODO: measure cg_z and aero balance

downforce = 0.5 .* rho .* vehicleParams.ClA .* Fvx.^2;
aeroBal_f = vehicleParams.aeroBal_f;

Fz_f = m .* az_road .* lr ./ L - m .* ax_long .* h ./ L +      aeroBal_f  .* downforce;
Fz_r = m .* az_road .* lf ./ L + m .* ax_long .* h ./ L + (1 - aeroBal_f) .* downforce;

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

latTransfer_f = m .* ay_tire ./ ft .* (h_roll *      rollShare_f  + lr * rc_f / L);
latTransfer_r = m .* ay_tire ./ rt .* (h_roll * (1 - rollShare_f) + lf * rc_r / L);

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
% ASSUMPTION: gage bias drifts slowly, so its rate is trustworthy but its level is not
% TODO: tune K and tau

K   = 1.5;   % gain on (gage rate - model rate)
tau = 1.0;   % (s) correction decays back to the model

Fz_bike_meas  = [Fz_fl_meas + Fz_fr_meas, Fz_rl_meas + Fz_rr_meas];
Fz_bike_model = [Fz_f, Fz_r];
Fz_bike_obs   = fzDerivativeObserver(Fz_bike_model, Fz_bike_meas, t, K, tau);

Fz_dual_meas  = [Fz_fl_meas, Fz_fr_meas, Fz_rl_meas, Fz_rr_meas];
Fz_dual_model = [Fz_fl, Fz_fr, Fz_rl, Fz_rr];
Fz_dual_obs   = fzDerivativeObserver(Fz_dual_model, Fz_dual_meas, t, K, tau);

%% plots bicycle model forces

figure("Name", "Bicycle model forces");
tl = tiledlayout(2, 1, "TileSpacing", "compact");

axF(1) = nexttile(tl);
hold on
plot(t, Fxf);
plot(t, Fxr);
grid on
title("Longitudinal");
ylabel("F_x [N]");
legend("front", "rear", "Location", "best");

axF(2) = nexttile(tl);
hold on
plot(t, Fyf);
plot(t, Fyr);
grid on
title("Lateral (front in tire frame)");
ylabel("F_y [N]");
legend("front", "rear", "Location", "best");

xlabel(tl, "Time [s]");
linkaxes(axF, "x");

%% plots normal force observers

names =["FL", "FR", "RL", "RR", "Front axle", "Rear axle"];
meas  = [Fz_dual_meas,  Fz_bike_meas];
model = [Fz_dual_model, Fz_bike_model];
obs   = [Fz_dual_obs,   Fz_bike_obs];

figure("Name", "Normal force observers");
tl = tiledlayout(3, 2, "TileSpacing", "compact");
ax = gobjects(6,1);

for i = 1:6
    ax(i) = nexttile(tl);
    hold on
    plot(t, meas(:,i),  "Color", [0.90 0.55 0.55]);
    plot(t, model(:,i));
    plot(t, obs(:,i));
    grid on
    title(names(i));
    ylabel("F_z [N]");
end

legend(ax(1), "gage (zeroed)", "model", "observer", "Location", "best");
xlabel(tl, "Time [s]");
linkaxes(ax, "x");


function Fz_obs = fzDerivativeObserver(Fz_model, Fz_meas, t, K, tau)
% leaky integral of (gage change - model change), added on top of the model

    Fz_model = fillmissing(Fz_model, "nearest");
    Fz_meas  = fillmissing(Fz_meas,  "nearest");

    correction = zeros(size(Fz_model));

    for k = 2:numel(t)
        dt        = t(k) - t(k-1);
        rateError = (Fz_meas(k,:) - Fz_meas(k-1,:)) - (Fz_model(k,:) - Fz_model(k-1,:));

        correction(k,:) = tau / (tau + dt) .* (correction(k-1,:) + K .* rateError);
    end

    Fz_obs = max(Fz_model + correction, 0);
end
