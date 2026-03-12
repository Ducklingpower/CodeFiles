%% ============================================================
%  FULL 15-STATE TUTORIAL EKF
%  TWO-TRACK VEHICLE MODEL WITH:
%      - steering
%      - roll
%      - pitch
%      - per-wheel Fx and Fy as EKF states
%
%  PURPOSE:
%  This script is written to TEACH the full workflow:
%
%    1) Define a nonlinear vehicle model
%    2) Define what is a "true hidden state"
%    3) Define what is "measured"
%    4) Generate synthetic measured data
%    5) Run an EKF
%    6) Compare true vs measured vs estimated quantities
%
%  ------------------------------------------------------------
%  EKF STATE VECTOR (15 states)
%  ------------------------------------------------------------
%  x =
%   [ vx
%     vy
%     r
%     phi
%     phi_dot
%     theta
%     theta_dot
%     Fx_fl
%     Fx_fr
%     Fx_rl
%     Fx_rr
%     Fy_fl
%     Fy_fr
%     Fy_rl
%     Fy_rr ]
%
%  ------------------------------------------------------------
%  "REAL MEASURED" INPUTS / SIGNALS IN THIS TUTORIAL
%  ------------------------------------------------------------
%  measured inputs:
%     delta_fl_meas, delta_fr_meas   (front steering angles)
%     omega_meas(1:4)                (wheel speeds)
%     Fz_meas(1:4)                   (wheel normal loads)
%
%  measured outputs used in EKF update:
%     z = [vx_meas; vy_meas; r_meas; ax_meas; ay_meas]
%
%  ------------------------------------------------------------
%  IMPORTANT MODELING CHOICE
%  ------------------------------------------------------------
%  In this tutorial:
%     - Fx_i and Fy_i ARE EKF states
%     - The EKF process model treats them as random-walk states
%       (dF/dt = 0 + process noise)
%
%  The synthetic "truth model" uses a hidden tire-force target
%  and first-order force dynamics to generate realistic motion.
%
%  ------------------------------------------------------------
%  ACCELERATION CONVENTION
%  ------------------------------------------------------------
%  Here ax_meas and ay_meas are assumed to be gravity-compensated
%  body-frame accelerations:
%
%      ax_meas ~= (sum body-x forces)/m
%      ay_meas ~= (sum body-y forces)/m
%
%  Gravity STILL appears in:
%      - static normal loads
%      - roll restoring moment
%      - pitch restoring moment
%      - load transfer equations
%
%% ============================================================

clear; clc; close all;

%% ============================================================
% 1) PARAMETERS
%% ============================================================

p = struct();

% ------------------------------
% Geometry and inertia
% ------------------------------
p.m       = 161140.0;     % [kg]
p.ms      = 140000.0;     % [kg] effective sprung mass
p.Iz      = 2134000.0;    % [kg*m^2]
p.Ix      = 950000.0;     % [kg*m^2] roll inertia
p.Iy      = 1100000.0;    % [kg*m^2] pitch inertia (tutorial value)

p.lf      = 3.1701;       % [m]
p.lr      = 2.7256;       % [m]
p.L       = p.lf + p.lr;  % [m]
p.tf      = 5.6860;       % [m]
p.tr      = 4.9580;       % [m]

p.Rw      = 1.70;         % [m]
p.h_cg    = 3.20;         % [m]
p.h_roll  = 2.80;         % [m]
p.h_pitch = 2.60;         % [m]
p.g       = 9.81;         % [m/s^2]

% ------------------------------
% Roll / pitch dynamics
% ------------------------------
p.k_phi   = 2.0e6;        % [N*m/rad]
p.c_phi   = 2.5e5;        % [N*m*s/rad]

p.k_theta = 2.5e6;        % [N*m/rad]
p.c_theta = 3.0e5;        % [N*m*s/rad]

% ------------------------------
% Load transfer correction terms
% ------------------------------
p.kphi_load   = 0.8e6;
p.cphi_load   = 1.0e5;
p.ktheta_load = 1.0e6;
p.ctheta_load = 1.2e5;

p.lambda_f = 0.55;
p.lambda_r = 0.45;

% ------------------------------
% Hidden truth-model tire law
% (used ONLY to generate synthetic truth)
% ------------------------------
p.Ck_fl = 8.0e5;
p.Ck_fr = 8.0e5;
p.Ck_rl = 9.5e5;
p.Ck_rr = 9.5e5;

p.Ca_fl = 1.2e6;
p.Ca_fr = 1.2e6;
p.Ca_rl = 1.0e6;
p.Ca_rr = 1.0e6;

p.mu_true = 0.75;   % hidden true friction coefficient

% truth force time constant
p.tau_F = 0.08;     % [s]

% force clipping for EKF state sanity
p.force_clip = 2.0e6;  % [N]

% ------------------------------
% Simulation time
% ------------------------------
dt   = 0.01;      % [s]
Tend = 20.0;      % [s]
t    = (0:dt:Tend)';
N    = numel(t);

%% ============================================================
% 2) DEFINE TRUE INPUT PROFILES
%% ============================================================

% Steering profile (true)
delta_base = deg2rad(6.0) * sin(0.6*t) .* (1 - exp(-0.7*t));
delta_fl_true = delta_base;
delta_fr_true = delta_base;

