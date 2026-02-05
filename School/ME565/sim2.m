clc
close all
clear
%% rinning quater car sim model

ks = 1000;
cs = 200;
ms = 100;

kt = 10000;
mu =10;

%% runningn sim 

tmax = 10;

sim("quater_car.slx",[0 tmax])


