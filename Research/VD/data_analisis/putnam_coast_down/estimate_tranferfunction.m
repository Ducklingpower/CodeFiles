clc
close all
clear 

%% opening csv

% data = readtable('FastLaps.csv');
data = readtable('/home/elijah/PurdueRacing/bags/putnum_AI_data/csv_output/tried_to_get_step.csv');

%% raw data

% 
boost_aim = data.boost_aim_kpa;
boost_pressure = data.boost_pressure_kpa;



t = data.time_s;
t = t-t(1);

% throttle_com = data.joy_accelerator_cmd;

ax = data.a_x;
ay = data.a_y;
az = data.a_z;

vx = data.odom_vx_mps;
vy = data.odom_vy_mps;

rpm = data.engine_rpm;
throttle = data.throttle_pct;
gear = data.current_gear;
T_e = data.est_drive_torque_nm;
brake = data.front_brake_pressure_kpa;


qx = data.odom_qx;
qy = data.odom_qy;
qz = data.odom_qz;
qw = data.odom_qw;

q = [qw qx qy qz];         
eul = quat2eul(q, 'ZYX');   % [yaw pitch roll]

yaw   = eul(:,1);
pitch = eul(:,2);
roll  = eul(:,3);

roll_deg  = rad2deg(roll);
pitch_deg = rad2deg(pitch);
yaw_deg   = rad2deg(yaw);

%% filtered data

mm = 20;
Ft = movmean(data.time_s,mm);

Fax = movmean(data.a_x,mm);
Fay = movmean(data.a_y,mm);
Faz = movmean(data.a_z,mm);

Fvx = movmean(data.odom_vx_mps,mm);
Fvy = movmean(data.odom_vy_mps,mm);

Frpm = movmean(data.engine_rpm,mm);
Fthrottle = movmean(data.throttle_pct,mm);
Fgear = movmean(data.current_gear,mm);
FT_e = movmean(data.est_drive_torque_nm,mm);
Fbrake = movmean(data.front_brake_pressure_kpa,mm);


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



m = 787;
r = 0.3;
roh = 1.22;
Cd = 0.3;
g = 9.81;

%% physics 
air      = 0.5*roh*1*Cd.*vx.^2;
F_pitch  = m*g.*sin(pitch);
body     = m.*ax;
Force    = body + air - F_pitch;

Fair     = 0.5*roh*1*Cd.*Fvx.^2;
FF_pitch = m*g .*sin(Fpitch);
Fbody    = m.*Fax;
FForce   = Fbody + Fair - FF_pitch;  

torqueAtTire  = Force.*r;
FtorqueAtTire = FForce.*r;


diff_ratio = 3;
eff_diff   = 0.99;
gear_eff   = 0.91;

gear_ratio = zeros(size(gear));
gear_ratio(gear == 2) = 1.8667;
gear_ratio(gear ~= 2) = 2.9167; 

total_ratio = eff_diff * diff_ratio * gear_ratio * gear_eff;

F_tire_e = T_e./r;

torqueAtengine   = torqueAtTire  ./ total_ratio;
FtorqueAtengine  = FtorqueAtTire ./ total_ratio;
torqueAtengine_e = T_e           ./ total_ratio;   


%%
figure

ha(1) = subplot(3,1,1);
plot(t, throttle,LineWidth=2)
grid on
xlabel("time")
ylabel("throttle")

ha(2) = subplot(3,1,2);
plot(t, FForce, "r",LineWidth=2)
hold on
plot(t, F_tire_e, "b",LineWidth=2)
grid on
xlabel("time")
ylabel("Torque")
legend("Calculated forve","Modetc Torque estimate to force")


ha(3) = subplot(3,1,3);
plot(t,gear,LineWidth=2)
grid on
xlabel("time")
ylabel("gear")
% Link only x-axes
linkaxes(ha, "x")

zoom on

%% 

% 
% for i = 1:length(F_tire_e)
%     if F_tire_e(i) <= 6
%         F_tire_e(i)=0;
%     end
% 
%     if throttle(i) <= 6
%         throttle(i) =0;
%     end
% end
% 


%% tranfer function
F_tire_e_cut = FForce(130000:140000);
throttle_cut = throttle(130000:140000);


dt = mean(diff(t));
data = iddata(F_tire_e_cut, throttle_cut, dt);
np = 1;
nz = 0;
sys = tfest(data, np, nz);
disp(sys)


[num, den] = tfdata(sys, 'v');   

sys_ct = tf(num, den);
disp(sys_ct)


