clc
close all
clear 
%% Final Sim 
g = 32.17;

W =  3000; %lb
Ws = 2700; %lb

m = W/g; % slugs
ms = Ws/g; % 

x1 = 3.5; % ft
x2 = -4.5; 
h = -1.2;
t =6;
c = 0.5;

Iz = 40000/g; %slug ft^2
Ix = 15000/g; 

dphiF = 8000;%lb-ft
dphiR = 5000;

ddphiF = 1000;%lb-ft/s
ddphiR = 500;

% linear tires
c1 = 140 *(180/pi);% slug/rad
c2=c1;

ca = c1+c2;
cb = x1*c1+x2*c2;
cc = x1^2*c1+x2^2*c2;

cPhi1 = 0;
cPhi2 = 0;

K = dphiF+dphiR;
D = ddphiF+ddphiR;



Ux = 30; %MPH
Ux = Ux * (5280/3600);%ft/s



M1 = [m 0 -ms*h;0 Iz -ms*h*c; -ms*h -ms*h*c Ix];
M2 = [-ca/Ux (-cb/Ux)-m*Ux 0 cPhi1+cPhi2;
      -cb/Ux -cc/Ux 0 x1*cPhi1+x2*cPhi2;
      0 ms*h*Ux -D -K];
M3 = [c1 c2; x1*c1 x2*c2; 0 0];

% ss
A = [M1\M2; 0 0 1 0];
B = [M1\M3; 0 0];


eigan = eigs(A)



% sim 
t_sim = 0:0.01:20;   % 5 seconds

% step magnitude (radians)
delta1_step = 45*pi/180;   % 45 deg step in rads

% input matrix [delta1, delta2]
u = zeros(length(t_sim),2);
u(:,1) = delta1_step;   % step in delta1
u(:,2) = 0;             % delta2 = 0

% initial condition
x0 = zeros(4,1);

% create state-space system
sys = ss(A,B,eye(4),zeros(4,2));

% simulate
[x,t_out] = lsim(sys,u,t_sim,x0);

% plot
figure
plot(t_out,x)
legend('v','r','\phi dot','\phi')
xlabel('Time (s)')
ylabel('States')
title('Response to Step in \delta_1')
grid on