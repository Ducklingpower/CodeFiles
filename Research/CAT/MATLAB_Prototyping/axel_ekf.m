%% axle_force_ekf_demo.m
% EKF for axle-level force estimation using:
%   1) measured axle normal loads from tire load sensors,
%   2) paper-style longitudinal force assumption,
%   3) steering-aware bicycle-model lateral force equations.
%
% -------------------------------------------------------------------------
% WHAT IS "MEASURED" IN THIS DEMO?
% -------------------------------------------------------------------------
% Measured / known signals (these are what your real machine would provide):
%   delta_meas   : measured front steering angle [rad]
%   ax_meas      : measured longitudinal acceleration [m/s^2]
%   ay_meas      : measured lateral acceleration [m/s^2]
%   r_meas       : measured yaw rate [rad/s]
%   Fzf_meas     : measured front axle normal load [N]
%   Fzr_meas     : measured rear axle normal load [N]
%   theta_meas   : measured or estimated pitch angle [rad] (optional here)
%
% Derived pseudo-measurements (computed ONLY from measured signals):
%   Fxf_pseudo_meas, Fxr_pseudo_meas : longitudinal axle forces from the
%                                      paper's longitudinal-friction method
%   Fyf_pseudo_meas, Fyr_pseudo_meas : lateral axle forces from the
%                                      steering-aware bicycle model
%
% Estimated signals from the EKF:
%   r_hat, Fxf_hat, Fxr_hat, Fyf_hat, Fyr_hat
%
% NOTE:
% This script uses synthetic "truth" ONLY to demonstrate performance.
% When using real CAT data, replace the synthetic measured-signal section
% with your logged measurements and keep the EKF section unchanged.

clear; clc; close all;
rng(2);

%% ------------------------------------------------------------------------
%  Vehicle parameters (replace with CAT values)
%% ------------------------------------------------------------------------
P.m  = 42000;      % mass [kg]
P.Iz = 2.2e5;      % yaw inertia [kg*m^2]
P.lf = 2.5;        % CG to front axle [m]
P.lr = 3.0;        % CG to rear axle [m]
P.L  = P.lf + P.lr;
P.g  = 9.81;       % gravity [m/s^2]

%% ------------------------------------------------------------------------
%  Simulation settings
%% ------------------------------------------------------------------------
dt = 0.05;
T  = 10;
t  = (0:dt:T)';
N  = numel(t);

%% ------------------------------------------------------------------------
%  "TRUE" axle-level signals used ONLY for demo/validation
%  In real use, you do NOT have these.
%% ------------------------------------------------------------------------
% Steering input (assumed measured)
delta_true = deg2rad(8)*sin(0.45*t) + deg2rad(3)*sin(1.2*t);

% Pitch angle used only for compensated mu_x demo
% (set K_theta = 0 below if you do not want this compensation)
theta_true = deg2rad(1.5)*sin(0.8*t).*(1 + 0.2*sin(0.1*t));

% "True" axle normal loads (in real use these come from load sensors)
Fzf_true = 0.56*P.m*P.g + 16000*sin(0.35*t) - 7000*sin(0.9*t);
Fzr_true = P.m*P.g - Fzf_true;

% True longitudinal friction utilization for demo
mu_x_true = 0.10*sin(0.25*t) + 0.06*sin(0.9*t) ...
          - 0.18*exp(-0.5*((t-9.0)/1.6).^2) ...
          + 0.14*exp(-0.5*((t-15.0)/1.8).^2);

% True longitudinal axle forces
Fxf_true = mu_x_true .* Fzf_true;
Fxr_true = mu_x_true .* Fzr_true;

% True lateral axle forces (chosen to create rich maneuvering)
Fyf_true = 50000*sin(0.42*t + 0.30) + 10000*sin(1.00*t + 0.20);
Fyr_true = 42000*sin(0.38*t)        + 12000*sin(1.10*t);

% Integrate yaw-rate dynamics to obtain truth signal
r_true = zeros(N,1);
for k = 1:N-1
    rdot_k = ( P.lf*(Fxf_true(k)*sin(delta_true(k)) + Fyf_true(k)*cos(delta_true(k))) ...
             - P.lr*Fyr_true(k) ) / P.Iz;
    r_true(k+1) = r_true(k) + dt*rdot_k;
end

% True body accelerations implied by the axle forces
ax_true = (Fxf_true.*cos(delta_true) - Fyf_true.*sin(delta_true) + Fxr_true) / P.m;
ay_true = (Fxf_true.*sin(delta_true) + Fyf_true.*cos(delta_true) + Fyr_true) / P.m;