% Prescribed slip-ratio command profiles used ONLY to create
% synthetic wheel speeds in the truth simulation
kappa_cmd_fl =  0.020*sin(0.70*t);
kappa_cmd_fr =  0.018*sin(0.70*t + 0.08);
kappa_cmd_rl =  0.030*sin(0.45*t);
kappa_cmd_rr =  0.028*sin(0.45*t - 0.10);

%% ============================================================
% 3) TRUE HIDDEN STATE TRAJECTORY GENERATION
%% ============================================================
% TRUE HIDDEN STATES:
%
% x_true = [vx, vy, r, phi, phi_dot, theta, theta_dot,
%           Fx_fl, Fx_fr, Fx_rl, Fx_rr,
%           Fy_fl, Fy_fr, Fy_rl, Fy_rr]'
%
% The truth model uses:
%   - the same rigid-body steering / roll / pitch equations
%   - but the force states follow first-order dynamics toward
%     hidden target forces computed from a tire law
%
% This makes the truth physically richer than the EKF model,
% which is good for teaching.

x_true = zeros(15, N);

% initial true state
x_true(:,1) = [ ...
    8.0;   % vx
    0.0;   % vy
    0.0;   % r
    0.0;   % phi
    0.0;   % phi_dot
    0.0;   % theta
    0.0;   % theta_dot
    0.0; 0.0; 0.0; 0.0; ...  % Fx states
    0.0; 0.0; 0.0; 0.0  ...  % Fy states
];

% Storage for truth signals
ax_true    = zeros(N,1);
ay_true    = zeros(N,1);
omega_true = zeros(4,N);
Fz_true    = zeros(4,N);
alpha_true = zeros(4,N);
kappa_true = zeros(4,N);

% initialize last accelerations
ax_last = 0.0;
ay_last = 0.0;

for k = 1:N-1

    % --------------------------------------------------------
    % True measured inputs for this instant
    % --------------------------------------------------------
    u_true.delta_fl = delta_fl_true(k);
    u_true.delta_fr = delta_fr_true(k);

    % --------------------------------------------------------
    % Compute normal loads using current true state and last
    % body accelerations
    % --------------------------------------------------------
    Fz_k = normalLoadsFromStates15(x_true(:,k), ax_last, ay_last, p);
    Fz_true(:,k) = Fz_k;

    % --------------------------------------------------------
    % Generate "true" wheel speeds from commanded slip ratio
    % --------------------------------------------------------
    wk_true = wheelKinematics15(x_true(:,k), u_true, p);

    omega_true(1,k) = (wk_true.Vx_w_fl / p.Rw) * (1 + kappa_cmd_fl(k));
    omega_true(2,k) = (wk_true.Vx_w_fr / p.Rw) * (1 + kappa_cmd_fr(k));
    omega_true(3,k) = (wk_true.Vx_w_rl / p.Rw) * (1 + kappa_cmd_rl(k));
    omega_true(4,k) = (wk_true.Vx_w_rr / p.Rw) * (1 + kappa_cmd_rr(k));

    u_true.omega = omega_true(:,k);
    u_true.Fz    = Fz_k;

    % --------------------------------------------------------
    % Hidden truth tire force target
    % (this is NOT used by the EKF, only for generating truth)
    % --------------------------------------------------------
    tire_target = hiddenTruthTireForceTarget(x_true(:,k), u_true, p);
    alpha_true(:,k) = tire_target.alpha;
    kappa_true(:,k) = tire_target.kappa;

    % --------------------------------------------------------
    % Propagate truth
    % --------------------------------------------------------
    [xdot_true, y_true] = truthDynamics15(x_true(:,k), u_true, tire_target, p);

    ax_true(k) = y_true(2);
    ay_true(k) = y_true(3);

    ax_last = y_true(2);
    ay_last = y_true(3);

    x_true(:,k+1) = x_true(:,k) + dt * xdot_true;
end

% fill last sample
Fz_true(:,N) = normalLoadsFromStates15(x_true(:,N), ax_last, ay_last, p);
u_last.delta_fl = delta_fl_true(N);
u_last.delta_fr = delta_fr_true(N);
wk_last = wheelKinematics15(x_true(:,N), u_last, p);
omega_true(1,N) = (wk_last.Vx_w_fl / p.Rw) * (1 + kappa_cmd_fl(N));
omega_true(2,N) = (wk_last.Vx_w_fr / p.Rw) * (1 + kappa_cmd_fr(N));
omega_true(3,N) = (wk_last.Vx_w_rl / p.Rw) * (1 + kappa_cmd_rl(N));
omega_true(4,N) = (wk_last.Vx_w_rr / p.Rw) * (1 + kappa_cmd_rr(N));
u_last.omega = omega_true(:,N);
u_last.Fz    = Fz_true(:,N);
tire_last = hiddenTruthTireForceTarget(x_true(:,N), u_last, p);
alpha_true(:,N) = tire_last.alpha;
kappa_true(:,N) = tire_last.kappa;
[~, y_last] = truthDynamics15(x_true(:,N), u_last, tire_last, p);
ax_true(N) = y_last(2);
ay_true(N) = y_last(3);

%% ============================================================
% 4) CREATE SYNTHETIC MEASUREMENTS
%% ============================================================

