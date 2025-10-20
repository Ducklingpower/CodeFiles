
close all
clear
%% part 1 solving for coef for controller 

f = @(x) [9-85.656+x(1)-x(4);
        17-2868.48+8*x(4)-x(4)*x(5)-(x(4)*x(6))-x(3);
        81-46854.4+8*x(3)-x(4)*x(5)*x(6)-x(3)*x(5)-x(3)*x(6)-x(2);
        72-379392+8*x(4)*x(5)+8*x(4)*x(6)+8*x(3)*x(5)*x(6)+8*x(2)-x(3)*x(5)*x(6)-x(2)*x(5)-x(2)*x(6);
        -1416960+72*x(1)-x(2)*x(5)*x(6)+8*x(2)*x(5)+8*x(2)*x(6)+8*x(3)*x(5)*x(6);
        -2560000+8*x(2)*x(5)*x(6)];

x0 = [900;12474;2759;831;3.3;7.78];
x0=[950;13000;2600;820;3;8]

[x,fval] = fsolve(f,x0)



% plottig sys
x = [907.43515373, 12474.2338439997, 2758.7902597922, ...
     830.7791537291, 3.2971949629, 7.7802126878];

s = tf('s')
controller = ((x(4)*s^2 + x(3)*s + x(2)) * (s+x(5))*(s+x(6))) / (s*(s^2 + 9)*(s+x(1)));
plant = (-s+8)/((s+1)*(s+8));


G = plant;
C = controller;

% Loop functions
L = C*G;
S = feedback(1, L);    % 1/(1+L)
T = feedback(L, 1);    % L/(1+L)

% step input
Tf = 4;  
dt = 1e-3; 
t  = 0:dt:Tf;

rA = 1;
r  = rA*ones(size(t));

% Disturbance: sine A*sin(w t + phi)

d   = sin(3*t);

Gd = G*S;                  % transfer from d_in to y



y_ref = lsim(T,  r, t); % ref
y_dis = lsim(Gd, d, t); % disterbance

y = y_ref + y_dis;

% Plot
figure; plot(t, y_ref, '*')
hold on
plot(t, y,'.'); 
hold on
plot(t,d,'*')
hold on
plot(t,r,'--')
grid on;
legend('no distrerbance', 'Disturbance ', 'raw disterbance','ref input');
xlabel('Time (s)'); ylabel('Output');
title('Step reference + sinusoidal disturbance');

% prof of roots closed loop tf proof
%%
P = pole(T);
Z = zero(T);


figure
plot(real(P),imag(P),'*',LineWidth=2)
hold on
plot(real(Z),imag(Z),'*',LineWidth=2)
grid on

xlabel('Real-axis')
ylabel('Imaginary-axis')

legend("CL: Poles","CL: Zeros")











%% part 2 from sol


clc;clear all; close all;s = tf('s');
% HW5 P2
% Nominal plant
tau0 = 1;
P0 = tf(1, [tau0, 1]);      % 1/(tau0 s + 1)
P0.InputName  = 'qt';
P0.OutputName = 'y';

% Time delay block (unit gain with input delay)
Td   = 2;
Delay = tf(1, 1, 'inputDelay', Td);
Delay.InputName  = 'qh';
Delay.OutputName = 'qhT';

% PI controller
Kp = 118; Ki = 10000;
C  = tf([Kp, Ki], [1, 0]);  % Kp + Ki/s
C.InputName  = 'ez';
C.OutputName = 'qh';

% Predicted plant with delay (for y_hat)
PPd = tf(1, [tau0, 1], 'inputDelay', Td);
PPd.InputName  = 'qh';
PPd.OutputName = 'y_hat';

% Predicted plant without delay (for y0_hat)
PP0 = tf(1, [tau0, 1]);
PP0.InputName  = 'qh';
PP0.OutputName = 'y0_hat';

