clc
close all
clear 

%% opening csv

% data = readtable('FastLaps.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/putnam/oversteer/2026-04-28_150159_merged.csv');
data = readtable('/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv');
%% filtered data

mm =20;
Ft = movmean(data.time_s,mm);

Fax = movmean(data.a_x,mm);
Fay = movmean(data.a_y,mm);
Faz = movmean(data.a_z,mm);

Ffz_fr = movmean(data.fr_load_n,mm);
Ffz_fl = movmean(data.fl_load_n,mm);
Ffz_rr = movmean(data.rr_load_n,mm);
Ffz_rl = movmean(data.rl_load_n,mm);

Fvx = movmean(data.odom_vx_mps,mm);
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
Fwy = movmean(data.odom_wy_rads,mm);



Fq = [Fqw Fqx Fqy Fqz];         
Feul = quat2eul(Fq, 'ZYX');   % [yaw pitch roll]

Fyaw   = Feul(:,1);
Fpitch = Feul(:,2);
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

% tire temp

fr_T_0 = data.fr_temp_1;
fr_T_1 = data.fr_temp_2;
fr_T_2 = data.fr_temp_3;
fr_T_3 = data.fr_temp_4;


%% getting yaw, pitch, and roll curvature

t = data.time_s(:);
t = t - t(1);


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

vehicleParams.wheelRate_f = 2.985553732e5;  % (N/m)
vehicleParams.wheelRate_r = 3.941321827e5;  % (N/m)

vehicleParams.ARB_f       = 0;             % (Nm/deg)  TBD
vehicleParams.ARB_r       = 0;              % (Nm/deg)  no anti roll bar in rear

vehicleParams.cg_z        = 0.275;          % CG height (m)  [275 mm]
vehicleParams.rc_f        = 0.1202436;      % roll center front (m) 
vehicleParams.rc_r        = 0.0016628;      % roll center rear  (m) 

vehicleParams.toe_f       = -0.451;         % toe front (deg, - = out) 
vehicleParams.toe_r       = -0.451;         % toe rear  (deg, - = out)

vehicleParams.m           = 787;            % vehicle mass (kg)  [base vehicle mass]

vehicleParams.mech_trail_f = 0;             % mech trail front (m) TBD
vehicleParams.mech_trail_r = 0;             % mech trail rear  (m) TBD

vehicleParams.frontalArea = 1 ;             % frontal area (m^2) TBD
vehicleParams.Cd          = 0.0;            % drag coeff (-)     TBD
vehicleParams.Cl          = 0.0;            % ift coeff (-)      TBD
vehicleParams.ACd         = 0.58;           % Area*coef down force      TBD
vehicleParams.aeroBalance = .33;            % frontal aero load (-) 33% avg
vehicleParams.copShift    = 0;              % balance shift with Vx (%/(m/s))TBD
vehicleParams.inertia     = 1000;           % moment of inertia




%% bicycle model lateral force

L  = vehicleParams.wheelbase;
b  = vehicleParams.w_dist_f * L;        
a  = L - b;                             

m  = vehicleParams.m;
Iz = vehicleParams.inertia;
r = Fwz;
% yaw acceleration
rdot = gradient(r, t);
rdot = movmean(rdot, mm); % yaw rate 



dt = gradient(t);
dt(dt <= 0) = median(dt(dt > 0));

steeringRatio = 1;   

delta = toe_rad; 

ay_cg = Fay;



Fyf = ((b) .* m .* ay_cg + Iz .* rdot) ./ L;
Fyr = (a .* m .* ay_cg - Iz .* rdot) ./ L;

vx_min = 10.0;   
vx_safe = Fvx;
vx_safe(abs(vx_safe) < vx_min) = 0;

alpha_f = delta - atan2(Fvy + a .* r, vx_safe);
alpha_r =       - atan2(Fvy - b .* r, vx_safe);

alpha_f_deg = rad2deg(alpha_f);
alpha_r_deg = rad2deg(alpha_r);

valid = isfinite(alpha_f_deg) & isfinite(alpha_r_deg) & ...
        isfinite(Fyf) & isfinite(Fyr) & ...
        abs(Fvx) > vx_min;


