clc
close all
clear
%%

syms s m1 m2 c1 c2 k1 k2 X1 X2 F Y

%-------------- Equations for solviong G(s)_1 -----------------------------
eq1 = X1 == (X2*(s*c1 + k1) + F) / (s^2*m1 + s*c1 + k1);
eq2 = X2 == (X1*(s*c1 + k1) - F) / (s^2*m2 + s*(c2 + c1) + (k2 + k1));

[solX1, solX2] = solve([eq1, eq2], [X1, X2]);

% Compute (X1 - X2) / F
G1 = simplify((solX1 - solX2) / F);
pretty(G1)



%-------------Equations for solviong G(s)_2--------------------------------

eq1 = X1 == (X2*(s*c1 + k1)) / (s^2*m1 + s*c1 + k1);
eq2 = X2 == (X1*(s*c1 + k1) - Y*(s*c2+k2)) / (s^2*m2 + s*(c2 + c1) + (k2 + k1));

[solX1, solX2] = solve([eq1, eq2], [X1, X2]);

% Compute (X1 - X2) / Y
G2 = simplify((solX1 - solX2) / Y);
pretty(G2)

%% Tranfer function 
% 
% 
% k1 = 80000;
% k2 = 500000;
% c1 = 350;
% c2 = 150000;
% m1 = 2500;
% m2 = 320;
% 
% tmax = 10;
% output = sim('week3.slx',[0 tmax]);
% 
% Respones = output.Respone.data;
% %% plotting week 3
% 
% figure
% plot(0:0.001:tmax,Respones(:,2),Linewidth = 2)
% hold on
% grid on
% plot(0:0.001:tmax,Respones(:,3),Linewidth = 2)
% hold on
% plot(0:0.001:tmax,Respones(:,1),Linewidth = 2)
% title("G1 and G2 Respones to step input")
% xlabel("Time (s)")
% ylabel("G(s)*Step")
% legend("Step Input","G(2) Respones","G(1) Respoense")

%% plotting week 5 
% Substitute numerical values for all parameters
% Substitute numerical values into G1 and G2
G1_numeric = vpa(subs(G1, {m1, m2, c1, c2, k1, k2}, {2500, 320, 350, 15000, 80000, 500000}));
G2_numeric = vpa(subs(G2, {m1, m2, c1, c2, k1, k2}, {2500, 320, 350, 15000, 80000, 500000}));

% Extract numerator and denominator
[numG1, denG1] = numden(G1_numeric);
[numG2, denG2] = numden(G2_numeric);

% Convert symbolic expressions to polynomials in s and ensure numeric values
numG1_coeffs = double(sym2poly(expand(numG1)));
denG1_coeffs = double(sym2poly(expand(denG1)));

numG2_coeffs = double(sym2poly(expand(numG2)));
denG2_coeffs = double(sym2poly(expand(denG2)));

% Define transfer function objects
G1_tf = tf(numG1_coeffs, denG1_coeffs);
G2_tf = tf(numG2_coeffs, denG2_coeffs);

% Plot Bode diagrams
figure;
bode(G1_tf);
title('Bode Plot of G1(s) (Force to Output)');

figure;
bode(G2_tf);
title('Bode Plot of G2(s) (Displacement to Output)');

