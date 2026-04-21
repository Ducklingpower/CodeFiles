%% CAT force estimation demo
% Fake-measurement demo for:
% 1) Corner normal load estimation using load transfer + strut pressure fusion
% 2) Axle force estimation using a bicycle model
%
% This script is intentionally transparent:
% - "true" signals are generated from a known analytic model
% - "fake measurements" are created by adding sensor noise
% - the estimator uses those fake measurements only
% - plots compare truth vs estimate

clear; clc; close all;
rng(10);

%% -----------------------------
% Parameters (CAT-style naming)
%% -----------------------------
P.m      = 42000;      % vehicle mass [kg]
P.g      = 9.81;       % gravity [m/s^2]
P.a      = 2.20;       % CG to front axle [m]
P.b      = 2.80;       % CG to rear axle [m]
P.L      = P.a + P.b;  % wheelbase [m]
P.h_cg   = 1.65;       % CG height [m]
P.tf     = 2.60;       % front track [m]
P.tr     = 2.60;       % rear track [m]
P.lambda_f = 0.55;     % fraction of lateral transfer at front
P.lambda_r = 0.45;     % fraction of lateral transfer at rear
P.Iz     = 1.25e5;     % yaw inertia [kg*m^2]

% Simple resistance model used for "truth"
P.Crr = 0.018;         % rolling resistance coefficient
P.CdA = 7.5;           % aero lump [m^2]
rho_air = 1.225;       % [kg/m^3]

%% -----------------------------
% Time
%% -----------------------------
dt = 0.02;
T  = 30;
t  = (0:dt:T)';
N  = numel(t);

%% -----------------------------
% Generate true motion signals
%% -----------------------------
u_true     = 8 + 2*sin(0.12*t) + 0.5*cos(0.31*t);         % long speed [m/s]
delta_true = deg2rad(4*sin(0.35*t));                      % steer angle [rad]
ax_true    = 0.55*sin(0.55*t) + 0.20*cos(0.12*t);         % body long accel [m/s^2]
ay_true    = 1.10*sin(0.40*t + 0.4) + 0.25*cos(0.90*t);   % body lat accel [m/s^2]
rdot_true  = ( (P.a+P.b) * 0 + 1 ); %#ok<NASGU>
rdot_true  = ((P.a + P.b)*0);                              % placeholder
% choose yaw-acceleration truth consistent with lateral force balance
rdot_true  = 0.22*sin(0.40*t + 0.4) + 0.07*cos(0.90*t);   % [rad/s^2]
r_true     = cumtrapz(t, rdot_true);                       % [rad/s]

%% -----------------------------
% True corner normal loads from load transfer
%% -----------------------------
Fzf_true = (P.b/P.L)*P.m*P.g - (P.m*P.h_cg/P.L).*ax_true;
Fzr_true = (P.a/P.L)*P.m*P.g + (P.m*P.h_cg/P.L).*ax_true;

dFzy_f_true = P.lambda_f*(P.m*P.h_cg/P.tf).*ay_true;
dFzy_r_true = P.lambda_r*(P.m*P.h_cg/P.tr).*ay_true;

FzFL_true = 0.5*Fzf_true - 0.5*dFzy_f_true;
FzFR_true = 0.5*Fzf_true + 0.5*dFzy_f_true;
FzRL_true = 0.5*Fzr_true - 0.5*dFzy_r_true;
FzRR_true = 0.5*Fzr_true + 0.5*dFzy_r_true;

%% -----------------------------
% True axle forces
%% -----------------------------
Fyf_true = (P.b*P.m.*ay_true + P.Iz.*rdot_true)./(P.a + P.b);
Fyr_true = (P.a*P.m.*ay_true - P.Iz.*rdot_true)./(P.a + P.b);

F_res_true = P.Crr*P.m*P.g + 0.5*rho_air*P.CdA.*(u_true.^2);
Fxtot_true = P.m.*ax_true + Fyf_true.*sin(delta_true) + F_res_true;

gamma_f_true = Fzf_true ./ (Fzf_true + Fzr_true);
gamma_r_true = 1 - gamma_f_true;
Fxf_true = gamma_f_true .* Fxtot_true;
Fxr_true = gamma_r_true .* Fxtot_true;

%% -----------------------------
% Create fake measurements
%% -----------------------------
ax_meas    = ax_true    + 0.006*randn(N,1);
ay_meas    = ay_true    + 0.008*randn(N,1);
r_meas     = r_true     + 0.001*randn(N,1);
rdot_meas  = rdot_true  + 0.003*randn(N,1);
delta_meas = delta_true + deg2rad(0.15)*randn(N,1);
u_meas     = u_true     + 0.008*randn(N,1);

