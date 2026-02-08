clc
close all
clear
%% rinning quater car sim model

ks = 100 * 12;  %lb/ft
cs = 50;    % lb/s/ft optimal = 10
ms = 1000/32.17; % slugs

kt = 1000 * 12; %lb/ft
ct = 0.01 * 12; %lb/ft/s
mu =100/32.17;  % slugs


%% sim parameters
Road_type = 1;

cs_nolinear = 0; % adding nonlinear damping


%% runningn sim 


sr= 0.001;
tmax=10;
t_span = 0:sr:tmax;

figure;
for i = 0 : 1
cs_nolinear = i;
output = sim("quater_car.slx",[0 tmax]);

xu = output.xu.Data; % un sprung mass displacment
xs = output.xs.Data; % sprung mass displacment
road = output.road.Data;


plot(t_span, xs);
hold on
plot(t_span,road)
title('Unsprung Mass Displacement');
xlabel('Time (s)');
ylabel('Displacement (ft)');

end

