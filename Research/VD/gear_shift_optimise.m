clc; clear; close all

%% Files
engine_map_file = ...
    "/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/control/acceleration_interface/config/engine_map_06psi.csv";
log_file = ...
    "/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv";

% Written next to this script.
ax_table_file = "ax_max_engine06_vs_speed.csv";

%% Driveline

gear_ratio      = [2.9167; 1.8667; 1.3750; 1.1111; 0.9524; 0.8889];
gear_eff        = [0.91; 0.91; 0.91; 0.96; 0.96; 0.96];
final_drive     = 3.0;
final_drive_eff = 0.99;
tire_radius_m   = 0.31;
vehicle_mass_kg = 815;

num_gears = numel(gear_ratio);

%% Aerodynamics
rho_air         = 1.22;
frontal_area_m2 = 1.0;
coef_drag       = 1.3;
gravity         = 9.81;


coef_lift = 0.58;
max_accel = 100.0;
min_accel = -15;

%% Shift search settings
redline_rpm           = 7000;
minimum_upshift_rpm   = 1500;
minimum_operating_rpm = 1500;
hysteresis_rpm        = 700;
rpm_resolution        = 1;

%% Acceleration envelope settings
speed_step_mps = 4;

%% Log settings
wot_throttle_pct = 98;
T_interval       = [815 825.5];

%% Load engine map
fid = fopen(engine_map_file, "r");
if fid < 0
    error("Cannot open engine map: %s", engine_map_file)
end
header = split(string(fgetl(fid)), ",");
fclose(fid);

throttle_label = str2double(header);            % NaN on the "rpm" label
[max_throttle, wot_col] = max(throttle_label);  % max() skips the NaN

if isnan(max_throttle)
    error("No numeric throttle columns in the header of %s.", engine_map_file)
end
if abs(max_throttle - 1) > 1e-6
    warning("Highest throttle column is %g, not 1.0; treating it as full throttle.", ...
        max_throttle)
end

engine_map_data = readmatrix(engine_map_file);

is_valid_row  = isfinite(engine_map_data(:,1)) & isfinite(engine_map_data(:,wot_col));
rpm_column    = engine_map_data(is_valid_row, 1);
torque_column = engine_map_data(is_valid_row, wot_col);

[rpm_map, keep_row] = unique(rpm_column);   % sorts and drops duplicates
torque_map          = torque_column(keep_row);

redline_rpm = min(redline_rpm, max(rpm_map));

%% Vehicle model

car.gear_ratio      = gear_ratio;
car.gear_eff        = gear_eff;
car.final_drive     = final_drive;
car.final_drive_eff = final_drive_eff;
car.tire_radius_m   = tire_radius_m;
car.mass_kg         = vehicle_mass_kg;
car.rho_air         = rho_air;
car.frontal_area_m2 = frontal_area_m2;
car.coef_drag       = coef_drag;
car.gravity         = gravity;
car.rpm_min         = min(rpm_map);
car.rpm_max         = max(rpm_map);
car.torque_lookup   = griddedInterpolant(rpm_map, torque_map, 'linear', 'none');

%% Engine summary
num_map_points = numel(rpm_map);
power_map_kw   = nan(num_map_points, 1);

for i = 1:num_map_points
    omega_rad_s     = rpm_map(i) * 2*pi / 60;
    power_map_kw(i) = torque_map(i) * omega_rad_s / 1000;
end

[peak_torque_nm, i_peak_torque] = max(torque_map);
[peak_power_kw,  i_peak_power]  = max(power_map_kw);

fprintf("\nEngine map loaded: %.0f - %.0f RPM, throttle column '%s' of %d.\n", ...
    car.rpm_min, car.rpm_max, header(wot_col), numel(header));
fprintf("Peak torque : %.2f Nm @ %.0f RPM\n", peak_torque_nm, rpm_map(i_peak_torque));
fprintf("Peak power  : %.2f kW @ %.0f RPM\n", peak_power_kw,  rpm_map(i_peak_power));
fprintf("Redline     : %.0f RPM\n", redline_rpm);

%% Optimal upshift rpm per gear
% Power criterion: shift where the next gear makes more power than staying put,
% with both gears evaluated at the same road speed. Drag and mass are identical
% on both sides and cancel, so this comes down to P(rpm) against P(rpm*ratio).

upshift_rpm     = nan(num_gears, 1);
rpm_after_shift = nan(num_gears, 1);

crossover = struct("rpm", {}, "accel_current", {}, "accel_next", {});

