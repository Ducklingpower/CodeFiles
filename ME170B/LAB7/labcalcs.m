clc
close all
clear
%% Calcs
m = 0.7*1;
cp = 4182;
T0 = 295.95;
T1 = 306.35;
T2 = 286.35;
T3 = 322.15;
T4 = 310.65;
T5 = 301.65;
T6 = 276.45;
T7 = 281.65;

PH = 10 *10^5;
PL = 2.4*10^5;



Cond_power = m*cp*(T1-T0); %J/s
Comp_power = m*cp*(T3-T2); %J/s
Evap_power = m*cp*(T3-T4); %J/s

COP = Comp_power/Cond_power;
EF  = Evap_power/Comp_power;


IdealCOP = (T2-T0)/(2*T0-T1-T2);

%% plots

T = [T3 T4 T6 T7];
S = [0.939 0.3772 0.3302 0.914775];

title("TS diagram K")
%plot(S,T);
hold on
plot(S(1),T(1),"*",linewidth = 3);
hold on 
plot(S(2),T(2),"*",linewidth = 3);
hold on
plot(S(3),T(3),"*",linewidth = 3);
hold on
plot(S(4),T(4),"*",linewidth = 3);
hold on
plot(0.9043,39.39+273,"o",linewidth = 3)
xlabel("Entropy kj/kg k")
ylabel("Temp k")
legend("1","2","3","4","sat(g)");

grid on




