clc
close all
clear
%% running area functions
dt = 0.001;
t = 0:dt:pi;

freq = 3;
y_sin = 2*sin(freq*(2*pi)*t + pi/2);


w = 2 * pi * freq; %omega

IC = -2/(6*pi);
IC = 0

y_true = -2/w * cos(w*t) + (IC + 2/w);

% single integration func
y_sin_integral = Integrate(y_sin,dt,IC);


figure
plot(t,y_sin,"*")
hold on
plot(t,y_true,"*")
hold on
plot(t,y_sin_integral,".")

grid on
legend("2*sin(t(2*pi)*3)","True Numeric integral","integrated 2*sin(t(2*pi)*3")


%% double integrator func
clc
clear

dt = 0.0001;
t = 0:dt:2*pi;

freq = 3;
y_sin = 2*sin(freq*(2*pi)*t);

x_IC = 0;
v_IC = -2/(6*pi);


y2_true = -(2/(freq*(2*pi))^2) * sin((freq*(2*pi))*t);

y_sin_2Integral = Double_Integrate(y_sin,dt,x_IC,v_IC);


figure 
plot(t,y_sin,"*");
hold on
plot(t,y2_true,"*")%% doule intral of sin;
hold on
plot(t,y_sin_2Integral,".")

grid on
legend("sin(t)","-sin(t)","double integral sin(t)")

%% step fun integrate

dt = 0.01;

step_time = 1;
end_time = 5;
t = dt:dt:end_time;

step = [zeros(step_time/dt,1);ones((end_time-step_time)/dt,1)];


step_integral = Integrate(step, dt, 0);
step_2integral = Double_Integrate(step,dt,0,0);
figure

hold on
plot(t, step_integral,'*')
hold on
plot(t,step_2integral,'*')
grid on
hold on
plot(t,step,"*")
legend("integrated step","double integration step","raw step signal")





