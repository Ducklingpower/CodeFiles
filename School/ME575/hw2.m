clc
clear 
close all
%% creating tranfer functs Problem 2

% 1)
TF1 = tf(2,[1 4 4]);

%2)
TF2 = tf([-1 10],[1 4 4]);

%3)
TF3 = tf([-1 0.2],[1 4 4]);

%4)
TF4 = tf(2,[1 0.2 4]);

%% plotting the step respons

figure
step(TF1,TF2,TF3,TF4)
leg1 = legend('$\frac{2}{s^2+4s+4}$','$\frac{-s+10}{s^2+4s+4}$','$\frac{-1+0.2}{s^2+4s+4}$', '$\frac{2}{s^2+0.2s+4}$');
set(leg1,'Interpreter','latex');
fontsize(leg1,14,'points')
grid on  
xlim([0 40])


S1 = stepinfo(TF1)              % default: 2% settling
S2 = stepinfo(TF2) 
S3 = stepinfo(TF3)
S4 = stepinfo(TF4)



%% Plotting the step respons problem 3


TF5 = tf([-6 8],[1 9 8]);
figure
step(TF5)
grid on
leg2 = legend('$\frac{-6s+8}{(s+1)(s+8)}$');
set(leg2,'Interpreter','latex')
fontsize(leg2,14,'points')


S5 = stepinfo(TF5)
