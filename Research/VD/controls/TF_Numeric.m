clear; clc; close all;
%%
n1 = 1.059;
n0 = 0.7502;
d1 = 0.7082;
d0 = 1;
dt = 0.01;
T_end = 5;

t = (0:dt:T_end)'; 
u = ones(size(t));% step 

a = 2/dt;
denom = d1*a + d0;

b0 = (n1*a + n0)/denom;
b1 = (n0 - n1*a)/denom;
a1 = (d1*a - d0)/denom;

Cs = tf([n1 n0],[d1 d0]);
Cz = c2d(Cs,dt,'tustin');
y_matlab = lsim(Cz,u,t);

y_numeric = zeros(size(t));
u_prev = 0;
y_prev = 0;

for k = 1:length(t)
    y_numeric(k) = a1*y_prev + b0*u(k) + b1*u_prev;
    u_prev = u(k);
    y_prev = y_numeric(k);
end

figure;
plot(t,y_matlab,'LineWidth',2); hold on;
plot(t,y_numeric,'--','LineWidth',2);
grid on;
xlabel('Time [s]');
ylabel('Output');
legend('MATLAB TF','Numerical TF','Location','best');
title('Transfer Function Step Response Comparison');