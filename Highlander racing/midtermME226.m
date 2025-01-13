clc
clear
close all
%% Q1
% A)
mu = 0.4;
w  = 40/1000;
a  = 125/1000;
r  = 300/2000;
F  = 4000;
c  = 2*a*cos(30*(pi/180));
radt_f = 120*(pi/180);
radt_i = 0;
alpha = (cos(radt_f)*(a*cos(radt_f)-2*r))/(2) - (cos(radt_i)*(a*cos(radt_i)-2*r))/(2);
beta  = (0.5*radt_f-sin(2*radt_f)/4) - (0.5*radt_i-sin(2*radt_i)/4);
mf = mu*w*r*alpha;
mn = w*r*a*beta;
p_maxCW  = (F*c)/(mn-mf)
p_maxCCW = (F*c)/(mn+mf)
% B)
torque_r = p_maxCW*mu*r^2*w*(cos(radt_i)-cos(radt_f))
torque_l = p_maxCCW*mu*r^2*w*(cos(radt_i)-cos(radt_f))
torque_net = torque_r +torque_l
% C)
%right shoe cw rotation
phi = (p_maxCW*r*w)/(1);
c1  = 0.5*sin(radt_f)^2 - 0.5*sin(radt_i)^2;
c2  = -(sin(2*radt_f)-2*radt_f)/(4) + (sin(2*radt_i)-2*radt_i)/(4);
Nx_r = phi*c1-phi*c2*mu-F*sin(30*(pi/180))
Ny_r = phi*c1*mu+phi*c2-F*cos(30*(pi/180))
%left shoe ccw rotation
phi = (p_maxCCW*r*w)/(1);
c1  = 0.5*sin(radt_f)^2 - 0.5*sin(radt_i)^2;
c2  = -(sin(2*radt_f)-2*radt_f)/(4) + (sin(2*radt_i)-2*radt_i)/(4);
Nx_l = phi*c1+phi*c2*mu-F*sin(30*(pi/180))
Ny_l = -phi*c1*mu+phi*c2-F*cos(30*(pi/180))