%% ------------------------------------------------------------------------
%  Measured signals (THIS is what the EKF receives in practice)
%% ------------------------------------------------------------------------
% Sensor-noise levels (tune to your hardware)
sig.ax    = 0.12;              % [m/s^2]
sig.ay    = 0.12;              % [m/s^2]
sig.r     = 0.010;             % [rad/s]
sig.Fz    = 2500;              % [N]
sig.theta = deg2rad(0.15);     % [rad]

% Build noisy measured signals
delta_meas = delta_true;  % assume steering angle is known accurately here
ax_meas    = ax_true    + sig.ax   * randn(N,1);
ay_meas    = ay_true    + sig.ay   * randn(N,1);
r_meas     = r_true     + sig.r    * randn(N,1);
Fzf_meas   = Fzf_true   + sig.Fz   * randn(N,1);
Fzr_meas   = Fzr_true   + sig.Fz   * randn(N,1);
theta_meas = theta_true + sig.theta* randn(N,1);

%% ------------------------------------------------------------------------
%  Derived pseudo-measurements from the force-estimation methodology
%% ------------------------------------------------------------------------
% Filter measured yaw rate before differentiating
r_filt     = movmean(r_meas, 9);
rdot_meas  = gradient(r_filt, dt);

% Optional pitch compensation for longitudinal friction estimate
% mu_x_hat = (ax/g)*(1 + Delta_mu_x)
% Delta_mu_x = K_theta * integral(theta dt) when |theta| > eps_theta
K_theta   = 0.12;               % set to 0 to disable compensation
eps_theta = deg2rad(0.25);
theta_filt = movmean(theta_meas, 11);
theta_int  = zeros(N,1);
for k = 2:N
    if abs(theta_filt(k)) > eps_theta
        theta_int(k) = theta_int(k-1) + theta_filt(k)*dt;
    else
        theta_int(k) = 0;
    end
end

mu_x_pseudo_meas = (ax_meas / P.g) .* (1 + K_theta*theta_int);

% Paper-style longitudinal axle-force pseudo-measurements
Fxf_pseudo_meas = mu_x_pseudo_meas .* Fzf_meas;
Fxr_pseudo_meas = mu_x_pseudo_meas .* Fzr_meas;

% Steering-aware bicycle-model lateral pseudo-measurements
cos_delta = cos(delta_meas);
small_idx = abs(cos_delta) < 0.20;  % numerical safeguard only
cos_delta(small_idx) = 0.20 * sign(cos_delta(small_idx) + eps);

Fyf_pseudo_meas = ( P.Iz*rdot_meas + P.lr*P.m*ay_meas ...
                  - P.L*Fxf_pseudo_meas.*sin(delta_meas) ) ./ (P.L*cos_delta);

Fyr_pseudo_meas = ( P.lf*P.m*ay_meas - P.Iz*rdot_meas ) / P.L;

%% ------------------------------------------------------------------------
%  EKF setup
%  State vector:
%     x = [ r, Fxf, Fxr, Fyf, Fyr ]'
%% ------------------------------------------------------------------------
nx = 5;

x_hat  = zeros(nx,N);
P_cov  = diag([0.20, 8e4, 8e4, 8e4, 8e4].^2);
Q_cov  = diag([0.04, 1.2e4, 1.2e4, 1.2e4, 1.2e4].^2);
R_cov  = diag([sig.r, sig.ax, sig.ay, 1.8e4, 1.8e4, 2.5e4, 2.5e4].^2);

% Initial condition from measurements / pseudo-measurements
x_hat(:,1) = [ r_meas(1);
               Fxf_pseudo_meas(1);
               Fxr_pseudo_meas(1);
               Fyf_pseudo_meas(1);
               Fyr_pseudo_meas(1) ];

%% ------------------------------------------------------------------------
%  EKF loop
%% ------------------------------------------------------------------------
for k = 2:N
    % Known input at previous step
    delta_km1 = delta_meas(k-1);

    % ----- Prediction -----
    x_prev = x_hat(:,k-1);
    [x_pred, A_k] = f_state(x_prev, delta_km1, dt, P);
    P_pred = A_k * P_cov * A_k' + Q_cov;

    % ----- Measurement model -----
    delta_k = delta_meas(k);
    [z_pred, H_k] = h_meas(x_pred, delta_k, P);

    % Measurement vector fed to EKF
    z_meas = [ r_meas(k);
               ax_meas(k);
               ay_meas(k);
               Fxf_pseudo_meas(k);
               Fxr_pseudo_meas(k);
               Fyf_pseudo_meas(k);
               Fyr_pseudo_meas(k) ];

    % ----- Update -----
    S_k = H_k * P_pred * H_k' + R_cov;
    K_k = P_pred * H_k' / S_k;

    innov = z_meas - z_pred;
    x_hat(:,k) = x_pred + K_k * innov;

    I = eye(nx);
    P_cov = (I - K_k*H_k) * P_pred * (I - K_k*H_k)' + K_k*R_cov*K_k';
