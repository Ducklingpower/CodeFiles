clc
clear
close all
%% Gathering Cell data from sheets

Missle   = readtable("Missle.csv");
Sphear   = readtable("Sphear.csv");
Inverted = readtable("Inverted.csv");
Disk     = readtable("Disk.csv");

%% Convert to SI

% Missle
Missle(:,4)   = Missle(:,4)./2.237;                   %MPH to m/s
Missle(:,5)   = Missle(:,5).*6895;                    %Psi to Pa
for i = 1:600
Missle(i,6)   = (Missle(i,6)-32).*(5/9) + 273.15;     %F to K
end
Missle(:,8)   = Missle(:,8).*248.8;                   %water In to pa
Missle(:,9)   = Missle(:,9).*248.8;                   %water In to pa
Missle(:,10)  = Missle(:,10).*4.44822;                %LBF to N
Missle(:,11)  = Missle(:,11).*4.44822;                %LBF to N
Missle(:,12)  = Missle(:,12).*4.44822;                %LBF to N

% Sphear
Sphear(:,4)   = Sphear(:,4)./2.237;                   %MPH to m/s
Sphear(:,5)   = Sphear(:,5).*6895;                    %Psi to Pa
for i = 1:600
Sphear(i,6)   = (Sphear(i,6)-32).*(5/9) + 273.15;     %F to K
end
Sphear(:,8)   = Sphear(:,8).*248.8;                   %water In to pa
Sphear(:,9)   = Sphear(:,9).*248.8;                   %water In to pa
Sphear(:,10)  = Sphear(:,10).*4.44822;                %LBF to N
Sphear(:,11)  = Sphear(:,11).*4.44822;                %LBF to N
Sphear(:,12)  = Sphear(:,12).*4.44822;                %LBF to N

% Inverted
Inverted(:,4)   = Inverted(:,4)./2.237;                %MPH to m/s
Inverted(:,5)   = Inverted(:,5).*6895;                 %Psi to Pa
for i = 1:600
Inverted(i,6)   = (Inverted(i,6)-32).*(5/9) + 273.15;  %F to K
end
Inverted(:,8)   = Inverted(:,8).*248.8;                %water In to pa
Inverted(:,9)   = Inverted(:,9).*248.8;                %water In to pa
Inverted(:,10)  = Inverted(:,10).*4.44822;             %LBF to N
Inverted(:,11)  = Inverted(:,11).*4.44822;             %LBF to N
Inverted(:,12)  = Inverted(:,12).*4.44822;             %LBF to N

%Disk
Disk(:,5)   = Disk(:,5).*6895;                         %Psi to Pa
for i = 1:600
Disk(i,6)   = (Disk(i,6)-32).*(5/9) + 273.15;          %F to K
end
Disk(:,8)   = Disk(:,8).*248.8;                        %water In to pa
Disk(:,9)   = Disk(:,9).*248.8;                        %water In to pa
Disk(:,10)  = Disk(:,10).*4.44822;                     %LBF to N
Disk(:,11)  = Disk(:,11).*4.44822;                     %LBF to N
Disk(:,12)  = Disk(:,12).*4.44822;                     %LBF to N




%% Breaking up data into sections

% MISSLE

MissleExp1 = table2array(Missle(1:100,4:end));      %Deg:0   ,V:50 mph
MissleExp2 = table2array(Missle(101:200,4:end));    %Deg:15  ,V:50 mph
MissleExp3 = table2array(Missle(201:300,4:end));    %Deg:30  ,V:50 mph
MissleExp4 = table2array(Missle(301:400,4:end));    %Deg:0   ,V:85 mph
MissleExp5 = table2array(Missle(401:500,4:end));    %Deg:15  ,V:85 mph
MissleExp6 = table2array(Missle(501:600,4:end));    %Deg:30  ,V:85 mph


% Sphear

SphearExp1 = table2array(Sphear(1:100,4:end));      %Deg:0   ,V:50 mph
SphearExp2 = table2array(Sphear(101:200,4:end));    %Deg:15  ,V:50 mph
SphearExp3 = table2array(Sphear(201:300,4:end));    %Deg:30  ,V:50 mph
SphearExp4 = table2array(Sphear(301:400,4:end));    %Deg:0   ,V:65 mph
SphearExp5 = table2array(Sphear(401:500,4:end));    %Deg:15  ,V:65 mph
SphearExp6 = table2array(Sphear(501:600,4:end));    %Deg:30  ,V:65 mph


