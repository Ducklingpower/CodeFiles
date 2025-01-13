clc
close all
clear
%%
data     = readtable("DATA.xlsx");

Brass    = data(:,2:4);
Brass    = table2array(Brass);
Aluminum = data(:,5:7);
Aluminum = table2array(Aluminum);
Steel    = data(:,8:10);
Steel    = table2array(Steel);
Plastic  = data(:,11:13);
Plastic  = table2array(Plastic);

A = [0.00314*0.006 0.00314*0.00606 0.00327*0.00585 0.0033*0.00595];


%% Plots

figure(Name = "Brass")
plot(Brass(:,2)/0.11507,Brass(:,3)/A(1),Linewidth = 3)
grid on
hold on
plot(11.48,341072,"*",LineWidth=3)
hold on
plot(84.89,417436,"*",LineWidth=3)
hold on
plot(111,299777,"*",LineWidth=3)
hold on
plot([2.69 9.42],[13508 298907],LineWidth=3)
m = (8375.34-863.667)/(1.12-0.3082);
m = m/100;
xlabel("Strain")
ylabel("stress kPa")
legend("Brass","yeild strength = 341 MPa","Tensile strength = 417.436 MPa","Breaking stress = 299.77 MPa","Elastic = "+m+" kN/mm^2")
title("Brass stress strain")
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(Name = "Aluminum")
plot(Aluminum(:,2)/0.11525,Aluminum(:,3)/A(2),Linewidth = 3)
grid on
hold on
plot(8.50,287066,"*",LineWidth=3)
hold on
plot(30.7,324636,"*",LineWidth=3);
hold on
plot(41.02,276555,"*",LineWidth=3);
hold on
plot([1.87 6.57],[7488.81 245980],LineWidth=3);
m = (6827-309.27)/(0.7632-0.2123);
m = m/100;
xlabel("Strain")
ylabel("stress kPa")
legend("Aluminum", "yeild strength = 287.066 MPa","Tensile strength = 324636  MPa","Breaking stress = 276.555 MPa","Elastic = "+m+" kN/mm^2")
title("Aluminum stress strain")

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(Name = "Steel")
plot(Steel(:,2)/0.11525,Steel(:,3)/A(3),Linewidth = 3)
grid on
hold on
plot(6.844,289453,"*",LineWidth=3)
hold on
plot(30.32,311676,"*",LineWidth=3)
hold on
plot(76.22,181097,"*",LineWidth=3)
hold on
plot([0.0429 5.28],[3648 265308],LineWidth=3)
m = (-899.53+ 7629.87)/(-0.0429+ 0.6157);
m = m/100;
xlabel("Strain")
ylabel("stress kPa")
legend("Steel","Yeild strength = 289.45 Mpa","Tensile strength = 311.676 MPa","Breaking stress = 76.168 MPa","Elastic = "+m+" kN/mm^2")
title("Steel stress strain")

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(Name = "Plastic")
plot(Plastic(:,2)/0.11525,Plastic(:,3)/A(4),Linewidth = 3)
grid on
hold on
plot(12.39,5632230,"*",LineWidth=3)
hold on
plot(73.105,7021350,"*",LineWidth=3)
hold on
plot(73.105,7021350,"*",LineWidth=3)
hold on

plot([2.07 8.46],[417494 4523580],LineWidth=3)
m = (-11359.7+ 130861)/(-0.2288+0.9989);
m = m/100;

xlabel("Strain")
ylabel("stress kPa")
legend("Plastic","Yield strength = 5632.23 MPa","Tensile strength = 7021.350 MPa","Breaking stress = 7021.350 MPa","Elastic = "+m+" kN/mm^2")
title("Plastic stress strain")

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(Name = "All specimen")
plot(Brass(:,2),Brass(:,3)/A(1),Linewidth = 3)
hold on
plot(Aluminum(:,2),Aluminum(:,3)/A(2),Linewidth = 3)
hold on
plot(Steel(:,2),Steel(:,3)/A(3),Linewidth = 3)
hold on

grid on
xlabel("Strain")
ylabel("stress kPa")
title("All specimen stress strain")
legend("Brass","Aluminum","Steel")











