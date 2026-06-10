clc
close all
clear 

%% opening csv

% data = readtable('FastLaps.csv');
% data = readtable('/home/elijah/PurdueRacing/bags/putnam/oversteer/2026-04-28_150159_merged.csv');
data = readtable('/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv');
%% filtered data

mm =50;
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

Fq = [Fqw Fqx Fqy Fqz];         
Feul = quat2eul(Fq, 'ZYX');   % [yaw pitch roll]

Fyaw   = Feul(:,1);
Fpitch = Feul(:,2);
Froll  = Feul(:,3);

Froll_deg  = rad2deg(Froll);
Fpitch_deg = rad2deg(Fpitch);
Fyaw_deg   = rad2deg(Fyaw);


yaw_unwrapped = unwrap(Fyaw);


% tire temp

fr_T_0 = data.fr_temp_1;
fr_T_1 = data.fr_temp_2;
fr_T_2 = data.fr_temp_3;
fr_T_3 = data.fr_temp_4;






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


t = data.time_s(:);
t = t - t(1);

r = gradient(yaw_unwrapped, t); % yaw 
r = movmean(r, mm);
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


% Plot 

scatter(alpha_f_deg(valid), Fyf(valid), 15, t(valid), 'filled')
grid on
xlabel('Front slip angle \alpha_f [deg]')
ylabel('Front lateral force F_{yf} [N]')
title('Front Axle Lateral Force vs Slip Angle')
cb = colorbar;
ylabel(cb, 'Time [s]')

figure
scatter(alpha_r_deg(valid), Fyr(valid), 15, t(valid), 'filled')
grid on
xlabel('Rear slip angle \alpha_r [deg]')
ylabel('Rear lateral force F_{yr} [N]')
title('Rear Axle Lateral Force vs Slip Angle')
cb = colorbar;
ylabel(cb, 'Time [s]')

figure
scatter(alpha_f_deg(valid), Fyf(valid), 15, 'filled')
hold on
scatter(alpha_r_deg(valid), Fyr(valid), 15, 'filled')
grid on
xlabel('Slip angle [deg]')
ylabel('Axle lateral force [N]')
title('Bicycle Model Lateral Force vs Slip Angle')
legend('Front axle', 'Rear axle', 'Location', 'best')


% dubug plots----------------------------------------------
figure
plot(t,steering_wheel,LineWidth=2)
grid on 

figure 
plot(t,Ffz_fl)
hold on
plot(t,Ffz_fr)
hold on
plot(t,Ffz_rl)
hold on
plot(t,Ffz_rr)

figure
plot(t,Fvx)

figure
plot(t,throttle)

figure
plot(t,Fax)

%%
figure
plot(t,fr_T_0,LineWidth=2)

hold on
grid on


%% Animate 
%% Animate front/rear slip curves + vehicle location
% ------------------------------------------------------------
% USER SETTINGS
% ------------------------------------------------------------
animationSpeed = 5;      % 1 = real time, 5 = 5x faster, 0.5 = 2x slower
frameSkip      = 10;     % larger = faster animation / fewer frames
startAnimationIndex = 1; % set to 26000 if you want to start later like before

% ------------------------------------------------------------
% Get vehicle position
% If position columns exist, use them.
% If not, estimate position by integrating body-frame velocity using yaw.
% ------------------------------------------------------------
varNames = data.Properties.VariableNames;

x_pos = [];
y_pos = [];
locationSource = "";

possibleXY = {
    'odom_x_m',        'odom_y_m'
    'odom_pos_x_m',    'odom_pos_y_m'
    'odom_position_x', 'odom_position_y'
    'position_x',      'position_y'
    'pos_x',           'pos_y'
    'x',               'y'
    'gps_x',           'gps_y'
    'utm_x',           'utm_y'
    'easting',         'northing'
};

