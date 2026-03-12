%% dual_track_ekf_demo.m
% Self-contained MATLAB rewrite of the Python code.
% Major change:
%   - No CSV access
%   - Synthetic "measured" signals are generated internally
%
% Outputs:
%   - results table in workspace
%   - plots similar to the Python version

clear; clc; close all;

%% ============================================================
% 1) USER PARAMETERS  --- SAME AS PYTHON VERSION
% =============================================================
params = struct();

% -------------------------------------------------------------
% vehicle parameters
% -------------------------------------------------------------
params.m       = 161140.0;    % [kg]
params.Iz      = 2134000.0;   % [kg m^2]
params.Ix      = 950000.0;    % [kg m^2]
params.ms      = 140000.0;    % [kg]
params.lf      = 3.1701;      % [m]
params.lr      = 2.7256;      % [m]
params.tf      = 5.6860;      % [m]
params.tr      = 4.9580;      % [m]
params.Rw      = 1.7;         % [m]
params.h_cg    = 3.2;         % [m]
params.h_roll  = 2.8;         % [m]

% -------------------------------------------------------------
% roll model parameters
% -------------------------------------------------------------
params.k_phi   = 2.0e6;       % [N m/rad]
params.c_phi   = 2.5e5;       % [N m s/rad]

% -------------------------------------------------------------
% optional roll-load-transfer contributions for Fz target
% -------------------------------------------------------------
params.kphi_f  = 0.0;
params.kphi_r  = 0.0;
params.cphi_f  = 0.0;
params.cphi_r  = 0.0;

% -------------------------------------------------------------
% strut calibration:
% Fz = k * pressure + b
% -------------------------------------------------------------
params.k_strut = struct('fl',80.0,'fr',80.0,'rl',80.0,'rr',80.0);
params.b_strut = struct('fl',0.0,'fr',0.0,'rl',0.0,'rr',0.0);

% -------------------------------------------------------------
% normal-load KF parameters
% -------------------------------------------------------------
params.lambda_f = 0.5;
params.lambda_r = 0.5;
params.tau_z    = 0.15;       % [s]

% -------------------------------------------------------------
% optional force constraints / tuning
% -------------------------------------------------------------
params.force_clip_N = 2.0e6;  % [N]

%% ============================================================
% 2) SYNTHETIC "MEASURED" DATA GENERATION
% =============================================================
dt = 0.02;              % [s]
T_end = 40.0;           % [s]
t = (0:dt:T_end)';      % time vector

df = generateSyntheticData(params, t);

%% ============================================================
% 3) RUN FILTERS
% =============================================================
results = runFiltersMATLAB(df, params, dt);

% Save if you want
writetable(results, 'dual_track_ekf_tire_force_and_normal_load_results_matlab.csv');
disp('Saved: dual_track_ekf_tire_force_and_normal_load_results_matlab.csv');

%% ============================================================
% 4) MAKE PLOTS
% =============================================================
makePlotsMATLAB(results);

disp('Done.');

%% ============================================================
% LOCAL FUNCTIONS
% =============================================================

