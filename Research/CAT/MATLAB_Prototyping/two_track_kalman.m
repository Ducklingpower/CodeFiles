%% two_track_force_compare_demo.m

clear; clc; close all;

%% -----------------------------
% Vehicle parameters
%% -----------------------------
m   = 1800;        % mass [kg]
Iz  = 2500;        % yaw inertia [kg*m^2]
a   = 1.40;        % CG to front axle [m]
b   = 1.60;        % CG to rear axle [m]
tf  = 1.60;        % front track width [m]
tr  = 1.60;        % rear track width [m]
Rw  = 0.32;        % effective wheel radius [m]

%% -----------------------------
% Simulation settings
%% -----------------------------
dt = 0.001;
T  = 20;
N  = round(T/dt);
t  = (0:N-1)'*dt;

%% -----------------------------
% Allocate fake input/measured signals
%% -----------------------------
vx_meas = 15 + 0.5*sin(0.5*t);                 
vy_meas = 0.5*sin(1.2*t);                      
r_meas  = 0.15*sin(0.8*t);                     

% NOTE:
% In your original script these were multiplied by zero.
% I leave them nonzero here so the yaw/lateral problem is a bit better excited.
delta_fl = deg2rad(4)*sin(0.7*t);              
delta_fr = deg2rad(4)*sin(0.7*t);              

% Fake normal loads with longitudinal and lateral transfer effects
g = 9.81;
Fz_static_f = m*g*b/(a+b)/2;
Fz_static_r = m*g*a/(a+b)/2;

ax_true_for_load = 1.2*sin(0.9*t);             
ay_true_for_load = 2.0*sin(0.8*t);             

h_cg = 0.65;                                   

dFz_long_front = -(m*h_cg./(a+b))*ax_true_for_load/2;
dFz_long_rear  = +(m*h_cg./(a+b))*ax_true_for_load/2;

dFz_lat_front  =  (m*h_cg/tf)*(b/(a+b))*ay_true_for_load/2;
dFz_lat_rear   =  (m*h_cg/tr)*(a/(a+b))*ay_true_for_load/2;

Fz_fl = Fz_static_f + dFz_long_front - dFz_lat_front;
Fz_fr = Fz_static_f + dFz_long_front + dFz_lat_front;
Fz_rl = Fz_static_r + dFz_long_rear  - dFz_lat_rear;
Fz_rr = Fz_static_r + dFz_long_rear  + dFz_lat_rear;

% Ensure no negative loads in fake data
Fz_fl = max(Fz_fl, 500);
Fz_fr = max(Fz_fr, 500);
Fz_rl = max(Fz_rl, 500);
Fz_rr = max(Fz_rr, 500);

%% -----------------------------
% Generate fake "true" tire forces
%% -----------------------------
Fx_fl_true =  300*sin(0.6*t);
Fx_fr_true =  320*sin(0.6*t + 0.1);
Fx_rl_true =  500*sin(0.6*t + 0.05);
Fx_rr_true =  520*sin(0.6*t + 0.12);

Fy_fl_true =  1800*sin(0.8*t);
Fy_fr_true =  1700*sin(0.8*t + 0.08);
Fy_rl_true =  1200*sin(0.8*t - 0.04);
Fy_rr_true =  1150*sin(0.8*t + 0.03);

x_true = [Fx_fl_true Fx_fr_true Fx_rl_true Fx_rr_true ...
          Fy_fl_true Fy_fr_true Fy_rl_true Fy_rr_true]';

%% -----------------------------
% Build fake measured accelerations from rigid body equations
%% -----------------------------
ax_meas = zeros(N,1);
ay_meas = zeros(N,1);
rzdot_meas = zeros(N,1);

