clc
close all
clear
% nomral force estimation




%% analysis time window

time_segment = [1910 1920];

time_segment = [740 830];
time_segment = [1450 1460]; % for wheel like on straight
time_segment = [1720 1734; 1800 1810; 1907 1916;1977 1986; 2075 2087; 2156 2166];

time_segment = [1700 2150];
time_segment = [0 inf]

%% opening csv

%data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_28_fastlap_tireLocking_acc/csv_output/2026-07-28_153834_merged.csv"); %% fast lap
%data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_19_full_test/csv_output/2026-07-19_133128_merged.csv");%% lift up tires
%data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_28_HardBraking_feedbackcontroller/csv_output/2026-07-28_130732_merged.csv");
data  = readtable("/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv");
%data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_26_hard_brake_onstraight/csv_output/2026-07-26_142425_merged.csv");
%% filtered data

mm = 20;

%% applying the time window


t0_recording = data.time_s(1);
t_recording  = data.time_s - t0_recording;

gage_zero = [ ...
    movmean(data.fl_load_n, mm), ...
    movmean(data.fr_load_n, mm), ...
    movmean(data.rl_load_n, mm), ...
    movmean(data.rr_load_n, mm)];

gage_zero = gage_zero(min(100, height(data)), :);   % [fl fr rl rr]

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

Fax = movmean(data.a_x,mm);
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

Fvx = movmean(data.odom_vx_mps,mm);
% Fvx = movmean(data.oms_vel_x_kmh, mm) ./ 3.6;
Fvy = movmean(data.odom_vy_mps,mm);

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
figure('Name','Fig T1 - Tire Temperature (sensors and average, per tire)');

layoutT1 = tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

axT1 = gobjects(4,1);

for iTire = 1:4

    axT1(iTire) = nexttile;
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
figure('Name','Fig T2 - Tire Temperature (average per tire)');

axT2 = axes();

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

figure('Name','Vehicle Pose (x-y)');
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


% geometric nmormal forces

fz_rr_geo = 2318.6;
fz_rl_geo = 2318.6;
fz_fr_geo = 1679;
fz_fl_geo = 1679;



 
% gage_zero = [fl fr rl rr] sampled at the start of the full recording
error_rr = gage_zero(4) - fz_rr_geo;
Fz_rr_adjusted = Ffz_rr - error_rr;

error_rl = gage_zero(3) - fz_rl_geo;
Fz_rl_adjusted = Ffz_rl - error_rl;

error_fr = gage_zero(2) - fz_fr_geo;
Fz_fr_adjusted = Ffz_fr - error_fr;

error_fl = gage_zero(1) - fz_fl_geo;
Fz_fl_adjusted = Ffz_fl - error_fl;



figure
tiledlayout(2,2)
nexttile
plot(t_plot,Fz_fr_adjusted);
grid on 
legend("fr")

nexttile
plot(t_plot,Fz_fl_adjusted)
grid on
legend("fl")

nexttile
plot(t_plot,Fz_rr_adjusted)
grid on
legend("rr")

nexttile
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






%% params 
vehicleParams.wheelbase   = 2.9718;      % wheelbase (m)  [2971.8 mm]
vehicleParams.w_dist_f    = 0.42;        % front weight distribution [42%]
vehicleParams.t_f         = 1.638762;    % front track (m)  [1638.762 mm]
vehicleParams.t_r         = 1.5239686;   % rear track (m)   [1523.9686 mm]

% Wheel rates computed from springs & motion ratios at 0 mm:
% avg stiffness*(motion_ratio)^2

vehicleParams.wheelRate_f = 2.985553732e5;  % (N/m) was 2.98
vehicleParams.wheelRate_r = 3.941321827e5;  % (N/m)

vehicleParams.ARB_f       = 0;             % (Nm/deg)  TBD
vehicleParams.ARB_r       = 0;              % (Nm/deg)  no anti roll bar in rear

vehicleParams.cg_z        = 0.275;          % CG height (m)  [275 mm]
vehicleParams.rc_f        = 0.1202436;      % roll center front (m) 
vehicleParams.rc_r        = 0.0016628;      % roll center rear  (m) 

vehicleParams.toe_f       = -0.451;         % toe front (deg, - = out) 
vehicleParams.toe_r       = -0.451;         % toe rear  (deg, - = out)

