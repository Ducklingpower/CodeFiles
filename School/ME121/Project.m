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
eq2 = X2 == (X1*(s*c1 + k1) + Y*(s*c2+k2)) / (s^2*m2 + s*(c2 + c1) + (k2 + k1));
[solX1, solX2] = solve([eq1, eq2], [X1, X2]);

% Compute (X1 - X2) / Y
G2 = simplify((solX1 - solX2) / Y);
pretty(G2)


%% symbolic to anyliticle tf

% Sub in params
G1_numeric = vpa(subs(G1, {m1, m2, c1, c2, k1, k2}, {2500, 320, 350, 15000, 80000, 500000}));
G2_numeric = vpa(subs(G2, {m1, m2, c1, c2, k1, k2}, {2500, 320, 350, 15000, 80000, 500000}));
[numG1, denG1] = numden(G1_numeric);
[numG2, denG2] = numden(G2_numeric);

% sym to poly
numG1_coeffs = double(sym2poly(expand(numG1)));
denG1_coeffs = double(sym2poly(expand(denG1)));
numG2_coeffs = double(sym2poly(expand(numG2)));
denG2_coeffs = double(sym2poly(expand(denG2)));

G1_tf = tf(numG1_coeffs, denG1_coeffs);
G2_tf = tf(numG2_coeffs, denG2_coeffs);



%% week 3 step stability and input respones


poles_G1 = pole(G1_tf);
poles_G2 = pole(G2_tf);

% Stability check
if all(real(poles_G1) < 0)
    disp('G1(s) is stable: All poles have negative real parts.');
else
    disp('G1(s) is unstable: Some poles have positive or zero real parts.');
end

if all(real(poles_G2) < 0)
    disp('G2(s) is stable: All poles have negative real parts.');
else
    disp('G2(s) is unstable: Some poles have positive or zero real parts.');
end


figure;
step(G1_tf)
legend("G_1(s) respones")
hold off

figure;
step(G2_tf)
legend("G_2(s) respones")
hold off

%% plotting week 5 

figure;
bode(G1_tf);
title('Bode Plot of G1(s) (Force to Output)');

figure;
bode(G2_tf);
title('Bode Plot of G2(s) (Displacement to Output)');


%% week 6 Plotting Niquiest 

figure;
nyquist(G1_tf);
title('Nyquist Diagram of G1(s) (Input to Output)');

figure;
nyquist(G2_tf);
title('Nyquist Diagram of G2(s) (Noise to Output)');


%% Week 7 plot root locus

figure;
rlocus(G1_tf);
title('Root Locus of G1(s) (Input to Output)');
xlabel('Real Axis');
ylabel('Imaginary Axis');
grid on;

figure;
rlocus(G2_tf);
title('Root Locus of G2(s) (Input to Output)');
xlabel('Real Axis');
ylabel('Imaginary Axis');
grid on;
D
%% week 9 siso

sisotool(G1_tf,1);

%%
% k1 = 80000;
% k2 = 500000;
% c1 = 350;
% c2 = 15000;
% m1 = 2500;
% m2 = 320;
% 
% tmax = 10;
% output = sim('week3.slx',[0 tmax]);
% Respones = output.Respone.data;
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
