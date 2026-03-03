clc
close all
clear 
%% SIM 3 Pitch plain model
% params

m = 3000 / (32.17 * 12); %lb/in*s^2 ????
I = 20000;
a = 4*12;% inches
b = 4*12;% inches
K1 = 200;% lb/in
K2 = 300;% lb/in

L = a+b;

% state space rep



% State space
A = [ 0 0 1 0;
      0 0 0 1;
     -(K1+K2)/m      -(K1*a - K2*b)/m     0 0;
     -(K1*a - K2*b)/I -(K1*a^2 + K2*b^2)/I 0 0 ];

B = [ 0     0;
      0     0;
      K1/m  K2/m;
      (a*K1)/I  -(b*K2)/I ];

C = [ 1 0 0 0;
      0 1 0 0 ];

D = zeros(2,2);

%% sim stuff
sr = 0.0001;
tmax =15;
t = 0:sr:tmax;
hit = 5;
v_mph = 10;
v_inps = v_mph*((5280*12)/(3600));
delay = L/v_inps;

% step
figure
speeds = [2 5 10 20 40 80];

colors = [linspace(1,0.4,length(speeds))' zeros(length(speeds),1) zeros(length(speeds),1)];

for k = 1:length(speeds)

    v_inps = speeds(k)*((5280*12)/(3600));
    delay = L/v_inps;

    in1 = zeros(length(t),1);
    in2 = zeros(length(t),1);

    for i = 1:length(t)-1
        if t(i) >= hit && t(i)<=tmax
            in1(i) = 2/12;
        end
    
        if t(i)>=hit + round(delay,3) && t(i)<=tmax
            in2(i) =2/12;
        end
    end
    
    input1 = timeseries(in1,t);
    input2 = timeseries(in2,t);
    
    step1 = input1;
    step2 = input2;
    
    output = sim('pitch_sim.slx',[0 tmax]);

    position = output.simout.Data(:,1);
    theta = output.simout.Data(:,2);
    P = k-1;
    subplot(6,2,P*2+1);
    xlabel('Time (s)');
    ylabel('Position (inches)');
    title('Position Response');
    plot(t,in1 ,'LineWidth',1.5);
    hold on
    plot(t,in2 ,'LineWidth',1.5);
    hold on
    plot(t, position,'Color',colors(k,:),'LineWidth',1.5);
    
    subplot(6,2,P*2+2);
    plot(t, theta,'Color',colors(k,:),'LineWidth',1.5);
    xlabel('Time (s)');
    ylabel('Pitch Angle (rad)');
    title('Pitch Response');
    hold on


end





