clear,
clc,
close all
%%%%%%%%%%%%%%%%%%%%%% Note:

load("C:\Users\elija\OneDrive\Documents\MATLAB\Highlander racing\VD\Tire fitting\lateral_tire_test.mat")

mechTrail = 0.005;  %meters
scrubR = 0.0254;      %meters
SteeringRT = 0.01905;  %meters
pnumatic = 0.021428; %meters
pitManT = 0.100;  %meters
Mz2 = FY.*pnumatic;
M_kingPinAxis = (FY.*(mechTrail))+(Mz2); %N-M
force_arm = M_kingPinAxis/pitManT;
torque = force_arm*SteeringRT;
torqueraw=force_arm;


figure(10)

plot(SA,torqueraw);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[y,y_reject] = organizer(torque);
% y  = organized data, sorted in an array. columns = # of data set.
%                                  rows = actual data with in a data set
%           
%y_reject = left out data that did not make it to the y array.(lost data)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[fit,coef] = fitter(SA,y);


% 
%  figure(3)
% plot(SA,fit);
% grid on




figure(2)
for i=1:100
plot(SA,y_reject(:,i),'color',rand(1,3),'Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on
end



for i=1:25
figure(1)
hex = rand(1,3);

plot(SA,y(:,i),'color',hex,MarkerSize=2,Marker='.',LineStyle='none')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on

curve = coef(i,1)*sin(coef(i,2)*atan(coef(i,3).*SA-coef(i,4)*(coef(i,3).*SA-atan(coef(i,3).*SA))));

% 
% plot(SA,curve,"color",hex,"LineWidth",2);
% grid on



figure(3)




plot(SA,curve,"color",hex,"LineWidth",2);
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on

curve = coef(i,1)*sin(coef(i,2)*atan(coef(i,3).*SA-coef(i,4)*(coef(i,3).*SA-atan(coef(i,3).*SA))));

end


figure(4)
tiledlayout(3,3)
for i =1:9



    curve = coef(i,1)*sin(coef(i,2)*atan(coef(i,3).*SA-coef(i,4)*(coef(i,3).*SA-atan(coef(i,3).*SA))));
   
    plot(SA,curve)
    hold on
    plot(SA,y(:,i))
    hold on
    nexttile





end







