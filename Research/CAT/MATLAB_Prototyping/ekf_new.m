%% cat_hybrid_force_estimator_demo.m
% Hybrid EKF + constrained body-force allocation demo for the CAT truck.
% -----------------------------------------------------------------------
% IMPORTANT:
% 1) This is a structured DEMO implementation with FAKE measurements.
% 2) The estimator works on four contact groups:
%       FL, FR, RL_dual, RR_dual
%    because the spec sheet shows 2 front tires and 4 rear tires.
%    So each rear "corner" here represents the combined force of the rear
%    dual-tire pair on that side.
% 3) The section named "FAKE MEASUREMENTS" is the one you will later swap
%    with your real CSV import code.
%
% What this script does:
%   - uses loaded-truck parameters from the CAT spec sheet
%   - generates fake GPS/IMU/wheel-speed/strut-load measurements
%   - runs an EKF on [u v r Dx Dyf Dyr bax bay br]'
%   - fuses physics-based and strut-based normal loads
%   - solves for Fx,Fy at FL, FR, RL, RR using a constrained force solve
%   - runs a small EKF to estimate Burckhardt parameters per contact group
%
% State vector:
%   x = [u; v; r; Dx; Dyf; Dyr; bax; bay; br]
% where
%   u,v,r = body longitudinal velocity, lateral velocity, yaw rate
%   Dx    = longitudinal load transfer state
%   Dyf   = front lateral load transfer state
%   Dyr   = rear lateral load transfer state
%   bax,bay,br = sensor biases
%
% Force vector ordering used everywhere:
%   f = [Fx_FL; Fx_FR; Fx_RL; Fx_RR; Fy_FL; Fy_FR; Fy_RL; Fy_RR]
%
% Author note:
% This is meant to be readable first, not hyper-optimized.

clear; clc; close all;
rng(7);

%% ======================================================================
%% 1) LOADED TRUCK PARAMETERS FROM THE CAT SPEC SHEET
%% ======================================================================
g = 9.81;

P = struct();
P.g   = g;
P.m   = 379.140e3;          % kg   (379.140 Mg)
P.Iz  = 4.253e9 * 1e-3;     % kg*m^2  (Mg-mm^2 -> kg*m^2)
P.a   = 3979.1e-3;          % m
P.b   = 1917.7e-3;          % m
P.L   = 5896.8e-3;          % m
P.tf  = 5674.0e-3;          % m, front track
P.tr  = 4958.0e-3;          % m, rear track (distance between dual groups)
P.h   = 4138.0e-3;          % m, CG height wrt ground
P.Ref = 1700.0e-3;          % m, front effective rolling radius
P.Rer = 1700.0e-3;          % m, rear effective rolling radius
P.R   = [P.Ref; P.Ref; P.Rer; P.Rer];

% Loaded axle forces from the spec sheet
P.Fa = 1209586.8;           % N, front axle load
P.Fb = 2509776.6;           % N, rear axle load

% Static per-corner loads in this 4-contact-group model.
% Rear left / right each represent a dual-tire pair.
P.Fz0 = [P.Fa/2; P.Fa/2; P.Fb/2; P.Fb/2];

% Actual tire counts from the spec sheet
P.nFrontTires = 2;
P.nRearTires  = 4;

% Vertical stiffness from loaded values in the spec
P.Kz_f = 4.331e6;           % N/m
P.Kz_r = 4.205e6;           % N/m

% Some estimator tuning / regularization choices
P.muBound        = 1.20;    % hard force bound in the allocator
P.rollSplitFront = 0.45;    % how much lateral transfer lands on front axle
P.rollSplitRear  = 0.55;    % how much lateral transfer lands on rear axle
P.driveBiasRear  = 0.85;    % only used as a soft prior if you want rear-drive bias later
P.minFz          = 0.10 * min(P.Fz0);

