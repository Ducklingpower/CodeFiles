clc
close all
clear

%% Time-span and sampling rate
sr= 0.001;
tmax=10;
t_span = 0:sr:tmax;

%% Part 1

% inputs
v     = ones(1,length(t_span));
v     = timeseries(v',t_span);
omega = ones(1,length(t_span));
omega = timeseries(omega',t_span);

%IC
x_o     = ones(1,length(t_span))*0;
x_o     = timeseries(x_o',t_span);
y_o     = ones(1,length(t_span))*0;
y_o     = timeseries(y_o',t_span);
theta_o = ones(1,length(t_span))*0;
theta_o = timeseries(theta_o',t_span);

%%Run sim
output = sim('UnicycleRobot.slx',[0 tmax]);

% Obtain outputs
states = output.states.data;

x     = states(:,1);
y     = states(:,2);
theta = states(:,3);

%output plots
plot(t_span,x,LineWidth=2)
hold on
plot(t_span,y,LineWidth=2)
hold on
plot(t_span,theta,LineWidth=2)
title("Unicycle outputs")
xlabel("time")
ylabel("states")
legend("x","y",'\theta')
grid on

%% Part 2
clc
clear 


%%Time-span and sampling rate
sr= 0.001;
tmax=10;
t_span = 0:sr:tmax;


%%Inputs
R  = 0.1;
L  = 0.5;
vr = ones(1,length(t_span));
vr = timeseries(vr',t_span)*10;
vl = ones(1,length(t_span))*5;
vl = timeseries(vl',t_span);

%%IC
x_o     = ones(1,length(t_span))*0;
x_o     = timeseries(x_o',t_span);
y_o     = ones(1,length(t_span))*0;
y_o     = timeseries(y_o',t_span);
theta_o = ones(1,length(t_span))*0;
theta_o = timeseries(theta_o',t_span);

%%Run sim
output = sim('differentialDriveRobot.slx',[0 tmax]);

% Obtain outputs
states = output.states.data;

x     = states(:,1);
y     = states(:,2);
theta = states(:,3);

%output plots
plot(t_span,x,LineWidth=2)
hold on
plot(t_span,y,LineWidth=2)
hold on
plot(t_span,theta,LineWidth=2)
title("Unicycle outputs")
xlabel("time")
ylabel("states")
legend("x","y",'\theta')
grid on