rng(7);

% Steering measurements
delta_fl_meas = delta_fl_true + deg2rad(0.10)*randn(N,1);
delta_fr_meas = delta_fr_true + deg2rad(0.10)*randn(N,1);

% Wheel speed measurements
omega_meas = omega_true + 0.03*randn(4,N);

% Wheel load measurements
Fz_meas = Fz_true + 2.0e4*randn(4,N);

% EKF measured outputs
vx_meas = x_true(1,:)' + 0.15*randn(N,1);
vy_meas = x_true(2,:)' + 0.15*randn(N,1);
r_meas  = x_true(3,:)' + 0.005*randn(N,1);
ax_meas = ax_true      + 0.08*randn(N,1);
ay_meas = ay_true      + 0.08*randn(N,1);

%% ============================================================
% 5) EKF SETUP
%% ============================================================

% EKF estimated state:
% x_hat = [vx vy r phi phi_dot theta theta_dot Fx_fl Fx_fr Fx_rl Fx_rr Fy_fl Fy_fr Fy_rl Fy_rr]'

nx = 15;
nz = 5; % z = [vx; vy; r; ax; ay]

xhat = zeros(nx, N);

% initial estimate
xhat(:,1) = [ ...
    vx_meas(1);
    vy_meas(1);
    r_meas(1);
    0.0;
    0.0;
    0.0;
    0.0;
    0.0;
    0.0;
    0.0;
    0.0;
    0.0;
    0.0;
    0.0;
    0.0
];

% Initial covariance P
P = diag([ ...
    1.0^2, ...        % vx
    1.0^2, ...        % vy
    0.10^2, ...       % r
    deg2rad(2)^2, ... % phi
    deg2rad(6)^2, ... % phi_dot
    deg2rad(2)^2, ... % theta
    deg2rad(6)^2, ... % theta_dot
    4e5, 4e5, 4e5, 4e5, ... % Fx states
    4e5, 4e5, 4e5, 4e5  ... % Fy states
]);

% Process noise covariance Q
Q = diag([ ...
    0.05^2, ...
    0.05^2, ...
    0.02^2, ...
    deg2rad(0.10)^2, ...
    deg2rad(0.60)^2, ...
    deg2rad(0.10)^2, ...
    deg2rad(0.60)^2, ...
    8e4, 8e4, 8e4, 8e4, ...
    8e4, 8e4, 8e4, 8e4
]);

% Measurement noise covariance R
R = diag([ ...
    0.15^2, ...  % vx
    0.15^2, ...  % vy
    0.005^2, ... % r
    0.08^2, ...  % ax
    0.08^2       % ay
]);

P_hist = zeros(nx,nx,N);
P_hist(:,:,1) = P;

% Post-processing storage
slip_est  = zeros(4,N);
alpha_est = zeros(4,N);
mu_est    = zeros(4,N);

%% ============================================================
% 6) RUN EKF
%% ============================================================

for k = 1:N-1

    % --------------------------------------------------------
    % Measured known inputs at time k
    % --------------------------------------------------------
    u_meas.delta_fl = delta_fl_meas(k);
    u_meas.delta_fr = delta_fr_meas(k);

    % These are measured too, but not part of the EKF update
    % in this 15-state formulation:
    u_meas.omega = omega_meas(:,k);
    u_meas.Fz    = max(Fz_meas(:,k), 1000.0);

    % --------------------------------------------------------
    % Measured outputs used by EKF update
    % --------------------------------------------------------
    z_k = [
        vx_meas(k);
        vy_meas(k);
        r_meas(k);
        ax_meas(k);
        ay_meas(k)
    ];

    % --------------------------------------------------------
    % Prediction
    % --------------------------------------------------------
    f_disc = @(x) x + dt * processModel15(x, u_meas, p);

    x_pred = f_disc(xhat(:,k));

    A = numericalJacobian(f_disc, xhat(:,k));
    P_pred = A*P*A' + Q;

    % --------------------------------------------------------
    % Update
    % --------------------------------------------------------
    h_fun = @(x) measurementModel15(x, u_meas, p);

    z_pred = h_fun(x_pred);
    H = numericalJacobian(h_fun, x_pred);

    innov = z_k - z_pred;
    S = H*P_pred*H' + R;
    K = P_pred*H' / S;

    x_upd = x_pred + K*innov;

    % Joseph form covariance update
    I = eye(nx);
    P = (I - K*H)*P_pred*(I - K*H)' + K*R*K';

    % Force sanity clipping
    x_upd(8:15) = min(max(x_upd(8:15), -p.force_clip), p.force_clip);

    xhat(:,k+1) = x_upd;
    P_hist(:,:,k+1) = P;

    % --------------------------------------------------------
    % Post-processing using measured wheel loads/speeds
    % --------------------------------------------------------
    slipout = computeSlipAndMu(xhat(:,k+1), u_meas, p);

    slip_est(:,k+1)  = slipout.kappa;
    alpha_est(:,k+1) = slipout.alpha;
    mu_est(:,k+1)    = slipout.mu;
end

%% ============================================================
% 7) PLOTS
%% ============================================================

figure;

