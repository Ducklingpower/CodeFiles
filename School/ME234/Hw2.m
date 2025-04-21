%% Hw 2
clc
clear
close all
%%
% state space to TF matrix

A = [-1 0 -1;
      0 1 0;
      1 0.5 -0.5];

B = [1 1;
     0.5 0.6;
     0 0];

C = [1 1 -1;
     0.5 1 0];

D = [0 0;
     1 0];

disp("Given:")
A
B
C
D


sys = ss(A, B, C, D);
TF_matrix = tf(sys);

disp('The tranfer funcrtion matrix is:');
TF_matrix

% TF matrix to state space



num1 = [1 -1 0.5];
den1 = [1 0.5 0.5 -1.5];

num2 = [1 1 0.5 -2];
den2 = [1 0.5 0.5 -1.5];

TF1 = tf(num1,den1);
TF2 = tf(num2,den2);
disp("Given the two trnafer functions shown:")
TF1
TF2
disp("The State space matrices are:")

tf_Matrix = tf({num1 num2},{den1 den2});
state_space = ss(tf_Matrix);
state_space





