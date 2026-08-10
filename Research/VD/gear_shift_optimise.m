clc
clear
close all

%% ================================================================
%  OPTIMAL GEAR SHIFT BOUND GENERATOR
%
%  Generates:
%       Lower RPM Bound -> Downshift
%       Upper RPM Bound -> Upshift
%
%  Uses the full-throttle engine torque curve.
%
%  Upshift criterion:
%
%       Te(RPM_current)*G_current
%
%                   =
%
%       Te(RPM_after_shift)*G_next
%
%  where:
%
%       RPM_after_shift = RPM_current*(G_next/G_current)
%
% ================================================================


%% ======================= USER SETTINGS ============================

engine_map_file = ...
    "/home/elijah/engine_30psi.csv";

% Transmission gear ratios
gear_ratio = [
    2.9167
    1.8667
    1.3750
    1.1111
    0.9524
    0.8889
];

num_gears = length(gear_ratio);

% Maximum engine RPM
redline_rpm = 7500;

% Lowest RPM considered when searching for an upshift
minimum_upshift_rpm = 3000;

% Minimum allowable downshift RPM
minimum_operating_rpm = 1500;

% Hysteresis below theoretical gear crossover
hysteresis_rpm = 300;

% RPM resolution for crossover search
rpm_resolution = 1;


%% ======================= LOAD ENGINE MAP ==========================

% Engine map format:
%
% Column 1 = RPM
% Column 2 = 0.0 throttle
% Column 3 = 0.3 throttle
% Column 4 = 0.6 throttle
% Column 5 = 1.0 throttle

engine_map_data = readmatrix(engine_map_file);

% Remove completely empty rows
engine_map_data = engine_map_data( ...
    ~all(isnan(engine_map_data),2), :);

% Check format
if size(engine_map_data,2) < 5

    error( ...
        "Engine map must contain at least 5 columns: " + ...
        "RPM, 0.0, 0.3, 0.6, 1.0 throttle.");

end


% RPM
rpm_map = engine_map_data(:,1);

% Full-throttle torque
torque_map = engine_map_data(:,5);


%% ======================= CLEAN ENGINE MAP =========================

valid = ...
    isfinite(rpm_map) & ...
    isfinite(torque_map);

rpm_map = rpm_map(valid);
torque_map = torque_map(valid);


% Sort by RPM
[rpm_map,sort_idx] = sort(rpm_map);

torque_map = torque_map(sort_idx);


% Remove duplicate RPM entries
[rpm_map,unique_idx] = unique(rpm_map,"stable");

torque_map = torque_map(unique_idx);


% Clamp redline to available engine map
redline_rpm = min(redline_rpm,max(rpm_map));


fprintf("\nEngine map loaded successfully.\n");

fprintf( ...
    "RPM range: %.0f - %.0f RPM\n", ...
    min(rpm_map), ...
    max(rpm_map));

fprintf("Using full-throttle torque curve.\n");


%% ===================== ENGINE INFORMATION =========================

engine_power_kw = ...
    torque_map .* ...
    rpm_map .* ...
    (2*pi/60) / 1000;


% Peak torque
[peak_torque,idx_peak_torque] = max(torque_map);

rpm_peak_torque = ...
    rpm_map(idx_peak_torque);


% Peak power
[peak_power,idx_peak_power] = max(engine_power_kw);

rpm_peak_power = ...
    rpm_map(idx_peak_power);


fprintf("\n========================================\n")
fprintf("ENGINE MAP INFORMATION\n")
fprintf("========================================\n")

fprintf( ...
    "Peak torque : %.2f Nm @ %.0f RPM\n", ...
    peak_torque, ...
    rpm_peak_torque);

fprintf( ...
    "Peak power  : %.2f kW @ %.0f RPM\n", ...
    peak_power, ...
    rpm_peak_power);

fprintf( ...
    "Redline     : %.0f RPM\n", ...
    redline_rpm);


%% ================================================================
%  FIND OPTIMAL UPSHIFT RPM
% ================================================================

upshift_rpm = nan(num_gears,1);

rpm_after_shift = nan(num_gears,1);

comparison_data = cell(num_gears-1,1);


