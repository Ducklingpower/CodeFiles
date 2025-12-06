clc 
close all
clear
%%
% full order \:

P = tf(4,[1 3 2]);

F_fo = tf([1 20 100],[1 21 119]);
C_fo = tf([81/4 162/4],[1 21 119]);

F_ro = tf([4 40],[9 18]);
C_ro = tf([9 18],[4 44]);

C = tf([3/4 3/2],[1 6 12 8]);



TF_fo = (P*C_fo*F_fo / (1+ P*C_fo));
TF_ro = P*C_ro*F_ro / (1+ P*C_ro);
TF_c = C*16/3;

step(TF_ro,"o")
hold on
step(TF_ro,"x")
hold on
step(TF_c)
grid on

legend("full order","reduced order","pole placment")

%% Part 3
clc
close all
clear TF_fo

P = tf(1,[1 4 4]);
P_p = tf(2,[1 2 1]);


c_1 = tf([1000 4000 4000],[1 30 300 0]);
c_2 = tf([100 400 400],[1 20 0]);
c_3 = c_2;

c_11 = tf([785 2420 2000],[1 32 359 0]);
T_11 = feedback(P_p*c_11,1);

c_22 = tf([69.5 229 200],[1 22 0]);
T_22 = feedback(P_p*c_22,1);



T_1 = feedback(c_1*P,1);
T_2 = feedback(c_2*P,1);
T_3 = feedback(c_3*P,1);

figure
step(T_1,"--")
hold on
step(T_2)
hold on
step(T_3,"o")
hold off
grid on
legend("Full order observer","Pole pacment","RO observer")
