clc

clear
%%
addpath '/home/elijah/MATLAB Add-Ons/Toolboxes/MFeval/MFeval'

% Load TIR files
front_tir = '2024003_Firestone_Firehawk Left Rear SC_RC__385_30R15_MF62_UM4.tir';
rear_tir  = '2024003_Firestone_Firehawk Right Rear SC_RC_385_30R15_MF62_UM4.tir';
            
% % Slip angle sweep
alpha = linspace(-0.45, 0.45, 300); % radians

%Fz_front_sweep = [800 1200 1600 2000 2400 2800 3200 3600]; % centered around 1465N
%Fz_rear_sweep  = [1200 1600 2000 2200 2400 2800 3200 3600 4000]; % centered around 2200N
Fz_front_sweep = linspace(550, 3700, 10);
Fz_rear_sweep = linspace(850, 4200, 10);
Fz_front_sweep = linspace(850, 4200, 10);

% Preallocate
Fy_front_all = zeros(length(Fz_front_sweep), length(alpha));
Fy_rear_all  = zeros(length(Fz_rear_sweep),  length(alpha));

for j = 1:length(Fz_rear_sweep)
    Fz = Fz_rear_sweep(j);
    for i = 1:length(alpha)
        out = mfeval(rear_tir, [Fz, 0, alpha(i), 0, 0, 40], 211);
        Fy_rear_all(j,i) = out(6);
    end
end

for j = 1:length(Fz_front_sweep)
    Fz = Fz_front_sweep(j);
    for i = 1:length(alpha)
        out = mfeval(front_tir, [Fz, 0, alpha(i), 0, 0, 40], 211);
        Fy_front_all(j,i) = out(6);
    end
end



%% plotting output
figure
for i = 1:10
plot(alpha(1,:),Fy_front_all(i,:),'r')
hold on
plot(alpha(1,:),Fy_rear_all(i,:),'g')
hold on

plot(alpha(1,:),Fy_rear_all(i,:)+Fy_front_all(i,:),'b')
hold on
grid on
end
legend("Fy_f","Fy_r")