% Inverted 

InvertedExp1 = table2array(Inverted(1:100,4:end));   %Deg:0   ,V:50 mph
InvertedExp2 = table2array(Inverted(101:200,4:end)); %Deg:15  ,V:50 mph
InvertedExp3 = table2array(Inverted(201:300,4:end)); %Deg:30  ,V:50 mph
InvertedExp4 = table2array(Inverted(301:400,4:end)); %Deg:0   ,V:65 mph
InvertedExp5 = table2array(Inverted(401:500,4:end)); %Deg:15  ,V:65 mph
InvertedExp6 = table2array(Inverted(501:600,4:end)); %Deg:30  ,V:65 mph


% Plate

DiskExp1 = table2array(Disk(1:100,4:end));           %Deg:0   ,V:50 mph
DiskExp2 = table2array(Disk(101:200,4:end));         %Deg:15  ,V:50 mph
DiskExp3 = table2array(Disk(201:300,4:end));         %Deg:30  ,V:50 mph
DiskExp4 = table2array(Disk(301:400,4:end));         %Deg:0   ,V:65 mph
DiskExp5 = table2array(Disk(401:500,4:end));         %Deg:15  ,V:65 mph
DiskExp6 = table2array(Disk(501:600,4:end));         %Deg:30  ,V:65 mph




%% Calcs

%Area calcs
AreaMissle   = 0.00614608; % m^2
AreaSphear   = 0.06280000; % m^2
AreaInverted = 0.01809800; % m^2
AreaPlate    = 0.03305800; % m^2

% Coef. of Drag
Cd_MissleExp1 = MissleExp1(:,7) ./(MissleExp1(:,5).*AreaMissle);       %Cd Sphear 
Cd_MissleExp2 = MissleExp2(:,7) ./(MissleExp2(:,5).*AreaMissle);       %Cd Sphear 
Cd_MissleExp3 = MissleExp3(:,7) ./(MissleExp3(:,5).*AreaMissle);       %Cd Sphear 
Cd_MissleExp4 = MissleExp4(:,7) ./(MissleExp4(:,5).*AreaMissle);       %Cd Sphear 
Cd_MissleExp5 = MissleExp5(:,7) ./(MissleExp5(:,5).*AreaMissle);       %Cd Sphear 
Cd_MissleExp6 = MissleExp6(:,7) ./(MissleExp6(:,5).*AreaMissle);       %Cd Sphear 

Cd_SphearExp1 = -SphearExp1(:,7) ./(SphearExp1(:,5).*AreaSphear);       %Cd Sphear 
Cd_SphearExp2 = -SphearExp2(:,7) ./(SphearExp2(:,5).*AreaSphear);       %Cd Sphear 
Cd_SphearExp3 = -SphearExp3(:,7) ./(SphearExp3(:,5).*AreaSphear);       %Cd Sphear 
Cd_SphearExp4 = -SphearExp4(:,7) ./(SphearExp4(:,5).*AreaSphear);       %Cd Sphear 
Cd_SphearExp5 = -SphearExp5(:,7) ./(SphearExp5(:,5).*AreaSphear);       %Cd Sphear 
Cd_SphearExp6 = -SphearExp6(:,7) ./(SphearExp6(:,5).*AreaSphear);       %Cd Sphear 

Cd_InvertedExp1 = -InvertedExp1(:,7) ./(InvertedExp1(:,5).*AreaInverted); %Cd Sphear 
Cd_InvertedExp2 = -InvertedExp2(:,7) ./(InvertedExp2(:,5).*AreaInverted); %Cd Sphear 
Cd_InvertedExp3 = -InvertedExp3(:,7) ./(InvertedExp3(:,5).*AreaInverted); %Cd Sphear 
Cd_InvertedExp4 = -InvertedExp4(:,7) ./(InvertedExp4(:,5).*AreaInverted); %Cd Sphear 
Cd_InvertedExp5 = -InvertedExp5(:,7) ./(InvertedExp5(:,5).*AreaInverted); %Cd Sphear 
Cd_InvertedExp6 = -InvertedExp6(:,7) ./(InvertedExp6(:,5).*AreaInverted); %Cd Sphear

