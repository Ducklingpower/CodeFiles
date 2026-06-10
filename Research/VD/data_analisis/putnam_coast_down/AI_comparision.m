clc
close all
clear 

%% opening csv

% data = readtable('FastLaps.csv');
data = readtable('/home/elijah/PurdueRacing/bags/putnam/new_ai_test/csv_output/2026-05-26_124450_merged.csv');

%% filtered data

mm =50;
Ft = movmean(data.time_s,mm);

x_pos = data.odom_px_m;
y_pos = data.odom_py_m;

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

ax_desired = data.acceleration_target;

% tire temp

fr_T_0 = data.fr_temp_1;
fr_T_1 = data.fr_temp_2;
fr_T_2 = data.fr_temp_3;
fr_T_3 = data.fr_temp_4;


% commands
throttle_old = data.joy_accelerator_cmd;
gear_old = data.joy_gear_cmd;
brake_f_old = data.joy_frt_brake_cmd;

throttle_new = data.new_ai_accelerator_cmd;
gear_new = data.new_ai_gear_cmd;
brake_f_new = data.new_ai_frt_brake_cmd;


t_s = data.time_s;
t = -t_s(1)+t_s;



lap_old = 147800:161950; % lap wiht old ai
delta = 161777 + length(lap_old) - 1;
lap_new = 161777:delta;
L = length(lap_old);
x  = 1:L;
%%


throttle_old_AI = throttle_old(147800:161950);
throttle_new_AI = throttle_new(161777:delta);

gear_old_AI = gear_old(147800:161950);
brake_f_old_AI = brake_f_old(147800:161950);

gear_new_AI = gear_new(161777:delta);
brake_f_new_Ai = brake_f_new(161777:delta);

figure
tiledlayout(3,1)

ax1(1) = nexttile;
plot(x, throttle_old_AI, 'LineWidth', 2)
hold on
plot(x, throttle_new_AI, 'LineWidth', 2)
grid on
ylabel('Throttle')
title('Throttle Comparison')
legend('Old AI', 'New AI')

ax1(2) = nexttile;
plot(x, gear_old_AI, 'LineWidth', 2)
hold on
plot(x, gear_new_AI, 'LineWidth', 2)
grid on
ylabel('Gear')
title('Gear Comparison')
legend('Old AI', 'New AI')

ax1(3) = nexttile;
plot(x, brake_f_old_AI, 'LineWidth',2)
hold on
plot(x, brake_f_new_Ai, 'LineWidth', 2)
grid on
xlabel('Sample')
ylabel('Front Brake')
title('Front Brake Comparison')
legend('Old AI', 'New AI')

linkaxes(ax1,'x')


figure
tiledlayout(3,1)

ax2(1) = nexttile;
plot(t, throttle_old, 'LineWidth', 2)
hold on
plot(t, throttle_new, 'LineWidth', 2)
grid on
ylabel('Throttle')
title('Throttle Comparison')
legend('Old AI', 'New AI')

ax2(2) = nexttile;
plot(t, gear_old, 'LineWidth', 2)
hold on
plot(t, gear_new, 'LineWidth', 2)
grid on
ylabel('Gear')
title('Gear Comparison')
legend('Old AI', 'New AI')

ax2(3) = nexttile;
plot(t, brake_f_old, 'LineWidth',2)
hold on
plot(t, brake_f_new, 'LineWidth', 2)
grid on
xlabel('Sample')
ylabel('Front Brake')
title('Front Brake Comparison')
legend('Old AI', 'New AI')

linkaxes(ax2,'x')


figure
plot(t,Fax)
hold on
plot(t,ax_desired)
grid on