function df = generateSyntheticData(params, t)
% Generates synthetic measured signals so the estimator can run
% without CSV files.

    rng(10); % repeatable noise

    n = numel(t);
    dt = t(2) - t(1);
    g = 9.81;
    L = params.lf + params.lr;

    % ---------------------------------------------------------
    % Define a synthetic maneuver
    % ---------------------------------------------------------
    % Longitudinal speed truth
    vx_true = 9.0 ...
            + 1.5*sin(0.18*t) ...
            + 0.8*sin(0.55*t);

    % Yaw rate truth
    r_true = 0.035*sin(0.35*t) ...
           + 0.015*sin(1.10*t);

    % Lateral speed truth
    vy_true = 0.6*sin(0.35*t - 0.4) ...
            + 0.15*sin(1.0*t);

    % Roll angle truth (small motion)
    phi_true = deg2rad(2.0)*sin(0.45*t);
    phi_dot_true = gradient(phi_true, dt);

    % Time derivatives
    vx_dot_true = gradient(vx_true, dt);
    vy_dot_true = gradient(vy_true, dt);
    r_dot_true  = gradient(r_true, dt);

    % Body-frame accelerations consistent with vehicle dynamics
    ax_true = vx_dot_true - r_true .* vy_true;
    ay_true = vy_dot_true + r_true .* vx_true;

    % ---------------------------------------------------------
    % Build synthetic "true" wheel forces from rigid-body balance
    % ---------------------------------------------------------
    sum_Fx = params.m * ax_true;
    sum_Fy = params.m * ay_true;
    Mz     = params.Iz * r_dot_true;

    % Split longitudinal force equally across all four wheels
    Fx_fl_true = 0.25 * sum_Fx;
    Fx_fr_true = 0.25 * sum_Fx;
    Fx_rl_true = 0.25 * sum_Fx;
    Fx_rr_true = 0.25 * sum_Fx;

    % Solve front/rear lateral axle forces from:
    %   Fyf + Fyr = sum_Fy
    %   lf*Fyf - lr*Fyr = Mz
    Fyf_total = (Mz + params.lr .* sum_Fy) ./ L;
    Fyr_total = sum_Fy - Fyf_total;

    Fy_fl_true = 0.5 * Fyf_total;
    Fy_fr_true = 0.5 * Fyf_total;
    Fy_rl_true = 0.5 * Fyr_total;
    Fy_rr_true = 0.5 * Fyr_total;

    % ---------------------------------------------------------
    % Synthetic normal loads (quasi-static truth)
    % ---------------------------------------------------------
    Fzf = params.m*g*params.lr/L - params.m*ax_true*params.h_cg/L;
    Fzr = params.m*g*params.lf/L + params.m*ax_true*params.h_cg/L;

    dFzf_ay = params.lambda_f * params.m .* ay_true .* params.h_cg / params.tf;
    dFzr_ay = params.lambda_r * params.m .* ay_true .* params.h_cg / params.tr;

    % optional roll contribution
    dFzf_roll = 2.0*(params.kphi_f*phi_true + params.cphi_f*phi_dot_true) / max(params.tf,1e-6);
    dFzr_roll = 2.0*(params.kphi_r*phi_true + params.cphi_r*phi_dot_true) / max(params.tr,1e-6);

    dFzf = dFzf_ay + dFzf_roll;
    dFzr = dFzr_ay + dFzr_roll;

    Fz_fl_true = Fzf/2 - dFzf/2;
    Fz_fr_true = Fzf/2 + dFzf/2;
    Fz_rl_true = Fzr/2 - dFzr/2;
    Fz_rr_true = Fzr/2 + dFzr/2;

    % ---------------------------------------------------------
    % Convert Fz truth into synthetic strut pressures
    %   pressure = (Fz - b)/k
    % ---------------------------------------------------------
    p_fl = (Fz_fl_true - params.b_strut.fl) / params.k_strut.fl;
    p_fr = (Fz_fr_true - params.b_strut.fr) / params.k_strut.fr;
    p_rl = (Fz_rl_true - params.b_strut.rl) / params.k_strut.rl;
    p_rr = (Fz_rr_true - params.b_strut.rr) / params.k_strut.rr;

    % add measurement noise
    p_fl_meas = p_fl + 250*randn(n,1);
    p_fr_meas = p_fr + 250*randn(n,1);
    p_rl_meas = p_rl + 250*randn(n,1);
    p_rr_meas = p_rr + 250*randn(n,1);

    % ---------------------------------------------------------
    % Synthetic wheel speeds
    % ---------------------------------------------------------
    Vx_wheel_fl = vx_true - r_true * params.tf/2;
    Vx_wheel_fr = vx_true + r_true * params.tf/2;
    Vx_wheel_rl = vx_true - r_true * params.tr/2;
    Vx_wheel_rr = vx_true + r_true * params.tr/2;

    % Simple synthetic slip ratio profile
    kappa_fl_true = 0.015*sin(0.40*t);
    kappa_fr_true = 0.013*sin(0.40*t + 0.15);
    kappa_rl_true = 0.018*sin(0.36*t + 0.20);
    kappa_rr_true = 0.017*sin(0.36*t - 0.10);

    omega_fl = Vx_wheel_fl .* (1 + kappa_fl_true) / params.Rw;
    omega_fr = Vx_wheel_fr .* (1 + kappa_fr_true) / params.Rw;
    omega_rl = Vx_wheel_rl .* (1 + kappa_rl_true) / params.Rw;
    omega_rr = Vx_wheel_rr .* (1 + kappa_rr_true) / params.Rw;

    % add wheel-speed noise
    omega_fl_meas = omega_fl + 0.03*randn(n,1);
    omega_fr_meas = omega_fr + 0.03*randn(n,1);
    omega_rl_meas = omega_rl + 0.03*randn(n,1);
    omega_rr_meas = omega_rr + 0.03*randn(n,1);

    % ---------------------------------------------------------
    % Synthetic measured body states / accelerations
    % ---------------------------------------------------------
    vx_meas = vx_true + 0.25*randn(n,1);
    vy_meas = vy_true + 0.20*randn(n,1);
    r_meas  = r_true  + 0.01*randn(n,1);
    ax_meas = ax_true + 0.20*randn(n,1);
    ay_meas = ay_true + 0.20*randn(n,1);

    % ---------------------------------------------------------
    % Assemble MATLAB table
    % ---------------------------------------------------------
    df = table();
    df.time_s = t;
    df.TransmissionTime = t;

    df.VehicleFrameLongitudinalSpeed = vx_meas;
    df.VehicleFrameLateralSpeed      = vy_meas;
    df.YawRate                       = r_meas;
    df.AccelerationX                 = ax_meas;
    df.AccelerationY                 = ay_meas;

    df.WheelSpeed0 = omega_fl_meas;
    df.WheelSpeed1 = omega_fr_meas;
    df.WheelSpeed2 = omega_rl_meas;
    df.WheelSpeed3 = omega_rr_meas;

    df.leftFrontStrutPressureSensorInput_Value  = p_fl_meas;
    df.rightFrontStrutPressureSensorInput_Value = p_fr_meas;
    df.leftRearStrutPressureSensorInput_Value   = p_rl_meas;
    df.rightRearStrutPressureSensorInput_Value  = p_rr_meas;

    % Optional truth channels for debugging
    df.vx_true = vx_true;
    df.vy_true = vy_true;
    df.r_true  = r_true;
    df.ax_true = ax_true;
    df.ay_true = ay_true;

    df.Fx_fl_true = Fx_fl_true;
    df.Fx_fr_true = Fx_fr_true;
    df.Fx_rl_true = Fx_rl_true;
    df.Fx_rr_true = Fx_rr_true;

    df.Fy_fl_true = Fy_fl_true;
    df.Fy_fr_true = Fy_fr_true;
    df.Fy_rl_true = Fy_rl_true;
    df.Fy_rr_true = Fy_rr_true;

    df.Fz_fl_true = Fz_fl_true;
    df.Fz_fr_true = Fz_fr_true;
    df.Fz_rl_true = Fz_rl_true;
    df.Fz_rr_true = Fz_rr_true;