vehicleParams.m           = 815;            % vehicle mass (kg)  [base vehicle mass]

vehicleParams.mech_trail_f = 0;             % mech trail front (m) TBD
vehicleParams.mech_trail_r = 0;             % mech trail rear  (m) TBD

vehicleParams.frontalArea = 1 ;             % frontal area (m^2) TBD
vehicleParams.Cd          = 0.0;            % drag coeff (-)     TBD
vehicleParams.Cl          = 0.0;            % ift coeff (-)      TBD
vehicleParams.ACd         = 0.58;           % Area*coef down force      TBD
vehicleParams.aeroBalance = .33;            % frontal aero load (-) 33% avg
vehicleParams.copShift    = 0;              % balance shift with Vx (%/(m/s))TBD
vehicleParams.inertia     = 1000;           % moment of inertia

%% load tranfer calcs (bycicle)


L  = vehicleParams.wheelbase;
a  = vehicleParams.w_dist_f * L;        
b  = L - a;            
m  = vehicleParams.m;
cgh = vehicleParams.cg_z;

%basic load tranfer 
fz_f_basic = ((a*m*9.81)/(L) - (m*Fax*cgh)/L);
fz_r_basic = ((b*m*9.81)/(L) + (m*Fax*cgh)/L);

front_axle = (Fz_fl_adjusted + Fz_fr_adjusted);
rear_axle = (Fz_rr_adjusted + Fz_rl_adjusted);



% CONSIDER CURVATURE 
aero_balance = 0.33;
scalar = 0.0;
down_force = 0.5 * 0.58 * 1.225 .* Fvx.^2;

front_aero = aero_balance .* down_force;
rear_aero  = (1 - aero_balance) .* down_force;

L = a + b;   % assuming a = lf, b = lr

az_road = 9.81 .* cos(Fpitch) .* cos(Froll) + Fvx .* Fwz .* sin(Froll) + Fvx .* Fwy*scalar;

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

figure 
tiledlayout(3,1)
nexttile
plot(t_plot,front_axle)
hold on
plot(t_plot,fz_f_basic)
hold on
plot(t_plot,fz_f_curvature,LineWidth=2)

legend("front measured","front basic calc","front 3D calc")


nexttile
plot(t_plot,rear_axle)
hold on
plot(t_plot,fz_r_basic)
hold on
plot(t_plot,fz_r_curvature,LineWidth=2)
legend("rear measured","rear basic calc","rear 3D calc")

nexttile
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


Fz_fr = fz_f_curvature/2 + LAT_weightTransferGradient_f * (Fay/9.81);
Fz_fl = fz_f_curvature/2 - LAT_weightTransferGradient_f* (Fay/9.81);

Fz_rr = fz_r_curvature/2 + LAT_weightTransferGradient_r* (Fay/9.81);
Fz_rl = fz_r_curvature/2 - LAT_weightTransferGradient_r* (Fay/9.81);




figure
tiledlayout(2,2)

axs = gobjects(4,1);

axs(1) = nexttile;
plot(t_plot, Fz_fl_adjusted);
hold on
plot(t_plot, Fz_fl, 'LineWidth', 2);
legend("Fl measured","Fl est")
title("Front Left")
grid on

axs(2) = nexttile;
plot(t_plot, Fz_fr_adjusted);
hold on
plot(t_plot, Fz_fr, 'LineWidth', 2);
legend("Fr measured","Fr est")
title("Front Right")
grid on

axs(3) = nexttile;
plot(t_plot, Fz_rl_adjusted);
hold on
plot(t_plot, Fz_rl, 'LineWidth', 2);
legend("Rl measured","Rl est")
title("Rear Left")
grid on
xlabel("Time [s]")

axs(4) = nexttile;
plot(t_plot, Fz_rr_adjusted);
hold on
plot(t_plot, Fz_rr, 'LineWidth', 2);
legend("Rr measured","Rr est")
title("Rear Right")
grid on
xlabel("Time [s]")

linkaxes(axs, 'x')






%%
Fz_fr = fz_f_curvature/2 + LAT_weightTransferGradient_f * (Fay/9.81);
Fz_fl = fz_f_curvature/2 - LAT_weightTransferGradient_f * (Fay/9.81);