% Load-transfer state dynamics tuning
P.tau_x  = 0.18;
P.tau_yf = 0.20;
P.tau_yr = 0.20;
P.kx  = P.m * P.h / (2*P.L);       % N per (m/s^2)
P.kyf = P.rollSplitFront * P.m * P.h / P.tf;
P.kyr = P.rollSplitRear  * P.m * P.h / P.tr;

%% ======================================================================
%% 2) SIMULATION SETTINGS
%% ======================================================================
dt = 0.01;
T  = 25;
N  = round(T/dt);
t  = (0:N-1)'*dt;

%% ======================================================================
%% 3) FAKE TRUE VEHICLE MOTION
%% ======================================================================
% These are not from data yet. They are just smooth motion profiles so the
% estimator has something to work with.

u_true = 12.0 ...
       + 0.7*sin(0.12*t) ...
       - 1.4*exp(-0.5*((t-16.0)/1.2).^2) ...
       + 0.3*exp(-0.5*((t-6.0)/0.8).^2);

v_true = 0.35*sin(0.55*t) + 0.20*sin(1.05*t + 0.6);
r_true = 0.030*sin(0.55*t) + 0.018*sin(1.05*t + 0.4);
delta  = deg2rad(3.0)*sin(0.55*t) + deg2rad(1.2)*sin(1.05*t + 0.3);

udot_true = gradient(u_true, dt);
vdot_true = gradient(v_true, dt);
rdot_true = gradient(r_true, dt);

ax_true = udot_true - v_true.*r_true;
ay_true = vdot_true + u_true.*r_true;

%% ======================================================================
%% 4) TRUE NORMAL LOADS + TRUE FORCES (STILL SYNTHETIC)
%% ======================================================================
Fz_true = zeros(N,4);
F_true  = zeros(N,8);
alpha_true = zeros(N,4);
lambda_true = zeros(N,4);
omega_true  = zeros(N,4);
mu_mob_true = zeros(N,4);

f_prev_truth = zeros(8,1);

for k = 1:N
    % Quasi-static "true" load transfer used only to synthesize fake data
    Dx_t  = P.kx  * ax_true(k);
    Dyf_t = P.kyf * ay_true(k);
    Dyr_t = P.kyr * ay_true(k);

    Fz_k = normalLoadsFromTransfer(P, [Dx_t; Dyf_t; Dyr_t]);
    Fz_true(k,:) = Fz_k.';

    % Build a consistent true force vector from body demands
    [f_k, ~] = allocateTireForces(P, delta(k), ax_true(k), ay_true(k), ...
                                  rdot_true(k), Fz_k, f_prev_truth, 1.10);
    F_true(k,:) = f_k.';
    f_prev_truth = f_k;

    % Wheel kinematics for synthetic wheel speed generation
    kin = wheelKinematics(u_true(k), v_true(k), r_true(k), delta(k), P);
    alpha_true(k,:) = kin.alpha.';

    % Fake slip ratios per contact group
    lam_base = 0.010*sin(0.45*t(k) + [0.00 0.25 0.50 0.75]) ...
             + 0.035*exp(-0.5*((t(k)-16.0)/1.0)^2) ...
             - 0.020*exp(-0.5*((t(k)-8.0)/0.7)^2);
    lam_base = max(-0.15, min(0.20, lam_base));
    lambda_true(k,:) = lam_base;

    omega_true(k,:) = ((1 + lambda_true(k,:).').*kin.Vx_local ./ P.R).';

    mu_mob_true(k,:) = sqrt(f_k(1:4).^2 + f_k(5:8).^2).' ./ max(Fz_k.',1);
end

%% ======================================================================
%% 5) FAKE MEASUREMENTS
%% ======================================================================
% This whole section is where you will later replace things with CSV reads.
% For now we make noisy sensor channels.

% True sensor biases (unknown to the estimator)
bax_true =  0.020*g;
bay_true = -0.015*g;
br_true  =  0.0015;

