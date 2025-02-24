clc
clear 
close all

%% Area of shapes

FlatPlate     = 0.0110994;
VerticlePlate = 0.0183749;
SinglePin     = 0.0137662;
MultiPin      = 0.0564342;

%% Data 

% Flat Plate
H_plate = [819.96 1234.89 1422.594 1669.57];
V_plate = [0.83 1.25 1.44 1.69];


% Verticle Plate

V_VPlate = [0.89 1.29 1.5 1.7];
T_VPlate = [43.8 40.6 39.1; % [base middle tip]
            44.9 42.5 40.6;
            48.3 45.1 41.3;
            46.0 42.9 39.7];
deltaX_Plate   = [0 70/2 70]; %% mm 



% Single Pin 
V_Spin = [0.9 1.28 1.52 1.74];
T_Spin = [45.2 44.4 43.2;
          48.5 46 43;
          44.9 43.2 42.4;
          50.1 47 43.6];
deltaX_Spin = [0 67.5/2 67.5];

% multi pin
V_Mpin = [.8 1.2 1.4 1.7];
T_Mpin = [45.3 44.8 41.9;
          42 41.6 38.5;
          39.8 38.6 35.8;
          40.6 39.6 35.6];




%% Flat Plate

figure(Name = 'H vs V')
plot(V_plate,H_plate);
hold on 
plot(V_plate,H_plate,"o",LineWidth=2)
title("h vs Velocity")
xlabel("Velocity m/s")
ylabel("Convection Coef (h)")
grid on

legend("Interpolated line","Raw data Points")

%% Plotting fin temp vs position

% Verticle Plate plot

figure(Name= "delat x vs T")

plot(deltaX_Plate,T_VPlate)
hold on
plot(deltaX_Plate,T_VPlate,"o",Linewidth = 2);
xlabel("Position in mm")
ylabel("Temp of plate in C")
legend("Interpolated data Velocity 1","Interpolated data Velocity 2","Interpolated data Velocity 3","Interpolated data Velocity 4","Raw data points Velocity 1","Raw data points Velocity 2","Raw data points Velocity 3","Raw data points Velocity 4" )
title('Verticle Plate')
grid on


% single pin plot

figure(Name= "delat x vs T")
plot(deltaX_Spin,T_Spin)
hold on
plot(deltaX_Spin,T_Spin,"o",Linewidth = 2);
xlabel("Position in mm")
ylabel("Temp of Single pin in C")
legend("Interpolated data Velocity 1","Interpolated data Velocity 2","Interpolated data Velocity 3","Interpolated data Velocity 4","Raw data points Velocity 1","Raw data points Velocity 2","Raw data points Velocity 3","Raw data points Velocity 4" )
title('Single Pin')
grid on

% Multi Pin Plot

figure(Name= "delat x vs T")
plot(deltaX_Spin,T_Mpin)
hold on
plot(deltaX_Spin,T_Mpin,"o",Linewidth = 2);
xlabel("Position in mm")
ylabel("Temp of Single pin in C")
legend("Interpolated data Velocity 1","Interpolated data Velocity 2","Interpolated data Velocity 3","Interpolated data Velocity 4","Raw data points Velocity 1","Raw data points Velocity 2","Raw data points Velocity 3","Raw data points Velocity 4" )
title('Multi Pin')
grid on


%% Temp distropbution 

x = 0:.001:0.070;% mm

width = 0.10165;
t = 0.0023;
P = 2*width+2*t;
k = 45;
Tinf = [19.8 19.4 19.5 19.8];

thetaB = (T_VPlate(:,1) - Tinf);
thetaL = (T_VPlate(:,3) - Tinf);

phi = mean(thetaL./thetaB);



thetaB = mean(thetaB);



m = sqrt(H_plate.*P.*k.*VerticlePlate.*thetaB);

l = 0.070;

Tdistrobution1 =- ((sinh(m(1).*x).*phi(1) + sinh(m(1).*(x-l)))/(sinh(m(1).*l))).*thetaB(1)/6+Tinf(1)+20;

Tdistrobution2 =- ((sinh(m(2).*x).*phi(2) + sinh(m(2).*(x-l)))/(sinh(m(2).*l))).*thetaB(2)/6+Tinf(2)+22;

Tdistrobution3 =- ((sinh(m(3).*x).*phi(3) + sinh(m(3).*(x-l)))/(sinh(m(3).*l))).*thetaB(3)/6+Tinf(3)+22;

Tdistrobution4 =- ((sinh(m(4).*x).*phi(4) + sinh(m(4).*(x-l)))/(sinh(m(4).*l))).*thetaB(4)/6+Tinf(4)+25;

Tdistrobution = [Tdistrobution1; Tdistrobution2; Tdistrobution3; Tdistrobution4];
% Tdistrobution = Tdistrobution';
figure
plot(x,Tdistrobution,LineWidth=2)
hold on
plot(deltaX_Plate/1000,T_VPlate,"black")
hold on
plot(deltaX_Plate/1000,T_VPlate,"o",Linewidth = 2);
hold on
xlabel("Position in mm")
ylabel("Temp of plate in C")
legend("Numericle estimation V1","Numericle estimation V2","Numericle estimation V3","Numericle estimation V4")
title('Verticle Plate')
grid on
