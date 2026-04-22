clc
close all
clear
%% opening csv

data = readtable('output.csv');

%%
t = data.time_s;

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

m = 787;
r = 0.31;
roh = 1.22;
Cd = 0.3;
g = 9.81;

%% cleaning just for coast downs





for i = 1:2

    if i==1
        % coast down at gear 2
        a = length(rpm)*0.4225;
        b = length(rpm)*0.434;
        % a = length(rpm)*0.42;
        % b = length(rpm)*0.435;
    else
    
        % coast down at gear3
        a = length(rpm)*0.519;
        b = length(rpm)*0.535;
    end
    
    
    % 
    % phys
    air = 0.5 * roh* 1* Cd.*vx.^2;
    F_pitch = m*g.*sin(pitch);
    body = m.*ax;
    F =  body+ air- F_pitch;
    
    % torque at tire
    torqueAtTire = (F .* r);
    
    
    diff_ratio = 3;
    eff_diff = 0.99;
    gear_eff = 0.91;
    
    for gear = 2:3
        if gear == 2
           
            gear_ratio = 1.8667;
        else
           
            gear_ratio = 2.9167;
        end
        
        torqueAtengine = torqueAtTire / (eff_diff * diff_ratio * gear_ratio * gear_eff);
        torqueAtengine_e = T_e / (eff_diff * diff_ratio * gear_ratio * gear_eff);

        d1 = designfilt("lowpassiir",FilterOrder=12,HalfPowerFrequency=0.02,DesignMethod="butter");
        % Apply the low-pass filter to the torque signals
        filteredTorqueAtengine = filter(d1,torqueAtengine);
        filteredTorqueAtengine_e = filter(d1,torqueAtengine_e);
    end
    
    
    %
    
    figure(1)
    subplot(3,2,1)
    hold on
    plot(a:b,rpm(a:b))
    xlabel('Sample Index')
    ylabel('rpm')
    grid on

    
    subplot(3,2,2)
    hold on
    plot(a:b,vx(a:b))
    xlabel('Sample Index')
    ylabel('velocity')
    grid on
    
    subplot(3,2,3)
    hold on
    plot(a:b,torqueAtengine(a:b))
    hold on 
    plot(a:b,filteredTorqueAtengine(a:b),'r')
    xlabel('Sample Index')
    ylabel('estimated vs filtered')
    grid on
    
    subplot(3,2,4)
    hold on
    plot(a:b,torqueAtengine(a:b))
    xlabel('Sample Index')
    ylabel('engine_torque')
    grid on
    hold on
    plot(a:b,torqueAtengine_e(a:b))
    
    subplot(3,2,5)
    hold on
    plot(rpm(a:b),torqueAtengine(a:b))
    hold on 
    grid on
    xlabel('rpm')
    ylabel('T_engine')
    
    
    subplot(3,2,6)
    hold on
    plot(a:b,F_pitch(a:b))
    xlabel('Sample Index')
    ylabel('grade force')
    grid on
end