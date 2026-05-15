clc
close all
clear
%% opening csv

data = readtable('output.csv');

%% raw data
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


%% filtered data
Ft = movmean(data.time_s,100);

Fax = movmean(data.a_x,100);
Fay = movmean(data.a_y,100);
Faz = movmean(data.a_z,100);

Fvx = movmean(data.odom_vx_mps,100);
Fvy = movmean(data.odom_vy_mps,100);

Frpm = movmean(data.engine_rpm,100);
Fthrottle = movmean(data.throttle_pct,100);
Fgear = movmean(data.current_gear,100);
FT_e = movmean(data.est_drive_torque_nm,100);
Fbrake = movmean(data.front_brake_pressure_kpa,100);


Fqx = movmean(data.odom_qx,100);
Fqy = movmean(data.odom_qy,100);
Fqz = movmean(data.odom_qz,100);
Fqw = movmean(data.odom_qw,100);

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

%% cleaning just for coast downs


close all


for i = 1:2

    if i==1
        % coast down at gear 2
        a = length(rpm)*0.423;
        b = length(rpm)*0.434;
        % a = length(rpm)*0.42;
        % b = length(rpm)*0.435;
    else
    
        % coast down at gear3
        a = length(rpm)*0.52;
        b = length(rpm)*0.535;
    end
    
    
    % 
    % phys no filtered
    air = 0.5 * roh* 1* Cd.*vx.^2;
    F_pitch = m*g.*sin(pitch);
    body = m.*ax;
    Force =  body+ air- F_pitch;

    % phys no filtered
    Fair = 0.5 * roh* 1* Cd.*Fvx.^2;
    FF_pitch = m*g.*sin(Fpitch);
    Fbody = m.*Fax;
    FForce =  Fbody+ Fair- F_pitch;
    

    torqueAtTire = (Force .* r);    % torque at tire non filterd

    FtorqueAtTire = (FForce .* r);    % filtered
    
    
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
        FtorqueAtengine = FtorqueAtTire / (eff_diff * diff_ratio * gear_ratio * gear_eff);
        torqueAtengine_e = T_e / (eff_diff * diff_ratio * gear_ratio * gear_eff);

    end
    
    
    %
    
    figure(1)
    subplot(3,2,1)
    hold on
    plot(a:b,rpm(a:b))
    hold on
    plot(a:b,Frpm(a:b))
    xlabel('Sample Index')
    ylabel('rpm')
    grid on

    
    subplot(3,2,2)
    hold on
    plot(a:b,vx(a:b))
    hold on
    plot(a:b,Fvx(a:b))
    xlabel('Sample Index')
    ylabel('velocity')
    grid on
    
    subplot(3,2,3)
    hold on
    plot(a:b,torqueAtengine(a:b))
    hold on 
    plot(a:b,FtorqueAtengine(a:b),'r')
    xlabel('Sample Index')
    ylabel('estimated vs filtered')
    grid on
 
    
    subplot(3,2,4)
    hold on
    plot(rpm(a:b),torqueAtengine(a:b))
    hold on 
    grid on
    xlabel('rpm')
    ylabel('T_engine')


    subplot(3,2,4)
    hold on
    plot(rpm(a:b),torqueAtengine(a:b))
    hold on 
    plot(rpm(a:b),FtorqueAtengine(a:b),"r")
    grid on
    xlabel('rpm')
    ylabel('T_engine')


    subplot(3,2,5)
    hold on
    plot(rpm(a:b),ax(a:b))
    hold on 
    plot(rpm(a:b),Fax(a:b),"r")
    grid on
    xlabel('rpm')
    ylabel('T_engine')
    
    
    subplot(3,2,6)
    hold on
    plot(rpm(a:b),pitch_deg(a:b))
    hold on
    plot(rpm(a:b),Fpitch_deg(a:b),LineWidth=2)
    xlabel('rpm')
    ylabel('grade (deg)')
    grid on



    if i == 1
        g2 = FtorqueAtengine(a:b);
    else
        g3 = FtorqueAtengine(a:b);
    end
end



%% fitting 
a2 = length(rpm)*0.423;
b2 = length(rpm)*0.434;

a3 = length(rpm)*0.52;
b3 = length(rpm)*0.535;




Poly = polyfit(rpm(a3:b3),g3,2);
g3_fitted = polyval(Poly,rpm(a3:b3));

Poly = polyfit(rpm(a2:b2),g2,2);
g2_fitted = polyval(Poly,rpm(a2:b2));


data = readtable("engine_map_boosted_reduced.csv");
table_torque = data.Var2;
table_rpm = data.Var1;


figure
subplot(3,1,1)
plot(rpm(a2:b2),g2,LineWidth=2);
hold on
plot(rpm(a2:b2),g2_fitted,LineWidth=2)
hold on
plot(table_rpm(3:73),table_torque(3:73),LineWidth=2)
grid on 
xlabel("rpm gear 2")
ylabel("engine torque")
legend("E torque: moving avg","E torque: poly fit","E torque: engine map")


subplot(3,1,2)
plot(rpm(a3:b3),g3,LineWidth=2);
hold on
plot(rpm(a3:b3),g3_fitted,LineWidth=2)
hold on 
plot(table_rpm(3:73),table_torque(3:73),LineWidth=2)
grid on
xlabel("rpm gear 3")
ylabel("engine torque")
legend("E torque: moving avg","E torque: poly fit","E torque: engine map")


subplot(3,1,3)
hold on
plot(rpm(a2:b2),g2_fitted,LineWidth=2)
hold on
plot(rpm(a3:b3),g3_fitted,LineWidth=2)
hold on 
plot(table_rpm(3:73),table_torque(3:73),LineWidth=2)
grid on
legend("E torque: poly fit gear 2","E torque: poly fit gear 3","E torque: engine map")


a9 = length(rpm)*0.423;
b9 = length(rpm)*0.434;
Poly9 = polyfit(rpm(a9:b9),g2,1);
g9_fitted = polyval(Poly,rpm(a9:b9));



figure 
plot(-10000:1:10000,polyval(Poly,-10000:1:10000),LineWidth=2)
hold on
plot(rpm(a2:b2),g2,LineWidth=2);
hold on
% plot(-10000:1:10000,polyval(Poly9,-10000:1:10000))
grid on
x = 0:1:10000;
y = -0.0097067.*x;
plot(x,y,LineWidth=2)
legend("fitted poly","data","old eye ball test")


%% final enginen brake values
x = 500:100:7500;
engine_brake = -0.0097067.*x;
var1 = [0 engine_brake]';

var2 = [0 x]';
var3 = data.Var3;
var3 = var3(2:end);
var4 = data.Var4;
var4 = var4(2:end);

engine = [var2' ;var1'; var3'; var4']';
csvwrite('engine_map.csv', engine)