ax_meas = ax_true + bax_true + 0.0003*g*randn(N,1);
ay_meas = ay_true + bay_true + 0.0003*g*randn(N,1);
r_meas  = r_true  + br_true  + 0.00002*randn(N,1);

u_gps = u_true + 0.0010*randn(N,1);
v_gps = v_true + 0.0005*randn(N,1);

omega_meas = omega_true .* (1 + 0.00003*randn(N,4)) + 0.0001*randn(N,4);

% Fake strut-derived vertical load measurements at each contact group.
% In your real pipeline you may build these from strut pressure channels.
Fz_strut_meas = Fz_true .* (1 + 0.02*randn(N,4)) + 5000*randn(N,4);
Fz_strut_meas = max(Fz_strut_meas, 0.05*min(P.Fz0));

rdot_meas = gradient(r_meas, dt);

%% ======================================================================
%% 6) MAIN ESTIMATOR STORAGE
%% ======================================================================
% EKF state: [u v r Dx Dyf Dyr bax bay br]'
xhat_hist = zeros(N,9);
Phat_hist = zeros(9,9,N);

Fz_est = zeros(N,4);
F_est  = zeros(N,8);
alpha_est = zeros(N,4);
lambda_est = zeros(N,4);
mu_mob_est = zeros(N,4);

% Burckhardt parameter estimates per contact group: theta = [C1 C2 C3]'
theta_hist = zeros(N,3,4);
mu_peak_hist = zeros(N,4);

%% ======================================================================
%% 7) EKF INITIALIZATION
%% ======================================================================
xhat = [u_gps(1); v_gps(1); r_meas(1); 0; 0; 0; 0; 0; 0];
Pekf = diag([ ...
    0.5^2, ...          % u
    0.3^2, ...          % v
    0.02^2, ...         % r
    (2e5)^2, ...        % Dx
    (2e5)^2, ...        % Dyf
    (2e5)^2, ...        % Dyr
    (0.20)^2, ...       % bax
    (0.20)^2, ...       % bay
    (0.01)^2]);         % br

Qekf = diag([ ...
    0.05^2, ...
    0.05^2, ...
    0.005^2, ...
    (4e4)^2, ...
    (5e4)^2, ...
    (5e4)^2, ...
    (0.004)^2, ...
    (0.004)^2, ...
    (0.0003)^2]);

Rekf = diag([ ...
    (0.05*g)^2, ...
    (0.05*g)^2, ...
    0.004^2, ...
    0.15^2, ...
    0.08^2]);

% Force estimate carried from one step to the next
f_prev_est = zeros(8,1);

% Burckhardt EKF init per contact group
Theta = repmat([1.00; 8.0; 0.20], 1, 4);
Ptheta = zeros(3,3,4);
for i = 1:4
    Ptheta(:,:,i) = diag([0.20^2, 3.0^2, 0.15^2]);
end

xhat_hist(1,:) = xhat.';
Phat_hist(:,:,1) = Pekf;
Fz_est(1,:) = P.Fz0.';

