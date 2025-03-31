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


%% Crank Shaft
clc;
close all;
clear;

L1 = 2; 
L2 = L1*2; 
w =2;  % Angular velocity


tiledlayout(2, 1);


ax1 = nexttile;
axis equal;
axis([-15 15 -15 15]); 
hold on;
P3 = [0, 0]; % Origin


ax2 = nexttile;
hold on;
title('Y-Coordinates of P2 and P1 Over Time');
xlabel('Iteration');
ylabel('Y-Coordinate');
grid on;


P2_y_vals = [];
P1_y_vals = [];

for i = 1:500
    th1 = w * (i / 10); 
    P2 = [L1 * cos(th1), L1 * sin(th1)];
    
    horizontal_dist = P2(1);     
    if abs(horizontal_dist) > L2
        continue; 
    end  
    
    aph = acos(horizontal_dist / L2); 
    P1 = [0, P2(2) + L2 * sin(aph)];  
    
    P2_y_vals = [P2_y_vals, P2(2)];
    P1_y_vals = [P1_y_vals, P1(2)];

    cla(ax1);  

    
    plot(ax1, [P3(1), P2(1)], [P3(2), P2(2)], 'o-', 'LineWidth', 2, 'Color', 'b');
    hold(ax1, 'on');   
    plot(ax1, [P2(1), P1(1)], [P2(2), P1(2)], 'o-', 'LineWidth', 2, 'Color', 'r'); 
    plot(ax1, P1(1), P1(2), 'ro', 'MarkerFaceColor', 'r');
    title(ax1, 'Slider Crank Mechanism');
    axis(ax1, [-15 15 -15 15]); 
    grid(ax1, 'on');
    
  
    cla(ax2);
    plot(ax2, 1:length(P2_y_vals), P2_y_vals, 'b', 'LineWidth', 1.5);
    hold(ax2, 'on');
    plot(ax2, 1:length(P1_y_vals), P1_y_vals, 'r', 'LineWidth', 1.5);
    legend(ax2, 'P2 Y-Coord', 'P1 Y-Coord');
    pause(0.01);
end


%% Spring constant 

inches_up1 = [0 1.5 2 2.4 2.6 3 3.5 3.75]./39.37;
newtons_up1= [0 2 2.4 3.9 4.9 6.4 7.3 9.8];  

inches_down1 = [3.5 3 2.7 2.5 2.25 2 1.75 1.5 1.25 1 0]./39.37;
newtons_down1= [9.3 7.3 6.4 5.9 5.4 4.9 4.4 3.1 2.4 2 0];

inches_up2 = [0 1.25 1.5 1.75 2 2.25 2.5 2.75 3 3.3 3.55 4 4.3]./39.37;
newtons_up2= [0 2 2.9 3.4 3.9 4.4 4.9 5.9 6.4 7.3 8.3 9.3 10.3];  

figure
inches = [inches_up1 inches_down1 inches_up2];
newtons = [newtons_up1 newtons_down1 newtons_up2];
plot(inches,newtons,".-","Color","black")
hold on
plot(inches_up1,newtons_up1,"o--",LineWidth=2)
hold on
plot(inches_down1,newtons_down1,"o--",LineWidth=2)
hold on
plot(inches_up2,newtons_up2,"o--",LineWidth=2)
hold on
grid on

p = polyfit(inches, newtons, 1);     
slope = p(1)
inches_fit = linspace(min(inches), max(inches), 100);
newtons_fit = polyval(p, inches_fit);
plot(inches_fit, newtons_fit, 'LineWidth', 2)

grid on
legend("Total test", "up 1", "down", "up 2", "Best fit line")
xlabel('meters')
ylabel('Newtons')
title('Force vs. dist')