sys_dt = c2d(sys_ct, dt, 'zoh');
disp(sys_dt)
t_sim = t - t(1);                        

% lsim 
F_tire_sim = lsim(sys_ct, throttle, t_sim);

fit_pct = 100 * (1 - norm(F_tire_e - F_tire_sim) / norm(F_tire_e - mean(F_tire_e)));
fprintf('\nFit: %.1f%%\n', fit_pct)

figure

ha(1) = subplot(2,1,1)
plot(t_sim, throttle,   'b', 'DisplayName', 'Measured',LineWidth=2)
hold on
plot(t_sim, throttle, 'r', 'DisplayName', 'Commanded',LineWidth=2)
grid on
xlabel('Time (s)')
ylabel('Throttle (%)')
legend

ha(2) = subplot(2,1,2)
plot(t_sim, F_tire_e,   'b', 'DisplayName', 'Measured',LineWidth=2)
hold on
plot(t_sim, F_tire_sim, 'r-.', 'DisplayName', 'TF Simulated',LineWidth=2)
grid on
xlabel('Time (s)')
ylabel('Tire Force (N)')
legend

linkaxes(ha, 'x')






%% engine map look up

% 100 percent boost map
map_boost_raw = readtable('engine_map_boosted_reduced.csv', ...
    'VariableNamingRule','preserve');

map_boost_throttle_bp = [0.0, 0.3, 1.0];
map_boost_rpm_bp      = map_boost_raw{:, 1};
map_boost_torque      = map_boost_raw{:, 2:end};

valid_rows_boost      = isfinite(map_boost_rpm_bp);
map_boost_rpm_bp      = map_boost_rpm_bp(valid_rows_boost);
map_boost_torque      = map_boost_torque(valid_rows_boost, :);


% 0 percent boost / no boost map
map_noboost_raw = readtable('engine_map_no_boost.csv', ...
    'VariableNamingRule','preserve');

% CSV columns are rpm, 0, 50, 100
% Convert 0, 50, 100 percent throttle into normalized throttle
map_noboost_throttle_bp = [0.0, 0.5, 1.0];
map_noboost_rpm_bp      = map_noboost_raw{:, 1};
map_noboost_torque      = map_noboost_raw{:, 2:end};

valid_rows_noboost      = isfinite(map_noboost_rpm_bp);
map_noboost_rpm_bp      = map_noboost_rpm_bp(valid_rows_noboost);
map_noboost_torque      = map_noboost_torque(valid_rows_noboost, :);


% Clean throttle and rpm signals
throttle_norm  = throttle / 100;
rpm_clean      = rpm;
throttle_clean = throttle_norm;

rpm_clean(~isfinite(rpm_clean)) = map_boost_rpm_bp(1);
throttle_clean(~isfinite(throttle_clean)) = 0;


% Clamp rpm and throttle separately for each map
rpm_clean_boost = min(max(rpm_clean, ...
    map_boost_rpm_bp(1)), map_boost_rpm_bp(end));

rpm_clean_noboost = min(max(rpm_clean, ...
    map_noboost_rpm_bp(1)), map_noboost_rpm_bp(end));

throttle_clean_boost = min(max(throttle_clean, ...
    map_boost_throttle_bp(1)), map_boost_throttle_bp(end));

throttle_clean_noboost = min(max(throttle_clean, ...
    map_noboost_throttle_bp(1)), map_noboost_throttle_bp(end));


% Interpolate each torque map independently
T_map_boost = interp2( ...
    map_boost_throttle_bp, ...
    map_boost_rpm_bp, ...
    map_boost_torque, ...
    throttle_clean_boost, ...
    rpm_clean_boost, ...
    'linear');

T_map_noboost = interp2( ...
    map_noboost_throttle_bp, ...
    map_noboost_rpm_bp, ...
    map_noboost_torque, ...
    throttle_clean_noboost, ...
    rpm_clean_noboost, ...
    'linear');



%% alpha calc

boost_diff = boost_aim - boost_pressure;

alpha = zeros(size(t));

% Only calculate boost ratio when boost is actually being commanded
boost_cmd_idx = boost_aim > 0 & isfinite(boost_aim) & isfinite(boost_pressure);

alpha(boost_cmd_idx) = boost_pressure(boost_cmd_idx) ./ boost_aim(boost_cmd_idx);

% Clamp alpha between 0 and 1
alpha(~isfinite(alpha)) = 0;
alpha = min(max(alpha, 0), 1);


