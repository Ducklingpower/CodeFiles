clc
close all
clear 

%% opening csv

data = readtable('FastLaps.csv');

%% raw data
t = data.time_s;
t = t-t(1);

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

boost_aim = data.boost_aim_kpa;
boost_pressure = data.boost_pressure_kpa;


%% filtered data
Ft = movmean(data.time_s,10);

Fax = movmean(data.a_x,10);
Fay = movmean(data.a_y,10);
Faz = movmean(data.a_z,10);

Fvx = movmean(data.odom_vx_mps,10);
Fvy = movmean(data.odom_vy_mps,10);

Frpm = movmean(data.engine_rpm,10);
Fthrottle = movmean(data.throttle_pct,10);
Fgear = movmean(data.current_gear,10);
FT_e = movmean(data.est_drive_torque_nm,10);
Fbrake = movmean(data.front_brake_pressure_kpa,10);


Fqx = movmean(data.odom_qx,10);
Fqy = movmean(data.odom_qy,10);
Fqz = movmean(data.odom_qz,10);
Fqw = movmean(data.odom_qw,10);

Fq = [Fqw Fqx Fqy Fqz];         
Feul = quat2eul(Fq, 'ZYX');   % [yaw pitch roll]

Fyaw   = Feul(:,1);
Fpitch = Feul(:,2);
Froll  = Feul(:,3);

Froll_deg  = rad2deg(Froll);
Fpitch_deg = rad2deg(Fpitch);
Fyaw_deg   = rad2deg(Fyaw);



m = 787;
r = 0.31;
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
plot(t, throttle)
grid on
xlabel("time")
ylabel("throttle")

ha(2) = subplot(3,1,2);
plot(t, FForce, "r")
hold on
plot(t, F_tire_e, "b")
grid on
xlabel("time")
ylabel("Torque")


ha(3) = subplot(3,1,3);
plot(t,gear)
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
F_tire_e_cut = FForce(96000:116000);
throttle_cut = throttle(96000:116000);


dt = mean(diff(t));
data = iddata(F_tire_e_cut, throttle_cut, dt);
np = 3;
nz = 2;
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
subplot(2,1,1)
plot(t_sim, FForce,   'b', 'DisplayName', 'Measured')
hold on
plot(t_sim, F_tire_sim, 'r--', 'DisplayName', 'TF Simulated')
grid on
xlabel('Time (s)')
ylabel('Tire Force (N)')
legend

subplot(2,1,2)
plot(t_sim, F_tire_e - F_tire_sim, 'k')
grid on
xlabel('Time (s)')
ylabel('Residual (N)')
title('Prediction Error')





%% engine map look up
map_raw = readtable('engine_map_boosted_reduced.csv');

map_throttle_bp = [0.0, 0.3, 1.0];
map_rpm_bp      = map_raw{:, 1};
map_torque      = map_raw{:, 2:end};

valid_rows      = isfinite(map_rpm_bp);
map_rpm_bp      = map_rpm_bp(valid_rows);
map_torque      = map_torque(valid_rows, :);

throttle_norm  = throttle / 100;
rpm_clean      = rpm;
throttle_clean = throttle_norm;

rpm_clean(~isfinite(rpm_clean))= map_rpm_bp(1);
throttle_clean(~isfinite(throttle_clean)) = 0;

rpm_clean      = min(max(rpm_clean,map_rpm_bp(1)),map_rpm_bp(end));
throttle_clean = min(max(throttle_clean, map_throttle_bp(1)), map_throttle_bp(end));

% LT
T_map = interp2(map_throttle_bp, map_rpm_bp, map_torque,throttle_clean, rpm_clean, 'linear');
T_map(throttle_norm <= 0.06) = 0;




%% alpha calc
boost_diff = boost_aim - boost_pressure;

alpha = zeros(size(t));
alpha(boost_diff <= 5)= 1.0;
alpha(boost_diff >  5 & boost_aim > 0)= boost_pressure(boost_diff > 5 & boost_aim > 0) ./ boost_aim(boost_diff > 5 & boost_aim > 0);


active_idx = throttle_norm > 0.06 & T_map > 0;
T_map_ref  = mean(T_map(active_idx));

gain_normalised = ((alpha .* T_map)./r) ./ (0.5336*10^3);

F_tire_scaled = F_tire_sim .* gain_normalised;


%%
% num_d = [0, 0.0752, 0.0738];
% den_d = [1, -1.9419, 0.9451];

num_d = [1];
den_d = [0.353, 1];

dt = mean(diff(t));
dc_gain = sum(num_d) / sum(den_d);
num_norm = num_d / dc_gain;
sys_norm = tf(num_norm, den_d);

K = (alpha .* T_map .* total_ratio) ./ r;
K(throttle_norm <= 0.06) = 0;
K(T_map <= 0)            = 0;



F_tire_model = lsim(sys_norm, K, t_sim);
F_tire_model = max(F_tire_model, 0);

fit_model = 100*(1 - norm(F_tire_e - F_tire_model) / norm(F_tire_e - mean(F_tire_e)));


%% 
figure

ha4(1) = subplot(4,1,1);
    plot(t, throttle, 'k')
    ylabel('Throttle (%)')
    grid on

ha4(2) = subplot(4,1,2);
    plot(t, K, 'c', 'DisplayName', 'K(t) = \alpha T_{map} ratio/r')
    hold on
    plot(t, F_tire_e, 'b', 'DisplayName', 'Measured F_{tire}')
    ylabel('Force (N)')
    legend; grid on
    title('Physics-based gain K(t) vs Measured')

ha4(3) = subplot(4,1,3);
    plot(t, F_tire_e,'b',  'DisplayName', 'Measured')
    hold on
    plot(t, F_tire_model, 'r',  'DisplayName', sprintf('Model %.1f%%', fit_model))
    ylabel('Tire Force (N)')
    legend; grid on

ha4(4) = subplot(4,1,4);
    plot(t, F_tire_e - F_tire_model, 'k')
    yline(0, 'r--')
    ylabel('Residual (N)')
    xlabel('Time (s)')
    grid on

linkaxes(ha4, 'x')
sgtitle('F_{tire} = TF_{norm}(z) × [\alpha(t) × T_{map} × ratio / r]')