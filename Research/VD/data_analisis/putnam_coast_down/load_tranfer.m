clc
close all
clear
%% opening csv

% data = readtable('FastLaps.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/putnam/oversteer/2026-04-28_150159_merged.csv');
data = readtable('/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv');
%% filtered data

mm =5;
Ft = movmean(data.time_s,mm);

Fax = movmean(data.a_x,mm);
Fay = movmean(data.a_y,mm);
Faz = movmean(data.a_z,mm);

Ffz_fr = data.fr_load_n;
Ffz_fl = data.fl_load_n;
Ffz_rr = data.rr_load_n;
Ffz_rl = data.rl_load_n;

Ffz_fr = movmean(data.fr_load_n,mm);
Ffz_fl = movmean(data.fl_load_n,mm);
Ffz_rr = movmean(data.rr_load_n,mm);
Ffz_rl = movmean(data.rl_load_n,mm);

Fvx = movmean(data.odom_vx_mps,mm);
Fvy = movmean(data.odom_vy_mps,mm);

Frpm = movmean(data.engine_rpm,mm);
throttle = data.throttle_pct;
Fgear = movmean(data.current_gear,mm);
FT_e = movmean(data.est_drive_torque_nm,mm);
Fbrake = movmean(data.front_brake_pressure_kpa,mm);

steering_wheel = movmean(data.steer_wheel_ang_deg,mm); 
toe_angle = 0.333+(steering_wheel)/15.015;
toe_rad = toe_angle*(pi/180);

Fqx = movmean(data.odom_qx,mm);
Fqy = movmean(data.odom_qy,mm);
Fqz = movmean(data.odom_qz,mm);
Fqw = movmean(data.odom_qw,mm);

Fwz = movmean(data.odom_wz_rads,mm);
Fwx = movmean(data.odom_wx_rads,mm);
Fwy = -movmean(data.odom_wy_rads,mm);



Fq = [Fqw Fqx Fqy Fqz];         
Feul = quat2eul(Fq, 'ZYX');   % [yaw pitch roll]

Fyaw   = Feul(:,1);
Fpitch = -Feul(:,2);
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




%% getting yaw, pitch, and roll curvature

t = data.time_s(:);
t = t - t(1);


V = sqrt(Fvx.^2 + Fvy.^2);
ds = [0; cumsum(0.5 * (V(1:end-1) + V(2:end)) .* diff(t))];

v_min_curv = 2.0;

% Curvature
kappa_yaw   = nan(size(V));
kappa_pitch = nan(size(V));
kappa_roll  = nan(size(V));

curv_valid = isfinite(V) & V > v_min_curv;

kappa_yaw(curv_valid)   = yaw_dot(curv_valid)   ./ V(curv_valid);
kappa_pitch(curv_valid) = pitch_dot(curv_valid) ./ V(curv_valid);
kappa_roll(curv_valid)  = roll_dot(curv_valid)  ./ V(curv_valid);






%% params 
vehicleParams.wheelbase   = 2.9718;      % wheelbase (m)  [2971.8 mm]
vehicleParams.w_dist_f    = 0.42;        % front weight distribution [42%]
vehicleParams.t_f         = 1.638762;    % front track (m)  [1638.762 mm]
vehicleParams.t_r         = 1.5239686;   % rear track (m)   [1523.9686 mm]

% Wheel rates computed from springs & motion ratios at 0 mm:
% avg stiffness*(motion_ratio)^2

vehicleParams.wheelRate_f = 2.985553732e5;  % (N/m)
vehicleParams.wheelRate_r = 3.941321827e5;  % (N/m)

vehicleParams.ARB_f       = 0;             % (Nm/deg)  TBD
vehicleParams.ARB_r       = 0;              % (Nm/deg)  no anti roll bar in rear

vehicleParams.cg_z        = 0.275;          % CG height (m)  [275 mm]
vehicleParams.rc_f        = 0.1202436;      % roll center front (m) 
vehicleParams.rc_r        = 0.0016628;      % roll center rear  (m) 

vehicleParams.toe_f       = -0.451;         % toe front (deg, - = out) 
vehicleParams.toe_r       = -0.451;         % toe rear  (deg, - = out)

vehicleParams.m           = 815;            % vehicle mass (kg)  [base vehicle mass]

vehicleParams.mech_trail_f = 0;             % mech trail front (m) TBD
vehicleParams.mech_trail_r = 0;             % mech trail rear  (m) TBD

