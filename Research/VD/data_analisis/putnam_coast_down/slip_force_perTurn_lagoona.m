clc
close all
clear

%% opening csv

% data = readtable('FastLaps.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/putnam/oversteer/2026-04-28_150159_merged.csv');
data = readtable('/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv');
% data = readtable('/home/elijah/bag_files/VD/laguna/comp/2025-07-24_175839_merged.csv');

%% filtered data

mm = 20;

Ft = movmean(data.time_s, mm);

Fax = movmean(data.a_x, mm);
Fay = movmean(data.a_y, mm);
Faz = movmean(data.a_z, mm);

Ffz_fr = movmean(data.fr_load_n, mm);
Ffz_fl = movmean(data.fl_load_n, mm);
Ffz_rr = movmean(data.rr_load_n, mm);
Ffz_rl = movmean(data.rl_load_n, mm);

Fvx = movmean(data.odom_vx_mps, mm);
Fvy = movmean(data.odom_vy_mps, mm);

Frpm = movmean(data.engine_rpm, mm);
throttle = data.throttle_pct;
Fgear = movmean(data.current_gear, mm);
FT_e = movmean(data.est_drive_torque_nm, mm);
Fbrake = movmean(data.front_brake_pressure_kpa, mm);

steering_wheel = movmean(data.steer_wheel_ang_deg, mm);

toe_angle = 0.333 + steering_wheel ./ 15.015;
toe_rad = deg2rad(toe_angle);

Fqx = movmean(data.odom_qx, mm);
Fqy = movmean(data.odom_qy, mm);
Fqz = movmean(data.odom_qz, mm);
Fqw = movmean(data.odom_qw, mm);

Fwz = movmean(data.odom_wz_rads, mm);
Fwx = movmean(data.odom_wx_rads, mm);
Fwy = movmean(data.odom_wy_rads, mm);

x_pos = data.odom_px_m;
y_pos = data.odom_py_m;

%% tire temperature

fr_T_0 = data.fr_temp_1;
fr_T_1 = data.fr_temp_2;
fr_T_2 = data.fr_temp_3;
fr_T_3 = data.fr_temp_4;

%% quaternion to yaw, pitch, roll

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

%% time, velocity, distance

t = data.time_s(:);
t = t - t(1);

V = sqrt(Fvx.^2 + Fvy.^2);

ds = [0; cumsum(0.5 .* (V(1:end-1) + V(2:end)) .* diff(t))];

%% curvature from yaw, pitch, and roll rate

v_min_curv = 2.0;

kappa_yaw   = nan(size(V));
kappa_pitch = nan(size(V));
kappa_roll  = nan(size(V));

curv_valid = isfinite(V) & V > v_min_curv;

kappa_yaw(curv_valid)   = yaw_dot(curv_valid)   ./ V(curv_valid);
kappa_pitch(curv_valid) = pitch_dot(curv_valid) ./ V(curv_valid);
kappa_roll(curv_valid)  = roll_dot(curv_valid)  ./ V(curv_valid);

%% vehicle parameters

vehicleParams.wheelbase   = 2.9718;   % wheelbase [m]
vehicleParams.w_dist_f    = 0.42;     % front weight distribution
vehicleParams.m           = 787;      % mass [kg]
vehicleParams.frontalArea = 1;        % frontal area [m^2]
vehicleParams.inertia     = 1000;     % yaw inertia [kg m^2]

L  = vehicleParams.wheelbase;
b  = vehicleParams.w_dist_f * L;
a  = L - b;

m  = vehicleParams.m;
Iz = vehicleParams.inertia;

g = 9.81;

%% yaw acceleration

r = Fwz;

rdot = gradient(r, t);
rdot = movmean(rdot, mm);

%% lateral acceleration method

theta = -Fpitch;
phi   = Froll;

v_min_curv = 5.0;

v2_kappa_yaw   = V.^2 .* kappa_yaw;
v2_kappa_pitch = V.^2 .* kappa_pitch;
v2_kappa_roll  = V.^2 .* kappa_roll;

curv_valid = isfinite(V) & V > v_min_curv & ...
             isfinite(kappa_yaw) & ...
             isfinite(theta) & ...
             isfinite(phi);

v2_kappa_yaw(~curv_valid)   = nan;
v2_kappa_pitch(~curv_valid) = nan;
v2_kappa_roll(~curv_valid)  = nan;

% lateral acceleration from yaw curvature
ay_inertial = v2_kappa_yaw;

% gravity projected into lateral body axis from roll/bank
g_y_body = -g .* cos(theta) .* sin(phi);

% Set this to true if you want to include bank/roll gravity correction.
useBankRollGravity = false;

if useBankRollGravity
    ay_tire = ay_inertial - g_y_body;
else
    ay_tire = ay_inertial;
end

%% front/rear bicycle lateral force split

Fyf = (b .* m .* ay_tire + Iz .* rdot) ./ L;
Fyr = (a .* m .* ay_tire - Iz .* rdot) ./ L;

%% slip angle calculation

delta = toe_rad;

vx_min = 10.0;

vx_safe = Fvx;
vx_safe(abs(vx_safe) < vx_min) = nan;

alpha_f = delta - atan2(Fvy + a .* r, vx_safe);
alpha_r =       - atan2(Fvy - b .* r, vx_safe);

alpha_f_deg = rad2deg(alpha_f);
alpha_r_deg = rad2deg(alpha_r);