%% ======================================================================
%% 8) MAIN ESTIMATION LOOP
%% ======================================================================
for k = 2:N
    % --------------------------------------------------------------
    % 8.1) EKF prediction
    % --------------------------------------------------------------
    [xpred, Fk] = processModel(xhat, dt, P, f_prev_est, delta(k-1), ...
                               ax_meas(k-1), ay_meas(k-1));
    Ppred = Fk * Pekf * Fk.' + Qekf;

    % --------------------------------------------------------------
    % 8.2) EKF update
    % --------------------------------------------------------------
    zk = [ax_meas(k); ay_meas(k); r_meas(k); u_gps(k); v_gps(k)];
    hk = measurementModel(xpred, f_prev_est, delta(k), P);
    Hk = measurementJacobian();

    Sk = Hk * Ppred * Hk.' + Rekf;
    Kk = Ppred * Hk.' / Sk;

    xhat = xpred + Kk * (zk - hk);
    Pekf = (eye(9) - Kk*Hk) * Ppred;

    % --------------------------------------------------------------
    % 8.3) Normal load estimation: physics + fake strut fusion
    % --------------------------------------------------------------
    Fz_phys = normalLoadsFromTransfer(P, xhat(4:6));
    Fz_fused = 0.65*Fz_phys + 0.35*Fz_strut_meas(k,:).';
    Fz_fused = max(Fz_fused, P.minFz);

    % --------------------------------------------------------------
    % 8.4) Wheel kinematics using EKF state + measured wheel speeds
    % --------------------------------------------------------------
    kin = wheelKinematics(xhat(1), xhat(2), xhat(3), delta(k), P);
    alpha_est(k,:) = kin.alpha.';

    wheelLin = P.R .* omega_meas(k,:).';
    denom = max([abs(kin.Vx_local), abs(wheelLin), 0.25*ones(4,1)], [], 2);
    lam_long = (wheelLin - kin.Vx_local) ./ denom;
    lam_long = max(-0.30, min(0.30, lam_long));
    lambda_est(k,:) = lam_long.';

    % --------------------------------------------------------------
    % 8.5) Constrained force allocation
    % --------------------------------------------------------------
    ax_hat   = ax_meas(k) - xhat(7);
    ay_hat   = ay_meas(k) - xhat(8);
    rdot_hat = rdot_meas(k);

    [f_est_k, ~] = allocateTireForces(P, delta(k), ax_hat, ay_hat, ...
                                      rdot_hat, Fz_fused, f_prev_est, P.muBound);
    f_prev_est = f_est_k;

    % --------------------------------------------------------------
    % 8.6) Mobilized friction and tire-parameter EKF per contact group
    % --------------------------------------------------------------
    mu_mob_k = sqrt(f_est_k(1:4).^2 + f_est_k(5:8).^2) ./ max(Fz_fused,1);
    mu_mob_k = max(0.0, min(1.30, mu_mob_k));

    lam_res = sqrt(lam_long.^2 + tan(kin.alpha).^2);
    lam_res = max(1e-4, min(0.8, lam_res));

    for i = 1:4
        [Theta(:,i), Ptheta(:,:,i), mu_peak_i] = burckhardtParamEKF( ...
            Theta(:,i), Ptheta(:,:,i), lam_res(i), mu_mob_k(i));
        mu_peak_hist(k,i) = mu_peak_i;
    end

    % --------------------------------------------------------------
    % 8.7) Log everything
    % --------------------------------------------------------------
    xhat_hist(k,:) = xhat.';
    Phat_hist(:,:,k) = Pekf;
    Fz_est(k,:) = Fz_fused.';
    F_est(k,:)  = f_est_k.';
    mu_mob_est(k,:) = mu_mob_k.';

    for i = 1:4
        theta_hist(k,:,i) = Theta(:,i).';
    end
end

%% ======================================================================
%% 9) PLOTS
%% ======================================================================
cornerNames = {'FL','FR','RL_{dual}','RR_{dual}'};

figure('Name','State estimation','Color','w');
subplot(3,1,1);
plot(t,u_true); hold on;
plot(t,xhat_hist(:,1),'r');
grid on; ylabel('u [m/s]'); legend('true','est'); title('Velocity states');

subplot(3,1,2);
plot(t,v_true); hold on;
plot(t,xhat_hist(:,2),'r');
grid on; ylabel('v [m/s]'); legend('true','est');

subplot(3,1,3);
plot(t,r_true); hold on;
plot(t,xhat_hist(:,3),'r');
grid on; ylabel('r [rad/s]'); xlabel('time [s]'); legend('true','est');

figure('Name','Normal loads','Color','w');
for i = 1:4
    subplot(2,2,i);
    plot(t, Fz_true(:,i)/1e3); hold on;
    plot(t, Fz_est(:,i)/1e3);
    grid on;
    xlabel('time [s]'); ylabel('F_z [kN]');
    title(cornerNames{i});
    legend('true','estimated','Location','best');
