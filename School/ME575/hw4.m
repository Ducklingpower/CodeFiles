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


%% question 2

% closed looped poles
root = roots([1,220,484,1000,240]);

% showig stability using stablitiyt using robust stabiltiy

w = 0.1:0.01:10;

N = sqrt((240-480*w.^2).^2 + (600.*w - 120.*w.^3).^2) .* w;
D = sqrt((w.^4 - 484.*w.^2 + 240).^2 + (-220.*w.^3 + 1000.*w).^2) .* sqrt(w.^2 + 10);

Robust = N./D;


figure(Name="Cheching ofr stability")

plot(w(:),Robust(1,:),"*")
xlabel("frequency \omega")
ylabel("Robust mag")
grid on
% system is stable

%% Q3 
% checking stabiltiy 
tau = 0.01:0.01:2;

% start color
hex = '#FF0000';                         
rgb = sscanf(hex(2:end),'%2x%2x%2x',[1 3])/255;   
n  = numel(tau);
t  = linspace(1,0,n).';                   
% colors = t .* rgb;  
colors = 1 - (1-rgb).*t;


figure 
hold on
grid on 
xlabel('Re\{s\}'); 
ylabel('Im\{s\}'); 

% color bar
cmap = [linspace(rgb(1),1,n)',linspace(rgb(2),1,n)',linspace(rgb(3),1,n)'];
colormap(cmap)
clim([tau(1) tau(end)]);



for i = 1:n
    data = roots([tau(i), 12*tau(i)^2 + 2*tau(i), 24*tau(i)+1, 12, 100]);
    scatter(real(data), imag(data), 36, colors(i,:), 'filled');  % color for this τ
    if i==1
        pause(3); 
    else
        pause(0.001); 
    end
end