%% valid mask

valid = isfinite(alpha_f_deg) & ...
        isfinite(alpha_r_deg) & ...
        isfinite(Fyf) & ...
        isfinite(Fyr) & ...
        isfinite(x_pos) & ...
        isfinite(y_pos) & ...
        abs(Fvx) > vx_min;

cornerPolys = {
    "C1", [
         -54.37, -158.40;   % G1 A
        -160.00, -330.00;   % C1 bulge
        -173.39, -475.53;   % extra gate A between C1/C2
        -246.71, -504.38;   % extra gate B between C1/C2
        -157.83,  -97.60    % G1 B
    ];

    "C2", [
        -173.39, -475.53;   % G2 A
         -57.41, -444.47;   % G2 B
        -140.00, -600.00;   % C2 bulge
        -246.71, -504.38    % extra gate B between C1/C2
    ];

    "C3", [
        -173.39, -475.53;   % G2 A
        -150.00, -340.00;   % C3 support point
        -105.00, -250.00;   % C3 bulge
          31.90, -220.86;   % G3 A
           4.88, -337.70;   % G3 B
         -57.41, -444.47    % G2 B
    ];

    "C4", [
          31.90, -220.86;   % G3 A
         215.00, -285.00;   % C4 bulge
         231.22, -549.84;   % G4 A
         112.78, -529.96;   % G4 B
           4.88, -337.70    % G3 B
    ];

    "C5", [
         231.22, -549.84;   % G4 A
         358.25, -741.30;   % G5 A
         376.93, -858.70;   % G5 B
          60.00, -880.00;   % C5 bulge
         112.78, -529.96    % G4 B
    ];

    "C6", [
         358.25, -741.30;   % G5 A
         517.23, -581.52;   % G6 A
         636.77, -590.48;   % G6 B
         625.00, -790.00;   % C6 bulge
         376.93, -858.70    % G5 B
    ];

    "C7", [
         517.23, -581.52;   % G6 A
         476.62, -191.70;   % G7 A
         596.58, -193.10;   % G7 B
         635.00, -330.00;   % C7 bulge
         636.77, -590.48    % G6 B
    ];

    "C8", [
         476.62, -191.70;   % G7 A
         424.04, -131.52;   % G8_5 A, new split gate
         368.48,   18.52;   % G8_5 B, new split gate
         600.00,   10.00;   % C8 bulge
         596.58, -193.10    % G7 B
    ];

    "C9", [
         424.04, -131.52;   % G8_5 A
          70.00,  -50.00;   % G8 A
         264.00,  129.88;   % G8 B
         450.00,   85.00;   % C9 bulge
         368.48,   18.52    % G8_5 B
    ];

    "C10", [
          70.00,  -50.00;   % G8 A
         -54.37, -158.40;   % G1 A
        -157.83,  -97.60;   % G1 B
          80.00,  190.00;   % C10 bulge
         264.00,  129.88    % G8 B
    ];
};
%% create masks for each polygon

numCorners = size(cornerPolys, 1);

cornerMasks = false(length(x_pos), numCorners);
alreadyAssigned = false(length(x_pos), 1);

for i = 1:numCorners
    P = cornerPolys{i,2};

    insideCorner = inpolygon(x_pos, y_pos, P(:,1), P(:,2));

    cornerMasks(:,i) = insideCorner & valid & ~alreadyAssigned;

    alreadyAssigned = alreadyAssigned | cornerMasks(:,i);
end

%% plot track with corner polygon sections

figure
plot(x_pos, y_pos, 'b')
hold on
grid on
axis equal
xlabel("xpos")
ylabel("ypos")
title("Track Map with Corner Polygon Sections")

for i = 1:numCorners

    name = cornerPolys{i,1};
    P = cornerPolys{i,2};

    poly_x = P(:,1);
    poly_y = P(:,2);

    patch(poly_x, poly_y, 'r', ...
        'FaceColor', 'none', ...
        'EdgeColor', 'r', ...
        'LineWidth', 1.5);

    text(mean(poly_x), mean(poly_y), name, ...
        'Color', 'r', ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'Interpreter', 'none');

end

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
legend("IMU ay", "curvature method")
title("IMU vs Curvature-Based Tire Lateral Acceleration")

%% lateral force vs slip angle per corner

nCols = 3;
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
frontMap = winter(256);
rearMap  = autumn(256);

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

    scatter(alpha_f_deg(mask), Fyf(mask), ...
        14, frontColors(mask,:), ...
        'o', 'filled', ...
        'MarkerFaceAlpha', 0.75, ...
        'MarkerEdgeAlpha', 0.15)

    scatter(alpha_r_deg(mask), Fyr(mask), ...
        14, rearColors(mask,:), ...
        's', 'filled', ...
        'MarkerFaceAlpha', 0.75, ...
        'MarkerEdgeAlpha', 0.15)

    grid on
    xlabel("\alpha [deg]")
    ylabel("F_y [N]")
    title(cornerPolys{i,1}, 'Interpreter', 'none')

    hF = scatter(nan, nan, 40, [0 0.45 1], 'o', 'filled', ...
        'DisplayName', 'Front');

    hR = scatter(nan, nan, 40, [1 0.25 0], 's', 'filled', ...
        'DisplayName', 'Rear');

    legend([hF hR], 'Location', 'best')

end

title(tl, "Front and Rear Lateral Force vs Slip Angle by Corner")