end

function results = runFiltersMATLAB(df, params, dt)

    nSamples = height(df);

    % ---------------------------------------------------------
    % 1) FORCE EKF initialization
    % ---------------------------------------------------------
    x0 = [
        df.VehicleFrameLongitudinalSpeed(1);  % vx
        df.VehicleFrameLateralSpeed(1);       % vy
        df.YawRate(1);                        % r
        0.0;                                  % phi
        0.0;                                  % phi_dot
        0.0; 0.0; 0.0; 0.0;                   % Fx states
        0.0; 0.0; 0.0; 0.0                    % Fy states
    ];

    forceEKF = initDualTrackForceEKF(params, dt, x0);

    % ---------------------------------------------------------
    % 2) NORMAL-LOAD KF initialization
    % ---------------------------------------------------------
    normalKF = initNormalLoadKF(params, dt);
    normalKF = initializeStaticNormalLoadKF(normalKF);

    % ---------------------------------------------------------
    % Preallocate result arrays
    % ---------------------------------------------------------
    time_s      = zeros(nSamples,1);

    vx_meas_arr = zeros(nSamples,1);
    vy_meas_arr = zeros(nSamples,1);
    r_meas_arr  = zeros(nSamples,1);
    ax_meas_arr = zeros(nSamples,1);
    ay_meas_arr = zeros(nSamples,1);

    vx_est_arr      = zeros(nSamples,1);
    vy_est_arr      = zeros(nSamples,1);
    r_est_arr       = zeros(nSamples,1);
    phi_est_arr     = zeros(nSamples,1);
    phi_dot_est_arr = zeros(nSamples,1);

    Fxf_est_arr = zeros(nSamples,1);
    Fxr_est_arr = zeros(nSamples,1);
    Fyf_est_arr = zeros(nSamples,1);
    Fyr_est_arr = zeros(nSamples,1);

    Fx_fl_est_arr = zeros(nSamples,1);
    Fx_fr_est_arr = zeros(nSamples,1);
    Fx_rl_est_arr = zeros(nSamples,1);
    Fx_rr_est_arr = zeros(nSamples,1);

    Fy_fl_est_arr = zeros(nSamples,1);
    Fy_fr_est_arr = zeros(nSamples,1);
    Fy_rl_est_arr = zeros(nSamples,1);
    Fy_rr_est_arr = zeros(nSamples,1);

    Fz_fl_meas_arr = zeros(nSamples,1);
    Fz_fr_meas_arr = zeros(nSamples,1);
    Fz_rl_meas_arr = zeros(nSamples,1);
    Fz_rr_meas_arr = zeros(nSamples,1);

    Fz_fl_est_arr = zeros(nSamples,1);
    Fz_fr_est_arr = zeros(nSamples,1);
    Fz_rl_est_arr = zeros(nSamples,1);
    Fz_rr_est_arr = zeros(nSamples,1);

    kappa_fl_arr = zeros(nSamples,1);
    kappa_fr_arr = zeros(nSamples,1);
    kappa_rl_arr = zeros(nSamples,1);
    kappa_rr_arr = zeros(nSamples,1);

    mu_fl_arr = zeros(nSamples,1);
    mu_fr_arr = zeros(nSamples,1);
    mu_rl_arr = zeros(nSamples,1);
    mu_rr_arr = zeros(nSamples,1);

    % ---------------------------------------------------------
    % Main estimation loop
    % ---------------------------------------------------------
    for k = 1:nSamples
        row = df(k,:);

        % ------------------------------
        % Force EKF
        % ------------------------------
        z_force = [
            row.VehicleFrameLongitudinalSpeed;
            row.VehicleFrameLateralSpeed;
            row.YawRate;
            row.AccelerationX;
            row.AccelerationY
        ];

        [forceEKF, xhat_force] = dualTrackForceEKF_step(forceEKF, z_force, row.AccelerationY);

        vx_est = xhat_force(1);
        vy_est = xhat_force(2);
        r_est  = xhat_force(3);
        phi_est = xhat_force(4);
        phi_dot_est = xhat_force(5);

        Fx_fl_est = xhat_force(6);
        Fx_fr_est = xhat_force(7);
        Fx_rl_est = xhat_force(8);
        Fx_rr_est = xhat_force(9);

        Fy_fl_est = xhat_force(10);
        Fy_fr_est = xhat_force(11);
        Fy_rl_est = xhat_force(12);
        Fy_rr_est = xhat_force(13);

        % ------------------------------
        % Raw strut loads
        % ------------------------------
        Fz_meas = strutPressuresToFzMeas(row, params);

        % ------------------------------
        % Normal-load KF
        % ------------------------------
        [normalKF, Fz_hat] = normalLoadKF_step( ...
            normalKF, row.AccelerationX, row.AccelerationY, Fz_meas, phi_est, phi_dot_est);

        Fz_fl_est = max(Fz_hat(1), 1e-6);
        Fz_fr_est = max(Fz_hat(2), 1e-6);
        Fz_rl_est = max(Fz_hat(3), 1e-6);
        Fz_rr_est = max(Fz_hat(4), 1e-6);

        % ------------------------------
        % Axle-summed forces
        % ------------------------------
        Fxf_est = Fx_fl_est + Fx_fr_est;
        Fxr_est = Fx_rl_est + Fx_rr_est;
        Fyf_est = Fy_fl_est + Fy_fr_est;
        Fyr_est = Fy_rl_est + Fy_rr_est;

        % ------------------------------
        % Slip ratios
        % ------------------------------
        kappa = computeSlipRatios(row, vx_est, r_est, params);

        % ------------------------------
        % Friction utilization
        % ------------------------------
        wheel_forces = struct( ...
            'Fx_fl', Fx_fl_est, 'Fx_fr', Fx_fr_est, 'Fx_rl', Fx_rl_est, 'Fx_rr', Fx_rr_est, ...
            'Fy_fl', Fy_fl_est, 'Fy_fr', Fy_fr_est, 'Fy_rl', Fy_rl_est, 'Fy_rr', Fy_rr_est);

        Fz_struct = struct('fl',Fz_fl_est,'fr',Fz_fr_est,'rl',Fz_rl_est,'rr',Fz_rr_est);
        mu = computeMuUtilization(wheel_forces, Fz_struct);

        % ------------------------------
        % Save
        % ------------------------------
        time_s(k) = row.time_s;

        vx_meas_arr(k) = row.VehicleFrameLongitudinalSpeed;
        vy_meas_arr(k) = row.VehicleFrameLateralSpeed;
        r_meas_arr(k)  = row.YawRate;
        ax_meas_arr(k) = row.AccelerationX;
        ay_meas_arr(k) = row.AccelerationY;

        vx_est_arr(k) = vx_est;
        vy_est_arr(k) = vy_est;
        r_est_arr(k)  = r_est;
        phi_est_arr(k) = phi_est;
        phi_dot_est_arr(k) = phi_dot_est;

        Fxf_est_arr(k) = Fxf_est;
        Fxr_est_arr(k) = Fxr_est;
        Fyf_est_arr(k) = Fyf_est;
        Fyr_est_arr(k) = Fyr_est;

        Fx_fl_est_arr(k) = Fx_fl_est;
        Fx_fr_est_arr(k) = Fx_fr_est;
        Fx_rl_est_arr(k) = Fx_rl_est;
        Fx_rr_est_arr(k) = Fx_rr_est;

        Fy_fl_est_arr(k) = Fy_fl_est;
        Fy_fr_est_arr(k) = Fy_fr_est;
        Fy_rl_est_arr(k) = Fy_rl_est;
        Fy_rr_est_arr(k) = Fy_rr_est;

        Fz_fl_meas_arr(k) = Fz_meas(1);
        Fz_fr_meas_arr(k) = Fz_meas(2);
        Fz_rl_meas_arr(k) = Fz_meas(3);
        Fz_rr_meas_arr(k) = Fz_meas(4);

        Fz_fl_est_arr(k) = Fz_fl_est;
        Fz_fr_est_arr(k) = Fz_fr_est;
        Fz_rl_est_arr(k) = Fz_rl_est;
        Fz_rr_est_arr(k) = Fz_rr_est;

        kappa_fl_arr(k) = kappa.fl;
        kappa_fr_arr(k) = kappa.fr;
        kappa_rl_arr(k) = kappa.rl;
        kappa_rr_arr(k) = kappa.rr;

        mu_fl_arr(k) = mu.fl;
        mu_fr_arr(k) = mu.fr;
        mu_rl_arr(k) = mu.rl;
        mu_rr_arr(k) = mu.rr;
    end

    % ---------------------------------------------------------
    % Create output table
    % ---------------------------------------------------------
    results = table( ...
        time_s, ...
        vx_meas_arr, vy_meas_arr, r_meas_arr, ax_meas_arr, ay_meas_arr, ...
        vx_est_arr, vy_est_arr, r_est_arr, phi_est_arr, phi_dot_est_arr, ...
        Fxf_est_arr, Fxr_est_arr, Fyf_est_arr, Fyr_est_arr, ...
        Fx_fl_est_arr, Fx_fr_est_arr, Fx_rl_est_arr, Fx_rr_est_arr, ...
        Fy_fl_est_arr, Fy_fr_est_arr, Fy_rl_est_arr, Fy_rr_est_arr, ...
        Fz_fl_meas_arr, Fz_fr_meas_arr, Fz_rl_meas_arr, Fz_rr_meas_arr, ...
        Fz_fl_est_arr, Fz_fr_est_arr, Fz_rl_est_arr, Fz_rr_est_arr, ...
        kappa_fl_arr, kappa_fr_arr, kappa_rl_arr, kappa_rr_arr, ...
        mu_fl_arr, mu_fr_arr, mu_rl_arr, mu_rr_arr, ...
        'VariableNames', { ...
        'time_s', ...
        'vx_meas','vy_meas','r_meas','ax_meas','ay_meas', ...
        'vx_est','vy_est','r_est','phi_est','phi_dot_est', ...
        'Fxf_est','Fxr_est','Fyf_est','Fyr_est', ...
        'Fx_fl_est','Fx_fr_est','Fx_rl_est','Fx_rr_est', ...
        'Fy_fl_est','Fy_fr_est','Fy_rl_est','Fy_rr_est', ...
        'Fz_fl_meas','Fz_fr_meas','Fz_rl_meas','Fz_rr_meas', ...
        'Fz_fl_est','Fz_fr_est','Fz_rl_est','Fz_rr_est', ...
        'kappa_fl','kappa_fr','kappa_rl','kappa_rr', ...
        'mu_fl','mu_fr','mu_rl','mu_rr'});
