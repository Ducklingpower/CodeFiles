clc 
close all
clear 
%% init

V = [0.0;30;60;90;120;150];
N_f = [1870; 1863.5; 1844.6; 1807.7; 1757.4; 1694.2];
N_r = [1125; 1123.9; 1120.4; 1114.5; 1107.7; 1093.5];
T_f = [0; 6.4; 26.4; 59.9; 105.8; 157.3];
T_r = [0;0;0;0;0;0];


ro = 0.00237;
A = 20;
L = 8;
a = 3.00508;
b = L-a;
weight = T_f(1,1)+T_r(1,1);

%% cal forces

F_d = T_f+T_r;
F_l = N_f+N_r-weight;
M_cg = 2.*T_f - 2.*T_r + + a.*N_f - b.*N_r;

figure;

tiledlayout(1,3);

nexttile;
plot(V(:,1),F_d(:,1), LineWidth=2)
grid on
xlabel("velocity")
ylabel("F_{drag}")

nexttile;
plot(V(:,1),F_l(:,1), LineWidth=2)
grid on
xlabel("velocity")
ylabel("F_{lift}")

nexttile;
plot(V(:,1),M_cg(:,1), LineWidth=2)
grid on
xlabel("velocity")
ylabel("M_{cg}")


A_v = [V(:,1).^2 V(:,1) ones(6,1)];
x_drag = (A_v'*A_v)^(-1)*A_v'*F_d(:,1);
x_lift = (A_v'*A_v)^(-1)*A_v'*F_l(:,1);
x_M_cg = (A_v'*A_v)^(-1)*A_v'*M_cg(:,1);


velocity = 0:1:250;

for i =1: length(velocity)
    F_d_fit(i) = x_drag(1).*velocity(i)^2 + x_drag(2).*velocity(i) + x_drag(3);
    F_l_fit(i) = x_lift(1).*velocity(i)^2 + x_lift(2).*velocity(i) + x_lift(3);
    F_M_fit(i) = x_M_cg(1).*velocity(i)^2 + x_M_cg(2).*velocity(i) + x_M_cg(3);
end



%%
figure;
tiledlayout(1,3);

nexttile
plot(V(:,1),F_d(:,1), LineWidth=2)
hold on
plot(velocity(:),F_d_fit(:),linewidth=2,LineStyle="--")
grid on
xlabel("velocity")
ylabel("F_{drag}")
legend("F_{drag} dta","F_{drag}_fitted")

nexttile
plot(V(:,1),F_l(:,1), LineWidth=2)
hold on
plot(velocity(:),F_l_fit(:),linewidth=2,LineStyle="--")
grid on
xlabel("velocity")
ylabel("F_{lift}")
legend("F_{lift} data","F_{lift}_fitted")

nexttile
plot(V(:,1),M_cg(:,1), LineWidth=2)
hold on
plot(velocity(:),F_M_fit(:),linewidth=2,LineStyle="--")
grid on
xlabel("velocity")
ylabel("M_{cg}")
legend("M_{cg} data","M_{cg}_fitted")


%% Fitting coefs

for i = 1:length(V)
    if V(i)<=0
        C_d(i) = 0;
        C_l(i) = 0;
        C_m(i) = 0;
    else
        C_d(i) = 2*(T_r(i)+T_f(i))/(ro*A*V(i)^2);
        C_l(i) = 2*(N_f(i)+N_r(i)+weight)/(ro*A*V(i)^2);
        C_m(i) = 2*(2*T_f(i)-2*T_r(i)+a*N_f(i)-b*N_r(i))/(ro*A*V(i)^2);
    end
end

% using fit;

for i = 1:length(velocity)
    if velocity(i)<=0
        C_d_fit(i) = 0;
        C_l_fit(i) = 0;
        C_m_fit(i) = 0;
    else
        C_d_fit(i) = 2*(F_d_fit(i))/(ro*A*velocity(i)^2);
        C_l_fit(i) = 2*(F_l_fit(i))/(ro*A*velocity(i)^2);
        C_m_fit(i) = 2*(F_M_fit(i))/(ro*A*velocity(i)^2);
    end
end

%%
figure
tiledlayout(1,3);

nexttile
plot(V(:),C_d(:),LineWidth=2)
hold on
plot(velocity(:),C_d_fit(:),LineWidth=2,LineStyle="-.")
grid on
xlabel("velocity")
ylabel("F_{drag}")
legend("F_{drag} dta","F_{drag}_fitted")

nexttile
plot(V(:),C_l(:),LineWidth=2)
hold on
plot(velocity(:),C_l_fit(:),LineWidth=2,LineStyle="-.")
grid on
xlabel("velocity")
ylabel("F_{lift}")
legend("F_{lift} data","F_{lift}_fitted")

nexttile
plot(V(:),C_m(:),LineWidth=2)
hold on
plot(velocity(:),C_m_fit(:),LineWidth=2,LineStyle="-.")
grid on
xlabel("velocity")
ylabel("M_{cg}")
legend("M_{cg} data","M_{cg}_fitted")


