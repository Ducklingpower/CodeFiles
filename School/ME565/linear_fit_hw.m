clc
close all
clear 
%%
A = [1 900 900^2;
     1 1350 1350^2;
     1 1800 1800^2];

b = [800/3;1025/3;1150/3];

x = A^-1 * b;


Fz = [900 1350 1800];

alpha = 0:0.1:6;

for i = 1:length(Fz)
    C(i) = x(1) + x(2)*Fz(i) + x(3)*Fz(i)^2;
    Fy(:,i) = C(i)*alpha;
end

figure
plot(alpha,Fy(:,:))
hold on 
plot(3,(x(1) + x(2)*Fz(1) + x(3)*Fz(1)^2)*3,"*",LineWidth=2)
hold on 
plot(3,(x(1) + x(2)*Fz(2) + x(3)*Fz(2)^2)*3,"*",LineWidth=2)
hold on 
plot(3,(x(1) + x(2)*Fz(3) + x(3)*Fz(3)^2)*3,"*",LineWidth=2)
xlabel('Alpha');
ylabel('Fy Values');
title('Plot of Fy vs Alpha for Different Fz');
grid on;

legend("Linear model at 800 lb","Linear model at 1000 lb","Linear model at 1150 lb")