end

%% ============================================================
% FORCE EKF FUNCTIONS
% =============================================================

function ekf = initDualTrackForceEKF(params, dt, x0)

    ekf = struct();
    ekf.m = params.m;
    ekf.Iz = params.Iz;
    ekf.Ix = params.Ix;
    ekf.ms = params.ms;
    ekf.lf = params.lf;
    ekf.lr = params.lr;
    ekf.tf = params.tf;
    ekf.tr = params.tr;
    ekf.h_roll = params.h_roll;
    ekf.k_phi = params.k_phi;
    ekf.c_phi = params.c_phi;
    ekf.force_clip_N = params.force_clip_N;
    ekf.dt = dt;

    ekf.n = 13;
    ekf.nz = 5;

    ekf.x = x0(:);

    ekf.P = diag([ ...
        2.0, ...      % vx
        2.0, ...      % vy
        0.1, ...      % r
        0.02, ...     % phi
        0.5, ...      % phi_dot
        1e6, 1e6, 1e6, 1e6, ... % Fx
        1e6, 1e6, 1e6, 1e6  ... % Fy
    ]);

    ekf.Q = diag([ ...
        0.05, ...
        0.05, ...
        0.01, ...
        1e-4, ...
        0.05, ...
        1e5, 1e5, 1e5, 1e5, ...
        1e5, 1e5, 1e5, 1e5 ...
    ]);

    ekf.R = diag([ ...
        0.5^2, ...
        0.5^2, ...
        0.05^2, ...
        0.75^2, ...
        0.75^2 ...
    ]);
