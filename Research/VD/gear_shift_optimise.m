clc
clear
close all

%% ================================================================
%  OPTIMAL GEAR SHIFT BOUND GENERATOR
%
%  Uses engine torque map to determine:
%
%       lower RPM bound -> downshift
%       upper RPM bound -> upshift
%
%  Strategy:
%
%  For gear i:
%
%       Te(RPM_i)*G_i
%
%  is compared against the wheel torque available after shifting:
%
%       Te(RPM_{i+1})*G_{i+1}
%
%  where:
%
%       RPM_{i+1} = RPM_i * G_{i+1}/G_i
%
%  The crossover is the optimal upshift RPM.
%
%  A hysteresis band is then added to the downshift boundary to
%  prevent gear hunting.
%
% ================================================================


%% ======================= USER SETTINGS ============================

engine_map_file = ...
    "/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/control/acceleration_interface/config/engine_map_30psi.csv";

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

% Engine operating limits
redline_rpm = 7500;

% Do not search for an upshift below this RPM.
% This mainly protects against strange low-RPM map behavior.
minimum_upshift_rpm = 3000;

% Lowest RPM where we allow a downshift boundary.
minimum_operating_rpm = 1500;

% Hysteresis applied to DOWN shifts.
%
% Example:
%
%   theoretical 3rd gear lower bound = 5100 RPM
%   hysteresis = 300 RPM
%
%   actual downshift boundary = 4800 RPM
%
hysteresis_rpm = 300;

% Resolution used when searching for torque crossovers
rpm_resolution = 1;


%% ======================= LOAD ENGINE MAP ==========================

opts = detectImportOptions( ...
    engine_map_file, ...
    "VariableNamingRule","preserve");

engine_map = readtable(engine_map_file,opts);

variable_names = string(engine_map.Properties.VariableNames);

% Find RPM column
rpm_col = find(strcmpi(variable_names,"rpm"),1);

if isempty(rpm_col)
    error("Could not find an RPM column in the engine map.")
end

rpm_map = engine_map{:,rpm_col};


%% ================= FIND FULL THROTTLE COLUMN ======================

% Headers in your file are:
%
%   rpm     0.0     0.3     0.6     1
%
% We want throttle = 1.

candidate_cols = setdiff(1:width(engine_map),rpm_col);

throttle_values = ...
    str2double(variable_names(candidate_cols));

target_throttle = 1.0;

[~,closest_throttle_idx] = ...
    min(abs(throttle_values-target_throttle));

torque_col = candidate_cols(closest_throttle_idx);

torque_map = engine_map{:,torque_col};

fprintf("\nUsing throttle column: %s\n", ...
    variable_names(torque_col));


%% ======================= CLEAN ENGINE MAP =========================

valid = ...
    isfinite(rpm_map) & ...
    isfinite(torque_map);

rpm_map = rpm_map(valid);
torque_map = torque_map(valid);

% Sort by RPM
[rpm_map,sort_idx] = sort(rpm_map);
torque_map = torque_map(sort_idx);

% Remove duplicate RPM points if any exist
[rpm_map,unique_idx] = unique(rpm_map,"stable");
torque_map = torque_map(unique_idx);

% Prevent redline from exceeding map
redline_rpm = min(redline_rpm,max(rpm_map));


%% ===================== ENGINE INFORMATION =========================

engine_power_kw = ...
    torque_map .* rpm_map .* (2*pi/60) / 1000;

[peak_torque,idx_peak_torque] = max(torque_map);
rpm_peak_torque = rpm_map(idx_peak_torque);

[peak_power,idx_peak_power] = max(engine_power_kw);
rpm_peak_power = rpm_map(idx_peak_power);

fprintf("\n========================================\n")
fprintf("ENGINE MAP INFORMATION\n")
fprintf("========================================\n")
fprintf("Peak torque : %.2f Nm @ %.0f RPM\n", ...
    peak_torque,rpm_peak_torque)

fprintf("Peak power  : %.2f kW @ %.0f RPM\n", ...
    peak_power,rpm_peak_power)

fprintf("Redline     : %.0f RPM\n",redline_rpm)


%% ================================================================
%  FIND OPTIMAL UPSHIFT RPM
% ================================================================

upshift_rpm = nan(num_gears,1);

% RPM immediately after each upshift
rpm_after_shift = nan(num_gears,1);

% Store crossover data for plotting
comparison_data = cell(num_gears-1,1);