for gear = 1:num_gears-1

    G_current = gear_ratio(gear);

    G_next = gear_ratio(gear+1);


    %% Current gear RPM search vector

    rpm_current = ...
        (minimum_upshift_rpm:rpm_resolution:redline_rpm)';


    %% RPM after shifting into next gear

    rpm_next = ...
        rpm_current .* ...
        (G_next/G_current);


    %% Only evaluate points inside engine map

    valid_rpm = ...
        rpm_current >= min(rpm_map) & ...
        rpm_current <= max(rpm_map) & ...
        rpm_next >= min(rpm_map) & ...
        rpm_next <= max(rpm_map);


    rpm_current = ...
        rpm_current(valid_rpm);

    rpm_next = ...
        rpm_next(valid_rpm);


    if isempty(rpm_current)

        error( ...
            "No valid RPM comparison range for gear %d -> %d.", ...
            gear, ...
            gear+1);

    end


    %% Interpolate engine torque

    torque_current = interp1( ...
        rpm_map, ...
        torque_map, ...
        rpm_current, ...
        "linear");


    torque_next = interp1( ...
        rpm_map, ...
        torque_map, ...
        rpm_next, ...
        "linear");


    %% Equivalent wheel torque
    %
    % Final drive, efficiency and tire radius cancel because they
    % are identical for both gear comparisons.

    wheel_torque_current = ...
        torque_current .* G_current;


    wheel_torque_next = ...
        torque_next .* G_next;


    %% Difference
    %
    % > 0 : next gear is better
    % < 0 : current gear is better

    torque_advantage_next = ...
        wheel_torque_next - ...
        wheel_torque_current;


    %% ============================================================
    %  FIND THE UPSHIFT CROSSOVER
    % ============================================================

    crossover_idx = find( ...
        torque_advantage_next(1:end-1) <= 0 & ...
        torque_advantage_next(2:end) > 0);


    if ~isempty(crossover_idx)

        % Use final crossover before redline
        idx = crossover_idx(end);


        % Linear interpolation around zero crossing

        x1 = rpm_current(idx);
        x2 = rpm_current(idx+1);

        y1 = torque_advantage_next(idx);
        y2 = torque_advantage_next(idx+1);


        if abs(y2-y1) > eps

            shift_rpm = ...
                x1 - ...
                y1*(x2-x1)/(y2-y1);

        else

            shift_rpm = x1;

        end


    elseif all(torque_advantage_next <= 0)

        % Current gear remains better all the way to redline
        shift_rpm = redline_rpm;


    elseif all(torque_advantage_next > 0)

        % Next gear is already better at the beginning of search
        shift_rpm = rpm_current(1);


    else

        % Safe fallback
        shift_rpm = redline_rpm;

    end


    %% Clamp shift RPM

    shift_rpm = min( ...
        max(shift_rpm,minimum_upshift_rpm), ...
        redline_rpm);


    %% Save upper bound

    upshift_rpm(gear) = ...
        shift_rpm;


    %% RPM immediately after shift

    rpm_after_shift(gear) = ...
        shift_rpm * ...
        G_next/G_current;


    %% Save data for plotting

    comparison_data{gear}.rpm = ...
        rpm_current;

    comparison_data{gear}.current = ...
        wheel_torque_current;

    comparison_data{gear}.next = ...
        wheel_torque_next;

end


%% Last gear has no higher gear

upshift_rpm(num_gears) = ...
    redline_rpm;


%% ================================================================
%  CALCULATE LOWER / DOWNSHIFT BOUNDS
% ================================================================

downshift_rpm = nan(num_gears,1);

theoretical_lower_rpm = nan(num_gears,1);


% First gear has no downshift
downshift_rpm(1) = 0;

theoretical_lower_rpm(1) = 0;


for gear = 2:num_gears

    %% RPM in current gear corresponding to previous gear's
    %  optimal upshift vehicle speed

    theoretical_lower_rpm(gear) = ...
        upshift_rpm(gear-1) * ...
        gear_ratio(gear) / ...
        gear_ratio(gear-1);


    %% Add hysteresis
    %
    % Example:
    %
    % theoretical crossover = 5500 RPM
    %
    % hysteresis = 300 RPM
    %
    % downshift boundary = 5200 RPM

    downshift_rpm(gear) = ...
        theoretical_lower_rpm(gear) - ...
        hysteresis_rpm;


    %% Minimum allowable downshift boundary

    downshift_rpm(gear) = ...
        max( ...
        downshift_rpm(gear), ...
        minimum_operating_rpm);

end


%% ================================================================
%  ROUND CONTROLLER VALUES
% ================================================================

upshift_rpm_rounded = ...
    round(upshift_rpm/10)*10;