vehicleParams.frontalArea = 1 ;             % frontal area (m^2) TBD
vehicleParams.Cd          = 0.0;            % drag coeff (-)     TBD
vehicleParams.Cl          = 0.0;            % ift coeff (-)      TBD
vehicleParams.ACd         = 0.58;           % Area*coef down force      TBD
vehicleParams.aeroBalance = .33;            % frontal aero load (-) 33% avg
vehicleParams.copShift    = 0;              % balance shift with Vx (%/(m/s))TBD
vehicleParams.inertia     = 1000;           % moment of inertia

%% load tranfer calcs


L  = vehicleParams.wheelbase;
b  = vehicleParams.w_dist_f * L;        
a  = L - b;            
m  = vehicleParams.m;
cgh = vehicleParams.cg_z;

%basic load tranfer 
fz_f_basic = ((a*m*9.81)/(L) - (m*Fax*cgh)/L);
fz_r_basic = ((b*m*9.81)/(L) + (m*Fax*cgh)/L);

front_axle = (Ffz_fl + Ffz_fr)/2 + 1750/2;
rear_axle = (Ffz_rr + Ffz_rl)/2 -1700/2;



% CONSIDER CURVATURE 
aero_balance = 0.33;
scalar = 0.5
down_force = 0.5 * 0.58 * 1.225 .* Fvx.^2;

front_aero = aero_balance .* down_force;
rear_aero  = (1 - aero_balance) .* down_force;

L = a + b;   % assuming a = lf, b = lr

az_road = ...
    9.81 .* cos(Fpitch) .* cos(Froll) ...
    + Fvx .* Fwz .* sin(Froll) ...
    + Fvx .* Fwy*scalar;

long_transfer_accel = ...
    Fax + 9.81 .* sin(Fpitch);

fz_f_curvature = ...
    a .* (m .* az_road) ./ L ...
    - (m .* long_transfer_accel .* cgh) ./ L ...
    + front_aero;

fz_r_curvature = ...
    b .* (m .* az_road) ./ L ...
    + (m .* long_transfer_accel .* cgh) ./ L ...
    + rear_aero;

figure 
tiledlayout(3,1)
nexttile
plot(t,front_axle)
hold on
plot(t,fz_f_basic)
hold on
plot(t,fz_f_curvature,LineWidth=2)

legend("front measured","front basic calc","front 3D calc")


nexttile
plot(t,rear_axle)
hold on
plot(t,fz_r_basic)
hold on
plot(t,fz_r_curvature,LineWidth=2)
legend("rear measured","rear basic calc","rear 3D calc")

nexttile
plot(t,Ffz_fr)
hold on
plot(t,Ffz_fl)



%% Observer Bycicle model


Fz_front_meas = front_axle;
Fz_rear_meas = rear_axle;


Fz_front_model = fz_f_curvature;
Fz_rear_model = fz_r_curvature;


% measured and model
Fz_meas = [Fz_front_meas Fz_rear_meas];
Fz_model = [Fz_front_model Fz_rear_model];

% gains

K_front = 0.05;
K_rear  = 0.05;
K = [K_front K_rear];

N = length(t);

Fz_hat = zeros(N,2);

% IC
Fz_hat(1,:) = 0;

for k = 2:N

    % model step
    model_delta = Fz_model(k,:) - Fz_model(k-1,:);

    % Prediction step
    Fz_pred = Fz_hat(k-1,:) + model_delta;

    error = Fz_meas(k,:) - Fz_pred;

    Fz_hat(k,:) = Fz_pred + K .* error;

    Fz_hat(k,:) = max(Fz_hat(k,:), 0);
end

% Split observer outputs
Fz_front_obs = Fz_hat(:,1);
Fz_rear_obs = Fz_hat(:,2);





figure
tiledlayout(2,1, 'TileSpacing', 'compact', 'Padding', 'compact')

axs = gobjects(4,1);

axs(1) = nexttile;
plot(t, front_axle, 'LineWidth', 1);
hold on
plot(t, fz_f_curvature, 'LineWidth', 1.5);
plot(t, Fz_front_obs, 'LineWidth', 1.5);
legend("front measured", "front model", "front observer")
title("Front")
ylabel("F_z [N]")
grid on

