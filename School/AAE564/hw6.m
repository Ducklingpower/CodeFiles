clc
close all
clear
%% Hw 6

% part e
Omega = 1;
w = sqrt(2)*Omega;

A = [0, 0, 1, 0;
     0, 0, 0, 1;
     Omega^2-w^2/2, w^2/2, 0, 0;
     w^2/2, Omega^2-w^2/2, 0, 0];

% IC
x0 = [1; -1; 0; 0];

% sim
tspan = [0 20];
[t,x] = ode45(@(t,x) A*x, tspan, x0);

% Plot 1
figure;
plot(t,x(:,1),'b');
hold on;
plot(t,-x(:,2),'r--');
xlabel('Time (s)');
ylabel('Displacement');
legend('\delta q_1','-\delta q_2');
grid on;

% Plot 2
figure;
plot(x(:,1),x(:,2));
xlabel('\delta q_1');
ylabel('\delta q_2');
grid on;

%%

% part f

% New IC
x0 = [1; 1; -1; -1];

% Simulate
[t,x] = ode45(@(t,x) A*x, [0 10], x0);

% Plot 1
figure;
plot(t,x(:,1),'b');
hold on;
plot(t,x(:,2),'r--');
xlabel('Time (s)');
ylabel('Displacement');
legend('\delta q_1','\delta q_2');
grid on;

% Plot 2
figure;
plot(x(:,1),x(:,2));
xlabel('\delta q_1');
ylabel('\delta q_2');
axis equal;
grid on;


% part g 

%% Part (g)

% Initial conditions
x0 = [1; 1; 1; 1];

% Simulate
[t,x] = ode45(@(t,x) A*x, [0 5], x0);

% Plot 1
figure;
plot(t,x(:,1),'b');
hold on;
plot(t,x(:,2),'r--');
xlabel('Time (s)');
ylabel('Displacement');
legend('\delta q_1','\delta q_2');
grid on;

% Plot 2
figure;
plot(x(:,1),x(:,2));
xlabel('\delta q_1');
ylabel('\delta q_2');
axis equal;
grid on;
