clc
close all
clear 
%% 

%system parameters
mp = .21;
mc = .455;
lp = .31;
Km = 0.00767;
Kg = 3.7;
r = 0.00635;
R = 2.6;
g = 9.8;


%%
%show plot of the states, x = [x1,x2,x3,x4] versus their estimates, xhat --- Please
% show the true states together with the estimated states, for example x1 versus
% x1hat, x2 versus x2hat ...
%so that is easy to see how the estimates compared with the true states
%show plot of the control u

%%%%% the goal of this part of the last assignment is to design a feedback
%%%%% controller u based on state estimate
%%%%% such that the cart position of an inverted pendulum y(t) will
%%%%% follow the referece r(t)
%%%%  x1: cart position, x2: pendulum angle, x3: cart velocity,
%%%%  x4: pendulum angular velocity

A = [0 0 1 0;
0 0 0 1;
0 (-mp*g/mc) (-Km^2*Kg^2/R/r^2/mc) 0;
0 ((mp+mc)*g/mc/lp) (Km^2*Kg^2/R/r^2/mc/lp) 0];
B = [0; 0; Km*Kg/R/r/mc; -Km*Kg/R/r/mc/lp];



m = 1; M = 5; L = 2; g = -10; d = 1;
b = 1; % Pendulum up (b=1)
A = [0 1 0 0;
0 -d/M b*m*g/M 0;
0 0 0 1;
0 -b*d/(M*L) -b*(m+M)*g/(M*L) 0];
B = [0; 1/M; 0; b*1/(M*L)];



C = [1 0 0 0];
D = 0;




%%%%%closed loop poles
clp_K = [-1+1j;-1-1j;-5+j*5;-5-j*5];

% initial condition of the state x(0)
x0 = [0;0;pi;0];


%% Tracking input r(t) using state feedback

k = place(A,B,clp_K);
AA = A-B*k;


sys = ss(AA,B,C,D);
[num,den] = ss2tf(AA,B,C,D);
P = den(size(den))/num(size(num));
P = den(end)/num(end);

BB = B*P;

% squar wave 
% r(t) is a square wave with a magnitude of 0.05 meters
% and frequency of 0.5 rad/sec
t = 0:.01:20;
r = 3*square(0.5*t);

%simulating
[y,x]=lsim(A-B*k,B*P,C,D,r,t,x0);

theta_eq = pi;
x_actual = x+ repmat([0, theta_eq, 0, 0], size(x,1), 1);




%% Plotting output from sim and input r(t)
figure(Name = "Simulation output");
title("Simulating the carts position and input signal")
hold on
grid on
plot(t,r,"--",LineWidth= 2)
plot(t,y,LineWidth=2);
hold off

%% state estimation: closed loop observor

%closed loop poles for observer
clp_L = 5*clp_K;
L = (place(AA',C',clp_L))';

Abar = AA-L*C;
Bbar = eye(4);
Cbar = eye(4);
Dbar = zeros(4);

uBar = BB.*r+L.*y';
xhat0 = [0.2, 0.1, 0.3, 0.4]'; % IC

[yhat,xhat] = lsim(Abar,Bbar,Cbar,Dbar,uBar,t,xhat0);

%% Plotting output from state estimation sim
figure(Name = "Simulation output");
tiledlayout(2,2)

nexttile
plot(t,x(:,1),Linewidth = 2);
hold on
plot(t,xhat(:,1),"--",Linewidth = 2)
grid on
xlim([0 10])
legend("Cart Position","Cart Position Estimated")

nexttile
plot(t,x(:,2),Linewidth = 2);
hold on
plot(t,xhat(:,2),"-.",Linewidth = 2)
grid on
xlim([0 10])
legend("Theta","Theta Estimated")

nexttile
plot(t,x(:,3),Linewidth = 2);
hold on
plot(t,xhat(:,3),"--",Linewidth = 2)
grid on
xlim([0 10])
legend("Velocity","Velocity Estimated")

nexttile
plot(t,x(:,4),Linewidth = 2);
hold on
plot(t,xhat(:,4),"--",Linewidth = 2)
grid on
xlim([0 10])
legend("Omega","Omega Estimated")

%% for fun
figure
tiledlayout(2,2)
grid on

W = [1 1.3 1.5 1.7 2 3];
int = [-5 -4 -3 -2 -1 1 2 3 4 5];