%% corner section boxes
% Format:
% name, xmin, xmax, ymin, ymax

cornerBoxes = {
    "C1",        -200,  -140,   -400,  -200;
    "C2",        -220,  -50,   -540,  -400;
    "C3",          -140,   50,   -400,  -250;
    "C4",    50,   200,   -550,  -250;
    "C5",        50,   380,   -850,  -550;
    "C6",     380,   600,   -850,  -450;
    "C7-8_corkscrew",        500,   610,   -450,  -160;
    "C9",          380,   610,   -160,   -20;
    "C10",          150,   380,   -125,   20;
    "C11",        0,   200,    20,   160;
};

numCorners = size(cornerBoxes,1);

% plot track with corner boxes

figure
plot(x_pos, y_pos, 'b')
hold on
grid on
axis equal
xlabel("xpos")
ylabel("ypos")
title("Track Map with Corner Sections")

for i = 1:numCorners
    name = cornerBoxes{i,1};

    xmin = cornerBoxes{i,2};
    xmax = cornerBoxes{i,3};
    ymin = cornerBoxes{i,4};
    ymax = cornerBoxes{i,5};

    rectangle('Position', [xmin, ymin, xmax-xmin, ymax-ymin], ...
              'EdgeColor', 'r', ...
              'LineWidth', 1.5);

    text(xmin, ymax, name, ...
         'Color', 'r', ...
         'FontSize', 9, ...
         'Interpreter', 'none');
end

% create masks for each corner

cornerMasks = false(length(x_pos), numCorners);

for i = 1:numCorners
    xmin = cornerBoxes{i,2};
    xmax = cornerBoxes{i,3};
    ymin = cornerBoxes{i,4};
    ymax = cornerBoxes{i,5};

    cornerMasks(:,i) = x_pos >= xmin & x_pos <= xmax & ...
                       y_pos >= ymin & y_pos <= ymax & ...
                       valid;
end



%% plot front and rear tire curves together by corner with different color maps

nCols = 3;   % try 3 or 4
nRows = ceil(numCorners / nCols);

