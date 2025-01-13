clc
clear
close all
m1 = 3000;
ms = 3000;
mf = 100;
mr = 500;
kft = 26000;
krt = 26000;

kf = 26000;
kr = 26000;
cf = 1400;
cr = 1400;
Lb = 0.734;
La = 0.828;
I = 1200;
rideHeight = 0.038;

A = [0 1;-(kf+kr)/(m1) -(cf+cr)/(m1)];

dthetadt = @(t,theta) [theta(2) ; (-kr.*tan(theta(1)).*Lb.^2)/(I)-(cr.*sec(theta(1)).^2.*Lb^2.*theta(2))/(I)-(kf.*tan(theta(1)).*La.^2)/(I)-(cf.*sec(theta(1)).^2.*La.^2.*theta(2))/(I)];
ode = @(t, x) A*x;

theta_init =  [.2,0];
x_init = [-.5; 0];

[time,theta] = ode45(dthetadt,0:.01: 10,theta_init);
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
theta = theta';
x = x';

xr = tan(theta(1,:)).*Lb;
xf = xr.*(Lb/La);

xr = x(1,:)+xr+rideHeight;
xf = x(1,:)-xf+rideHeight;

figure(1)
plot(tspan, x(1, :), 'LineWidth', 5)
hold on
plot(tspan, x(2, :), 'LineWidth', 5)
xlabel('Time')
ylabel('States')
legend('Cg position', 'Cg Velocity')

figure(2)
plot(time, theta(1, :), 'LineWidth', 5)
hold on
plot(time, theta(2, :), 'LineWidth', 5)
xlabel('Time')
ylabel('States')
legend('theta', 'omega')

figure(3)
plot(time, xr, 'LineWidth', 5)
hold on
plot(time, xf, 'LineWidth', 5)
xlabel('Time')
ylabel('States')
legend('x_r', 'x_f')


%%%with tires

% % Matrix =[
% %     0 1 0 0 0 0;
% %     (kf+kr)/(ms) (cr+cf)/(ms) (-kf)/(ms) (-cf)/ms (-kr)/ms (-cr)/ms;
% %     0 0 0 1 0 0;
% %     (-kf)/mf (-cf)/mf (kf-kft)/mf (cf)/mf 0 0;
% %     0 0 0 0 0 1;
% %     (-kr)/mr (-cr)/mr 0 0 (kr-krt)/mr (cr)/mr
% %     ];
Matrix =[
    0 1 0 0 0 0;
    -(kf+kr)/(ms) -(cr+cf)/(ms) (-kf)/(ms) (-cf)/ms (-kr)/ms (-cr)/ms;
    0 0 0 1 0 0;
    (-kf)/mf (-cf)/mf (-kf-kft)/mf (-cf)/mf 0 0;
    0 0 0 0 0 1;
    (-kr)/mr (-cr)/mr 0 0 (-kr-krt)/mr (-cr)/mr
    ];


ode_system = @(t, d) Matrix*d;

d_init = [.5 0 0 0 0 0];
[tspan, d] = ode45(ode_system, 0:.01: 5, d_init);
d = d';
figure(4)
plot(tspan, d(1, :), 'LineWidth', 5)
hold on
plot(tspan, d(2, :), 'LineWidth', 5)
hold on
plot(tspan, d(3, :), 'LineWidth', 5)

hold on
plot(tspan, d(4, :), 'LineWidth', 5)

hold on
plot(tspan, d(5, :), 'LineWidth', 5)

hold on
plot(tspan, d(6, :), 'LineWidth', 5)
xlabel('Time')
ylabel('States')
legend('xs position', 'xs Velocity','xf position', 'xf Velocity','xr position', 'xr Velocity')




figure(5)
plot(tspan, d(1, :), 'LineWidth', 5)
hold on

plot(tspan, d(3, :), 'LineWidth', 5)

hold on
plot(tspan, d(5, :), 'LineWidth', 5)

xlabel('Time')
ylabel('States')
legend('xs position','xf position' ,'xr position' )