for k = 1:size(possibleXY,1)
    ix = find(strcmpi(varNames, possibleXY{k,1}), 1);
    iy = find(strcmpi(varNames, possibleXY{k,2}), 1);

    if ~isempty(ix) && ~isempty(iy)
        x_pos = data.(varNames{ix});
        y_pos = data.(varNames{iy});
        locationSource = "position columns";
        break
    end
end

% Fallback: dead-reckon position from vx, vy, and yaw
if isempty(x_pos) || isempty(y_pos)
    psi = yaw_unwrapped(:);

    x_dot = Fvx(:).*cos(psi) - Fvy(:).*sin(psi);
    y_dot = Fvx(:).*sin(psi) + Fvy(:).*cos(psi);

    x_dot = fillmissing(x_dot, 'linear', 'EndValues', 'nearest');
    y_dot = fillmissing(y_dot, 'linear', 'EndValues', 'nearest');

    x_pos = cumtrapz(t, x_dot);
    y_pos = cumtrapz(t, y_dot);

    locationSource = "dead-reckoned from velocity and yaw";
end

x_pos = x_pos(:);
y_pos = y_pos(:);

% ------------------------------------------------------------
% Animation index setup
% ------------------------------------------------------------
validAnim = valid & ...
            isfinite(x_pos) & isfinite(y_pos) & ...
            isfinite(alpha_f_deg) & isfinite(alpha_r_deg) & ...
            isfinite(Fyf) & isfinite(Fyr);

animIdx = find(validAnim);
animIdx = animIdx(animIdx >= startAnimationIndex);
animIdx = animIdx(1:frameSkip:end);

if isempty(animIdx)
    warning('No valid animation points found. Check valid mask, speed threshold, or startAnimationIndex.');
else

    % ------------------------------------------------------------
    % Create figure
    % ------------------------------------------------------------
    figure('Name','Animated Front/Rear Slip Curves and Vehicle Location');

    tiledlayout(3,1,'TileSpacing','compact','Padding','compact');

    % ------------------------------------------------------------
    % Front slip curve
    % ------------------------------------------------------------
    ax1 = nexttile;
    scatter(ax1, alpha_f_deg(valid), Fyf(valid), 12, t(valid), 'filled');
    hold(ax1, 'on');
    frontDot = plot(ax1, NaN, NaN, 'ro', ...
        'MarkerFaceColor','r', ...
        'MarkerSize',8, ...
        'LineWidth',1.5);

    grid(ax1, 'on');
    xlabel(ax1, 'Front slip angle \alpha_f [deg]');
    ylabel(ax1, 'Front lateral force F_{yf} [N]');
    title(ax1, 'Front Axle Lateral Force vs Slip Angle');
    cb1 = colorbar(ax1);
    ylabel(cb1, 'Time [s]');

    % ------------------------------------------------------------
    % Rear slip curve
    % ------------------------------------------------------------
    ax2 = nexttile;
    scatter(ax2, alpha_r_deg(valid), Fyr(valid), 12, t(valid), 'filled');
    hold(ax2, 'on');
    rearDot = plot(ax2, NaN, NaN, 'ro', ...
        'MarkerFaceColor','r', ...
        'MarkerSize',8, ...
        'LineWidth',1.5);

    grid(ax2, 'on');
    xlabel(ax2, 'Rear slip angle \alpha_r [deg]');
    ylabel(ax2, 'Rear lateral force F_{yr} [N]');
    title(ax2, 'Rear Axle Lateral Force vs Slip Angle');
    cb2 = colorbar(ax2);
    ylabel(cb2, 'Time [s]');

    % ------------------------------------------------------------
    % Vehicle location plot
    % ------------------------------------------------------------
    ax3 = nexttile;
    plot(ax3, x_pos(validAnim), y_pos(validAnim), 'k-', 'LineWidth',1.2);
    hold(ax3, 'on');

    pathSoFar = plot(ax3, NaN, NaN, 'b-', 'LineWidth',2);
    carDot = plot(ax3, NaN, NaN, 'ro', ...
        'MarkerFaceColor','r', ...
        'MarkerSize',9, ...
        'LineWidth',1.5);

    grid(ax3, 'on');
    axis(ax3, 'equal');
    xlabel(ax3, 'X position [m]');
    ylabel(ax3, 'Y position [m]');
    title(ax3, "Vehicle Location, red dot = current time/location, source = " + locationSource);

    % ------------------------------------------------------------
    % Lock axes so the animation does not resize every frame
    % ------------------------------------------------------------
    axis(ax1, 'manual');
    axis(ax2, 'manual');
    axis(ax3, 'manual');

    % ------------------------------------------------------------
    % Animate
    % ------------------------------------------------------------
    % for kk = 1:length(animIdx)
    % 
    %     i = animIdx(kk);
    % 
    %     % Update front current point
    %     set(frontDot, ...
    %         'XData', alpha_f_deg(i), ...
    %         'YData', Fyf(i));
    % 
    %     % Update rear current point
    %     set(rearDot, ...
    %         'XData', alpha_r_deg(i), ...
    %         'YData', Fyr(i));
    % 
    %     % Update vehicle path and current location
    %     currentPathIdx = animIdx(1:kk);
    % 
    %     set(pathSoFar, ...
    %         'XData', x_pos(currentPathIdx), ...
    %         'YData', y_pos(currentPathIdx));
    % 
    %     set(carDot, ...
    %         'XData', x_pos(i), ...
    %         'YData', y_pos(i));
    % 
    %     % Update title with current time
    %     title(ax3, sprintf('Vehicle Location | Current time = %.2f s | source = %s', ...
    %         t(i), locationSource));
    % 
    %     drawnow limitrate
    % 
    %     % Pause based on time spacing and animation speed
    %     if kk < length(animIdx)
    %         dt_anim = t(animIdx(kk+1)) - t(animIdx(kk));
    %         pause(max(dt_anim / animationSpeed, 0.001));
    %     end
    % end
