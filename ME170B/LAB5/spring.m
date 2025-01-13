clc
clear
close all


m = 3000;
k = 26000;
c = 1400;


A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [1; 0]; %[x , x_dot]
StateSpace = @(t, x) A*x;
[tspan, x] = ode45(StateSpace, 0:.01: 10, x_init);
x = x';

figure(1)
plot(tspan,x,linewidth = 2)




%% Raw data plots Small

 figure(1)
 tiledlayout(3,1)
 nexttile
plot(Acc_Data.Time_Acceleration,Acc_Data.Amplitude_Acceleration,LineWidth=3)
hold on

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 140.61;
c = 0.053;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [0.0025; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

a = (pi/4)*(1.5/39.37)^2;
u = c/(6*pi*a);
u  = u/10;
plot(tspan,acc,':',LineWidth=2)
title("Small, Air 200g added weight, c ="+ c + ", mu =" + u )
legend('Experimental', "estemated respones using C = " + c)
ylabel("m/s/s")
xlabel("s")
%%
 nexttile
plot(Acc_Data.Time_Acceleration,Acc_Data.Amplitude_Acceleration_1,LineWidth=3)
hold on

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 140.61;
c = 0.22;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [0.0015; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

a = (pi/4)*(2/39.37)^2;
u = c/(6*pi*a);
u  = u/10;
plot(tspan,acc,':',LineWidth=2)
title("Small, water 200g added weight, c ="+ c + ", mu =" + u )
legend('Experimental', "estemated respones using C = " + c)
ylabel("m/s/s")
xlabel("s")
%%
 nexttile
plot(Acc_Data.Time_Acceleration,Acc_Data.Amplitude_Acceleration_2,LineWidth=3)
hold on

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 140.61;
c = 0.65;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [0.0015; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

a = (pi/4)*(2/39.37)^2;
u = c/(6*pi*a);
u  = u/10;
plot(tspan,acc,':',LineWidth=2)
title("Small, glyce 200g added weight, c ="+ c + ", mu =" + u )
legend('Experimental', "estemated respones using C = " + c)
ylabel("m/s/s")
xlabel("s")

%% Raw data plots medium

 figure(2)
 tiledlayout(3,1)
 nexttile
plot(Acc_Data.Time_Acceleration,Acc_Data.Amplitude_Acceleration_3,LineWidth=3)
hold on

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 140.61;
c = 0.053;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [0.0026; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

a = (pi/4)*(1.5/39.37)^2;
u = c/(6*pi*a);
u  = u/10;
plot(tspan,acc,':',LineWidth=2)
title("Small, Air 200g added weight, c ="+ c + ", mu =" + u )
legend('Experimental', "estemated respones using C = " + c)

 nexttile
plot(Acc_Data.Time_Acceleration,Acc_Data.Amplitude_Acceleration_4,LineWidth=3)
hold on

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 140.61;
c = 0.35;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [0.001; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

a = (pi/4)*(2/39.37)^2;
u = c/(6*pi*a);
u  = u/10;
plot(tspan,acc,':',LineWidth=2)
title("medium, Air 200g added weight, c ="+ c + ", mu =" + u )
legend('Experimental', "estemated respones using C = " + c)


 nexttile
plot(Acc_Data.Time_Acceleration,Acc_Data.Amplitude_Acceleration_5,LineWidth=3)
hold on

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 140.61;
c = 1;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [0.0009; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

a = (pi/4)*(2/39.37)^2;
u = c/(6*pi*a);
u  = u/10;
plot(tspan,acc,':',LineWidth=2)
title("large, Air 200g added weight, c ="+ c + ", mu =" + u )
legend('Experimental', "estemated respones using C = " + c)



%% Raw data plots Large

 figure(3)
 tiledlayout(3,1)
 nexttile
plot(Acc_Data.Time_Acceleration,Acc_Data.Amplitude_Acceleration_6,LineWidth=3)
hold on

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 140.61;
c = 0.053;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [0.0026; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

a = (pi/4)*(1.5/39.37)^2;
u = c/(6*pi*a);
u  = u/10;
plot(tspan,acc,':',LineWidth=2)
title("Small, Air 200g added weight, c ="+ c + ", mu =" + u )
legend('Experimental', "estemated respones using C = " + c)

 nexttile
plot(Acc_Data.Time_Acceleration,Acc_Data.Amplitude_Acceleration_7,LineWidth=3)
hold on

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 140.61;
c = 0.70;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [0.001; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

a = (pi/4)*(2/39.37)^2;
u = c/(6*pi*a);
u  = u/10;
plot(tspan,acc,':',LineWidth=2)
title("medium, Air 200g added weight, c ="+ c + ", mu =" + u )
legend('Experimental', "estemated respones using C = " + c)


 nexttile
plot(Acc_Data.Time_Acceleration,Acc_Data.Amplitude_Acceleration_8,LineWidth=3)
hold on

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 140.61;
c = 1.25;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [0.0007; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 10, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

a = (pi/4)*(2/39.37)^2;
u = c/(6*pi*a);
u  = u/10;
plot(tspan,acc,':',LineWidth=2)
title("large, Air 200g added weight, c ="+ c + ", mu =" + u )
legend('Experimental', "estemated respones using C = " + c)

%%
figure(100)
c = 0.5;
for i  =1:5

added = 200/1000;

m = 109.87/1000 + 70/1000 + added;

k = 10;
c = c+0.5;
A = [0 1;-(k)/(m) -(c)/(m)];
x_init = [5; 0];
ode = @(t, x) A*x;
[tspan, x] = ode45(ode, 0:.01: 4, x_init);
x = x';
acc = (-k*x(1,:)-c*x(2,:))/m;

plot(tspan,x(1,:),LineWidth=2)
hold on
grid on
end

legend("c = 1 Ns/m","c = 1.5 Ns/m","c = 2 Ns/m", "c = 2.5 Ns/m", "c = 3 Ns/m")