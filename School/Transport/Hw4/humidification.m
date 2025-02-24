clc
clear
Po = 101.325;

To = 36;%Celsius
RH = 17;%Percent
Psat = 5.948;

Pv = Psat*(RH/100);
Pa = Po-Pv;
omega = 0.622 * Pv/(Po-Pv);
h = 1.005*To + omega*(2618);
v = (To+273)*(1+omega)/((Pa*1000)/287+(Pv*1000)/462);


%%
Tf = 14;
hs = 4.1*Tf;

T2 = 19;
Psat2 = 2.198;
hvT2 = 2536;
omega2 = (h -1.005*T2-omega*hs)/(hvT2-hs);

inj = omega2-omega;
Pv2 = (omega2 * Po)/(0.622+omega2);

RH2 = Pv2/Psat2*100;
%%
vflow = 1;
T2 = 14;
RH2 = 100;
Psat2 = 1.599;

Pv2 = Psat2*(RH2/100);
omega2 = 0.622 * Pv2/(Po-Pv2);
h2 = 1.005*T2 + omega2*(2500 + 1.9*T2);

Q = vflow*((h-h2)+(omega-omega2)*4.1*T2);
inj = (omega - omega2)*vflow;
dh = h2 - h;

hs = dh/(omega2-omega);

Ts = (hs-2500)/1.9;