end




%% Slip angle vs lateral force colored by individual tire normal forces
% ------------------------------------------------------------
% This makes 4 plots:
%   1) Front slip curve colored by FL normal force
%   2) Front slip curve colored by FR normal force
%   3) Rear slip curve colored by RL normal force
%   4) Rear slip curve colored by RR normal force
% ------------------------------------------------------------

g   = 9.81;
rho = 1.225;

% ------------------------------------------------------------
% Basic vehicle parameters
% ------------------------------------------------------------
L  = vehicleParams.wheelbase;
b  = vehicleParams.w_dist_f * L;
a  = L - b;

m  = vehicleParams.m;
h  = vehicleParams.cg_z;
tf = vehicleParams.t_f;
tr = vehicleParams.t_r;

% ------------------------------------------------------------
% Aero normal load
% ------------------------------------------------------------
V_for_aero = abs(Fvx);
V_for_aero(~isfinite(V_for_aero)) = 0;

totalDownforce = 0.5 * rho * vehicleParams.ACd .* V_for_aero.^2;

frontAero = vehicleParams.aeroBalance .* totalDownforce;
rearAero  = (1 - vehicleParams.aeroBalance) .* totalDownforce;

% ------------------------------------------------------------
% Axle normal loads
%
% positive Fax = forward acceleration
% front loses load, rear gains load
% ------------------------------------------------------------
Fz_front_axle = m*g*(b/L) - m.*Fax.*h./L + frontAero;
Fz_rear_axle  = m*g*(a/L) + m.*Fax.*h./L + rearAero;

% ------------------------------------------------------------
% Lateral load transfer estimate
%
% This is a simple quasi-static estimate.
% It splits lateral load transfer front/rear based on roll stiffness.
% ------------------------------------------------------------
Kroll_f = vehicleParams.wheelRate_f * tf^2 / 2;
Kroll_r = vehicleParams.wheelRate_r * tr^2 / 2;

rollDist_f = Kroll_f / (Kroll_f + Kroll_r);
rollDist_r = Kroll_r / (Kroll_f + Kroll_r);

