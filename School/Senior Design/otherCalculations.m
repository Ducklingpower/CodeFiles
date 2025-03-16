clc
close all
clear 
%% Half circe dor damping area 
theta = pi/2:0.01:pi;
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


%%

rmin = 100;
rmax = 50;
kR = linspace(rmin,rmax,100);
kr = linspace(rmin,0.1,100);

theta = linspace(0,2.8,100);

R = theta.*kR.^(-1/4);
r = theta.*kr.^(-1/4);

xR = R.*cos(theta);
yR = R.*sin(theta);

xr = r.*cos(theta);
yr = r.*sin(theta);
%%
figure
for i = 1:100
plot(xR(i),yR(i),"*");
hold on
plot(xr(i),yr(i),"*");
grid on
pause(0.1)
end

%% Solving for area 

delta = 0.01;
for i = 1:100

A(i) = pi*(R(i)^2-r(i)^2)*delta;

end

figure
plot(1:100,A);

hold on
plot(1:100,1./(A.^2))