Cd_DiskExp1 = -DiskExp1(:,7) ./(DiskExp1(:,5).*AreaPlate);             %Cd Sphear 
Cd_DiskExp2 = -DiskExp2(:,7) ./(DiskExp2(:,5).*AreaPlate);             %Cd Sphear 
Cd_DiskExp3 = -DiskExp3(:,7) ./(DiskExp3(:,5).*AreaPlate);             %Cd Sphear 
Cd_DiskExp4 = -DiskExp4(:,7) ./(DiskExp4(:,5).*AreaPlate);             %Cd Sphear 
Cd_DiskExp5 = -DiskExp5(:,7) ./(DiskExp5(:,5).*AreaPlate);             %Cd Sphear 
Cd_DiskExp6 = -DiskExp6(:,7) ./(DiskExp6(:,5).*AreaPlate);             %Cd Sphear 



% Coef. of Lift
Cl_MissleExp1 = MissleExp1(:,8) ./(MissleExp1(:,5).*AreaMissle);       %Cl Sphear 
Cl_MissleExp2 = MissleExp2(:,8) ./(MissleExp2(:,5).*AreaMissle);       %Cl Sphear 
Cl_MissleExp3 = MissleExp3(:,8) ./(MissleExp3(:,5).*AreaMissle);       %Cl Sphear 
Cl_MissleExp4 = MissleExp4(:,8) ./(MissleExp4(:,5).*AreaMissle);       %Cl Sphear 
Cl_MissleExp5 = MissleExp5(:,8) ./(MissleExp5(:,5).*AreaMissle);       %Cl Sphear 
Cl_MissleExp6 = MissleExp6(:,8) ./(MissleExp6(:,5).*AreaMissle);       %Cl Sphear 

Cl_SphearExp1 = -SphearExp1(:,8) ./(SphearExp1(:,5).*AreaSphear);       %Cl Sphear 
Cl_SphearExp2 = -SphearExp2(:,8) ./(SphearExp2(:,5).*AreaSphear);       %Cl Sphear 
Cl_SphearExp3 = -SphearExp3(:,8) ./(SphearExp3(:,5).*AreaSphear);       %Cl Sphear 
Cl_SphearExp4 = -SphearExp4(:,8) ./(SphearExp4(:,5).*AreaSphear);       %Cl Sphear 
Cl_SphearExp5 = -SphearExp5(:,8) ./(SphearExp5(:,5).*AreaSphear);       %Cl Sphear 
Cl_SphearExp6 = -SphearExp6(:,8) ./(SphearExp6(:,5).*AreaSphear);       %Cl Sphear 

Cl_InvertedExp1 = -InvertedExp1(:,8) ./(InvertedExp1(:,5).*AreaInverted); %Cl Sphear 
Cl_InvertedExp2 = -InvertedExp2(:,8) ./(InvertedExp2(:,5).*AreaInverted); %Cl Sphear 
Cl_InvertedExp3 = -InvertedExp3(:,8) ./(InvertedExp3(:,5).*AreaInverted); %Cl Sphear 
Cl_InvertedExp4 = -InvertedExp4(:,8) ./(InvertedExp4(:,5).*AreaInverted); %Cl Sphear 
Cl_InvertedExp5 = -InvertedExp5(:,8) ./(InvertedExp5(:,5).*AreaInverted); %Cl Sphear 
Cl_InvertedExp6 = -InvertedExp6(:,8) ./(InvertedExp6(:,5).*AreaInverted); %Cl Sphear