subplot(4,2,1);
plot(t, x_true(1,:), 'b', 'LineWidth',1.4); hold on;
plot(t, vx_meas, '.', 'Color',[0.7 0.7 0.7], 'MarkerSize',4);
plot(t, xhat(1,:), 'r', 'LineWidth',1.4);
grid on; ylabel('v_x [m/s]'); title('Longitudinal speed');
legend('true','measured','EKF');

subplot(4,2,2);
plot(t, x_true(2,:), 'b', 'LineWidth',1.4); hold on;
plot(t, vy_meas, '.', 'Color',[0.7 0.7 0.7], 'MarkerSize',4);
plot(t, xhat(2,:), 'r--', 'LineWidth',1.4);
grid on; ylabel('v_y [m/s]'); title('Lateral speed');
legend('true','measured','EKF');

subplot(4,2,3);
plot(t, x_true(3,:), 'b', 'LineWidth',1.4); hold on;
plot(t, r_meas, '.', 'Color',[0.7 0.7 0.7], 'MarkerSize',4);
plot(t, xhat(3,:), 'r--', 'LineWidth',1.4);
grid on; ylabel('r [rad/s]'); title('Yaw rate');
legend('true','measured','EKF');

subplot(4,2,4);
plot(t, x_true(4,:), 'b', 'LineWidth',1.4); hold on;
plot(t, xhat(4,:), 'r--', 'LineWidth',1.4);
grid on; ylabel('\phi [rad]'); title('Roll angle');
legend('true','EKF');

subplot(4,2,5);
plot(t, x_true(5,:), 'b', 'LineWidth',1.4); hold on;
plot(t, xhat(5,:), 'r--', 'LineWidth',1.4);
grid on; ylabel('\phi dot [rad/s]'); title('Roll rate');
legend('true','EKF');

subplot(4,2,6);
plot(t, x_true(6,:), 'b', 'LineWidth',1.4); hold on;
plot(t, xhat(6,:), 'r--', 'LineWidth',1.4);
grid on; ylabel('\theta [rad]'); title('Pitch angle');
legend('true','EKF');

subplot(4,2,7);
plot(t, x_true(7,:), 'b', 'LineWidth',1.4); hold on;
plot(t, xhat(7,:), 'r--', 'LineWidth',1.4);
grid on; ylabel('\theta dot [rad/s]'); xlabel('time [s]');
title('Pitch rate');
legend('true','EKF');

figure;

names = {'FL','FR','RL','RR'};

for i = 1:4
    subplot(4,2,2*i-1);
    plot(t, x_true(7+i,:), 'b', 'LineWidth',1.3); hold on;
    plot(t, xhat(7+i,:), 'r--', 'LineWidth',1.3);
    grid on; ylabel(['Fx ',names{i},' [N]']);
    title(['Longitudinal force ',names{i}]);
    legend('true','EKF');
end

for i = 1:4
    subplot(4,2,2*i);
    plot(t, x_true(11+i,:), 'b', 'LineWidth',1.3); hold on;
    plot(t, xhat(11+i,:), 'r--', 'LineWidth',1.3);
    grid on; ylabel(['Fy ',names{i},' [N]']);
    title(['Lateral force ',names{i}]);
    legend('true','EKF');
end

figure('Color','w','Name','Measured vs predicted outputs');

zhat_store = zeros(nz,N);
for i = 1:N
    u_tmp.delta_fl = delta_fl_meas(i);
    u_tmp.delta_fr = delta_fr_meas(i);
    u_tmp.omega    = omega_meas(:,i);
    u_tmp.Fz       = max(Fz_meas(:,i),1000.0);
    zhat_store(:,i) = measurementModel15(xhat(:,i), u_tmp, p);
end

subplot(5,1,1);
plot(t, vx_meas, 'b'); hold on;
plot(t, zhat_store(1,:), 'r--', 'LineWidth',1.3);
grid on; ylabel('v_x');
title('Measured vs EKF-predicted outputs');
legend('measured','predicted');

subplot(5,1,2);
plot(t, vy_meas, 'b'); hold on;
plot(t, zhat_store(2,:), 'r--', 'LineWidth',1.3);
grid on; ylabel('v_y');
legend('measured','predicted');

subplot(5,1,3);
plot(t, r_meas, 'b'); hold on;
plot(t, zhat_store(3,:), 'r--', 'LineWidth',1.3);
grid on; ylabel('r');
legend('measured','predicted');

subplot(5,1,4);
plot(t, ax_meas, 'b'); hold on;
plot(t, zhat_store(4,:), 'r--', 'LineWidth',1.3);
grid on; ylabel('a_x');
legend('measured','predicted');

subplot(5,1,5);
plot(t, ay_meas, 'b'); hold on;
plot(t, zhat_store(5,:), 'r--', 'LineWidth',1.3);
grid on; ylabel('a_y'); xlabel('time [s]');
legend('measured','predicted');

figure;

for i = 1:4
    subplot(4,1,i);
    plot(t, Fz_true(i,:), 'k', 'LineWidth',1.2); hold on;
    plot(t, Fz_meas(i,:), '.', 'Color',[0.7 0.7 0.7], 'MarkerSize',4);
    grid on; ylabel(['Fz ',names{i}]);
    title(['Wheel load ',names{i}]);
    if i == 4
        xlabel('time [s]');
    end
    legend('true','measured');
end

figure;