for gear = 1:num_gears-1

    G_current = gear_ratio(gear);
    G_next    = gear_ratio(gear+1);

    % Search current gear RPM
    rpm_current = ...
        (minimum_upshift_rpm:rpm_resolution:redline_rpm)';

    % RPM after changing into next gear
    rpm_next = ...
        rpm_current .* G_next/G_current;


    %% Only use locations covered by engine map

    valid_rpm = ...
        rpm_current >= min(rpm_map) & ...
        rpm_current <= max(rpm_map) & ...
        rpm_next    >= min(rpm_map) & ...
        rpm_next    <= max(rpm_map);

    rpm_current = rpm_current(valid_rpm);
    rpm_next    = rpm_next(valid_rpm);


    %% Engine torque

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
    % Final drive and drivetrain efficiency are omitted because they
    % are common to both gears and therefore cancel when determining
    % the crossover.
    %

    wheel_torque_current = ...
        torque_current .* G_current;

    wheel_torque_next = ...
        torque_next .* G_next;


    %% Difference
    %
    % positive:
    %       next gear makes MORE wheel torque
    %
    % negative:
    %       current gear makes MORE wheel torque
    %

    advantage_next = ...
        wheel_torque_next - wheel_torque_current;


    %% ============================================================
    %  FIND CROSSOVER
    %
    %  We want the final crossover where the next gear becomes
    %  better and remains better approaching redline.
    % ============================================================

    if advantage_next(end) <= 0

        % Current gear is still better at redline.
        % Therefore shift because of redline rather than torque
        % crossover.

        shift_rpm = redline_rpm;

    else

        crossover_idx = find( ...
            advantage_next(1:end-1) <= 0 & ...
            advantage_next(2:end)   >= 0, ...
            1, ...
            "last");


        if isempty(crossover_idx)

            % Next gear is already superior throughout search range.
            shift_rpm = rpm_current(1);

        else

            %% Linear interpolation of zero crossing

            x1 = rpm_current(crossover_idx);
            x2 = rpm_current(crossover_idx+1);

            y1 = advantage_next(crossover_idx);
            y2 = advantage_next(crossover_idx+1);

            shift_rpm = ...
                x1 - y1*(x2-x1)/(y2-y1);

        end
    end


    %% Save result

    upshift_rpm(gear) = shift_rpm;

    rpm_after_shift(gear) = ...
        shift_rpm * G_next/G_current;


    %% Store plotting information

    comparison_data{gear}.rpm = rpm_current;
    comparison_data{gear}.current = wheel_torque_current;
    comparison_data{gear}.next = wheel_torque_next;


end


%% Last gear cannot upshift

upshift_rpm(end) = redline_rpm;


%% ================================================================
%  CALCULATE LOWER / DOWNSHIFT BOUNDS
% ================================================================

downshift_rpm = nan(num_gears,1);

% First gear has no lower gear
downshift_rpm(1) = 0;


for gear = 2:num_gears

    %% Theoretical crossover RPM in CURRENT gear
    %
    % Example:
    %
    % 2nd upshifts at 7000 RPM.
    %
    % After shifting:
    %
    % RPM_3 = 7000 * G3/G2
    %
    % That RPM represents the same physical vehicle speed.
    %

    theoretical_lower_bound = ...
        upshift_rpm(gear-1) * ...
        gear_ratio(gear)/gear_ratio(gear-1);


    %% Add hysteresis
    %
    % Lowering the downshift boundary prevents:
    %
    %       2 -> 3 -> 2 -> 3
    %
    % immediately around the force crossover.
    %

    downshift_rpm(gear) = ...
        theoretical_lower_bound - hysteresis_rpm;


    %% Clamp minimum

    downshift_rpm(gear) = ...
        max( ...
        downshift_rpm(gear), ...
        minimum_operating_rpm);

end


%% ================================================================
%  ROUND VALUES FOR CONTROLLER
% ================================================================

upshift_rpm_rounded = ...
    round(upshift_rpm/10)*10;

downshift_rpm_rounded = ...
    round(downshift_rpm/10)*10;

rpm_after_shift_rounded = ...
    round(rpm_after_shift/10)*10;


%% ================================================================
%  CREATE SHIFT TABLE
% ================================================================

Gear = (1:num_gears)';

LowerBoundRPM = downshift_rpm_rounded;
UpperBoundRPM = upshift_rpm_rounded;

RPM_After_Upshift = rpm_after_shift_rounded;

shift_schedule = table( ...
    Gear, ...
    LowerBoundRPM, ...
    UpperBoundRPM, ...
    RPM_After_Upshift);


fprintf("\n\n========================================\n")
fprintf("OPTIMAL SHIFT SCHEDULE\n")
fprintf("========================================\n\n")

disp(shift_schedule)


%% ================================================================
%  PRINT COPY-PASTE CONTROLLER ARRAYS
% ================================================================

fprintf("\n========================================\n")
fprintf("COPY-PASTE ARRAYS\n")
fprintf("========================================\n\n")


fprintf("Lower RPM bounds:\n{");

for gear = 1:num_gears

    if gear < num_gears
        fprintf("%.0f, ",LowerBoundRPM(gear));
    else
        fprintf("%.0f",LowerBoundRPM(gear));
    end

end

fprintf("}\n\n");


fprintf("Upper RPM bounds:\n{");

for gear = 1:num_gears

    if gear < num_gears
        fprintf("%.0f, ",UpperBoundRPM(gear));
    else
        fprintf("%.0f",UpperBoundRPM(gear));
    end

end

fprintf("}\n");


%% ================================================================
%  PLOT ENGINE TORQUE AND POWER
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

title("Full-Throttle Engine Map")

grid on


%% ================================================================
%  PLOT EACH GEAR CROSSOVER
% ================================================================

figure

tiledlayout( ...
    ceil((num_gears-1)/2), ...
    2, ...
    "TileSpacing","compact", ...
    "Padding","compact");


for gear = 1:num_gears-1

    nexttile

    rpm_plot = comparison_data{gear}.rpm;

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
        sprintf("Shift %.0f RPM",upshift_rpm(gear)), ...
        "LineWidth",1.5);


    xlabel(sprintf("Gear %d Engine RPM",gear))

    ylabel("Equivalent Wheel Torque")

    title(sprintf( ...
        "Gear %d  \\rightarrow  Gear %d", ...
        gear, ...
        gear+1))

    legend( ...
        sprintf("Stay in Gear %d",gear), ...
        sprintf("Shift to Gear %d",gear+1), ...
        "Location","best")

    grid on

end


%% ================================================================
%  OPTIONAL: SAVE SHIFT SCHEDULE
% ================================================================

% output_file = ...
%     "/home/elijah/PurdueRacing/on_vehicle/on-vehicle/src/control/acceleration_interface/config/optimal_shift_bounds.csv";
%
% writetable(shift_schedule,output_file);