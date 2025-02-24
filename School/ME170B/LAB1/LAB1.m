clc
clear 
close all
%%
% shape : Small brass donut 
T1_15 = [46;45;44.7;33;32.3;31;28;27.7;27.3];
T1_25 = [54.1;52.9;52.5;35;34.6;33.3;29.8;29.2;28.8];

% Shape: Large brass donut
T2_15 = [52.5;50.3;48.5;40.3;39.5;38.1;37.3;35.6;32.1];
T2_25 = [65.8;62.4;59.8;47.7;47.1;45.7;43.8;41.1;38.5];

% shape: Steel donut
T3_15 = [72;70;68.7;47.8;45.5;40.3;36.1;35.1;34.2];
T3_25 = [85.2;82.6;81.1;61.4;53.4;45.1;38.6;37.2;35.8];

% Shape: radial Heat

T4_30 = [33.7;29.2;26.3;24.7;23.3];
T4_40 = [39.6;33.2;29.3;26.8;24.7];



%% Theory

x = linspace(0,0.0762,50);
R = linspace(0.0127,0.0762,50);

t1_15 = (-(T1_15(4)-T1_15(6))/0.0762) * x + T1_15(4);
t2_15 = (-(T2_15(4)-T2_15(6))/0.0762) * x + T2_15(4);
t3_15 = (-(T3_15(4)-T3_15(6))/0.0762) * x + T3_15(4);
t4_30 = ((T4_30(1)-T4_30(5))/(log(0.0127/0.0762))) * log(R) + 5 %T4_30(5) * (((T4_30(1)-T4_30(5))*log(0.0127))/(log(0.0127/0.0762)));


t1_25 = (-(T1_25(4)-T1_25(6))/0.0762) * x + T1_25(4);
t2_25 = (-(T2_25(4)-T2_25(6))/0.0762) * x + T2_25(4);
t3_25 = (-(T3_25(4)-T3_25(6))/0.0762) * x + T3_25(4);
t4_40 = ((T4_40(1)-T4_40(5))/(log(0.0127/0.0762))) * log(R) %T4_40(5) * (((T4_40(1)-T4_40(5))*log(0.0127))/(log(0.0127/0.0762)));





%% Plots
figure
tiledlayout(1,2)
nexttile
d = linspace(0,0.0762,3);
plot(x,t1_15,LineWidth=2);
hold on
plot(d,T1_15(4:6),LineWidth=2)
hold on
plot(d,T1_15(4:6),"*",LineWidth=2);
xlabel("distance in meters");
ylabel("temp in C")
title('Heat = 15 Watts, Small brass donut')
legend("Theroeticle T(x)" , "Experimental Data" )
grid on
nexttile

d = linspace(0,0.0762,3);
plot(x,t1_25,LineWidth=2);
hold on
plot(d,T1_25(4:6),LineWidth=2)
hold on
plot(d,T1_25(4:6),"*",LineWidth=2);
xlabel("distance in meters");
ylabel("temp in C")
title('Heat = 25 Watts, Small brass donut')
legend("Theroeticle T(x)" , "Experimental Data" )
grid on
%--------------------------------------------------------------------------
figure
tiledlayout(1,2)
nexttile
d = linspace(0,0.0762,3);
plot(x,t2_15,LineWidth=2);
hold on
plot(d,T2_15(4:6),LineWidth=2)
hold on
plot(d,T2_15(4:6),"*",LineWidth=2);
xlabel("distance in meters");
ylabel("temp in C")
title('Heat = 15 Watts,Large brass donut')
legend("Theroeticle T(x)" , "Experimental Data" )
grid on
nexttile

d = linspace(0,0.0762,3);
plot(x,t2_25,LineWidth=2);
hold on
plot(d,T2_25(4:6),LineWidth=2)
hold on
plot(d,T2_25(4:6),"*",LineWidth=2);
xlabel("distance in meters");
ylabel("temp in C")
title('Heat = 25 Watts, Large brass donut')
legend("Theroeticle T(x)" , "Experimental Data" )
grid on

%--------------------------------------------------------------------------

figure
tiledlayout(1,2)
nexttile
d = linspace(0,0.0762,3);
plot(x,t3_15,LineWidth=2);
hold on
plot(d,T3_15(4:6),LineWidth=2)
hold on
plot(d,T3_15(4:6),"*",LineWidth=2);
xlabel("distance in meters");
ylabel("temp in C")
title('Heat = 15 Watts,Large Steel donut')
legend("Theroeticle T(x)" , "Experimental Data" )
grid on
nexttile

d = linspace(0,0.0762,3);
plot(x,t3_25,LineWidth=2);
hold on
plot(d,T3_25(4:6),LineWidth=2)
hold on
plot(d,T3_25(4:6),"*",LineWidth=2);
xlabel("distance in meters");
ylabel("temp in C")
title('Heat = 25 Watts, Large Steel donut')
legend("Theroeticle T(x)" , "Experimental Data" )
grid on

%--------------------------------------------------------------------------% Temp distrobution (T-t0) vs ln(r/r0) radial
 

figure
tiledlayout(1,2)
nexttile
r =linspace(0.0127,0.0762,5 );
plot(R,t4_30,LineWidth=2);
hold on
plot(r,T4_30(:),LineWidth=2)
hold on
plot(r,T4_30(:),"*",LineWidth=2);
xlabel("distance in meters");
ylabel("temp in C")
title('Heat = 30 Watts,steel plate')
legend("Theroeticle T(x)" , "Experimental Data" )
grid on

nexttile

r =linspace(0.0127,0.0762,5);
plot(R,t4_40,LineWidth=2);
hold on
plot(r,T4_40(:),LineWidth=2)
hold on
plot(r,T4_40(:),"*",LineWidth=2);
xlabel("distance in meters");
ylabel("temp in C")
title('Heat = 40 Watts, steel plate')
legend("Theroeticle T(x)" , "Experimental Data" )
grid on

%%
% Temp distrobution (T-t0) vs ln(r/r0) radial

TT0(1)  = T4_30(1) -  T4_30(2);
TT0(2)  = T4_30(1) -  T4_30(3);
TT0(3)  = T4_30(1) -  T4_30(4);
TT0(4)  = T4_30(1) -  T4_30(5);

TT1(1)  = T4_40(1) -  T4_40(2);
TT1(2)  = T4_40(1) -  T4_40(3);
TT1(3)  = T4_40(1) -  T4_40(4);
TT1(4)  = T4_40(1) -  T4_40(5);

rr(1) = abs(log(r(2) - r(1))); 
rr(2) = abs(log(r(3) - r(1))); 
rr(3) = abs(log(r(4) - r(1))); 
rr(4) = abs(log(r(5) - r(1))); 


figure
plot(TT0(:),rr(:),LineWidth=2);
hold on
plot(TT0(:),rr(:),"*",LineWidth=2);

plot(TT1(:),rr(:),LineWidth=2);
hold on
plot(TT1(:),rr(:),"*",LineWidth=2);
grid on
title("Differnce in temp in radial driection.")
xlabel("T-T0")
ylabel("ln(r/r0)")
legend("Heat = 30 watts", "Heat = 30, points", "Heat = 40 watts", "Heat = 40, points")