subplot(2,1,1);
plot(t, slip_est(1,:), 'DisplayName','FL'); hold on;
plot(t, slip_est(2,:), 'DisplayName','FR');
plot(t, slip_est(3,:), 'DisplayName','RL');
plot(t, slip_est(4,:), 'DisplayName','RR');
grid on; ylabel('\kappa'); title('Estimated slip ratios from EKF states + measured wheel speeds');
legend;

subplot(2,1,2);
plot(t, mu_est(1,:), 'DisplayName','FL'); hold on;
plot(t, mu_est(2,:), 'DisplayName','FR');
plot(t, mu_est(3,:), 'DisplayName','RL');
plot(t, mu_est(4,:), 'DisplayName','RR');
grid on; ylabel('\mu utilization'); xlabel('time [s]');
title('Estimated friction utilization using measured Fz');
legend;

figure('Color','w','Name','Diagonal Entries of P');
state_names = {'vx','vy','r','phi','phiDot','theta','thetaDot', ...
               'Fxfl','Fxfr','Fxrl','Fxrr','Fyfl','Fyfr','Fyrl','Fyrr'};

for i = 1:nx
    subplot(nx,1,i);
    plot(t, squeeze(P_hist(i,i,:)), 'LineWidth',1.2);
    grid on; ylabel(state_names{i});
    if i == 1
        title('EKF covariance diagonal entries');
    end
    if i == nx
        xlabel('time [s]');
    end
end

disp('Done.');
disp('EKF estimated states:');
disp('[vx vy r phi phi_dot theta theta_dot Fx_fl Fx_fr Fx_rl Fx_rr Fy_fl Fy_fr Fy_rl Fy_rr]');
disp('Measured inputs available in this tutorial: steering, wheel speeds, wheel loads');
disp('Measured outputs used by EKF update: [vx vy r ax ay]');

%% ============================================================
% LOCAL FUNCTIONS
%% ============================================================

function J = numericalJacobian(fun, x)
% Numerical Jacobian by central differences
    x = x(:);
    y0 = fun(x);
    n = numel(x);
    m = numel(y0);
    J = zeros(m,n);
    epsJ = 1e-6;

    for i = 1:n
        dx = zeros(n,1);
        dx(i) = epsJ;
        y_plus  = fun(x + dx);
        y_minus = fun(x - dx);
        J(:,i) = (y_plus - y_minus) / (2*epsJ);
    end
end

function [xdot, y] = truthDynamics15(x, u, tire_target, p)
% =============================================================
% TRUE hidden dynamics used only to generate synthetic data
%
% This truth model uses:
%   - same body / roll / pitch equations as EKF model
%   - BUT force states are first-order dynamics toward hidden
%     tire-force targets
% =============================================================

    % unpack states
    vx      = x(1);
    vy      = x(2);
    r       = x(3);
    phi     = x(4);
    phi_dot = x(5);
    theta   = x(6);
    th_dot  = x(7);

    Fx_fl = x(8);  Fx_fr = x(9);  Fx_rl = x(10); Fx_rr = x(11);
    Fy_fl = x(12); Fy_fr = x(13); Fy_rl = x(14); Fy_rr = x(15);

    dfl = u.delta_fl;
    dfr = u.delta_fr;

    % body-frame force sums with steering explicitly included
    sumFx = ...
        Fx_fl*cos(dfl) - Fy_fl*sin(dfl) + ...
        Fx_fr*cos(dfr) - Fy_fr*sin(dfr) + ...
        Fx_rl + Fx_rr;

    sumFy = ...
        Fx_fl*sin(dfl) + Fy_fl*cos(dfl) + ...
        Fx_fr*sin(dfr) + Fy_fr*cos(dfr) + ...
        Fy_rl + Fy_rr;

    % body accelerations
    ax_body = sumFx / p.m;
    ay_body = sumFy / p.m;

    % translational dynamics
    vx_dot = r*vy + ax_body;
    vy_dot = -r*vx + ay_body;

    % yaw dynamics
    Mz = ...
        p.lf*(Fx_fl*sin(dfl) + Fy_fl*cos(dfl)) ...
        - (p.tf/2)*(Fx_fl*cos(dfl) - Fy_fl*sin(dfl)) ...
      + p.lf*(Fx_fr*sin(dfr) + Fy_fr*cos(dfr)) ...
        + (p.tf/2)*(Fx_fr*cos(dfr) - Fy_fr*sin(dfr)) ...
      - p.lr*Fy_rl - (p.tr/2)*Fx_rl ...
      - p.lr*Fy_rr + (p.tr/2)*Fx_rr;

    r_dot = Mz / p.Iz;

    % roll dynamics with gravity restoring term
    phi_ddot = ( ...
        p.ms*p.h_roll*ay_body ...
        - p.c_phi*phi_dot ...
        - p.k_phi*phi ...
        - p.ms*p.g*p.h_roll*sin(phi) ...
        ) / p.Ix;

    % pitch dynamics with gravity restoring term
    theta_ddot = ( ...
        p.ms*p.h_pitch*ax_body ...
        - p.c_theta*th_dot ...
        - p.k_theta*theta ...
        - p.ms*p.g*p.h_pitch*sin(theta) ...
        ) / p.Iy;

    % hidden true force dynamics: first-order toward tire target
    Fx_fl_dot = (tire_target.Fx(1) - Fx_fl)/p.tau_F;
    Fx_fr_dot = (tire_target.Fx(2) - Fx_fr)/p.tau_F;
    Fx_rl_dot = (tire_target.Fx(3) - Fx_rl)/p.tau_F;
    Fx_rr_dot = (tire_target.Fx(4) - Fx_rr)/p.tau_F;

    Fy_fl_dot = (tire_target.Fy(1) - Fy_fl)/p.tau_F;
    Fy_fr_dot = (tire_target.Fy(2) - Fy_fr)/p.tau_F;
    Fy_rl_dot = (tire_target.Fy(3) - Fy_rl)/p.tau_F;
    Fy_rr_dot = (tire_target.Fy(4) - Fy_rr)/p.tau_F;

    xdot = [
        vx_dot;
        vy_dot;
        r_dot;
        phi_dot;
        phi_ddot;
        th_dot;
        theta_ddot;
        Fx_fl_dot;
        Fx_fr_dot;
        Fx_rl_dot;
        Fx_rr_dot;
        Fy_fl_dot;
        Fy_fr_dot;
        Fy_rl_dot;
        Fy_rr_dot
    ];

    y = [
        vx;
        vy;
        r;
        ax_body;
        ay_body
    ];