% Blend between no-boost and boosted engine maps
%
% alpha = 0 -> use no-boost torque map
% alpha = 1 -> use 100 percent boost torque map
T_map = (1 - alpha) .* T_map_noboost + alpha .* T_map_boost;


% Remove torque when throttle is basically closed
T_map(throttle_norm <= 0.06) = 0;


%%
% first order tire/engine force response

tau = 0.153;   % seconds

% Physical steady-state tire force estimate
% Engine torque -> wheel torque -> tire force
K = (T_map .* total_ratio) ./ 0.3;

% K(throttle_norm <= 0.06) = 0;
% K(T_map <= 0)            = 0;
% K(~isfinite(K))          = 0;

% Make time start at zero
t_lsim = t - t(1);

% Continuous first-order low-pass:
% tau*y_dot + y = K
A = -1/tau;
B =  1/tau;
C =  1;
D =  0;

sys_first_order = ss(A, B, C, D);

% Important:
% If the system is already producing force at the first sample,
% do not force the model to start from zero.
y0 = K(1);

F_tire_model = lsim(sys_first_order, K, t_lsim, y0);
F_tire_model = K;

%%

figure

ha4(1) = subplot(5,1,1);
    plot(t, throttle, 'k', 'LineWidth', 1.5)
    ylabel('Throttle (%)')
    grid on

ha4(2) = subplot(5,1,2);
    plot(t, FForce, 'b', 'LineWidth', 1.5, ...
        'DisplayName', 'Measured F_{tire}')
    hold on
    plot(t, (T_map_boost.*total_ratio) ./ 0.3, 'k', 'LineWidth', 1.5, ...
        'DisplayName', '100% Boost Torque Map')
    hold on
    plot(t, (T_map_noboost.*total_ratio) ./ 0.3, 'g', 'LineWidth', 1.5, ...
        'DisplayName', '0% Boost Torque Map')
    ylabel('Tire Force N')
    legend
    grid on
    title('Torque from 100% Boost Engine Map')

% ha4(3) = subplot(5,1,3);
%     plot(t, FForce, 'b', 'LineWidth', 1.5, ...
%         'DisplayName', 'Measured F_{tire}')
%     hold on
%     plot(t, K, 'r', 'LineWidth', 1.5, ...
%         'DisplayName', 'K(t) = T_{map} ratio/r')
%     hold on
% 
%     ylabel('Tire Force N')
%     legend
%     grid on
%     title('Physics-based gain K(t) vs Measured')

ha4(3) = subplot(5,1,3);
    plot(t, alpha, 'b', 'LineWidth', 1.5, ...
        'DisplayName', 'alpah')

    ylabel('alpha')
    legend
    grid on
    title('Physics-based gain K(t) vs Measured')

ha4(4) = subplot(5,1,4);
    plot(t, FForce, 'b', 'LineWidth', 1.5, ...
        'DisplayName', 'Measured')
    hold on
    plot(t, F_tire_model, 'r', 'LineWidth', 1.5, ...
        'DisplayName', 'TF sim * blended map')
    hold on
    plot(t,F_tire_e,'g', 'LineWidth', 1.5, 'DisplayName','estimated by motec')

    ylabel('Tire Force (N)')
    legend
    grid on

ha4(5) = subplot(5,1,5);
    plot(t_sim, FForce, 'b', 'LineWidth', 1.5, ...
        'DisplayName', 'Measured')
    hold on
    plot(t_sim, F_tire_sim, 'r-.', 'LineWidth', 1.5, ...
        'DisplayName', 'TF Simulated')
    grid on
    xlabel('Time (s)')
    ylabel('Tire Force (N)')
    legend

linkaxes(ha4, 'x')

sgtitle('F_{tire} = TF_{norm}(z) × [T_{map,blend}(t) × ratio / r]')

%% figure for meeting 

figure
ha(1) = subplot(3,1,1)
plot(t_sim, FForce,   'b', 'DisplayName', 'Measured',LineWidth=2)
hold on
plot(t_sim, F_tire_sim, 'r-.', 'DisplayName', 'TF Simulated',LineWidth=2)
grid on
xlabel('Time (s)')
ylabel('Tire Force (N)')
legend

ha(2) = subplot(3,1,2)
plot(t_sim, throttle, 'k')
grid on
xlabel('Time (s)')
ylabel('Throttle')

ha(3) = subplot(3,1,3)
plot(t_sim, boost_pressure)
grid on
xlabel('Time (s)')
ylabel('boost ')

linkaxes(ha, "x")