% Fake strut pressure measurements:
% p_i = c_i * Fz_i + d_i + noise
cFL = 1.40e-6; dFL = 0.15;
cFR = 1.45e-6; dFR = 0.12;
cRL = 1.35e-6; dRL = 0.18;
cRR = 1.38e-6; dRR = 0.16;

pFL_meas = cFL*FzFL_true + dFL + 0.0010*randn(N,1);
pFR_meas = cFR*FzFR_true + dFR + 0.0010*randn(N,1);
pRL_meas = cRL*FzRL_true + dRL + 0.0010*randn(N,1);
pRR_meas = cRR*FzRR_true + dRR + 0.010*randn(N,1);

% Pressure-only load reconstructions (what calibration gives back)
FzFL_fromP = (pFL_meas - dFL)/cFL;
FzFR_fromP = (pFR_meas - dFR)/cFR;
FzRL_fromP = (pRL_meas - dRL)/cRL;
FzRR_fromP = (pRR_meas - dRR)/cRR;

%% -----------------------------
% Normal-load estimator
% Simple first-order observer / complementary fusion
% This is EKF-ready, but kept simple for demo transparency.
%% -----------------------------
tau_z = 0.20;  % estimator time constant [s]
Kp = dt/max(tau_z,dt);

FzFL_est = zeros(N,1); FzFR_est = zeros(N,1);
FzRL_est = zeros(N,1); FzRR_est = zeros(N,1);

% initialize from calibrated pressure measurements
FzFL_est(1) = FzFL_fromP(1);
FzFR_est(1) = FzFR_fromP(1);
FzRL_est(1) = FzRL_fromP(1);
FzRR_est(1) = FzRR_fromP(1);

for k = 2:N
    Fzf_qs = (P.b/P.L)*P.m*P.g - (P.m*P.h_cg/P.L)*ax_meas(k);
    Fzr_qs = (P.a/P.L)*P.m*P.g + (P.m*P.h_cg/P.L)*ax_meas(k);

    dFzy_f_qs = P.lambda_f*(P.m*P.h_cg/P.tf)*ay_meas(k);
    dFzy_r_qs = P.lambda_r*(P.m*P.h_cg/P.tr)*ay_meas(k);

    FzFL_qs = 0.5*Fzf_qs - 0.5*dFzy_f_qs;
    FzFR_qs = 0.5*Fzf_qs + 0.5*dFzy_f_qs;
    FzRL_qs = 0.5*Fzr_qs - 0.5*dFzy_r_qs;
    FzRR_qs = 0.5*Fzr_qs + 0.5*dFzy_r_qs;

    % prediction toward quasi-static model + correction from pressure
    FzFL_pred = FzFL_est(k-1) + Kp*(FzFL_qs - FzFL_est(k-1));
    FzFR_pred = FzFR_est(k-1) + Kp*(FzFR_qs - FzFR_est(k-1));
    FzRL_pred = FzRL_est(k-1) + Kp*(FzRL_qs - FzRL_est(k-1));
    FzRR_pred = FzRR_est(k-1) + Kp*(FzRR_qs - FzRR_est(k-1));

    alpha = 0.35; % pressure correction weight
    FzFL_est(k) = (1-alpha)*FzFL_pred + alpha*FzFL_fromP(k);
    FzFR_est(k) = (1-alpha)*FzFR_pred + alpha*FzFR_fromP(k);
    FzRL_est(k) = (1-alpha)*FzRL_pred + alpha*FzRL_fromP(k);
    FzRR_est(k) = (1-alpha)*FzRR_pred + alpha*FzRR_fromP(k);
end

Fzf_est = FzFL_est + FzFR_est;
Fzr_est = FzRL_est + FzRR_est;

%% -----------------------------
% Axle lateral force estimator (bicycle model)
%% -----------------------------
Fyf_est = (P.b*P.m.*ay_meas + P.Iz.*rdot_meas)./((P.a + P.b).*cos(delta_meas));
Fyr_est = (P.a*P.m.*ay_meas - P.Iz.*rdot_meas)./(P.a + P.b);

%% -----------------------------
% Axle longitudinal force estimator
%% -----------------------------
F_res_est = P.Crr*P.m*P.g + 0.5*rho_air*P.CdA.*(u_meas.^2);
Fxtot_est = P.m.*ax_meas + Fyf_est.*sin(delta_meas) + F_res_est;