end

function xdot = processModel15(x, u, p)
% =============================================================
% EKF PROCESS MODEL
%
% States:
%   x =
%   [vx vy r phi phi_dot theta theta_dot Fx_fl Fx_fr Fx_rl Fx_rr Fy_fl Fy_fr Fy_rl Fy_rr]'
%
% Measured known inputs:
%   u.delta_fl, u.delta_fr
%
% IMPORTANT:
%   In the EKF model the tire forces are treated as random-walk
%   states, so their deterministic derivatives are zero.
%   The filter changes them through process noise Q and the
%   measurement update.
% =============================================================

    vx      = x(1);
    vy      = x(2);
    r       = x(3);
    phi     = x(4);
    phi_dot = x(5);
    theta   = x(6);
    th_dot  = x(7);

    Fx_fl = x(8);  Fx_fr = x(9);  Fx_rl = x(10); Fx_rr = x(11);
    Fy_fl = x(12); Fy_fr = x(13); Fy_rl = x(14); Fy_rr = x(15);

    dfl = u.delta_fl;
    dfr = u.delta_fr;

    % ---------------------------------------------------------
    % Explicit body-frame force components
    % ---------------------------------------------------------
    sumFx = ...
        Fx_fl*cos(dfl) - Fy_fl*sin(dfl) + ...
        Fx_fr*cos(dfr) - Fy_fr*sin(dfr) + ...
        Fx_rl + Fx_rr;

    sumFy = ...
        Fx_fl*sin(dfl) + Fy_fl*cos(dfl) + ...
        Fx_fr*sin(dfr) + Fy_fr*cos(dfr) + ...
        Fy_rl + Fy_rr;

    % ---------------------------------------------------------
    % Body-frame accelerations
    % These are the model-predicted accelerations
    % ---------------------------------------------------------
    ax_body = sumFx / p.m;
    ay_body = sumFy / p.m;

    % ---------------------------------------------------------
    % Planar vehicle dynamics
    % ---------------------------------------------------------
    vx_dot = r*vy + ax_body;
    vy_dot = -r*vx + ay_body;

    % ---------------------------------------------------------
    % Yaw dynamics (fully expanded)
    % ---------------------------------------------------------
    Mz = ...
        p.lf*(Fx_fl*sin(dfl) + Fy_fl*cos(dfl)) ...
        - (p.tf/2)*(Fx_fl*cos(dfl) - Fy_fl*sin(dfl)) ...
      + p.lf*(Fx_fr*sin(dfr) + Fy_fr*cos(dfr)) ...
        + (p.tf/2)*(Fx_fr*cos(dfr) - Fy_fr*sin(dfr)) ...
      - p.lr*Fy_rl - (p.tr/2)*Fx_rl ...
      - p.lr*Fy_rr + (p.tr/2)*Fx_rr;

    r_dot = Mz / p.Iz;

    % ---------------------------------------------------------
    % Roll and pitch dynamics with gravity restoring terms
    % ---------------------------------------------------------
    phi_ddot = ( ...
        p.ms*p.h_roll*ay_body ...
        - p.c_phi*phi_dot ...
        - p.k_phi*phi ...
        - p.ms*p.g*p.h_roll*sin(phi) ...
        ) / p.Ix;

    theta_ddot = ( ...
        p.ms*p.h_pitch*ax_body ...
        - p.c_theta*th_dot ...
        - p.k_theta*theta ...
        - p.ms*p.g*p.h_pitch*sin(theta) ...
        ) / p.Iy;

    % ---------------------------------------------------------
    % Force states: random walk
    % ---------------------------------------------------------
    Fx_fl_dot = 0.0;
    Fx_fr_dot = 0.0;
    Fx_rl_dot = 0.0;
    Fx_rr_dot = 0.0;

    Fy_fl_dot = 0.0;
    Fy_fr_dot = 0.0;
    Fy_rl_dot = 0.0;
    Fy_rr_dot = 0.0;

    xdot = [
        vx_dot;
        vy_dot;
        r_dot;
        phi_dot;
        phi_ddot;
        th_dot;
        theta_ddot;
        Fx_fl_dot;
        Fx_fr_dot;
        Fx_rl_dot;
        Fx_rr_dot;
        Fy_fl_dot;
        Fy_fr_dot;
        Fy_rl_dot;
        Fy_rr_dot
    ];