Cl_DiskExp1 = -DiskExp1(:,8) ./(DiskExp1(:,5).*AreaPlate);             %Cl Sphear 
Cl_DiskExp2 = -DiskExp2(:,8) ./(DiskExp2(:,5).*AreaInverted);             %Cl Sphear 
Cl_DiskExp3 = -DiskExp3(:,8) ./(DiskExp3(:,5).*AreaInverted);             %Cl Sphear 
Cl_DiskExp4 = -DiskExp4(:,8) ./(DiskExp4(:,5).*AreaInverted);             %Cl Sphear 
Cl_DiskExp5 = -DiskExp5(:,8) ./(DiskExp5(:,5).*AreaInverted);             %Cl Sphear 
Cl_DiskExp6 = -DiskExp6(:,8) ./(DiskExp6(:,5).*AreaInverted);             %Cl Sphear 


%% Plots

% Cd and cl for Missle
figure(1)
tiledlayout(1,2)
nexttile
semilogy(1:100,Cd_MissleExp1,linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp2,linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp3,linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp4,linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp5,linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp6,linewidth=2)
xlabel('Samples');
ylabel('Drag Coef.');
legend("Missle, 0 deg, 50mph","Missle, 15 deg, 50mph","Missle, 15 deg, 50mph","Missle, 0 deg, 85mph","Missle, 15 deg, 85mph","Missle, 30 deg, 85mph");
title("Cd Missle Exp 1-6")
nexttile
semilogy(1:100,abs(Cl_MissleExp1),linewidth=2)
hold on
semilogy(1:100,abs(Cl_MissleExp2),linewidth=2)
hold on
semilogy(1:100,abs(Cl_MissleExp3),linewidth=2)
hold on
semilogy(1:100,abs(Cl_MissleExp4),linewidth=2)
hold on
semilogy(1:100,abs(Cl_MissleExp5),linewidth=2)
hold on
semilogy(1:100,abs(Cl_MissleExp6),linewidth=2)
xlabel('Samples');
ylabel('Lift Coef.');
legend("Missle, 0 deg, 50mph","Missle, 15 deg, 50mph","Missle, 15 deg, 50mph","Missle, 0 deg, 85mph","Missle, 15 deg, 85mph","Missle, 30 deg, 85mph");
title("Cl Missle Exp 1-6")




% Cd and Cl for sphear

figure(2)
tiledlayout(1,2)
nexttile
semilogy(1:100,Cd_SphearExp6,linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp5,linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp4,linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp3,linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp2,linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp1,linewidth=2)
xlabel('Samples');
ylabel('Drag Coef.');
legend("Sphear, 0 deg, 50mph","Sphear, 15 deg, 50mph","Sphear, 15 deg, 50mph","Sphear, 0 deg, 85mph","Sphear, 15 deg, 85mph","Sphear, 30 deg, 85mph");
title("CD Sphear Exp 1-6")
nexttile
semilogy(1:100,abs(Cl_SphearExp6),linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp5),linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp4),linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp3),linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp2),linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp1),linewidth=2)
xlabel('Samples');
ylabel('Lift Coef.');
legend("Sphear, 0 deg, 50mph","Sphear, 15 deg, 50mph","Sphear, 15 deg, 50mph","Sphear, 0 deg, 85mph","Sphear, 15 deg, 85mph","Sphear, 30 deg, 85mph");
title("Cl Sphear Exp 1-6")

% Cd and Cl for Inverted

figure(3)
tiledlayout(1,2)
nexttile
semilogy(1:100,Cd_InvertedExp6,linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp5,linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp4,linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp3,linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp2,linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp1,linewidth=2)
xlabel('Samples');
ylabel('Drag Coef.');
legend("Inverted, 0 deg, 50mph","Inverted, 15 deg, 50mph","Inverted, 15 deg, 50mph","Inverted, 0 deg, 85mph","Inverted, 15 deg, 85mph","Inverted, 30 deg, 85mph");
title("CD Inverted Exp 1-6")
nexttile
semilogy(1:100,abs(Cl_InvertedExp6),linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp5),linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp4),linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp3),linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp2),linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp1),linewidth=2)
xlabel('Samples');
ylabel('Lift Coef.');
legend("Inverted, 0 deg, 50mph","Inverted, 15 deg, 50mph","Inverted, 15 deg, 50mph","Inverted, 0 deg, 85mph","Inverted, 15 deg, 85mph","Inverted, 30 deg, 85mph");
title("Cl Inverted Exp 1-6")