gamma_f_est = Fzf_est ./ (Fzf_est + Fzr_est);
gamma_r_est = 1 - gamma_f_est;

Fxf_est = gamma_f_est .* Fxtot_est;
Fxr_est = gamma_r_est .* Fxtot_est;

%% -----------------------------
% Error metrics
%% -----------------------------
rmse = @(xhat,x) sqrt(mean((xhat-x).^2));

fprintf('\n=== RMSE summary ===\n');
fprintf('FzFL: %.1f N\n', rmse(FzFL_est,FzFL_true));
fprintf('FzFR: %.1f N\n', rmse(FzFR_est,FzFR_true));
fprintf('FzRL: %.1f N\n', rmse(FzRL_est,FzRL_true));
fprintf('FzRR: %.1f N\n', rmse(FzRR_est,FzRR_true));
fprintf('Fy_front axle: %.1f N\n', rmse(Fyf_est,Fyf_true));
fprintf('Fy_rear  axle: %.1f N\n', rmse(Fyr_est,Fyr_true));
fprintf('Fx_front axle: %.1f N\n', rmse(Fxf_est,Fxf_true));
fprintf('Fx_rear  axle: %.1f N\n', rmse(Fxr_est,Fxr_true));
fprintf('Fx_total: %.1f N\n\n', rmse(Fxtot_est,Fxtot_true));

%% -----------------------------
% Plots
%% -----------------------------
figure;
plot(t, ax_meas); hold on;
plot(t, ay_meas);
plot(t, rdot_meas);
grid on;
xlabel('Time [s]');
ylabel('Signal');
title('Fake measurements used by estimator');
legend('a_x fake meas','a_y fake meas','r_dot fake meas','Location','best');

figure;
plot(t, FzFL_true); hold on;
plot(t, FzFL_est, '--');
plot(t, FzFR_true);
plot(t, FzFR_est, '--');
grid on;
xlabel('Time [s]');
ylabel('Load [N]');
title('Front corner normal loads: truth vs estimate');
legend('FzFL true','FzFL est','FzFR true','FzFR est','Location','best');

figure;
plot(t, FzRL_true); hold on;
plot(t, FzRL_est, '--');
plot(t, FzRR_true);
plot(t, FzRR_est, '--');
grid on;
xlabel('Time [s]');
ylabel('Load [N]');
title('Rear corner normal loads: truth vs estimate');
legend('FzRL true','FzRL est','FzRR true','FzRR est','Location','best');

figure;
plot(t, Fyf_true); hold on;
plot(t, Fyf_est, '--');
plot(t, Fyr_true);
plot(t, Fyr_est, '--');
grid on;
xlabel('Time [s]');
ylabel('Force [N]');
title('Axle lateral forces from bicycle model');
legend('Fy front true','Fy front est','Fy rear true','Fy rear est','Location','best');

figure;
plot(t, Fxf_true); hold on;
plot(t, Fxf_est, '--');
plot(t, Fxr_true);
plot(t, Fxr_est, '--');
grid on;
xlabel('Time [s]');
ylabel('Force [N]');
title('Axle longitudinal forces');
legend('Fx front true','Fx front est','Fx rear true','Fx rear est','Location','best');

figure;
plot(t, Fxtot_true); hold on;
plot(t, Fxtot_est);
grid on;
xlabel('Time [s]');
ylabel('Force [N]');
title('Total longitudinal resultant');
legend('Fx total true','Fx total est','Location','best');

%% -----------------------------
% Optional: package estimated signals
%% -----------------------------
est.t = t;
est.FzFL_est = FzFL_est; est.FzFR_est = FzFR_est;
est.FzRL_est = FzRL_est; est.FzRR_est = FzRR_est;
est.Fyf_est = Fyf_est;   est.Fyr_est = Fyr_est;
est.Fxf_est = Fxf_est;   est.Fxr_est = Fxr_est;
est.Fxtot_est = Fxtot_est;

truth.FzFL_true = FzFL_true; truth.FzFR_true = FzFR_true;
truth.FzRL_true = FzRL_true; truth.FzRR_true = FzRR_true;
truth.Fyf_true = Fyf_true;   truth.Fyr_true = Fyr_true;
truth.Fxf_true = Fxf_true;   truth.Fxr_true = Fxr_true;
truth.Fxtot_true = Fxtot_true;