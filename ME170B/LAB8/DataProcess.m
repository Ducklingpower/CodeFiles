clc
close all
clear
%%

Data = readtable("F24Group5Data.xlsx");
U    = Data(:,1);
V    = Data(:,2);
W    = Data(:,3);
T    = Data(:,4);

U = table2array(U);
V = table2array(V);
W = table2array(W);
T = table2array(T);


t = 1:505;
t1 = 1:168;
t2 = 167:167*2;
t3 = 167*2:167*3;

x1 = linspace(1,300,167);
%%
figure(name="U avg with no heat (5 min)")
title("U avg with no heat (5 min)")
plot(x1,U(1:167),LineWidth=3);
ylim([-3  3])
grid on
title("U avg with no heat (5 min)")
xlabel("time (s)")
ylabel("U averge")

figure(name="V avg with no heat (5 min)")
title("V avg with no heat (5 min)")
plot(x1,V(1:167),LineWidth=3);
ylim([-3  3])
grid on
title("V avg with no heat (5 min)")
xlabel("time (s)")
ylabel("V averge")

figure(name="W avg with no heat (5 min)")
plot(x1,W(1:167),LineWidth=3);
ylim([-3  3])
grid on
title("W avg with no heat (5 min)")
xlabel("time (s)")
ylabel("W averge")


%%
figure(name="U avg with heat 1 (5 min)")
plot(x1,U(168:167*2),LineWidth=3);
ylim([-3  3])
grid on
title("U avg with heat 1 (5 min)")
xlabel("time (s)")
ylabel("U averge")

figure(name="V avg with heat 1 (5 min)")
plot(x1,V(168:167*2),LineWidth=3);
ylim([-3  3])
grid on
title("V avg with heat 1 (5 min)")
xlabel("time (s)")
ylabel("V averge")

figure(name="W avg with heat 1 (5 min)")
plot(x1,W(168:167*2),LineWidth=3);
ylim([-3  3])
grid on
title("W avg with heat 1 (5 min)")
xlabel("time (s)")
ylabel("W averge")


%%

figure(name="U avg with heat 2 (5 min)")
plot(x1,U(167*2:167*3-1),LineWidth=3);
ylim([-3  3])
grid on
title("U avg with heat 2 (5 min)")
xlabel("time (s)")
ylabel("U averge")

figure(name="V avg with heat 2 (5 min)")
plot(x1,V(167*2:167*3-1),LineWidth=3);
ylim([-3  3])
grid on
title("V avg with heat 2 (5 min)")
xlabel("time (s)")
ylabel("V averge")

figure(name="W avg with heat 2 (5 min)")
plot(x1,W(167*2:167*3-1),LineWidth=3);
ylim([-3  3])
grid on
title("W avg with heat 2 (5 min)")
xlabel("time (s)")
ylabel("W averge")


%%

figure(name= "heat")
plot(t,T,LineWidth=3);
hold on




