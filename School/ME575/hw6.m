clc; clear; close all;
s = tf('s');

% Plant
P = (s + 3) / (s * (s - 2));

% --- Controller with internal model at omega=3 (s^2 + 9) ---
x4 = 12; x3 = 31; x2 = 98; x1 = 80; x0 = 32;
C = (x4*s^4 + x3*s^3 + x2*s^2 + x1*s + x0) / (s*(s^2 + 9)*(s + 3));

% Closed-loop and disturbance path
L = C*P;
T = feedback(L, 1);     % ref->output
S = 1/(1 + L);          % sensitivity
Yd = P*S;               % disturbance (before plant) -> output

% Check stability
disp('Closed-loop poles (with s^2+9):');
disp(pole(T));          % should all be at s = -2 (numerically equal to -2)

% Ramp disturbance
t = 0:0.01:20;
d_ramp = t;                             % ramp
y_ramp = lsim(T, d_ramp, t);

figure; plot(t, y_ramp); 
grid on;
hold on
plot(t,t)
xlabel('Time (s)'); ylabel('y(t)');
title('Output due to Ramp Disturbance (IM at \omega=3)');

% --- If your target sinusoid is sin(2t), switch to s^2 + 4: ---
C2 = (x4*s^4 + x3*s^3 + x2*s^2 + x1*s + x0) / (s*(s^2 + 9)*(s + 3));
L2 = C2*P; T2 = feedback(L2, 1); S2 = 1/(1 + L2); Yd2 = P*S2;

disp('Closed-loop poles (with s^2+4):');
disp(pole(T2));         % still stable (clustered at -2 by construction)

% Ramp disturbance with s^2+4 internal model
y_ramp2 = lsim(Yd2, d_ramp, t);
figure; plot(t, y_ramp2, 'LineWidth', 2); grid on;
xlabel('Time (s)'); ylabel('y(t)');
title('Output due to Ramp Disturbance (IM at \omega=2)');




%%
clear

s = tf('s');
P = (s + 1)/((s + 5)*(s + 3));
C_no_int = 1;          % Type 0
C_with_int = 1/s;      % Type 1 (adds integrator)

T0 = feedback(C_no_int*P,1);
T1 = feedback(C_with_int*P,1);

figure; step(T0, T1)
legend('Without integrator','With integrator');
grid on;
