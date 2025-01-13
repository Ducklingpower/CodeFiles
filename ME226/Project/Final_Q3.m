clc
clear 
close all


ms = 1085/2;    %kg
mu = 40;        %kg
ks = 10000;   
ku = 150000;
cs = 800;

M = [ms 0 ;
     0 mu];
K = [ks -ks;
    -ks ks+ku];
C = [cs -cs;
    -cs cs];


A1 = M^(-1)*K;
[EV,EVal] = eig(A1);
EVal  =(sqrt(EVal))/(2*pi);
mode = EV;



mode1 = mode;
resonant1 = diag(EVal);
figure(Name='Mode shapes')
tiledlayout(2,1)
nexttile
plot([0 1],mode(1,:))
title([EVal(1,1)] + "Hz")
grid on

nexttile
plot([0 1],mode(2,:))
title([EVal(2,2)] + "Hz")
grid on