Fz_rr = fz_r_curvature/2 + LAT_weightTransferGradient_r * (Fay/9.81);
Fz_rl = fz_r_curvature/2 - LAT_weightTransferGradient_r * (Fay/9.81);




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

Fwy = -movmean(data.odom_wy_rads,mm);
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

figure();

layout = tiledlayout(2, 2, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

title(layout, "Normal Force Observer Comparison", ...
    "FontWeight", "bold");

observer_axes = gobjects(4,1);

for tire = 1:4

    observer_axes(tire) = nexttile;
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

figure();

layout = tiledlayout(2, 1, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

title(layout, "Observer Correction Diagnostics", ...
    "FontWeight", "bold");

ax1 = nexttile;
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


ax2 = nexttile;
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

Fwy = -movmean(data.odom_wy_rads,mm);
set(ax2, ...
    "FontSize", 11, ...
    "LineWidth", 0.8, ...
    "GridAlpha", 0.20);

linkaxes([ax1, ax2], "x");




%% slip / force params
vx_min_slip_angle     = 4;        
vx_min_slip_ratio     = 15;    
vx_max_slip_ratio     = Inf;      
alpha_max_deg         = 20;       
slip_ratio_max        = 100;     
brakePressureMin_kPa  = 75;       
defaultFrontBrakeBias = 0.53;    
maxFrontBrakeBias     = 0.8;   
minFrontBrakeBias     = 0.2;     
Fx_deadband_N         = 50;       
CdA_drag              = 1.33;     
rho                   = 1.225;   
g                     = 9.81;    
Iz                    = vehicleParams.inertia;

useBankCorrection = true;   
plot_per_tire     = true;   
use_observed_Fz   = true;  
slip_ratio_def = "sae"; % or wheel
fx_split_mode = "load";

ay_max_pure_long = 2.0;   % m/s^2
Fwy = -movmean(data.odom_wy_rads,mm);%eport and the sample is
biasMap_pressureMin_kPa = 400;
biasMap_climTail        = 0.01;
biasMap_greyColor       = [0.72, 0.72, 0.72];


kappaMap_negLimit   = -0.08;                  % kappa that reaches the deep red end
kappaMap_posLimit   =  0.005;                 % top of the ramp; above this is flat
kappaMap_colorGamma =  1.00;                  % < 1 packs the cool hues into small slip
kappaMap_tickStep   =  0.02;                  % colorbar tick spacing
kappaMap_posColor   = [0.720, 0.720, 0.720];  % flat grey past posLimit

lf = b;   
lr = a;   

%% yaw acceleration
dt_series = gradient(t);
dt_series(dt_series <= 0) = median(dt_series(dt_series > 0));
rdot = movmean(gradient(Fwz) ./ dt_series, mm);

%% lateral acceleration at the tires (curvature based, bank corrected)
ay_inertial = V.^2 .* kappa_yaw;
g_y_body    = -g .* cos(Fpitch) .* sin(Froll);

if useBankCorrection
    ay_tire = ay_inertial - g_y_body;
else
    ay_tire = ay_inertial;
end

ay_tire(~curv_valid) = NaN;

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
Fx_total = m .* Fax + Fdrag + Fgrade + Fyf .* sin(toe_rad); % not adding in lat controbutin

%% Fx split front / rear by measured brake bias
Pf = Fbrake;                                       % front brake pressure [kPa]
Pr = movmean(data.rear_brake_pressure_kpa, mm);    % rear brake pressure  [kPa]

brakePressureTotal = Pf + Pr;
hasBrakePressure   = brakePressureTotal > brakePressureMin_kPa;

biasF = defaultFrontBrakeBias .* ones(size(Fx_total));
biasF(hasBrakePressure) = Pf(hasBrakePressure) ./ brakePressureTotal(hasBrakePressure);
biasF = max(0, min(1, biasF));


biasTooHigh = hasBrakePressure & biasF > maxFrontBrakeBias;
biasTooLow  = hasBrakePressure & biasF < minFrontBrakeBias;
biasValid   = ~(biasTooHigh | biasTooLow);

fprintf("brake bias outside [%.2f %.2f] rejected on %d of %d samples (%.1f%%): %d high, %d low\n", ...
    minFrontBrakeBias, maxFrontBrakeBias, sum(~biasValid), numel(biasValid), ...
    100 * sum(~biasValid) / numel(biasValid), sum(biasTooHigh), sum(biasTooLow));

driveMode = Fx_total >  Fx_deadband_N;
brakeMode = Fx_total < -Fx_deadband_N;

Fxf = zeros(size(Fx_total));
Fxr = zeros(size(Fx_total));

% Drive: rear wheel drive, so all of the tractive force sits on the rear axle.
Fxr(driveMode) = Fx_total(driveMode);

% Brake: split by the measured brake bias.
Fxf(brakeMode) = biasF(brakeMode)       .* Fx_total(brakeMode);
Fxr(brakeMode) = (1 - biasF(brakeMode)) .* Fx_total(brakeMode);



%% per-tire lateral forces 
Fy_fl = Fyf ./ 2;   Fy_fr = Fyf ./ 2;
Fy_rl = Fyr ./ 2;   Fy_rr = Fyr ./ 2;

%% wheel speeds and tire-frame velocities

Vw_fl = movmean(data.fl_speed_kmh, mm) ./ 3.61 - 0.1;
Vw_fr = movmean(data.fr_speed_kmh, mm) ./ 3.61 - 0.1;
Vw_rl = movmean(data.rl_speed_kmh, mm) ./ 3.61 - 0.1;
Vw_rr = movmean(data.rr_speed_kmh, mm) ./ 3.61 - 0.1;

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

figure('Name','Fig S0 - Wheel Speeds / Brake Pressure / Bias / a_x / Slip Ratio');

axS0 = gobjects(5,1);

axS0(1) = subplot(5,1,1);
plot(t_plot, Vw_fl);
hold on
plot(t_plot, Vw_fr);
plot(t_plot, Vw_rl);
plot(t_plot, Vw_rr);
grid on
ylabel("Wheel speed [m/s]");
legend("FL", "FR", "RL", "RR", "Location", "best");
title("Wheel speeds");

axS0(2) = subplot(5,1,2);
plot(t_plot, Pf);
hold on
plot(t_plot, Pr);
grid on
ylabel("Pressure [kPa]");
legend("front", "rear", "Location", "best");
title("Brake pressure");

axS0(3) = subplot(5,1,3);
plot(t_plot, biasF, "DisplayName", "bias used");
hold on
plot(t_plot, biasF_measured, "LineWidth", 1.5, "DisplayName", "measured only");
plot(t(~biasValid), biasF(~biasValid), "rx", "MarkerSize", 5, ...
    "DisplayName", "rejected");
yline(defaultFrontBrakeBias, "k--", "default", "HandleVisibility", "off");
yline(maxFrontBrakeBias, "r--", "max", "HandleVisibility", "off");
yline(minFrontBrakeBias, "r--", "min", "HandleVisibility", "off");
grid on
ylim([0 1]);
ylabel("Front bias [-]");
legend("Location", "best");
title("Front brake bias  P_f / (P_f + P_r)");

axS0(4) = subplot(5,1,4);
plot(t_plot, Fax);
yline(0, "k--");
grid on
ylabel("a_x [m/s^2]");
title("Longitudinal acceleration");

kappa_all = abs([slip_ratio_x_fl; slip_ratio_x_fr; slip_ratio_x_rl; slip_ratio_x_rr]);
kappa_all = sort(kappa_all(isfinite(kappa_all)));

if isempty(kappa_all)
    kappa_lim = 1;
else
    kappa_lim = kappa_all(max(1, round(0.995 * numel(kappa_all))));
end

kappa_lim = min(max(kappa_lim, 0.05), 2);   % keep the axis readable

axS0(5) = subplot(5,1,5);
plot(t_plot, slip_ratio_x_fl);
hold on
plot(t_plot, slip_ratio_x_fr);
plot(t_plot, slip_ratio_x_rl);
plot(t_plot, slip_ratio_x_rr);
yline(0, "k--");
grid on
ylim(1.1 * [-kappa_lim kappa_lim]);
xlabel("Time [s]");
ylabel("\kappa [-]");
legend("FL", "FR", "RL", "RR", "Location", "best");
title("Slip ratio");

% Mark the joins between time_segment sections on every panel.
for iAx = 1:numel(axS0)
    for iSeam = 1:numel(seam_time)
        xline(axS0(iAx), seam_time(iSeam), "k:", "LineWidth", 1.2, ...
            "HandleVisibility", "off");
    end
end

linkaxes(axS0, "x");

%% fig S1 - slip angle vs axle lateral force [N]
figure('Name','Fig S1 - Slip Angle vs F_y (per axle, measured)');

subplot(1,2,1)
scatterTime(alpha_f_deg(validFront), Fyf(validFront), tAbs(validFront));
xlabel('Front slip angle \alpha_f [deg]');
ylabel('Front lateral force F_{y,f} [N]');
title('Front axle');

subplot(1,2,2)
scatterTime(alpha_r_deg(validRear), Fyr(validRear), tAbs(validRear));
xlabel('Rear slip angle \alpha_r [deg]');
ylabel('Rear lateral force F_{y,r} [N]');
title('Rear axle');

sgtitle('Slip angle vs measured lateral force');

%% fig S2 - slip angle vs axle Fy / Fz [-]
figure('Name','Fig S2 - Slip Angle vs F_y/F_z (per axle, observed F_z)');

subplot(1,2,1)
scatterTime(alpha_f_deg(validFront_n), ...
            Fyf(validFront_n) ./ Fz_front_norm(validFront_n), ...
            tAbs(validFront_n));
xlabel('Front slip angle \alpha_f [deg]');
ylabel('F_{y,f} / F_{z,f} [-]');
title('Front axle');

subplot(1,2,2)
scatterTime(alpha_r_deg(validRear_n), ...
            Fyr(validRear_n) ./ Fz_rear_norm(validRear_n), ...
            tAbs(validRear_n));
xlabel('Rear slip angle \alpha_r [deg]');
ylabel('F_{y,r} / F_{z,r} [-]');
title('Rear axle');

sgtitle(sprintf('Slip angle vs measured lateral force / %s', Fz_label));

%% fig S3 - slip ratio vs axle longitudinal force [N]
figure('Name','Fig S3 - Slip Ratio vs F_x (per axle, measured)');

subplot(1,2,1)
scatterTime(slip_ratio_f(validFront_L), Fxf(validFront_L), tAbs(validFront_L));
xlabel('Front slip ratio \kappa_f [-]');
ylabel('Front longitudinal force F_{x,f} [N]');
title('Front axle');

subplot(1,2,2)
scatterTime(slip_ratio_r(validRear_L), Fxr(validRear_L), tAbs(validRear_L));
xlabel('Rear slip ratio \kappa_r [-]');
ylabel('Rear longitudinal force F_{x,r} [N]');
title('Rear axle');

sgtitle(sprintf('Slip ratio vs measured longitudinal force   (%s, %s)', ...
    slip_ratio_label, pureLong_label));

%% fig S4 - slip ratio vs axle Fx / Fz [-]
figure('Name','Fig S4 - Slip Ratio vs F_x/F_z (per axle, observed F_z)');

subplot(1,2,1)
scatterTime(slip_ratio_f(validFront_Ln), ...
            Fxf(validFront_Ln) ./ Fz_front_norm(validFront_Ln), ...
            tAbs(validFront_Ln));
xlabel('Front slip ratio \kappa_f [-]');
ylabel('F_{x,f} / F_{z,f} [-]');
title('Front axle');

subplot(1,2,2)
scatterTime(slip_ratio_r(validRear_Ln), ...
            Fxr(validRear_Ln) ./ Fz_rear_norm(validRear_Ln), ...
            tAbs(validRear_Ln));
xlabel('Rear slip ratio \kappa_r [-]');
ylabel('F_{x,r} / F_{z,r} [-]');
title('Rear axle');

sgtitle(sprintf('Slip ratio vs measured longitudinal force / %s   (%s, %s)', ...
    Fz_label, slip_ratio_label, pureLong_label));

%% fig S5 - friction circle per axle [N]
figure('Name','Fig S5 - Friction Circle (per axle, measured)');

subplot(1,2,1)
scatterTime(Fxf(validFront), Fyf(validFront), tAbs(validFront));
axis equal;
xlabel('F_{x,f} [N]'); ylabel('F_{y,f} [N]');
title('Front axle');

subplot(1,2,2)
scatterTime(Fxr(validRear), Fyr(validRear), tAbs(validRear));
axis equal;
xlabel('F_{x,r} [N]'); ylabel('F_{y,r} [N]');
title('Rear axle');

sgtitle('Friction circle - measured force');

%% fig S6 - friction circle per axle, normalized [-]
figure('Name','Fig S6 - Friction Circle (per axle, observed F_z)');

subplot(1,2,1)
scatterTime(Fxf(validFront_n) ./ Fz_front_norm(validFront_n), ...
            Fyf(validFront_n) ./ Fz_front_norm(validFront_n), ...
            tAbs(validFront_n));
muCircle(1.0); axis equal;
xlabel('F_{x,f} / F_{z,f} [-]'); ylabel('F_{y,f} / F_{z,f} [-]');
title('Front axle');

subplot(1,2,2)
scatterTime(Fxr(validRear_n) ./ Fz_rear_norm(validRear_n), ...
            Fyr(validRear_n) ./ Fz_rear_norm(validRear_n), ...
            tAbs(validRear_n));
muCircle(1.0); axis equal;
xlabel('F_{x,r} / F_{z,r} [-]'); ylabel('F_{y,r} / F_{z,r} [-]');
title('Rear axle');

sgtitle(sprintf('Friction circle - measured force / %s (dashed = \\mu 1.0)', Fz_label));

%% per-tire figures
if plot_per_tire

    %% fig S7 - slip ratio vs Fx per tire [N]
    figure('Name','Fig S7 - Slip Ratio vs F_x (per tire, measured)');

    subplot(2,2,1)
    scatterTime(slip_ratio_x_fl(validFL_L), fx_fl(validFL_L), tAbs(validFL_L));
    xlabel('\kappa_{fl} [-]'); ylabel('F_{x,fl} [N]'); title('Front Left');

    subplot(2,2,2)
    scatterTime(slip_ratio_x_fr(validFR_L), fx_fr(validFR_L), tAbs(validFR_L));
    xlabel('\kappa_{fr} [-]'); ylabel('F_{x,fr} [N]'); title('Front Right');

    subplot(2,2,3)
    scatterTime(slip_ratio_x_rl(validRL_L), fx_rl(validRL_L), tAbs(validRL_L));
    xlabel('\kappa_{rl} [-]'); ylabel('F_{x,rl} [N]'); title('Rear Left');

    subplot(2,2,4)
    scatterTime(slip_ratio_x_rr(validRR_L), fx_rr(validRR_L), tAbs(validRR_L));
    xlabel('\kappa_{rr} [-]'); ylabel('F_{x,rr} [N]'); title('Rear Right');

    sgtitle(sprintf('Slip ratio vs measured longitudinal force (per-tire split: %s)   (%s, %s)', ...
        fx_split_label, slip_ratio_label, pureLong_label));

    %% fig S8 - slip ratio vs Fx / Fz per tire [-]
    figure('Name','Fig S8 - Slip Ratio vs F_x/F_z (per tire, observed F_z)');

    subplot(2,2,1)
    scatterTime(slip_ratio_x_fl(validFL_Ln), ...
                fx_fl(validFL_Ln) ./ Fz_fl_norm(validFL_Ln), tAbs(validFL_Ln));
    xlabel('\kappa_{fl} [-]'); ylabel('F_{x,fl} / F_{z,fl} [-]'); title('Front Left');

    subplot(2,2,2)
    scatterTime(slip_ratio_x_fr(validFR_Ln), ...
                fx_fr(validFR_Ln) ./ Fz_fr_norm(validFR_Ln), tAbs(validFR_Ln));
    xlabel('\kappa_{fr} [-]'); ylabel('F_{x,fr} / F_{z,fr} [-]'); title('Front Right');

    subplot(2,2,3)
    scatterTime(slip_ratio_x_rl(validRL_Ln), ...
                fx_rl(validRL_Ln) ./ Fz_rl_norm(validRL_Ln), tAbs(validRL_Ln));
    xlabel('\kappa_{rl} [-]'); ylabel('F_{x,rl} / F_{z,rl} [-]'); title('Rear Left');

    subplot(2,2,4)
    scatterTime(slip_ratio_x_rr(validRR_Ln), ...
                fx_rr(validRR_Ln) ./ Fz_rr_norm(validRR_Ln), tAbs(validRR_Ln));
    xlabel('\kappa_{rr} [-]'); ylabel('F_{x,rr} / F_{z,rr} [-]'); title('Rear Right');

    sgtitle(sprintf('Slip ratio vs measured longitudinal force / %s   (%s, %s)', ...
        Fz_label, slip_ratio_label, pureLong_label));

    %% fig S8b - fig S8 colored by tire temperature instead of time
    % Same axes and the same samples as fig S8, but each point is colored by
    % that tire's own average temperature (tire_temp_mean_f) rather than by when
    % it happened. Read this way a cold-tire branch separates from a hot-tire
    % branch that otherwise sit on top of each other in fig S8.
    %
    % A sample with no live sensor on that tire has a NaN average and cannot be
    % colored, so those drop out on top of the fig S8 masks. RL and RR only ever
    % have three live sensors (see the tire temp section), so their counts are
    % the ones to watch.
    %
    % The four panels share one color scale. Left to themselves, a tire that
    % only moved through 5 degC would use the same full ramp as one that moved
    % through 40, and the panels could not be read against each other.

    tempS8_valid = { ...
        validFL_Ln & isfinite(tire_temp_mean_f(:,1)), ...
        validFR_Ln & isfinite(tire_temp_mean_f(:,2)), ...
        validRL_Ln & isfinite(tire_temp_mean_f(:,3)), ...
        validRR_Ln & isfinite(tire_temp_mean_f(:,4))};

    tempS8_kappa = {slip_ratio_x_fl, slip_ratio_x_fr, slip_ratio_x_rl, slip_ratio_x_rr};
    tempS8_fx    = {fx_fl, fx_fr, fx_rl, fx_rr};
    tempS8_fz    = {Fz_fl_norm, Fz_fr_norm, Fz_rl_norm, Fz_rr_norm};

    tempS8_all = [];

    for tire = 1:4
        tempS8_all = [tempS8_all; tire_temp_mean_f(tempS8_valid{tire}, tire)];   %#ok<AGROW>
    end

    fprintf("fig S8b: FL %d, FR %d, RL %d, RR %d samples have a temperature (fig S8 plots %d, %d, %d, %d)\n", ...
        sum(tempS8_valid{1}), sum(tempS8_valid{2}), ...
        sum(tempS8_valid{3}), sum(tempS8_valid{4}), ...
        sum(validFL_Ln), sum(validFR_Ln), sum(validRL_Ln), sum(validRR_Ln));

    figure('Name','Fig S8b - Slip Ratio vs F_x/F_z (per tire, colored by tire temperature)');

    layoutS8b = tiledlayout(2, 2, "TileSpacing", "compact", "Padding", "compact");

    axS8b = gobjects(4,1);

    for tire = 1:4

        keep = tempS8_valid{tire};

        axS8b(tire) = nexttile;

        scatter(tempS8_kappa{tire}(keep), ...
                tempS8_fx{tire}(keep) ./ tempS8_fz{tire}(keep), ...
                18, tire_temp_mean_f(keep, tire), "filled");

        grid on
        box on
        xline(0, "k--");
        yline(0, "k--");

        title(sprintf("%s  (%d samples)", tire_names(tire), sum(keep)));
        xlabel("\kappa [-]");
        ylabel("F_x / F_z [-]");

        set(axS8b(tire), "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);
    end

    linkaxes(axS8b, "xy");

    if isempty(tempS8_all)
        warning("notmal_force_estimation:emptyTempS8", ...
            "Fig S8b has no samples with a live tire temperature.");
    else
        tempS8_clim = robustRange(tempS8_all, 0.01);

        % A run that held one temperature would otherwise get a scale of nearly
        % zero width, which turns sensor noise into a full sweep of the ramp.
        if tempS8_clim(2) - tempS8_clim(1) < 1
            tempS8_clim = mean(tempS8_clim) + [-0.5 0.5];
        end

        for tire = 1:4
            caxis(axS8b(tire), tempS8_clim);
        end

        fprintf("  fig S8b temperature color scale: %.1f to %.1f degC\n", ...
            tempS8_clim(1), tempS8_clim(2));
    end

    cbS8b = colorbar(axS8b(1));
    cbS8b.Layout.Tile = "east";
    ylabel(cbS8b, "Tire temperature [\circC]");

    title(layoutS8b, ...
        sprintf('Slip ratio vs F_x / %s, colored by tire temperature   (%s, %s)', ...
        Fz_label, slip_ratio_label, pureLong_label), ...
        "FontWeight", "bold");

    %% fig S9 - friction circle per tire [N]
    figure('Name','Fig S9 - Friction Circle (per tire, measured)');

    subplot(2,2,1)
    scatterTime(fx_fl(validFL), Fy_fl(validFL), tAbs(validFL));
    axis equal; xlabel('F_{x,fl} [N]'); ylabel('F_{y,fl} [N]'); title('Front Left');

    subplot(2,2,2)
    scatterTime(fx_fr(validFR), Fy_fr(validFR), tAbs(validFR));
    axis equal; xlabel('F_{x,fr} [N]'); ylabel('F_{y,fr} [N]'); title('Front Right');

    subplot(2,2,3)
    scatterTime(fx_rl(validRL), Fy_rl(validRL), tAbs(validRL));
    axis equal; xlabel('F_{x,rl} [N]'); ylabel('F_{y,rl} [N]'); title('Rear Left');

    subplot(2,2,4)
    scatterTime(fx_rr(validRR), Fy_rr(validRR), tAbs(validRR));
    axis equal; xlabel('F_{x,rr} [N]'); ylabel('F_{y,rr} [N]'); title('Rear Right');

    sgtitle(sprintf('Friction circle per tire - measured force (per-tire split: %s)', ...
        fx_split_label));

    %% fig S10 - friction circle per tire, normalized [-]
    figure('Name','Fig S10 - Friction Circle (per tire, observed F_z)');

    subplot(2,2,1)
    scatterTime(fx_fl(validFL_n) ./ Fz_fl_norm(validFL_n), ...
                Fy_fl(validFL_n) ./ Fz_fl_norm(validFL_n), tAbs(validFL_n));
    muCircle(1.0); axis equal;
    xlabel('F_{x,fl} / F_{z,fl} [-]'); ylabel('F_{y,fl} / F_{z,fl} [-]'); title('Front Left');

    subplot(2,2,2)
    scatterTime(fx_fr(validFR_n) ./ Fz_fr_norm(validFR_n), ...
                Fy_fr(validFR_n) ./ Fz_fr_norm(validFR_n), tAbs(validFR_n));
    muCircle(1.0); axis equal;
    xlabel('F_{x,fr} / F_{z,fr} [-]'); ylabel('F_{y,fr} / F_{z,fr} [-]'); title('Front Right');

    subplot(2,2,3)
    scatterTime(fx_rl(validRL_n) ./ Fz_rl_norm(validRL_n), ...
                Fy_rl(validRL_n) ./ Fz_rl_norm(validRL_n), tAbs(validRL_n));
    muCircle(1.0); axis equal;
    xlabel('F_{x,rl} / F_{z,rl} [-]'); ylabel('F_{y,rl} / F_{z,rl} [-]'); title('Rear Left');

    subplot(2,2,4)
    scatterTime(fx_rr(validRR_n) ./ Fz_rr_norm(validRR_n), ...
                Fy_rr(validRR_n) ./ Fz_rr_norm(validRR_n), tAbs(validRR_n));
    muCircle(1.0); axis equal;
    xlabel('F_{x,rr} / F_{z,rr} [-]'); ylabel('F_{y,rr} / F_{z,rr} [-]'); title('Rear Right');

    sgtitle(sprintf('Friction circle per tire - measured force / %s (dashed = \\mu 1.0)', Fz_label));
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
figure('Name','Fig S11 - Slip Ratio vs Speed and a_x (per tire, samples)');

layoutS11 = tiledlayout(2, 2, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

axS11 = gobjects(4,1);

for tire = 1:4

    keep = kappa_map_keep{tire};

    axS11(tire) = nexttile;
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

figure('Name','Fig S12 - Front Brake Bias vs Speed and a_x');

axS12 = axes();

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
ylabel(cbS12, "Front brake bias  P_f / (P_f + P_r)  [-]");

% Same plane as fig S11, so pan and zoom together.
linkaxes([axS11(:); axS12], "xy");


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








% The slip angle / slip ratio / tire force section lives above the local
% function definitions, since MATLAB requires script functions to come last.
% It normalizes with the observer loads: Fz_fl_obs, Fz_fr_obs, Fz_rl_obs,
% Fz_rr_obs (set use_observed_Fz = false to normalize with the strain gages).
