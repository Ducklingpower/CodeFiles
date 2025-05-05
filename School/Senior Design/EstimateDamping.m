clc
close all
clear 
%% Params

m1 = 1; %kg
m2 = 5; %kg

k1 = 20000; %N/m
k2 = 500; %N/m

c1 = 2; %Ns/m
c2 = 20; %Ns/m the damper !!!

%% Mass/Stiffness matrices

M = [m1  0 ; 
     0  m2];

K = [k1+k2  -k2 ;
       -k2   k2 ];


[Evect,Eval] = eig(K,M);
NaturalFrequency = diag(sqrt(Eval)) / (2 * pi);



%% state space dx/dt = Ax+Bu  y = Cx+Du


IC = [0 0 0 0]; % Initial conditions

A = [      0             1            0         0   ;
     (-k1-k2)/(m1) (-c1-c2)/(m1)    k2/m1     c2/m1 ;
           0             0            0         1   ;
         k2/m2         c2/m2       -k2/m2    -c2/m2];





%% ODE solve

% signal one
x_init = [0; 0; 1; 0]; %[x , x_dot]
StateSpace = @(t, x1) A*x1;
[tspan, x1] = ode45(StateSpace, 0:.01: 10, x_init);
x1 = x1';


% signal one

c2 = 10;
A = [      0             1            0         0   ;
     (-k1-k2)/(m1) (-c1-c2)/(m1)    k2/m1     c2/m1 ;
           0             0            0         1   ;
         k2/m2         c2/m2       -k2/m2    -c2/m2];

x_init = [0; 0; 1.2; 20]; %[x , x_dot]
StateSpace = @(t, x2) A*x2;
[tspan, x2] = ode45(StateSpace, 0:.01: 10, x_init);
x2 = x2';


figure(1)
plot(tspan,x1(3,:),linewidth = 2)
hold on
plot(tspan,x2(3,:),linewidth = 2)
grid on 
legend("Top plate","Bottem plate")

