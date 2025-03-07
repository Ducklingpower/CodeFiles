clc
close all
clear 
%% Half circe dor damping area 
theta = 0:0.01:pi;
R = 1;
r = 0.2;
Area_Turn = (theta/(2*pi))*pi*(R^2-r^2);
Area_Open = (pi/2)*(R^2-r^2);
Area_damper = Area_Open-Area_Turn;

figure
plot(theta,Area_damper,LineWidth=2)
grid on 
xlabel("Theat (Rads)")
ylabel("Open Area")