end
sgtitle('Corner normal loads');

figure('Name','Longitudinal forces','Color','w');
for i = 1:4
    subplot(2,2,i);
    plot(t, F_est(:,i)/1e3,  'r');
    hold on;
    plot(t, F_true(:,i)/1e3);
   
    grid on;
    xlabel('time [s]'); ylabel('F_x [kN]');
    title(cornerNames{i});
    legend('est','true','Location','best');
end
sgtitle('Corner longitudinal forces');

figure('Name','Lateral forces','Color','w');
for i = 1:4
    subplot(2,2,i);
    plot(t, F_est(:,i+4)/1e3,'r');
    hold on;

    plot(t, F_true(:,i+4)/1e3);
   
    grid on;
    xlabel('time [s]'); ylabel('F_y [kN]');
    title(cornerNames{i});
    legend('est','true','Location','best');
end
sgtitle('Corner lateral forces');

figure('Name','Slip and mobilized friction','Color','w');
for i = 1:4
    subplot(2,2,i);
    yyaxis left;
    plot(t, lambda_est(:,i)); hold on;
    ylabel('\lambda');
    yyaxis right;
    plot(t, mu_mob_est(:,i), 'r');
    ylabel('\mu_{mob}');
    grid on;
    xlabel('time [s]');
    title(cornerNames{i});
end
sgtitle('Estimated slip and mobilized friction');

figure('Name','Peak friction estimate','Color','w');
for i = 1:4
    subplot(2,2,i);
    plot(t, mu_peak_hist(:,i));
    grid on;
    xlabel('time [s]'); ylabel('\mu_{peak}');
    title(cornerNames{i});
end
sgtitle('Burckhardt peak-friction estimate');

%% ======================================================================
%% 10) PRINT SOME SUMMARY NUMBERS
%% ======================================================================
Fx_rmse = sqrt(mean((F_est(:,1:4) - F_true(:,1:4)).^2, 1));
Fy_rmse = sqrt(mean((F_est(:,5:8) - F_true(:,5:8)).^2, 1));
Fz_rmse = sqrt(mean((Fz_est - Fz_true).^2, 1));

fprintf('\n===== RMSE SUMMARY =====\n');
for i = 1:4
    fprintf('%s  :  Fz RMSE = %8.1f N,   Fx RMSE = %8.1f N,   Fy RMSE = %8.1f N\n', ...
        cornerNames{i}, Fz_rmse(i), Fx_rmse(i), Fy_rmse(i));
end
fprintf('========================\n\n');

%% ======================================================================
%% LOCAL FUNCTIONS
%% ======================================================================
function Fz = normalLoadsFromTransfer(P, D)
% D = [Dx; Dyf; Dyr]
Dx  = D(1);
Dyf = D(2);
Dyr = D(3);

Fz = [ ...
    P.Fz0(1) - Dx - Dyf; ...
    P.Fz0(2) - Dx + Dyf; ...
    P.Fz0(3) + Dx - Dyr; ...
    P.Fz0(4) + Dx + Dyr];

Fz = max(Fz, P.minFz);
end

function kin = wheelKinematics(u, v, r, delta, P)
% Body-frame contact point velocities:
% Vx_i = u - r*y_i
% Vy_i = v + r*x_i

yFL = +P.tf/2; yFR = -P.tf/2;
yRL = +P.tr/2; yRR = -P.tr/2;

xF = +P.a;
xR = -P.b;

Vx_b = [u - r*yFL; ...
        u - r*yFR; ...
        u - r*yRL; ...
        u - r*yRR];

Vy_b = [v + r*xF; ...
        v + r*xF; ...
        v + r*xR; ...
        v + r*xR];

c = cos(delta);
s = sin(delta);

% Rotate front wheel velocities into the steered wheel frame
Vx_local = zeros(4,1);
Vy_local = zeros(4,1);

