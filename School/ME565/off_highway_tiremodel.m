clc 
close all 
clear
%%

A = [0.67 0.65 0.52 0.53 0.88];
Bc = [0.17 0.07 0.19 0.14 0.15];




Fz = [100 1000];

B = 1.01*(100/Fz(1))*exp(0.14)-0.8401;
alpha = 0:15;
for i = 1:length(A)
        for k = 1:length(alpha)
            Fy(i,k) = (A(i)*(1-exp(-B(1)*alpha(k))) * Fz(1));
        end
end


figure 
plot(alpha(:),Fy(:,:))