% Cd and Cl for Plate
figure(4)
tiledlayout(1,2)
nexttile
semilogy(1:100,Cd_DiskExp6,linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp5,linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp4,linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp3,linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp2,linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp1,linewidth=2)
xlabel('Samples');
ylabel('Drag Coef.');
legend("Plate, 0 deg, 50mph","Plate, 15 deg, 50mph","Plate, 15 deg, 50mph","Plate, 0 deg, 85mph","Plate, 15 deg, 85mph","Plate, 30 deg, 85mph");
title("CD Plate Exp 1-6")
nexttile
semilogy(1:100,abs(Cl_DiskExp6),linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp5),linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp4),linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp3),linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp2),linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp1),linewidth=2)
xlabel('Samples');
ylabel('Lift Coef.');
legend("Plate, 0 deg, 50mph","Plate, 15 deg, 50mph","Plate, 15 deg, 50mph","Plate, 0 deg, 85mph","Plate, 15 deg, 85mph","Plate, 30 deg, 85mph");
title("Cl Plate Exp 1-6")

%% Comparing objects

figure(5)
tiledlayout(1,2)
nexttile
semilogy(1:100,Cd_MissleExp1,'red',linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp2,'red',linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp3,'red',linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp4,'red',linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp5,'red',linewidth=2)
hold on
semilogy(1:100,Cd_MissleExp6,'red',linewidth=2)

hold on
semilogy(1:100,Cd_SphearExp6,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp5,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp4,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp3,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp2,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp1,'blue',linewidth=2)

hold on
semilogy(1:100,Cd_InvertedExp6,'Green',linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp5,'Green',linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp4,'Green',linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp3,'Green',linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp2,'Green',linewidth=2)
hold on
semilogy(1:100,Cd_InvertedExp1,'Green',linewidth=2)

hold on
semilogy(1:100,Cd_DiskExp6,'black',linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp5,'black',linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp4,'black',linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp3,'black',linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp2,'black',linewidth=2)
hold on
semilogy(1:100,Cd_DiskExp1,'black',linewidth=2)
xlabel('Samples');
ylabel('Drag Coef.');
title("Red = missle, blue = Sphear, green = Inverted, Black = Disk")

nexttile

semilogy(1:100,abs(Cl_SphearExp6),'red',linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp5),'red',linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp4),'red',linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp3),'red',linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp2),'red',linewidth=2)
hold on
semilogy(1:100,abs(Cl_SphearExp1),'red',linewidth=2)
hold on

semilogy(1:100,Cd_SphearExp6,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp5,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp4,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp3,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp2,'blue',linewidth=2)
hold on
semilogy(1:100,Cd_SphearExp1,'blue',linewidth=2)
hold on

semilogy(1:100,abs(Cl_InvertedExp6),'green',linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp5),'green',linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp4),'green',linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp3),'green',linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp2),'green',linewidth=2)
hold on
semilogy(1:100,abs(Cl_InvertedExp1),'green',linewidth=2)
hold on

semilogy(1:100,abs(Cl_DiskExp6),'black',linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp5),'black',linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp4),'black',linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp3),'black',linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp2),'black',linewidth=2)
hold on
semilogy(1:100,abs(Cl_DiskExp1),'black',linewidth=2)
hold on

xlabel('Samples');
ylabel('Lift Coef.');
title("Red = missle, blue = Sphear, green = Inverted, Black = Disk")


%% Velcocity vs normal force

figure(6)
tiledlayout(2,2)
nexttile
MissleExp = [MissleExp1; MissleExp2 ;MissleExp3 ;MissleExp4 ;MissleExp5 ;MissleExp6];