downshift_rpm_rounded = ...
    round(downshift_rpm/10)*10;


theoretical_lower_rpm_rounded = ...
    round(theoretical_lower_rpm/10)*10;


rpm_after_shift_rounded = ...
    round(rpm_after_shift/10)*10;


%% ================================================================
%  CREATE SHIFT TABLE
% ================================================================

Gear = ...
    (1:num_gears)';


LowerBoundRPM = ...
    downshift_rpm_rounded;


TheoreticalCrossoverRPM = ...
    theoretical_lower_rpm_rounded;


UpperBoundRPM = ...
    upshift_rpm_rounded;


RPM_After_Upshift = ...
    rpm_after_shift_rounded;


shift_schedule = table( ...
    Gear, ...
    LowerBoundRPM, ...
    TheoreticalCrossoverRPM, ...
    UpperBoundRPM, ...
    RPM_After_Upshift);


fprintf("\n\n========================================\n")
fprintf("OPTIMAL SHIFT SCHEDULE\n")
fprintf("========================================\n\n")


disp(shift_schedule)


%% ================================================================
%  PRINT CONTROLLER ARRAYS
% ================================================================

fprintf("\n========================================\n")
fprintf("COPY-PASTE CONTROLLER ARRAYS\n")
fprintf("========================================\n\n")


fprintf("Lower RPM bounds:\n{");

for gear = 1:num_gears

    if gear < num_gears

        fprintf( ...
            "%.0f, ", ...
            LowerBoundRPM(gear));

    else

        fprintf( ...
            "%.0f", ...
            LowerBoundRPM(gear));

    end

end

fprintf("}\n\n");


fprintf("Upper RPM bounds:\n{");

for gear = 1:num_gears

    if gear < num_gears

        fprintf( ...
            "%.0f, ", ...
            UpperBoundRPM(gear));

    else

        fprintf( ...
            "%.0f", ...
            UpperBoundRPM(gear));

    end

end

fprintf("}\n\n");


%% ================================================================
%  ENGINE TORQUE / POWER PLOT
% ================================================================

figure

yyaxis left

plot( ...
    rpm_map, ...
    torque_map, ...
    "LineWidth",2)

ylabel("Engine Torque [Nm]")


yyaxis right

plot( ...
    rpm_map, ...
    engine_power_kw, ...
    "LineWidth",2)

ylabel("Engine Power [kW]")


xlabel("Engine Speed [RPM]")

title("Full-Throttle Engine Torque and Power")

grid on


%% ================================================================
%  GEAR CROSSOVER PLOTS
% ================================================================

figure

tiledlayout( ...
    ceil((num_gears-1)/2), ...
    2, ...
    "TileSpacing","compact", ...
    "Padding","compact");


for gear = 1:num_gears-1

    nexttile


    rpm_plot = ...
        comparison_data{gear}.rpm;


    plot( ...
        rpm_plot, ...
        comparison_data{gear}.current, ...
        "LineWidth",2)

    hold on


    plot( ...
        rpm_plot, ...
        comparison_data{gear}.next, ...
        "LineWidth",2)


    xline( ...
        upshift_rpm(gear), ...
        "--", ...
        sprintf( ...
            "Upshift = %.0f RPM", ...
            upshift_rpm(gear)), ...
        "LineWidth",1.5);


    xlabel( ...
        sprintf( ...
            "Gear %d Engine RPM", ...
            gear));


    ylabel( ...
        "Torque \times Gear Ratio [Nm]")


    title( ...
        sprintf( ...
            "Gear %d \\rightarrow Gear %d", ...
            gear, ...
            gear+1));


    legend( ...
        sprintf( ...
            "Stay in Gear %d", ...
            gear), ...
        sprintf( ...
            "Shift to Gear %d", ...
            gear+1), ...
        "Location","best");


    grid on

end


%% ================================================================
%  SHIFT BOUND PLOT
% ================================================================

figure

hold on


for gear = 1:num_gears

    plot( ...
        [gear gear], ...
        [LowerBoundRPM(gear) UpperBoundRPM(gear)], ...
        "-o", ...
        "LineWidth",2)

end


xlabel("Gear")

ylabel("Engine RPM")

title("Gear Operating RPM Bounds")

xticks(1:num_gears)

grid on


%% ================================================================
%  OPTIONAL SAVE
% ================================================================

% output_file = ...
%     "/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/control/acceleration_interface/config/optimal_shift_bounds.csv";
%
% writetable(shift_schedule,output_file);