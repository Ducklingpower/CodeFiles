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

damping_method = 1; % 1-5 0 = defualt 50
x = damping_method;


%% runningn sim: testing nonlinear damper theroy


sr= 0.001;
tmax=10;
t_span = 0:sr:tmax;

figure;
tiledlayout(3,1)
nexttile
road_option = [1 3 5];
for k = 1:3
    Road_type = road_option(k);
    for i = 0 : 1
    cs_nolinear = i;
    output = sim("quater_car.slx",[0 tmax]);
    
    xu = output.xu.Data; % un sprung mass displacment
    xs = output.xs.Data; % sprung mass displacment
    road = output.road.Data;
    
    
    plot(t_span, xs);
    hold on
    end
    title('Unsprung Mass Displacement');
    xlabel('Time (s)');
    ylabel('Displacement (ft)');
    plot(t_span,road,Linewidth = 2)
    legend("linear","nonlinear","road input")
    grid on
    nexttile;
end


%% runningn sim: full test all dampers and road inputs 


sr= 0.001;
tmax=10;
t_span = 0:sr:tmax;
cs_nolinear = 1;
figure;
tiledlayout(3,2)
nexttile
road_option = [1 2 3 4 5 6];
damping_option = [4 5 0];
for k = 1:6
    Road_type = road_option(k);
    for i = 1 : 3
    x = damping_option(i);
    output = sim("quater_car.slx",[0 tmax]);
    
    xu = output.xu.Data; % un sprung mass displacment
    xs = output.xs.Data; % sprung mass displacment
    road = output.road.Data;
    
    
    plot(t_span, xs,LineWidth=2);
    hold on
    end
    title('Unsprung Mass Displacement');
    xlabel('Time (s)');
    ylabel('Displacement (ft)');
    plot(t_span,road,Linewidth = 0.5 )
    legend("Option 4","Option 5","Linear","Input")
    grid on
    nexttile;
end

