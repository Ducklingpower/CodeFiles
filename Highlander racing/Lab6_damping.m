
m  = 1;
kf = 10;
cf = 0.5;
x_init = [1; 0];

A = [0 1;-(kf)/(m) -(cf)/(m)];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 40, x_init);

x = x';

plot(tspan,x(1,:),LineWidth=2);