for k = 1:N
    xt = x_true(:,k);

    Fx_fl = xt(1); Fx_fr = xt(2); Fx_rl = xt(3); Fx_rr = xt(4);
    Fy_fl = xt(5); Fy_fr = xt(6); Fy_rl = xt(7); Fy_rr = xt(8);

    dfl = delta_fl(k);
    dfr = delta_fr(k);

    % transform front tire-frame forces to body frame
    FxB_fl = Fx_fl*cos(dfl) - Fy_fl*sin(dfl);
    FyB_fl = Fx_fl*sin(dfl) + Fy_fl*cos(dfl);

    FxB_fr = Fx_fr*cos(dfr) - Fy_fr*sin(dfr);
    FyB_fr = Fx_fr*sin(dfr) + Fy_fr*cos(dfr);

    % rear wheels assumed non-steered
    FxB_rl = Fx_rl;
    FyB_rl = Fy_rl;
    FxB_rr = Fx_rr;
    FyB_rr = Fy_rr;

    sumFx = FxB_fl + FxB_fr + FxB_rl + FxB_rr;
    sumFy = FyB_fl + FyB_fr + FyB_rl + FyB_rr;

    Mz = ...
        a*FyB_fl - (-tf/2)*FxB_fl + ...
        a*FyB_fr - ( tf/2)*FxB_fr + ...
       (-b)*FyB_rl - (-tr/2)*FxB_rl + ...
       (-b)*FyB_rr - ( tr/2)*FxB_rr;

    % body-frame accelerations
    ax_meas(k) = sumFx/m + r_meas(k)*vy_meas(k);
    ay_meas(k) = sumFy/m - r_meas(k)*vx_meas(k);
    rzdot_meas(k) = Mz/Iz;
end

% add measurement noise
rng(1);
ax_meas = ax_meas + 0.15*randn(N,1);
ay_meas = ay_meas + 0.15*randn(N,1);
rzdot_meas = rzdot_meas + 0.03*randn(N,1);

% fake wheel speeds
omega_fl = vx_meas/Rw + 0.3*randn(N,1);
omega_fr = vx_meas/Rw + 0.3*randn(N,1);
omega_rl = vx_meas/Rw + 0.3*randn(N,1);
omega_rr = vx_meas/Rw + 0.3*randn(N,1);

%% ==========================================================
% METHOD 1: ORIGINAL 8-STATE FORCE EKF
%% ==========================================================
nx = 8;   
nz = 3;   

xhat = zeros(nx,1);
P = diag([1e5 1e5 1e5 1e5 1e5 1e5 1e5 1e5]);

% process noise: random walk on forces
Q = diag([3e3 3e3 3e3 3e3 3e3 3e3 3e3 3e3]);

% measurement noise
R = diag([0.15^2, 0.15^2, 0.03^2]);

xhat_hist = zeros(nx,N);

for k = 1:N

    uk.vx = vx_meas(k);
    uk.vy = vy_meas(k);
    uk.r  = r_meas(k);

    uk.delta_fl = delta_fl(k);
    uk.delta_fr = delta_fr(k);

    uk.omega_fl = omega_fl(k);
    uk.omega_fr = omega_fr(k);
    uk.omega_rl = omega_rl(k);
    uk.omega_rr = omega_rr(k);

    uk.Fz_fl = Fz_fl(k);
    uk.Fz_fr = Fz_fr(k);
    uk.Fz_rl = Fz_rl(k);
    uk.Fz_rr = Fz_rr(k);

    zk = [ax_meas(k); ay_meas(k); rzdot_meas(k)];

    % Prediction
    x_pred = xhat;
    Fk = eye(nx);
    P_pred = Fk*P*Fk' + Q;

    % Update
    [z_pred, Hk] = measurement_model_and_jacobian(x_pred, uk, m, Iz, a, b, tf, tr);

    yk = zk - z_pred;
    Sk = Hk*P_pred*Hk' + R;
    Kk = P_pred*Hk'/Sk;

    xhat = x_pred + Kk*yk;
    P = (eye(nx) - Kk*Hk)*P_pred;

    xhat_hist(:,k) = xhat;
end