totalLatTransfer = m .* Fay .* h;

dFz_front_lat = rollDist_f .* totalLatTransfer ./ tf;
dFz_rear_lat  = rollDist_r .* totalLatTransfer ./ tr;

% ------------------------------------------------------------
% Individual tire normal forces
%
% Sign convention:
% If the left/right look swapped, switch the plus/minus signs below.
% ------------------------------------------------------------
Fz_FL = Fz_front_axle./2 - dFz_front_lat./2;
Fz_FR = Fz_front_axle./2 + dFz_front_lat./2;

Fz_RL = Fz_rear_axle./2 - dFz_rear_lat./2;
Fz_RR = Fz_rear_axle./2 + dFz_rear_lat./2;

% ------------------------------------------------------------
% Valid points
% ------------------------------------------------------------
validFz4 = valid & ...
           isfinite(Fz_FL) & isfinite(Fz_FR) & ...
           isfinite(Fz_RL) & isfinite(Fz_RR) & ...
           Fz_FL > 0 & Fz_FR > 0 & Fz_RL > 0 & Fz_RR > 0;

% ------------------------------------------------------------
% Plot 4 slip-force plots colored by tire normal force
% ------------------------------------------------------------
figure('Name','Slip Force Curves Colored by Individual Tire Normal Force')

subplot(2,2,1)
scatter(alpha_f_deg(validFz4), Fyf(validFz4), 18, Fz_FL(validFz4), 'filled')
grid on
xlabel('Front slip angle \alpha_f [deg]')
ylabel('Front lateral force F_{yf} [N]')
title('Front Slip Curve Colored by F_{z,FL}')
cb = colorbar;
ylabel(cb, 'F_{z,FL} [N]')

subplot(2,2,2)
scatter(alpha_f_deg(validFz4), Fyf(validFz4), 18, Fz_FR(validFz4), 'filled')
grid on
xlabel('Front slip angle \alpha_f [deg]')
ylabel('Front lateral force F_{yf} [N]')
title('Front Slip Curve Colored by F_{z,FR}')
cb = colorbar;
ylabel(cb, 'F_{z,FR} [N]')

subplot(2,2,3)
scatter(alpha_r_deg(validFz4), Fyr(validFz4), 18, Fz_RL(validFz4), 'filled')
grid on
xlabel('Rear slip angle \alpha_r [deg]')
ylabel('Rear lateral force F_{yr} [N]')
title('Rear Slip Curve Colored by F_{z,RL}')
cb = colorbar;
ylabel(cb, 'F_{z,RL} [N]')

subplot(2,2,4)
scatter(alpha_r_deg(validFz4), Fyr(validFz4), 18, Fz_RR(validFz4), 'filled')
grid on
xlabel('Rear slip angle \alpha_r [deg]')
ylabel('Rear lateral force F_{yr} [N]')
title('Rear Slip Curve Colored by F_{z,RR}')
cb = colorbar;
ylabel(cb, 'F_{z,RR} [N]')








%% by corner 

%% Plot same corner every lap using a spatial corner gate
% ------------------------------------------------------------
% Goal:
% Select one physical corner on the track, then plot the slip-force
% curves for every lap through only that corner.
%
% This assumes x_pos and y_pos already exist from your animation code.
% ------------------------------------------------------------

%% USER SETTINGS

cornerName = 'Selected Corner';

% Choose selection mode:
% 'box'    = use x/y limits
% 'circle' = use center point and radius
cornerSelectMode = 'box';

% ------------------------------------------------------------
% BOX MODE SETTINGS
% Change these based on the corner location from the path plot.
% ------------------------------------------------------------
xMinCorner = -400;
xMaxCorner =  -250;

yMinCorner =  151;
yMaxCorner =  240;

% ------------------------------------------------------------
% CIRCLE MODE SETTINGS
% Change these if using circle mode.
% ------------------------------------------------------------
cornerCenterX = 0;
cornerCenterY = 60;
cornerRadius  = 30;