plot(MissleExp(:,1),MissleExp(:,8),"black",LineWidth= 2)
hold on
plot(MissleExp1(:,1),MissleExp1(:,8),LineWidth= 2)
hold on
plot(MissleExp2(:,1),MissleExp2(:,8),LineWidth= 2)
hold on
plot(MissleExp3(:,1),MissleExp3(:,8),LineWidth= 2)
hold on
plot(MissleExp4(:,1),MissleExp4(:,8),LineWidth= 2)
hold on
plot(MissleExp5(:,1),MissleExp5(:,8),LineWidth= 2)
hold on
plot(MissleExp6(:,1),MissleExp6(:,8),LineWidth= 2)
hold on
legend("Trail","Missle, deg = 0, v = 50","Missle, deg = 15, v = 50", "Missle, deg = 30, v = 50","Missle, deg = 0, v = 85","Missle, deg = 15, v = 85", "Missle, deg = 30, v = 85")
xlabel("Velocity")
ylabel("Drag")
nexttile

SphearExp = [SphearExp1; SphearExp2 ;SphearExp3 ;SphearExp4 ;SphearExp5 ;SphearExp6];

plot(SphearExp(:,1),SphearExp(:,8),"black",LineWidth= 2)
hold on
plot(SphearExp1(:,1),SphearExp1(:,8),LineWidth= 2)
hold on
plot(SphearExp2(:,1),SphearExp2(:,8),LineWidth= 2)
hold on
plot(SphearExp3(:,1),SphearExp3(:,8),LineWidth= 2)
hold on
plot(SphearExp4(:,1),SphearExp4(:,8),LineWidth= 2)
hold on
plot(SphearExp5(:,1),SphearExp5(:,8),LineWidth= 2)
hold on
plot(SphearExp6(:,1),SphearExp6(:,8),LineWidth= 2)
hold on
legend("Trail","Sphear, deg = 0, v = 50","Sphear, deg = 15, v = 50", "Sphear, deg = 30, v = 50","Sphear, deg = 0, v = 85","Sphear, deg = 15, v = 85", "Sphear, deg = 30, v = 85")
xlabel("Velocity")
ylabel("Drag")
nexttile

InvertedExp = [InvertedExp1; InvertedExp2 ;InvertedExp3 ;InvertedExp4 ;InvertedExp5 ;InvertedExp6];

plot(InvertedExp(:,1),InvertedExp(:,8),"black",LineWidth= 2)
hold on
plot(InvertedExp1(:,1),InvertedExp1(:,8),LineWidth= 2)
hold on
plot(InvertedExp2(:,1),InvertedExp2(:,8),LineWidth= 2)
hold on
plot(InvertedExp3(:,1),InvertedExp3(:,8),LineWidth= 2)
hold on
plot(InvertedExp4(:,1),InvertedExp4(:,8),LineWidth= 2)
hold on
plot(InvertedExp5(:,1),InvertedExp5(:,8),LineWidth= 2)
hold on
plot(InvertedExp6(:,1),InvertedExp6(:,8),LineWidth= 2)
hold on
legend("Trail","Inverted, deg = 0, v = 50","Inverted, deg = 15, v = 50", "Inverted, deg = 30, v = 50","Inverted, deg = 0, v = 85","Inverted, deg = 15, v = 85", "Inverted, deg = 30, v = 85")
nexttile
xlabel("Velocity")
ylabel("Drag")
DiskExp = [DiskExp1; DiskExp2 ;DiskExp3 ;DiskExp4 ;DiskExp5 ;DiskExp6];

plot(DiskExp(:,1),DiskExp(:,8),"black",LineWidth= 2)
hold on
plot(DiskExp1(:,1),DiskExp1(:,8),LineWidth= 2)
hold on
plot(DiskExp2(:,1),DiskExp2(:,8),LineWidth= 2)
hold on
plot(DiskExp3(:,1),DiskExp3(:,8),LineWidth= 2)
hold on
plot(DiskExp4(:,1),DiskExp4(:,8),LineWidth= 2)
hold on
plot(DiskExp5(:,1),DiskExp5(:,8),LineWidth= 2)
hold on
plot(DiskExp6(:,1),DiskExp6(:,8),LineWidth= 2)
hold on
legend("Trail","Disk, deg = 0, v = 50","Disk, deg = 15, v = 50", "Disk, deg = 30, v = 50","Disk, deg = 0, v = 85","Disk, deg = 15, v = 85", "Disk, deg = 30, v = 85")
xlabel("Velocity")
ylabel("Drag")