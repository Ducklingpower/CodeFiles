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
vr = ones(1,length(t_span))*10;
vr = timeseries(vr',t_span);
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

%% Part 3 comparing results
clc
clear

%%Time-span and sampling rate
sr= 0.001;
tmax=10;
t_span = 0:sr:tmax;

%%inputs
%(Unicycle)
v     = ones(1,length(t_span));
v     = timeseries(v',t_span);
omega = sin(100*t_span);
omega = timeseries(omega',t_span);

%IC
x_o     = ones(1,length(t_span))*0;
x_o     = timeseries(x_o',t_span);
y_o     = ones(1,length(t_span))*0;
y_o     = timeseries(y_o',t_span);
theta_o = ones(1,length(t_span))*0;
theta_o = timeseries(theta_o',t_span);


%%Run sim Unicycle
output = sim('UnicycleRobot.slx',[0 tmax]);

% Obtain outputs
states = output.states.data;

x     = states(:,1);
y     = states(:,2);
theta = states(:,3);

%output plots
plot(t_span,x,"o",LineWidth=1)
hold on
plot(t_span,y,"o",LineWidth=1)
hold on
plot(t_span,theta,"o",LineWidth=1)
title("Unicycle outputs")
xlabel("time")
ylabel("states")
grid on

clearvars x y theta v omega

%(diff drive)
R  = 0.1;
L  = 0.5;
v     = ones(1,length(t_span));
omega = sin(100*t_span);
vr = (2.*v+omega.*L)./(2.*R);
vr = timeseries(vr',t_span);
vl = (2.*v-omega.*L)./(2.*R);
vl = timeseries(vl',t_span);

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
legend("x_{unicycle}","y_{unicycle}",'\theta_{unicycle}',"x_{DiffDrive}","y_{DiffDrive}",'\theta_{DiffDrive}')

%% part 4 Linearized unix
clc
clear

%%Time-span and sampling rate
sr= 0.001;
tmax=10;
t_span = 0:sr:tmax;

% Stright line solution
theta_sol = 0;
v         = 1;


% state space

A = [ 0 0 -v*sin(theta_sol);
      0 0  v*cos(theta_sol);
      0 0          0      ];

B = [v*cos(theta_sol) 0 ;
     v*sin(theta_sol) 0 ;
            0         1];

C = [1 0 0 ;
     0 1 0 ;
     0 0 1];

D = [0 0 ;
     0 0 ; 
     0 0];

IC = [0 0 0];
% Inputs

delta_v     = ones(1,length(t_span));
delta_v     = timeseries(delta_v',t_span);
delta_omega = sin(0.1*t_span);
delta_omega = timeseries(delta_omega',t_span);


% Sol inputs

x_sol     = v.*t_span;
x_sol     = timeseries(x_sol',t_span);
y_sol     = zeros(1,length(t_span));
y_sol     = timeseries(y_sol',t_span);
theta_sol = zeros(1,length(t_span));
theta_sol = timeseries(theta_sol',t_span);



%%Run sim
output = sim('linearizedUnicycleRobot.slx',[0 tmax]);

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

%% part 5 linearized model vs normal

clc
clear

%%Time-span and sampling rate
sr= 0.001;
tmax=10;
t_span = 0:sr:tmax;

% inputs unicycle
velocity = ones(1,length(t_span));
velocity = timeseries(velocity',t_span);
omega    = sin(0.1.*t_span);
omega    = timeseries(omega',t_span);

%IC
x_o     = ones(1,length(t_span))*0;
x_o     = timeseries(x_o',t_span);
y_o     = ones(1,length(t_span))*0;
y_o     = timeseries(y_o',t_span);
theta_o = ones(1,length(t_span))*0;
theta_o = timeseries(theta_o',t_span);

% inputs linearized
delta_v     = ones(1,length(t_span));
delta_v     = timeseries(delta_v',t_span);
delta_omega = sin(0.1*t_span);
delta_omega = timeseries(delta_omega',t_span);

% Stright line solution
theta_sol = 0;
v         = 1;


% state space

A = [ 0 0 -v*sin(theta_sol);
      0 0  v*cos(theta_sol);
      0 0          0      ];

B = [v*cos(theta_sol) 0 ;
     v*sin(theta_sol) 0 ;
            0         1];

C = [1 0 0 ;
     0 1 0 ;
     0 0 1];

D = [0 0 ;
     0 0 ; 
     0 0];



%%Run sim
output = sim('linearizedUnicycleRobotVSUnicycleRobot.slx',[0 tmax]);

% Obtain outputs Uncicyle
states = output.statesUnicycle.data;

x_unicycle      = states(:,1);
y_unicycle      = states(:,2);
theta_unicycle  = states(:,3);

% Obtain outputs LinearIzed
states = output.statesLinearized.data;

x_Linear     = states(:,1);
y_Linear     = states(:,2);
theta_Linear = states(:,3);

%output plots
plot(t_span,theta_unicycle ,'o',LineWidth=2)
hold on
plot(t_span,x_unicycle ,'o',LineWidth=2)
hold on
plot(t_span,y_unicycle ,'o',LineWidth=2)
hold on
plot(t_span,theta_Linear,LineWidth=2)
hold on
plot(t_span,x_Linear,LineWidth=2)
hold on
plot(t_span,y_Linear,LineWidth=2)
title("Unicycle Vs Linearized")
xlabel("time")
ylabel("states")
legend('\theta_{unicycle}',"x_{unicycle}","y_{unicycle}",'\theta_{linearized}',"x_{linearized}","y_{linearized}")
grid on




%% Part 6
clc

% Stright line solution
theta = 0;
v     = 2;

k1 = -2;
k2 = -4;
k3 = -6;

% inputs unicycle (zero)
velocity = ones(1,length(t_span)).*0;
velocity = timeseries(velocity',t_span);
omega    = sin(0.1.*t_span).*0;
omega    = timeseries(omega',t_span);

% Sol inputs

x_sol     = v.*t_span;
x_sol     = timeseries(x_sol',t_span);
y_sol     = zeros(1,length(t_span));
y_sol     = timeseries(y_sol',t_span);
theta_sol = zeros(1,length(t_span));
theta_sol = timeseries(theta_sol',t_span);

% inputs Diff drive

%%Inputs
R  = 0.1;
L  = 0.5;
% vr = ones(1,length(t_span))*10;
% vr = timeseries(vr',t_span);
% vl = ones(1,length(t_span))*5;
% vl = timeseries(vl',t_span);

%%IC
x_o     = ones(1,length(t_span)).*-1;
x_o     = timeseries(x_o',t_span);
y_o     = ones(1,length(t_span));
y_o     = timeseries(y_o',t_span);
theta_o = ones(1,length(t_span)).*(pi/4);
theta_o = timeseries(theta_o',t_span);


% state space

A = [ k1*v*cos(theta) 0 -v*sin(theta);
      k1*v*sin(theta) 0  v*cos(theta);
             0        k2      k3    ];

EiganVals = eig(A);

B = [  0    0;
       0    0;
       0    0];

C = [1 0 0 ;
     0 1 0 ;
     0 0 1];

D = [0 0 ;
     0 0 ; 
     0 0];

IC = [-1 1 pi/4];


%%Run sim
output = sim('ControlledUnicycleAndDifferentialDrive.slx',[0 tmax]);

% Obtain outputs Uncicyle
states = output.states.data;