axs(2) = nexttile;
plot(t, rear_axle, 'LineWidth', 1);
hold on
plot(t, fz_r_curvature, 'LineWidth', 1.5);
plot(t, Fz_rear_obs, 'LineWidth', 1.5);
legend("rear measured", "rear model", "rear observer")
title("rear")
ylabel("F_z [N]")
grid on

linkaxes(axs, 'x')


%% doal track load tranfer 

% split laterally 


w_dist_f = vehicleParams.w_dist_f;
rc_f = vehicleParams.rc_f;                
rc_r = vehicleParams.rc_r;                 
wheelRate_f = vehicleParams.wheelRate_f;    
wheelRate_r = vehicleParams.wheelRate_r;    
t_f = vehicleParams.t_f;                    
t_r = vehicleParams.t_r;                  
ARB_f = vehicleParams.ARB_f;                


w = m*9.81;                                                      %Vehcile weight (N)
cg2rollAxis = cgh -((1-w_dist_f)*(rc_r-rc_f) + rc_f);
l_a = (1 - w_dist_f) * L;                           
l_b = L - l_a;                                       
k_phi_f = ((wheelRate_f *(t_f^2))/2) + (ARB_f);   
k_phi_r = ((wheelRate_r *(t_r^2))/2) + (0);       
LAT_weightTransferGradient_f = (w/t_f) * ((cg2rollAxis * k_phi_f)/(k_phi_f + k_phi_r) + (l_b * rc_f/L));
LAT_weightTransferGradient_r = (w/t_r) * ((cg2rollAxis * k_phi_r)/(k_phi_f + k_phi_r) + (l_a * rc_r/L));



% figure 
% plot(t,LAT_weightTransferGradient_f*(Fay/9.81),"r")
% hold on
% plot(t,LAT_weightTransferGradient_r*(Fay/9.81),"b")
% legend("front load tranfer in (N)","rear load tranfer N")


Fz_fr = fz_f_curvature + LAT_weightTransferGradient_f * (Fay/9.81);
Fz_fl = fz_f_curvature - LAT_weightTransferGradient_f* (Fay/9.81);

Fz_rr = fz_r_curvature + LAT_weightTransferGradient_r* (Fay/9.81);
Fz_rl = fz_r_curvature - LAT_weightTransferGradient_r* (Fay/9.81);




figure
tiledlayout(2,2)

axs = gobjects(4,1);

axs(1) = nexttile;
plot(t, Ffz_fl + 800);
hold on
plot(t, Fz_fl, 'LineWidth', 2);
legend("Fl measured","Fl est")
title("Front Left")
grid on

axs(2) = nexttile;
plot(t, Ffz_fr + 800);
hold on
plot(t, Fz_fr, 'LineWidth', 2);
legend("Fr measured","Fr est")
title("Front Right")
grid on

axs(3) = nexttile;
plot(t, Ffz_rl - 900);
hold on
plot(t, Fz_rl, 'LineWidth', 2);
legend("Rl measured","Rl est")
title("Rear Left")
grid on
xlabel("Time [s]")

axs(4) = nexttile;
plot(t, Ffz_rr - 900);
hold on
plot(t, Fz_rr, 'LineWidth', 2);
legend("Rr measured","Rr est")
title("Rear Right")
grid on
xlabel("Time [s]")

linkaxes(axs, 'x')

%% Observer dual track 


Fz_fl_meas = Ffz_fl + 800;
Fz_fr_meas = Ffz_fr + 800;
Fz_rl_meas = Ffz_rl - 900;
Fz_rr_meas = Ffz_rr - 900;

Fz_fl_model = Fz_fl;
Fz_fr_model = Fz_fr;
Fz_rl_model = Fz_rl;
Fz_rr_model = Fz_rr;

% measured and model
Fz_meas = [Fz_fl_meas, Fz_fr_meas, Fz_rl_meas, Fz_rr_meas];
Fz_model = [Fz_fl_model, Fz_fr_model, Fz_rl_model, Fz_rr_model];

% gains
K_fl = 0.05;
K_fr = 0.05;
K_rl = 0.05;
K_rr = 0.05;

K = [K_fl, K_fr, K_rl, K_rr];


N = length(t);

Fz_hat = zeros(N,4);

% IC
Fz_hat(1,:) = 0;

for k = 2:N

    % model step
    model_delta = Fz_model(k,:) - Fz_model(k-1,:);

    % Prediction step
    Fz_pred = Fz_hat(k-1,:) + model_delta;

    error = Fz_meas(k,:) - Fz_pred;

    Fz_hat(k,:) = Fz_pred + K .* error;

    Fz_hat(k,:) = max(Fz_hat(k,:), 0);
