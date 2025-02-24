clc
clear
Po = 101.325;

m1 = 3;
To = 15;%Celsius
RH = 56;%Percent
Psat = 1.706;
Pv = Psat*(RH/100);
Pa = Po-Pv;
omega = 0.622 * Pv/(Po-Pv);
h = 1.005*To + omega*(2500 + 1.9*To);
water = m1*omega;
% v = (To+273)*(1+omega)/((Pa*1000)/287+(Pv*1000)/462);

m2 = 3;
T2 = 65;
RH2 = 35;
Psat2 = 25.04;
Pv2 = Psat2*(RH2/100);
omega2 = 0.622 * Pv2/(Po-Pv2);
h2 = 1.005*T2 + omega2*(2500 + 1.9*T2);
water2 = m2*omega2;

m3 = m1 + m2;
omega3 = (water + water2)/m3;
Pv3 = (omega3 * Po)/(0.622+omega3);

T3 = ((h*m1 + h2*m2)/m3-omega3*2500)/(1.005 + 1.9*omega3);
% Psat3 =7.862;
% RH3 = Pv3/Psat3*100;
