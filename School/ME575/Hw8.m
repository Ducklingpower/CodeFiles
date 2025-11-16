clc
close all
clear
%% Hw8
% L2 = 1
A = [0 1 0 0 0 0;
     0 0 -15/7 0 -15/7 0;
     0 0 0 1 0 0;
     0 0 255/28 0 45/28 0;
     0 0 0 0 0 1;
     0 0 45/28 0 255/28 0];

B = [0;2/25;0;-3/14;0;-3/14];

C = [1 0 0 0 0 0;
     0 0 1 0 0 0;
     0 0 0 0 1 0];

Wc = [B A*B A^2*B A^3*B A^4*B A^5*B];
rref(Wc)
rank_wc = rank(Wc);

T = [Wc(:,1) Wc(:,2) Wc(:,3) Wc(:,4) [1;0;1;0;0;0] [0;1;0;1;0;0]];
rank(T);

A_bar = T^(-1)*A*(T)
B_bar = T^(-1)*B
C_bar = C*T

uncontrollable = [0 1; 7.5 0];
eigs(uncontrollable)
%%
clc
clear
% L2 = 1.5

A = [0 1 0 0 0 0;
     0 0 -15/7 0 -15/7 0;
     0 0 0 1 0 0;
     0 0 255/28 0 45/28 0;
     0 0 0 0 0 1;
     0 0 85/14 0 14/4 0];

B = [0;2/25;0;-3/14;0;-1/7];

Wc = [B A*B A^2*B A^3*B A^4*B A^5*B];
rank_wc = rank(Wc);
 

%% Problem 2
clc
clear

A = [0 1 0 0;
     0 0 -2 0;
     0 0 0 1;
     0 0 120 0];

B = [0;0.2;0;0.2];

C = [0 0 1 0];

Wc = [B A*B A^2*B A^3*B];
rank(Wc);

Wo = [C;C*A;C*A^2;C*A^3];
rank(Wo)
rref(Wo)

T = [[1;0;0;0] [0;1;0;0] Wo(:,3) Wo(:,4)];
rank(T)


A_bar = (T^(-1))*A*T;
B_bar = T^(-1)*B;
C_bar = C*T;