Vx_local(1) =  c*Vx_b(1) + s*Vy_b(1);
Vy_local(1) = -s*Vx_b(1) + c*Vy_b(1);

Vx_local(2) =  c*Vx_b(2) + s*Vy_b(2);
Vy_local(2) = -s*Vx_b(2) + c*Vy_b(2);

Vx_local(3) = Vx_b(3);
Vy_local(3) = Vy_b(3);

Vx_local(4) = Vx_b(4);
Vy_local(4) = Vy_b(4);

alpha = atan2(Vy_local, max(abs(Vx_local), 0.10));

kin = struct();
kin.Vx_body  = Vx_b;
kin.Vy_body  = Vy_b;
kin.Vx_local = Vx_local;
kin.Vy_local = Vy_local;
kin.alpha    = alpha;
end

function [FxBody, FyBody, Mz] = bodyTotalsFromLocal(f, delta, P)
% f = [FxFL FxFR FxRL FxRR FyFL FyFR FyRL FyRR]'
Fx = f(1:4);
Fy = f(5:8);

c = cos(delta);
s = sin(delta);

% Convert front local forces to body frame
FxB_FL = c*Fx(1) - s*Fy(1);
FyB_FL = s*Fx(1) + c*Fy(1);

FxB_FR = c*Fx(2) - s*Fy(2);
FyB_FR = s*Fx(2) + c*Fy(2);

FxB_RL = Fx(3);
FyB_RL = Fy(3);

FxB_RR = Fx(4);
FyB_RR = Fy(4);

FxBody = FxB_FL + FxB_FR + FxB_RL + FxB_RR;
FyBody = FyB_FL + FyB_FR + FyB_RL + FyB_RR;

% Yaw moment Mz = x*Fy - y*Fx
Mz = P.a*FyB_FL - (P.tf/2)*FxB_FL ...
   + P.a*FyB_FR + (P.tf/2)*FxB_FR ...
   - P.b*FyB_RL - (P.tr/2)*FxB_RL ...
   - P.b*FyB_RR + (P.tr/2)*FxB_RR;
end

function Aeq = buildForceBalanceMatrix(P, delta)
% Builds the exact linear map from local tire force vector f to:
% [sum Fx_body; sum Fy_body; Mz]

c = cos(delta);
s = sin(delta);

Aeq = zeros(3,8);

% Row 1: total body longitudinal force
Aeq(1,:) = [c, c, 1, 1, -s, -s, 0, 0];

% Row 2: total body lateral force
Aeq(2,:) = [s, s, 0, 0, c, c, 1, 1];

% Row 3: yaw moment
Aeq(3,1) = P.a*s - (P.tf/2)*c;   % Fx_FL coeff
Aeq(3,2) = P.a*s + (P.tf/2)*c;   % Fx_FR coeff
Aeq(3,3) = -(P.tr/2);            % Fx_RL coeff
Aeq(3,4) = +(P.tr/2);            % Fx_RR coeff
Aeq(3,5) = P.a*c + (P.tf/2)*s;   % Fy_FL coeff
Aeq(3,6) = P.a*c - (P.tf/2)*s;   % Fy_FR coeff
Aeq(3,7) = -P.b;                 % Fy_RL coeff
Aeq(3,8) = -P.b;                 % Fy_RR coeff
end

function [f, debug] = allocateTireForces(P, delta, ax, ay, rdot, Fz, f_prev, muBound)
% Solves a constrained force allocation problem.
% Equality constraints enforce body force / yaw moment balance.
% The quadratic objective pulls the solution toward:
%   (a) a load-weighted nominal force split
%   (b) the previous timestep force estimate

Xreq = P.m * ax;
Yreq = P.m * ay;
Nreq = P.Iz * rdot;

% Nominal axle lateral split from bicycle-style force/moment balance
FyF_tot = (P.b/P.L)*Yreq + Nreq/P.L;
FyR_tot = (P.a/P.L)*Yreq - Nreq/P.L;