%% ==========================================================
% METHOD 2: RESULTANT FORCE RECONSTRUCTION + ALLOCATION
%
% This is the method I actually recommend for your use-case.
% It reconstructs observable aggregate quantities first:
%   Fx_tot, Fy_tot, Mz
% then splits Fy using yaw moment and axle geometry,
% and finally allocates left/right using measured Fz.
%
% For Fx, because no torque/brake info exists, this uses load-based
% allocation. That is an allocation rule, not a direct observation.
%% ==========================================================

Fx_alloc_hist = zeros(4,N);   % [fl fr rl rr]
Fy_alloc_hist = zeros(4,N);   % [fl fr rl rr]

Fx_tot_hist = zeros(N,1);
Fy_tot_hist = zeros(N,1);
Mz_hist     = zeros(N,1);
Fyf_hist    = zeros(N,1);
Fyr_hist    = zeros(N,1);

for k = 1:N

    % Observable body-level resultants
    Fx_tot = m*(ax_meas(k) - r_meas(k)*vy_meas(k));
    Fy_tot = m*(ay_meas(k) + r_meas(k)*vx_meas(k));
    Mz_tot = Iz*rzdot_meas(k);

    Fx_tot_hist(k) = Fx_tot;
    Fy_tot_hist(k) = Fy_tot;
    Mz_hist(k)     = Mz_tot;

    % Solve front/rear lateral resultants from:
    % Fy_f + Fy_r = Fy_tot
    % a*Fy_f - b*Fy_r = Mz
    Fy_f = (Mz_tot + b*Fy_tot)/(a+b);
    Fy_r = (a*Fy_tot - Mz_tot)/(a+b);

    Fyf_hist(k) = Fy_f;
    Fyr_hist(k) = Fy_r;

    % Left-right lateral allocation using measured normal loads
    Fzf_sum = Fz_fl(k) + Fz_fr(k);
    Fzr_sum = Fz_rl(k) + Fz_rr(k);

    Fy_fl_est = (Fz_fl(k)/Fzf_sum) * Fy_f;
    Fy_fr_est = (Fz_fr(k)/Fzf_sum) * Fy_f;
    Fy_rl_est = (Fz_rl(k)/Fzr_sum) * Fy_r;
    Fy_rr_est = (Fz_rr(k)/Fzr_sum) * Fy_r;

    % Longitudinal allocation:
    % Since no torque / brake info exists, use a pure load-based split.
    % This is an allocation assumption, not a true per-wheel observer.
    Fz_sum = Fz_fl(k) + Fz_fr(k) + Fz_rl(k) + Fz_rr(k);

    Fx_fl_est = (Fz_fl(k)/Fz_sum) * Fx_tot;
    Fx_fr_est = (Fz_fr(k)/Fz_sum) * Fx_tot;
    Fx_rl_est = (Fz_rl(k)/Fz_sum) * Fx_tot;
    Fx_rr_est = (Fz_rr(k)/Fz_sum) * Fx_tot;

    Fx_alloc_hist(:,k) = [Fx_fl_est; Fx_fr_est; Fx_rl_est; Fx_rr_est];
    Fy_alloc_hist(:,k) = [Fy_fl_est; Fy_fr_est; Fy_rl_est; Fy_rr_est];
end

%% ==========================================================
% OPTIONAL: SMOOTH METHOD 2 OUTPUTS
%% ==========================================================
win = 51; % odd window length for moving average
b_ma = ones(win,1)/win;

for i = 1:4
    Fx_alloc_hist(i,:) = filtfilt(b_ma,1,Fx_alloc_hist(i,:));
    Fy_alloc_hist(i,:) = filtfilt(b_ma,1,Fy_alloc_hist(i,:));
end

%% -----------------------------
% Compute error metrics
%% -----------------------------
true_forces = x_true;
ekf_forces  = xhat_hist;
alloc_forces = [Fx_alloc_hist; Fy_alloc_hist];

rmse_ekf   = sqrt(mean((ekf_forces - true_forces).^2, 2));
rmse_alloc = sqrt(mean((alloc_forces - true_forces).^2, 2));