end

% Split observer outputs
Fz_fl_obs = Fz_hat(:,1);
Fz_fr_obs = Fz_hat(:,2);
Fz_rl_obs = Fz_hat(:,3);
Fz_rr_obs = Fz_hat(:,4);




figure
tiledlayout(2,2, 'TileSpacing', 'compact', 'Padding', 'compact')

axs = gobjects(4,1);

axs(1) = nexttile;
plot(t, Fz_fl_meas, 'LineWidth', 1);
hold on
plot(t, Fz_fl_model, 'LineWidth', 1.5);
plot(t, Fz_fl_obs, 'LineWidth', 1.5);
legend("FL measured", "FL model", "FL observer")
title("Front Left")
ylabel("F_z [N]")
grid on

axs(2) = nexttile;
plot(t, Fz_fr_meas, 'LineWidth', 1);
hold on
plot(t, Fz_fr_model, 'LineWidth', 1.5);
plot(t, Fz_fr_obs, 'LineWidth', 1.5);
legend("FR measured", "FR model", "FR observer")
title("Front Right")
ylabel("F_z [N]")
grid on

axs(3) = nexttile;
plot(t, Fz_rl_meas, 'LineWidth', 1);
hold on
plot(t, Fz_rl_model, 'LineWidth', 1.5);
plot(t, Fz_rl_obs, 'LineWidth', 1.5);
legend("RL measured", "RL model", "RL observer")
title("Rear Left")
xlabel("Time [s]")
ylabel("F_z [N]")
grid on

axs(4) = nexttile;
plot(t, Fz_rr_meas, 'LineWidth', 1);
hold on
plot(t, Fz_rr_model, 'LineWidth', 1.5);
plot(t, Fz_rr_obs, 'LineWidth', 1.5);
legend("RR measured", "RR model", "RR observer")
title("Rear Right")
xlabel("Time [s]")
ylabel("F_z [N]")
grid on

linkaxes(axs, 'x')





%% 

%% BICYCLE NORMAL LOAD OBSERVER



Fz_front_meas = front_axle;
Fz_rear_meas  = rear_axle;

% gains
obs.K_front = 0.03;     
obs.K_rear  = 0.03;     

% Optional: limit how fast bias can change [N/sample]
% This prevents the observer from chasing spikes too aggressively.
% obs.max_bias_step_front = 2000;
% obs.max_bias_step_rear  = 2000;

% Observer state
obs.bias_hat = [0, 0];          % [front_bias, rear_bias]
obs.Fz_hat   = [NaN, NaN];      % [front_Fz_hat, rear_Fz_hat]
obs.Fz_model = [NaN, NaN];      % [front_Fz_model, rear_Fz_model]

N = length(t);

% set verctors
Fz_front_obs  = zeros(N,1);
Fz_rear_obs   = zeros(N,1);
Fz_front_model_online = zeros(N,1);
Fz_rear_model_online  = zeros(N,1);
bias_front_log = zeros(N,1);
bias_rear_log  = zeros(N,1);


% IC
input0.Fax    = Fax(1);
input0.Fpitch = Fpitch(1);
input0.Froll  = Froll(1);
input0.Fvx    = Fvx(1);
input0.Fwz    = Fwz(1);
input0.Fwy    = Fwy(1);

meas0 = [Fz_front_meas(1), Fz_rear_meas(1)];

[obs, out0] = bicycleFzObserverUpdate(obs, input0, meas0, vehicleParams);

Fz_front_obs(1) = out0.Fz_hat(1);
Fz_rear_obs(1)  = out0.Fz_hat(2);

Fz_front_model_online(1) = out0.Fz_model(1);
Fz_rear_model_online(1)  = out0.Fz_model(2);

bias_front_log(1) = obs.bias_hat(1);
bias_rear_log(1)  = obs.bias_hat(2);