figure
tl = tiledlayout(nRows, nCols, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

% Time normalization
tValid = Ft(valid & isfinite(Ft));
tMin = min(tValid);
tMax = max(tValid);

if tMax == tMin
    tMax = tMin + 1;
end

% Different color maps
frontMap = winter(256);   % blue/green style for front
rearMap  = autumn(256);   % red/yellow style for rear

% Convert every time sample into a color index
tNorm = (Ft - tMin) ./ (tMax - tMin);
tNorm = max(0, min(1, tNorm));

tIdx = round(1 + tNorm * 255);
tIdx(~isfinite(tIdx)) = 1;

frontColors = frontMap(tIdx, :);
rearColors  = rearMap(tIdx, :);

for i = 1:numCorners
    nexttile
    mask = cornerMasks(:,i);

    hold on

    % Front: blue/green time gradient
    scatter(alpha_f_deg(mask), Fyf(mask), ...
        14, frontColors(mask,:), ...
        'o', 'filled', ...
        'MarkerFaceAlpha', 0.75, ...
        'MarkerEdgeAlpha', 0.15)

    % Rear: red/yellow time gradient
    scatter(alpha_r_deg(mask), Fyr(mask), ...
        14, rearColors(mask,:), ...
        's', 'filled', ...
        'MarkerFaceAlpha', 0.75, ...
        'MarkerEdgeAlpha', 0.15)

    grid on
    xlabel("\alpha deg")
    ylabel("F_y N")
    title(cornerBoxes{i,1}, 'Interpreter', 'none')

    % Dummy points only for legend
    hF = scatter(nan, nan, 40, [0 0.45 1], 'o', 'filled', ...
        'DisplayName', 'Front');
    hR = scatter(nan, nan, 40, [1 0.25 0], 's', 'filled', ...
        'DisplayName', 'Rear');

    legend([hF hR], 'Location', 'best')
end

title(tl, "Front and Rear Lateral Force vs Slip Angle by Corner")












%% PART 2 method with grade, bank, and curvature

g = 9.81;

theta = -Fpitch;   
phi   = Froll;   

% Vehicle speed magnitude
V = sqrt(Fvx.^2 + Fvy.^2);

v_min_curv = 5.0;

% Curvature acceleration terms
v2_kappa_yaw   = V.^2 .* kappa_yaw;    
v2_kappa_pitch = V.^2 .* kappa_pitch;   
v2_kappa_roll  = V.^2 .* kappa_roll;   

% Remove low speed junk
curv_valid = isfinite(V) & V > v_min_curv & ...
             isfinite(kappa_yaw) & isfinite(theta) & isfinite(phi);

v2_kappa_yaw(~curv_valid)   = nan;
v2_kappa_pitch(~curv_valid) = nan;
v2_kappa_roll(~curv_valid)  = nan;

%% lateral acceleration demand from tires

ay_inertial = v2_kappa_yaw;

% Gravity projected to bank/roll
g_y_body = -g .* cos(theta) .* sin(phi);

ay_tire = ay_inertial - g_y_body * 0;


%% front/rear bicycle lateral force split

Fyf = (b .* m .* ay_tire + Iz .* rdot) ./ L;
Fyr = (a .* m .* ay_tire - Iz .* rdot) ./ L;

%% optional diagnostic plots

figure
tiledlayout(4,1)

nexttile
plot(t, ay_inertial)
grid on
ylabel("a_{y,inertial} [m/s^2]")
title("Lateral Acceleration from Yaw Curvature")

nexttile
plot(t, g_y_body)
grid on
ylabel("g_y body [m/s^2]")
title("Gravity Lateral Component from Bank/Roll")

nexttile
plot(t, ay_tire)
grid on
ylabel("a_{y,tire} [m/s^2]")
title("Tire Lateral Acceleration Demand")

nexttile
plot(t, Fay)
hold on
plot(t, ay_tire)
grid on
xlabel("time [s]")
ylabel("a_y [m/s^2]")
legend("ay", "curvature method")
title("IMU vs Curvature-Based Tire Lateral Acceleration")



nCols = 3;   % try 3 or 4
nRows = ceil(numCorners / nCols);

figure
tl = tiledlayout(nRows, nCols, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

% Time normalization
tValid = Ft(valid & isfinite(Ft));
tMin = min(tValid);
tMax = max(tValid);

if tMax == tMin
    tMax = tMin + 1;
end

% Different color maps
frontMap = winter(256);   % blue/green style for front
rearMap  = autumn(256);   % red/yellow style for rear

% Convert every time sample into a color index
tNorm = (Ft - tMin) ./ (tMax - tMin);
tNorm = max(0, min(1, tNorm));

tIdx = round(1 + tNorm * 255);
tIdx(~isfinite(tIdx)) = 1;

frontColors = frontMap(tIdx, :);
rearColors  = rearMap(tIdx, :);

for i = 1:numCorners
    nexttile
    mask = cornerMasks(:,i);

    hold on

    % Front: blue/green time gradient
    scatter(alpha_f_deg(mask), Fyf(mask), ...
        14, frontColors(mask,:), ...
        'o', 'filled', ...
        'MarkerFaceAlpha', 0.75, ...
        'MarkerEdgeAlpha', 0.15)

    % Rear: red/yellow time gradient
    scatter(alpha_r_deg(mask), Fyr(mask), ...
        14, rearColors(mask,:), ...
        's', 'filled', ...
        'MarkerFaceAlpha', 0.75, ...
        'MarkerEdgeAlpha', 0.15)

    grid on
    xlabel("\alpha deg")
    ylabel("F_y N")
    title(cornerBoxes{i,1}, 'Interpreter', 'none')

    % Dummy points only for legend
    hF = scatter(nan, nan, 40, [0 0.45 1], 'o', 'filled', ...
        'DisplayName', 'Front');
    hR = scatter(nan, nan, 40, [1 0.25 0], 's', 'filled', ...
        'DisplayName', 'Rear');

    legend([hF hR], 'Location', 'best')
end

title(tl, "Front and Rear Lateral Force vs Slip Angle by Corner")





%% debug plot

figure
plot(Fpitch,ay_cg)
hold on
plot(Fpitch,ay_tire)

figure
plot(Froll,ay_cg)
hold on
plot(Froll,ay_tire)