% This separates each pass through the corner.
% If the time gap between selected points is larger than this,
% it counts as a new lap/pass through the corner.
cornerGapTime = 2.0;   % [s]

% Plot options
plotEachLapSeparately = false;  % true = one figure per lap/pass
markerSize = 18;

% First plot the full path so you can pick the corner bounds

figure('Name','Pick Corner Region From Vehicle Path')
plot(x_pos(validFz4), y_pos(validFz4), 'k.', 'MarkerSize', 4)
grid on
axis equal
xlabel('X position [m]')
ylabel('Y position [m]')
title('Use this plot to choose x/y bounds or circle center for the corner')

hold on

if strcmpi(cornerSelectMode, 'box')
    plot([xMinCorner xMaxCorner xMaxCorner xMinCorner xMinCorner], ...
         [yMinCorner yMinCorner yMaxCorner yMaxCorner yMinCorner], ...
         'r-', 'LineWidth', 2)
else
    th = linspace(0, 2*pi, 300);
    plot(cornerCenterX + cornerRadius*cos(th), ...
         cornerCenterY + cornerRadius*sin(th), ...
         'r-', 'LineWidth', 2)
end

legend('Full vehicle path', 'Selected corner gate', 'Location', 'best')

%% Build spatial corner mask

if strcmpi(cornerSelectMode, 'box')

    cornerSpatialMask = x_pos >= xMinCorner & x_pos <= xMaxCorner & ...
                        y_pos >= yMinCorner & y_pos <= yMaxCorner;

elseif strcmpi(cornerSelectMode, 'circle')

    distFromCornerCenter = sqrt((x_pos - cornerCenterX).^2 + ...
                                (y_pos - cornerCenterY).^2);

    cornerSpatialMask = distFromCornerCenter <= cornerRadius;

else
    error('cornerSelectMode must be either box or circle')
end

% Final mask: valid data AND inside selected corner
cornerMask = validFz4 & cornerSpatialMask;

fprintf('Total points inside selected corner: %d\n', sum(cornerMask));

if sum(cornerMask) < 5
    warning('Very few points selected. Adjust the corner bounds/radius.')
end

%% Split selected corner data into each lap/pass

idxCorner = find(cornerMask);

if isempty(idxCorner)

    warning('No data found inside selected corner.')

