clc
close all
clear 

%% openign data


% Load the dataset from a specified file
data = readtable('output.csv');

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
legend("Calculated forve","Modetc Torque estimate to force")


ha(3) = subplot(3,1,3);
plot(t,gear)
grid on
xlabel("time")
ylabel("gear")
% Link only x-axes
linkaxes(ha, "x")

zoom on


%% TF test

% best fit tf from the fastes lap csv, itted to calculated force

throttle_cut = throttle(96000:116000);


dt = mean(diff(t));
sys_ct = tf([0 473.7457 676.4046 26.6514], [1 7.3075 7.0367 0.9746]); % tf for the fastes lap fitted data
disp(sys_ct)


sys_dt = c2d(sys_ct, dt, 'zoh');
disp(sys_dt)
t_sim = t - t(1);                        

% lsim 
F_tire_sim = lsim(sys_ct, throttle, t_sim);


fit_pct = 100 * (1 - norm(F_tire_e - F_tire_sim) / norm(F_tire_e - mean(F_tire_e)));
fprintf('\nFit: %.1f%%\n', fit_pct)

figure
ha(1) = subplot(2,1,1);
plot(t_sim, F_tire_e,   'b', 'DisplayName', 'Measured')
hold on
plot(t_sim, F_tire_sim, 'r--', 'DisplayName', 'TF Simulated')
grid on
xlabel('Time (s)')
ylabel('Tire Force (N)')
legend

ha(2) = subplot(2,1,2);
plot(t_sim,throttle, 'k')
grid on
xlabel('Time (s)')
ylabel('Throttle Position')
title("Throtle vs time")
linkaxes(ha, "x")


