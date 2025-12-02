clc
close all
clear 
%%



A = [0 1 0;
     0 0 1;
     0 0 -3];
B = [0;0;600];



K_clp = [-10+10*j; -10-10*j; -50]; 

k = place(A,B,K_clp);


x = 1;
A_bar = A-B*k;
B_bar = [-1; 0 ; 600*x];
C = [0 1 0];

sys_cl = ss(A_bar, B_bar, C, 0);

sys_tf = tf(sys_cl);

% plotting 

for x =-10:2.5:10

    A_bar = A-B*k;
    B_bar = [-1; 0 ; 600*x];
    C = [0 1 0];
    
    sys_cl = ss(A_bar, B_bar, C, 0);
    
    sys_tf = tf(sys_cl);
    step(sys_tf)
    hold on
    grid on
end

legend("kr = -10","kr = -7.5","kr = -5.0","kr = -2.5","kr = 0","kr = 2.5","kr = 5.0","kr = 7.5","kr = 10")



