%% CAT Axle Force Estimator Prototype
% This prototype estimates axle-resultant forces:
%   Fx_f, Fx_r, Fy_f, Fy_r, Fz_f, Fz_r
%
% Philosophy:
%   - No tire model
%   - Longitudinal force split uses the paper's method:
%         Fx_f = (Fz_f/g) * a_x_eff
%         Fx_r = (Fz_r/g) * a_x_eff
%   - Lateral force uses an algebraic bicycle model
%   - A small Kalman filter estimates yaw acceleration r_dot from measured yaw rate
%
% -------------------------------------------------------------------------

clear; clc; close all;

%% =========================
%  USER / VEHICLE PARAMETERS
%  =========================
P.g   = 9.81;          % [m/s^2]
P.m   = 42000;         % [kg]   <-- replace with CAT truck mass
P.Iz  = 2.8e5;         % [kg*m^2] <-- replace with CAT yaw inertia
P.lf  = 2.8;           % [m]    <-- CG to front axle
P.lr  = 2.4;           % [m]    <-- CG to rear axle
P.Crr = 0.02;          % rolling resistance coefficient (optional)
P.use_grade = false;   % set true if you have grade estimate
P.cos_delta_min = 0.15; % safeguard for large steering angles
P.normalize_Fz = true;  % force Fz_f + Fz_r ~= m*g if desired

%% ====================================
%  EXAMPLE / PLACEHOLDER SENSOR DATA
%  Replace this section with real data
% =====================================
dt = 0.01;
t  = (0:dt:20)';

N = length(t);

% Example steering [rad]
delta = deg2rad(6)*sin(0.4*t);

% Example IMU signals
ax_meas = 0.35*sin(0.6*t) + 0.02*randn(N,1);   % [m/s^2]
ay_meas = 0.60*sin(0.5*t) + 0.03*randn(N,1);   % [m/s^2]
r_meas  = 0.08*sin(0.5*t) + 0.005*randn(N,1);  % [rad/s]

% Example wheel speeds [rad/s]
% These are not used directly in the current estimator core,
% but included for future checks / extensions.
omega_fl = 10 + 0.2*sin(0.4*t);
omega_fr = 10 + 0.2*sin(0.4*t + 0.05);
omega_rl = 10 + 0.15*sin(0.4*t - 0.02);
omega_rr = 10 + 0.15*sin(0.4*t + 0.04);

% Example strut-derived tire normal loads [N]
% Construct realistic axle loads that sum to approximately m*g
W = P.m * P.g;
Fz_front_nom = 0.54*W;
Fz_rear_nom  = 0.46*W;

Fz_fl = 0.5*Fz_front_nom + 8000*sin(0.3*t) + 1000*randn(N,1);
Fz_fr = 0.5*Fz_front_nom - 8000*sin(0.3*t) + 1000*randn(N,1);
Fz_rl = 0.5*Fz_rear_nom  + 6000*sin(0.25*t+0.2) + 1000*randn(N,1);
Fz_rr = 0.5*Fz_rear_nom  - 6000*sin(0.25*t+0.2) + 1000*randn(N,1);

% Optional grade [rad]
grade = zeros(N,1);  % flat ground for now

%% ========================================
%  PACK INTO DATA STRUCTURE FOR ESTIMATOR
% ========================================
data.t       = t;
data.dt      = dt;
data.ax_meas = ax_meas;
data.ay_meas = ay_meas;
data.r_meas  = r_meas;
data.delta   = delta;
data.omega_fl = omega_fl;
data.omega_fr = omega_fr;
data.omega_rl = omega_rl;
data.omega_rr = omega_rr;
data.Fz_fl   = Fz_fl;
data.Fz_fr   = Fz_fr;
data.Fz_rl   = Fz_rl;
data.Fz_rr   = Fz_rr;
data.grade   = grade;

%% ============================
%  RUN AXLE FORCE ESTIMATOR
% ============================
est = run_cat_axle_force_estimator(data, P);

%% ============================
%  PLOTS
% ============================
figure;
plot(t, est.Fx_f, 'LineWidth', 1.5); hold on;
plot(t, est.Fx_r, 'LineWidth', 1.5);
grid on;
xlabel('Time [s]');
ylabel('Longitudinal Axle Force [N]');
legend('F_{x,f}','F_{x,r}','Location','best');
title('Estimated Longitudinal Axle Forces');

