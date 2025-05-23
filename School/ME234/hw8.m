clc
close all
clear 
%% Q1 

A = [0 0 1 0;
     0 0 0 1;
     0 0 0 0;
     0 0 0 0];
B=  [0 0 ;
     0 0 ;
     1 0 ;
     0 1 ];
C = [1 0 0 0;
     0 1 0 0];
Control = rank([B A*B A^2*B A^3*B]);
Observe = rank([C; C*A; C*A^2; C*A^3]);



%% Q2

A = [0 1 0;
     0 0 1;
     0 2 -1];

B = [0 1;
     1 0;
     0 0];

C = [1 0 1];

Control = rank([B A*B A^2*B]);
Observe = rank([C; C*A; C*A^2]);


%% Q3
t0 = 0;
t1 = 5;
n = 1000;
tau_vec = linspace(t0, t1, n);
dt = (t1 - t0)/n;

Wc = zeros(2,2); 
Wo = zeros(2,2); 

A = [0 0; 0 -1];

for i = 1:n
    tau = tau_vec(i);


    B = [1; exp(-tau)];
    Phi_c = expm(A * (t1 - tau));
    Wc = Wc + (Phi_c * (B * B') * Phi_c') * dt;

    C = [1, exp(-tau)];
    Phi_o = expm(A * (tau - t0));
    Wo = Wo + (Phi_o' * (C' * C) * Phi_o) * dt;
end

controle = rank(Wc)
Observe = rank(Wo)