end

%% ------------------------------------------------------------------------
%  Estimated signals from EKF
%% ------------------------------------------------------------------------
r_hat   = x_hat(1,:)';
Fxf_hat = x_hat(2,:)';
Fxr_hat = x_hat(3,:)';
Fyf_hat = x_hat(4,:)';
Fyr_hat = x_hat(5,:)';

%% ------------------------------------------------------------------------
%  Error metrics (demo only, because truth is known here)
%% ------------------------------------------------------------------------
rmse_Fxf_pseudo = sqrt(mean((Fxf_pseudo_meas - Fxf_true).^2));
rmse_Fxr_pseudo = sqrt(mean((Fxr_pseudo_meas - Fxr_true).^2));
rmse_Fyf_pseudo = sqrt(mean((Fyf_pseudo_meas - Fyf_true).^2));
rmse_Fyr_pseudo = sqrt(mean((Fyr_pseudo_meas - Fyr_true).^2));

rmse_Fxf_ekf = sqrt(mean((Fxf_hat - Fxf_true).^2));
rmse_Fxr_ekf = sqrt(mean((Fxr_hat - Fxr_true).^2));
rmse_Fyf_ekf = sqrt(mean((Fyf_hat - Fyf_true).^2));
rmse_Fyr_ekf = sqrt(mean((Fyr_hat - Fyr_true).^2));

fprintf('\n=============================================================\n');
fprintf('RMSE comparison (pseudo-measured vs EKF-estimated)\n');
fprintf('-------------------------------------------------------------\n');
fprintf('Front longitudinal axle force  : pseudo = %8.1f N, EKF = %8.1f N\n', rmse_Fxf_pseudo, rmse_Fxf_ekf);
fprintf('Rear  longitudinal axle force  : pseudo = %8.1f N, EKF = %8.1f N\n', rmse_Fxr_pseudo, rmse_Fxr_ekf);
fprintf('Front lateral axle force       : pseudo = %8.1f N, EKF = %8.1f N\n', rmse_Fyf_pseudo, rmse_Fyf_ekf);
fprintf('Rear  lateral axle force       : pseudo = %8.1f N, EKF = %8.1f N\n', rmse_Fyr_pseudo, rmse_Fyr_ekf);
fprintf('=============================================================\n\n');

%% ------------------------------------------------------------------------
%  Plots
%% ------------------------------------------------------------------------
% Figure 1: raw measured signals vs true values (demo only)
figure;
subplot(4,1,1);
plot(t, delta_true, 'b', 'LineWidth', 1.5); hold on;
plot(t, delta_meas, '--', 'LineWidth', 1.0);
ylabel('\delta_f [rad]'); grid on;
legend('True','Measured','Location','best');
title('Known / measured input signal');

subplot(4,1,2);
plot(t, ax_true, 'b', 'LineWidth', 1.5); hold on;
plot(t, ax_meas, '.', 'MarkerSize', 4);
ylabel('a_x [m/s^2]'); grid on;
legend('True','Measured','Location','best');
title('Measured longitudinal acceleration');

subplot(4,1,3);
plot(t, ay_true, 'b', 'LineWidth', 1.5); hold on;
plot(t, ay_meas, '.', 'MarkerSize', 4);
ylabel('a_y [m/s^2]'); grid on;
legend('True','Measured','Location','best');
title('Measured lateral acceleration');

subplot(4,1,4);
plot(t, r_true, 'b', 'LineWidth', 1.5); hold on;
plot(t, r_meas, '.', 'MarkerSize', 4);
ylabel('r [rad/s]'); xlabel('Time [s]'); grid on;
legend('True','Measured','Location','best');
title('Measured yaw rate');

% Figure 2: axle normal load measurements
figure;
subplot(2,1,1);
plot(t, Fzf_true, 'b', 'LineWidth', 1.5); hold on;
plot(t, Fzf_meas, '.', 'MarkerSize', 4);
ylabel('F_{z,f} [N]'); grid on;
legend('True','Measured','Location','best');
title('Front axle normal load');

subplot(2,1,2);
plot(t, Fzr_true, 'b', 'LineWidth', 1.5); hold on;
plot(t, Fzr_meas, '.', 'MarkerSize', 4);
ylabel('F_{z,r} [N]'); xlabel('Time [s]'); grid on;
legend('True','Measured','Location','best');
title('Rear axle normal load');