for stateIdx = 1:4 % loop over x1 to x4
    nexttile
    hold on
    title(['State x', num2str(stateIdx)])
    xlabel('Time (s)')
    ylabel(['x', num2str(stateIdx)])
    grid on
    xlim([0 7]) % <-- Set x-axis limit here

    for j = 1:length(W)
        clp_L = W(j)*clp_K;
        L = place(AA',C',clp_L)';
    
        Abar = AA - L*C;
        Bbar = eye(4);
        Cbar = eye(4);
        Dbar = zeros(4);
    
        uBar = BB.*r + L.*y';
    
        for i = 1:length(int)
            xhat0 = [int(i), 0.1, 0.3, 0.4]'; % Varying x1 IC
            [~, xhat] = lsim(Abar, Bbar, Cbar, Dbar, uBar, t, xhat0);
    
            if i == 1 && j == 1
                % Plot true state once
                plot(t, x(:, stateIdx), 'k', 'LineWidth', 3)
            end
    
            plot(t, xhat(:, stateIdx), 'r', 'LineWidth', 0.5)
        end
    end
end

%% Control efforts plotting

for i=1:length(t)
u(i)=-k*(x(i,:))'+P*r(i);
end

for i=1:length(t)
ubar(:,i) = B*u(i)+L*y(i);
end

figure(Name = "Control efforts")
tiledlayout(2,1)
sgtitle("Control Efforts Over Time") % <-- This sets the overall title above all tiles

nexttile
title("Control Efforts U(t) = P*r(t) - K*x(t)")
plot(t, u, LineWidth = 2);
xlabel('Time (s)')
ylabel('u(t)')
grid on

nexttile
title("Control Efforts U(t) = B*u(t) + L*y(t)")
plot(t, ubar, LineWidth = 2)
legend("control for x1","control for x2","control for x3","control for x4")
xlabel("Time (s)")
ylabel("u(t)")
grid on



%% running annimation of simulation
animate_cart_pendulum(x(:,1), x(:,3), x(:,2), x(:,4))

%% Part B

clc
clear

% System: Reduced-order observer for double integrator dynamics
A = [0 0 1 0;
     0 0 0 1;
     0 0 0 0;
     0 0 0 0]; % A is unstable

B = [0 0;
     0 0;
     1 0;
     0 1];

C = [1 0 0 0;
     0 1 0 0];

D = 0;

% Reduced-order observer poles
clp_L = [-1+1j, -1-1j];
L = place([0 0; 0 0]', [1 0; 0 1]', clp_L)';

% Input signal
t = 0:0.1:20;
u = 0.01 * [cos(t); cos(t)];

x0 = zeros(4,1);
z0 = [0.1; 0.2];

% Simulate true system
[y, x] = lsim(A, B, C, D, u, t, x0);

% Compute observer input
for i = 1:length(t)
    ubar(:,i) = -L * (L * y(i,:)') + u(:,i);
end

% Simulate reduced-order observer
[zhat, xhat] = lsim(-eye(2) * L, eye(2), eye(2), zeros(2), ubar, t, z0);
what = zhat + y * L'; % Final estimated states xhat_3 and xhat_4

% Figure 1: Measured positions x1 and x2
figure
plot(t, x(:,1), 'k', 'LineWidth', 2);
hold on
plot(t, x(:,2), 'g--', 'LineWidth', 2);
grid on
xlabel('Time (s)')
ylabel('Position')
title('Measured States x_1 and x_2 (Positions)')
legend('x_1', 'x_2')

% Figure 2: Velocities and their Estimates
figure
plot(t, x(:,3), 'k', 'LineWidth', 2);
hold on
plot(t, x(:,4), 'k--', 'LineWidth', 2);
plot(t, what(:,1), 'r', 'LineWidth', 2);
plot(t, what(:,2), 'r--', 'LineWidth', 2);
grid on
xlabel('Time (s)')
ylabel('Velocity')
title('True vs Estimated Velocities: x_3, x_4 vs hatx_3, hatx_4')
legend('x_3','x_4','hatx_3','hatx_4')

% Figure 3: Individual Velocity Estimation Comparison
figure
tiledlayout(2,1)

nexttile
plot(t, x(:,3), 'k', 'LineWidth', 2);
hold on
plot(t, what(:,1), 'r--', 'LineWidth', 2);
grid on
xlabel('Time (s)')
ylabel('x_3 and hatx_3')
title('True vs Estimated: x_3 and hatx_3')
legend('x_3', 'hatx_3')

nexttile
plot(t, x(:,4), 'k', 'LineWidth', 2);
hold on
plot(t, what(:,2), 'r--', 'LineWidth', 2);
grid on
xlabel('Time (s)')
ylabel('x_4 and hatx_4')
title('True vs Estimated: x_4 and hatx_4')
legend('x_4', 'hatx_4')