end

function [ekf, xhat] = dualTrackForceEKF_step(ekf, z, ay_meas)
    ekf = dualTrackForceEKF_predict(ekf, ay_meas);
    ekf = dualTrackForceEKF_update(ekf, z);
    xhat = ekf.x;
end

function ekf = dualTrackForceEKF_predict(ekf, ay_meas)
    Fk = dualTrackForceEKF_Fjacobian(ekf, ekf.x);
    ekf.x = dualTrackForceEKF_f(ekf, ekf.x, ay_meas);
    ekf.P = Fk * ekf.P * Fk' + ekf.Q;
end

function ekf = dualTrackForceEKF_update(ekf, z)
    z = z(:);

    Hk = dualTrackForceEKF_Hjacobian(ekf, ekf.x);
    zhat = dualTrackForceEKF_h(ekf, ekf.x);

    y = z - zhat;
    S = Hk * ekf.P * Hk' + ekf.R;
    K = ekf.P * Hk' / S;

    ekf.x = ekf.x + K * y;

    I = eye(ekf.n);
    % Joseph form is more numerically robust
    ekf.P = (I - K*Hk) * ekf.P * (I - K*Hk)' + K*ekf.R*K';

    ekf.x(6:end) = min(max(ekf.x(6:end), -ekf.force_clip_N), ekf.force_clip_N);
end

function x_next = dualTrackForceEKF_f(ekf, x, ay_meas)
    s = unpackForceState(x);

    sum_Fx = s.Fx_fl + s.Fx_fr + s.Fx_rl + s.Fx_rr;
    sum_Fy = s.Fy_fl + s.Fy_fr + s.Fy_rl + s.Fy_rr;

    % body-frame translational dynamics
    vx_dot = s.r * s.vy + sum_Fx / ekf.m;
    vy_dot = -s.r * s.vx + sum_Fy / ekf.m;

    % yaw dynamics
    Mz = ...
        ekf.lf * (s.Fy_fl + s.Fy_fr) ...
      - ekf.lr * (s.Fy_rl + s.Fy_rr) ...
      + (ekf.tf/2) * (s.Fx_fr - s.Fx_fl) ...
      + (ekf.tr/2) * (s.Fx_rr - s.Fx_rl);

    r_dot = Mz / ekf.Iz;

    % roll dynamics
    phi_dot  = s.phi_dot;
    phi_ddot = (ekf.ms * ekf.h_roll * ay_meas ...
               - ekf.c_phi * s.phi_dot ...
               - ekf.k_phi * s.phi) / ekf.Ix;

    x_next = [
        s.vx      + ekf.dt * vx_dot;
        s.vy      + ekf.dt * vy_dot;
        s.r       + ekf.dt * r_dot;
        s.phi     + ekf.dt * phi_dot;
        s.phi_dot + ekf.dt * phi_ddot;
        s.Fx_fl;
        s.Fx_fr;
        s.Fx_rl;
        s.Fx_rr;
        s.Fy_fl;
        s.Fy_fr;
        s.Fy_rl;
        s.Fy_rr
    ];

    x_next(6:end) = min(max(x_next(6:end), -ekf.force_clip_N), ekf.force_clip_N);
end