% Figure 3: longitudinal axle forces
figure;
subplot(2,1,1);
plot(t, Fxf_true, 'b', 'LineWidth', 1.8); hold on;
plot(t, Fxf_pseudo_meas, 'r:', 'LineWidth', 1.2);
plot(t, Fxf_hat, 'g', 'LineWidth', 1.4);
ylabel('F_{x,f} [N]'); grid on;
legend('True force (demo only)','Pseudo-measured from method','EKF estimated','Location','best');
title('Front longitudinal axle force');

subplot(2,1,2);
plot(t, Fxr_true, 'b', 'LineWidth', 1.8); hold on;
plot(t, Fxr_pseudo_meas, 'r:', 'LineWidth', 1.2);
plot(t, Fxr_hat, 'g', 'LineWidth', 1.4);
ylabel('F_{x,r} [N]'); xlabel('Time [s]'); grid on;
legend('True force (demo only)','Pseudo-measured from method','EKF estimated','Location','best');
title('Rear longitudinal axle force');

% Figure 4: lateral axle forces
figure;
subplot(2,1,1);
plot(t, Fyf_true, 'b', 'LineWidth', 1.8); hold on;
plot(t, Fyf_pseudo_meas, 'r:', 'LineWidth', 1.2);
plot(t, Fyf_hat, 'g', 'LineWidth', 1.4);
ylabel('F_{y,f} [N]'); grid on;
legend('True force (demo only)','Pseudo-measured from method','EKF estimated','Location','best');
title('Front lateral axle force');

subplot(2,1,2);
plot(t, Fyr_true, 'b', 'LineWidth', 1.8); hold on;
plot(t, Fyr_pseudo_meas, 'r:', 'LineWidth', 1.2);
plot(t, Fyr_hat, 'g', 'LineWidth', 1.4);
ylabel('F_{y,r} [N]'); xlabel('Time [s]'); grid on;
legend('True force (demo only)','Pseudo-measured from method','EKF estimated','Location','best');
title('Rear lateral axle force');

% Figure 5: yaw-rate state estimate
figure;
plot(t, r_true, 'b', 'LineWidth', 1.8); hold on;
plot(t, r_meas, '.', 'MarkerSize', 4);
plot(t, r_hat, 'g', 'LineWidth', 1.4);
ylabel('r [rad/s]'); xlabel('Time [s]'); grid on;
legend('True state (demo only)','Measured yaw rate','EKF estimated state','Location','best');
title('Yaw-rate state in the EKF');

%% ------------------------------------------------------------------------
%  Local functions
%% ------------------------------------------------------------------------
function [x_next, A] = f_state(x, delta, dt, P)
% Nonlinear state transition
% x = [r; Fxf; Fxr; Fyf; Fyr]
    r   = x(1);
    Fxf = x(2);
    Fxr = x(3);
    Fyf = x(4);
    Fyr = x(5);

    rdot = ( P.lf*(Fxf*sin(delta) + Fyf*cos(delta)) - P.lr*Fyr ) / P.Iz;

    x_next = [ r + dt*rdot;
               Fxf;
               Fxr;
               Fyf;
               Fyr ];

    % Jacobian A = df/dx
    A = eye(5);
    A(1,2) = dt * P.lf * sin(delta) / P.Iz;
    A(1,4) = dt * P.lf * cos(delta) / P.Iz;
    A(1,5) = -dt * P.lr / P.Iz;
end

function [z_pred, H] = h_meas(x, delta, P)
% Measurement model
% z = [r_meas; ax_meas; ay_meas; Fxf_pseudo; Fxr_pseudo; Fyf_pseudo; Fyr_pseudo]
    r   = x(1);
    Fxf = x(2);
    Fxr = x(3);
    Fyf = x(4);
    Fyr = x(5);

    ax = (Fxf*cos(delta) - Fyf*sin(delta) + Fxr) / P.m;
    ay = (Fxf*sin(delta) + Fyf*cos(delta) + Fyr) / P.m;

    z_pred = [ r;
               ax;
               ay;
               Fxf;
               Fxr;
               Fyf;
               Fyr ];

    % Jacobian H = dh/dx
    H = [ 1,                  0,          0,                  0,          0;
          0,  cos(delta)/P.m,      1/P.m, -sin(delta)/P.m,          0;
          0,  sin(delta)/P.m,          0,  cos(delta)/P.m,      1/P.m;
          0,                  1,          0,                  0,          0;
          0,                  0,          1,                  0,          0;
          0,                  0,          0,                  1,          0;
          0,                  0,          0,                  0,          1 ];
end