for gear = 1:num_gears-1

    % Engine rpm in the next gear, at the road speed the current gear is doing.
    rpm_drop_ratio = gear_ratio(gear+1) / gear_ratio(gear);

    rpm_search_grid = (minimum_upshift_rpm : rpm_resolution : redline_rpm)';
    num_search      = numel(rpm_search_grid);

    rpm_compared    = nan(num_search, 1);
    power_advantage = nan(num_search, 1);
    num_compared    = 0;

    for i = 1:num_search

        rpm_current = rpm_search_grid(i);
        rpm_next    = rpm_current * rpm_drop_ratio;

        % Both gears have to be on the map for the comparison to mean anything.
        if rpm_current < car.rpm_min || rpm_current > car.rpm_max
            continue
        end
        if rpm_next < car.rpm_min || rpm_next > car.rpm_max
            continue
        end

        power_current = engine_power_kw(rpm_current, car);
        power_next    = engine_power_kw(rpm_next,    car);

        num_compared = num_compared + 1;
        rpm_compared(num_compared)    = rpm_current;
        power_advantage(num_compared) = power_next - power_current;  % >0 => shift up
    end

    if num_compared == 0
        error("No valid RPM comparison range for gear %d -> %d.", gear, gear+1)
    end

    rpm_compared    = rpm_compared(1:num_compared);
    power_advantage = power_advantage(1:num_compared);

    shift_rpm = last_upcrossing_rpm(rpm_compared, power_advantage, redline_rpm);

    upshift_rpm(gear)     = min(max(shift_rpm, minimum_upshift_rpm), redline_rpm);
    rpm_after_shift(gear) = upshift_rpm(gear) * rpm_drop_ratio;


    num_plot_points = 750;
    rpm_plot_start  = max(car.rpm_min, car.rpm_min / rpm_drop_ratio);
    rpm_plot        = linspace(rpm_plot_start, car.rpm_max, num_plot_points)';

    accel_current_plot = nan(num_plot_points, 1);
    accel_next_plot    = nan(num_plot_points, 1);

    for i = 1:num_plot_points

        rpm_current = rpm_plot(i);
        rpm_next    = rpm_current * rpm_drop_ratio;

        road_speed = road_speed_mps(rpm_current, gear, car);
        force_drag = drag_force_n(road_speed, car);

        accel_current_plot(i) = (tractive_force_n(rpm_current, gear,   car) - force_drag) / car.mass_kg;
        accel_next_plot(i)    = (tractive_force_n(rpm_next,    gear+1, car) - force_drag) / car.mass_kg;
    end

    crossover(gear).rpm           = rpm_plot;
    crossover(gear).accel_current = accel_current_plot;
    crossover(gear).accel_next    = accel_next_plot;
end

% Top gear has nothing to shift into.
upshift_rpm(num_gears) = redline_rpm;

%% Downshift bounds

theoretical_lower_rpm = nan(num_gears, 1);
downshift_rpm         = nan(num_gears, 1);

theoretical_lower_rpm(1) = 0;
downshift_rpm(1)         = 0;

for gear = 2:num_gears

    rpm_drop_ratio = gear_ratio(gear) / gear_ratio(gear-1);

    crossover_rpm = upshift_rpm(gear-1) * rpm_drop_ratio;

    theoretical_lower_rpm(gear) = crossover_rpm;
    downshift_rpm(gear)         = max(crossover_rpm - hysteresis_rpm, minimum_operating_rpm);
end

%% Shift table
upshift_speed_mps = nan(num_gears, 1);

for gear = 1:num_gears
    upshift_speed_mps(gear) = road_speed_mps(upshift_rpm(gear), gear, car);
end

shift_schedule = table((1:num_gears)', ...
    round_to_10(downshift_rpm), ...
    round_to_10(theoretical_lower_rpm), ...
    round_to_10(upshift_rpm), ...
    round_to_10(rpm_after_shift), ...
    round(upshift_speed_mps, 1), ...
    'VariableNames', {'Gear','LowerBoundRPM','TheoreticalCrossoverRPM', ...
                      'UpperBoundRPM','RPM_After_Upshift','UpshiftSpeed_mps'});

fprintf("\nOPTIMAL SHIFT SCHEDULE\n")
disp(shift_schedule)