function Fk = dualTrackForceEKF_Fjacobian(ekf, x)
    s = unpackForceState(x);

    Ac = zeros(ekf.n, ekf.n);

    % vx_dot = r*vy + sumFx/m
    Ac(1,2) = s.r;
    Ac(1,3) = s.vy;
    Ac(1,6) = 1/ekf.m;
    Ac(1,7) = 1/ekf.m;
    Ac(1,8) = 1/ekf.m;
    Ac(1,9) = 1/ekf.m;

    % vy_dot = -r*vx + sumFy/m
    Ac(2,1)  = -s.r;
    Ac(2,3)  = -s.vx;
    Ac(2,10) = 1/ekf.m;
    Ac(2,11) = 1/ekf.m;
    Ac(2,12) = 1/ekf.m;
    Ac(2,13) = 1/ekf.m;

    % r_dot
    Ac(3,6)  = -(ekf.tf/2)/ekf.Iz;
    Ac(3,7)  = +(ekf.tf/2)/ekf.Iz;
    Ac(3,8)  = -(ekf.tr/2)/ekf.Iz;
    Ac(3,9)  = +(ekf.tr/2)/ekf.Iz;
    Ac(3,10) =  ekf.lf/ekf.Iz;
    Ac(3,11) =  ekf.lf/ekf.Iz;
    Ac(3,12) = -ekf.lr/ekf.Iz;
    Ac(3,13) = -ekf.lr/ekf.Iz;

    % phi_dot
    Ac(4,5) = 1.0;

    % phi_ddot
    Ac(5,4) = -ekf.k_phi / ekf.Ix;
    Ac(5,5) = -ekf.c_phi / ekf.Ix;

    Fk = eye(ekf.n) + ekf.dt * Ac;
end

function zhat = dualTrackForceEKF_h(ekf, x)
    s = unpackForceState(x);

    sum_Fx = s.Fx_fl + s.Fx_fr + s.Fx_rl + s.Fx_rr;
    sum_Fy = s.Fy_fl + s.Fy_fr + s.Fy_rl + s.Fy_rr;

    ax = sum_Fx / ekf.m;
    ay = sum_Fy / ekf.m;

    zhat = [
        s.vx;
        s.vy;
        s.r;
        ax;
        ay
    ];
end

function Hk = dualTrackForceEKF_Hjacobian(ekf, ~)
    Hk = zeros(ekf.nz, ekf.n);

    Hk(1,1) = 1.0; % vx
    Hk(2,2) = 1.0; % vy
    Hk(3,3) = 1.0; % r

    Hk(4,6) = 1/ekf.m;
    Hk(4,7) = 1/ekf.m;
    Hk(4,8) = 1/ekf.m;
    Hk(4,9) = 1/ekf.m;

    Hk(5,10) = 1/ekf.m;
    Hk(5,11) = 1/ekf.m;
    Hk(5,12) = 1/ekf.m;
    Hk(5,13) = 1/ekf.m;
end

function s = unpackForceState(x)
    x = x(:);
    s = struct();
    s.vx      = x(1);
    s.vy      = x(2);
    s.r       = x(3);
    s.phi     = x(4);
    s.phi_dot = x(5);

    s.Fx_fl = x(6);
    s.Fx_fr = x(7);
    s.Fx_rl = x(8);
    s.Fx_rr = x(9);

    s.Fy_fl = x(10);
    s.Fy_fr = x(11);
    s.Fy_rl = x(12);
    s.Fy_rr = x(13);
end

%% ============================================================
% NORMAL-LOAD KF FUNCTIONS
% =============================================================

function kf = initNormalLoadKF(params, dt)

    kf = struct();
    kf.m = params.m;
    kf.lf = params.lf;
    kf.lr = params.lr;
    kf.L = params.lf + params.lr;
    kf.h = params.h_cg;
    kf.tf = params.tf;
    kf.tr = params.tr;
    kf.dt = dt;
    kf.g = 9.81;

    kf.lambda_f = params.lambda_f;
    kf.lambda_r = params.lambda_r;
    kf.tau_z    = params.tau_z;

    kf.kphi_f = params.kphi_f;
    kf.kphi_r = params.kphi_r;
    kf.cphi_f = params.cphi_f;
    kf.cphi_r = params.cphi_r;

    kf.n = 4;
    kf.x = zeros(4,1);

    kf.P = diag([1e5, 1e5, 1e5, 1e5]);
    kf.Q = diag([2e4, 2e4, 2e4, 2e4]);
    kf.R = diag([5e4, 5e4, 5e4, 5e4]);
end

function kf = initializeStaticNormalLoadKF(kf)
    Fzf = kf.m * kf.g * kf.lr / kf.L;
    Fzr = kf.m * kf.g * kf.lf / kf.L;

    kf.x = [
        Fzf/2;
        Fzf/2;
        Fzr/2;
        Fzr/2
    ];
end

function x_star = quasiStaticTargetNormalLoadKF(kf, ax, ay, phi, phi_dot)
    Fzf = kf.m*kf.g*kf.lr/kf.L - kf.m*ax*kf.h/kf.L;
    Fzr = kf.m*kf.g*kf.lf/kf.L + kf.m*ax*kf.h/kf.L;

    dFzf_ay = kf.lambda_f * kf.m * ay * kf.h / kf.tf;
    dFzr_ay = kf.lambda_r * kf.m * ay * kf.h / kf.tr;

    dFzf_roll = 2.0*(kf.kphi_f*phi + kf.cphi_f*phi_dot) / max(kf.tf,1e-6);
    dFzr_roll = 2.0*(kf.kphi_r*phi + kf.cphi_r*phi_dot) / max(kf.tr,1e-6);

    dFzf = dFzf_ay + dFzf_roll;
    dFzr = dFzr_ay + dFzr_roll;

    Fz_fl_star = Fzf/2 - dFzf/2;
    Fz_fr_star = Fzf/2 + dFzf/2;
    Fz_rl_star = Fzr/2 - dFzr/2;
    Fz_rr_star = Fzr/2 + dFzr/2;

    x_star = [
        Fz_fl_star;
        Fz_fr_star;
        Fz_rl_star;
        Fz_rr_star
    ];
