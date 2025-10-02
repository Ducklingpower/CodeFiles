clc 
close all
clear

format longG
%%

w = 0:0.01:10;
t = 0:0.05:0.2;

for i = 1:length(t)
y(:,i) = ((10)./(sqrt((10-w.^2).^2 + w.^2))) .* sqrt((cos(t(i).*w)-1).^2 + (sin(t(i).*w)).^2) ;
end

figure
plot(w,y,'.',LineWidth=1)
grid on

legend('\tau = 0','\tau = 0.05','\tau = 0.1','\tau = 0.15','\tau = 0.2')

max_tau = max(y(:,3));


%% question

% closed looped poles
root = roots([1,220,484,1000,240]);
