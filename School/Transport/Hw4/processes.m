clc
clear

Po = 101.325;
To = 40;%Celsius
RH = 53;%Percent
Psat = 7.385;
flow = 3.5;

Pv = Psat*(RH/100);
Pa = Po-Pv;
omega = 0.622 * Pv/(Po-Pv);
h = 1.005*To + omega*(2500 + 1.9*To);
v = (To+273)*(1+omega)/((Pa*1000)/287+(Pv*1000)/462);

% T2 = 34;
% h2 = 1.005*T2 + omega*(2500 + 1.9*T2);
% dh = h2-h;

% RH2 = Pv/Psat2*100;

T2 = 15;
Psat2 = 1.706;
Pv2 = Psat2;
omega2 = 0.622 * Pv2/(Po-Pv2);
h2 = 1.005*T2 + omega2*(2500 + 1.9*T2);
dh = (h2-h)*3.5;

cond = (omega - omega2)*3.5;
