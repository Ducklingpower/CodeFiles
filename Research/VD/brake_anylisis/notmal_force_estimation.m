clc
close all
clear
% nomral force estimation




%% analysis time window



time_segment = [1450 1460]; % for wheel like on straight

time_segment = [1720 1734; 1800 1810; 1907 1916;1977 1986; 2075 2087; 2156 2166];
time_segment = [256 264;345 350;365 372; 446 452; 464 473; 546 550; 641 644; 658 665; 733 736; 749 756; 823 826; 840 846] % copmp t11 T2
time_segment = [0 Inf]
%% opening csv

%data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_28_fastlap_tireLocking_acc/csv_output/2026-07-28_153834_merged.csv"); %% fast lap
%data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_19_full_test/csv_output/2026-07-19_133128_merged.csv");%% lift up tires
%data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_28_HardBraking_feedbackcontroller/csv_output/2026-07-28_130732_merged.csv");
data  = readtable("/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv");
%data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_19_full_test/csv_output/2026-07-19_133128_merged.csv");
%% sensor source

use_oms = false;

% Longitudinal acceleration, both sources. Not part of the switch.
sensor.ax = "a_x";

if use_oms
    sensor.vx      = "oms_vel_x_kmh";
    sensor.vxScale = 1/3.6;                 % km/h -> m/s
    sensor.vy      = "oms_vel_y_kmh";
    sensor.vyScale = 1/3.6;
    sensor.label   = "OMS velocity + logged a_x";
else
    sensor.vx      = "odom_vx_mps";
    sensor.vxScale = 1;
    sensor.vy      = "odom_vy_mps";
    sensor.vyScale = 1;
    sensor.label   = "odometry velocity + logged a_x";
end

sensor_missing = setdiff([sensor.vx, sensor.vy, sensor.ax], ...
    string(data.Properties.VariableNames));

if ~isempty(sensor_missing)
    error("notmal_force_estimation:missingSensorChannel", ...
        "use_oms = %d asks for %s, which this log does not have. " + ...
        "Flip use_oms at the top of the script.", ...
        use_oms, join(sensor_missing, ", "));
end

fprintf("sensor source: %s   (v_x %s, v_y %s, a_x %s)\n", ...
    sensor.label, sensor.vx, sensor.vy, sensor.ax);

%% filtered data

% Where longitudinal acceleration comes from. See "longitudinal acceleration
% source" below.
%   "channel"    -> the sensor.ax column chosen above, as logged
%   "derivative" -> differentiated from the filtered speed Fvx
ax_source = "channel";

mm = 30;

%% FIGURE WINDOWS
%
% This script makes 25+ figures. R2025b docks them all into one tab strip in a
% single window, in creation order, which is unusable for finding the one you
% want. So instead each figure becomes a TAB inside one of a handful of themed
% container WINDOWS, grouped by what the plot is actually about.
%
% Set figureGrouping = false to go back to one loose figure per plot.
figureGrouping = true;

% key -> window title. Order here is the order the windows are created in.
figGroupDefs = { ...
    "inputs",   "1 - Inputs & Sensors"          ; ...
    "normal",   "2 - Normal Force & Load Transfer" ; ...
    "lateral",  "3 - Lateral (slip angle, F_y)" ; ...
    "long",     "4 - Longitudinal (slip ratio, F_x)" ; ...
    "circle",   "5 - Friction Circles"          ; ...
    "maps",     "6 - Operating Maps (speed / a_x planes)" ; ...
    "envelope", "7 - Acceleration Envelope"     };

FG = makeFigureGroups(figGroupDefs, figureGrouping);

%% applying the time window


t0_recording = data.time_s(1);
t_recording  = data.time_s - t0_recording;

gage_zero = [ ...
    movmean(data.fl_load_n, mm), ...
    movmean(data.fr_load_n, mm), ...
    movmean(data.rl_load_n, mm), ...
    movmean(data.rr_load_n, mm)];

gage_zero = gage_zero(min(100, height(data)), :);   % [fl fr rl rr]

%% wheel speed calibration
% Runs on the FULL recording, before the time window is applied, for the same
% reason gage_zero does: a time_segment made of hard braking windows may not
% contain a single free-rolling sample to calibrate on.
%
% A free-rolling wheel has slip ratio zero by definition, so in a straight
% line, at steady speed, with the brakes off, every wheel speed channel must
% read the ground speed. Whatever it reads instead is a rolling-radius or
% calibration error, and it lands as a STANDING OFFSET on every slip ratio
% built from that channel.
%
% This replaces the old  ./3.61 - 0.1. That was one common factor applied to
% all four wheels, and one factor cannot null both axles when the front and
% rear tires are different sizes. On this recording it nulls the REAR
% (+0.0007) and leaves the FRONT at +0.0063 - more than twice the front slip
% actually seen under braking (-0.0028), and opposite in sign, so the front
% tire curve in measured_slip_ratio_front.csv comes out translated sideways by
% more than its own amplitude.
%
% A SCALE, not an offset: the residual is flat with speed (+0.0055 at 12-18
% m/s, +0.0071 at 30-36), which is the signature of a radius error. A sensor
% offset would shrink as speed rises.

wheelCal_brakeMax_kPa = 60;     % both circuits below this counts as brakes off
wheelCal_axMax        = 0.6;    % m/s^2, near enough to no longitudinal force
wheelCal_ayMax        = 0.5;    % m/s^2
wheelCal_steerMax     = 2;      % deg
wheelCal_vxMin        = 12;     % m/s
wheelCal_minSamples   = 300;

cal_vx    = movmean(data.(char(sensor.vx)), mm) .* sensor.vxScale;
cal_ax    = movmean(data.(char(sensor.ax)), mm);
cal_ay    = movmean(data.a_y, mm);
cal_steer = movmean(data.steer_wheel_ang_deg, mm);

freeRolling = abs(cal_ay)    < wheelCal_ayMax ...
            & abs(cal_steer) < wheelCal_steerMax ...
            & abs(cal_ax)    < wheelCal_axMax ...
            & movmean(data.front_brake_pressure_kpa, mm) < wheelCal_brakeMax_kPa ...
            & movmean(data.rear_brake_pressure_kpa,  mm) < wheelCal_brakeMax_kPa ...
            & cal_vx > wheelCal_vxMin ...
            & isfinite(cal_vx);

wheelSpeed_channels = ["fl_speed_kmh", "fr_speed_kmh", "rl_speed_kmh", "rr_speed_kmh"];
wheelSpeed_names    = ["FL", "FR", "RL", "RR"];
wheelSpeedCal       = ones(1,4);

if sum(freeRolling) < wheelCal_minSamples

    warning("notmal_force_estimation:noFreeRolling", ...
        "Only %d free-rolling samples (need %d); wheel speeds left uncalibrated. " + ...
        "Every slip ratio below will carry whatever standing offset the channels have.", ...
        sum(freeRolling), wheelCal_minSamples);
else
    fprintf("wheel speed calibration on %d free-rolling samples (straight, brakes off, |a_x|<%.1f):\n", ...
        sum(freeRolling), wheelCal_axMax);

    for iWheel = 1:4

        vw = movmean(data.(char(wheelSpeed_channels(iWheel))), mm) ./ 3.6;
        wheelSpeedCal(iWheel) = mean(vw(freeRolling) ./ cal_vx(freeRolling), "omitnan");

        fprintf("  %s reads %+.3f%% against ground speed -> scale %.5f (free-rolling slip %+.5f -> 0)\n", ...
            wheelSpeed_names(iWheel), 100*(wheelSpeedCal(iWheel)-1), ...
            1/wheelSpeedCal(iWheel), 1 - 1/wheelSpeedCal(iWheel));
    end
end

% Front/rear rolling radius ratio, from the same calibration. v = omega*R, so a
% channel that over-reads by x% was built with a radius x% larger than the
% truth, and the ratio of the two axles' errors is the ratio of their radii -
% PROVIDED the logger used one common radius for all four channels. If it
% already applies per-wheel radii, this residual is calibration error instead
% and says nothing about radius. Either way the two cannot both be right, which
% is the point of printing it.
rollingRadiusRatio = mean(wheelSpeedCal(1:2)) / mean(wheelSpeedCal(3:4));   % R_r / R_f

fprintf("  implied R_r/R_f = %.4f\n", rollingRadiusRatio);

if isempty(time_segment)
    time_segment = [0 Inf];
end

if size(time_segment, 2) ~= 2
    error("notmal_force_estimation:badSegment", ...
        "time_segment must be an N-by-2 matrix, one [t_min t_max] row per section.");
end

% Chronological order, so segment_id below counts up with time.
time_segment = sortrows(time_segment, 1);
n_segments = size(time_segment, 1);

% Union of every row. segment_id records which row each kept sample came from.
segment_keep = false(height(data), 1);
segment_id   = zeros(height(data), 1);

for iSeg = n_segments:-1:1
    inSeg = t_recording >= time_segment(iSeg,1) & t_recording <= time_segment(iSeg,2);

    if ~any(inSeg)
        warning("notmal_force_estimation:emptySegmentRow", ...
            "time_segment row %d [%g %g] s selects no samples.", ...
            iSeg, time_segment(iSeg,1), time_segment(iSeg,2));
    end

    % Descending loop so overlapping rows are attributed to the earliest one.
    segment_keep = segment_keep | inSeg;
    segment_id(inSeg) = iSeg;
end

if ~any(segment_keep)
    error("notmal_force_estimation:emptySegment", ...
        "time_segment selects no samples (recording is %.1f s long).", ...
        t_recording(end));
end

data       = data(segment_keep, :);
segment_id = segment_id(segment_keep);

fprintf("time_segment: %d section(s), %d of %d samples\n", ...
    n_segments, sum(segment_keep), numel(segment_keep));

for iSeg = 1:n_segments
    inSeg = segment_id == iSeg;

    if any(inSeg)
        segTimes = t_recording(segment_keep);
        fprintf("  section %d: %.2f s to %.2f s (%d samples)\n", ...
            iSeg, min(segTimes(inSeg)), max(segTimes(inSeg)), sum(inSeg));
    end
end

% Time stays referenced to the start of the recording, so a cropped window
% keeps its true timestamps on every axis and colorbar.
t = data.time_s(:) - t0_recording;
tAbs = t;


dt_sample = diff(t);
seam_idx  = find(diff(segment_id) ~= 0 & dt_sample > 2 * median(dt_sample));
seam_time = t(seam_idx);
seam_guard = ceil(mm/2);

seamValid = true(numel(t), 1);

for iSeam = 1:numel(seam_idx)
    lo = max(1, seam_idx(iSeam) - seam_guard);
    hi = min(numel(t), seam_idx(iSeam) + 1 + seam_guard);
    seamValid(lo:hi) = false;
end

if ~isempty(seam_idx)
    fprintf("  %d seam(s) between sections, %d samples guarded\n", ...
        numel(seam_idx), sum(~seamValid));
end


t_plot = t;
t_plot(seam_idx) = NaN;

Fax_channel = movmean(data.(char(sensor.ax)), mm);   % Fax itself is chosen
                                                     % below by ax_source
Fay = movmean(data.a_y,mm);
Faz = movmean(data.a_z,mm);

Ffz_fr = data.fr_load_n;
Ffz_fl = data.fl_load_n;
Ffz_rr = data.rr_load_n;
Ffz_rl = data.rl_load_n;

Ffz_fr = movmean(data.fr_load_n,mm);
Ffz_fl = movmean(data.fl_load_n,mm);
Ffz_rr = movmean(data.rr_load_n,mm);
Ffz_rl = movmean(data.rl_load_n,mm);


Fvx = movmean(data.(char(sensor.vx)), mm) .* sensor.vxScale;
Fvy = movmean(data.(char(sensor.vy)), mm) .* sensor.vyScale;

Frpm = movmean(data.engine_rpm,mm);
throttle = data.throttle_pct;
Fgear = movmean(data.current_gear,mm);
FT_e = movmean(data.est_drive_torque_nm,mm);
Fbrake = movmean(data.front_brake_pressure_kpa,mm);

steering_wheel = movmean(data.steer_wheel_ang_deg,mm); 
toe_angle = 0.333+(steering_wheel)/15.015;
toe_rad = toe_angle*(pi/180);

Fqx = movmean(data.odom_qx,mm);
Fqy = movmean(data.odom_qy,mm);
Fqz = movmean(data.odom_qz,mm);
Fqw = movmean(data.odom_qw,mm);

Fwz = movmean(data.odom_wz_rads,mm);
Fwx = movmean(data.odom_wx_rads,mm);
Fwy = -movmean(data.odom_wy_rads,mm);



Fq = [Fqw Fqx Fqy Fqz];         
Feul = quat2eul(Fq, 'ZYX');   % [yaw pitch roll]

Fyaw   = Feul(:,1);
Fpitch = -Feul(:,2);
Froll  = Feul(:,3);

yaw_u   = unwrap(Fyaw);
pitch_u = unwrap(Fpitch);
roll_u  = unwrap(Froll);

yaw_dot   = Fwz;
pitch_dot = Fwy;
roll_dot  = Fwx;

yaw_unwrapped = unwrap(Fyaw);

x_pos = data.odom_px_m;
y_pos = data.odom_py_m;

%% longitudinal acceleration source
% ax_source picks what feeds Fax, which sets Fx_total and so every longitudinal
% force in this script. It has to be chosen here rather than up with the other
% filtered channels, because the derivative needs Fvx, Fvy and Fwz.
%
%   "channel"     the sensor.ax column as logged.
%
%   "derivative"  differentiated from the filtered speed, so it inherits
%                 whatever Fvx is built from. Body-frame kinematics rather than
%                 a plain derivative: for axes that turn with the car,
%                 a_x = d(vx)/dt - r*vy. On this recording the r*vy term is
%                 tiny (p95 about 0.05 m/s^2, ~40 N) because the odometry
%                 sideslip stays near zero, but it is the correct form and
%                 costs nothing.
%
% The derivative differentiates straight across a section seam. seamValid
% already vetoes those samples in the results, but the raw trace in fig S0 will
% show a spike at each join.

ax_dt = gradient(t);
ax_dt(ax_dt <= 0) = median(ax_dt(ax_dt > 0));

switch lower(string(ax_source))

    case "channel"
        Fax = Fax_channel;
        ax_source_label = "logged " + sensor.ax;

    case "derivative"
        Fax = movmean(gradient(Fvx) ./ ax_dt, mm) - Fwz .* Fvy;
        ax_source_label = "d(v_x)/dt - r v_y";

    otherwise
        error("notmal_force_estimation:badAxSource", ...
            "ax_source must be ""channel"" or ""derivative"", got ""%s"".", ...
            ax_source);
end

axCompare = isfinite(Fax) & isfinite(Fax_channel) & seamValid;

fprintf("a_x source: %s  (vs the logged channel: bias %+.3f, rms %.3f m/s^2, %d samples)\n", ...
    ax_source_label, ...
    mean(Fax(axCompare) - Fax_channel(axCompare)), ...
    std(Fax(axCompare) - Fax_channel(axCompare)), ...
    sum(axCompare));

%% tire temp


tireTemp_validRange = [0 200];   

tire_temp_prefix  = ["fl", "fr", "rl", "rr"];
tire_temp_names   = ["FL", "FR", "RL", "RR"];
tire_temp_sensors = cell(4,1);              
tire_temp_mean    = nan(height(data), 4);   

dataVars = string(data.Properties.VariableNames);

for iTire = 1:4

    sensors = nan(height(data), 4);

    for iSensor = 1:4
        colName = tire_temp_prefix(iTire) + "_temp_" + iSensor;

        if any(dataVars == colName)
            sensors(:,iSensor) = data.(char(colName));
        else
            warning("notmal_force_estimation:missingTireTemp", ...
                "%s is not in the log; it is left out of the %s average.", ...
                colName, tire_temp_names(iTire));
        end
    end

    sensors(sensors < tireTemp_validRange(1) | sensors > tireTemp_validRange(2)) = NaN;

    tire_temp_sensors{iTire} = sensors;
    tire_temp_mean(:,iTire)  = mean(sensors, 2, "omitnan");

    sensorLive = any(isfinite(sensors), 1);

    fprintf("tire temp %s: %d of 4 sensors live, %.1f%% of samples have a reading, mean %.1f C\n", ...
        tire_temp_names(iTire), sum(sensorLive), ...
        100 * mean(isfinite(tire_temp_mean(:,iTire))), ...
        mean(tire_temp_mean(:,iTire), "omitnan"));
end

tire_temp_mean_f = movmean(tire_temp_mean, mm, 1, "omitnan");

%% fig T1 - the four sensors and their average, per tire
parentT1 = newFigTab(FG, "inputs", 'Fig T1 - Tire Temperature (sensors and average, per tire)');

layoutT1 = tiledlayout(parentT1, 2, 2, "TileSpacing", "compact", "Padding", "compact");

axT1 = gobjects(4,1);