end

function zhat = measurementModel15(x, u, p)
% =============================================================
% EKF MEASUREMENT MODEL
%
% Measured outputs:
%   z = [vx_meas; vy_meas; r_meas; ax_meas; ay_meas]
%
% IMPORTANT:
%   The model-predicted accelerations come from the current
%   force-state values and steering angle.
% =============================================================

    vx      = x(1);
    vy      = x(2);
    r       = x(3);

    Fx_fl = x(8);  Fx_fr = x(9);  Fx_rl = x(10); Fx_rr = x(11);
    Fy_fl = x(12); Fy_fr = x(13); Fy_rl = x(14); Fy_rr = x(15);

    dfl = u.delta_fl;
    dfr = u.delta_fr;

    ax_body = ( ...
        Fx_fl*cos(dfl) - Fy_fl*sin(dfl) + ...
        Fx_fr*cos(dfr) - Fy_fr*sin(dfr) + ...
        Fx_rl + Fx_rr ...
        ) / p.m;

    ay_body = ( ...
        Fx_fl*sin(dfl) + Fy_fl*cos(dfl) + ...
        Fx_fr*sin(dfr) + Fy_fr*cos(dfr) + ...
        Fy_rl + Fy_rr ...
        ) / p.m;

    zhat = [
        vx;
        vy;
        r;
        ax_body;
        ay_body
    ];
end

function Fz = normalLoadsFromStates15(x, ax_body, ay_body, p)
% =============================================================
% Wheel normal loads:
%   - static gravity load distribution
%   - longitudinal transfer from ax
%   - pitch correction
%   - lateral transfer from ay
%   - roll correction
% =============================================================

    phi     = x(4);
    phi_dot = x(5);
    theta   = x(6);
    th_dot  = x(7);

    % front/rear axle loads
    Fzf = ...
        p.m*p.g*p.lr/p.L ...
        - p.m*p.h_cg*ax_body/p.L ...
        - (p.ktheta_load*theta + p.ctheta_load*th_dot)/p.L;

    Fzr = ...
        p.m*p.g*p.lf/p.L ...
        + p.m*p.h_cg*ax_body/p.L ...
        + (p.ktheta_load*theta + p.ctheta_load*th_dot)/p.L;

    % left-right transfer
    dFf = ...
        p.lambda_f * p.m*p.h_cg*ay_body/p.tf ...
        + 2*(p.kphi_load*phi + p.cphi_load*phi_dot)/p.tf;

    dFr = ...
        p.lambda_r * p.m*p.h_cg*ay_body/p.tr ...
        + 2*(p.kphi_load*phi + p.cphi_load*phi_dot)/p.tr;

    Fz_fl = Fzf/2 - dFf/2;
    Fz_fr = Fzf/2 + dFf/2;
    Fz_rl = Fzr/2 - dFr/2;
    Fz_rr = Fzr/2 + dFr/2;

    Fz = [Fz_fl; Fz_fr; Fz_rl; Fz_rr];
    Fz = max(Fz, 1000.0);
end

function wk = wheelKinematics15(x, u, p)
% =============================================================
% Wheel-center kinematics in wheel frame
% =============================================================

    vx = x(1);
    vy = x(2);
    r  = x(3);

    dfl = u.delta_fl;
    dfr = u.delta_fr;

    % body-frame contact patch velocities
    Vx_b_fl = vx - r*p.tf/2;
    Vy_b_fl = vy + p.lf*r;

    Vx_b_fr = vx + r*p.tf/2;
    Vy_b_fr = vy + p.lf*r;

    Vx_b_rl = vx - r*p.tr/2;
    Vy_b_rl = vy - p.lr*r;

    Vx_b_rr = vx + r*p.tr/2;
    Vy_b_rr = vy - p.lr*r;

    % rotate front wheels into wheel frame
    wk.Vx_w_fl =  Vx_b_fl*cos(dfl) + Vy_b_fl*sin(dfl);
    wk.Vy_w_fl = -Vx_b_fl*sin(dfl) + Vy_b_fl*cos(dfl);

    wk.Vx_w_fr =  Vx_b_fr*cos(dfr) + Vy_b_fr*sin(dfr);
    wk.Vy_w_fr = -Vx_b_fr*sin(dfr) + Vy_b_fr*cos(dfr);

    % rear wheels (no rear steer)
    wk.Vx_w_rl = Vx_b_rl;
    wk.Vy_w_rl = Vy_b_rl;

    wk.Vx_w_rr = Vx_b_rr;
    wk.Vy_w_rr = Vy_b_rr;
end