% observer loop
for k = 2:N

    input_k.Fax    = Fax(k);
    input_k.Fpitch = Fpitch(k);
    input_k.Froll  = Froll(k);
    input_k.Fvx    = Fvx(k);
    input_k.Fwz    = Fwz(k);
    input_k.Fwy    = Fwy(k);

    % current measurment
    meas_k = [Fz_front_meas(k), Fz_rear_meas(k)];

    % Observer update.
    [obs, out] = bicycleFzObserverUpdate(obs, input_k, meas_k, vehicleParams);

    % Store outputs.
    Fz_front_obs(k) = out.Fz_hat(1);
    Fz_rear_obs(k)  = out.Fz_hat(2);

    Fz_front_model_online(k) = out.Fz_model(1);
    Fz_rear_model_online(k)  = out.Fz_model(2);

    bias_front_log(k) = obs.bias_hat(1);
    bias_rear_log(k)  = obs.bias_hat(2);
end

% =========================
% Plot observer result
% =========================
figure
tiledlayout(3,1, 'TileSpacing', 'compact', 'Padding', 'compact')

ax1 = nexttile;
plot(t, Fz_front_meas, 'LineWidth', 1)
hold on
% plot(t, Fz_front_model_online, 'LineWidth', 1.5)
plot(t, Fz_front_obs, 'LineWidth', 2)
legend("front measured", "front model online", "front observer")
title("Front Axle Normal Load Observer")
ylabel("F_z [N]")
grid on

ax2 = nexttile;
plot(t, Fz_rear_meas, 'LineWidth', 1)
hold on
% plot(t, Fz_rear_model_online, 'LineWidth', 1.5)
plot(t, Fz_rear_obs, 'LineWidth', 2)
legend("rear measured", "rear model online", "rear observer")
title("Rear Axle Normal Load Observer")
ylabel("F_z [N]")
grid on

ax3 = nexttile;
plot(t, bias_front_log, 'LineWidth', 1.5)
hold on
plot(t, bias_rear_log, 'LineWidth', 1.5)
legend("front model bias", "rear model bias")
title("Estimated Model Bias")
xlabel("Time [s]")
ylabel("Bias [N]")
grid on

linkaxes([ax1 ax2 ax3], 'x')


%% =========================
% LOCAL FUNCTIONS
% Put these at the bottom of your MATLAB script.
% =========================

function [obs, out] = bicycleFzObserverUpdate(obs, input, meas, vehicleParams)

% Inputs:
%   obs.bias_hat = estimated model bias [front, rear]
%   input        = current measured vehicle signals
%   meas         = current measured axle loads [front, rear]
%   vehicleParams = vehicle parameters
%
% Output:
%   Fz_hat = model load + estimated model bias


    % 1. Compute model prediction for this current sample only
    Fz_model = bicycleFzModelStep(input, vehicleParams);

    % 2. Predict measurement using current model plus old bias estimate
    Fz_pred = Fz_model + obs.bias_hat;

    % 3. Measurement residual
    error = meas - Fz_pred;

    % 4. Bias observer correction
    bias_step_front = obs.K_front * error(1);
    bias_step_rear  = obs.K_rear  * error(2);

    obs.bias_hat(1) = obs.bias_hat(1) + bias_step_front;
    obs.bias_hat(2) = obs.bias_hat(2) + bias_step_rear;

    % 5. Final corrected normal load estimate
    Fz_hat = Fz_model + obs.bias_hat;

    % Normal load should not go negative
    Fz_hat = max(Fz_hat, [0, 0]);

    obs.Fz_hat   = Fz_hat;
    obs.Fz_model = Fz_model;

    out.Fz_hat   = Fz_hat;
    out.Fz_model = Fz_model;
    out.error    = error;
end


function Fz_model = bicycleFzModelStep(input, vehicleParams)
% bicycleFzModelStep
%
% Computes front/rear axle normal load for one time step.
% This is the model that would run inside the observer at every sample.

    g = 9.81;

    L   = vehicleParams.wheelbase;
    wf  = vehicleParams.w_dist_f;
    m   = vehicleParams.m;
    hcg = vehicleParams.cg_z;

    % Distance definitions matching your current script
    b = wf * L;
    a = L - b;

    % Aero
    rho = 1.225;
    aero_balance = vehicleParams.aeroBalance;
    down_force = 0.5 * vehicleParams.ACd * rho * input.Fvx^2;

    front_aero = aero_balance * down_force;
    rear_aero  = (1 - aero_balance) * down_force;

    % Same scalar idea from your current script
    scalar = 0.5;

    % Effective vertical acceleration / road normal acceleration model
    az_road = ...
        g * cos(input.Fpitch) * cos(input.Froll) ...
        + input.Fvx * input.Fwz * sin(input.Froll) ...
        + input.Fvx * input.Fwy * scalar;

    % Longitudinal load-transfer acceleration
    long_transfer_accel = input.Fax + g * sin(input.Fpitch);

    % Front/rear axle normal load model
    Fz_front_model = ...
        a * (m * g) / L ...
        - (m * long_transfer_accel * hcg) / L ...
        + front_aero;

    Fz_rear_model = ...
        b * (m * g) / L ...
        + (m * long_transfer_accel * hcg) / L ...
        + rear_aero;

    Fz_model = [Fz_front_model, Fz_rear_model];