fprintf("Lower RPM bounds:\n{%s}\n\n", ...
    join(compose("%.0f", shift_schedule.LowerBoundRPM'), ", "));
fprintf("Upper RPM bounds:\n{%s}\n\n", ...
    join(compose("%.0f", shift_schedule.UpperBoundRPM'), ", "));

%% Plot: engine torque and power
figure

yyaxis left
plot(rpm_map, torque_map, "LineWidth", 2), hold on
plot(rpm_map(i_peak_torque), peak_torque_nm, "o", "MarkerSize", 8, "LineWidth", 1.5)
ylabel("Engine Torque [Nm]")

yyaxis right
plot(rpm_map, power_map_kw, "LineWidth", 2), hold on
plot(rpm_map(i_peak_power), peak_power_kw, "o", "MarkerSize", 8, "LineWidth", 1.5)
ylabel("Engine Power [kW]")

xline(redline_rpm, "--", "Redline")
xlabel("Engine Speed [RPM]")
title("Full-Throttle Engine Torque and Power")
legend("Torque", sprintf("Peak %.0f Nm @ %.0f RPM", peak_torque_nm, rpm_map(i_peak_torque)), ...
       "Power",  sprintf("Peak %.0f kW @ %.0f RPM", peak_power_kw,  rpm_map(i_peak_power)), ...
       "Location", "best")
grid on

%% Plot: gear crossovers
figure
tiledlayout(ceil((num_gears-1)/2), 2, "TileSpacing", "compact", "Padding", "compact")

for gear = 1:num_gears-1
    nexttile
    plot(crossover(gear).rpm, crossover(gear).accel_current, "LineWidth", 2), hold on
    plot(crossover(gear).rpm, crossover(gear).accel_next,    "LineWidth", 2)
    xline(upshift_rpm(gear), "--", sprintf("Upshift = %.0f RPM", upshift_rpm(gear)), ...
        "LineWidth", 1.5)
    xlabel(sprintf("Gear %d Engine RPM", gear))
    ylabel("Acceleration [m/s^2]")
    title(sprintf("Gear %d \\rightarrow Gear %d", gear, gear+1))
    legend(sprintf("Stay in Gear %d", gear), sprintf("Shift to Gear %d", gear+1), ...
        "Location", "best")
    grid on
end

%% Plot: power available in each gear
% Engine power depends on engine rpm alone, so every gear traces the same curve
% against rpm. Against road speed they separate and the power-criterion shift
% points land exactly on the crossings.
num_sweep_points = 750;
rpm_sweep        = linspace(car.rpm_min, car.rpm_max, num_sweep_points)';
power_sweep_kw   = nan(num_sweep_points, 1);
speed_sweep_mps  = nan(num_sweep_points, num_gears);

for gear = 1:num_gears
    for i = 1:num_sweep_points
        speed_sweep_mps(i, gear) = road_speed_mps(rpm_sweep(i), gear, car);
    end
end

for i = 1:num_sweep_points
    power_sweep_kw(i) = engine_power_kw(rpm_sweep(i), car);
end

% Shift markers, each placed at the road speed and power of the gear being left.
% Top gear has no upshift and first gear has no downshift, so those entries stay
% NaN and simply do not draw.
speed_at_upshift = nan(num_gears, 1);
power_at_upshift = nan(num_gears, 1);

for gear = 1:num_gears-1
    speed_at_upshift(gear) = road_speed_mps(upshift_rpm(gear), gear, car);
    power_at_upshift(gear) = engine_power_kw(upshift_rpm(gear), car);
end

speed_at_downshift = nan(num_gears, 1);
power_at_downshift = nan(num_gears, 1);

for gear = 2:num_gears
    speed_at_downshift(gear) = road_speed_mps(downshift_rpm(gear), gear, car);
    power_at_downshift(gear) = engine_power_kw(downshift_rpm(gear), car);
end

figure
hold on

for gear = 1:num_gears
    plot(speed_sweep_mps(:, gear), power_sweep_kw, "LineWidth", 2)
end

plot(speed_at_upshift, power_at_upshift, ...
    "o", "MarkerSize", 9, "MarkerFaceColor", "r", "MarkerEdgeColor", "k")
plot(speed_at_downshift, power_at_downshift, ...
    "o", "MarkerSize", 9, "MarkerFaceColor", "b", "MarkerEdgeColor", "k")

xlabel("Road Speed [m/s]"), ylabel("Power [kW]")
title("Full-Throttle Power Available in Each Gear")
legend([compose("Gear %d", 1:num_gears), "Upshift", "Downshift"], ...
    "Location", "southeast")
grid on

%% Plot: power vs engine rpm in each gear
% Engine power depends on engine rpm alone, so plotted against rpm the gears can
% only separate through driveline efficiency. This is power at the wheels, so
% gears sharing a gear_eff trace exactly on top of each other.
wheel_power_sweep_kw = nan(num_sweep_points, num_gears);

for gear = 1:num_gears
    for i = 1:num_sweep_points
        wheel_power_sweep_kw(i, gear) = wheel_power_kw(rpm_sweep(i), gear, car);
    end
end

wheel_power_at_upshift   = nan(num_gears, 1);
wheel_power_at_downshift = nan(num_gears, 1);

for gear = 1:num_gears-1
    wheel_power_at_upshift(gear) = wheel_power_kw(upshift_rpm(gear), gear, car);
end

for gear = 2:num_gears
    wheel_power_at_downshift(gear) = wheel_power_kw(downshift_rpm(gear), gear, car);
end

figure
hold on

for gear = 1:num_gears
    plot(rpm_sweep, wheel_power_sweep_kw(:, gear), "LineWidth", 2)
end

plot(upshift_rpm, wheel_power_at_upshift, ...
    "o", "MarkerSize", 9, "MarkerFaceColor", "r", "MarkerEdgeColor", "k")
plot(downshift_rpm, wheel_power_at_downshift, ...
    "o", "MarkerSize", 9, "MarkerFaceColor", "b", "MarkerEdgeColor", "k")

xline(redline_rpm, "--", "Redline")
xlabel("Engine Speed [RPM]"), ylabel("Power at the Wheels [kW]")
title("Full-Throttle Power vs Engine Speed in Each Gear")
legend([compose("Gear %d", 1:num_gears), "Upshift", "Downshift"], ...
    "Location", "northwest")
grid on

%% Plot: acceleration available in each gear
% Rolling resistance, grade and the traction limit are not modelled, so this is
% what the driveline can deliver rather than what the car will achieve.
accel_sweep_mps2 = nan(num_sweep_points, num_gears);

for gear = 1:num_gears
    for i = 1:num_sweep_points

        rpm        = rpm_sweep(i);
        road_speed = road_speed_mps(rpm, gear, car);

        force_tractive = tractive_force_n(rpm, gear, car);
        force_drag     = drag_force_n(road_speed, car);

        accel_sweep_mps2(i, gear) = (force_tractive - force_drag) / car.mass_kg;
    end
end

accel_at_upshift   = nan(num_gears, 1);
accel_at_downshift = nan(num_gears, 1);

for gear = 1:num_gears-1
    rpm        = upshift_rpm(gear);
    road_speed = road_speed_mps(rpm, gear, car);
    accel_at_upshift(gear) = ...
        (tractive_force_n(rpm, gear, car) - drag_force_n(road_speed, car)) / car.mass_kg;
end

for gear = 2:num_gears
    rpm        = downshift_rpm(gear);
    road_speed = road_speed_mps(rpm, gear, car);
    accel_at_downshift(gear) = ...
        (tractive_force_n(rpm, gear, car) - drag_force_n(road_speed, car)) / car.mass_kg;
end

figure
hold on

for gear = 1:num_gears
    plot(speed_sweep_mps(:, gear), accel_sweep_mps2(:, gear), "LineWidth", 2)
end

plot(speed_at_upshift, accel_at_upshift, ...
    "o", "MarkerSize", 9, "MarkerFaceColor", "r", "MarkerEdgeColor", "k")
plot(speed_at_downshift, accel_at_downshift, ...
    "o", "MarkerSize", 9, "MarkerFaceColor", "b", "MarkerEdgeColor", "k")

xlabel("Road Speed [m/s]"), ylabel("Acceleration [m/s^2]")
title(sprintf("Acceleration in Each Gear, %.0f kg, CdA = %.2f m^2", ...
    car.mass_kg, car.coef_drag*car.frontal_area_m2))
legend([compose("Gear %d", 1:num_gears), "Upshift", "Downshift"], ...
    "Location", "northeast")
grid on

%% Acceleration envelope on the shift schedule
% What the car can actually pull at a given road speed: take the gear the
% upshift schedule leaves us in at that speed, the rpm that gear implies, and
% difference tractive force against drag. Only the upshift bounds matter here
% because the car is speeding up, so the downshift hysteresis never comes into
% play. Below the speed where first gear reaches launch_rpm the clutch is
% slipping, so the engine is held at launch_rpm instead of being dragged down
% with the road speed. No traction limit is applied, so first gear reads over
% 1.5 g where the map spikes -- this is what the driveline offers, not what the
% tires will take.
launch_rpm = minimum_operating_rpm;

top_speed_mps  = road_speed_mps(redline_rpm, num_gears, car);
speed_grid_mps = (0 : speed_step_mps : top_speed_mps)';
num_speed_pts  = numel(speed_grid_mps);

gear_on_grid  = nan(num_speed_pts, 1);
rpm_on_grid   = nan(num_speed_pts, 1);
accel_on_grid = nan(num_speed_pts, 1);

for i = 1:num_speed_pts

    road_speed = speed_grid_mps(i);

    % The first gear whose upshift speed is still ahead of us.
    gear = find(upshift_speed_mps > road_speed, 1, "first");
    if isempty(gear)
        gear = num_gears;
    end

    rpm_geared = engine_rpm_at_speed(road_speed, gear, car);
    rpm_used   = max(rpm_geared, launch_rpm);

    force_tractive = tractive_force_n(rpm_used, gear, car);
    force_drag     = drag_force_n(road_speed, car);

    gear_on_grid(i)  = gear;
    rpm_on_grid(i)   = rpm_used;
    accel_on_grid(i) = (force_tractive - force_drag) / car.mass_kg;
end

accel_envelope = table(round(speed_grid_mps, 2), ...
    round(accel_on_grid, 3), ...
    gear_on_grid, ...
    round_to_10(rpm_on_grid), ...
    'VariableNames', {'v_mps','ax_max_mps2','Gear','EngineRPM'});

fprintf("\nACCELERATION ENVELOPE ON THE SHIFT SCHEDULE\n")
fprintf("%.0f m/s steps, launch rpm %.0f\n", speed_step_mps, launch_rpm);
disp(accel_envelope)

i_last_driving = find(accel_on_grid > 0, 1, "last");
if ~isempty(i_last_driving) && i_last_driving < num_speed_pts
    fprintf("Drag overtakes the driveline between %.0f and %.0f m/s.\n", ...
        speed_grid_mps(i_last_driving), speed_grid_mps(i_last_driving+1));
end

script_dir = fileparts(mfilename("fullpath"));
if isempty(script_dir)
    script_dir = pwd;
end

ax_table_path = fullfile(script_dir, ax_table_file);
writetable(accel_envelope(:, {'v_mps','ax_max_mps2'}), ax_table_path);
fprintf("Wrote %s\n", ax_table_path);

%% Plot: acceleration envelope
% The per-gear curves sit behind in grey as the envelope this is picked out of.
figure
hold on

for gear = 1:num_gears
    h_curve = plot(speed_sweep_mps(:, gear), accel_sweep_mps2(:, gear), ...
        "Color", [0.75 0.75 0.75], "LineWidth", 1);
    if gear > 1
        h_curve.HandleVisibility = "off";
    end
end

for gear = 1:num_gears-1
    xline(upshift_speed_mps(gear), ":", sprintf("%d\\rightarrow%d", gear, gear+1), ...
        "HandleVisibility", "off")
end

yline(0, "-", "", "Color", [0.5 0.5 0.5], "HandleVisibility", "off")

plot(speed_grid_mps, accel_on_grid, "-", "Color", [0.2 0.2 0.2], "LineWidth", 1.5)

gear_colour   = lines(num_gears);
legend_labels = ["Available in each gear", sprintf("Envelope, %.0f m/s steps", speed_step_mps)];

for gear = 1:num_gears

    in_gear = gear_on_grid == gear;
    if ~any(in_gear)
        continue
    end

    plot(speed_grid_mps(in_gear), accel_on_grid(in_gear), "o", ...
        "MarkerSize", 8, "MarkerFaceColor", gear_colour(gear,:), "MarkerEdgeColor", "k")

    legend_labels(end+1) = sprintf("Gear %d", gear); %#ok<SAGROW>
end

xlabel("Road Speed [m/s]"), ylabel("Max Acceleration [m/s^2]")
title(sprintf("Max Acceleration vs Speed on the Shift Schedule, %.0f kg, CdA = %.2f m^2", ...
    car.mass_kg, car.coef_drag*car.frontal_area_m2))
legend(legend_labels, "Location", "northeast")
xticks(0 : 2*speed_step_mps : max(speed_grid_mps))
grid on

%% Plot: road speed vs engine rpm
% rpm is proportional to road speed within a gear, so each gear is a straight
% line out of the origin.
rpm_line   = [0; car.rpm_max];
speed_line = nan(2, num_gears);

for gear = 1:num_gears
    speed_line(1, gear) = road_speed_mps(rpm_line(1), gear, car);
    speed_line(2, gear) = road_speed_mps(rpm_line(2), gear, car);
end

figure
hold on

for gear = 1:num_gears
    plot(speed_line(:, gear), rpm_line, "LineWidth", 2)
end

plot(speed_at_upshift, upshift_rpm, ...
    "o", "MarkerSize", 9, "MarkerFaceColor", "r", "MarkerEdgeColor", "k")
plot(speed_at_downshift, downshift_rpm, ...
    "o", "MarkerSize", 9, "MarkerFaceColor", "b", "MarkerEdgeColor", "k")

yline(redline_rpm, "--", "Redline")
xlabel("Road Speed [m/s]"), ylabel("Engine Speed [RPM]")
title("Gearing: Road Speed vs Engine Speed")
legend([compose("Gear %d", 1:num_gears), "Upshift", "Downshift"], "Location", "southeast")
grid on

%% Plot: operating bounds
figure
plot([1:num_gears; 1:num_gears], ...
     [shift_schedule.LowerBoundRPM'; shift_schedule.UpperBoundRPM'], ...
     "-o", "LineWidth", 2)
xlabel("Gear"), ylabel("Engine RPM")
title("Gear Operating RPM Bounds")
xticks(1:num_gears), grid on

%% Load the measured run log
data = readtable(log_file);

t_full    = data.time_s - data.time_s(1);   % epoch -> seconds into the run
in_window = t_full >= T_interval(1) & t_full <= T_interval(2);

if ~any(in_window)
    error("T_interval [%g %g] selects no samples; the run spans 0 - %.1f s.", ...
        T_interval(1), T_interval(2), t_full(end))
end

%% Road grade from odometry
% sin(theta) = rise / horizontal run along the path. odom_vz is body-frame and
% integrates to almost nothing, so the world-frame positions are used instead.
% Computed over the WHOLE log before any masking, because differentiating
% position needs contiguous samples, and smoothed because differentiating at
% 100 Hz is noisy. Positive is climbing; negate if the log's z axis is down.
grade_smooth_samples = 50;      % ~0.5 s at 100 Hz
max_grade            = 0.3;     % guard against near-standstill

rise_per_sample = movmean(gradient(data.odom_pz_m), grade_smooth_samples);
run_per_sample  = movmean(hypot(gradient(data.odom_px_m), ...
                                gradient(data.odom_py_m)), grade_smooth_samples);

grade_full = rise_per_sample ./ max(run_per_sample, 1e-3);
grade_full = min(max(grade_full, -max_grade), max_grade);

% The merge leaves a handful of interpolated (fractional) gear values.
gear_full = min(max(round(data.current_gear), 1), num_gears);

%% Full-throttle samples across the whole run
is_wot = data.throttle_pct >= wot_throttle_pct & ...
         data.odom_vx_mps  >= 5 & ...
         data.engine_rpm   >= 1200;

rpm_wot   = data.engine_rpm(is_wot);
vx_wot    = data.odom_vx_mps(is_wot);
ax_wot    = data.a_x(is_wot);
gear_wot  = gear_full(is_wot);
grade_wot = grade_full(is_wot);

accel_model_wot = model_accel_mps2(rpm_wot, gear_wot, vx_wot, grade_wot, car);
implied_eff_wot = implied_gear_eff(ax_wot, rpm_wot, gear_wot, vx_wot, grade_wot, car);

%% Time window used for the histories and the path
t_s       = t_full(in_window);
vx_mps    = data.odom_vx_mps(in_window);
ax_meas   = data.a_x(in_window);
rpm_meas  = data.engine_rpm(in_window);
thr_pct   = data.throttle_pct(in_window);
px_m      = data.odom_px_m(in_window);
py_m      = data.odom_py_m(in_window);
gear_meas = gear_full(in_window);
grade_sin = grade_full(in_window);

% Engine speed at the same road speed one gear lower. Gear 1 has nothing below
% it, so it maps to itself and the two traces coincide there.
gear_lower    = max(gear_meas - 1, 1);
rpm_downshift = rpm_meas .* gear_ratio(gear_lower) ./ gear_ratio(gear_meas);

ax_theory = model_accel_mps2(rpm_meas, gear_meas, vx_mps, grade_sin, car);

%% Plot: run time histories and path
[~, log_name] = fileparts(log_file);

figure
tiledlayout(4, 5, "TileSpacing", "compact", "Padding", "compact")

ax_time(1) = nexttile(1, [1 3]);
plot(t_s, vx_mps)
ylabel("Velocity X [m/s]"), grid on
title("Run " + log_name, "Interpreter", "none")

ax_time(2) = nexttile(6, [1 3]);
plot(t_s, rpm_meas), hold on
plot(t_s, rpm_downshift)
yline(redline_rpm, "--", "Redline")
ylabel("Engine Speed [RPM]"), grid on
legend("Measured", "One gear lower", "Location", "best")

ax_time(3) = nexttile(11, [1 3]);
stairs(t_s, gear_meas)
ylabel("Gear"), grid on
ylim([0.5 num_gears+0.5]), yticks(1:num_gears)

ax_time(4) = nexttile(16, [1 3]);
plot(t_s, thr_pct)
ylabel("Throttle [%]"), xlabel("Time [s]"), grid on
ylim([0 100])

linkaxes(ax_time, "x")
if t_s(end) > t_s(1)
    xlim([t_s(1) t_s(end)])
end

nexttile(4, [4 2]);
scatter(px_m, py_m, 6, t_s, "filled")
axis equal, grid on
xlabel("X [m]"), ylabel("Y [m]")
title("Vehicle Path")
cb = colorbar;
cb.Label.String = "Time [s]";

%% Plot: measured vs modelled acceleration at full throttle
% The samples are scattered through the run rather than contiguous, so a moving
% mean along the array would be meaningless. Binning by speed and taking the
% median per bin is the honest summary.
speed_bin_width = 2.5;
speed_edges     = floor(min(vx_wot)) : speed_bin_width : ceil(max(vx_wot)) + speed_bin_width;
num_speed_bins  = numel(speed_edges) - 1;

speed_bin    = discretize(vx_wot, speed_edges);
is_binned    = ~isnan(speed_bin);
speed_centre = speed_edges(1:end-1)' + diff(speed_edges)'/2;

median_meas   = accumarray(speed_bin(is_binned), ax_wot(is_binned), ...
                           [num_speed_bins 1], @median, NaN);
median_theory = accumarray(speed_bin(is_binned), accel_model_wot(is_binned), ...
                           [num_speed_bins 1], @median, NaN);

figure
hold on

plot(vx_wot, ax_wot,          ".", "MarkerSize", 4, "Color", [0.00 0.45 0.74 0.25])
plot(vx_wot, accel_model_wot, ".", "MarkerSize", 4, "Color", [0.85 0.33 0.10 0.25])
plot(speed_centre, median_meas,   "-o", "LineWidth", 2, "Color", [0.00 0.45 0.74])
plot(speed_centre, median_theory, "-o", "LineWidth", 2, "Color", [0.85 0.33 0.10])

xlabel("Velocity X [m/s]"), ylabel("Acceleration [m/s^2]")
title(sprintf("Measured vs Modelled Acceleration, throttle >= %g%% (n = %d)", ...
    wot_throttle_pct, numel(vx_wot)))
legend("Measured a_x", "Modelled", "Measured, median per 2.5 m/s", ...
       "Modelled, median per 2.5 m/s", "Location", "best")
grid on

%% Driveline efficiency implied by the log
% Everything the model omits -- wheel slip, rolling resistance, drag error, map
% error -- lands in this number, so it is a fit, not a measurement. The a_x
% floor drops shift transients, where the throttle is still open but the
% driveline is not delivering.
min_driving_accel = 0.3;
min_samples       = 20;

is_driving = ax_wot > min_driving_accel;

fprintf("\nIMPLIED DRIVELINE EFFICIENCY (throttle >= %g%%, CdA = %.2f)\n", ...
    wot_throttle_pct, car.coef_drag*car.frontal_area_m2);

for gear = 1:num_gears
    in_gear = is_driving & gear_wot == gear;
    if nnz(in_gear) >= min_samples
        fprintf("  gear %d: n=%5d  median %.3f  (currently set to %.2f)\n", ...
            gear, nnz(in_gear), median(implied_eff_wot(in_gear)), gear_eff(gear));
    end
end

%% Optional save
% writetable(shift_schedule, ...
%     "/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/control/acceleration_interface/config/optimal_shift_bounds.csv");

%% Local functions

function torque_nm = engine_torque_nm(rpm, car)
% Full-throttle engine torque. NaN outside the mapped rpm range.
    torque_lookup = car.torque_lookup;
    torque_nm     = torque_lookup(rpm);
end

function power_kw = engine_power_kw(rpm, car)
% P = T * w, with w in rad/s.
    torque_nm   = engine_torque_nm(rpm, car);
    omega_rad_s = rpm .* (2*pi/60);
    power_kw    = torque_nm .* omega_rad_s ./ 1000;
end

function power_kw = wheel_power_kw(rpm, gear, car)
% Engine power less the driveline losses of the gear it is going through.
    engine_power  = engine_power_kw(rpm, car);
    driveline_eff = car.gear_eff(gear) .* car.final_drive_eff;
    power_kw      = engine_power .* driveline_eff;
end

function speed_mps = road_speed_mps(rpm, gear, car)
% Road speed at an engine speed, in a given gear. No slip anywhere.
    total_ratio      = car.gear_ratio(gear) .* car.final_drive;
    wheel_rpm        = rpm ./ total_ratio;
    wheel_rad_per_s  = wheel_rpm .* (2*pi/60);
    speed_mps        = wheel_rad_per_s .* car.tire_radius_m;
end

function rpm = engine_rpm_at_speed(speed_mps, gear, car)
% Inverse of road_speed_mps: the engine speed a road speed forces in a gear.
    wheel_rad_per_s = speed_mps ./ car.tire_radius_m;
    wheel_rpm       = wheel_rad_per_s .* (60/(2*pi));
    rpm             = wheel_rpm .* car.gear_ratio(gear) .* car.final_drive;
end

function force_n = tractive_force_n(rpm, gear, car)
% Force at the driven wheels. Efficiency is per-gear, so unlike the ratios it
% does NOT cancel when two gears are compared.
    engine_torque   = engine_torque_nm(rpm, car);
    total_ratio     = car.gear_ratio(gear) .* car.final_drive;
    total_eff       = car.gear_eff(gear)   .* car.final_drive_eff;
    wheel_torque_nm = engine_torque .* total_ratio .* total_eff;
    force_n         = wheel_torque_nm ./ car.tire_radius_m;
end

function force_n = drag_force_n(speed_mps, car)
    dynamic_pressure = 0.5 * car.rho_air .* speed_mps.^2;
    force_n          = dynamic_pressure .* car.coef_drag .* car.frontal_area_m2;
end

function accel_mps2 = model_accel_mps2(rpm, gear, speed_mps, grade_sin, car)
% Modelled longitudinal acceleration. Rolling resistance is not included.
    force_tractive = tractive_force_n(rpm, gear, car);
    force_drag     = drag_force_n(speed_mps, car);

    accel_driveline = (force_tractive - force_drag) ./ car.mass_kg;
    accel_grade     = car.gravity .* grade_sin;

    accel_mps2 = accel_driveline - accel_grade;
end

function gear_eff = implied_gear_eff(accel_meas, rpm, gear, speed_mps, grade_sin, car)
% The gear efficiency that would make the model match a measured a_x.
    force_drag     = drag_force_n(speed_mps, car);
    force_required = car.mass_kg .* (accel_meas + car.gravity .* grade_sin) + force_drag;

    wheel_torque_required = force_required .* car.tire_radius_m;
    wheel_torque_ideal    = engine_torque_nm(rpm, car) .* car.gear_ratio(gear) ...
                            .* car.final_drive .* car.final_drive_eff;

    gear_eff = wheel_torque_required ./ wheel_torque_ideal;
end

function rounded = round_to_10(value)
    rounded = round(value/10) * 10;
end

function rpm = last_upcrossing_rpm(rpm_grid, advantage, redline_rpm)
% Highest rpm where advantage crosses from <=0 up through 0, interpolated onto
% the crossing. Taking the last one matters where the curves touch more than
% once: the shift point is the final place the next gear takes over for good.
    is_upcrossing = advantage(1:end-1) <= 0 & advantage(2:end) > 0;
    idx           = find(is_upcrossing, 1, "last");

    if ~isempty(idx)

        rpm_before = rpm_grid(idx);
        rpm_after  = rpm_grid(idx+1);

        advantage_before = advantage(idx);
        advantage_after  = advantage(idx+1);

        slope = advantage_after - advantage_before;

        if abs(slope) > eps
            rpm = rpm_before - advantage_before * (rpm_after - rpm_before) / slope;
        else
            rpm = rpm_before;
        end

    elseif all(advantage > 0)
        rpm = rpm_grid(1);      % next gear already better at the search start
    else
        rpm = redline_rpm;      % current gear better all the way up
    end
end