figure;
plot(t, est.Fy_f, 'LineWidth', 1.5); hold on;
plot(t, est.Fy_r, 'LineWidth', 1.5);
grid on;
xlabel('Time [s]');
ylabel('Lateral Axle Force [N]');
legend('F_{y,f}','F_{y,r}','Location','best');
title('Estimated Lateral Axle Forces');

figure;
plot(t, est.Fz_f, 'LineWidth', 1.5); hold on;
plot(t, est.Fz_r, 'LineWidth', 1.5);
grid on;
xlabel('Time [s]');
ylabel('Axle Normal Load [N]');
legend('F_{z,f}','F_{z,r}','Location','best');
title('Measured / Processed Axle Normal Loads');

figure;
plot(t, r_meas, 'DisplayName', 'r measured'); hold on;
plot(t, est.r_hat, 'LineWidth', 1.5, 'DisplayName', 'r filtered');
plot(t, est.rdot_hat, 'LineWidth', 1.5, 'DisplayName', 'r dot estimated');
grid on;
xlabel('Time [s]');
ylabel('Yaw signals');
legend('Location','best');
title('Yaw Rate Filtering / Yaw Acceleration Estimate');

%% Optional consistency check
Fx_total_est = est.Fx_f + est.Fx_r;
Fy_total_est = est.Fy_f + est.Fy_r;

figure;
plot(t, Fx_total_est, 'LineWidth', 1.5); hold on;
plot(t, P.m*est.ax_eff, '--', 'LineWidth', 1.2);
grid on;
xlabel('Time [s]');
ylabel('Force [N]');
legend('F_{x,f}+F_{x,r}','m a_{x,eff}','Location','best');
title('Longitudinal Consistency Check');

figure;
plot(t, Fy_total_est, 'LineWidth', 1.5); hold on;
plot(t, P.m*est.ay_filt, '--', 'LineWidth', 1.2);
grid on;
xlabel('Time [s]');
ylabel('Force [N]');
legend('F_{y,f}+F_{y,r}','m a_y','Location','best');
title('Lateral Consistency Check');