end










%%%%


%% BICYCLE NORMAL LOAD RATE-BASED OBSERVER
% This observer does NOT trust the absolute strain-gage normal force.
% It only uses the CHANGE in strain-gage force from sample to sample.
%
% Absolute Fz comes from the model.
% Dynamic load-transfer correction comes from strain-gage delta.

% ---------------------------------------------------------
% Use raw strain-gage axle signals here if possible.
% Do NOT manually add constant offsets for this observer.
% The offset mostly cancels when taking differences.
% ---------------------------------------------------------
Fz_front_strain = (Ffz_fl + Ffz_fr) / 2;
Fz_rear_strain  = (Ffz_rl + Ffz_rr) / 2;

% If you still want to use your already-created signals, use this instead:
% Fz_front_strain = front_axle;
% Fz_rear_strain  = rear_axle;

N = length(t);

% ---------------------------------------------------------
% Initialize observer
% ---------------------------------------------------------
obs = initBicycleFzRateObserver();

% Storage
Fz_front_obs  = zeros(N,1);
Fz_rear_obs   = zeros(N,1);

Fz_front_model_online = zeros(N,1);
Fz_rear_model_online  = zeros(N,1);

corr_front_log = zeros(N,1);
corr_rear_log  = zeros(N,1);

dFz_front_meas_log  = zeros(N,1);
dFz_rear_meas_log   = zeros(N,1);
dFz_front_model_log = zeros(N,1);
dFz_rear_model_log  = zeros(N,1);

rate_error_front_log = zeros(N,1);
rate_error_rear_log  = zeros(N,1);

% ---------------------------------------------------------
% Observer loop
% ---------------------------------------------------------
for k = 1:N

    % Current model inputs
    input_k.Fax    = Fax(k);
    input_k.Fpitch = Fpitch(k);
    input_k.Froll  = Froll(k);
    input_k.Fvx    = Fvx(k);
    input_k.Fwz    = Fwz(k);
    input_k.Fwy    = Fwy(k);

    % Current raw strain-gage measurement
    % Absolute value is not trusted.
    % Only change from previous sample is used.
    meas_k = [Fz_front_strain(k), Fz_rear_strain(k)];

    % Observer update
    [obs, out] = bicycleFzRateObserverUpdate(obs, input_k, meas_k, vehicleParams);

    % Store outputs
    Fz_front_obs(k) = out.Fz_hat(1);
    Fz_rear_obs(k)  = out.Fz_hat(2);

    Fz_front_model_online(k) = out.Fz_model(1);
    Fz_rear_model_online(k)  = out.Fz_model(2);

    corr_front_log(k) = out.dynamic_correction(1);
    corr_rear_log(k)  = out.dynamic_correction(2);

    dFz_front_meas_log(k)  = out.dFz_meas(1);
    dFz_rear_meas_log(k)   = out.dFz_meas(2);

    dFz_front_model_log(k) = out.dFz_model(1);
    dFz_rear_model_log(k)  = out.dFz_model(2);

    rate_error_front_log(k) = out.rate_error(1);
    rate_error_rear_log(k)  = out.rate_error(2);
end

% ---------------------------------------------------------
% For plotting only:
% align strain-gage signals to the model initial value.
% This does NOT affect the observer.
% It just helps visualize shape/load-transfer agreement.
% ---------------------------------------------------------
Fz_front_strain_aligned = Fz_front_strain - Fz_front_strain(1) + Fz_front_model_online(1);
Fz_rear_strain_aligned  = Fz_rear_strain  - Fz_rear_strain(1)  + Fz_rear_model_online(1);

% ---------------------------------------------------------
% Plot observer result
% ---------------------------------------------------------
figure
tiledlayout(4,1, 'TileSpacing', 'compact', 'Padding', 'compact')