end

function [kf, xhat] = normalLoadKF_step(kf, ax, ay, z_meas, phi, phi_dot)
    kf = normalLoadKF_predict(kf, ax, ay, phi, phi_dot);
    kf = normalLoadKF_update(kf, z_meas);
    xhat = kf.x;
end

function kf = normalLoadKF_predict(kf, ax, ay, phi, phi_dot)
    x_star = quasiStaticTargetNormalLoadKF(kf, ax, ay, phi, phi_dot);

    A = (1 - kf.dt/kf.tau_z) * eye(4);
    B = (kf.dt/kf.tau_z) * eye(4);

    kf.x = A*kf.x + B*x_star;
    kf.P = A*kf.P*A' + kf.Q;
end

function kf = normalLoadKF_update(kf, z_meas)
    z = z_meas(:);
    H = eye(4);

    y = z - H*kf.x;
    S = H*kf.P*H' + kf.R;
    K = kf.P*H'/S;

    kf.x = kf.x + K*y;

    I = eye(4);
    kf.P = (I - K*H)*kf.P*(I - K*H)' + K*kf.R*K';
end

%% ============================================================
% HELPER FUNCTIONS
% =============================================================

function Fz = strutPressuresToFzMeas(row, params)

    Fz_fl = params.k_strut.fl * row.leftFrontStrutPressureSensorInput_Value  + params.b_strut.fl;
    Fz_fr = params.k_strut.fr * row.rightFrontStrutPressureSensorInput_Value + params.b_strut.fr;
    Fz_rl = params.k_strut.rl * row.leftRearStrutPressureSensorInput_Value   + params.b_strut.rl;
    Fz_rr = params.k_strut.rr * row.rightRearStrutPressureSensorInput_Value  + params.b_strut.rr;

    Fz = max([Fz_fl; Fz_fr; Fz_rl; Fz_rr], 1e-6);
end

function Vx_wheels = computeWheelLongitudinalSpeeds(vx, r, tf, tr)
    Vx_wheels = struct();
    Vx_wheels.fl = vx - r*tf/2;
    Vx_wheels.fr = vx + r*tf/2;
    Vx_wheels.rl = vx - r*tr/2;
    Vx_wheels.rr = vx + r*tr/2;
end

function kappa = computeSlipRatios(row, vx, r, params)
    eps_val = 0.25;

    Vx_wheels = computeWheelLongitudinalSpeeds(vx, r, params.tf, params.tr);

    omega.fl = row.WheelSpeed0;
    omega.fr = row.WheelSpeed1;
    omega.rl = row.WheelSpeed2;
    omega.rr = row.WheelSpeed3;

    keys = {'fl','fr','rl','rr'};
    kappa = struct();

    for i = 1:numel(keys)
        key = keys{i};
        num = params.Rw * omega.(key) - Vx_wheels.(key);
        den = max([abs(params.Rw * omega.(key)), abs(Vx_wheels.(key)), eps_val]);
        kappa.(key) = num / den;
    end
end

function mu = computeMuUtilization(wheel_forces, Fz)
    mu = struct();

    mu.fl = sqrt(wheel_forces.Fx_fl^2 + wheel_forces.Fy_fl^2) / max(Fz.fl,1e-6);
    mu.fr = sqrt(wheel_forces.Fx_fr^2 + wheel_forces.Fy_fr^2) / max(Fz.fr,1e-6);
    mu.rl = sqrt(wheel_forces.Fx_rl^2 + wheel_forces.Fy_rl^2) / max(Fz.rl,1e-6);
    mu.rr = sqrt(wheel_forces.Fx_rr^2 + wheel_forces.Fy_rr^2) / max(Fz.rr,1e-6);
end

%% ============================================================
% PLOTTING
% =============================================================