else

    timeGaps = diff(t(idxCorner));

    newPassStart = [true; timeGaps > cornerGapTime];

    passID = cumsum(newPassStart);

    numPasses = max(passID);

    fprintf('Detected %d passes/laps through this corner.\n', numPasses);

    % Store pass number for every sample
    cornerPassNumber = NaN(size(t));
    cornerPassNumber(idxCorner) = passID;

    %% Check selected corner points on vehicle path

    figure('Name','Selected Corner Points Across All Laps')
    plot(x_pos(validFz4), y_pos(validFz4), 'k-', 'LineWidth', 1)
    hold on
    scatter(x_pos(cornerMask), y_pos(cornerMask), 25, cornerPassNumber(cornerMask), 'filled')
    grid on
    axis equal
    xlabel('X position [m]')
    ylabel('Y position [m]')
    title(['Selected Corner Across All Laps: ', cornerName])
    cb = colorbar;
    ylabel(cb, 'Lap/pass number')
    legend('Full path', 'Selected corner points', 'Location', 'best')

    %% Plot four slip-force curves for the selected corner across all laps
    % Top row: front slip curve colored by FL and FR normal force
    % Bottom row: rear slip curve colored by RL and RR normal force

    figure('Name',['Slip Force Curves for ', cornerName, ' Across All Laps'])

    subplot(2,2,1)
    scatter(alpha_f_deg(cornerMask), Fyf(cornerMask), markerSize, Fz_FL(cornerMask), 'filled')
    grid on
    xlabel('Front slip angle \alpha_f [deg]')
    ylabel('Front lateral force F_{yf} [N]')
    title(['Front Curve Colored by F_{z,FL} | ', cornerName])
    cb = colorbar;
    ylabel(cb, 'F_{z,FL} [N]')

    subplot(2,2,2)
    scatter(alpha_f_deg(cornerMask), Fyf(cornerMask), markerSize, Fz_FR(cornerMask), 'filled')
    grid on
    xlabel('Front slip angle \alpha_f [deg]')
    ylabel('Front lateral force F_{yf} [N]')
    title(['Front Curve Colored by F_{z,FR} | ', cornerName])
    cb = colorbar;
    ylabel(cb, 'F_{z,FR} [N]')

    subplot(2,2,3)
    scatter(alpha_r_deg(cornerMask), Fyr(cornerMask), markerSize, Fz_RL(cornerMask), 'filled')
    grid on
    xlabel('Rear slip angle \alpha_r [deg]')
    ylabel('Rear lateral force F_{yr} [N]')
    title(['Rear Curve Colored by F_{z,RL} | ', cornerName])
    cb = colorbar;
    ylabel(cb, 'F_{z,RL} [N]')

    subplot(2,2,4)
    scatter(alpha_r_deg(cornerMask), Fyr(cornerMask), markerSize, Fz_RR(cornerMask), 'filled')
    grid on
    xlabel('Rear slip angle \alpha_r [deg]')
    ylabel('Rear lateral force F_{yr} [N]')
    title(['Rear Curve Colored by F_{z,RR} | ', cornerName])
    cb = colorbar;
    ylabel(cb, 'F_{z,RR} [N]')

    %% Optional: plot each lap/pass separately

    if plotEachLapSeparately

        for lapNum = 1:numPasses

            thisLapMask = cornerMask & cornerPassNumber == lapNum;

            if sum(thisLapMask) < 3
                continue
            end

            figure('Name',sprintf('%s - Lap/Pass %d', cornerName, lapNum))

            subplot(2,2,1)
            scatter(alpha_f_deg(thisLapMask), Fyf(thisLapMask), markerSize, Fz_FL(thisLapMask), 'filled')
            grid on
            xlabel('Front slip angle \alpha_f [deg]')
            ylabel('Front lateral force F_{yf} [N]')
            title(sprintf('Lap %d Front Curve Colored by F_{z,FL}', lapNum))
            cb = colorbar;
            ylabel(cb, 'F_{z,FL} [N]')

            subplot(2,2,2)
            scatter(alpha_f_deg(thisLapMask), Fyf(thisLapMask), markerSize, Fz_FR(thisLapMask), 'filled')
            grid on
            xlabel('Front slip angle \alpha_f [deg]')
            ylabel('Front lateral force F_{yf} [N]')
            title(sprintf('Lap %d Front Curve Colored by F_{z,FR}', lapNum))
            cb = colorbar;
            ylabel(cb, 'F_{z,FR} [N]')

            subplot(2,2,3)
            scatter(alpha_r_deg(thisLapMask), Fyr(thisLapMask), markerSize, Fz_RL(thisLapMask), 'filled')
            grid on
            xlabel('Rear slip angle \alpha_r [deg]')
            ylabel('Rear lateral force F_{yr} [N]')
            title(sprintf('Lap %d Rear Curve Colored by F_{z,RL}', lapNum))
            cb = colorbar;
            ylabel(cb, 'F_{z,RL} [N]')

            subplot(2,2,4)
            scatter(alpha_r_deg(thisLapMask), Fyr(thisLapMask), markerSize, Fz_RR(thisLapMask), 'filled')
            grid on
            xlabel('Rear slip angle \alpha_r [deg]')
            ylabel('Rear lateral force F_{yr} [N]')
            title(sprintf('Lap %d Rear Curve Colored by F_{z,RR}', lapNum))
            cb = colorbar;
            ylabel(cb, 'F_{z,RR} [N]')
        end
    end
end