for iTire = 1:4

    axT1(iTire) = nexttile(layoutT1);
    hold on

    for iSensor = 1:4
        plot(t_plot, tire_temp_sensors{iTire}(:,iSensor), "LineWidth", 0.8, ...
            "DisplayName", sprintf("sensor %d", iSensor));
    end

    plot(t_plot, tire_temp_mean_f(:,iTire), "k", "LineWidth", 2, ...
        "DisplayName", "tire average");

    hold off
    grid on
    box on

    title(tire_temp_names(iTire), "FontWeight", "bold");
    xlabel("Time [s]");
    ylabel("Temperature [\circC]");

    set(axT1(iTire), "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);

    if iTire == 1
        legend("Location", "best");
    end
end

linkaxes(axT1, "xy");

title(layoutT1, "Tire temperature - across-tread sensors and their average", ...
    "FontWeight", "bold");

%% fig T2 - the four tire averages together
parentT2 = newFigTab(FG, "inputs", 'Fig T2 - Tire Temperature (average per tire)');

axT2 = axes(parentT2);

plot(t_plot, tire_temp_mean_f, "LineWidth", 1.8);
grid on
box on

xlabel("Time [s]");
ylabel("Temperature [\circC]");
title("Average tire temperature per tire, fault codes removed before averaging", ...
    "FontWeight", "bold");
legend(tire_temp_names, "Location", "best");

set(axT2, "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);

for iSeam = 1:numel(seam_time)
    xline(axT2, seam_time(iSeam), "k:", "LineWidth", 1.2, "HandleVisibility", "off");
end

%% pose


pos_valid = isfinite(x_pos) & isfinite(y_pos);

parentPose = newFigTab(FG, "inputs", 'Vehicle Pose (x-y)');
axes(parentPose);
scatter(x_pos(pos_valid), y_pos(pos_valid), 10, t(pos_valid), "filled");
hold on
plot(x_pos(find(pos_valid, 1)), y_pos(find(pos_valid, 1)), ...
    "o", "MarkerSize", 9, "MarkerFaceColor", "g", "MarkerEdgeColor", "k");
plot(x_pos(find(pos_valid, 1, "last")), y_pos(find(pos_valid, 1, "last")), ...
    "s", "MarkerSize", 9, "MarkerFaceColor", "r", "MarkerEdgeColor", "k");
grid on
axis equal
xlabel("x [m]");
ylabel("y [m]");
if n_segments > 1
    title(sprintf("Vehicle pose, %d sections between %.1f s and %.1f s", ...
        n_segments, t(1), t(end)));
else
    title(sprintf("Vehicle pose, %.1f s to %.1f s", t(1), t(end)));
end
legend("path", "start", "end", "Location", "best");
cb = colorbar;
ylabel(cb, "Time [s]");




%% adjusting strain gage sensors


% STATIC CORNER LOADS  [FL FR RL RR], newtons.
%
% This is a MEASUREMENT INPUT. Put corner scale readings here. The default
% below is the old geometric split - 42% front, and left/right assumed equal -
% which is an assumption, not data, and it is the assumption that a cross-weight
% violates.
%
% Why it matters: the dual-track model splits each axle by these shares, so a
% cross-weight the car really has but this array does not will land entirely on
% one tire's mu. With an open diff, where both rear wheels take equal force,
% that error goes straight into deciding which wheel spins first - the lighter
% one always lets go first, so getting its load wrong points the blame at the
% wrong corner.
%
% This recording HINTS at a rear cross-weight with RR heavier, but cannot size
% it. The gages say RR-RL is about +405 N at matched free-rolling conditions and
% the damper pots say about +171 N - a factor of 2.4 apart - and over the session
% the two ANTI-correlate (r = -0.88). Meanwhile the gage bias itself wanders 243 N
% on FR and 189 N on RL at matched conditions, with the four-corner sum moving
% 462 N when it must be constant. The sign is probably real; the magnitude is
% inside the noise.
%
% GET CORNER SCALES. Nothing in a driving log can separate a real cross-weight
% from a gage offset - see the zeroing note below.
staticCornerLoad_N = [1679, 1679, 2318.6, 2318.6];   % [FL FR RL RR]

fz_fl_geo = staticCornerLoad_N(1);
fz_fr_geo = staticCornerLoad_N(2);
fz_rl_geo = staticCornerLoad_N(3);
fz_rr_geo = staticCornerLoad_N(4);

% Left/right share of each axle, used to split the modelled axle loads per
% corner. Symmetric corner loads give 0.5 each and reproduce the old /2 exactly,
% so this changes nothing until real corner weights go in above.
cornerShare_fl = fz_fl_geo / (fz_fl_geo + fz_fr_geo);
cornerShare_fr = fz_fr_geo / (fz_fl_geo + fz_fr_geo);
cornerShare_rl = fz_rl_geo / (fz_rl_geo + fz_rr_geo);
cornerShare_rr = fz_rr_geo / (fz_rl_geo + fz_rr_geo);

fprintf("static corner shares: front %.3f/%.3f L/R, rear %.3f/%.3f L/R", ...
    cornerShare_fl, cornerShare_fr, cornerShare_rl, cornerShare_rr);

if abs(cornerShare_rl - 0.5) < 1e-6 && abs(cornerShare_fl - 0.5) < 1e-6
    fprintf("   <- SYMMETRIC (assumed, not measured - see staticCornerLoad_N)\n");
else
    fprintf("   <- cross-weight carried through to the per-tire loads\n");
end

%% zeroing the gages
%
% gage_zero comes from the top of the script, sampled on the full recording
% before the time window is applied.
%
% Treat Fz_*_adjusted as a DIAGNOSTIC TRACE, not as truth. The gage bias drifts
% during a session, up and down, so no single zero - one sample or an average -
% is correct at every point in the run. That is the whole reason the derivative
% observer further down exists: it takes only the RATE of the gage signal, where
% a slowly drifting bias differentiates away, and anchors the absolute level to
% the dual-track model instead.
%
% For context on how unreliable the absolute level is, the four stationary
% stretches in this recording redistribute by more than 1000 N while their SUM
% stays put at about 14800:
%
%     0-562 s      FL 3666  FR 3574  RL 3586  RR 3990    RR-RL  405
%     564-698 s    FL 4093  FR 3186  RL 3155  RR 4463    RR-RL 1308
%     2213-2229 s  FL 3834  FR 3426  RL 3333  RR 4183    RR-RL  850
%     2538-2548 s  FL 3572  FR 3691  RL 3659  RR 3847    RR-RL  188
%
% Constant sum, diagonal redistribution - the car standing on uneven ground with
% suspension stiction holding whatever state it settled into, on top of whatever
% the bias is doing. Any of those four windows would give a different zero.
% Nothing here can separate a real cross-weight from gage bias, which is why
% staticCornerLoad_N above wants corner scales rather than a number fitted from
% this data.

error_fl = gage_zero(1) - fz_fl_geo;   Fz_fl_adjusted = Ffz_fl - error_fl;
error_fr = gage_zero(2) - fz_fr_geo;   Fz_fr_adjusted = Ffz_fr - error_fr;
error_rl = gage_zero(3) - fz_rl_geo;   Fz_rl_adjusted = Ffz_rl - error_rl;
error_rr = gage_zero(4) - fz_rr_geo;   Fz_rr_adjusted = Ffz_rr - error_rr;

fprintf("  offsets removed [N]: FL %+.0f  FR %+.0f  RL %+.0f  RR %+.0f\n", ...
    error_fl, error_fr, error_rl, error_rr);
fprintf("  static corner loads used [N]: FL %.0f  FR %.0f  RL %.0f  RR %.0f  (sum %.0f)\n", ...
    fz_fl_geo, fz_fr_geo, fz_rl_geo, fz_rr_geo, sum(staticCornerLoad_N));



parentGage = newFigTab(FG, "normal", 'Strain gage F_z, zeroed (per corner)');
layoutGage = tiledlayout(parentGage,2,2);
nexttile(layoutGage)
plot(t_plot,Fz_fr_adjusted);
grid on
legend("fr")

nexttile(layoutGage)
plot(t_plot,Fz_fl_adjusted)
grid on
legend("fl")

nexttile(layoutGage)
plot(t_plot,Fz_rr_adjusted)
grid on
legend("rr")

nexttile(layoutGage)
plot(t_plot,Fz_rl_adjusted)
grid on
legend("rl")

xlabel("time (s)")
ylabel("Normal force measured")



%% getting yaw, pitch, and roll curvature



V = sqrt(Fvx.^2 + Fvy.^2);
ds = [0; cumsum(0.5 * (V(1:end-1) + V(2:end)) .* diff(t))];

v_min_curv = 2.0;

% Curvature
kappa_yaw   = nan(size(V));
kappa_pitch = nan(size(V));
kappa_roll  = nan(size(V));

curv_valid = isfinite(V) & V > v_min_curv;

kappa_yaw(curv_valid)   = yaw_dot(curv_valid)   ./ V(curv_valid);
kappa_pitch(curv_valid) = pitch_dot(curv_valid) ./ V(curv_valid);
kappa_roll(curv_valid)  = roll_dot(curv_valid)  ./ V(curv_valid);

%% LATERAL ACCELERATION AT THE TIRES
%
% ONE lateral acceleration for the whole script. It has to be built here, before
% the load transfer, because the load transfer and the lateral forces used to be
% driven by two DIFFERENT accelerations:
%
%   lateral load transfer  <- Fay, the logged a_y channel
%   axle lateral force     <- ay_tire, built from yaw curvature
%
% On this recording those agree to corr 0.998, so the split was invisible. The
% bank correction below breaks that agreement, and then the F_z model and the F_y
% model disagree about how hard the car is cornering - the two halves of every
% mu = F_y / F_z. So both now read ay_tire.
%
% THE KINEMATIC TERM. a_y in a frame that turns with the car is
%
%     a_y = d(v_y)/dt + r*v_x
%
% The old form was V^2 * kappa_yaw, which reduces to V*r, and dropped d(v_y)/dt
% entirely. Two changes:
%
%   - V*r -> v_x*r. Worth nothing on this log (p95 of the difference is
%     0.002 m/s^2, the sideslip is tiny) but it is the correct term, and writing
%     it directly avoids dividing by V and multiplying it back.
%   - d(v_y)/dt is restored. p95 0.60 m/s^2, max 4.41 - up to 3600 N of axle
%     force, and it is concentrated in corner entry and exit, which is exactly
%     where the peak of the tire curve gets read.
%
% Writing it as v_x*r also removes the need for the curv_valid gate: there is no
% division by V any more, so ay_body is finite at every speed. That matters
% because the load transfer must not go NaN at low speed - it would take the
% observer and everything downstream with it.

% Road bank / crossfall handling. See the validation note below before changing.
useBankCorrection = true;

% Constant roll offset to remove before the bank correction, degrees, positive
% in the same sense as Froll.
%
% On straights (|a_y| < 1, |r| < 0.03) this log reads a MEDIAN roll of -1.43 deg.
% That is either genuine consistent crossfall or an IMU mounting offset, and
% nothing in a driving log can separate the two. Left at 0 so the default does
% not silently subtract a real road feature.
%
% It is worth measuring, because a constant roll offset is a CONSTANT phantom
% lateral force - 1.43 deg is m*g*sin(1.43) = 203 N always pushing the same way,
% which biases left-hand against right-hand corners and shows up as a left/right
% asymmetry in the per-tire mu. To measure it: park on known-flat ground and read
% Froll.
rollBias_deg = 0.0;

ay_dt = gradient(t);
ay_dt(ay_dt <= 0) = median(ay_dt(ay_dt > 0));

dvy_dt  = movmean(gradient(Fvy) ./ ay_dt, mm);
ay_body = Fvx .* Fwz + dvy_dt;          % kinematic, gravity-free, finite at all speeds

% GRAVITY ALONG THE BODY y AXIS.
%
% Fax, Fay and Faz are all gravity-COMPENSATED kinematic channels, not raw
% accelerometers - checked three ways on this log: corr(a_y, v_x*r) = 0.998 at
% slope 1.007, a_x - (dv_x/dt - r*v_y) has p95 0.68 m/s^2 with ZERO correlation
% against g*sin(pitch), and median a_z is +0.26 rather than +-9.81. So gravity is
% absent from every one of them and has to be added back by hand wherever a TIRE
% force is wanted. That is what this term does laterally, and what Fgrade does
% longitudinally.
%
% For ZYX with the script's negated pitch, g in body axes is
% [-g sin(Fpitch), -g cos(Fpitch) sin(Froll), -g cos(Fpitch) cos(Froll)], so the
% tires must supply m*ay_body - m*g_y_body.
Froll_corrected = Froll - deg2rad(rollBias_deg);

g_y_body = -9.81 .* cos(Fpitch) .* sin(Froll_corrected);

% IS Froll ACTUALLY THE ROAD BANK? Yes on this log, and the obvious test says no,
% so this is worth writing down.
%
% Froll regresses against a_y at -3.47 deg/g. That looks exactly like an INS
% leveling leak - an attitude filter letting lateral specific force tilt its
% gravity estimate - and the tempting fix is to detrend Froll against a_y. THAT
% WOULD BE WRONG. Binning the log into 8x8 m track cells revisited 20+ times:
%
%     within-cell std of Froll         0.10 deg   <- same place, same reading, every lap
%     across-cell std of mean Froll    2.82 deg   <- Froll is a function of PLACE
%     within-cell std of a_y           0.87 m/s^2 <- a_y moves; Froll does not follow
%
% Roll repeats to a tenth of a degree at a given point on track while a_y swings
% almost 1 m/s^2 there. The -3.47 deg/g is CONFOUNDING, not causation: the car
% corners in the same banked places every lap, so a_y and bank correlate through
% track geometry. Detrending destroys real signal - it cuts the place-dependent
% part from 2.82 to 1.76 deg and triples within-cell scatter to 0.35 deg.
% Independent confirmation: on straights, with no lateral acceleration to explain
% it, Froll still reads -1.43 deg median and 4.08 deg max.
%
% SIGN, checked physically rather than by inspection. Over the cornering samples
% (|a_y| > 4 m/s^2, V > 10, 43k samples) corr(g_y_body, ay_body) = +0.774: the
% bank is favourable, as a real track's is, and subtracting g_y_body correctly
% SHRINKS the demand on the tires by 7.0%. Adding it would grow it by the same
% 7.0%, so the sign here is load-bearing.
if useBankCorrection
    ay_tire_full = ay_body - g_y_body;
    ay_source_label = "v_x r + dv_y/dt, bank corrected";
else
    ay_tire_full = ay_body;
    ay_source_label = "v_x r + dv_y/dt, flat-road";
end

% Gated copy, for the slip/force figures and the pureLong mask, which have always
% dropped unresolved-curvature samples. ay_tire_full stays gap-free for the load
% transfer.
ay_tire = ay_tire_full;
ay_tire(~curv_valid) = NaN;

banked = isfinite(ay_body) & abs(ay_body) > 4 & V > 10;

% Reported as accelerations because the vehicle mass is not set until the params
% block below. Multiply by vehicleParams.m for the axle force.
fprintf("a_y source: %s\n", ay_source_label);
fprintf("  bank term g_y: median %.3f m/s^2 over cornering samples, p95 %.3f, max %.3f\n", ...
    median(abs(g_y_body(banked)), "omitnan"), ...
    prctile(abs(g_y_body), 95), max(abs(g_y_body)));

if any(banked)
    fprintf("  bank shifts the cornering demand by %+.1f%% (mean over %d cornering samples)\n", ...
        100 * mean(abs(ay_tire_full(banked)) - abs(ay_body(banked))) ...
            / mean(abs(ay_body(banked))), sum(banked));
end

fprintf("  dv_y/dt term: p95 %.2f m/s^2, max %.2f m/s^2\n", ...
    prctile(abs(dvy_dt), 95), max(abs(dvy_dt)));

% Straight-line roll diagnostic - the number rollBias_deg above wants.
straightish = isfinite(Fvy) & abs(ay_body) < 1.0 & abs(Fwz) < 0.03 & V > 8;

if any(straightish)
    fprintf("  roll on straights (%d samples): median %+.2f deg, max %.2f deg  <- rollBias_deg candidate\n", ...
        sum(straightish), rad2deg(median(Froll(straightish), "omitnan")), ...
        rad2deg(max(abs(Froll(straightish)))));
end



%% params 
vehicleParams.wheelbase   = 2.9718;      % wheelbase (m)  [2971.8 mm]
vehicleParams.w_dist_f    = 0.42;        % front weight distribution [42%]
vehicleParams.t_f         = 1.638762;    % front track (m)  [1638.762 mm]
vehicleParams.t_r         = 1.5239686;   % rear track (m)   [1523.9686 mm]

% Wheel rates computed from springs & motion ratios at 0 mm:
% avg stiffness*(motion_ratio)^2

vehicleParams.wheelRate_f = 2.985553732e5;  % (N/m) was 2.98
vehicleParams.wheelRate_r = 2.941321827e5;  % (N/m)

vehicleParams.ARB_f       = 0;             % (Nm/deg)  TBD
vehicleParams.ARB_r       = 0;              % (Nm/deg)  no anti roll bar in rear

% CG height (m). This sets the longitudinal load transfer, so it moves every
% F_z in this script, the mu that comes out of dividing by them, and the
% envelope at the end - it is not a detail.
%
% Was 0.575 with a comment reading [275 mm], which cannot both be right. 0.35
% is what brake_bias_schedule.m uses, so the two files now agree.
%
% It is worth knowing what the choice does to the answer. Under braking a
% higher cg_z hands load to the front, so it makes the front tire look grippier
% and the rear look weaker, and past about 0.5 it flips WHICH AXLE runs out of
% grip first - a stability conclusion, not a 10% number. Two consistency checks
% on this log bracket it: front and rear peak mu come out equal at about 0.28,
% and the rear's mu on power matches its mu on the brakes at about 0.47.
% Neither is clean, because both are divided by the measured brake bias.
% MEASURE THIS.
vehicleParams.cg_z        = 0.35;           % CG height (m)
vehicleParams.rc_f        = 0.1202436;      % roll center front (m) 
vehicleParams.rc_r        = 0.0016628;      % roll center rear  (m) 

vehicleParams.toe_f       = -0.451;         % toe front (deg, - = out) 
vehicleParams.toe_r       = -0.451;         % toe rear  (deg, - = out)

% Vehicle mass (kg). 815 matches both the corner loads in staticCornerLoad_N,
% which sum to 7995 N, and P.m in brake_bias_schedule.m. It was 800, which
% agreed with neither.
vehicleParams.m           = 815;

vehicleParams.mech_trail_f = 0;             % mech trail front (m) TBD
vehicleParams.mech_trail_r = 0;             % mech trail rear  (m) TBD

vehicleParams.frontalArea = 1 ;             % frontal area (m^2) TBD
vehicleParams.Cd          = 0.0;            % drag coeff (-)     TBD
vehicleParams.Cl          = 0.0;            % ift coeff (-)      TBD
vehicleParams.ACd         = 0.58;           % Area*coef down force      TBD
vehicleParams.aeroBalance = .33;            % frontal aero load (-) 33% avg
vehicleParams.copShift    = 0;              % balance shift with Vx (%/(m/s))TBD
vehicleParams.inertia     = 1000;           % moment of inertia

% Loaded tire radii. R_f is the anchor and has to come from a measurement -
% a rolling-circumference check, or the tire data sheet at your hot pressure.
% Nothing in this log fixes the ABSOLUTE scale: the wheel speed channels give
% omega*R, and without an independent omega there is no way to separate the two.
%
% What the log DOES fix is the RATIO, from the wheel speed calibration above.
% It reads R_r/R_f = 1.0056, against the 1.0333 that the old hard-coded pair
% (0.30 / 0.31) implied - six times the difference. R_r is therefore derived
% rather than typed in, so the radii and the wheel speeds cannot drift apart.
%
% Set useMeasuredRadiusRatio = false to go back to a hand-entered R_r.
useMeasuredRadiusRatio = true;

vehicleParams.R_f         = 0.30;           % front loaded tire radius (m) - MEASURE THIS

if useMeasuredRadiusRatio
    vehicleParams.R_r     = vehicleParams.R_f * rollingRadiusRatio;
    radiusSource          = "from wheel speeds";
else
    vehicleParams.R_r     = 0.31;           % rear loaded tire radius (m)
    radiusSource          = "hand-entered";
end

fprintf("tire radii: R_f %.4f m (anchor), R_r %.4f m (%s), ratio %.4f\n", ...
    vehicleParams.R_f, vehicleParams.R_r, radiusSource, ...
    vehicleParams.R_r / vehicleParams.R_f);

% Radius used to turn est_drive_torque_nm into a force at the rear contact
% patch. This is the weak link in the engine-braking split: a force-balance fit
% over the no-brake samples of this log put it near 0.356 m, but it was unstable
% across subsets (0.35 to 0.49 m) and implied a negative rolling resistance, so
% it is absorbing a bias somewhere. Treat it as a knob to sweep, not a
% measurement - over that range the rear mu correction runs +8% to +12%.
vehicleParams.R_driveline = 0.31;           % (m)

% Axle brake torque per unit line pressure: 2 * pad mu * piston area *
% effective rotor radius, per axle. Only the RATIO of the two matters here, so
% the units are free and leaving both at 1 says "the two axles have the same
% brake hardware". That is an assumption, not a measurement - if the front and
% rear calipers, pads or rotors differ, this is a far bigger lever on the brake
% split than the tire radii below it, so it is worth filling in from the
% hardware if you have the numbers.
vehicleParams.brakeGain_f = 1.0;            % (Nm/kPa, arbitrary matched units)
vehicleParams.brakeGain_r = 1.0;            % (Nm/kPa, arbitrary matched units)

%% load tranfer calcs (bycicle)


L  = vehicleParams.wheelbase;

% a and b are the AXLE LOAD SHARES as lengths, not lf and lr.
%
%   a = w_dist_f * L        -> multiplies m*g/L to give the FRONT static load
%   b = L - a               -> gives the REAR
%
% In the standard bicycle notation, static front load = m*g*lr/L, so
%
%       a is l_r   (CG -> REAR axle)
%       b is l_f   (CG -> FRONT axle)
%
% which is the opposite of what the names suggest. This car is REAR-HEAVY -
% w_dist_f = 0.42, so 42% of the static weight is on the front and the CG sits
% closer to the rear axle. That makes l_r the SHORT one:
%
%       l_r = 0.42 * 2.9718 = 1.2482 m
%       l_f = 0.58 * 2.9718 = 1.7236 m
%
% Checks out against staticCornerLoad_N (front 3358 N of 7995 N = 42%) and
% against P.lf / P.lr in brake_bias_schedule.m, which carries the same geometry
% under the correct names.
a  = vehicleParams.w_dist_f * L;        % = l_r, CG -> rear axle
b  = L - a;                             % = l_f, CG -> front axle
m  = vehicleParams.m;
cgh = vehicleParams.cg_z;

%basic load tranfer 
fz_f_basic = ((a*m*9.81)/(L) - (m*Fax*cgh)/L);
fz_r_basic = ((b*m*9.81)/(L) + (m*Fax*cgh)/L);

front_axle = (Fz_fl_adjusted + Fz_fr_adjusted);
rear_axle = (Fz_rr_adjusted + Fz_rl_adjusted);



% CONSIDER CURVATURE
aero_balance = 0.33;
down_force = 0.5 * 0.58 * 1.225 .* Fvx.^2;

front_aero = aero_balance .* down_force;
rear_aero  = (1 - aero_balance) .* down_force;

L = a + b;   % a + b is the wheelbase either way round - see the note above,
             % where a is l_r and b is l_f, not the other way about.

%% ROAD-NORMAL ACCELERATION - the crest/dip term
%
% az_road is the total normal load per unit mass, so m*az_road is what the four
% tires carry before aero. The balance along the body z axis is
%
%     m*a_z_kinematic = sum(F_z) + m*g_z_body     g_z_body = -g cos(th) cos(ph)
%     sum(F_z) = m*a_z_kinematic + m*g cos(th) cos(ph)
%
% The gravity half was always here. The KINEMATIC half - the vertical
% acceleration from driving over a crest or through a dip - was written as
% Fvx.*Fwy*scalar with scalar = 0.0, so it was deleted, and on a track with real
% elevation change it is the biggest single term in this file: m*Fvx.*Fwy reaches
% p95 2092 N and max 6008 N against 7995 N of static weight. Crests unload all
% four tires, dips load them, and every mu = F_y/F_z downstream inherited the
% error - including through the observer, which anchors its absolute level to
% fz_*_curvature.
%
% WHY NOT JUST SET scalar = 1. Because Fvx.*Fwy OVERSHOOTS the measured vertical
% acceleration badly: corr(a_z, Fvx.*Fwy) is only +0.427, the regression slope is
% 0.553, and the residual has p95 2.88 m/s^2. The reason is physical - pitch RATE
% mixes the road's vertical curvature with SUSPENSION pitch from braking and
% acceleration, and suspension pitch does not unload the tires. A rate-based
% reconstruction cannot tell the two apart.
%
% So the default reads the a_z channel, which is a direct measurement of exactly
% this quantity and is already gravity-compensated (median +0.26 m/s^2, not
% +-9.81 - see the note on Fax/Fay/Faz in the lateral acceleration block).
%
%   "channel"  a_z, smoothed over az_smooth_samples. Preferred.
%   "rates"    the old reconstruction, Fvx.*Fwz.*sin(Froll) + Fvx.*Fwy scaled by
%              az_rateScale. Kept for an A/B against the channel.
%   "none"     flat road, gravity only - reproduces the old scalar = 0 behaviour.
az_source = "channel";

az_rateScale = 0.553;   % only read when az_source == "rates"; the a_z regression slope

% Smoothing window for the a_z channel, in samples. NOT the script-wide mm.
%
% This one is measured, not guessed. Testing the model against the MEASURED
% four-corner gage sum - where the longitudinal transfer cancels exactly, so the
% comparison isolates this term - over the moving samples of this log:
%
%     az_source          RMS error   corr
%     none                  1052 N   +0.688
%     rates, scale 1.0       1018 N   +0.677
%     channel at mm = 30     1121 N   +0.573   <- WORSE than flat road
%     channel at 90          863 N    +0.683   <- best
%     channel at 300         882 N    +0.644
%     channel at 900         903 N    +0.646
%
% At the script's mm = 30 (0.3 s at this log's 100 Hz) the raw channel makes the
% fit WORSE than assuming a flat road, because a_z at the IMU is dominated by
% wheel hop and chassis vibration - its max is 15.9 m/s^2, which is 13 kN of
% apparent load change on a 8 kN car and is plainly not the road. Smoothed to
% 0.9 s it becomes the best estimate available, an 18% RMS improvement on
% flat-road. 0.9 s is about 27 m of track at 30 m/s, which is the length scale a
% real vertical curve actually has; 3 s over-smooths and starts losing it again.
%
% Re-check this if you change logs, sample rate, or mm.
az_smooth_samples = 90;

switch lower(string(az_source))

    case "channel"
        az_kinematic = movmean(data.a_z, az_smooth_samples);
        az_source_label = sprintf("logged a_z, smoothed %d samples", az_smooth_samples);

    case "rates"
        az_kinematic = Fvx .* Fwz .* sin(Froll) + Fvx .* Fwy .* az_rateScale;
        az_source_label = sprintf("rates, scale %.3f", az_rateScale);

    case "none"
        az_kinematic = zeros(size(Fvx));
        az_source_label = "none (flat road)";

    otherwise
        error("notmal_force_estimation:badAzSource", ...
            "az_source must be ""channel"", ""rates"" or ""none"", got ""%s"".", ...
            az_source);
end

az_road = 9.81 .* cos(Fpitch) .* cos(Froll) + az_kinematic;

fprintf("a_z source: %s  (crest/dip term p95 %.0f N, max %.0f N on %.0f N static)\n", ...
    az_source_label, prctile(abs(m .* az_kinematic), 95), ...
    max(abs(m .* az_kinematic)), sum(staticCornerLoad_N));

long_transfer_accel = ...
    Fax + 9.81 .* sin(Fpitch);

fz_f_curvature = ...
    a .* (m .* az_road) ./ L ...
    - (m .* long_transfer_accel .* cgh) ./ L ...
    + front_aero;

fz_r_curvature = ...
    b .* (m .* az_road) ./ L ...
    + (m .* long_transfer_accel .* cgh) ./ L ...
    + rear_aero;

parentAxle = newFigTab(FG, "normal", 'Axle load - measured vs bicycle vs 3D model');
layoutAxle = tiledlayout(parentAxle,3,1);
nexttile(layoutAxle)
plot(t_plot,front_axle)
hold on
plot(t_plot,fz_f_basic)
hold on
plot(t_plot,fz_f_curvature,LineWidth=2)

legend("front measured","front basic calc","front 3D calc")


nexttile(layoutAxle)
plot(t_plot,rear_axle)
hold on
plot(t_plot,fz_r_basic)
hold on
plot(t_plot,fz_r_curvature,LineWidth=2)
legend("rear measured","rear basic calc","rear 3D calc")

nexttile(layoutAxle)
plot(t_plot,Ffz_fr)
hold on
plot(t_plot,Ffz_fl)



%% doal track load tranfer 

% split laterally 


w_dist_f = vehicleParams.w_dist_f;
rc_f = vehicleParams.rc_f;                
rc_r = vehicleParams.rc_r;                 
wheelRate_f = vehicleParams.wheelRate_f;    
wheelRate_r = vehicleParams.wheelRate_r;    
t_f = vehicleParams.t_f;                    
t_r = vehicleParams.t_r;                  
ARB_f = vehicleParams.ARB_f;                


w = m*9.81;                                                      %Vehcile weight (N)
cg2rollAxis = cgh -((1-w_dist_f)*(rc_r-rc_f) + rc_f);
l_a = (1 - w_dist_f) * L;                           
l_b = L - l_a;                                       
k_phi_f = ((wheelRate_f *(t_f^2))/2) + (ARB_f);   
k_phi_r = ((wheelRate_r *(t_r^2))/2) + (0);       
LAT_weightTransferGradient_f = (w/t_f) * ((cg2rollAxis * k_phi_f)/(k_phi_f + k_phi_r) + (l_b * rc_f/L));
LAT_weightTransferGradient_r = (w/t_r) * ((cg2rollAxis * k_phi_r)/(k_phi_f + k_phi_r) + (l_a * rc_r/L));



% figure 
% plot(t_plot,LAT_weightTransferGradient_f*(Fay/9.81),"r")
% hold on
% plot(t_plot,LAT_weightTransferGradient_r*(Fay/9.81),"b")
% legend("front load tranfer in (N)","rear load tranfer N")


% Split each axle by its STATIC CORNER SHARE, not by half. With a symmetric
% staticCornerLoad_N this is identical to the old /2; with corner scales entered
% it carries the cross-weight through to the per-tire loads.
%
% This matters most with the open diff: both rear wheels take equal FORCE, so
% which one lets go first is decided purely by which one carries less load. If
% the model says they are equal and they are not, the per-tire mu panels in
% fig S8 split apart by the cross-weight and the wrong wheel looks like the
% limiting one.
%
% ay_tire, not Fay. Lateral load transfer is driven by the lateral force the
% TIRES make, which is m*ay_tire including the bank term - the same number the
% axle lateral forces are built from further down. Using the raw Fay channel here
% while F_y used ay_tire left the two halves of every mu disagreeing about how
% hard the car was cornering. ay_tire_full is the gap-free copy, so this stays
% finite at low speed and cannot NaN out the observer.
lat_transfer_g = ay_tire_full ./ 9.81;

Fz_fr = fz_f_curvature .* cornerShare_fr + LAT_weightTransferGradient_f * lat_transfer_g;
Fz_fl = fz_f_curvature .* cornerShare_fl - LAT_weightTransferGradient_f * lat_transfer_g;

Fz_rr = fz_r_curvature .* cornerShare_rr + LAT_weightTransferGradient_r * lat_transfer_g;
Fz_rl = fz_r_curvature .* cornerShare_rl - LAT_weightTransferGradient_r * lat_transfer_g;

fprintf("lateral load transfer from ay_tire (was the raw a_y channel): front %.0f N/g, rear %.0f N/g\n", ...
    LAT_weightTransferGradient_f, LAT_weightTransferGradient_r);



parentCorner = newFigTab(FG, "normal", 'Per-corner F_z - measured vs dual-track model');
layoutCorner = tiledlayout(parentCorner,2,2);

axs = gobjects(4,1);

axs(1) = nexttile(layoutCorner);
plot(t_plot, Fz_fl_adjusted);
hold on
plot(t_plot, Fz_fl, 'LineWidth', 2);
legend("Fl measured","Fl est")
title("Front Left")
grid on

axs(2) = nexttile(layoutCorner);
plot(t_plot, Fz_fr_adjusted);
hold on
plot(t_plot, Fz_fr, 'LineWidth', 2);
legend("Fr measured","Fr est")
title("Front Right")
grid on

axs(3) = nexttile(layoutCorner);
plot(t_plot, Fz_rl_adjusted);
hold on
plot(t_plot, Fz_rl, 'LineWidth', 2);
legend("Rl measured","Rl est")
title("Rear Left")
grid on
xlabel("Time [s]")

axs(4) = nexttile(layoutCorner);
plot(t_plot, Fz_rr_adjusted);
hold on
plot(t_plot, Fz_rr, 'LineWidth', 2);
legend("Rr measured","Rr est")
title("Rear Right")
grid on
xlabel("Time [s]")

linkaxes(axs, 'x')






%%
% NOTE this block, not the earlier one, is what the observer consumes - it is
% the last assignment to Fz_* before Fz_model is built. Same static corner
% shares, and the same ay_tire-driven lateral transfer, as above. It is a
% verbatim repeat of that block; if you change one, change both.
Fz_fr = fz_f_curvature .* cornerShare_fr + LAT_weightTransferGradient_f * lat_transfer_g;
Fz_fl = fz_f_curvature .* cornerShare_fl - LAT_weightTransferGradient_f * lat_transfer_g;

Fz_rr = fz_r_curvature .* cornerShare_rr + LAT_weightTransferGradient_r * lat_transfer_g;
Fz_rl = fz_r_curvature .* cornerShare_rl - LAT_weightTransferGradient_r * lat_transfer_g;




%% FOUR-TIRE DERIVATIVE NORMAL-FORCE OBSERVER

Fz_measured = [
    Ffz_fl, ...
    Ffz_fr, ...
    Ffz_rl, ...
    Ffz_rr
];

% Absolute force estimate from the dual-track model
Fz_model = [
    Fz_fl, ...
    Fz_fr, ...
    Fz_rl, ...
    Fz_rr
];

N = length(t);
dt_nominal = median(diff(t), "omitnan");

observer = initDualTrackFzDerivativeObserver();

Fz_observer = zeros(N,4);
Fz_dynamic_correction = zeros(N,4);

dFz_measured_log = zeros(N,4);
dFz_model_log = zeros(N,4);
rate_error_log = zeros(N,4);

for k = 1:N

    if k == 1
        dt_k = dt_nominal;
    else
        dt_k = t(k) - t(k-1);

        if ~isfinite(dt_k) || dt_k <= 0
            dt_k = dt_nominal;
        end
    end

    measurement_k = Fz_measured(k,:);
    model_k = Fz_model(k,:);

    [observer, output] = dualTrackFzDerivativeObserverUpdate( ...
        observer, measurement_k, model_k, dt_k);

    Fz_observer(k,:) = output.Fz_hat;
    Fz_dynamic_correction(k,:) = output.dynamic_correction;

    dFz_measured_log(k,:) = output.dFz_measured;
    dFz_model_log(k,:) = output.dFz_model;
    rate_error_log(k,:) = output.rate_error;
end

% Individual observer outputs
Fz_fl_obs = Fz_observer(:,1);
Fz_fr_obs = Fz_observer(:,2);
Fz_rl_obs = Fz_observer(:,3);
Fz_rr_obs = Fz_observer(:,4);





%% OBSERVER PLOTS

% Align measured signals only for visualization.
% This does not affect the observer.
initial_idx = t <= t(1) + min(2, t(end) - t(1));

plot_offset = median( ...
    Fz_measured(initial_idx,:) - Fz_model(initial_idx,:), ...
    1, ...
    "omitnan");

Fz_measured_aligned = Fz_measured - plot_offset;

tire_names = [
    "Front Left"
    "Front Right"
    "Rear Left"
    "Rear Right"
];

measured_color = [0.90, 0.55, 0.55];  % Light red
observer_color = [0.10, 0.45, 0.70];  % Deep blue
model_color    = [0.60, 0.35, 0.75];  % Purple
% Per-tire colors
tire_colors = [
    0.12, 0.29, 0.49   % FL - navy
    0.67, 0.23, 0.30   % FR - muted red
    0.16, 0.47, 0.39   % RL - teal
    0.55, 0.42, 0.67   % RR - muted purple
];

%% Measured, observer, and model comparison

parentObs = newFigTab(FG, "normal", 'Normal Force Observer Comparison');

layout = tiledlayout(parentObs, 2, 2, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

title(layout, "Normal Force Observer Comparison", ...
    "FontWeight", "bold");

observer_axes = gobjects(4,1);

for tire = 1:4

    observer_axes(tire) = nexttile(layout);
    hold on

    plot(t_plot, Fz_measured_aligned(:,tire), ...
        "Color", measured_color, ...
        "LineStyle", "-", ...
        "LineWidth", 1.4);


    plot(t_plot, Fz_model(:,tire), ...
        "Color", model_color, ...
        "LineWidth", 1.7);

    plot(t_plot, Fz_observer(:,tire), ...
        "Color", observer_color, ...
        "LineStyle", "-", ...
        "LineWidth", 2.0);

    hold off
    grid on
    box on

    title(tire_names(tire), "FontWeight", "bold");
    xlabel("Time [s]");
    ylabel("Normal force [N]");

    set(gca, ...
        "FontSize", 11, ...
        "LineWidth", 0.8, ...
        "GridAlpha", 0.20, ...
        "MinorGridAlpha", 0.10);

    if tire == 1
        legend( ...
            "Aligned strain gauge", ...
            "Dual-track model", ...
            "Dual-track observer", ...
            "Location", "best");
    end
end

linkaxes(observer_axes, "x");


%% Observer correction and rate error

parentObsDiag = newFigTab(FG, "normal", 'Observer Correction Diagnostics');

layout = tiledlayout(parentObsDiag, 2, 1, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

title(layout, "Observer Correction Diagnostics", ...
    "FontWeight", "bold");

ax1 = nexttile(layout);
set(ax1, "ColorOrder", tire_colors, "NextPlot", "replacechildren");

plot(t_plot, Fz_dynamic_correction, "LineWidth", 1.6);
yline(0, "--", "Color", [0.35, 0.35, 0.35], ...
    "HandleVisibility", "off");

grid on
box on
ylabel("Correction [N]");
title("Per-Tire Dynamic Observer Correction");
legend("FL", "FR", "RL", "RR", ...
    "Location", "best", ...
    "NumColumns", 4);

set(ax1, ...
    "FontSize", 11, ...
    "LineWidth", 0.8, ...
    "GridAlpha", 0.20);


ax2 = nexttile(layout);
set(ax2, "ColorOrder", tire_colors, "NextPlot", "replacechildren");

plot(t_plot, rate_error_log, "LineWidth", 1.6);
yline(0, "--", "Color", [0.35, 0.35, 0.35], ...
    "HandleVisibility", "off");

grid on
box on
xlabel("Time [s]");
ylabel("Rate error [N/s]");
title("Measured Rate Minus Modeled Rate");
legend("FL", "FR", "RL", "RR", ...
    "Location", "best", ...
    "NumColumns", 4);

set(ax2, ...
    "FontSize", 11, ...
    "LineWidth", 0.8, ...
    "GridAlpha", 0.20);

linkaxes([ax1, ax2], "x");




%% slip / force params
vx_min_slip_angle     = 4;        
vx_min_slip_ratio     = 4;    
vx_max_slip_ratio     = Inf;      
alpha_max_deg         = 20;       
slip_ratio_max        = 100;     
brakePressureMin_kPa  = 75;       
defaultFrontBrakeBias = 0.53;    
maxFrontBrakeBias     = 0.8;   
minFrontBrakeBias     = 0.2;     
Fx_deadband_N         = 50;       
CdA_drag              = 1.33; %1.33;     
rho                   = 1.225;   
g                     = 9.81;    
Iz                    = vehicleParams.inertia;

% useBankCorrection now lives with the lateral acceleration it controls, up in
% the LATERAL ACCELERATION AT THE TIRES block, because the load transfer consumes
% ay_tire and runs long before this point.
plot_per_tire     = true;
use_observed_Fz   = true;
slip_ratio_def = "wheel"; % or wheel
fx_split_mode = "even";

% Per-tire lateral force split, same two modes as fx_split_mode.
%
%   "even"  axle/2, what this script always did
%   "load"  in proportion to each tire's normal force
%
% "load" is the default because "even" is at its worst exactly where the lateral
% forces are largest. The front lateral transfer gradient below works out to
% 1032 N/g on a 1679 N static front corner, so at 1 g the front tires carry
% 2711 N and 647 N - a 4:1 ratio - while an even split hands them identical
% lateral force. That puts the inside tire's mu about 4x the outside tire's in
% figs S7/S8, as a pure artifact of the split.
%
% WHY THIS DIFFERS FROM fx_split_mode, deliberately. Leaving F_x on "even" while
% F_y goes "load" is not an inconsistency - the hardware constrains the two
% differently:
%
%   F_x  the open diff forces both rear wheels to take equal FORCE whatever their
%        loads, and both front calipers see the same line pressure, so equal
%        torque and equal force - until a wheel locks. "even" IS the physical
%        constraint, which is why it is the default there.
%   F_y  nothing couples the two sides laterally. Lateral force follows load, so
%        "load" is the physical answer.
%
% Set "even" to reproduce the old per-tire figures.
fy_split_mode = "load";

% Resolve the front axle lateral force into the TIRE frame rather than the
% vehicle frame. See the per-tire lateral force section for the algebra.
use_tire_frame_front = true;

% Engine braking is a 100%-REAR force. See the F_x split section below for what
% this changes and why it is not simply "adding a missing force". Set false to
% recover the old pressure-only split exactly, for an A/B.
include_engine_braking = true;

% Where the engine brake torque comes from.
%
%   "map"             interpolate an engine map on (rpm, throttle). Preferred:
%                     it is a physical model rather than an estimator output,
%                     and it extrapolates to runs the estimator was not tuned
%                     for.
%   "torque_channel"  est_drive_torque_nm as logged.
%
% WHICH MAP. engine_map_boosted_reduced.csv is 3.2x too steep in engine
% braking. Its zero-throttle column is the straight line -0.033*(rpm-500),
% which reaches -137 Nm at 4650 rpm - 26% of the 526 Nm peak, where a boosted
% engine motors at 8-15%. Using it makes the calipers produce +1775 N with the
% pedal up (see the zero-pressure test below), which is impossible.
% engine_map_newEnginebrake.csv is -0.0097*rpm, lands at -45 Nm, and leaves a
% +78 N intercept. That is the one to use. Note it has NO header row, so the
% throttle breakpoints are supplied here instead.
engine_brake_source = "map";

engineMapFile = "/home/elijah/code/CodeFiles/Research/VD/data_analisis/putnam_coast_down/engine_map_newEnginebrake.csv";

% Throttle fraction each column of the map stands for. Only read when the file
% has no header row.
engineMap_throttleBreaks = [0, 0.3, 1.0];

% Trim on the map's engine-brake torque. Solving "calipers make zero force at
% zero line pressure" over this log wants 0.91 for newEnginebrake and 0.31 for
% boosted_reduced - both landing on about -41 Nm at 4650 rpm. Left at 1.0
% because 0.91 is inside the noise of that fit; set it if you re-run the
% zero-pressure check on your own data.
engineMap_scale = 1.0;

% Throttle fraction at or below which the engine is treated as fully closed.
%
% These maps jump straight from a 0.0 column to a 0.3 column, so they have NO
% resolution in between, and a linear interpolation across that gap is
% meaningless: at 4650 rpm it reads a 2% pedal opening as 7% of the way from
% -45 Nm to +58 Nm, quietly deleting 15% of the engine braking. The throttle
% channel makes that worse - it floors at 3.2% and sits at 5.2% (a fraction of
% 0.021) all the way through hard braking, which is the throttle body's idle
% position, not the driver asking for torque.
%
% So below this fraction the zero-throttle column is used as-is. 0.05 clears
% the 0.021 median and the 0.027 p95 seen under braking while still letting a
% genuine trail-brake application (p99 is 0.36) interpolate normally.
engineMap_closedThrottleFrac = 0.05;

% Lateral-acceleration ceiling for a sample to count as "pure longitudinal" in
% figs S3, S4, S7 and S8.
%
% This was 30.0 m/s^2, which is 3.06 g. Peak |a_y| on this recording is 1.68 g,
% so the gate never excluded a single sample and those figures were showing
% fully-cornering data as though it were pure braking and traction. 3.0 m/s^2 is
% about 0.3 g, small enough that the lateral demand is a few percent of the
% friction circle. The keep-count is printed below - if it drops too low to plot,
% raise this rather than switching it off, because a disabled gate is what
% produced the old curves.
ay_max_pure_long = 3.0;   % m/s^2

biasMap_pressureMin_kPa = 400;
biasMap_climTail        = 0.01;
biasMap_greyColor       = [0.72, 0.72, 0.72];


kappaMap_negLimit   = -0.08;                  % kappa that reaches the deep red end
kappaMap_posLimit   =  0.005;                 % top of the ramp; above this is flat
kappaMap_colorGamma =  1.00;                  % < 1 packs the cool hues into small slip
kappaMap_tickStep   =  0.02;                  % colorbar tick spacing
kappaMap_posColor   = [0.720, 0.720, 0.720];  % flat grey past posLimit

% CG to each axle, for the bicycle model below.
%
% WAS "lf = a; lr = b", which had them the wrong way round. a is the FRONT LOAD
% SHARE as a length, which in bicycle notation is l_r, not l_f - see the note
% where a and b are defined. The car is rear-heavy, so l_r is the SHORT one
% (1.248 m) and l_f the long one (1.724 m); the old assignment gave the CG a
% front-heavy position this car does not have.
%
% What it cost, since these feed the F_y calc directly:
%
%   Fyf = m*ay*l_r/L   should be 0.420*m*ay, was 0.580*m*ay   (+38%)
%   Fyr = m*ay*l_f/L   should be 0.580*m*ay, was 0.420*m*ay   (-28%)
%
% At 1.5 g that is 5037 N on the front axle against 6956 N as it was computed.
% It also shifted both slip angles, through vy_front / vy_rear below, so it
% moved BOTH axes of figs S1, S2 and S13.
%
% The tell that this was a slip rather than a convention: the lateral load
% transfer block above already gets it right, building l_a = (1-w_dist_f)*L and
% pairing l_b with rc_f and l_a with rc_r. The file was internally inconsistent -
% geometric jacking correct, bicycle model inverted.
%
% brake_bias_schedule.m has the same geometry under the correct names
% (P.lf = 1.723644, P.lr = 1.248156) and needs no change.
lf = b;   % CG -> front axle, 1.7236 m
lr = a;   % CG -> rear  axle, 1.2482 m

fprintf("bicycle geometry: l_f %.4f m, l_r %.4f m, front static share %.1f%% (rear-heavy)\n", ...
    lf, lr, 100 * lr / L);

%% yaw acceleration
dt_series = ay_dt;      % same guarded gradient(t) built with the lateral accel
rdot = movmean(gradient(Fwz) ./ dt_series, mm);

%% lateral acceleration at the tires
% ay_tire is built in the LATERAL ACCELERATION AT THE TIRES block near the top,
% before the load transfer, so that the F_z model and the F_y model below are
% driven by the same number. Nothing to compute here.

%% slip angles (bicycle, per axle)
vx_safe_angle = Fvx;
vx_safe_angle(abs(vx_safe_angle) < vx_min_slip_angle) = NaN;

vy_front = Fvy + lf .* Fwz;
vy_rear  = Fvy - lr .* Fwz;

alpha_f = toe_rad - atan2(vy_front, vx_safe_angle);
alpha_r =         - atan2(vy_rear,  vx_safe_angle);

alpha_f_deg = rad2deg(alpha_f);
alpha_r_deg = rad2deg(alpha_r);

%% axle lateral forces (yaw moment balance)
Fyf = (m .* lr .* ay_tire + Iz .* rdot) ./ L;
Fyr = (m .* lf .* ay_tire - Iz .* rdot) ./ L;

%% total longitudinal force (force balance along the vehicle x axis)
Fdrag    = 0.5 .* rho .* CdA_drag .* Fvx .* abs(Fvx);
Fgrade   = m .* g .* sin(Fpitch);
% The steered-front coupling term is still zeroed here, but deliberately and not
% for the old reason. Its partner - rotating Fyf into the tire frame - is now
% applied further down, after the F_x split. Enabling BOTH makes the system
% circular: Fx_total would need Fy_tire_f, which needs Fxf, which comes from
% Fx_total. It is solvable in one or two fixed-point passes, and worth doing if
% you want the front friction circle exact in combined braking-and-cornering,
% where this term is a few hundred newtons. Until then the rotation is applied on
% the F_y side only, which is where it matters for reading the tire curve.
%
% Fgrade is correct as written despite Fax being a kinematic channel: gravity is
% absent from Fax, so it has to be added back to get a TIRE force. Verified -
% Fax - (dv_x/dt - r*v_y) has p95 0.68 m/s^2 and zero correlation against
% g*sin(pitch), so the channel carries no grade component of its own.
Fx_total = m .* Fax + Fdrag + Fgrade + Fyf .* sin(toe_rad)*0;

%% Fx split front / rear by measured brake bias
% biasF is a FORCE bias - the share of the braking force at the contact patch
% that the front axle makes - because that is what Fx_total has to be split by.
% Line pressure does not give that directly. The chain is
%
%   pressure -> axle brake torque -> longitudinal force at the ground
%   T_axle = brakeGain * P            Fx_axle = T_axle / R_tire
%
% so the front share is (gain_f*Pf/R_f) / (gain_f*Pf/R_f + gain_r*Pr/R_r).
% Splitting on Pf/(Pf+Pr) is that expression with gain_f = gain_r AND
% R_f = R_r: it assumes matched brake hardware and equal tire radii. The radii
% are not equal here (0.30 front, 0.31 rear), so a given torque makes about
% 3.3% more force at the front than the naive split credits it with.
%
% Setting R_f = R_r and leaving both gains at 1 recovers the old pressure-ratio
% behaviour exactly, so this is the switch for comparing the two.
%
% Note this is the torque-to-force conversion only. It says nothing about
% whether an axle can USE that force - a locked wheel makes what friction
% allows, not what the caliper commands - so these shares are the demand, not a
% measurement of what the tires did.

Pf = Fbrake;                                       % front brake pressure [kPa]
Pr = movmean(data.rear_brake_pressure_kpa, mm);    % rear brake pressure  [kPa]

brakePressureTotal = Pf + Pr;
hasBrakePressure   = brakePressureTotal > brakePressureMin_kPa;

R_f = vehicleParams.R_f;
R_r = vehicleParams.R_r;

brakeForce_f = vehicleParams.brakeGain_f .* Pf ./ R_f;   % front force demand
brakeForce_r = vehicleParams.brakeGain_r .* Pr ./ R_r;   % rear force demand

brakeForceTotal = brakeForce_f + brakeForce_r;

biasF = defaultFrontBrakeBias .* ones(size(Fx_total));
biasF(hasBrakePressure) = brakeForce_f(hasBrakePressure) ...
                       ./ brakeForceTotal(hasBrakePressure);
biasF = max(0, min(1, biasF));

% Pressure ratio kept alongside, so fig S0 can show what the radii moved and so
% the bias map below has the raw hardware quantity to draw.
biasF_pressure = defaultFrontBrakeBias .* ones(size(Fx_total));
biasF_pressure(hasBrakePressure) = Pf(hasBrakePressure) ...
                                ./ brakePressureTotal(hasBrakePressure);
biasF_pressure = max(0, min(1, biasF_pressure));

fprintf("brake split: R_f %.3f m, R_r %.3f m, gain ratio f/r %.3f -> front force bias is %+.4f vs the pressure ratio (median over braking samples)\n", ...
    R_f, R_r, vehicleParams.brakeGain_f / vehicleParams.brakeGain_r, ...
    median(biasF(hasBrakePressure) - biasF_pressure(hasBrakePressure)));


biasTooHigh = hasBrakePressure & biasF > maxFrontBrakeBias;
biasTooLow  = hasBrakePressure & biasF < minFrontBrakeBias;
biasValid   = ~(biasTooHigh | biasTooLow);

fprintf("brake bias outside [%.2f %.2f] rejected on %d of %d samples (%.1f%%): %d high, %d low\n", ...
    minFrontBrakeBias, maxFrontBrakeBias, sum(~biasValid), numel(biasValid), ...
    100 * sum(~biasValid) / numel(biasValid), sum(biasTooHigh), sum(biasTooLow));

driveMode = Fx_total >  Fx_deadband_N;
brakeMode = Fx_total < -Fx_deadband_N;

% Engine braking, and why this is a SPLIT fix rather than a missing force.
%
% Fx_total comes from measured deceleration, so the driveline drag is already
% inside it - nothing is missing from the total, and adding F_engine on top of
% Fx_total would double-count it and break the force balance.
%
% The error is that biasF is a brake PRESSURE ratio, so the old two lines below
% divided the whole of Fx_total 53/47 as though every newton of it came out of
% a caliper. Engine braking comes out of the driveline and is 100% rear, so the
% front was being credited with biasF of it. The under-count on the rear is
%
%     biasF * F_engine
%
% and NOT the whole of F_engine. Only the caliper share deserves the pressure
% split:
%
%     F_caliper = Fx_total - F_engine        split by biasF
%     F_engine  = T_drive / R_driveline      all of it to the rear
%
% On this log that is worth +16% to the rear mu at a_x = -5, +11% at -7 and
% +7% at -9 - the largest single asymmetry between the accel and braking
% branches, though not the whole of it. Note it fades as the braking gets
% harder, because the caliper force grows while the engine torque does not.

% Engine torque -> force at the rear contact patch, by POWER BALANCE:
%
%     T_engine * omega_engine  =  F_contact * v_wheel_surface
%     F = T_engine * omega_engine / Vw_rear
%
% This needs no gear ratio, no final drive and no tire radius - the measured
% rpm and the measured wheel speed already carry all of it, and it stays right
% through a shift. (For reference the ratios implied by this log are 8.70,
% 5.59 and 4.12 for gears 1-3.) It also handles rear wheel slip correctly,
% which is why it uses the wheel speed channel and not Fvx: the driveline is
% tied to the wheel, not to the road.
%
% Lossless is assumed. Driveline friction during engine braking acts with the
% engine, so this slightly UNDER-states the rear force - conservative here.

if include_engine_braking

    switch lower(string(engine_brake_source))

        case "torque_channel"
            % est_drive_torque_nm is already an axle torque on this log, so it
            % only needs the loaded radius.
            Fx_engine = FT_e ./ vehicleParams.R_driveline;
            engine_brake_label = "est\_drive\_torque\_nm";

        case "map"
            % Rear wheel surface speed. Deliberately a clean /3.6 rather than
            % the /3.61 - 0.1 used in the slip-ratio section further down: that
            % fudge belongs to slip ratio, and letting it into a power balance
            % would put a false offset on the engine force at every speed.
            Vw_rear_eng = 0.5 .* (movmean(data.rl_speed_kmh, mm) ...
                                + movmean(data.rr_speed_kmh, mm)) ./ 3.6;

            % throttle_pct does not read 0 with the pedal up - it floors near
            % 3% on this log. Feeding the raw percentage into the map
            % interpolates ~10% toward the 0.3 column and throws away about a
            % quarter of the engine braking, so the closed reading is measured
            % off the data and removed.
            throttle_closed_pct = prctile(throttle, 1);
            throttle_frac = max(0, (throttle - throttle_closed_pct) ...
                                 ./ max(100 - throttle_closed_pct, eps));

            % Snap idle-position throttle onto the motoring column rather than
            % interpolating across the map's unresolved 0-to-0.3 gap. See
            % engineMap_closedThrottleFrac above.
            closedThrottle = throttle_frac <= engineMap_closedThrottleFrac;
            throttle_frac(closedThrottle) = 0;

            T_engine = engineMap_scale .* lookupEngineTorque( ...
                engineMapFile, engineMap_throttleBreaks, Frpm, throttle_frac);

            % Below a few m/s the power balance divides by a vanishing wheel
            % speed. Those samples are far outside every mask in this script.
            Vw_safe = Vw_rear_eng;
            Vw_safe(abs(Vw_safe) < 2) = NaN;

            Fx_engine = T_engine .* (Frpm .* 2*pi/60) ./ Vw_safe;
            Fx_engine(~isfinite(Fx_engine)) = 0;

            engine_brake_label = "map: " + string(engineMapFile);

            fprintf("engine map: %s\n", engineMapFile);
            fprintf("  throttle closed reading %.2f%% removed before lookup; %.1f%% of samples snapped to the motoring column\n", ...
                throttle_closed_pct, 100*mean(closedThrottle));

        otherwise
            error("notmal_force_estimation:badEngineBrakeSource", ...
                "engine_brake_source must be ""map"" or ""torque_channel"", got ""%s"".", ...
                engine_brake_source);
    end
else
    Fx_engine = zeros(size(Fx_total));
    engine_brake_label = "none";
end

Fx_caliper = Fx_total - Fx_engine;

% A caliper can only ever oppose motion. Where the torque estimate is large
% enough to imply a forward caliper force, trust the measured total instead and
% hand the whole of it to the driveline, so the two shares always sum back to
% Fx_total whatever R_driveline is set to.
engineOvershoot = brakeMode & Fx_caliper > 0;

Fx_caliper(engineOvershoot) = 0;
Fx_engine(engineOvershoot)  = Fx_total(engineOvershoot);

Fxf = zeros(size(Fx_total));
Fxr = zeros(size(Fx_total));

% Drive: rear wheel drive, so all of the tractive force sits on the rear axle.
% The engine term needs no special handling here - it is already all rear.
Fxr(driveMode) = Fx_total(driveMode);

% Brake: pressure split on the caliper share only, driveline share all rear.
Fxf(brakeMode) = biasF(brakeMode)       .* Fx_caliper(brakeMode);
Fxr(brakeMode) = (1 - biasF(brakeMode)) .* Fx_caliper(brakeMode) ...
               + Fx_engine(brakeMode);

if include_engine_braking

    fprintf("engine braking: source %s, %d braking samples, %d clamped by the caliper-sign guard\n", ...
        engine_brake_label, sum(brakeMode), sum(engineOvershoot));

    hardBrake = brakeMode & Fax < -4 & isfinite(Fx_engine);

    if any(hardBrake)
        rear_old = (1 - biasF(hardBrake)) .* Fx_total(hardBrake);
        rear_new = Fxr(hardBrake);

        fprintf("  a_x < -4: median F_engine %+.0f N, rear F_x %+.0f -> %+.0f N (%+.1f%% on rear mu)\n", ...
            median(Fx_engine(hardBrake)), median(rear_old), median(rear_new), ...
            100 * (median(rear_new) / median(rear_old) - 1));
    end

    % Sanity: the two shares must add back up to the total everywhere.
    splitErr = max(abs(Fxf(brakeMode) + Fxr(brakeMode) - Fx_total(brakeMode)));

    fprintf("  force balance check: max |Fxf + Fxr - Fx_total| over braking samples = %.3g N\n", splitErr);

    % ZERO-PRESSURE TEST - the thing that tells you whether the engine brake
    % model is the right SIZE, independent of everything else in the script.
    %
    % Regress the caliper share against line pressure over the braking samples.
    % With the pedal up the calipers make nothing, so the fit must pass through
    % the origin. Too large an engine brake leaves a POSITIVE intercept, which
    % says the calipers are pushing the car forward at zero pressure - not a
    % thing that happens. Too small leaves a negative one, which is the error
    % the old pressure-only split had.
    %
    % On this log: boosted_reduced +1775 N (3.2x too steep), newEnginebrake
    % +78 N, est_drive_torque_nm -196 N, no engine brake at all -781 N.

    presFloor = prctile(brakePressureTotal, 1);
    zpValid   = brakeMode & isfinite(Fx_caliper) & isfinite(brakePressureTotal);

    if sum(zpValid) > 100

        Xzp  = [brakePressureTotal(zpValid) - presFloor, ones(sum(zpValid),1)];
        czp  = Xzp \ Fx_caliper(zpValid);

        fprintf("  zero-pressure test: caliper force = %.3f*P %+.0f N -> intercept %+.0f N", ...
            czp(1), czp(2), czp(2));

        if abs(czp(2)) < 250
            fprintf("   (OK)\n");
        elseif czp(2) > 0
            fprintf("   (engine brake TOO LARGE - calipers would push forward)\n");
        else
            fprintf("   (engine brake TOO SMALL)\n");
        end
    end
end



%% per-tire lateral forces
% MOVED. The per-tire split needs Fz_*_norm to weight by load, and Fxf to rotate
% the front axle into the tire frame, and neither exists yet at this point in the
% script. It now sits with the per-tire LONGITUDINAL split, after both.

%% wheel speeds and tire-frame velocities

% Per-wheel scale from the free-rolling calibration at the top of the script,
% replacing the old common  ./3.61 - 0.1. See that section for why one shared
% factor cannot serve two different tire sizes.
Vw_fl = movmean(data.fl_speed_kmh, mm) ./ 3.6 ./ wheelSpeedCal(1);
Vw_fr = movmean(data.fr_speed_kmh, mm) ./ 3.6 ./ wheelSpeedCal(2);
Vw_rl = movmean(data.rl_speed_kmh, mm) ./ 3.6 ./ wheelSpeedCal(3);
Vw_rr = movmean(data.rr_speed_kmh, mm) ./ 3.6 ./ wheelSpeedCal(4);

% Residual free-rolling slip inside the analysed window. Every one of these
% should print as ~0; a number here is a standing bias on that wheel's slip
% ratio in figs S7/S8 and in the exported CSVs.
calCheck = abs(Fay) < wheelCal_ayMax & abs(steering_wheel) < wheelCal_steerMax ...
         & abs(Fax) < wheelCal_axMax & Fbrake < wheelCal_brakeMax_kPa ...
         & Fvx > wheelCal_vxMin;

if any(calCheck)

    fprintf("wheel speed check inside the window (%d free-rolling samples):", sum(calCheck));

    vwList = {Vw_fl, Vw_fr, Vw_rl, Vw_rr};

    for iWheel = 1:4
        vw = vwList{iWheel};
        fprintf("  %s %+.5f", wheelSpeed_names(iWheel), ...
            mean((vw(calCheck) - Fvx(calCheck)) ./ vw(calCheck), "omitnan"));
    end

    fprintf("   (all should be ~0)\n");
else
    fprintf("wheel speed check: no free-rolling samples inside this time_segment, cannot verify\n");
end

Vw_front = 0.5 .* (Vw_fl + Vw_fr);
Vw_rear  = 0.5 .* (Vw_rl + Vw_rr);

ft = vehicleParams.t_f;
rt = vehicleParams.t_r;

Vx_fl_c = Fvx - Fwz .* (ft/2);
Vx_fr_c = Fvx + Fwz .* (ft/2);
Vx_rl_c = Fvx - Fwz .* (rt/2);
Vx_rr_c = Fvx + Fwz .* (rt/2);

Vy_front_c = Fvy + Fwz .* lf;
Vy_rear_c  = Fvy - Fwz .* lr;

% Front corners are rotated into the steered tire frame.
Vx_tire_fl =  Vx_fl_c .* cos(toe_rad) + Vy_front_c .* sin(toe_rad);
Vx_tire_fr =  Vx_fr_c .* cos(toe_rad) + Vy_front_c .* sin(toe_rad);
Vx_tire_rl =  Vx_rl_c;
Vx_tire_rr =  Vx_rr_c;

Vy_tire_fl = -Vx_fl_c .* sin(toe_rad) + Vy_front_c .* cos(toe_rad);
Vy_tire_fr = -Vx_fr_c .* sin(toe_rad) + Vy_front_c .* cos(toe_rad);
Vy_tire_rl =  Vy_rear_c;
Vy_tire_rr =  Vy_rear_c;

lowSpeedMask = abs(Fvx) < vx_min_slip_ratio;
Vx_tire_fl(lowSpeedMask) = 0;  Vy_tire_fl(lowSpeedMask) = 0;
Vx_tire_fr(lowSpeedMask) = 0;  Vy_tire_fr(lowSpeedMask) = 0;
Vx_tire_rl(lowSpeedMask) = 0;  Vy_tire_rl(lowSpeedMask) = 0;
Vx_tire_rr(lowSpeedMask) = 0;  Vy_tire_rr(lowSpeedMask) = 0;

%% slip ratios


switch lower(string(slip_ratio_def))

    case "wheel"
        slipRef_fl = Vw_fl;
        slipRef_fr = Vw_fr;
        slipRef_rl = Vw_rl;
        slipRef_rr = Vw_rr;
        slipRef_f  = Vw_front;
        slipRef_r  = Vw_rear;

        slip_ratio_label = "\kappa = (V_w - V_x) / V_w";

    case "sae"
        slipRef_fl = abs(Vx_tire_fl);
        slipRef_fr = abs(Vx_tire_fr);
        slipRef_rl = abs(Vx_tire_rl);
        slipRef_rr = abs(Vx_tire_rr);
        slipRef_f  = abs(Fvx);
        slipRef_r  = abs(Fvx);

        slip_ratio_label = "\kappa = (V_w - V_x) / |V_x|";

    otherwise
        error("notmal_force_estimation:badSlipRatioDef", ...
            "slip_ratio_def must be ""wheel"" or ""sae"", got ""%s"".", ...
            slip_ratio_def);
end

fprintf("slip ratio definition: %s\n", slip_ratio_def);

slip_ratio_x_fl = (Vw_fl - Vx_tire_fl) ./ slipRef_fl;
slip_ratio_x_fr = (Vw_fr - Vx_tire_fr) ./ slipRef_fr;
slip_ratio_x_rl = (Vw_rl - Vx_tire_rl) ./ slipRef_rl;
slip_ratio_x_rr = (Vw_rr - Vx_tire_rr) ./ slipRef_rr;

slip_ratio_f = (Vw_front - Fvx) ./ slipRef_f;
slip_ratio_r = (Vw_rear  - Fvx) ./ slipRef_r;

%% normal forces used for normalization
if use_observed_Fz
    Fz_fl_norm = Fz_fl_obs;
    Fz_fr_norm = Fz_fr_obs;
    Fz_rl_norm = Fz_rl_obs;
    Fz_rr_norm = Fz_rr_obs;
    Fz_label   = "observed F_z";
else
    Fz_fl_norm = Fz_fl_adjusted;
    Fz_fr_norm = Fz_fr_adjusted;
    Fz_rl_norm = Fz_rl_adjusted;
    Fz_rr_norm = Fz_rr_adjusted;
    Fz_label   = "strain gage F_z";
end

Fz_front_norm = Fz_fl_norm + Fz_fr_norm;
Fz_rear_norm  = Fz_rl_norm + Fz_rr_norm;

%% per-tire longitudinal forces


switch lower(string(fx_split_mode))

    case "even"
        fx_fl = Fxf ./ 2;   fx_fr = Fxf ./ 2;
        fx_rl = Fxr ./ 2;   fx_rr = Fxr ./ 2;

        fx_split_label = "axle/2";

    case "load"
        % Start from the even split so that an axle carrying no measured load
        % falls back to it instead of producing NaN.
        fx_fl = Fxf ./ 2;   fx_fr = Fxf ./ 2;
        fx_rl = Fxr ./ 2;   fx_rr = Fxr ./ 2;

        shareF = Fz_front_norm > 0 & Fz_fl_norm >= 0 & Fz_fr_norm >= 0;
        shareR = Fz_rear_norm  > 0 & Fz_rl_norm >= 0 & Fz_rr_norm >= 0;

        fx_fl(shareF) = Fxf(shareF) .* Fz_fl_norm(shareF) ./ Fz_front_norm(shareF);
        fx_fr(shareF) = Fxf(shareF) .* Fz_fr_norm(shareF) ./ Fz_front_norm(shareF);
        fx_rl(shareR) = Fxr(shareR) .* Fz_rl_norm(shareR) ./ Fz_rear_norm(shareR);
        fx_rr(shareR) = Fxr(shareR) .* Fz_rr_norm(shareR) ./ Fz_rear_norm(shareR);

        fx_split_label = "load-weighted";

        fprintf("per-tire Fx split: load-weighted on %d of %d front and %d of %d rear samples (rest fell back to axle/2)\n", ...
            sum(shareF), numel(shareF), sum(shareR), numel(shareR));

    otherwise
        error("notmal_force_estimation:badFxSplitMode", ...
            "fx_split_mode must be ""even"" or ""load"", got ""%s"".", ...
            fx_split_mode);
end

fprintf("per-tire Fx split: %s\n", fx_split_label);

%% front axle lateral force in the TIRE frame
%
% Fyf out of the yaw moment balance is the front axle's contribution along the
% VEHICLE y axis. The tire makes its lateral force perpendicular to ITSELF, and
% its longitudinal force along itself, so at road wheel angle delta
%
%     Fy_vehicle = Fy_tire*cos(delta) + Fx_tire*sin(delta)
%
% and solving the bicycle balance actually gives that whole combination, not
% Fy_tire alone. Inverting:
%
%     Fy_tire = (Fyf - Fxf*sin(delta)) / cos(delta)
%
% Size on this log: p95 delta is 5.2 deg and max 11.8 deg, so sin(delta) reaches
% 0.20, and with Fxf in the kN under braking this is 200-600 N on the front axle
% in combined braking and cornering. It is also the missing half of a pair - line
% "Fx_total = ... + Fyf.*sin(toe_rad)*0" zeroed the reciprocal coupling with the
% comment "not adding in lat contribution". Both halves belong in together, or
% the friction circles in figs S5/S6 are plotting two different frames on one set
% of axes.
%
% The rear axle is unsteered, so Fyr is already in the tire frame.
if use_tire_frame_front

    Fyf_vehicle = Fyf;
    Fyf = (Fyf_vehicle - Fxf .* sin(toe_rad)) ./ cos(toe_rad);

    frameShift = isfinite(Fyf) & isfinite(Fyf_vehicle);

    fprintf("front F_y rotated into the tire frame: median |change| %.0f N, p95 %.0f N, max %.0f N\n", ...
        median(abs(Fyf(frameShift) - Fyf_vehicle(frameShift))), ...
        prctile(abs(Fyf(frameShift) - Fyf_vehicle(frameShift)), 95), ...
        max(abs(Fyf(frameShift) - Fyf_vehicle(frameShift))));
else
    Fyf_vehicle = Fyf;
    fprintf("front F_y left in the vehicle frame (use_tire_frame_front = false)\n");
end

%% per-tire lateral forces
% Same two modes as the F_x split above, and the same reason for preferring
% "load": see fy_split_mode where it is set.

switch lower(string(fy_split_mode))

    case "even"
        Fy_fl = Fyf ./ 2;   Fy_fr = Fyf ./ 2;
        Fy_rl = Fyr ./ 2;   Fy_rr = Fyr ./ 2;

        fy_split_label = "axle/2";

    case "load"
        % Fall back to the even split wherever the measured load cannot weight
        % it, so an axle with no valid F_z gives the old answer instead of NaN.
        Fy_fl = Fyf ./ 2;   Fy_fr = Fyf ./ 2;
        Fy_rl = Fyr ./ 2;   Fy_rr = Fyr ./ 2;

        shareF_y = Fz_front_norm > 0 & Fz_fl_norm >= 0 & Fz_fr_norm >= 0;
        shareR_y = Fz_rear_norm  > 0 & Fz_rl_norm >= 0 & Fz_rr_norm >= 0;

        Fy_fl(shareF_y) = Fyf(shareF_y) .* Fz_fl_norm(shareF_y) ./ Fz_front_norm(shareF_y);
        Fy_fr(shareF_y) = Fyf(shareF_y) .* Fz_fr_norm(shareF_y) ./ Fz_front_norm(shareF_y);
        Fy_rl(shareR_y) = Fyr(shareR_y) .* Fz_rl_norm(shareR_y) ./ Fz_rear_norm(shareR_y);
        Fy_rr(shareR_y) = Fyr(shareR_y) .* Fz_rr_norm(shareR_y) ./ Fz_rear_norm(shareR_y);

        fy_split_label = "load-weighted";

        fprintf("per-tire Fy split: load-weighted on %d of %d front and %d of %d rear samples (rest fell back to axle/2)\n", ...
            sum(shareF_y), numel(shareF_y), sum(shareR_y), numel(shareR_y));

    otherwise
        error("notmal_force_estimation:badFySplitMode", ...
            "fy_split_mode must be ""even"" or ""load"", got ""%s"".", ...
            fy_split_mode);
end

fprintf("per-tire Fy split: %s\n", fy_split_label);

%% validity masks

speedValid = abs(Fvx) > vx_min_slip_angle & abs(Fvx) < vx_max_slip_ratio;

fprintf("speed window [%.3g %.3g] m/s keeps %d of %d samples (%.1f%%)\n", ...
    vx_min_slip_angle, vx_max_slip_ratio, sum(speedValid), numel(speedValid), ...
    100 * sum(speedValid) / numel(speedValid));

validFront = isfinite(alpha_f_deg) & isfinite(Fyf) & isfinite(slip_ratio_f) ...
           & speedValid ...
           & abs(alpha_f_deg) < alpha_max_deg ...
           & abs(slip_ratio_f) < slip_ratio_max ...
           & biasValid ...
           & seamValid;

validRear  = isfinite(alpha_r_deg) & isfinite(Fyr) & isfinite(slip_ratio_r) ...
           & speedValid ...
           & abs(alpha_r_deg) < alpha_max_deg ...
           & abs(slip_ratio_r) < slip_ratio_max ...
           & biasValid ...
           & seamValid;

% Normalized versions additionally require a positive normal force.
validFront_n = validFront & Fz_front_norm > 0;
validRear_n  = validRear  & Fz_rear_norm  > 0;

validTire = @(sr) isfinite(sr) & speedValid ...
                & abs(sr) < slip_ratio_max ...
                & biasValid ...
                & seamValid;

validFL = validTire(slip_ratio_x_fl);
validFR = validTire(slip_ratio_x_fr);
validRL = validTire(slip_ratio_x_rl);
validRR = validTire(slip_ratio_x_rr);

validFL_n = validFL & Fz_fl_norm > 0;
validFR_n = validFR & Fz_fr_norm > 0;
validRL_n = validRL & Fz_rl_norm > 0;
validRR_n = validRR & Fz_rr_norm > 0;

%% pure-longitudinal masks for figs S3, S4, S7 and S8
% The masks above, narrowed to samples that are not meaningfully cornering.
% ay_tire is NaN wherever the curvature is not resolved, and abs(NaN) < x is
% false, so those samples drop out here as well.

pureLong = abs(ay_tire) < ay_max_pure_long;

if isfinite(ay_max_pure_long)
    pureLong_label = sprintf("|a_y| < %.3g m/s^2", ay_max_pure_long);
else
    pureLong_label = "no a_y gate";
end

fprintf("pure-longitudinal gate |a_y| < %.3g m/s^2 keeps %d of %d samples (%.1f%%)\n", ...
    ay_max_pure_long, sum(pureLong), numel(pureLong), ...
    100 * sum(pureLong) / numel(pureLong));

validFront_L   = validFront   & pureLong;
validRear_L    = validRear    & pureLong;
validFront_Ln  = validFront_n & pureLong;
validRear_Ln   = validRear_n  & pureLong;

validFL_L  = validFL  & pureLong;
validFR_L  = validFR  & pureLong;
validRL_L  = validRL  & pureLong;
validRR_L  = validRR  & pureLong;

validFL_Ln = validFL_n & pureLong;
validFR_Ln = validFR_n & pureLong;
validRL_Ln = validRL_n & pureLong;
validRR_Ln = validRR_n & pureLong;

if isfinite(ay_max_pure_long)
    fprintf("  fig S8 per-tire counts after the gate: FL %d, FR %d, RL %d, RR %d (was %d, %d, %d, %d)\n", ...
        sum(validFL_Ln), sum(validFR_Ln), sum(validRL_Ln), sum(validRR_Ln), ...
        sum(validFL_n),  sum(validFR_n),  sum(validRL_n),  sum(validRR_n));
end

%% fig S0 - inputs: wheel speeds, brake pressure, brake bias, a_x
% biasF is held at defaultFrontBrakeBias whenever the line pressure is too low
% to resolve it, so the measured-only trace is overlaid to show where the bias
% is genuinely observed. Samples outside the min/max bias window are marked
% red; they still appear here as a diagnostic but are excluded from every
% result.

biasF_measured = biasF;
biasF_measured(~hasBrakePressure) = NaN;

parentS0 = newFigTab(FG, "inputs", 'Fig S0 - Wheel Speeds / Brake Pressure / Bias / a_x / a_y');

layoutS0 = tiledlayout(parentS0, 5, 1, "TileSpacing", "compact", "Padding", "compact");

axS0 = gobjects(5,1);

axS0(1) = nexttile(layoutS0);
plot(t_plot, Vw_fl);
hold on
plot(t_plot, Vw_fr);
plot(t_plot, Vw_rl);
plot(t_plot, Vw_rr);
grid on
ylabel("Wheel speed [m/s]");
legend("FL", "FR", "RL", "RR", "Location", "best");
title("Wheel speeds");

axS0(2) = nexttile(layoutS0);
plot(t_plot, Pf);
hold on
plot(t_plot, Pr);
grid on
ylabel("Pressure [kPa]");
legend("front", "rear", "Location", "best");
title("Brake pressure");

axS0(3) = nexttile(layoutS0);
plot(t_plot, biasF, "DisplayName", "force bias used");
hold on
plot(t_plot, biasF_measured, "LineWidth", 1.5, "DisplayName", "measured only");
plot(t_plot, biasF_pressure, ":", "LineWidth", 1.2, ...
    "DisplayName", "pressure ratio P_f/(P_f+P_r)");
plot(t(~biasValid), biasF(~biasValid), "rx", "MarkerSize", 5, ...
    "DisplayName", "rejected");
yline(defaultFrontBrakeBias, "k--", "default", "HandleVisibility", "off");
yline(maxFrontBrakeBias, "r--", "max", "HandleVisibility", "off");
yline(minFrontBrakeBias, "r--", "min", "HandleVisibility", "off");
grid on
ylim([0 1]);
ylabel("Front bias [-]");
legend("Location", "best");
title("Front brake bias - force share used to split F_x, against the raw pressure ratio");

axS0(4) = nexttile(layoutS0);
plot(t_plot, Fax);
yline(0, "k--");
grid on
ylabel("a_x [m/s^2]");
title("Longitudinal acceleration");

% Lateral acceleration, replacing the slip-ratio panel this figure used to end
% on. Slip ratio has four dedicated figures of its own (S7, S8, S8b-d) plus the
% per-axle pair S3/S4, so it was the one channel here that was already well
% covered elsewhere - and a_y was not shown anywhere in the time domain at all,
% despite three different definitions of it now driving the analysis.
%
% Both traces, because the difference between them is the point:
%
%   a_y channel   the logged a_y, the direct measurement. Pairs with the a_x
%                 panel above, which is also the logged channel.
%   ay_tire       what the TIRES have to make - the same kinematic acceleration
%                 with the bank's gravity assist taken out. This is what Fyf and
%                 Fyr are built from.
%
% They sit on top of each other on flat ground and separate on the banked
% sections, so the gap between them IS the bank, plotted against time. Worth
% about 7% of the cornering demand on this track.
axS0(5) = nexttile(layoutS0);
plot(t_plot, Fay, "LineWidth", 1.0);
hold on
plot(t_plot, ay_tire, "LineWidth", 1.4);
yline(0, "k--", "HandleVisibility", "off");
grid on
xlabel("Time [s]");
ylabel("a_y [m/s^2]");
legend("a_y channel", "a_y at the tires (bank corrected)", "Location", "best");
title("Lateral acceleration");

% Mark the joins between time_segment sections on every panel.
for iAx = 1:numel(axS0)
    for iSeam = 1:numel(seam_time)
        xline(axS0(iAx), seam_time(iSeam), "k:", "LineWidth", 1.2, ...
            "HandleVisibility", "off");
    end
end

linkaxes(axS0, "x");

%% fig S1 - slip angle vs axle lateral force [N]
parentS1 = newFigTab(FG, "lateral", 'Fig S1 - Slip Angle vs F_y (per axle, measured)');

layoutS1 = tiledlayout(parentS1, 1, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(layoutS1)
scatterTime(alpha_f_deg(validFront), Fyf(validFront), tAbs(validFront));
xlabel('Front slip angle \alpha_f [deg]');
ylabel('Front lateral force F_{y,f} [N]');
title('Front axle');

nexttile(layoutS1)
scatterTime(alpha_r_deg(validRear), Fyr(validRear), tAbs(validRear));
xlabel('Rear slip angle \alpha_r [deg]');
ylabel('Rear lateral force F_{y,r} [N]');
title('Rear axle');

title(layoutS1, 'Slip angle vs measured lateral force');

%% fig S2 - slip angle vs axle Fy / Fz [-]
parentS2 = newFigTab(FG, "lateral", 'Fig S2 - Slip Angle vs F_y/F_z (per axle, observed F_z)');

layoutS2 = tiledlayout(parentS2, 1, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(layoutS2)
scatterTime(alpha_f_deg(validFront_n), ...
            Fyf(validFront_n) ./ Fz_front_norm(validFront_n), ...
            tAbs(validFront_n));
xlabel('Front slip angle \alpha_f [deg]');
ylabel('F_{y,f} / F_{z,f} [-]');
title('Front axle');

nexttile(layoutS2)
scatterTime(alpha_r_deg(validRear_n), ...
            Fyr(validRear_n) ./ Fz_rear_norm(validRear_n), ...
            tAbs(validRear_n));
xlabel('Rear slip angle \alpha_r [deg]');
ylabel('F_{y,r} / F_{z,r} [-]');
title('Rear axle');

title(layoutS2, sprintf('Slip angle vs measured lateral force / %s', Fz_label));

%% fig S3 - slip ratio vs axle longitudinal force [N]
parentS3 = newFigTab(FG, "long", 'Fig S3 - Slip Ratio vs F_x (per axle, measured)');

layoutS3 = tiledlayout(parentS3, 1, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(layoutS3)
scatterTime(slip_ratio_f(validFront_L), Fxf(validFront_L), tAbs(validFront_L));
xlabel('Front slip ratio \kappa_f [-]');
ylabel('Front longitudinal force F_{x,f} [N]');
title('Front axle');

nexttile(layoutS3)
scatterTime(slip_ratio_r(validRear_L), Fxr(validRear_L), tAbs(validRear_L));
xlabel('Rear slip ratio \kappa_r [-]');
ylabel('Rear longitudinal force F_{x,r} [N]');
title('Rear axle');

title(layoutS3, sprintf('Slip ratio vs measured longitudinal force   (%s, %s)', ...
    slip_ratio_label, pureLong_label));

%% fig S4 - slip ratio vs axle Fx / Fz [-]
parentS4 = newFigTab(FG, "long", 'Fig S4 - Slip Ratio vs F_x/F_z (per axle, observed F_z)');

layoutS4 = tiledlayout(parentS4, 1, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(layoutS4)
scatterTime(slip_ratio_f(validFront_Ln), ...
            Fxf(validFront_Ln) ./ Fz_front_norm(validFront_Ln), ...
            tAbs(validFront_Ln));
xlabel('Front slip ratio \kappa_f [-]');
ylabel('F_{x,f} / F_{z,f} [-]');
title('Front axle');

nexttile(layoutS4)
scatterTime(slip_ratio_r(validRear_Ln), ...
            Fxr(validRear_Ln) ./ Fz_rear_norm(validRear_Ln), ...
            tAbs(validRear_Ln));
xlabel('Rear slip ratio \kappa_r [-]');
ylabel('F_{x,r} / F_{z,r} [-]');
title('Rear axle');

title(layoutS4, sprintf('Slip ratio vs measured longitudinal force / %s   (%s, %s)', ...
    Fz_label, slip_ratio_label, pureLong_label));

%% fig S5 - friction circle per axle [N]
parentS5 = newFigTab(FG, "circle", 'Fig S5 - Friction Circle (per axle, measured)');

layoutS5 = tiledlayout(parentS5, 1, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(layoutS5)
scatterTime(Fxf(validFront), Fyf(validFront), tAbs(validFront));
axis equal;
xlabel('F_{x,f} [N]'); ylabel('F_{y,f} [N]');
title('Front axle');

nexttile(layoutS5)
scatterTime(Fxr(validRear), Fyr(validRear), tAbs(validRear));
axis equal;
xlabel('F_{x,r} [N]'); ylabel('F_{y,r} [N]');
title('Rear axle');

title(layoutS5, 'Friction circle - measured force');

%% fig S6 - friction circle per axle, normalized [-]
parentS6 = newFigTab(FG, "circle", 'Fig S6 - Friction Circle (per axle, observed F_z)');

layoutS6 = tiledlayout(parentS6, 1, 2, "TileSpacing", "compact", "Padding", "compact");

nexttile(layoutS6)
scatterTime(Fxf(validFront_n) ./ Fz_front_norm(validFront_n), ...
            Fyf(validFront_n) ./ Fz_front_norm(validFront_n), ...
            tAbs(validFront_n));
muCircle(1.0); axis equal;
xlabel('F_{x,f} / F_{z,f} [-]'); ylabel('F_{y,f} / F_{z,f} [-]');
title('Front axle');

nexttile(layoutS6)
scatterTime(Fxr(validRear_n) ./ Fz_rear_norm(validRear_n), ...
            Fyr(validRear_n) ./ Fz_rear_norm(validRear_n), ...
            tAbs(validRear_n));
muCircle(1.0); axis equal;
xlabel('F_{x,r} / F_{z,r} [-]'); ylabel('F_{y,r} / F_{z,r} [-]');
title('Rear axle');

title(layoutS6, sprintf('Friction circle - measured force / %s (dashed = \\mu 1.0)', Fz_label));

%% per-tire figures
if plot_per_tire

    %% fig S7 - slip ratio vs Fx per tire [N]
    parentS7 = newFigTab(FG, "long", 'Fig S7 - Slip Ratio vs F_x (per tire, measured)');

layoutS7 = tiledlayout(parentS7, 2, 2, "TileSpacing", "compact", "Padding", "compact");

    nexttile(layoutS7)
    scatterTime(slip_ratio_x_fl(validFL_L), fx_fl(validFL_L), tAbs(validFL_L));
    xlabel('\kappa_{fl} [-]'); ylabel('F_{x,fl} [N]'); title('Front Left');

    nexttile(layoutS7)
    scatterTime(slip_ratio_x_fr(validFR_L), fx_fr(validFR_L), tAbs(validFR_L));
    xlabel('\kappa_{fr} [-]'); ylabel('F_{x,fr} [N]'); title('Front Right');

    nexttile(layoutS7)
    scatterTime(slip_ratio_x_rl(validRL_L), fx_rl(validRL_L), tAbs(validRL_L));
    xlabel('\kappa_{rl} [-]'); ylabel('F_{x,rl} [N]'); title('Rear Left');

    nexttile(layoutS7)
    scatterTime(slip_ratio_x_rr(validRR_L), fx_rr(validRR_L), tAbs(validRR_L));
    xlabel('\kappa_{rr} [-]'); ylabel('F_{x,rr} [N]'); title('Rear Right');

    title(layoutS7, sprintf('Slip ratio vs measured longitudinal force (per-tire split: %s)   (%s, %s)', ...
        fx_split_label, slip_ratio_label, pureLong_label));

    %% fig S8 - slip ratio vs Fx / Fz per tire [-]
    parentS8 = newFigTab(FG, "long", 'Fig S8 - Slip Ratio vs F_x/F_z (per tire, observed F_z)');

layoutS8 = tiledlayout(parentS8, 2, 2, "TileSpacing", "compact", "Padding", "compact");

    nexttile(layoutS8)
    scatterTime(slip_ratio_x_fl(validFL_Ln), ...
                fx_fl(validFL_Ln) ./ Fz_fl_norm(validFL_Ln), tAbs(validFL_Ln));
    xlabel('\kappa_{fl} [-]'); ylabel('F_{x,fl} / F_{z,fl} [-]'); title('Front Left');

    nexttile(layoutS8)
    scatterTime(slip_ratio_x_fr(validFR_Ln), ...
                fx_fr(validFR_Ln) ./ Fz_fr_norm(validFR_Ln), tAbs(validFR_Ln));
    xlabel('\kappa_{fr} [-]'); ylabel('F_{x,fr} / F_{z,fr} [-]'); title('Front Right');

    nexttile(layoutS8)
    scatterTime(slip_ratio_x_rl(validRL_Ln), ...
                fx_rl(validRL_Ln) ./ Fz_rl_norm(validRL_Ln), tAbs(validRL_Ln));
    xlabel('\kappa_{rl} [-]'); ylabel('F_{x,rl} / F_{z,rl} [-]'); title('Rear Left');

    nexttile(layoutS8)
    scatterTime(slip_ratio_x_rr(validRR_Ln), ...
                fx_rr(validRR_Ln) ./ Fz_rr_norm(validRR_Ln), tAbs(validRR_Ln));
    xlabel('\kappa_{rr} [-]'); ylabel('F_{x,rr} / F_{z,rr} [-]'); title('Rear Right');

    title(layoutS8, sprintf('Slip ratio vs measured longitudinal force / %s   (%s, %s)', ...
        Fz_label, slip_ratio_label, pureLong_label));

    %% figs S8b, S8c - fig S8 colored by condition instead of by time
    % Same axes and the same samples as fig S8; only the color changes. Fig S8
    % colors by time, which answers "when did this happen". These answer "under
    % what condition", which is what pulls apart two branches of a tire curve
    % that otherwise sit on top of each other.
    %
    %   S8b  tire temperature - that tire's own across-tread average
    %   S8c  speed
    %   S8d  yaw rate, signed, on a scale centred on zero
    %
    % A sample whose color channel is NaN cannot be drawn and is dropped on top
    % of the fig S8 masks. That matters for temperature, where RL and RR only
    % ever have three live sensors (see the tire temp section).
    %
    % Within a figure the four panels share one color scale. Left to themselves
    % a tire that only moved through 5 degC would use the same full ramp as one
    % that moved through 40, and the panels could not be read against each
    % other.

    s8_baseValid = {validFL_Ln, validFR_Ln, validRL_Ln, validRR_Ln};
    s8_kappa     = {slip_ratio_x_fl, slip_ratio_x_fr, slip_ratio_x_rl, slip_ratio_x_rr};
    s8_fx        = {fx_fl, fx_fr, fx_rl, fx_rr};
    s8_fz        = {Fz_fl_norm, Fz_fr_norm, Fz_rl_norm, Fz_rr_norm};

    s8_colorTags   = ["S8b", "S8c", "S8d"];
    s8_colorNames  = ["tire temperature", "speed", "yaw rate"];
    s8_colorBars   = ["Tire temperature [\circC]", "Speed v_x [m/s]", ...
                      "Yaw rate r [deg/s]"];
    s8_colorUnits  = ["degC", "m/s", "deg/s"];

    % Smallest color range worth spreading over the whole ramp, in each
    % channel's own units. Below this the scale is widened to it, so that a run
    % holding one value does not turn sensor noise into a full sweep of hues.
    s8_colorMinSpan = [1, 1, 1];

    % Signed channels get a color scale centred on zero, so a left and a right
    % turn of the same magnitude land on mirrored hues instead of the sign being
    % swallowed by whichever direction the run happened to favour.
    s8_colorSymmetric = [false, false, true];

    % One color vector per tire per figure. Temperature is genuinely per tire;
    % speed and yaw rate are vehicle channels reused four times.
    s8_colorData = { ...
        {tire_temp_mean_f(:,1), tire_temp_mean_f(:,2), ...
         tire_temp_mean_f(:,3), tire_temp_mean_f(:,4)}, ...
        {Fvx, Fvx, Fvx, Fvx}, ...
        {rad2deg(Fwz), rad2deg(Fwz), rad2deg(Fwz), rad2deg(Fwz)}};

    for iColor = 1:numel(s8_colorTags)

        colorPerTire = s8_colorData{iColor};

        s8_keep     = cell(4,1);
        s8_colorAll = [];

        for tire = 1:4
            s8_keep{tire} = s8_baseValid{tire} & isfinite(colorPerTire{tire});
            s8_colorAll = [s8_colorAll; colorPerTire{tire}(s8_keep{tire})];   %#ok<AGROW>
        end

        fprintf("fig %s (colored by %s): FL %d, FR %d, RL %d, RR %d samples (fig S8 plots %d, %d, %d, %d)\n", ...
            s8_colorTags(iColor), s8_colorNames(iColor), ...
            sum(s8_keep{1}), sum(s8_keep{2}), sum(s8_keep{3}), sum(s8_keep{4}), ...
            sum(s8_baseValid{1}), sum(s8_baseValid{2}), ...
            sum(s8_baseValid{3}), sum(s8_baseValid{4}));

        parentS8x = newFigTab(FG, "long", sprintf('Fig %s - Slip Ratio vs F_x/F_z (per tire, colored by %s)', ...
            s8_colorTags(iColor), s8_colorNames(iColor)));

        layoutS8x = tiledlayout(parentS8x, 2, 2, "TileSpacing", "compact", "Padding", "compact");

        axS8x = gobjects(4,1);

        for tire = 1:4

            keep = s8_keep{tire};

            axS8x(tire) = nexttile(layoutS8x);

            scatter(s8_kappa{tire}(keep), ...
                    s8_fx{tire}(keep) ./ s8_fz{tire}(keep), ...
                    18, colorPerTire{tire}(keep), "filled");

            grid on
            box on
            xline(0, "k--");
            yline(0, "k--");

            title(sprintf("%s  (%d samples)", tire_names(tire), sum(keep)));
            xlabel("\kappa [-]");
            ylabel("F_x / F_z [-]");

            set(axS8x(tire), "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);
        end

        linkaxes(axS8x, "xy");

        if isempty(s8_colorAll)
            warning("notmal_force_estimation:emptyS8Color", ...
                "Fig %s has no samples with a finite %s.", ...
                s8_colorTags(iColor), s8_colorNames(iColor));
        else
            s8_colorLimits = robustRange(s8_colorAll, 0.01);

            if s8_colorSymmetric(iColor)
                s8_colorLimits = max(abs(s8_colorLimits)) .* [-1 1];
            end

            if s8_colorLimits(2) - s8_colorLimits(1) < s8_colorMinSpan(iColor)
                s8_colorLimits = mean(s8_colorLimits) ...
                    + s8_colorMinSpan(iColor) .* [-0.5 0.5];
            end

            for tire = 1:4
                caxis(axS8x(tire), s8_colorLimits);
            end

            fprintf("  fig %s color scale: %.1f to %.1f %s\n", ...
                s8_colorTags(iColor), s8_colorLimits(1), s8_colorLimits(2), ...
                s8_colorUnits(iColor));
        end

        cbS8x = colorbar(axS8x(1));
        cbS8x.Layout.Tile = "east";
        ylabel(cbS8x, s8_colorBars(iColor));

        title(layoutS8x, ...
            sprintf('Slip ratio vs F_x / %s, colored by %s   (%s, %s)', ...
            Fz_label, s8_colorNames(iColor), slip_ratio_label, pureLong_label), ...
            "FontWeight", "bold");
    end

    %% fig S9 - friction circle per tire [N]
    parentS9 = newFigTab(FG, "circle", 'Fig S9 - Friction Circle (per tire, measured)');

layoutS9 = tiledlayout(parentS9, 2, 2, "TileSpacing", "compact", "Padding", "compact");

    nexttile(layoutS9)
    scatterTime(fx_fl(validFL), Fy_fl(validFL), tAbs(validFL));
    axis equal; xlabel('F_{x,fl} [N]'); ylabel('F_{y,fl} [N]'); title('Front Left');

    nexttile(layoutS9)
    scatterTime(fx_fr(validFR), Fy_fr(validFR), tAbs(validFR));
    axis equal; xlabel('F_{x,fr} [N]'); ylabel('F_{y,fr} [N]'); title('Front Right');

    nexttile(layoutS9)
    scatterTime(fx_rl(validRL), Fy_rl(validRL), tAbs(validRL));
    axis equal; xlabel('F_{x,rl} [N]'); ylabel('F_{y,rl} [N]'); title('Rear Left');

    nexttile(layoutS9)
    scatterTime(fx_rr(validRR), Fy_rr(validRR), tAbs(validRR));
    axis equal; xlabel('F_{x,rr} [N]'); ylabel('F_{y,rr} [N]'); title('Rear Right');

    title(layoutS9, sprintf('Friction circle per tire - measured force (per-tire split: %s)', ...
        fx_split_label));

    %% fig S10 - friction circle per tire, normalized [-]
    parentS10 = newFigTab(FG, "circle", 'Fig S10 - Friction Circle (per tire, observed F_z)');

layoutS10 = tiledlayout(parentS10, 2, 2, "TileSpacing", "compact", "Padding", "compact");

    nexttile(layoutS10)
    scatterTime(fx_fl(validFL_n) ./ Fz_fl_norm(validFL_n), ...
                Fy_fl(validFL_n) ./ Fz_fl_norm(validFL_n), tAbs(validFL_n));
    muCircle(1.0); axis equal;
    xlabel('F_{x,fl} / F_{z,fl} [-]'); ylabel('F_{y,fl} / F_{z,fl} [-]'); title('Front Left');

    nexttile(layoutS10)
    scatterTime(fx_fr(validFR_n) ./ Fz_fr_norm(validFR_n), ...
                Fy_fr(validFR_n) ./ Fz_fr_norm(validFR_n), tAbs(validFR_n));
    muCircle(1.0); axis equal;
    xlabel('F_{x,fr} / F_{z,fr} [-]'); ylabel('F_{y,fr} / F_{z,fr} [-]'); title('Front Right');

    nexttile(layoutS10)
    scatterTime(fx_rl(validRL_n) ./ Fz_rl_norm(validRL_n), ...
                Fy_rl(validRL_n) ./ Fz_rl_norm(validRL_n), tAbs(validRL_n));
    muCircle(1.0); axis equal;
    xlabel('F_{x,rl} / F_{z,rl} [-]'); ylabel('F_{y,rl} / F_{z,rl} [-]'); title('Rear Left');

    nexttile(layoutS10)
    scatterTime(fx_rr(validRR_n) ./ Fz_rr_norm(validRR_n), ...
                Fy_rr(validRR_n) ./ Fz_rr_norm(validRR_n), tAbs(validRR_n));
    muCircle(1.0); axis equal;
    xlabel('F_{x,rr} / F_{z,rr} [-]'); ylabel('F_{y,rr} / F_{z,rr} [-]'); title('Rear Right');

    title(layoutS10, sprintf('Friction circle per tire - measured force / %s (dashed = \\mu 1.0)', Fz_label));
end

%% export the fig S8 longitudinal slip data, one CSV per axle

slipExport_enable = true;

if slipExport_enable

    slipExport_scriptDir = fileparts(mfilename('fullpath'));

    if isempty(slipExport_scriptDir)
        slipExport_scriptDir = pwd;   % running loose in the command window
    end

    slipExport_dir = fullfile(slipExport_scriptDir, "..", "tire_model_matlab");

    export_names  = ["FL", "FR", "RL", "RR"];
    export_axle   = ["front", "front", "rear", "rear"];
    export_kappa  = {slip_ratio_x_fl, slip_ratio_x_fr, slip_ratio_x_rl, slip_ratio_x_rr};
    export_vxTire = {Vx_tire_fl, Vx_tire_fr, Vx_tire_rl, Vx_tire_rr};
    export_wheel  = {Vw_fl, Vw_fr, Vw_rl, Vw_rr};
    export_fx     = {fx_fl, fx_fr, fx_rl, fx_rr};
    export_fz     = {Fz_fl_norm, Fz_fr_norm, Fz_rl_norm, Fz_rr_norm};
    export_valid  = {validFL_n, validFR_n, validRL_n, validRR_n};

    export_rows = cell(4,1);

    for iTire = 1:4

        kappa_tire = export_kappa{iTire};
        vxTire     = export_vxTire{iTire};
        wheelSpeed = export_wheel{iTire};
        fxTire     = export_fx{iTire};
        fzTire     = export_fz{iTire};

        % Sim-convention slip ratio, referenced to the tire's own vx.
        kappa_vxRef = (wheelSpeed - vxTire) ./ abs(vxTire);

        keep = export_valid{iTire} & ~lowSpeedMask ...
             & isfinite(kappa_tire) & isfinite(kappa_vxRef) ...
             & isfinite(fxTire) & isfinite(fzTire) & fzTire > 0;

        export_rows{iTire} = table( ...
            tAbs(keep), ...
            repmat(export_names(iTire), sum(keep), 1), ...
            Fvx(keep), ...
            Fax(keep), ...
            kappa_tire(keep), ...
            kappa_vxRef(keep), ...
            fxTire(keep), ...
            fzTire(keep), ...
            fxTire(keep) ./ fzTire(keep), ...
            'VariableNames', {'time_s', 'tire', 'vx_mps', 'ax_mps2', ...
                              'slip_ratio', 'slip_ratio_vx_ref', ...
                              'Fx_N', 'Fz_N', 'Fx_over_Fz'});

        fprintf("slip export %s: %d of %d samples kept (%d dropped by the fig S8 masks, %d by the zero-speed guard)\n", ...
            export_names(iTire), sum(keep), numel(keep), ...
            sum(~export_valid{iTire}), sum(export_valid{iTire} & lowSpeedMask));
    end

    slipExport_axles = ["front", "rear"];
    slipExport_files = ["measured_slip_ratio_front.csv", "measured_slip_ratio_rear.csv"];

    for iAxle = 1:2

        axleRows = vertcat(export_rows{export_axle == slipExport_axles(iAxle)});
        outPath  = fullfile(slipExport_dir, slipExport_files(iAxle));

        writetable(axleRows, outPath);

        if height(axleRows) == 0
            warning("notmal_force_estimation:emptySlipExport", ...
                "%s has no rows: every %s sample was vetoed.", ...
                outPath, slipExport_axles(iAxle));
        else
            fprintf("wrote %s  (%d rows, kappa %.3f to %.3f, Fz %.0f to %.0f N)\n", ...
                outPath, height(axleRows), ...
                min(axleRows.slip_ratio), max(axleRows.slip_ratio), ...
                min(axleRows.Fz_N), max(axleRows.Fz_N));
        end
    end
end

%% slip ratio over the (speed, a_x) plane
% Speed on the x axis and longitudinal acceleration on the y axis, signed the
% same way as the a_x trace in fig S0: negative is braking, so the lower half
% of each panel is deceleration and the upper half is acceleration. Color is
% the slip ratio: negative means the wheel is turning slower than the road
% under it (braking slip) and gets the whole rainbow, dark purple at
% kappa = kappaMap_posLimit through blue, cyan, green and yellow to deep red
% at kappaMap_negLimit and anything past it. Slip above kappaMap_posLimit is
% one flat grey - these maps are for reading the braking side.

kappa_per_tire = {slip_ratio_x_fl, slip_ratio_x_fr, slip_ratio_x_rl, slip_ratio_x_rr};
kappa_valid    = {validFL, validFR, validRL, validRR};

% The per-tire masks already drop the low-speed, bad-bias and seam samples;
% a sample also needs a finite speed and acceleration to be placed on the map.
mapValid = isfinite(Fvx) & isfinite(Fax);

kappa_map_keep    = cell(4,1);
kappa_map_samples = cell(4,1);

for tire = 1:4
    kappa_map_keep{tire} = kappa_valid{tire} & mapValid & isfinite(kappa_per_tire{tire});
    kappa_map_samples{tire} = kappa_per_tire{tire}(kappa_map_keep{tire});
end

kappa_map_samples = vertcat(kappa_map_samples{:});

kappaMapAnyValid = kappa_map_keep{1} | kappa_map_keep{2} | ...
                   kappa_map_keep{3} | kappa_map_keep{4};

% One color scale for both figures and all four tires, so a panel that is
% further up the rainbow really is slipping more. CLim runs from the negative
% limit up through a short band above posLimit: MATLAB clamps to the end rows,
% so anything at or below kappaMap_negLimit lands on the deep red end and
% anything above kappaMap_posLimit lands in the flat block whatever its size.
kappa_map_flatBand = (kappaMap_posLimit - kappaMap_negLimit) / 9;   % ~10% of the bar
kappa_map_clim     = [kappaMap_negLimit, kappaMap_posLimit + kappa_map_flatBand];
kappa_map_cmap    = kappaColormap(512, kappaMap_negLimit, kappaMap_posLimit, ...
                                  kappa_map_clim(2), kappaMap_posColor, ...
                                  kappaMap_colorGamma);

% Where the landmark hues land, so colorGamma can be set on numbers: a
% rainbow position p sits at kappa = posLimit - p^(1/gamma) * (posLimit - negLimit).
kappa_map_hueNames     = ["cyan", "green", "yellow", "orange", "red"];
kappa_map_huePositions = [0.30, 0.45, 0.60, 0.75, 0.88];
kappa_map_hueKappa     = kappaMap_posLimit ...
    - kappa_map_huePositions .^ (1 / kappaMap_colorGamma) ...
      .* (kappaMap_posLimit - kappaMap_negLimit);

fprintf("kappa map hues (gamma %.2f):", kappaMap_colorGamma);

for iHue = 1:numel(kappa_map_hueNames)
    fprintf(" %s at %.3f", kappa_map_hueNames(iHue), kappa_map_hueKappa(iHue));
end

fprintf("\n");

kappa_map_ticks = kappaMap_negLimit : kappaMap_tickStep : kappaMap_posLimit;

% posLimit gets its own tick only when the stepped ticks stop well short of
% it, so that the top of the ramp is labelled without crowding the tick below.
if isempty(kappa_map_ticks) || ...
        kappaMap_posLimit - kappa_map_ticks(end) > 0.5 * kappaMap_tickStep
    kappa_map_ticks(end+1) = kappaMap_posLimit;
end

% Rounded before unique so that a colon-operator endpoint landing an ulp away
% from posLimit does not leave two ticks with the same printed label.
kappa_map_ticks = unique(round(kappa_map_ticks, 6));

% Where the slip actually sits, so the two limits can be set on numbers
% instead of guessed at.
kappa_abs_sorted = sort(abs(kappa_map_samples));

if ~isempty(kappa_abs_sorted)
    kappa_pct_levels = [0.50 0.75 0.90 0.95 0.99 1.00];
    kappa_pct_values = kappa_abs_sorted( ...
        max(1, round(kappa_pct_levels .* numel(kappa_abs_sorted))));

    fprintf("kappa map |kappa| spread over %d samples: 50%% %.3f | 75%% %.3f | 90%% %.3f | 95%% %.3f | 99%% %.3f | max %.3f\n", ...
        numel(kappa_abs_sorted), kappa_pct_values);

    fprintf("kappa map color scale: ramp %.3f to %.3f, %.1f%% of samples clip to the red end, %.1f%% fall in the grey block\n", ...
        kappaMap_negLimit, kappaMap_posLimit, ...
        100 * mean(kappa_map_samples <= kappaMap_negLimit), ...
        100 * mean(kappa_map_samples > kappaMap_posLimit));
end

if ~any(kappaMapAnyValid)
    warning("notmal_force_estimation:emptyKappaMap", ...
        "No valid samples for the slip-ratio maps (figs S11 and S12).");
end

%% fig S11 - slip ratio vs speed and a_x, every sample
parentS11 = newFigTab(FG, "maps", 'Fig S11 - Slip Ratio vs Speed and a_x (per tire, samples)');

layoutS11 = tiledlayout(parentS11, 2, 2, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

axS11 = gobjects(4,1);

for tire = 1:4

    keep = kappa_map_keep{tire};

    axS11(tire) = nexttile(layoutS11);
    scatter(Fvx(keep), Fax(keep), 14, kappa_per_tire{tire}(keep), "filled");
    grid on
    box on
    yline(0, "k--");

    colormap(axS11(tire), kappa_map_cmap);
    caxis(axS11(tire), kappa_map_clim);

    title(sprintf("%s  (%d samples)", tire_names(tire), sum(keep)));
    xlabel("Speed v_x [m/s]");
    ylabel("a_x [m/s^2]   (negative = braking)");

    set(axS11(tire), "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);
end

linkaxes(axS11, "xy");

cbS11 = colorbar(axS11(1));
cbS11.Layout.Tile = "east";
cbS11.Ticks = kappa_map_ticks;
ylabel(cbS11, "slip ratio");

title(layoutS11, ...
    sprintf("Slip ratio over speed and a_x, braking negative  (rainbow ramp \\kappa = %.2f to %.2f, grey above)", ...
    kappaMap_negLimit, kappaMap_posLimit), ...
    "FontWeight", "bold");

%% fig S12 - front brake bias vs speed and a_x, every sample
% Same plane as fig S11, colored by the front brake bias instead of by slip
% ratio, so the two read against each other: where the bias sits when a corner
% starts to lock. Brake bias is a vehicle-level quantity, so this is one panel
% rather than four.
%
% The bias is taken straight from the two pressure channels here rather than
% from biasF, which is held at defaultFrontBrakeBias whenever the pressure is
% too low to resolve the split. A sample only counts as braking when the two
% pressures add up to more than biasMap_pressureMin_kPa; below that the split
% is residual pressure and sensor offset, which is why a bias could otherwise
% appear on the acceleration side of the plot. Samples that are not braking
% have no bias to show and are drawn grey.

biasMap_value = nan(size(brakePressureTotal));
biasMap_braking = brakePressureTotal > biasMap_pressureMin_kPa;

biasMap_value(biasMap_braking) = ...
    Pf(biasMap_braking) ./ brakePressureTotal(biasMap_braking);

% A split outside the physical window means a pressure channel dropped out, so
% it is no more a bias than the low-pressure samples are.
biasMap_observed = biasMap_braking & isfinite(biasMap_value) ...
                 & biasMap_value >= minFrontBrakeBias ...
                 & biasMap_value <= maxFrontBrakeBias;

biasMapBase  = mapValid & speedValid & seamValid;
biasMapColor = biasMapBase & biasMap_observed;
biasMapGrey  = biasMapBase & ~biasMap_observed;

fprintf("bias map: %d of %d plotted samples are braking above %g kPa total (%.1f%%), %d drawn grey\n", ...
    sum(biasMapColor), sum(biasMapBase), biasMap_pressureMin_kPa, ...
    100 * sum(biasMapColor) / max(1, sum(biasMapBase)), sum(biasMapGrey));

parentS12 = newFigTab(FG, "maps", 'Fig S12 - Front Brake Bias vs Speed and a_x');

axS12 = axes(parentS12);

hold on

% Grey first, so the samples that carry a bias sit on top of the ones that
% do not.
scatter(Fvx(biasMapGrey), Fax(biasMapGrey), 14, biasMap_greyColor, "filled", ...
    "DisplayName", sprintf("not braking (P_f + P_r < %g kPa)", biasMap_pressureMin_kPa));

scatter(Fvx(biasMapColor), Fax(biasMapColor), 14, biasMap_value(biasMapColor), ...
    "filled", "HandleVisibility", "off");

hold off

grid on
box on
yline(0, "k--", "HandleVisibility", "off");

colormap(axS12, rainbowColormap(512));

% Color limits from the bias that was actually observed, trimmed at both ends:
% a run whose bias only moves between 0.5 and 0.6 should still use the whole
% ramp.
if any(biasMapColor)
    bias_clim = robustRange(biasMap_value(biasMapColor), biasMap_climTail);
    bias_clim = min(max(bias_clim, 0), 1);   % a bias is a fraction

    % A run that holds one bias would otherwise get a scale of nearly zero
    % width, which turns sensor noise into a full sweep of the rainbow.
    if bias_clim(2) - bias_clim(1) < 0.02
        bias_clim = median(biasMap_value(biasMapColor)) + [-0.01 0.01];
    end

    caxis(axS12, bias_clim);

    fprintf("bias map color scale: %.3f to %.3f\n", bias_clim(1), bias_clim(2));
end

legend(axS12, "Location", "best");

xlabel("Speed v_x [m/s]");
ylabel("a_x [m/s^2]   (negative = braking)");
title(sprintf("Front brake bias over speed and a_x, braking negative  (%d braking samples of %d)", ...
    sum(biasMapColor), sum(biasMapBase)), "FontWeight", "bold");

set(axS12, "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);

cbS12 = colorbar(axS12);
ylabel(cbS12, "Front brake PRESSURE bias  P_f / (P_f + P_r)  [-]");

% Same plane as fig S11, so pan and zoom together.
linkaxes([axS11(:); axS12], "xy");

%% modelled lateral envelope, from brake_bias_schedule.m
% The a_y counterpart of the tire accel / decel curves that the longitudinal
% envelope reads back further down, and it is drawn over fig S13 for the same
% reason: the model says what the tires ALLOW at each speed, the scatter shows
% what the car DID, and the gap between them is the useful quantity.
%
% Written by the "max lateral acceleration vs speed" section of
% brake_bias_schedule.m on the same 0:4:100 m/s grid as max_accel_vs_speed.csv.
% THREE columns, not two, so the two-column loader used for the a_x curves below
% would reject it:
%
%   v_mps, ay_max_mps2, ay_max_holding_speed_mps2
%
% The second is pure cornering. The third also makes the rear push through drag
% to hold speed, which eats its friction circle - the two are identical up to
% about 65 m/s and only separate above that.
%
% The lut directory is worked out again here rather than reusing envelope_dir,
% which is not defined until the envelope section much further down.
% Grip level to overlay, matching the suffixes brake_bias_schedule.m writes:
% mu100 is the ultimate tire limit, mu095/090/085/080 are that scaled down by
% fixed fractions of nominal. mu100 is the right default here - this figure is
% asking whether the car ever exceeded what the tires allow, and the answer is
% only meaningful against the ultimate number.
envelope_gripLevel = "mu100";

latEnv_file = "max_lat_accel_vs_speed_" + envelope_gripLevel + ".csv";

latEnv_scriptDir = fileparts(mfilename('fullpath'));

if isempty(latEnv_scriptDir)
    latEnv_scriptDir = pwd;     % running the cell by hand rather than the file
end

latEnv_path   = fullfile(latEnv_scriptDir, "lut", latEnv_file);
latEnv_loaded = false;

if ~isfile(latEnv_path)
    warning("notmal_force_estimation:missingLatEnvelope", ...
        "%s not found; fig S13 is drawn without the modelled envelope. " + ...
        "Run brake_bias_schedule.m to write it.", latEnv_path);
else
    latEnv_tbl  = readtable(latEnv_path);
    latEnv_vars = string(latEnv_tbl.Properties.VariableNames);

    if ~all(ismember(["v_mps", "ay_max_mps2"], latEnv_vars))
        warning("notmal_force_estimation:latEnvelopeShape", ...
            "%s has columns %s, expected v_mps and ay_max_mps2. Envelope left off.", ...
            latEnv_path, join(latEnv_vars, ", "));
    else
        latEnv_v  = latEnv_tbl.v_mps;
        latEnv_ay = latEnv_tbl.ay_max_mps2;

        % The holding-speed column is optional, so an older file still draws.
        if any(latEnv_vars == "ay_max_holding_speed_mps2")
            latEnv_ayTrim = latEnv_tbl.ay_max_holding_speed_mps2;
        else
            latEnv_ayTrim = nan(size(latEnv_v));
        end

        latEnv_keep = isfinite(latEnv_v) & isfinite(latEnv_ay);

        if ~any(latEnv_keep)
            warning("notmal_force_estimation:emptyLatEnvelope", ...
                "%s has no usable rows; envelope left off.", latEnv_path);
        else
            latEnv_v      = latEnv_v(latEnv_keep);
            latEnv_ay     = latEnv_ay(latEnv_keep);
            latEnv_ayTrim = latEnv_ayTrim(latEnv_keep);
            latEnv_loaded = true;

            fprintf("lateral envelope: %s  (%d speeds, %.1f-%.1f m/s, a_y %.2f to %.2f m/s^2)\n", ...
                latEnv_path, sum(latEnv_keep), min(latEnv_v), max(latEnv_v), ...
                min(latEnv_ay), max(latEnv_ay));
        end
    end
end

%% fig S13 - lateral acceleration vs speed, coloured by slip angle
%
% The cornering envelope: what a_y the car actually reached at each speed, and
% how much slip angle the tires were carrying to get there. One panel per axle,
% because the front and rear slip angles are what tell you WHICH end ran out.
%
% Reading it. The outer edge of the cloud is the grip limit at that speed. Points
% on that edge with LARGE slip angle are the axle that is saturated; if the front
% edge is deep red/blue while the rear edge is still pale at the same speed and
% a_y, the car is understeering there, and the other way round for oversteer.
% A colour that keeps growing while a_y stops growing is the signature of an axle
% past its peak - the tire is giving up more angle for no more force.
%
% a_y is ay_tire, so it is the bank-corrected lateral acceleration the TIRES have
% to make, not the raw sensor channel - see the LATERAL ACCELERATION block. On a
% banked track those differ by about 7%, and it is the tire number that belongs
% on an axis next to slip angle.
%
% Signed, not absolute, on both axes. Left and right corners land on opposite
% halves, so an asymmetric cloud is real information - track layout, aero, or a
% cross-weight - and taking abs() would hide it. The diverging colormap is
% centred on zero slip so the neutral band really is alpha = 0.

% Margin past the fastest sample for the fig S13 x limit. This was the width of
% the binned p99 envelope that used to be drawn over the scatter; that line is
% gone, but the margin is still what keeps the rightmost points off the axis.
ayvx_speedBinWidth = 2.0;    % m/s

% Percentile used for the envelope, per speed bin. NOT max/min: a raw max traces
% the single noisiest sample in each bin, and the dv_y/dt term in ay_tire has a
% max of 4.4 m/s^2 against a p95 of 0.5, so one differentiated glitch drags the
% boundary up by a third of a g. 99 follows the real edge of the cloud.
% Percentile used for the a_y statistics printed to the console for fig S13.
% It no longer drives a plotted line - the binned envelope that used to be drawn
% over the scatter has been removed - but the "% of the modelled limit" numbers
% still need a robust top-of-the-data figure, and a raw max is not one: the
% dv_y/dt term in ay_tire has a max of 4.41 m/s^2 against a p95 of 0.50, so a
% single differentiated glitch would set the answer.
ayvx_envelopePct = 99;

% RETIRED, kept at 0 so the three a_y tabs share one sample population.
%
% This was 4.0 m/s^2, gating the flat-road tab to cornering samples to suppress a
% crest-driven spike on the straights. The tightened ratio band below removes
% that spike at its source, and the gate turned out to have its own bias: cutting
% the low-|a_y| samples shortens the population, which RAISES the rank a p99
% lands on. At 14-16 m/s it inflated the envelope from 11.60 to 13.98 m/s^2, and
% it applied to only one of the three tabs - so S13c was not comparable with
% S13a/S13b, which is precisely the comparison the tabs exist to support.
ayvx_flatMinAy = 0;   % m/s^2

% PURE-LATERAL GATE for fig S13, [a_x_min a_x_max] in m/s^2.
%
% The mirror of ay_max_pure_long, which isolates pure braking and traction for
% figs S3/S4/S7/S8. This one isolates pure CORNERING.
%
% Why it belongs on S13 specifically. The modelled limit that S13 draws comes
% from the "max lateral acceleration" section of brake_bias_schedule.m, and that
% is a PURE cornering solve - a_x is taken as zero, so no longitudinal transfer
% and, more importantly, no share of the friction circle spent on F_x. A measured
% sample taken while braking or accelerating hard is using part of its grip
% longitudinally and physically CANNOT reach the lateral limit the model draws.
% Leaving those samples in makes the car look further from its lateral limit than
% it is, and the gap is combined-slip, not a tire shortfall.
%
% [-2 2] keeps roughly a quarter g of longitudinal, which spends under 3% of the
% friction circle by the ellipse - small enough to call pure lateral. Widen it to
% [-Inf Inf] to switch the gate off and get every sample back.
%
% This gates fig S13 only. The other figures keep their own masks; in particular
% the raw a_y trace in fig S0 is deliberately ungated, so the full time history
% is still visible somewhere.
ayvx_axPureLatRange = [-50 50];   % m/s^2

pureLat = Fax >= ayvx_axPureLatRange(1) & Fax <= ayvx_axPureLatRange(2);

if all(isfinite(ayvx_axPureLatRange))
    pureLat_label = sprintf("a_x in [%.3g %.3g] m/s^2", ...
        ayvx_axPureLatRange(1), ayvx_axPureLatRange(2));
else
    pureLat_label = "no a_x gate";
end

fprintf("pure-lateral gate %s keeps %d of %d samples (%.1f%%)\n", ...
    pureLat_label, sum(pureLat), numel(pureLat), ...
    100 * sum(pureLat) / numel(pureLat));

% Bound on the road-geometry load ratio Fz_geo/Fz_flat before the flat-road
% equivalent is treated as meaningless.
%
% The correction divides by this ratio, so a small ratio is a large
% amplification. The old guard only rejected below 0.25, which still allows 4x -
% and that produced a streak of samples at 23 m/s reaching -29 m/s^2, or 3 g of
% "flat-road equivalent" lateral, which no tire on this car makes. Those are
% single crest events where az_road briefly collapses, and at that point the car
% is close enough to unloaded that the quasi-static framing behind the whole
% correction has stopped being true.
%
% The band is MEASURED, not picked for looks. Binning the log into 8x8 m track
% cells revisited 20+ times separates the ratio's real content from its noise:
%
%     within-cell std  0.037   scatter at one fixed place - a_z noise
%     across-cell std  0.094   genuine place-to-place road geometry
%
% So the real geometry is about +-0.19 at 2 sigma, i.e. a ratio between 0.81 and
% 1.19, and anything outside that is the a_z channel's noise rather than the
% road. (For contrast the same test on roll gives 0.109 deg against 2.994 deg -
% roll is 25:1 signal to noise, this ratio only 2.5:1, which is why it needs a
% band at all.)
%
% WHY A LOOSE BAND IS ACTIVELY WRONG HERE, not just imprecise. The correction
% DIVIDES by this ratio, and the envelope then takes a p99 of the result. That
% multiplies two independent tails - the tail of a_y and the tail of 1/ratio -
% so a p99 preferentially selects "the sample that had high a_y AND happened to
% read a low az_road". With the old [0.6 1.6] the 14-16 m/s envelope came out at
% 15.76 m/s^2 against a raw p99 of 11.92, a 32% inflation that is pure noise
% selection. Tightening the band collapses it: 11.60 at [0.8 1.25], 11.03 at
% [0.9 1.11]. A number that moves that much with the guard was never a
% measurement.
%
% Samples outside the band are dropped rather than clipped, because a clipped
% value would still be plotted as though it meant something.
ayvx_flatRatioRange = [0.80 1.25];

% Slip angle colour limits for fig S13, degrees, symmetric about zero.
%
% Symmetric and shared across BOTH panels, so front and rear are directly
% comparable by eye - the whole point of putting them side by side.
%
% FIXED rather than fitted. It was max(abs(robustRange(alpha, 0.01))), which on
% this log lands at 3.04 deg. That auto-scales, which sounds helpful and is not:
% the scale then moves whenever the time window, the log or the validity masks
% change, so the same colour means a different slip angle from one run to the
% next and two figures cannot be compared. A fixed range makes the colour mean
% one thing always.
%
% Samples beyond it saturate at the end colours rather than being dropped; the
% fraction that clips is printed below so a range that is hiding data is visible.
ayvx_alphaLim = 6;   % deg

alphaLim = ayvx_alphaLim;

%% FLAT-ROAD EQUIVALENT a_y
%
% What this is for. The modelled limit is computed on FLAT LEVEL ground - in
% brake_bias_schedule.m the axle loads are m*g shares plus downforce, nothing
% else. The measured a_y is not on that basis, so the two are not directly
% comparable until the road geometry is taken out of the measurement.
%
% ay_tire already removes HALF the bank effect: it subtracts the gravity assist,
% the g*cos(pitch)*sin(roll) that a banked corner contributes to turning the car.
% What it does NOT remove is the other half - a bank also presses the car INTO
% the road, raising every F_z and so raising the force the tires can make. Same
% for vertical curvature: a dip loads the car, a crest unloads it, and neither
% appears in a flat-road model.
%
% So a measured point on a banked corner can sit above the modelled line without
% the tire having done anything the model says is impossible - it simply had more
% normal load than the model assumes.
%
% THE CORRECTION. Scale the measured demand by how much the road geometry changed
% the normal load:
%
%       a_y,flat = a_y,tire * Fz_axle_flat / Fz_axle_actual
%
% Fz_axle_actual is the modelled/observed load the tire really had - it carries
% az_road, so it already contains BOTH the gravity projection (bank, pitch) and
% the a_z crest/dip term. Fz_axle_flat is that same axle on flat level ground:
% the m*g share plus the same aero. The ratio is therefore exactly the road
% geometry, and dividing by it asks "what a_y would this tire utilisation have
% produced on the flat?"
%
% Direction check: on a favourable bank Fz_actual > Fz_flat, so a_y,flat is LOWER
% than measured - the bank's help is removed. Over a crest Fz_actual < Fz_flat
% and a_y,flat is HIGHER - the tire was working harder than the raw number looks.
%
% ROAD GEOMETRY ONLY, deliberately - longitudinal transfer is left alone.
%
% The first version of this used the full observed axle load, which also carries
% the m*a_x*h/L transfer term, and that was wrong in a way worth recording. On a
% straight at full throttle the front axle is unloaded, the ratio drops well
% below 1, and every small a_y in that bin gets scaled UP. Worse, a p99 envelope
% then preferentially selects exactly those samples - the most unloaded ones -
% so the corrected envelope spiked to 19 m/s^2 at 62 m/s where the car was going
% in a straight line. A selection artifact, not a tire limit.
%
% So the ratio below is built from az_road and aero only. az_road is 9.81 on flat
% level ground and departs from it exactly through the gravity projection (bank
% and pitch) and the a_z crest/dip term - which is precisely the pair being
% stripped, and nothing else.
%
% WHAT THIS STILL DOES NOT FIX. Simultaneous F_x eats the friction circle, and no
% F_z scaling undoes that, so trail-braking and corner-exit samples still sit
% below their pure-lateral potential. And a few turn-in transients sit above the
% model because it assumes a balanced yaw moment while Iz*rdot is real. Those are
% the residual, not something this correction is meant to remove.

Fz_f_flat = a .* (m * 9.81) ./ L + front_aero;
Fz_r_flat = b .* (m * 9.81) ./ L + rear_aero;

Fz_f_geo  = a .* (m .* az_road) ./ L + front_aero;
Fz_r_geo  = b .* (m .* az_road) ./ L + rear_aero;

%% fig S13 - one tab per a_y definition
%
% Three separate tabs rather than three curves on one pair of axes. They are the
% SAME measurement with successively more of the road taken out, so overlaying
% them buried the scatter under near-parallel lines and made the one comparison
% that matters - measured against the modelled tire limit - hard to read. Each
% tab now carries its own scatter, its own envelope, and the model.
%
%   a       ay_body   raw kinematic. The gravity ASSIST is still in it, so a
%                     banked corner flatters the car. This is what the car pulled.
%   b       ay_tire   assist removed. The lateral force the TIRES actually make.
%   c       ay_flat   assist AND the bank's normal-load boost removed, so it is
%                     on the same flat-road basis as the model. The like-for-like
%                     comparison, and the only one where sitting above the green
%                     line means the model is wrong.
%
% The console prints the p99 of all three against the model, so the tabs and the
% numbers agree.

ayvx_axles = { ...
    "Front", alpha_f_deg, validFront, "\alpha_f", Fz_f_flat, Fz_f_geo; ...
    "Rear",  alpha_r_deg, validRear,  "\alpha_r", Fz_r_flat, Fz_r_geo};

% key, tab title, y label, whether to gate to cornering samples
ayvx_variants = { ...
    "body", 'Fig S13a - a_y vs Speed (with gravity assist)', ...
        "a_y with gravity assist [m/s^2]", false; ...
    "tire", 'Fig S13b - a_y vs Speed (gravity assist removed)', ...
        "a_y at the tires [m/s^2]", false; ...
    "flat", 'Fig S13c - a_y vs Speed (flat-road equivalent)', ...
        "a_y, flat-road equivalent [m/s^2]", true};

nAyVar = size(ayvx_variants, 1);
axS13  = gobjects(2, nAyVar);

for iVar = 1:nAyVar

    varKey   = ayvx_variants{iVar,1};
    varTitle = ayvx_variants{iVar,2};
    varYLab  = ayvx_variants{iVar,3};
    varGate  = ayvx_variants{iVar,4};

    parentS13v = newFigTab(FG, "maps", varTitle);

    layoutS13v = tiledlayout(parentS13v, 1, 2, ...
        "TileSpacing", "compact", "Padding", "compact");

    for iAxle = 1:2

        axleName   = ayvx_axles{iAxle,1};
        alphaDeg   = ayvx_axles{iAxle,2};
        axleValid  = ayvx_axles{iAxle,3};
        alphaSym   = ayvx_axles{iAxle,4};
        FzFlat     = ayvx_axles{iAxle,5};
        FzGeo      = ayvx_axles{iAxle,6};

        % Guarded: an axle momentarily near zero load would otherwise send the
        % flat-equivalent to infinity.
        roadRatio = FzGeo ./ FzFlat;
        roadRatio(~isfinite(roadRatio) ...
            | roadRatio < ayvx_flatRatioRange(1) ...
            | roadRatio > ayvx_flatRatioRange(2)) = NaN;

        switch varKey
            case "body",  ayVar = ay_body;
            case "tire",  ayVar = ay_tire;
            case "flat",  ayVar = ay_tire ./ roadRatio;
        end

        keep = axleValid & isfinite(Fvx) & isfinite(ayVar) & isfinite(alphaDeg) ...
             & pureLat;

        % The flat-road variant divides by the road-geometry ratio, so a sample
        % taken over a crest gets scaled up hard. Harmless in itself, but a p99
        % then preferentially picks exactly those, and on a straight that grows
        % a spike where the car was not cornering. Only that variant is gated.
        if varGate && ayvx_flatMinAy > 0
            keep = keep & abs(ay_tire) > ayvx_flatMinAy;
        end

        axS13(iAxle,iVar) = nexttile(layoutS13v);

        scatter(Fvx(keep), ayVar(keep), 14, alphaDeg(keep), "filled", ...
            "HandleVisibility", "off");
        hold on

        yline(0, "k--", "HandleVisibility", "off");

        yline(g,  ":", "1 g", "Color", [0.35 0.35 0.35], ...
            "LabelHorizontalAlignment", "left", "HandleVisibility", "off");
        yline(-g, ":", "-1 g", "Color", [0.35 0.35 0.35], ...
            "LabelHorizontalAlignment", "left", "HandleVisibility", "off");

        hModel     = gobjects(0);
        hModelTrim = gobjects(0);

        if latEnv_loaded

            % Clipped to the speed the car actually reached. The CSV runs to
            % 100 m/s because brake_bias_schedule.m sweeps that far, but this
            % log tops out near 65, and letting the model set the x limit
            % squashes every measured point into the left of the panel.
            envDraw = latEnv_v <= max(Fvx(keep)) + ayvx_speedBinWidth;

            hModel = plot(latEnv_v(envDraw),  latEnv_ay(envDraw), ...
                "-", "LineWidth", 2.0, "Color", [0.00 0.50 0.25]);
            plot(latEnv_v(envDraw), -latEnv_ay(envDraw), ...
                "-", "LineWidth", 2.0, "Color", [0.00 0.50 0.25], ...
                "HandleVisibility", "off");

            if any(isfinite(latEnv_ayTrim))
                hModelTrim = plot(latEnv_v(envDraw),  latEnv_ayTrim(envDraw), ...
                    "--", "LineWidth", 1.5, "Color", [0.85 0.45 0.10]);
                plot(latEnv_v(envDraw), -latEnv_ayTrim(envDraw), ...
                    "--", "LineWidth", 1.5, "Color", [0.85 0.45 0.10], ...
                    "HandleVisibility", "off");
            end
        end

        xlim(axS13(iAxle,iVar), [0 max(Fvx(keep)) + ayvx_speedBinWidth]);

        grid on
        box on

        xlabel("Speed v_x [m/s]");
        ylabel(varYLab);
        title(sprintf("%s axle - coloured by %s", axleName, alphaSym), ...
            "FontWeight", "bold");

        colormap(axS13(iAxle,iVar), slipAngleColormap(256));
        clim(axS13(iAxle,iVar), [-alphaLim alphaLim]);

        set(axS13(iAxle,iVar), "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);

        % Handle/label pairs built together, so they cannot drift apart.
        % Letting legend pick up whatever is visible silently mislabels every
        % curve the moment the number of objects and the number of strings
        % disagree, which is how the model lines got swapped once already.
        legHandles = gobjects(0);
        legLabels  = strings(0);

        if ~isempty(hModel)
            legHandles = [legHandles, hModel];
            legLabels  = [legLabels, "model: tire limit"];
        end

        if ~isempty(hModelTrim)
            legHandles = [legHandles, hModelTrim];
            legLabels  = [legLabels, "model: holding speed"];
        end

        if iAxle == 1 && ~isempty(legHandles)
            lgdS13 = legend(legHandles, legLabels, "Orientation", "horizontal");
            lgdS13.Layout.Tile = "south";
        end
    end

    cbS13 = colorbar(axS13(2,iVar));
    cbS13.Layout.Tile = "east";
    ylabel(cbS13, "Slip angle [deg]");
    cbS13.Ticks = round(linspace(-alphaLim, alphaLim, 9), 2);

    title(layoutS13v, sprintf("%s   (%s)", varTitle(11:end), pureLat_label), ...
        "FontWeight", "bold");

    linkaxes(axS13(:,iVar), "xy");
end

% How much of the modelled limit the car actually used, per speed bin. This is
% the number the figure exists to produce - the same "% used" the longitudinal
% envelope reports in fig E1.
if latEnv_loaded

    % Front axle, on both bases. The flat-road-equivalent row is the meaningful
    % comparison - the raw row is kept alongside so the size of the road-geometry
    % correction is visible rather than silently applied.
    ayUse_ratio = Fz_f_geo ./ Fz_f_flat;
    ayUse_ratio(~isfinite(ayUse_ratio) ...
        | ayUse_ratio < ayvx_flatRatioRange(1) ...
        | ayUse_ratio > ayvx_flatRatioRange(2)) = NaN;

    ayUse_flat = ay_tire ./ ayUse_ratio;

    ayUse_valid = validFront & isfinite(Fvx) & isfinite(ay_tire) & Fvx > 10 & pureLat;

    ayUse_model = interp1(latEnv_v, latEnv_ay, Fvx(ayUse_valid), "linear", NaN);
    ayUse_raw   = abs(ay_tire(ayUse_valid));
    ayUse_flatV = abs(ayUse_flat(ayUse_valid));

    ayUse_ok = isfinite(ayUse_model) & ayUse_model > 0 & isfinite(ayUse_flatV);

    % Same population as the other two tabs; see ayvx_flatMinAy.
    ayUse_corner = ayUse_ok & ayUse_raw > ayvx_flatMinAy;

    fprintf("lateral envelope usage (front axle, %d samples):\n", sum(ayUse_ok));
    fprintf("  as measured           p99 %.0f%%  peak %.0f%%  of the modelled limit\n", ...
        100 * prctile(ayUse_raw(ayUse_ok) ./ ayUse_model(ayUse_ok), ayvx_envelopePct), ...
        100 * max(ayUse_raw(ayUse_ok) ./ ayUse_model(ayUse_ok)));
    fprintf("  flat-road equivalent  p99 %.0f%%  peak %.0f%%   <- the like-for-like number\n", ...
        100 * prctile(ayUse_flatV(ayUse_corner) ./ ayUse_model(ayUse_corner), ayvx_envelopePct), ...
        100 * max(ayUse_flatV(ayUse_corner) ./ ayUse_model(ayUse_corner)));
    fprintf("    (cornering samples only, |a_y| > %.1f m/s^2: %d of %d)\n", ...
        ayvx_flatMinAy, sum(ayUse_corner), sum(ayUse_ok));
    fprintf("  road geometry was worth a median %+.1f%% of normal load on the front axle\n", ...
        100 * (median(ayUse_ratio(ayUse_valid), "omitnan") - 1));

    % THE TWO HALVES OF THE BANK CORRECTION, separated.
    %
    % A bank helps the car twice and they are removed at different places, so it
    % is worth showing them apart rather than as one lump:
    %
    %   1. the gravity ASSIST - g*cos(pitch)*sin(roll) turning the car for free.
    %      Removed by useBankCorrection when ay_tire is built, far above.
    %   2. the normal-load BOOST - the same bank pressing the car into the road,
    %      raising F_z and so raising the force the tires can make. Removed by
    %      the flat-road-equivalent scaling here.
    %
    % Neither alone is the whole road effect, and on this log they are close to
    % the same size, so stripping only the assist leaves most of the job undone.
    ayHalf_raw  = abs(ay_body(ayUse_valid));
    ayHalf_tire = abs(ay_tire(ayUse_valid));
    ayHalf_flat = abs(ayUse_flat(ayUse_valid));

    ayHalf_ok = ayUse_corner;

    fprintf("  the road's two halves, p99 a_y over cornering samples:\n");
    fprintf("    raw kinematic (nothing removed)   %5.2f m/s^2  %3.0f%% of model\n", ...
        prctile(ayHalf_raw(ayHalf_ok), ayvx_envelopePct), ...
        100 * prctile(ayHalf_raw(ayHalf_ok) ./ ayUse_model(ayHalf_ok), ayvx_envelopePct));
    fprintf("    gravity assist removed            %5.2f m/s^2  %3.0f%%\n", ...
        prctile(ayHalf_tire(ayHalf_ok), ayvx_envelopePct), ...
        100 * prctile(ayHalf_tire(ayHalf_ok) ./ ayUse_model(ayHalf_ok), ayvx_envelopePct));
    fprintf("    + normal-load boost removed       %5.2f m/s^2  %3.0f%%\n", ...
        prctile(ayHalf_flat(ayHalf_ok), ayvx_envelopePct), ...
        100 * prctile(ayHalf_flat(ayHalf_ok) ./ ayUse_model(ayHalf_ok), ayvx_envelopePct));
end

fprintf("fig S13 (a_y vs v_x, %s): front %d, rear %d samples, slip angle colour scale +/-%.2f deg\n", ...
    pureLat_label, ...
    sum(validFront & isfinite(Fvx) & isfinite(ay_tire) & pureLat), ...
    sum(validRear  & isfinite(Fvx) & isfinite(ay_tire) & pureLat), alphaLim);

% A fixed colour range can hide data by saturating it, so say how much it hides.
alphaClipF = validFront & isfinite(alpha_f_deg) & abs(alpha_f_deg) > alphaLim;
alphaClipR = validRear  & isfinite(alpha_r_deg) & abs(alpha_r_deg) > alphaLim;

fprintf("  clipped at the colour limits: front %.2f%%, rear %.2f%% of samples " + ...
    "(p99 |alpha| front %.2f deg, rear %.2f deg)\n", ...
    100 * sum(alphaClipF) / max(sum(validFront & isfinite(alpha_f_deg)), 1), ...
    100 * sum(alphaClipR) / max(sum(validRear  & isfinite(alpha_r_deg)), 1), ...
    prctile(abs(alpha_f_deg(validFront)), 99), ...
    prctile(abs(alpha_r_deg(validRear)),  99));

%% TIRE-LIMITED LONGITUDINAL ACCELERATION ENVELOPE
%
% What this is: the a_x the TIRES allow at a given speed, for both signs. It is
% not what the car will do - the engine limit is well below this in first and
% second gear, and the brake hardware may not reach the bias the decel side
% wants - so it is a ceiling to be intersected with those, not a prediction.
%
% MU IS AN INPUT HERE, not something this section fits. The measured slip curve
% is still drawn - fig E1's left panel - so you can see what these numbers are
% being set against, but nothing reads a percentile off it any more. Set them
% by eye from that panel, or from a rig, and keep them in step with P.muF /
% P.muR / P.muR_drive in brake_bias_schedule.m, which are the same three
% quantities used by the same physics.
%
% Three, not two, because the rear tire does not read the same on power as on
% the brakes and each regime should use its own number:
%
%   drive, rear    the car is RWD, so the whole of Fx is rear and no brake
%                  split divides into it. The trustworthy one.
%
%   brake, front   only ever seen through the measured brake bias, which the
%                  Fx-split section flags as the weak link.
%
%   brake, rear    same caveat.
%
% F_z comes from the same load model the slip curve was normalised by - static
% split, longitudinal transfer m*a*cg_z/L, and aero - so the mu you read off
% that panel is being divided and multiplied by consistent loads.
%
% The solve is implicit: grip depends on load, load depends on a_x, a_x depends
% on grip. Fixed-point iteration, which converges because each pass multiplies
% the error by mu*cg_z/L (driving) or (mu_f-mu_r)*cg_z/L (braking), both well
% inside 1.
%
% Deceleration is distributed the way the car really distributes it, and only
% that way: the front/rear split comes from the bias the controller will
% command, read out of lut/brake_bias_map_grid.csv at this speed and decel, and
% engine braking is added at the REAR because that is where the driveline puts
% it. Whichever axle that combination saturates first caps the car; the other
% is left with grip on the table.
%
% There is deliberately no ideal-bias curve. That one answers "what could the
% tires do if the bias were free", which is a different question from "what
% will this car do", and mixing the two on one plot only invites reading the
% optimistic line as the answer.

mu_rear_drive_peak  = 1.35;   % P.muR_drive in brake_bias_schedule.m
mu_front_brake_peak = 0.95;    % P.muF
mu_rear_brake_peak  = 1.35;    % P.muR

envelope_speedStep_mps  = 4;
envelope_speedMax_mps   = 88;
envelope_maxIter        = 200;
envelope_tol            = 1e-9;

% Brake bias for the second decel curve comes from the schedule the car
% actually runs - lut/brake_bias_map_grid.csv, written by brake_bias_schedule.m
% - rather than a single held number. The file is PRESSURE bias on a
% (decel, speed) grid; it is converted to the FORCE bias this solve needs by
% the same gain-and-radius chain the Fx split section uses. The fallback is
% only reached if the file is missing.
envelope_biasLutFile  = "brake_bias_map_grid.csv";
envelope_biasFallback = defaultFrontBrakeBias;
envelope_biasRelax    = 0.5;   % damping on the coupled bias/decel iteration

% Engine braking. A closed throttle retards through the driveline, which on a
% RWD car is a REAR-ONLY force, so it does not add to the tire limit - it
% SPENDS rear grip that the calipers would otherwise have had. That makes it
% invisible in the ideal-bias curve and costly in the scheduled one, because
% the bias schedule does not know the driveline is already using part of the
% rear.
%
% Which gear the car is in sets how much of it there is, so the shift schedule
% is needed. These are pasted straight from the vehicle config, which counts
% gear 0 first - entry g+1 is gear g. Only the lower bounds are read here: a
% car that is slowing crosses the DOWNSHIFT bound, never the upshift one.
envelope_engineBraking = true;

envelope_gearRatio    = [2.9167; 1.8667; 1.3750; 1.1111; 0.9524; 0.8889];
envelope_finalDrive   = 3.0;

envelope_lbRpm = [0.0, 0.0, 3780.0, 4460.0, 4960.0, 5080.0, 5290.0];   % lb_rpm, 30 psi
envelope_ubRpm = [0.0, 7000.0, 7000.0, 7000.0, 6750.0, 6420.0, 7000.0]; % ub_rpm, kept for reference

envelope_export = true;
envelope_file   = "tire_limit_ax_vs_speed.csv";

% Curves computed elsewhere, drawn on the envelope panel. All three are the
% same shape - v_mps in the first column, an a_x in the second, signed as
% plotted - so one loader reads all of them and a missing file just leaves that
% curve off.
%
%   tire accel / decel   brake_bias_schedule.m, from lut/. Grip and F = ma.
%
%   engine accel         what the DRIVELINE can deliver, from the GGV
%                        engine-potential sweep. Independent of the tires
%                        entirely, so where it sits below the tire curve the
%                        car is torque-limited rather than grip-limited, and
%                        that is the whole point of putting them together.
% Suffixed by grip level - see envelope_gripLevel where the lateral envelope is
% loaded. brake_bias_schedule.m no longer writes unsuffixed versions of these.
envelope_compareAccelFile = "max_accel_vs_speed_" + envelope_gripLevel + ".csv";
envelope_compareDecelFile = "max_decel_vs_speed_" + envelope_gripLevel + ".csv";
envelope_compareEngineFile = ...
    "/home/elijah/PurdueRacing/GGV_stuff/Engine_potential/ax_max_engine30_vs_speed.csv";

envelope_scriptDir = fileparts(mfilename('fullpath'));

if isempty(envelope_scriptDir)
    envelope_scriptDir = pwd;   % running the cell by hand rather than the file
end

envelope_dir = fullfile(envelope_scriptDir, "lut");

%% measured mu samples, for the slip curve in fig E1
% Only the scatter. Nothing here is fitted and nothing feeds the envelope - the
% mu it runs on are the constants set above. This is the picture those
% constants get drawn over.

Fz_axle_total = Fz_front_norm + Fz_rear_norm;

% Same samples the exported slip curve is built from. lowSpeedMask matters:
% below vx_min_slip_ratio the wheel-speed channels are too noisy to divide by,
% which is exactly the regime a slip ratio is most sensitive to.
muBase = pureLong & seamValid & speedValid & biasValid & ~lowSpeedMask;

mu_rearDrive  =  Fxr      ./ Fz_rear_norm;
mu_frontBrake = -Fxf      ./ Fz_front_norm;
mu_rearBrake  = -Fxr      ./ Fz_rear_norm;

keep_rearDrive  = muBase & driveMode & Fz_rear_norm  > 0 ...
                & isfinite(mu_rearDrive);
keep_frontBrake = muBase & brakeMode & Fz_front_norm > 0 ...
                & isfinite(mu_frontBrake);
keep_rearBrake  = muBase & brakeMode & Fz_rear_norm  > 0 ...
                & isfinite(mu_rearBrake);

fprintf("\nENVELOPE MU (set by hand, not fitted)\n");
fprintf("  drive rear %.3f | brake front %.3f | brake rear %.3f\n", ...
    mu_rear_drive_peak, mu_front_brake_peak, mu_rear_brake_peak);
fprintf("  slip curve drawn from %d drive, %d front-brake, %d rear-brake samples\n", ...
    sum(keep_rearDrive), sum(keep_frontBrake), sum(keep_rearBrake));

%% brake bias schedule
% Read the same way lookupEngineTorque reads an engine map: the header row by
% hand for the speed breakpoints, the body through readmatrix. Rows are the
% commanded decel, columns are speed, cells are the front PRESSURE bias.
%
% Two things about this file are worth knowing before its numbers are trusted.
% It was solved with its own grip assumption (P.muF/P.muR in
% brake_bias_schedule.m), so if that does not match the mu measured above, the
% schedule is distributing brake force by the wrong ratio and the decel curve
% it produces will sit below the ideal-bias one. And it already holds its edge
% values past a_max and below the drag cut-in, so clamping onto the grid
% continues the file's own convention rather than inventing an extrapolation.

biasLut_path   = fullfile(envelope_dir, envelope_biasLutFile);
biasLut_loaded = isfile(biasLut_path);

if biasLut_loaded

    fid = fopen(biasLut_path, 'r');
    biasLut_headerLine = fgetl(fid);
    fclose(fid);

    biasLut_speed = str2double(strsplit(strtrim(biasLut_headerLine), ','));
    biasLut_speed = biasLut_speed(2:end);   % first cell names the decel column

    biasLut_raw = readmatrix(biasLut_path);
    biasLut_raw = biasLut_raw(isfinite(biasLut_raw(:,1)), :);

    biasLut_decel = biasLut_raw(:,1);
    biasLut_press = biasLut_raw(:,2:end);

    if numel(biasLut_speed) ~= size(biasLut_press, 2)
        error("notmal_force_estimation:biasLutShape", ...
            "%s has %d bias columns but %d speed breakpoints in its header.", ...
            biasLut_path, size(biasLut_press,2), numel(biasLut_speed));
    end

    % Pressure bias -> force bias. A pressure makes torque through the caliper
    % gain and a force through the tire radius, so the axle with the smaller
    % radius makes more force per kPa and the force bias is not the pressure
    % bias. Same expression as the Fx split section, and it collapses to the
    % identity when the gains and radii match.
    brakeGainRatio = (vehicleParams.brakeGain_f / R_f) ...
                   / (vehicleParams.brakeGain_r / R_r);

    biasLut_force = brakeGainRatio .* biasLut_press ...
        ./ (brakeGainRatio .* biasLut_press + (1 - biasLut_press));

    fprintf("\nbrake bias schedule: %s\n", biasLut_path);
    fprintf("  %d decel x %d speed breakpoints, decel %.3g-%.3g m/s^2, speed %.3g-%.3g m/s\n", ...
        numel(biasLut_decel), numel(biasLut_speed), ...
        min(biasLut_decel), max(biasLut_decel), ...
        min(biasLut_speed), max(biasLut_speed));
    fprintf("  pressure bias %.3f-%.3f -> force bias %.3f-%.3f (gain/radius ratio %.4f)\n", ...
        min(biasLut_press(:)), max(biasLut_press(:)), ...
        min(biasLut_force(:)), max(biasLut_force(:)), brakeGainRatio);

else
    % A degenerate two-by-two grid, so the solve below takes one code path
    % whether or not the schedule was found.
    warning("notmal_force_estimation:noBiasLut", ...
        "%s not found; the scheduled-bias decel curve falls back to a held %.3f. " + ...
        "Run brake_bias_schedule.m to generate it.", ...
        biasLut_path, envelope_biasFallback);

    biasLut_speed = [0 1000];
    biasLut_decel = [0; 1000];
    biasLut_force = envelope_biasFallback * ones(2,2);
end

%% downshift speeds
% The speed at which each gear hands down to the one below, from its lower rpm
% bound. Coming down the speed range the car is in the highest gear whose
% downshift speed it is still above.

num_envelope_gears = numel(envelope_gearRatio);

if numel(envelope_lbRpm) ~= num_envelope_gears + 1
    error("notmal_force_estimation:gearScheduleShape", ...
        "envelope_lbRpm has %d entries; %d gears plus the leading gear-0 slot needs %d.", ...
        numel(envelope_lbRpm), num_envelope_gears, num_envelope_gears + 1);
end

envelope_downshiftSpeed = nan(num_envelope_gears, 1);

for gear = 1:num_envelope_gears
    envelope_downshiftSpeed(gear) = envelope_lbRpm(gear+1) ...
        / (envelope_gearRatio(gear) * envelope_finalDrive) ...
        * (2*pi/60) * vehicleParams.R_r;
end

if envelope_engineBraking
    fprintf("\ndownshift speeds [m/s]:");

    for gear = 2:num_envelope_gears
        fprintf("  %d->%d at %.1f", gear, gear-1, envelope_downshiftSpeed(gear));
    end

    fprintf("\n");
end

%% curves computed elsewhere, for comparison
% Two from brake_bias_schedule.m and one from the engine-potential sweep. Two
% columns each: v_mps first, an a_x second.

envelopeCompare_paths = [fullfile(envelope_dir, envelope_compareAccelFile), ...
                         fullfile(envelope_dir, envelope_compareDecelFile), ...
                         envelope_compareEngineFile];

envelopeCompare_names = ["tire accel", "tire decel", "engine accel"];

nCompare = numel(envelopeCompare_paths);

envelopeCompare_speed  = cell(1,nCompare);
envelopeCompare_ax     = cell(1,nCompare);
envelopeCompare_loaded = false(1,nCompare);

for iCmp = 1:nCompare

    cmpPath = envelopeCompare_paths(iCmp);

    if ~isfile(cmpPath)
        warning("notmal_force_estimation:missingCompareCurve", ...
            "%s not found; the %s curve is left off.", ...
            cmpPath, envelopeCompare_names(iCmp));
        continue
    end

    cmpTbl  = readtable(cmpPath);
    cmpVars = string(cmpTbl.Properties.VariableNames);

    % The speed column is checked by NAME and the a_x column is taken as the
    % only other one. Older runs of brake_bias_schedule.m wrote these files with
    % speed_kph second, and taking column 2 on faith would draw a speed as
    % though it were an acceleration - hence the width check rather than a
    % blind index.
    if numel(cmpVars) ~= 2 || cmpVars(1) ~= "v_mps"
        warning("notmal_force_estimation:compareCurveShape", ...
            "%s is not a two-column v_mps/a_x file (has %s). That curve is left off.", ...
            cmpPath, join(cmpVars, ", "));
        continue
    end

    cmpSpeed = cmpTbl.(char(cmpVars(1)));
    cmpAx    = cmpTbl.(char(cmpVars(2)));

    cmpKeep  = isfinite(cmpSpeed) & isfinite(cmpAx);

    if ~any(cmpKeep)
        warning("notmal_force_estimation:emptyCompareCurve", ...
            "%s has no usable rows; that curve is left off.", cmpPath);
        continue
    end

    envelopeCompare_speed{iCmp}  = cmpSpeed(cmpKeep);
    envelopeCompare_ax{iCmp}     = cmpAx(cmpKeep);
    envelopeCompare_loaded(iCmp) = true;

    fprintf("comparison %s curve: %s  (%d speeds, %.1f-%.1f m/s, a_x %.2f to %.2f)\n", ...
        envelopeCompare_names(iCmp), cmpPath, sum(cmpKeep), ...
        min(cmpSpeed(cmpKeep)), max(cmpSpeed(cmpKeep)), ...
        min(cmpAx(cmpKeep)), max(cmpAx(cmpKeep)));
end

%% envelope solve

envelope_speed_mps = (0 : envelope_speedStep_mps : envelope_speedMax_mps)';
nEnvelope          = numel(envelope_speed_mps);

env_axMax        = nan(nEnvelope,1);
env_axMin        = nan(nEnvelope,1);
env_downforce    = nan(nEnvelope,1);
env_FzRearDrive  = nan(nEnvelope,1);
env_FzFront      = nan(nEnvelope,1);
env_FzRear       = nan(nEnvelope,1);
env_gear         = nan(nEnvelope,1);
env_engineRpm    = nan(nEnvelope,1);
env_engineForce  = nan(nEnvelope,1);
env_biasSched    = nan(nEnvelope,1);
env_schedLimit   = strings(nEnvelope,1);
env_schedConverged = true(nEnvelope,1);

% Static axle loads from the same weight distribution the load transfer uses.
W_front = vehicleParams.w_dist_f       * m * g;
W_rear  = (1 - vehicleParams.w_dist_f) * m * g;

for iEnv = 1:nEnvelope

    speed = envelope_speed_mps(iEnv);

    F_drag = 0.5 * rho * CdA_drag          * speed^2;
    F_down = 0.5 * rho * vehicleParams.ACd * speed^2;

    F_down_f = aero_balance       * F_down;
    F_down_r = (1 - aero_balance) * F_down;

    % Drive: rear axle only. Two things load the driven axle beyond its static
    % share - longitudinal transfer, which ADDS here because the car is
    % squatting, and the rear share of the downforce. Drag is the only term
    % working against it, and with this car's CdA against its ACd the drag wins
    % as speed rises, so the drive limit falls with speed even though the rear
    % tires are being pushed down harder.
    accel = 0;

    for iter = 1:envelope_maxIter
        Fz_rear_drive = max(W_rear + m * accel * cgh / L + F_down_r, 0);
        accel_next    = (mu_rear_drive_peak * Fz_rear_drive - F_drag) / m;

        if abs(accel_next - accel) < envelope_tol
            accel = accel_next;
            break
        end

        accel = accel_next;
    end

    % Engine braking at this speed, in whatever gear the downshift schedule
    % leaves the car. Force by power balance, T*omega_engine / v_wheel, which
    % with no slip is just the ratio over the radius. Losses are left out, the
    % same assumption the log-side engine split makes; carrying them would make
    % this force slightly LARGER, so the rear cost below is a floor.
    if envelope_engineBraking

        gearDecel = 1;

        for gearTry = num_envelope_gears:-1:2
            if speed >= envelope_downshiftSpeed(gearTry)
                gearDecel = gearTry;
                break
            end
        end

        rpmDecel = speed / vehicleParams.R_r * (60/(2*pi)) ...
                 * envelope_gearRatio(gearDecel) * envelope_finalDrive;

        T_engineBrake = engineMap_scale * lookupEngineTorque( ...
            engineMapFile, engineMap_throttleBreaks, rpmDecel, 0);

        % Closed-throttle torque is negative; keep it as a positive retarding
        % force and never let a positive map value push the car along.
        F_engineBrake = max(-T_engineBrake * envelope_gearRatio(gearDecel) ...
            * envelope_finalDrive / vehicleParams.R_driveline, 0);
    else
        gearDecel     = NaN;
        rpmDecel      = NaN;
        F_engineBrake = 0;
    end


    % Brake, scheduled bias: the split the car will actually command at this
    % speed and decel, so whichever axle the schedule overworks caps the car
    % and the other one is left with grip on the table. The bias depends on the
    % decel and the decel depends on the bias, so the lookup sits inside the
    % same fixed point. Damped, because the LUT is piecewise linear and an
    % undamped step can hop back and forth across a breakpoint forever.
    decelSched    = 0;
    schedSettled  = false;

    for iter = 1:envelope_maxIter

        Fz_f_sched = max(W_front + m * decelSched * cgh / L + F_down_f, 0);
        Fz_r_sched = max(W_rear  - m * decelSched * cgh / L + F_down_r, 0);

        biasSched = scheduledFrontBias(biasLut_speed, biasLut_decel, ...
            biasLut_force, speed, decelSched);

        % The schedule splits CALIPER force, so the rear's share is capped by
        % what the driveline has left it, not by the whole rear grip.
        brakeForce = min(mu_front_brake_peak * Fz_f_sched / biasSched, ...
            max(mu_rear_brake_peak * Fz_r_sched - F_engineBrake, 0) / (1 - biasSched));

        decelSched_next = decelSched + envelope_biasRelax ...
            * ((brakeForce + F_engineBrake + F_drag) / m - decelSched);

        if abs(decelSched_next - decelSched) < envelope_tol
            decelSched   = decelSched_next;
            schedSettled = true;
            break
        end

        decelSched = decelSched_next;
    end

    Fz_f_sched = max(W_front + m * decelSched * cgh / L + F_down_f, 0);
    Fz_r_sched = max(W_rear  - m * decelSched * cgh / L + F_down_r, 0);

    biasSched = scheduledFrontBias(biasLut_speed, biasLut_decel, ...
        biasLut_force, speed, decelSched);

    if mu_front_brake_peak * Fz_f_sched / biasSched ...
            <= max(mu_rear_brake_peak * Fz_r_sched - F_engineBrake, 0) / (1 - biasSched)
        env_schedLimit(iEnv) = "front";
    else
        env_schedLimit(iEnv) = "rear";
    end

    if F_engineBrake > mu_rear_brake_peak * Fz_r_sched
        warning("notmal_force_estimation:engineBrakeOverRear", ...
            "At %.0f m/s engine braking alone (%.0f N) exceeds the rear grip " + ...
            "(%.0f N); the rear locks on a closed throttle before any brake is applied.", ...
            speed, F_engineBrake, mu_rear_brake_peak * Fz_r_sched);
    end

    env_axMax(iEnv)          =  accel;
    env_axMin(iEnv)          = -decelSched;
    env_downforce(iEnv)      =  F_down;
    env_FzRearDrive(iEnv)    =  max(W_rear + m * accel * cgh / L + F_down_r, 0);
    env_FzFront(iEnv)        =  Fz_f_sched;
    env_FzRear(iEnv)         =  Fz_r_sched;
    env_gear(iEnv)           =  gearDecel;
    env_engineRpm(iEnv)      =  rpmDecel;
    env_engineForce(iEnv)    =  F_engineBrake;
    env_biasSched(iEnv)      =  biasSched;
    env_schedConverged(iEnv) =  schedSettled;
end

if ~all(env_schedConverged)
    warning("notmal_force_estimation:biasSolveNotConverged", ...
        "The scheduled-bias decel solve hit %d iterations at %d of %d speeds; " + ...
        "lower envelope_biasRelax.", ...
        envelope_maxIter, sum(~env_schedConverged), nEnvelope);
end

envelope_table = table(envelope_speed_mps, ...
    round(env_axMax, 3), ...
    round(env_axMin, 3), ...
    round(env_downforce), ...
    round(env_FzRearDrive), ...
    round(env_FzFront), ...
    round(env_FzRear), ...
    env_gear, ...
    round(env_engineRpm), ...
    round(env_engineForce), ...
    round(env_biasSched, 4), ...
    env_schedLimit, ...
    'VariableNames', {'v_mps','ax_max_mps2','ax_min_mps2', ...
                      'downforce_N','Fz_rear_drive_N','Fz_front_brake_N','Fz_rear_brake_N', ...
                      'gear','engine_rpm','F_engine_brake_N', ...
                      'biasF_sched','limited_by'});

fprintf("\nTIRE-LIMITED a_x ENVELOPE  (drive mu_r %.3f | brake mu_f %.3f mu_r %.3f | " + ...
    "m %.0f kg, cg_z %.3f m, ACd %.2f, CdA %.2f)\n", ...
    mu_rear_drive_peak, mu_front_brake_peak, mu_rear_brake_peak, ...
    m, cgh, vehicleParams.ACd, CdA_drag);
fprintf("Decel is on the commanded bias schedule with engine braking at the rear;\n");
fprintf("Fz_rear_drive is the load at the DRIVE limit, Fz_*_brake at the DECEL limit\n");
disp(envelope_table)

for axleName = ["front", "rear"]
    nAxle = sum(env_schedLimit == axleName);

    if nAxle > 0
        fprintf("  the %s axle saturates first at %d of %d speeds\n", ...
            axleName, nAxle, nEnvelope);
    end
end

if envelope_engineBraking
    % The driveline takes this share of the rear before the calipers get any,
    % which is why the rear is usually the axle that gives out first.
    engShareRear = 100 * env_engineForce ./ max(mu_rear_brake_peak * env_FzRear, eps);

    fprintf("engine braking: %.0f-%.0f N through the rear, %.0f-%.0f%% of the rear grip, gears %d-%d\n", ...
        min(env_engineForce), max(env_engineForce), ...
        min(engShareRear), max(engShareRear), ...
        min(env_gear), max(env_gear));
end

% What the log actually reached, against the envelope at that same speed. The
% envelope is a percentile of the mu scatter, so a best-ever sample sitting
% above it is expected - a whole cloud sitting above it is not.
envCompare = isfinite(Fvx) & isfinite(Fax) & seamValid & Fvx > 0;

% Slip ratio behind those samples, so the cloud says not only where the car got
% to but how much the tires had to slide to do it. A point near the envelope at
% small slip is grip in hand; the same point at large slip is a tire already
% past its peak and on the way to locking or spinning.
%
%   "worst"  the axle slipping most, keeping its sign - answers "was anything
%            close to letting go", which is what a limit plot is for
%   "front"  / "rear"  that axle only
%
% Signed, on this script's convention kappa = (Vw - Vx)/Vw: positive is the
% wheel outrunning the road (driving), negative is the wheel held back
% (braking). That is why this gets a symmetric two-sided scale rather than the
% braking-only ramp figs S11 and S12 use - here both signs are in play.
envelope_slipColor = "worst";     % "worst" | "front" | "rear"

switch lower(string(envelope_slipColor))

    case "front"
        envSlip      = slip_ratio_f;
        envSlipLabel = "Front slip ratio \kappa_f [-]";

    case "rear"
        envSlip      = slip_ratio_r;
        envSlipLabel = "Rear slip ratio \kappa_r [-]";

    case "worst"
        % Pick by magnitude, but fall to whichever axle actually resolved when
        % the other is NaN - abs(NaN) >= x is false and would silently keep the
        % NaN.
        takeFront = (abs(slip_ratio_f) >= abs(slip_ratio_r)) ...
                  | (~isfinite(slip_ratio_r) & isfinite(slip_ratio_f));

        envSlip            = slip_ratio_r;
        envSlip(takeFront) = slip_ratio_f(takeFront);
        envSlipLabel       = "Slip ratio \kappa of the axle slipping most [-]";

    otherwise
        error("notmal_force_estimation:badEnvelopeSlipColor", ...
            "envelope_slipColor must be ""worst"", ""front"" or ""rear"", got ""%s"".", ...
            envelope_slipColor);
end

envSlipValid = envCompare & isfinite(envSlip);

% Symmetric limits so zero slip sits on the neutral middle of the colormap and
% a drive and a brake sample of the same size mirror each other.
%
% Fixed rather than fitted to the run, so the same colour means the same slip
% from one log to the next. +/-0.07 covers where the data actually sits - p99
% of |kappa| is about 0.034 on this log - so the ramp is spent on the range
% that matters and anything past it clamps to the ends. Set
% envelope_slipColorLimit = [] to go back to a robust auto-scale off the data.
envelope_slipColorLimit = 0.07;

if isempty(envelope_slipColorLimit)
    envSlipLimit = robustRange(envSlip(envSlipValid), 0.02);
    envSlipLimit = max(abs(envSlipLimit)) * [-1 1];
else
    envSlipLimit = abs(envelope_slipColorLimit) * [-1 1];
end

if ~(envSlipLimit(2) > 0)
    envSlipLimit = [-0.01 0.01];
end

fprintf("envelope slip colouring: %s, %d samples, scale +/-%.3f (|kappa| median %.4f, max %.3f)\n", ...
    envelope_slipColor, sum(envSlipValid), envSlipLimit(2), ...
    median(abs(envSlip(envSlipValid)), "omitnan"), max(abs(envSlip(envSlipValid))));

[axPeakDrive, iPeakDrive] = max(Fax(envCompare));
[axPeakBrake, iPeakBrake] = min(Fax(envCompare));

vxCompare = Fvx(envCompare);

fprintf("measured peak drive  %+.2f m/s^2 at %.1f m/s, envelope there %+.2f  (%.0f%% used)\n", ...
    axPeakDrive, vxCompare(iPeakDrive), ...
    interp1(envelope_speed_mps, env_axMax, vxCompare(iPeakDrive), "linear", "extrap"), ...
    100 * axPeakDrive / interp1(envelope_speed_mps, env_axMax, vxCompare(iPeakDrive), "linear", "extrap"));

fprintf("measured peak brake  %+.2f m/s^2 at %.1f m/s, envelope there %+.2f  (%.0f%% used)\n", ...
    axPeakBrake, vxCompare(iPeakBrake), ...
    interp1(envelope_speed_mps, env_axMin, vxCompare(iPeakBrake), "linear", "extrap"), ...
    100 * axPeakBrake / interp1(envelope_speed_mps, env_axMin, vxCompare(iPeakBrake), "linear", "extrap"));

if envelope_export

    if ~isfolder(envelope_dir)
        mkdir(envelope_dir);
    end

    envelope_path = fullfile(envelope_dir, envelope_file);

    writetable(envelope_table(:, {'v_mps','ax_max_mps2','ax_min_mps2'}), ...
        envelope_path);

    fprintf("wrote %s\n", envelope_path);
end

%% fig E1 - where the mu came from, and the envelope it produces

parentE1 = newFigTab(FG, "envelope", 'Fig E1 - Tire-Limited Longitudinal Acceleration Envelope');

layoutE1 = tiledlayout(parentE1, 1, 2, "TileSpacing", "compact", "Padding", "compact");

% Left: the measured slip curve, as measured. Both signs folded into the
% positive quadrant so the drive and brake branches can be compared directly.
axE1(1) = nexttile(layoutE1);
hold on

plot(abs(slip_ratio_r(keep_rearDrive)),  abs(mu_rearDrive(keep_rearDrive)), ...
    ".", "MarkerSize", 6, "Color", [0.10 0.45 0.70]);
plot(abs(slip_ratio_r(keep_rearBrake)),  abs(mu_rearBrake(keep_rearBrake)), ...
    ".", "MarkerSize", 6, "Color", [0.16 0.47 0.39]);
plot(abs(slip_ratio_f(keep_frontBrake)), abs(mu_frontBrake(keep_frontBrake)), ...
    ".", "MarkerSize", 6, "Color", [0.67 0.23 0.30]);

grid on
box on
xlim([0 0.08])
xlabel("|\kappa| [-]");
ylabel("|F_x / F_z| [-]");
title("Longitudinal slip vs friction, measured");
legend("rear, on power", "rear, on brakes", "front, on brakes", "Location", "southeast");

set(axE1(1), "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);

% Right: the envelope, with every sample of this run behind it.
axE1(2) = nexttile(layoutE1);
hold on

% Samples first so the limit curves draw over them. Coloured by slip ratio,
% and the samples whose slip never resolved are drawn in grey underneath
% rather than dropped, so the cloud keeps its true shape.
envSlipGrey = envCompare & ~isfinite(envSlip);

if any(envSlipGrey)
    plot(Fvx(envSlipGrey), Fax(envSlipGrey), ".", "MarkerSize", 4, ...
        "Color", [0.85 0.85 0.85], "HandleVisibility", "off");
end

scatter(Fvx(envSlipValid), Fax(envSlipValid), 12, envSlip(envSlipValid), "filled");

colormap(axE1(2), slipDivergingColormap(256));
caxis(axE1(2), envSlipLimit);

envLegend = "this run, coloured by slip";

% The curves are all computed elsewhere and read back from CSV. This script's
% own envelope is still solved, printed and exported below - it is just not
% plotted here.
%
% Tire accel and decel in blue and red, engine accel in dark green. The two
% acceleration curves are the interesting pair: the lower of them is what the
% car can actually do, and which one that is changes with speed.
%
% Drawn with a marker on every row of the CSV, so the dots are the data and the
% line between them is straight-line interpolation and nothing more. These
% files are on a 4 m/s grid, which is coarse enough that the difference matters
% - a peak between two breakpoints is not in the file and the line will cut
% straight across it.
envelopeCompare_colour = {[0.10 0.45 0.70], [0.67 0.23 0.30], [0.00 0.35 0.15]};

for iCmp = 1:nCompare
    if envelopeCompare_loaded(iCmp)

        plot(envelopeCompare_speed{iCmp}, envelopeCompare_ax{iCmp}, "-o", ...
            "LineWidth", 2.2, "Color", envelopeCompare_colour{iCmp}, ...
            "MarkerFaceColor", envelopeCompare_colour{iCmp}, ...
            "MarkerEdgeColor", "none", "MarkerSize", 7);

        envLegend(end+1) = envelopeCompare_names(iCmp); %#ok<SAGROW>
    end
end

yline(0, "-", "", "Color", [0.5 0.5 0.5], "HandleVisibility", "off");

grid on
box on
xlabel("Speed v_x [m/s]");
ylabel("a_x [m/s^2]");
title("Measured a_x against the brake\_bias\_schedule limits");

legend(envLegend, "Location", "east");

set(axE1(2), "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);

cbE1 = colorbar(axE1(2));
cbE1.Layout.Tile = "east";
ylabel(cbE1, envSlipLabel);

title(layoutE1, sprintf("Tire-limited a_x envelope   (drive \\mu_r %.3f, " + ...
    "brake \\mu_f %.3f / \\mu_r %.3f)", ...
    mu_rear_drive_peak, mu_front_brake_peak, mu_rear_brake_peak), ...
    "FontWeight", "bold");

%% fig E2 - the same envelope, one panel per tire
% Same axes and the same limit curves as fig E1's right panel, but each panel
% is coloured by that ONE tire's slip ratio instead of the worst of the two
% axles. That is what separates a car sliding evenly from one dragging a single
% corner: a locked front left shows up here and nowhere else, because the
% axle-level view averages it away with its partner.
%
% The engine curve is drawn on the REAR panels only. It is a driveline limit,
% and on a RWD car the front tires have no part in putting that torque down -
% plotting it against a front slip ratio would invite reading a relationship
% that is not there.
%
% One colour scale across all four, so the panels can be read against each
% other rather than each one auto-scaling to its own worst corner.

parentE2 = newFigTab(FG, "envelope", 'Fig E2 - Envelope per tire, coloured by that tire''s slip');

layoutE2 = tiledlayout(parentE2, 2, 2, "TileSpacing", "compact", "Padding", "compact");

axE2     = gobjects(4,1);
hE2      = gobjects(0);
labelsE2 = strings(0);

for tire = 1:4

    isRearTire = tire >= 3;

    kappaTire = kappa_per_tire{tire};
    keepTire  = envCompare & isfinite(kappaTire);

    axE2(tire) = nexttile(layoutE2);
    hold on

    hSamplesE2 = scatter(Fvx(keepTire), Fax(keepTire), 10, ...
        kappaTire(keepTire), "filled");

    colormap(axE2(tire), slipDivergingColormap(256));
    caxis(axE2(tire), envSlipLimit);

    for iCmp = 1:nCompare

        % Index 3 is the engine curve: rear panels only.
        if ~envelopeCompare_loaded(iCmp) || (iCmp == 3 && ~isRearTire)
            continue
        end

        hCurveE2 = plot(envelopeCompare_speed{iCmp}, envelopeCompare_ax{iCmp}, ...
            "-o", "LineWidth", 1.8, "Color", envelopeCompare_colour{iCmp}, ...
            "MarkerFaceColor", envelopeCompare_colour{iCmp}, ...
            "MarkerEdgeColor", "none", "MarkerSize", 4);

        % The legend is built off the last rear panel, which is the one that
        % carries every curve appearing anywhere in the figure.
        if tire == 4
            hE2(end+1)      = hCurveE2;                       %#ok<SAGROW>
            labelsE2(end+1) = envelopeCompare_names(iCmp);    %#ok<SAGROW>
        end
    end

    if tire == 4
        hE2      = [hSamplesE2, hE2];
        labelsE2 = ["this run, coloured by slip", labelsE2];
    end

    yline(0, "-", "", "Color", [0.5 0.5 0.5], "HandleVisibility", "off");

    grid on
    box on
    title(tire_names(tire));

    if isRearTire
        xlabel("Speed v_x [m/s]");
    end

    if mod(tire, 2) == 1
        ylabel("a_x [m/s^2]");
    end

    set(axE2(tire), "FontSize", 10, "LineWidth", 0.8, "GridAlpha", 0.20);
end

linkaxes(axE2, "xy");

cbE2 = colorbar(axE2(4));
cbE2.Layout.Tile = "east";
ylabel(cbE2, "Slip ratio \kappa [-]");

if ~isempty(hE2)
    lgdE2 = legend(hE2, labelsE2, "Orientation", "horizontal");
    lgdE2.Layout.Tile = "south";
end

title(layoutE2, "Vehicle Limit", "FontWeight", "bold");

%% tidy the figure windows
% Close any group that ended up with no tabs (plot_per_tire = false leaves the
% per-tire groups empty), then bring the first window forward.
pruneEmptyFigureGroups(FG);

if figureGrouping
    fprintf("\nfigure windows:\n");

    for iGroup = 1:numel(FG.keys)

        if isgraphics(FG.tabgroup(iGroup))
            fprintf("  %-40s %d tabs\n", FG.titles(iGroup), ...
                numel(FG.tabgroup(iGroup).Children));
        end
    end

    if isgraphics(FG.figure(1))
        figure(FG.figure(1));
    end
end


function observer = initDualTrackFzDerivativeObserver()

    observer.K = [ ...
        1.5, ... % FL
        1.5, ... % FR
        1.5, ... % RL
        1.5  ... % RR
    ];

    % Low-pass filter applied before calculating derivatives.
    % Larger value gives smoother signals but more delay.
    observer.tau_signal = 0.05;       % seconds

    % Time over which observer correction decays toward the model.
    % Larger value allows corrections to remain longer.
    observer.tau_correction = 1;    % seconds

    % Ignore very small derivative disagreement.
    observer.rate_deadband = [ ...
        40, 40, 40, 40 ...           % N/s
    ];

    % Reject strain-gage spikes
    observer.max_rate_error = [ ...
        120000, 120000, 150000, 150000 ... % N/s
    ];

    % Maximum speed at which the correction can move
    observer.max_correction_rate = [ ...
        25000, 25000, 30000, 30000 ...   % N/s
    ];

    % Maximum total observer correction
    observer.max_correction = [ ...
        10000, 10000, 13000, 13000 ...   % N
    ];

    % Setting this true forces the four corrections to sum to zero.
    % Leave false initially because bumps and heave can change total load.
    observer.enforce_zero_total_correction = false;

    observer.measured_filtered = nan(1,4);
    observer.model_filtered = nan(1,4);

    observer.previous_residual = nan(1,4);
    observer.dynamic_correction = zeros(1,4);

    observer.initialized = false;
end


function [observer, output] = dualTrackFzDerivativeObserverUpdate( ...
    observer, measurement, model, dt)
% Updates the four-tire derivative normal-force observer.
%
% Inputs:
%   measurement = raw or lightly filtered strain-gage forces
%   model       = dual-track model forces
%   dt          = current timestep
%
% Tire order:
%   [FL, FR, RL, RR]

    measurement = measurement(:).';
    model = model(:).';

    if ~observer.initialized

        bad_model = ~isfinite(model);
        model(bad_model) = 0;

        bad_measurement = ~isfinite(measurement);
        measurement(bad_measurement) = model(bad_measurement);

        observer.measured_filtered = measurement;
        observer.model_filtered = model;

        observer.previous_residual = measurement - model;
        observer.dynamic_correction = zeros(1,4);

        Fz_hat = max(model, 0);

        observer.initialized = true;

        output.Fz_hat = Fz_hat;
        output.dynamic_correction = observer.dynamic_correction;
        output.dFz_measured = zeros(1,4);
        output.dFz_model = zeros(1,4);
        output.rate_error = zeros(1,4);

        return
    end

    % Replace missing samples with the previous filtered values
    bad_measurement = ~isfinite(measurement);
    measurement(bad_measurement) = ...
        observer.measured_filtered(bad_measurement);

    bad_model = ~isfinite(model);
    model(bad_model) = observer.model_filtered(bad_model);

    previous_measured_filtered = observer.measured_filtered;
    previous_model_filtered = observer.model_filtered;

    % First-order low-pass filtering before differentiation
    alpha_signal = dt / (observer.tau_signal + dt);

    observer.measured_filtered = ...
        previous_measured_filtered ...
        + alpha_signal .* ...
        (measurement - previous_measured_filtered);

    observer.model_filtered = ...
        previous_model_filtered ...
        + alpha_signal .* ...
        (model - previous_model_filtered);

    % Derivatives for logging and error calculation
    dFz_measured = ...
        (observer.measured_filtered ...
        - previous_measured_filtered) ./ dt;

    dFz_model = ...
        (observer.model_filtered ...
        - previous_model_filtered) ./ dt;

    rate_error = dFz_measured - dFz_model;

    % Deadband removes small derivative noise
    rate_error_used = sign(rate_error) .* max( ...
        abs(rate_error) - observer.rate_deadband, ...
        0);

    % Reject extreme derivative spikes
    rate_error_used = clampArray( ...
        rate_error_used, ...
        -observer.max_rate_error, ...
         observer.max_rate_error);

    % Equivalent residual change.
    % Using residual change avoids unnecessarily integrating a noisy
    % numerical derivative.
    residual = ...
        observer.measured_filtered ...
        - observer.model_filtered;

    delta_residual = residual - observer.previous_residual;

    % Use the limited derivative error to create a limited residual change
    delta_residual_used = rate_error_used .* dt;

    % Leaky derivative/high-pass observer
    alpha_correction = ...
        observer.tau_correction ...
        / (observer.tau_correction + dt);

    correction_candidate = alpha_correction .* ( ...
        observer.dynamic_correction ...
        + observer.K .* delta_residual_used);

    % Limit correction movement per timestep
    correction_change = ...
        correction_candidate ...
        - observer.dynamic_correction;

    maximum_change = observer.max_correction_rate .* dt;

    correction_change = clampArray( ...
        correction_change, ...
        -maximum_change, ...
         maximum_change);

    observer.dynamic_correction = ...
        observer.dynamic_correction ...
        + correction_change;

    % Limit total correction
    observer.dynamic_correction = clampArray( ...
        observer.dynamic_correction, ...
        -observer.max_correction, ...
         observer.max_correction);

    % Optional conservation constraint
    if observer.enforce_zero_total_correction
        observer.dynamic_correction = ...
            observer.dynamic_correction ...
            - mean(observer.dynamic_correction);
    end

    % Model gives absolute force; observer supplies dynamic adjustment
    Fz_hat = model + observer.dynamic_correction;

    % Tire normal force cannot be negative
    Fz_hat = max(Fz_hat, 0);

    observer.previous_residual = residual;

    output.Fz_hat = Fz_hat;
    output.dynamic_correction = observer.dynamic_correction;
    output.dFz_measured = dFz_measured;
    output.dFz_model = dFz_model;
    output.rate_error = rate_error;
end


function output = clampArray(input, minimum_value, maximum_value)

    output = min(max(input, minimum_value), maximum_value);
end


function T = lookupEngineTorque(mapFile, throttleBreaks, rpm, throttleFrac)
% Engine torque [Nm] interpolated from an engine map on (rpm, throttle).
%
% The map is a table whose first column is rpm and whose remaining columns are
% torque at fixed throttle fractions. Some of the maps in this repo carry a
% header row naming those fractions (engine_map_boosted_reduced.csv is
% "rpm,0.0,0.3,1") and some have none at all (engine_map_newEnginebrake.csv
% starts straight in on data), so the header is used when it is there and
% throttleBreaks is the fallback when it is not.
%
% Both axes are clamped rather than extrapolated. Past the last rpm row a
% straight-line extrapolation of a torque curve goes somewhere silly quickly,
% and a throttle outside 0..1 is not a throttle.

    persistent cache

    if isempty(cache)
        cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end

    key = char(mapFile);

    if isKey(cache, key)

        entry = cache(key);

    else
        if ~isfile(mapFile)
            error("notmal_force_estimation:missingEngineMap", ...
                "Engine map not found: %s", mapFile);
        end

        raw = readmatrix(mapFile);

        % readmatrix turns a text header into a NaN row; drop any row whose rpm
        % did not parse, which covers both the header and stray blank lines.
        raw = raw(isfinite(raw(:,1)), :);

        nCols = size(raw,2) - 1;

        % Recover the throttle breakpoints from the header if the file has one.
        fid  = fopen(mapFile, 'r');
        line1 = fgetl(fid);
        fclose(fid);

        headerVals = str2double(strsplit(strtrim(line1), ','));

        if numel(headerVals) == nCols + 1 && any(isnan(headerVals))
            % First cell is text ("rpm"), the rest are the throttle fractions.
            breaks = headerVals(2:end);
        else
            breaks = throttleBreaks;
        end

        if numel(breaks) ~= nCols
            error("notmal_force_estimation:engineMapShape", ...
                "%s has %d torque columns but %d throttle breakpoints were given.", ...
                mapFile, nCols, numel(breaks));
        end

        % unique rather than sort: interp1 needs strictly monotonic breakpoints,
        % and a repeated rpm row would throw. Matches loadMapCSV in
        % data_analisis/engine_map_anylisis.m.
        [rpmU, order] = unique(raw(:,1));

        entry.rpm    = rpmU;
        entry.T      = raw(order,2:end);
        entry.breaks = breaks(:).';

        [entry.breaks, bOrder] = sort(entry.breaks);
        entry.T = entry.T(:, bOrder);

        cache(key) = entry;

        fprintf("engine map loaded: %s  (%d rpm rows %.0f-%.0f, throttle breakpoints %s)\n", ...
            mapFile, numel(entry.rpm), entry.rpm(1), entry.rpm(end), ...
            mat2str(entry.breaks));
    end

    rpmQ = min(max(rpm(:), entry.rpm(1)), entry.rpm(end));
    thrQ = min(max(throttleFrac(:), entry.breaks(1)), entry.breaks(end));

    % Interpolate down the rpm axis first, one column at a time, then across
    % throttle. Two 1-D passes rather than interp2, so a map with only a few
    % throttle columns needs no gridded-data fuss.
    nCols = numel(entry.breaks);
    colT  = zeros(numel(rpmQ), nCols);

    for iCol = 1:nCols
        colT(:,iCol) = interp1(entry.rpm, entry.T(:,iCol), rpmQ, 'linear');
    end

    T = zeros(numel(rpmQ), 1);

    for iCol = 1:nCols-1

        inSpan = thrQ >= entry.breaks(iCol) & thrQ <= entry.breaks(iCol+1);

        if ~any(inSpan), continue, end

        w = (thrQ(inSpan) - entry.breaks(iCol)) ...
          ./ (entry.breaks(iCol+1) - entry.breaks(iCol));

        T(inSpan) = (1-w) .* colT(inSpan,iCol) + w .* colT(inSpan,iCol+1);
    end

    T = reshape(T, size(rpm));
end


function scatterTime(x, y, c)
% Scatter x vs y colored by time. All three inputs are already restricted to
% the plot's validity mask.

    scatter(x, y, 18, c, "filled");
    grid on
    cb = colorbar;
    ylabel(cb, "Time [s]");
    xline(0, "k--");
    yline(0, "k--");
end


function muCircle(mu)
% Reference friction circle of radius mu on a normalized force plot.

    theta = linspace(0, 2*pi, 200);

    hold on
    plot(mu .* cos(theta), mu .* sin(theta), "k--", "LineWidth", 1);
end


function cmap = slipDivergingColormap(n)
% Two-sided map for SIGNED slip ratio: blue where the wheel is held back
% (braking slip), near-neutral at zero, red where it is outrunning the road
% (drive slip). Used with symmetric colour limits, so the neutral band really
% does land on kappa = 0.
%
% Deliberately not kappaColormap: that one gives the whole rainbow to braking
% and flattens everything positive to grey, which is right for figs S11 and
% S12 and wrong here, where the drive side is half the picture.

    if nargin < 1 || isempty(n)
        n = 256;
    end

    negEnd  = [0.12 0.35 0.62];   % deep blue, most negative
    neutral = [0.94 0.94 0.90];   % near-white at zero
    posEnd  = [0.70 0.15 0.15];   % deep red, most positive

    half = floor(n/2);
    lower = [linspace(negEnd(1), neutral(1), half)', ...
             linspace(negEnd(2), neutral(2), half)', ...
             linspace(negEnd(3), neutral(3), half)'];

    upper = [linspace(neutral(1), posEnd(1), n - half)', ...
             linspace(neutral(2), posEnd(2), n - half)', ...
             linspace(neutral(3), posEnd(3), n - half)'];

    cmap = [lower; upper];
end

function bias = scheduledFrontBias(speedBreaks, decelBreaks, biasGrid, speed, decel)
% Front FORCE bias from the brake schedule LUT at a speed and a commanded
% decel.
%
% Both axes are clamped onto the grid rather than extrapolated. The LUT is
% written with its edge values already held - above a_max it repeats the a_max
% answer, below the drag cut-in it repeats the lowest decel that uses the
% brakes - so clamping continues the file's own convention. Extrapolating a
% bias would also be free to leave [0 1], which is not a bias.

    speed = min(max(speed, speedBreaks(1)), speedBreaks(end));
    decel = min(max(decel, decelBreaks(1)), decelBreaks(end));

    bias = interp2(speedBreaks, decelBreaks, biasGrid, speed, decel, "linear");

    % The solve divides by both bias and 1-bias, so neither end is allowed to
    % be reached exactly.
    bias = min(max(bias, 1e-3), 1 - 1e-3);
end

function limits = robustRange(x, tailFraction)
% [lo hi] covering x with the extreme tailFraction of the samples dropped off
% each end, so one outlier cannot stretch a whole plotting grid.

    x = sort(x(isfinite(x)));

    if isempty(x)
        limits = [0 1];
        return
    end

    loIdx = min(numel(x), max(1, round(tailFraction * numel(x))));
    hiIdx = min(numel(x), max(loIdx, round((1 - tailFraction) * numel(x))));

    limits = [x(loIdx) x(hiIdx)];

    if ~(limits(2) > limits(1))
        limits = limits(1) + [-0.5 0.5];
    end
end


function cmap = kappaColormap(n, negLimit, posLimit, climTop, posColor, gamma)
% One-sided color scale for slip ratio, to be used with
% CLim = [negLimit climTop].
%
% The rows covering negLimit to posLimit are a flipped rainbow, so the braking
% side runs deep red at negLimit through orange, yellow, green and cyan to
% deep blue at posLimit: more hues over the range than a two-ended ramp, which
% is the point of using a rainbow here. The rows above posLimit are one flat
% color, so slip past it reads as a single block rather than as a magnitude.
% MATLAB clamps out-of-range data onto the end rows, which is what puts a deep
% lock-up on the red end and any large positive slip on the flat color.
%
% gamma bends where the hues land without touching the value axis. Writing f
% for how far a row sits from posLimit toward negLimit, the rainbow is sampled
% at f^gamma, so gamma below 1 runs the cool half off quickly over small slip
% and leaves the whole orange-to-red end for the deep slip near negLimit.

    if nargin < 6 || isempty(gamma)
        gamma = 1;
    end

    climSpan = climTop - negLimit;

    nRamp = max(2, round(n * (posLimit - negLimit) / climSpan));
    nFlat = max(1, n - nRamp);

    base   = rainbowColormap(256);            % deep blue -> deep red
    basePos = linspace(0, 1, size(base,1)).';

    % Row 1 sits at negLimit, so f runs 1 down to 0 across the ramp rows.
    f = linspace(1, 0, nRamp).';
    ramp = interp1(basePos, base, f .^ gamma);

    cmap = [ramp; repmat(posColor(:).', nFlat, 1)];
    cmap = min(max(cmap, 0), 1);
end


function cmap = rainbowColormap(n)
% Full rainbow ramp, deep blue through cyan, green and yellow to deep red.
% turbo is the better one - jet's cyan and yellow bands read as edges that are
% not in the data - so it is used whenever the release has it.

    if exist("turbo", "file")
        cmap = turbo(n);
    else
        cmap = jet(n);
    end
end


function cmap = slipAngleColormap(n)
% Multi-hue diverging map for SIGNED slip angle.
%
% slipDivergingColormap is only blue -> near-white -> red, which has just two
% hues to spend on the whole range. Inside a slip angle scale of a few degrees
% that puts most of the data into pale washed-out tones where a degree of change
% is nearly invisible.
%
% This runs through seven stops - deep blue, blue, cyan, neutral, amber, orange,
% deep red - so the eye gets hue changes as well as lightness changes to read
% gradations by. Still DIVERGING and still symmetric, so the neutral band lands
% on alpha = 0 when used with symmetric colour limits, which is the property that
% matters for a signed quantity.
%
% Not turbo/jet: those are not diverging, so zero would fall on an arbitrary
% colour and the sign of the slip angle would stop being readable.

    if nargin < 1 || isempty(n)
        n = 256;
    end

    stops = [ ...
        0.14 0.20 0.55        % deep blue      most negative
        0.22 0.45 0.72        % blue
        0.45 0.70 0.84        % cyan
        0.95 0.95 0.92        % neutral        zero
        0.99 0.80 0.45        % amber
        0.92 0.52 0.22        % orange
        0.62 0.09 0.14];      % deep red       most positive

    nStop = size(stops,1);

    xStop = linspace(0, 1, nStop);
    xOut  = linspace(0, 1, n);

    cmap = [interp1(xStop, stops(:,1), xOut, "pchip")', ...
            interp1(xStop, stops(:,2), xOut, "pchip")', ...
            interp1(xStop, stops(:,3), xOut, "pchip")'];

    cmap = min(max(cmap, 0), 1);   % pchip can overshoot slightly
end


function FG = makeFigureGroups(groupDefs, enabled)
% One container window per group, each holding a uitabgroup that newFigTab adds
% tabs to. Returns a struct: FG.enabled, FG.keys, FG.titles, FG.tabgroup(i).
%
% With enabled = false nothing is created and newFigTab falls back to plain
% figures, so the grouping can be switched off without touching the plot code.

    FG.enabled = enabled;
    FG.keys    = string(groupDefs(:,1));
    FG.titles  = string(groupDefs(:,2));
    FG.tabgroup = gobjects(numel(FG.keys), 1);
    FG.figure   = gobjects(numel(FG.keys), 1);

    if ~enabled
        return
    end

    for iGroup = 1:numel(FG.keys)

        FG.figure(iGroup) = figure( ...
            "Name", FG.titles(iGroup), ...
            "NumberTitle", "off");

        FG.tabgroup(iGroup) = uitabgroup(FG.figure(iGroup), ...
            "Units", "normalized", ...
            "Position", [0 0 1 1]);
    end
end


function parent = newFigTab(FG, groupKey, tabTitle)
% Parent container for one plot: a new tab in that group's window, or a plain
% figure when grouping is off.
%
% IMPORTANT for callers. The returned handle must be passed EXPLICITLY to
% tiledlayout or axes, and the layout handle then passed to every nexttile:
%
%     p  = newFigTab(FG, "lateral", 'Fig S1 - ...');
%     tl = tiledlayout(p, 1, 2);
%     ax = nexttile(tl);
%
% A BARE nexttile does not work here. It ignores a tab-parented layout and
% silently builds a second layout as a direct child of the container figure,
% which then floats on top of the tab group and hides it. Verified in R2025b:
% with tl parented to a Tab, isequal(nexttile().Parent, tl) is false.

    if ~FG.enabled
        parent = figure("Name", tabTitle, "NumberTitle", "off");
        return
    end

    iGroup = find(FG.keys == string(groupKey), 1);

    if isempty(iGroup)
        error("notmal_force_estimation:unknownFigureGroup", ...
            "figure group ""%s"" is not in figGroupDefs. Known groups: %s.", ...
            groupKey, join(FG.keys, ", "));
    end

    parent = uitab(FG.tabgroup(iGroup), "Title", tabTitle);
end


function pruneEmptyFigureGroups(FG)
% Close any container window that ended up with no tabs, so switches like
% plot_per_tire = false do not leave empty windows behind.

    if ~FG.enabled
        return
    end

    for iGroup = 1:numel(FG.keys)

        tg = FG.tabgroup(iGroup);

        if isgraphics(tg) && isempty(tg.Children)
            close(FG.figure(iGroup));
        end
    end
end








% The slip angle / slip ratio / tire force section lives above the local
% function definitions, since MATLAB requires script functions to come last.
% It normalizes with the observer loads: Fz_fl_obs, Fz_fr_obs, Fz_rl_obs,
% Fz_rr_obs (set use_observed_Fz = false to normalize with the strain gages).