function makePlotsMATLAB(results)
    t = results.time_s;

    % ---------------------------------------------------------
    % Plot 1: measured vs estimated vehicle states
    % ---------------------------------------------------------
    figure('Name','State Comparison','Color','w');

    subplot(4,1,1);
    plot(t, results.vx_meas, 'DisplayName','vx meas'); hold on;
    plot(t, results.vx_est, '--', 'DisplayName','vx est');
    ylabel('vx [m/s]'); title('Longitudinal Speed'); grid on; legend;

    subplot(4,1,2);
    plot(t, results.vy_meas, 'DisplayName','vy meas'); hold on;
    plot(t, results.vy_est, '--', 'DisplayName','vy est');
    ylabel('vy [m/s]'); title('Lateral Speed'); grid on; legend;

    subplot(4,1,3);
    plot(t, results.r_meas, 'DisplayName','r meas'); hold on;
    plot(t, results.r_est, '--', 'DisplayName','r est');
    ylabel('r [rad/s]'); title('Yaw Rate'); grid on; legend;

    subplot(4,1,4);
    plot(t, results.phi_est, 'DisplayName','phi est'); hold on;
    plot(t, results.phi_dot_est, 'DisplayName','phi\_dot est');
    ylabel('roll'); xlabel('time [s]'); title('Estimated Roll States'); grid on; legend;

    % ---------------------------------------------------------
    % Plot 2: axle-summed estimated forces
    % ---------------------------------------------------------
    figure('Name','Axle Forces','Color','w');

    subplot(2,1,1);
    plot(t, results.Fxf_est, 'DisplayName','Fxf axle sum'); hold on;
    plot(t, results.Fxr_est, 'DisplayName','Fxr axle sum');
    ylabel('Force [N]'); title('Estimated Axle Longitudinal Forces'); grid on; legend;

    subplot(2,1,2);
    plot(t, results.Fyf_est, 'DisplayName','Fyf axle sum'); hold on;
    plot(t, results.Fyr_est, 'DisplayName','Fyr axle sum');
    ylabel('Force [N]'); xlabel('time [s]'); title('Estimated Axle Lateral Forces'); grid on; legend;

    % ---------------------------------------------------------
    % Plot 3: per-wheel longitudinal forces
    % ---------------------------------------------------------
    figure('Name','Wheel Fx','Color','w');
    plot(t, results.Fx_fl_est, 'DisplayName','Fx fl'); hold on;
    plot(t, results.Fx_fr_est, 'DisplayName','Fx fr');
    plot(t, results.Fx_rl_est, 'DisplayName','Fx rl');
    plot(t, results.Fx_rr_est, 'DisplayName','Fx rr');
    ylabel('Force [N]'); xlabel('time [s]');
    title('Estimated Per-Wheel Longitudinal Forces'); grid on; legend;

    % ---------------------------------------------------------
    % Plot 4: per-wheel lateral forces
    % ---------------------------------------------------------
    figure('Name','Wheel Fy','Color','w');
    plot(t, results.Fy_fl_est, 'DisplayName','Fy fl'); hold on;
    plot(t, results.Fy_fr_est, 'DisplayName','Fy fr');
    plot(t, results.Fy_rl_est, 'DisplayName','Fy rl');
    plot(t, results.Fy_rr_est, 'DisplayName','Fy rr');
    ylabel('Force [N]'); xlabel('time [s]');
    title('Estimated Per-Wheel Lateral Forces'); grid on; legend;

    % ---------------------------------------------------------
    % Plot 5: measured vs estimated Fz
    % ---------------------------------------------------------
    figure('Name','Normal Loads Comparison','Color','w');

    subplot(4,1,1);
    plot(t, results.Fz_fl_meas, 'DisplayName','FL meas'); hold on;
    plot(t, results.Fz_fl_est, '--', 'DisplayName','FL est');
    ylabel('N'); title('FL Normal Load'); grid on; legend;

    subplot(4,1,2);
    plot(t, results.Fz_fr_meas, 'DisplayName','FR meas'); hold on;
    plot(t, results.Fz_fr_est, '--', 'DisplayName','FR est');
    ylabel('N'); title('FR Normal Load'); grid on; legend;

    subplot(4,1,3);
    plot(t, results.Fz_rl_meas, 'DisplayName','RL meas'); hold on;
    plot(t, results.Fz_rl_est, '--', 'DisplayName','RL est');
    ylabel('N'); title('RL Normal Load'); grid on; legend;

    subplot(4,1,4);
    plot(t, results.Fz_rr_meas, 'DisplayName','RR meas'); hold on;
    plot(t, results.Fz_rr_est, '--', 'DisplayName','RR est');
    ylabel('N'); xlabel('time [s]'); title('RR Normal Load'); grid on; legend;

    % ---------------------------------------------------------
    % Plot 6: slip ratios
    % ---------------------------------------------------------
    figure('Name','Slip Ratios','Color','w');
    plot(t, results.kappa_fl, 'DisplayName','kappa fl'); hold on;
    plot(t, results.kappa_fr, 'DisplayName','kappa fr');
    plot(t, results.kappa_rl, 'DisplayName','kappa rl');
    plot(t, results.kappa_rr, 'DisplayName','kappa rr');
    ylabel('Slip ratio [-]'); xlabel('time [s]');
    title('Per-Wheel Slip Ratios'); grid on; legend;

    % ---------------------------------------------------------
    % Plot 7: friction utilization
    % ---------------------------------------------------------
    figure('Name','Mu Utilization','Color','w');
    plot(t, results.mu_fl, 'DisplayName','mu fl'); hold on;
    plot(t, results.mu_fr, 'DisplayName','mu fr');
    plot(t, results.mu_rl, 'DisplayName','mu rl');
    plot(t, results.mu_rr, 'DisplayName','mu rr');
    ylabel('\mu utilization [-]'); xlabel('time [s]');
    title('Per-Wheel Friction Utilization'); grid on; legend;

    % ---------------------------------------------------------
    % Plot 8: mu vs slip scatter
    % ---------------------------------------------------------
    figure('Name','Mu vs Slip','Color','w');
    scatter(results.kappa_fl, results.mu_fl, 8, 'DisplayName','FL'); hold on;
    scatter(results.kappa_fr, results.mu_fr, 8, 'DisplayName','FR');
    scatter(results.kappa_rl, results.mu_rl, 8, 'DisplayName','RL');
    scatter(results.kappa_rr, results.mu_rr, 8, 'DisplayName','RR');
    xlabel('Slip ratio \kappa [-]');
    ylabel('\mu utilization [-]');
    title('\mu vs Slip Ratio');
    grid on; legend;
end