% Nominal axle longitudinal split by instantaneous normal-load share
FzF = Fz(1) + Fz(2);
FzR = Fz(3) + Fz(4);
FzT = FzF + FzR;
FxF_tot = Xreq * (FzF / max(FzT,1));
FxR_tot = Xreq * (FzR / max(FzT,1));

% Body-frame nominal corner forces based on Fz ratios
FxB_nom = zeros(4,1);
FyB_nom = zeros(4,1);

FxB_nom(1) = FxF_tot * Fz(1) / max(FzF,1);
FxB_nom(2) = FxF_tot * Fz(2) / max(FzF,1);
FxB_nom(3) = FxR_tot * Fz(3) / max(FzR,1);
FxB_nom(4) = FxR_tot * Fz(4) / max(FzR,1);

FyB_nom(1) = FyF_tot * Fz(1) / max(FzF,1);
FyB_nom(2) = FyF_tot * Fz(2) / max(FzF,1);
FyB_nom(3) = FyR_tot * Fz(3) / max(FzR,1);
FyB_nom(4) = FyR_tot * Fz(4) / max(FzR,1);

% Convert front nominal forces from body frame to local wheel frame
c = cos(delta);
s = sin(delta);

Fx_nom = zeros(4,1);
Fy_nom = zeros(4,1);

% local = R(-delta) * body
Fx_nom(1) =  c*FxB_nom(1) + s*FyB_nom(1);
Fy_nom(1) = -s*FxB_nom(1) + c*FyB_nom(1);

Fx_nom(2) =  c*FxB_nom(2) + s*FyB_nom(2);
Fy_nom(2) = -s*FxB_nom(2) + c*FyB_nom(2);

Fx_nom(3) = FxB_nom(3);
Fy_nom(3) = FyB_nom(3);
Fx_nom(4) = FxB_nom(4);
Fy_nom(4) = FyB_nom(4);

f0 = [Fx_nom; Fy_nom];

Aeq = buildForceBalanceMatrix(P, delta);
beq = [Xreq; Yreq; Nreq];

% Bounds from a Kamm-circle-inspired box constraint
ub = muBound * [Fz; Fz];
lb = -ub;

% If body demand is clearly above total available friction, scale it back
cap = muBound * sum(Fz);
XYmag = norm(beq(1:2));
if XYmag > 0.95*cap
    beq(1:2) = beq(1:2) * (0.95*cap / XYmag);
end

% Quadratic objective:
%  - stay near nominal load-weighted split
%  - stay near previous timestep estimate
wNom = 1.0;
wSm  = 1.5;
H = 2*(wNom + wSm)*eye(8);
g = -2*(wNom*f0 + wSm*f_prev);

f = [];

% Try quadprog first
if exist('quadprog','file') == 2
    try
        opts = optimoptions('quadprog','Display','off');
        f = quadprog(H, g, [], [], Aeq, beq, lb, ub, [], opts);
    catch
        f = [];
    end
end

% Fallback 1: least-squares equality solution + clipping
if isempty(f) || any(~isfinite(f))
    f = pinv(Aeq) * beq;
    f = min(max(f, lb), ub);

    % one correction step toward equality after clipping
    res = beq - Aeq*f;
    f = f + Aeq.' * ((Aeq*Aeq.' + 1e-6*eye(3)) \ res);
    f = min(max(f, lb), ub);
end

% Final safety fallback
if any(~isfinite(f))
    f = zeros(8,1);
end

debug = struct();
debug.bodyDemand = beq;
debug.f0 = f0;
end

function [xnext, F] = processModel(x, dt, P, f_prev, delta_prev, axm_prev, aym_prev)
% Discrete process model used by the EKF.
% The process propagation uses the PREVIOUS force estimate.

u   = x(1);
v   = x(2);
r   = x(3);
Dx  = x(4);
Dyf = x(5);
Dyr = x(6);
bax = x(7);
bay = x(8);
br  = x(9);