disp('RMSE per channel [EKF, Allocation]:');
labels = {'Fx_fl','Fx_fr','Fx_rl','Fx_rr','Fy_fl','Fy_fr','Fy_rl','Fy_rr'};
for i = 1:8
    fprintf('%6s : %10.3f   %10.3f\n', labels{i}, rmse_ekf(i), rmse_alloc(i));
end

%% -----------------------------
% Plot results: per-wheel comparison
%% -----------------------------
plot_labels = {'Fx_{fl}','Fx_{fr}','Fx_{rl}','Fx_{rr}','Fy_{fl}','Fy_{fr}','Fy_{rl}','Fy_{rr}'};

figure('Name','Per-wheel Force Comparison');
for i = 1:8
    subplot(4,2,i);
    plot(t, x_true(i,:), 'r', 'LineWidth', 1.5); hold on;
    plot(t, xhat_hist(i,:), 'b--', 'LineWidth', 1.0);
    plot(t, alloc_forces(i,:), 'g-.', 'LineWidth', 1.0);
    grid on;
    ylabel(plot_labels{i});
    if i == 1
        title('True vs EKF vs Resultant+Allocation');
        legend('True','8-state EKF','Resultant+Allocation','Location','best');
    end
end
xlabel('Time [s]');

%% -----------------------------
% Plot resultants used by Method 2
%% -----------------------------
% True body-frame totals for comparison
Fx_tot_true = zeros(N,1);
Fy_tot_true = zeros(N,1);
Mz_true     = zeros(N,1);

for k = 1:N
    Fx_fl = Fx_fl_true(k); Fx_fr = Fx_fr_true(k); Fx_rl = Fx_rl_true(k); Fx_rr = Fx_rr_true(k);
    Fy_fl = Fy_fl_true(k); Fy_fr = Fy_fr_true(k); Fy_rl = Fy_rl_true(k); Fy_rr = Fy_rr_true(k);

    dfl = delta_fl(k);
    dfr = delta_fr(k);

    FxB_fl = Fx_fl*cos(dfl) - Fy_fl*sin(dfl);
    FyB_fl = Fx_fl*sin(dfl) + Fy_fl*cos(dfl);

    FxB_fr = Fx_fr*cos(dfr) - Fy_fr*sin(dfr);
    FyB_fr = Fx_fr*sin(dfr) + Fy_fr*cos(dfr);

    FxB_rl = Fx_rl;
    FyB_rl = Fy_rl;
    FxB_rr = Fx_rr;
    FyB_rr = Fy_rr;

    Fx_tot_true(k) = FxB_fl + FxB_fr + FxB_rl + FxB_rr;
    Fy_tot_true(k) = FyB_fl + FyB_fr + FyB_rl + FyB_rr;

    Mz_true(k) = ...
        a*FyB_fl - (-tf/2)*FxB_fl + ...
        a*FyB_fr - ( tf/2)*FxB_fr + ...
       (-b)*FyB_rl - (-tr/2)*FxB_rl + ...
       (-b)*FyB_rr - ( tr/2)*FxB_rr;
end

figure('Name','Resultant Forces and Yaw Moment');

subplot(3,1,1);
plot(t, Fx_tot_true, 'r', 'LineWidth', 1.5); hold on;
plot(t, Fx_tot_hist, 'g--', 'LineWidth', 1.0);
grid on;
ylabel('F_{x,tot} [N]');
title('Resultant Reconstruction Used by Method 2');
legend('True','Reconstructed');

subplot(3,1,2);
plot(t, Fy_tot_true, 'r', 'LineWidth', 1.5); hold on;
plot(t, Fy_tot_hist, 'g--', 'LineWidth', 1.0);
grid on;
ylabel('F_{y,tot} [N]');
legend('True','Reconstructed');

subplot(3,1,3);
plot(t, Mz_true, 'r', 'LineWidth', 1.5); hold on;
plot(t, Mz_hist, 'g--', 'LineWidth', 1.0);
grid on;
ylabel('M_z [N m]');
xlabel('Time [s]');
legend('True','Reconstructed');