function tire = hiddenTruthTireForceTarget(x, u, p)
% =============================================================
% Hidden truth tire-force target used ONLY for synthetic data
% generation.
%
% This is not part of the EKF.
% =============================================================

    wk = wheelKinematics15(x, u, p);
    omega = u.omega(:);
    Fz    = max(u.Fz(:), 1000.0);

    epsV = 0.5;

    kappa_fl = (p.Rw*omega(1) - wk.Vx_w_fl) / max([abs(p.Rw*omega(1)), abs(wk.Vx_w_fl), epsV]);
    kappa_fr = (p.Rw*omega(2) - wk.Vx_w_fr) / max([abs(p.Rw*omega(2)), abs(wk.Vx_w_fr), epsV]);
    kappa_rl = (p.Rw*omega(3) - wk.Vx_w_rl) / max([abs(p.Rw*omega(3)), abs(wk.Vx_w_rl), epsV]);
    kappa_rr = (p.Rw*omega(4) - wk.Vx_w_rr) / max([abs(p.Rw*omega(4)), abs(wk.Vx_w_rr), epsV]);

    alpha_fl = atan2(wk.Vy_w_fl, max(abs(wk.Vx_w_fl), epsV));
    alpha_fr = atan2(wk.Vy_w_fr, max(abs(wk.Vx_w_fr), epsV));
    alpha_rl = atan2(wk.Vy_w_rl, max(abs(wk.Vx_w_rl), epsV));
    alpha_rr = atan2(wk.Vy_w_rr, max(abs(wk.Vx_w_rr), epsV));

    Fx_fl = p.Ck_fl * kappa_fl;
    Fx_fr = p.Ck_fr * kappa_fr;
    Fx_rl = p.Ck_rl * kappa_rl;
    Fx_rr = p.Ck_rr * kappa_rr;

    Fy_fl = -p.Ca_fl * alpha_fl;
    Fy_fr = -p.Ca_fr * alpha_fr;
    Fy_rl = -p.Ca_rl * alpha_rl;
    Fy_rr = -p.Ca_rr * alpha_rr;

    [Fx_fl, Fy_fl] = saturateFrictionCircle(Fx_fl, Fy_fl, p.mu_true, Fz(1));
    [Fx_fr, Fy_fr] = saturateFrictionCircle(Fx_fr, Fy_fr, p.mu_true, Fz(2));
    [Fx_rl, Fy_rl] = saturateFrictionCircle(Fx_rl, Fy_rl, p.mu_true, Fz(3));
    [Fx_rr, Fy_rr] = saturateFrictionCircle(Fx_rr, Fy_rr, p.mu_true, Fz(4));

    tire.Fx = [Fx_fl; Fx_fr; Fx_rl; Fx_rr];
    tire.Fy = [Fy_fl; Fy_fr; Fy_rl; Fy_rr];
    tire.alpha = [alpha_fl; alpha_fr; alpha_rl; alpha_rr];
    tire.kappa = [kappa_fl; kappa_fr; kappa_rl; kappa_rr];
end

function out = computeSlipAndMu(xhat, u, p)
% =============================================================
% Post-processing:
%   - uses EKF-estimated states
%   - uses measured wheel speeds and measured wheel loads
% =============================================================

    wk = wheelKinematics15(xhat, u, p);
    omega = u.omega(:);
    Fz    = max(u.Fz(:), 1000.0);

    Fx = xhat(8:11);
    Fy = xhat(12:15);

    epsV = 0.5;

    kappa_fl = (p.Rw*omega(1) - wk.Vx_w_fl) / max([abs(p.Rw*omega(1)), abs(wk.Vx_w_fl), epsV]);
    kappa_fr = (p.Rw*omega(2) - wk.Vx_w_fr) / max([abs(p.Rw*omega(2)), abs(wk.Vx_w_fr), epsV]);
    kappa_rl = (p.Rw*omega(3) - wk.Vx_w_rl) / max([abs(p.Rw*omega(3)), abs(wk.Vx_w_rl), epsV]);
    kappa_rr = (p.Rw*omega(4) - wk.Vx_w_rr) / max([abs(p.Rw*omega(4)), abs(wk.Vx_w_rr), epsV]);

    alpha_fl = atan2(wk.Vy_w_fl, max(abs(wk.Vx_w_fl), epsV));
    alpha_fr = atan2(wk.Vy_w_fr, max(abs(wk.Vx_w_fr), epsV));
    alpha_rl = atan2(wk.Vy_w_rl, max(abs(wk.Vx_w_rl), epsV));
    alpha_rr = atan2(wk.Vy_w_rr, max(abs(wk.Vx_w_rr), epsV));

    mu = zeros(4,1);
    for i = 1:4
        mu(i) = hypot(Fx(i), Fy(i)) / max(Fz(i), 1e-6);
    end

    out.kappa = [kappa_fl; kappa_fr; kappa_rl; kappa_rr];
    out.alpha = [alpha_fl; alpha_fr; alpha_rl; alpha_rr];
    out.mu    = mu;
end

function [Fx_sat, Fy_sat] = saturateFrictionCircle(Fx, Fy, mu, Fz)
% Combined-force saturation:
%   sqrt(Fx^2 + Fy^2) <= mu*Fz
    Fmax = max(mu*Fz, 1.0);
    magF = hypot(Fx, Fy);

    if magF <= Fmax
        Fx_sat = Fx;
        Fy_sat = Fy;
    else
        scale = Fmax / magF;
        Fx_sat = Fx * scale;
        Fy_sat = Fy * scale;
    end
end