[FxBody, FyBody, Mz] = bodyTotalsFromLocal(f_prev, delta_prev, P);

ax_body = FxBody / P.m;
ay_body = FyBody / P.m;

xdot = zeros(9,1);
xdot(1) = ax_body + v*r;
xdot(2) = ay_body - u*r;
xdot(3) = Mz / P.Iz;
xdot(4) = -(1/P.tau_x )*Dx  + (P.kx /P.tau_x )*(axm_prev - bax);
xdot(5) = -(1/P.tau_yf)*Dyf + (P.kyf/P.tau_yf)*(aym_prev - bay);
xdot(6) = -(1/P.tau_yr)*Dyr + (P.kyr/P.tau_yr)*(aym_prev - bay);
xdot(7) = 0;
xdot(8) = 0;
xdot(9) = 0;

xnext = x + dt*xdot;

% Simple analytical Jacobian
F = eye(9);
F(1,2) = dt*r;
F(1,3) = dt*v;
F(2,1) = -dt*r;
F(2,3) = -dt*u;

F(4,4) = 1 - dt/P.tau_x;
F(4,7) = -dt*(P.kx/P.tau_x);

F(5,5) = 1 - dt/P.tau_yf;
F(5,8) = -dt*(P.kyf/P.tau_yf);

F(6,6) = 1 - dt/P.tau_yr;
F(6,8) = -dt*(P.kyr/P.tau_yr);
end

function h = measurementModel(x, f_prev, delta, P)
% z = [ax_meas; ay_meas; r_meas; u_gps; v_gps]

[FxBody, FyBody, ~] = bodyTotalsFromLocal(f_prev, delta, P);
ax_body = FxBody / P.m;
ay_body = FyBody / P.m;

h = [ ...
    ax_body + x(7); ...
    ay_body + x(8); ...
    x(3) + x(9); ...
    x(1); ...
    x(2)];
end

function H = measurementJacobian()
% Linearized measurement Jacobian for z = [ax ay r u v]
H = zeros(5,9);
H(1,7) = 1;  % bax
H(2,8) = 1;  % bay
H(3,3) = 1;  % r
H(3,9) = 1;  % br
H(4,1) = 1;  % u
H(5,2) = 1;  % v
end

function [theta, Pth, mu_peak] = burckhardtParamEKF(theta, Pth, lam, mu_meas)
% Tiny EKF on Burckhardt parameters theta = [C1 C2 C3]'
% mu(lam) = C1*(1 - exp(-C2*lam)) - C3*lam

lam = max(1e-4, min(0.8, lam));
mu_meas = max(0.0, min(1.30, mu_meas));

Qth = diag([1e-5, 2e-3, 1e-5]);
Rth = 2e-3;

% Predict
Pth = Pth + Qth;

% Clamp before computing Jacobian/model
C1 = min(max(theta(1), 0.05), 2.00);
C2 = min(max(theta(2), 0.50), 40.0);
C3 = min(max(theta(3), 0.01), 3.00);
theta = [C1; C2; C3];

% Measurement model and Jacobian
h = C1*(1 - exp(-C2*lam)) - C3*lam;
H = [ ...
    (1 - exp(-C2*lam)), ...
    C1*lam*exp(-C2*lam), ...
    -lam];

S = H*Pth*H.' + Rth;
K = (Pth*H.') / S;

theta = theta + K*(mu_meas - h);

% Clamp to physically meaningful bounds
C1 = min(max(theta(1), 0.05), 2.00);
C2 = min(max(theta(2), 0.50), 40.0);
C3 = min(max(theta(3), 0.01), 3.00);
theta = [C1; C2; C3];

Pth = (eye(3) - K*H) * Pth;

% Peak friction from Burckhardt parameters
arg = max(C1*C2/max(C3,1e-6), 1.0001);
mu_peak = C1 - (C3/C2)*(1 + log(arg));
mu_peak = max(0.0, min(1.50, mu_peak));
end