%% -----------------------------
% Plot fake measurements
%% -----------------------------
figure('Name','Fake Measurements');

subplot(3,1,1);
plot(t, ax_meas, 'LineWidth', 1.2); grid on;
ylabel('a_x [m/s^2]');
title('Fake Measurements');

subplot(3,1,2);
plot(t, ay_meas, 'LineWidth', 1.2); grid on;
ylabel('a_y [m/s^2]');

subplot(3,1,3);
plot(t, r_meas, 'LineWidth', 1.2); grid on;
ylabel('r [rad/s]');
xlabel('Time [s]');

%% -----------------------------
% Local function
%% -----------------------------
function [z_pred, H] = measurement_model_and_jacobian(x, u, m, Iz, a, b, tf, tr)

    % states
    Fx_fl = x(1); Fx_fr = x(2); Fx_rl = x(3); Fx_rr = x(4);
    Fy_fl = x(5); Fy_fr = x(6); Fy_rl = x(7); Fy_rr = x(8);

    dfl = u.delta_fl;
    dfr = u.delta_fr;
    vx  = u.vx;
    vy  = u.vy;
    r   = u.r;

    % body-frame front tire forces
    FxB_fl = Fx_fl*cos(dfl) - Fy_fl*sin(dfl);
    FyB_fl = Fx_fl*sin(dfl) + Fy_fl*cos(dfl);

    FxB_fr = Fx_fr*cos(dfr) - Fy_fr*sin(dfr);
    FyB_fr = Fx_fr*sin(dfr) + Fy_fr*cos(dfr);

    % rear wheels
    FxB_rl = Fx_rl;
    FyB_rl = Fy_rl;
    FxB_rr = Fx_rr;
    FyB_rr = Fy_rr;

    % predicted measurements
    sumFx = FxB_fl + FxB_fr + FxB_rl + FxB_rr;
    sumFy = FyB_fl + FyB_fr + FyB_rl + FyB_rr;

    ax_pred = sumFx/m + r*vy;
    ay_pred = sumFy/m - r*vx;

    Mz = ...
        a*FyB_fl - (-tf/2)*FxB_fl + ...
        a*FyB_fr - ( tf/2)*FxB_fr + ...
       (-b)*FyB_rl - (-tr/2)*FxB_rl + ...
       (-b)*FyB_rr - ( tr/2)*FxB_rr;

    rdot_pred = Mz/Iz;

    z_pred = [ax_pred; ay_pred; rdot_pred];

    % Jacobian H = dh/dx
    H = zeros(3,8);

    % ax derivatives
    H(1,1) = cos(dfl)/m;
    H(1,2) = cos(dfr)/m;
    H(1,3) = 1/m;
    H(1,4) = 1/m;
    H(1,5) = -sin(dfl)/m;
    H(1,6) = -sin(dfr)/m;
    H(1,7) = 0;
    H(1,8) = 0;

    % ay derivatives
    H(2,1) = sin(dfl)/m;
    H(2,2) = sin(dfr)/m;
    H(2,3) = 0;
    H(2,4) = 0;
    H(2,5) = cos(dfl)/m;
    H(2,6) = cos(dfr)/m;
    H(2,7) = 1/m;
    H(2,8) = 1/m;

    % rdot derivatives
    H(3,1) = (a*sin(dfl) + (tf/2)*cos(dfl))/Iz;
    H(3,5) = (a*cos(dfl) - (tf/2)*sin(dfl))/Iz;

    H(3,2) = (a*sin(dfr) - (tf/2)*cos(dfr))/Iz;
    H(3,6) = (a*cos(dfr) + (tf/2)*sin(dfr))/Iz;

    H(3,3) = (tr/2)/Iz;
    H(3,7) = (-b)/Iz;

    H(3,4) = -(tr/2)/Iz;
    H(3,8) = (-b)/Iz;
end