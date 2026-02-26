
clear; clc; close all;

%% 1) Parameters (EDIT THESE FOR YOUR CAR)
m   = 300;        % mass [kg]
Iz  = 180;        % yaw inertia [kg*m^2]
a   = 0.9;        % CG -> front axle [m]
b   = 0.9;        % CG -> rear axle [m]
Cf  = 30000;      % front cornering stiffness [N/rad]
Cr  = 32000;      % rear cornering stiffness [N/rad]
Ux  = 12;         % constant longitudinal speed [m/s]

% Sanity checks
if Ux <= 0
    error('Ux must be > 0 for this linear model.');
end



A = zeros(4,4);
B = zeros(4,1);

% x1 = y
A(1,2) = 1;

% x2 = y_dot = v_y
A(2,2) = -(Cf + Cr)/(m*Ux);
A(2,4) = -( Ux + (a*Cf - b*Cr)/(m*Ux) );
B(2)   =  Cf/m;

% x3 = psi
A(3,4) = 1;

% x4 = r
A(4,2) = -(a*Cf - b*Cr)/(Iz*Ux);
A(4,4) = -(a^2*Cf + b^2*Cr)/(Iz*Ux);
B(4)   =  a*Cf/Iz;

%% Steering input function delta(t)

delta_step_deg = 3;
t_step = 1.0;

delta = @(t) (t >= t_step) * deg2rad(delta_step_deg)*sin(t);

f = @(t,x) A*x + B*delta(t);

%% sim
tspan = [0 6];  % [s]
x0 = [0; 0; 0; 0];  % initial [y; y_dot; psi; r]

opts = odeset('RelTol',1e-7,'AbsTol',1e-9);
[t, X] = ode45(f, tspan, x0, opts);

y     = X(:,1);          % [m]
ydot  = X(:,2);          % [m/s]
psi   = X(:,3);          % [rad]
r     = X(:,4);          % [rad/s]

% Also compute lateral acceleration a_y = y_ddot + Ux*r
% y_ddot comes from the state equation for y_dot:
ay = zeros(size(t));
for k = 1:numel(t)
    xk = X(k,:)';
    xdotk = A*xk + B*delta(t(k));
    yddot = xdotk(2);
    ay(k) = yddot + Ux*xk(4);
end

%% 6) Plot outputs
figure; plot(t, y, 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('y [m]'); title('Lateral Position y');

figure; plot(t, ydot, 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('y\_dot [m/s]'); title('Lateral Velocity y\_dot');

figure; plot(t, rad2deg(psi), 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('\psi [deg]'); title('Yaw Angle \psi');

figure; plot(t, rad2deg(r), 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('r [deg/s]'); title('Yaw Rate r');

figure; plot(t, ay, 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('a_y [m/s^2]'); title('Lateral Acceleration a_y');

%% 7) Plot steering input for reference
d = arrayfun(delta, t);
figure; plot(t, rad2deg(d), 'LineWidth', 1.5);
grid on; xlabel('Time [s]'); ylabel('\delta [deg]'); title('Steering Input \delta(t)');