ax1 = nexttile;
plot(t, Fz_front_model_online, 'LineWidth', 1.2)
hold on
plot(t, Fz_front_obs, 'LineWidth', 2)
plot(t, Fz_front_strain_aligned,Color="red")
legend("front model", "front rate observer", "front strain aligned for visual only")
title("Front Axle Rate-Based Normal Load Observer")
ylabel("F_z [N]")
grid on

ax2 = nexttile;
plot(t, Fz_rear_model_online, 'LineWidth', 1.2)
hold on
plot(t, Fz_rear_obs, 'LineWidth', 2)
plot(t, Fz_rear_strain_aligned, '--', 'LineWidth', 1)
legend("rear model", "rear rate observer", "rear strain aligned for visual only")
title("Rear Axle Rate-Based Normal Load Observer")
ylabel("F_z [N]")
grid on

ax3 = nexttile;
plot(t, corr_front_log, 'LineWidth', 1.5)
hold on
plot(t, corr_rear_log, 'LineWidth', 1.5)
legend("front dynamic correction", "rear dynamic correction")
title("Observer Dynamic Correction")
ylabel("Correction [N]")
grid on

ax4 = nexttile;
plot(t, rate_error_front_log, 'LineWidth', 1.2)
hold on
plot(t, rate_error_rear_log, 'LineWidth', 1.2)
legend("front delta error", "rear delta error")
title("Delta Error: Measured Load Transfer Change - Model Load Transfer Change")
xlabel("Time [s]")
ylabel("\Delta F_z Error [N/sample]")
grid on

linkaxes([ax1 ax2 ax3 ax4], 'x')




function obs = initBicycleFzRateObserver()
% initBicycleFzRateObserver
%
% This observer trusts the model for absolute normal load.
% It only uses strain-gage measurements for dynamic change/load transfer.
%
% State:
%   obs.dynamic_correction = correction added to model [front, rear]
%
% Estimate:
%   Fz_hat = Fz_model + dynamic_correction
%
% Correction:
%   dFz_meas  = strain_meas(k) - strain_meas(k-1)
%   dFz_model = Fz_model(k) - Fz_model(k-1)
%   error     = dFz_meas - dFz_model
%
%   dynamic_correction = leak * dynamic_correction + K * error

    % Observer gain
    % Larger = follows strain-gage dynamic load transfer more aggressively.
    % Smaller = trusts model more.
    obs.K_front = 0.03;
    obs.K_rear  = 1;

    % Leakage prevents the correction from becoming a fake offset.
    % 1.00 = correction can persist forever
    % 0.99 = slow decay back toward model
    % 0.95 = faster decay back toward model
    obs.leak = 0.995;

    % Optional limit on correction step per sample [N/sample]
    % This prevents spikes in strain gage from causing large jumps.
    obs.max_correction_step_front = 150;
    obs.max_correction_step_rear  = 150;

    % Optional total correction limit [N]
    % This keeps observer from drifting too far from physics model.
    obs.max_total_correction_front = 1500;
    obs.max_total_correction_rear  = 1500;

    % Internal state
    obs.dynamic_correction = [0, 0];

    obs.prev_meas  = [NaN, NaN];
    obs.prev_model = [NaN, NaN];

    obs.Fz_hat   = [NaN, NaN];
    obs.Fz_model = [NaN, NaN];

    obs.initialized = false;
end