% Sum blocks (NOTE: use ASCII '-' everywhere)
Sum1 = sumblk('qt = qhT + di');             % plant input: delayed control + disturbance
Sum2 = sumblk('dl_hat = y - y_hat');        % delay-line error
Sum3 = sumblk('z = dl_hat + y0_hat');       % internal model sum
Sum4 = sumblk('ez = r - z');                % controller error

% Interconnect
CL = connect(P0, Delay, C, PPd, PP0, Sum1, Sum2, Sum3, Sum4, ...
             {'r','di'}, {'y','y_hat','y0_hat','dl_hat','z'});

% --- Plots ---
% From r to y
figure
step(CL(1,1)); grid on; title('r \rightarrow y');
disp(stepinfo(CL(1,1)))

% From di to y
figure
step(CL(1,2)); grid on; 

% Bode of r->y closed-loop
figure
bode(CL(1,1)); grid on; title('Bode: r \rightarrow y');

% --- New time-delay block (only this delay changes) ---
Td2 = 2.02;
Delay2 = tf(1, 1, 'inputDelay', Td2);
Delay2.InputName  = 'qh';
Delay2.OutputName = 'qhT';

% --- Sum blocks (use ASCII '-' !) ---
Sum1 = sumblk('qt = qhT + di');
Sum2 = sumblk('dl_hat = y - y_hat');
Sum3 = sumblk('z = dl_hat + y0_hat');
Sum4 = sumblk('ez = r - z');

% --- Interconnect for the perturbed delay model ---
CL2 = connect(P0, Delay2, C, PPd, PP0, ...
              Sum1, Sum2, Sum3, Sum4, ...
              {'r','di'}, ...
              {'y','y_hat','y0_hat','dl_hat','z'});

% --- Plots: compare baseline CL (Td = 2) vs new CL2 (Td = 2.02) ---
figure
step(CL(1,1), CL2(1,1));
grid on; legend('T_d = 2','T_d = 2.02'); title('r \rightarrow y');

figure
step(CL(1,2), CL2(1,2));
grid on; legend('T_d = 2','T_d = 2.02'); title('d_i \rightarrow y');

figure
step(CL(4,2), CL2(4,2));
grid on; legend('T_d = 2','T_d = 2.02'); title('d_i \rightarrow dl\_hat');


%%


clc;clear all; close all;s = tf('s');
% HW5 P2
% Nominal plant
tau0 = 1;
P0 = tf([1 3], [1 6 5]);      % 1/(tau0 s + 1)
P0.InputName  = 'qt';
P0.OutputName = 'y';

% Time delay block (unit gain with input delay)
Td   = 2;
Delay = tf(1, 1, 'inputDelay', Td);
Delay.InputName  = 'qh';
Delay.OutputName = 'qhT';

% PI controller
Kp = 118; Ki = 10000;
C  = tf([3.242, 25.215, 45], [1, 3, 0]); 
C.InputName  = 'ez';
C.OutputName = 'qh';

% Predicted plant with delay (for y_hat)
PPd = tf([1 3], [1 6 5], 'inputDelay', Td);
PPd.InputName  = 'qh';
PPd.OutputName = 'y_hat';

% Predicted plant without delay (for y0_hat)
PP0 = tf([1 3], [1 6 5]);
PP0.InputName  = 'qh';
PP0.OutputName = 'y0_hat';

% Sum blocks (NOTE: use ASCII '-' everywhere)
Sum1 = sumblk('qt = qhT + di');             % plant input: delayed control + disturbance
Sum2 = sumblk('dl_hat = y - y_hat');        % delay-line error
Sum3 = sumblk('z = dl_hat + y0_hat');       % internal model sum
Sum4 = sumblk('ez = r - z');                % controller error

% Interconnect
CL = connect(P0, Delay, C, PPd, PP0, Sum1, Sum2, Sum3, Sum4, ...
             {'r','di'}, {'y','y_hat','y0_hat','dl_hat','z'});

% --- Plots ---
% From r to y
figure
step(CL(1,1)); grid on; title('r \rightarrow y');
disp(stepinfo(CL(1,1)))