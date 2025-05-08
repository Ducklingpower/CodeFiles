clc
clear 
close all
%% Data extraction
Data = load("lateral_tire_test.mat");

%% fake data 

Data_SA = transpose(linspace(-14,14,100));
Data_Fz = ones(100,1).*0;



figure(name= "Lateral model")
for i = 1:20
Data_Fz =Data_Fz+50;
Fy = LateralTireModel(Data_Fz,Data_SA);
plot(Data_SA,Fy)
xlim([-14 14])
grid on
xlabel("SA")
ylabel("Fy")
title("Lateral Model")
hold on
end











%% Using Tire Model Functions
Data_Fy = Data.FY * 0.7;
Data_Fz = Data.FZ;
Data_Mz = Data.MZ;
Data_SA = Data.SA;


Fy = LateralTireModel(Data_Fz,Data_SA);
Mz = AligningTireModel(Data_Fz,Data_SA);

%% Plotting SA vs Fy

figure(name= "Lateral model + Raw Data")

tiledlayout(1,2)
nexttile
plot(Data_SA,Fy)
xlim([-14 14])
grid on
xlabel("SA")
ylabel("Fy")
title("Lateral Model")

nexttile
plot(Data_SA,Data_Fy)
xlim([-14 14])
grid on
xlabel("SA")
ylabel("Fy")
title("Raw data")

%--------------------------------------------------------------------------

figure(name = "Overlayed Model + raw data")

plot(Data_SA,Data_Fy)
hold on
plot(Data_SA,Fy)
xlim([-14 14])
grid on
xlabel("SA")
ylabel("Fy")
title("Overlayed data")
legend("Raw data","Tire Model")

%% Plotting SA vs Mz

figure(name= "Lateral model + Raw Data")

tiledlayout(1,2)
nexttile
plot(Data_SA,Mz)
xlim([-14 14])
grid on
xlabel("SA")
ylabel("Fy")
title("Lateral Model")

nexttile
plot(Data_SA,Data_Mz)
xlim([-14 14])
grid on
xlabel("SA")
ylabel("Fy")
title("Raw data")

%--------------------------------------------------------------------------

figure(name = "Overlayed Model + raw data")

plot(Data_SA,Data_Mz)
hold on
plot(Data_SA,Mz)
xlim([-14 14])
grid on
xlabel("SA")
ylabel("Fy")
title("Overlayed data")
legend("Raw data","Tire Model")

