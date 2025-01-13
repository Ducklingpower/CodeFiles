clc
clear
close all
Cd = 0.208;
A = 2.2; %%m^2
Ut = 1.2;
Ur = 0.01;
m = 1980; %%kg
p = 1.223; %% kg/m^3
g = 9.81; %%m/s^2


vtdt = @(t,V) -(1/(2*m))*Cd*p*A*(V^2)-Ur*m*g+Ut*m*g;
%%% 0 to 60 mph
t_span = 0:.1:1000;
IC = [0;0];%%[position, velocity]

dxdt = @(t,x) [x(2);-(1/(2*m))*Cd*p*A*(x(2)^2)-0.01*g+Ut*g];

[t,X] = ode45(dxdt,t_span,IC);
V60 = find(X(:,2)>=26.7);V60 = V60(1,1);
t60 = t(V60,1); %%estimate 0-60 time s
x60 = X(V60,1); %% etimate distance m
fprintf('The 0 to 60 time for tesla model s was claculated to be %s seconds. And the total distance traveled is %d meters.\n',t60,x60)




%%%%%%%%%%%%question (d)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% velocity and distance if the car starts from rest and is supplied
%%% with a tractive force from 30 mph (13.42m/s)

dxdt = @(t,x) [x(2);-(1/(2*m))*Cd*p*A*(x(2)^2)-.01*g+.01275*g];
[t,d] = ode45(dxdt,t_span,IC);

figure('Name','Q2,P(D)')
plot(t,d(:,1),"o","LineWidth",1)
title('Q2,P(D)')
grid on
hold on
plot(t,d(:,1),'LineWidth',2)
xlabel('time')
ylabel('position')
yyaxis right
ylabel('velocity')
hold on
plot(t,d(:,2),"o","LineWidth",1)
hold on
plot(t,d(:,2),'LineWidth',2,'LineStyle','-','Color','black')
xlabel('time')



%%%%%%%%%%%%%%%question (e)$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
IC = [0;13.4112];%%[position, velocity]
dxdt = @(t,x) [x(2);-(1/(2*m))*Cd*p*A*(x(2)^2)-Ur*g+Ut*g];

[t,d] = ode45(dxdt,0:.05:3,IC);

tt = zeros(1,1);
dd = zeros(1,1);
i=1;
while d(i,2)<27
tt(i,1) = t(i);
dd(i,1) = d(i);
dd(i,2) = d(i,2);

i = i+1;
end

figure('Name','Q2,P(e)')
plot(tt,dd(:,1),"o","LineWidth",1)
title('Q2,P(e)')
grid on
hold on
plot(tt,dd(:,1),'LineWidth',2)
xlabel('time')
ylabel('position')
hold on
yyaxis right
ylabel('velocity')
plot(tt,dd(:,2),'color','black','LineWidth',2,'LineStyle','-')
hold on
plot(tt,dd(:,2),"o","LineWidth",1)

%%%%%%%%%%%%%%%%%%%%%%%%question(f)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IC = [0;27];%%[position, velocity]
dxdt = @(t,x) [x(2);(1/(2*m))*Cd*p*A*(x(2)^2)+Ur*g-Ut*g];

[t,d] = ode45(dxdt,0:.05:3,IC);

tt = zeros(1,1);
dd = zeros(1,1);
i=1;
while d(i,2)>13
tt(i,1) = t(i);
dd(i,1) = d(i);
dd(i,2) = d(i,2);

i = i+1;
end

figure('Name','Q2,P(f)')
plot(tt,dd(:,1),"o","LineWidth",1)
title('Q2,P(f)')
grid on
hold on
plot(tt,dd(:,1),'LineWidth',2)
xlabel('time')
ylabel('position')
hold on
yyaxis right
ylabel('velocity')
plot(tt,dd(:,2),'color','black','LineWidth',2,'LineStyle','-')
hold on
plot(tt,dd(:,2),"o","LineWidth",1)

%%%%%%%%%%%%%%%%%%%question (g)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

IC = [0;27];%%[position, velocity]
dxdt = @(t,x) [x(2);(1/(2*m))*Cd*p*A*(x(2)^2)+Ur*g-Ut*g];

[t,d] = ode45(dxdt,0:.05:10,IC);

tt = zeros(1,1);
dd = zeros(1,1);
i=1;
while d(i,2)>=0
tt(i,1) = t(i);
dd(i,1) = d(i);
dd(i,2) = d(i,2);

i = i+1;
end

figure('Name','Q2,P(g)')
plot(tt,dd(:,1),"o","LineWidth",1)
title('Q2,P(g)')
grid on
hold on
plot(tt,dd(:,1),'LineWidth',2)
xlabel('time')
ylabel('position')
hold on
yyaxis right
ylabel('velocity')
plot(tt,dd(:,2),'color','black','LineWidth',2,'LineStyle','-')
hold on
plot(tt,dd(:,2),"o","LineWidth",1)


fprintf('The 60 to 0 time for tesla model s was claculated to be')
t_rest = max(tt)
x_rest = max(dd(:,1))