%% =========================================================
%  MAIN ESTIMATOR FUNCTION
% =========================================================
function est = run_cat_axle_force_estimator(data, P)

    t  = data.t(:);
    dt = data.dt;
    N  = length(t);

    % Preallocate
    ax_filt  = zeros(N,1);
    ay_filt  = zeros(N,1);
    r_hat    = zeros(N,1);
    rdot_hat = zeros(N,1);

    Fz_f = zeros(N,1);
    Fz_r = zeros(N,1);

    Fx_f = zeros(N,1);
    Fx_r = zeros(N,1);
    Fy_f = zeros(N,1);
    Fy_r = zeros(N,1);

    ax_eff = zeros(N,1);

    % -------------------------------
    % 1) Low-pass filter ax and ay
    % -------------------------------
    fc_acc = 3.0;  % [Hz] cutoff
    alpha_acc = lowpass_alpha(fc_acc, dt);

    ax_filt(1) = data.ax_meas(1);
    ay_filt(1) = data.ay_meas(1);

    for k = 2:N
        ax_filt(k) = alpha_acc*ax_filt(k-1) + (1-alpha_acc)*data.ax_meas(k);
        ay_filt(k) = alpha_acc*ay_filt(k-1) + (1-alpha_acc)*data.ay_meas(k);
    end

    % --------------------------------------------
    % 2) Yaw-rate Kalman filter to estimate r_dot
    % State: x = [r; r_dot]
    % --------------------------------------------
    [r_hat, rdot_hat] = yaw_rate_kf(data.r_meas, dt);

    % -----------------------------------------
    % 3) Build front/rear axle normal loads
    % -----------------------------------------
    for k = 1:N
        Fz_f_raw = data.Fz_fl(k) + data.Fz_fr(k);
        Fz_r_raw = data.Fz_rl(k) + data.Fz_rr(k);

        if P.normalize_Fz
            totalFz = Fz_f_raw + Fz_r_raw;
            if totalFz > 1e-6
                scale = (P.m * P.g) / totalFz;
                Fz_f(k) = Fz_f_raw * scale;
                Fz_r(k) = Fz_r_raw * scale;
            else
                Fz_f(k) = Fz_f_raw;
                Fz_r(k) = Fz_r_raw;
            end
        else
            Fz_f(k) = Fz_f_raw;
            Fz_r(k) = Fz_r_raw;
        end
    end

    % -----------------------------------------
    % 4) Longitudinal estimator (paper-style)
    %     Fx_f = (Fz_f/g)*a_x_eff
    %     Fx_r = (Fz_r/g)*a_x_eff
    % -----------------------------------------
    for k = 1:N

        if P.use_grade
            theta = data.grade(k);
        else
            theta = 0.0;
        end

        % Effective longitudinal acceleration
        % You can simplify this to ax_filt(k) if you want a flatter prototype.
        ax_eff(k) = ax_filt(k) + P.g*sin(theta) + P.Crr*P.g*cos(theta);

        Fx_f(k) = (Fz_f(k)/P.g) * ax_eff(k);
        Fx_r(k) = (Fz_r(k)/P.g) * ax_eff(k);
    end

    % -------------------------------------------------
    % 5) Lateral estimator
    %
    % Coupled steering-aware algebraic bicycle model:
    %
    %   m*a_y = Fx_f*sin(delta) + Fy_f*cos(delta) + Fy_r
    %   Iz*r_dot = lf*(Fx_f*sin(delta)+Fy_f*cos(delta)) - lr*Fy_r
    %
    % Define:
    %   B = m*a_y - Fx_f*sin(delta)
    %   C = Iz*r_dot - lf*Fx_f*sin(delta)
    %
    % Then:
    %   Fy_f = (C + lr*B) / ((lf+lr)*cos(delta))
    %   Fy_r = (lf*B - C) / (lf+lr)
    % -------------------------------------------------
    for k = 1:N
        delta = data.delta(k);
        cdel  = cos(delta);
        sdel  = sin(delta);

        if abs(cdel) < P.cos_delta_min
            % avoid blow-up if steering gets too large
            Fy_f(k) = NaN;
            Fy_r(k) = NaN;
            continue;
        end

        B = P.m * ay_filt(k) - Fx_f(k)*sdel;
        C = P.Iz * rdot_hat(k) - P.lf * Fx_f(k)*sdel;

        Fy_f(k) = (C + P.lr*B) / ((P.lf + P.lr)*cdel);
        Fy_r(k) = (P.lf*B - C) / (P.lf + P.lr);
    end

    % -----------------------------------------
    % 6) Package outputs
    % -----------------------------------------
    est.t = t;
    est.ax_filt  = ax_filt;
    est.ay_filt  = ay_filt;
    est.ax_eff   = ax_eff;
    est.r_hat    = r_hat;
    est.rdot_hat = rdot_hat;

    est.Fz_f = Fz_f;
    est.Fz_r = Fz_r;

    est.Fx_f = Fx_f;
    est.Fx_r = Fx_r;
    est.Fy_f = Fy_f;
    est.Fy_r = Fy_r;
end

%% =========================================================
%  SMALL HELPER: FIRST-ORDER LPF ALPHA
% =========================================================
function alpha = lowpass_alpha(fc, dt)
    tau = 1/(2*pi*fc);
    alpha = tau/(tau + dt);
end

%% =========================================================
%  YAW RATE KALMAN FILTER
%  State x = [r; r_dot]
% =========================================================
function [r_hat, rdot_hat] = yaw_rate_kf(r_meas, dt)

    N = length(r_meas);

    % State-space model
    A = [1 dt;
         0  1];
    C = [1 0];

    % Tuning
    Q = [1e-6 0;
         0    5e-3];
    R = 2e-4;

    % Init
    xhat = [r_meas(1); 0];
    Pk   = eye(2);

    r_hat    = zeros(N,1);
    rdot_hat = zeros(N,1);

    for k = 1:N
        % Predict
        xbar = A*xhat;
        Pbar = A*Pk*A' + Q;

        % Update
        yk = r_meas(k);
        Kk = Pbar*C'/(C*Pbar*C' + R);
        xhat = xbar + Kk*(yk - C*xbar);
        Pk = (eye(2) - Kk*C)*Pbar;

        r_hat(k)    = xhat(1);
        rdot_hat(k) = xhat(2);
    end
end