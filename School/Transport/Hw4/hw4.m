clc

w = 6.3;
T = 24;

w = w/1000;
pv = (101.325)/((0.622/w) + 1) %kpa

hgT = 2545.4;
h = 1.005*T+w*hgT

psat = 0.02985;
RH = (pv/100)/psat
