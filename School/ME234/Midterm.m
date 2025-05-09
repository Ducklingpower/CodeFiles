clc
close all
clear
%%

beta = 1;
P = [ beta 0 0;
      0   4 -3;
      0  -5 4 ;];


A = [0 4 3; 0 20 16; 0 -25 -20];


J = inv(P)*A*P


%%

syms t

et = expm(A*t)

%% Part C

%%  Part (c) Time-response of the state–space system

A = [ 0   4    3  ;
      0  20   16  ;
      0 -25  -20 ];

B = [ 1  0  ;
      0  1  ;
      0  0 ];

C = [ 1  0  0  ;
      0  1  0 ];

D = [1 0; 0 1];                           

sys = ss(A,B,C,D);                      

t  = 0:0.1:15;
t  = t';
u  = [sin(t)  cos(t)];
x0 = [0.1 ; 0.2 ; 0.3];                 

[y,t_out,x] = lsim(sys,u,t,x0);          


%% Plotting 

figure("Name","Plotting states")                         
plot(t_out,x,'LineWidth',2)
grid on,
xlabel('seconds')
ylabel('States')
legend('x_1','x_2','x_3')
title('States')

figure("Name","Plotting Output")                       
plot(t_out,y,'LineWidth',2)
grid on,
xlabel('seconds')
ylabel('Outputs')
legend('y_1','y_2')
title('Output')


%% 
A = [1/2 1 1; 0 -1 0; 0 0 -1];
syms t
et = expm(A*t)