function [obs, out] = bicycleFzRateObserverUpdate(obs, input, meas, vehicleParams)
% bicycleFzRateObserverUpdate
%
% Inputs:
%   obs           = observer state
%   input         = current vehicle/model inputs
%   meas          = raw strain-gage axle measurements [front, rear]
%   vehicleParams = vehicle parameters
%
% Outputs:
%   out.Fz_hat = model normal load + dynamic correction

    meas = meas(:).';

    % ---------------------------------------------------------
    % 1. Compute model prediction for current sample
    % ---------------------------------------------------------
    Fz_model = bicycleFzModelStep_test(input, vehicleParams);
    Fz_model = Fz_model(:).';

    % ---------------------------------------------------------
    % 2. First sample initialization
    % ---------------------------------------------------------
    if ~obs.initialized
        obs.prev_meas  = meas;
        obs.prev_model = Fz_model;

        obs.dynamic_correction = [0, 0];

        Fz_hat = Fz_model;

        obs.Fz_hat   = Fz_hat;
        obs.Fz_model = Fz_model;
        obs.initialized = true;

        out.Fz_hat = Fz_hat;
        out.Fz_model = Fz_model;
        out.dynamic_correction = obs.dynamic_correction;
        out.dFz_meas = [0, 0];
        out.dFz_model = [0, 0];
        out.rate_error = [0, 0];

        return
    end

    % ---------------------------------------------------------
    % 3. Compare measured change vs model change
    % ---------------------------------------------------------
    dFz_meas  = meas     - obs.prev_meas;
    dFz_model = Fz_model - obs.prev_model;

    rate_error = dFz_meas/0.01 - dFz_model/0.01;

    % ---------------------------------------------------------
    % 4. Observer correction based on load-transfer change
    % ---------------------------------------------------------
    correction_step_front = obs.K_front * rate_error(1);
    correction_step_rear  = obs.K_rear  * rate_error(2);

    % Limit correction step to reject spikes
    correction_step_front = clampValue( ...
        correction_step_front, ...
        -obs.max_correction_step_front, ...
         obs.max_correction_step_front);

    correction_step_rear = clampValue( ...
        correction_step_rear, ...
        -obs.max_correction_step_rear, ...
         obs.max_correction_step_rear);

    % Apply leakage so correction does not become a drifting offset
    obs.dynamic_correction(1) = obs.leak * obs.dynamic_correction(1) + correction_step_front;
    obs.dynamic_correction(2) = obs.leak * obs.dynamic_correction(2) + correction_step_rear;

    % Limit total correction
    obs.dynamic_correction(1) = clampValue( ...
        obs.dynamic_correction(1), ...
        -obs.max_total_correction_front, ...
         obs.max_total_correction_front);

    obs.dynamic_correction(2) = clampValue( ...
        obs.dynamic_correction(2), ...
        -obs.max_total_correction_rear, ...
         obs.max_total_correction_rear);

    % ---------------------------------------------------------
    % 5. Final normal load estimate
    % ---------------------------------------------------------
    Fz_hat = Fz_model + obs.dynamic_correction;

    % Normal load cannot be negative
    Fz_hat = max(Fz_hat, [0, 0]);

    % ---------------------------------------------------------
    % 6. Store previous values for next sample
    % ---------------------------------------------------------
    obs.prev_meas  = meas;
    obs.prev_model = Fz_model;

    obs.Fz_hat   = Fz_hat;
    obs.Fz_model = Fz_model;

    % ---------------------------------------------------------
    % 7. Output
    % ---------------------------------------------------------
    out.Fz_hat = Fz_hat;
    out.Fz_model = Fz_model;
    out.dynamic_correction = obs.dynamic_correction;
    out.dFz_meas = dFz_meas;
    out.dFz_model = dFz_model;
    out.rate_error = rate_error;
end


function Fz_model = bicycleFzModelStep_test(input, vehicleParams)
% bicycleFzModelStep
%
% Computes front/rear axle normal load for one time step.
% This is the model baseline that the observer trusts for absolute force.

    g = 9.81;

    L   = vehicleParams.wheelbase;
    wf  = vehicleParams.w_dist_f;
    m   = vehicleParams.m;
    hcg = vehicleParams.cg_z;

    % Distance definitions
    b = wf * L;
    a = L - b;

    % Aero
    rho = 1.225;
    aero_balance = vehicleParams.aeroBalance;
    down_force = 0.5 * vehicleParams.ACd * rho * input.Fvx^2;

    front_aero = aero_balance * down_force;
    rear_aero  = (1 - aero_balance) * down_force;

    % Effective road-normal acceleration model
    scalar = 0.5;

    az_road = ...
        g * cos(input.Fpitch) * cos(input.Froll) ...
        + input.Fvx * input.Fwz * sin(input.Froll) ...
        + input.Fvx * input.Fwy * scalar;

    % Longitudinal load-transfer acceleration
    long_transfer_accel = input.Fax + g * sin(input.Fpitch);

    % Front/rear axle normal load model
    Fz_front_model = ...
        a * (m * g) / L ...
        - (m * long_transfer_accel * hcg) / L ...
        + front_aero;

    Fz_rear_model = ...
        b * (m * g) / L ...
        + (m * long_transfer_accel * hcg) / L ...
        + rear_aero;

    Fz_model = [Fz_front_model, Fz_rear_model];
end


function y = clampValue(x, xmin, xmax)
% clampValue
% Limits x between xmin and xmax.

    y = min(max(x, xmin), xmax);
end



