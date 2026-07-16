clc;
clear;

% Parameters
m = 815;
g = 9.81;
h = .5;
lf = 1.723644;
lr = 1.248156;
l = lf + lr;
mf = m * lr / l;
mr = m * lf / l;

% Brake system parameters
A_caliper_mm2 = 4486.0;
R_brake_lever_m = 0.134;
mu_k = 0.4;
r_tire_fr = 0.3;  
r_tire_re = 0.31;
A_caliper_m2 = A_caliper_mm2 * 1e-6;


mu = 1;  % road friction

decel = 0:0.1:30;

bias_range = linspace(0.1, 1.0, 10000);
max_decelerations = zeros(size(bias_range));
max_pressures = zeros(size(bias_range));

for i = 1:numel(bias_range)
    bias = bias_range(i);

    force_required = m * decel;
    pressure = brake_pressure_from_force(force_required, bias,A_caliper_m2, mu_k, R_brake_lever_m, r_tire_fr, r_tire_re);
    [frt_force, rear_force] = frt_and_rear_force_from_pressure(pressure, bias, A_caliper_m2, mu_k, R_brake_lever_m, r_tire_fr, r_tire_re);

    % Dynamic axle loads
    front_weights = mf * g + decel * m * h / l;
    rear_weights  = mr * g - decel * m * h / l;

    % Grip limits
    front_grip = front_weights * mu;
    rear_grip  = rear_weights * mu;

    % Safety limits
    front_index = find(front_grip - frt_force < 0, 1, 'first');
    rear_index  = find(rear_grip - rear_force < 0, 1, 'first');

    if isempty(front_index)
        front_limit = decel(end);
    else
        front_limit = decel(front_index);
    end

    if isempty(rear_index)
        rear_limit = decel(end);
    else
        rear_limit = decel(rear_index);
    end

    max_decel = min(front_limit, rear_limit);
    max_index = find(decel == max_decel, 1, 'first');

    max_decelerations(i) = max_decel;
    max_pressures(i) = pressure(max_index);
end

% Plot: Max Deceleration and Max Brake Pressure vs Bias
figure('Position', [100 100 800 800]);

ax1 = subplot(2,1,1);
plot(bias_range, max_decelerations, 'b-', 'LineWidth', 1.5, ...
    'DisplayName', 'Max Safe Deceleration');
ylabel('Max Deceleration (m/s^2)');
title('Max Deceleration and Brake Pressure vs Brake Bias');
grid on;
legend('show', 'Location', 'best');

ax2 = subplot(2,1,2);
plot(bias_range, max_pressures, 'r-', 'LineWidth', 1.5, ...
    'DisplayName', 'Max Brake Pressure');
xlabel('Brake Bias (Front)');
ylabel('Brake Pressure (Pa)');
grid on;
legend('show', 'Location', 'best');

linkaxes([ax1 ax2], 'x');


function pressure = brake_pressure_from_force(force_total, bias, ...
    A_caliper_m2, mu_k, R_brake_lever_m, r_tire_fr, r_tire_re)
    term = (1 / r_tire_fr + ((1 - bias) / bias) / r_tire_re);
    pressure = force_total ./ (2 * A_caliper_m2 * mu_k * R_brake_lever_m * term);
end

function [ff, fr] = frt_and_rear_force_from_pressure(pressure, bias, ...
    A_caliper_m2, mu_k, R_brake_lever_m, r_tire_fr, r_tire_re)
    ff = pressure * A_caliper_m2 * mu_k * R_brake_lever_m / r_tire_fr * 2;
    fr = pressure * A_caliper_m2 * mu_k * R_brake_lever_m / r_tire_re * 2 * (1 - bias) / bias;
end
