clc
close all
clear
%%

syms s m1 m2 c1 c2 k1 k2
TF = compute_transfer_function(s, m1, m2, c1, c2, k1, k2);
pretty(TF)  

%% Tranfer function 


k1 = 1;
k2 = 1;
c1 = 1;
c2 = 1;
m1 = 1;
m2 = 1;


G_1 = (k2 + c2*s + m1*s^2 + m2*s^2)/(k1*k2 + c1*m1*s^3 + c1*m2*s^3 + c2*m1*s^3 + k1*m1*s^2 + k1*m2*s^2 + k2*m1*s^2 + m1*m2*s^4 + c1*k2*s + c2*k1*s + c1*c2*s^2);
 
