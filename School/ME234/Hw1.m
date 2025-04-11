clc
close all
clear
%%

A = [1 2 3  ;
     4 5 6  ;
     8 1 10];

% eigan vect/ eigan val
[vect,val] = eig(A);
disp("Eigan vectors of A are:")
disp(vect)

disp("Eigan values are:")
disp(diag(val));


% span of A
span = orth(A);
disp("The span of A is:")
disp(span)

% Rank of A
Rank = rank(A);
disp("The rank of A is:")
disp(Rank)

% determinant of A
Determinant = det(A);
disp("the determinant of A is:")
disp(Determinant);

% inverse of A
Inverse = inv(A);
disp("the inverse of A is:")
disp(Inverse)

% Tranformation matrix T
T = vect;
disp("The tranformation matrix is T = ")
disp(T)
disp("proof, T^-1 AT =")
Diag = inv(T)*A*T;
disp(Diag)


% new meatirx 

B = A + transpose(A);
[vect_b,val_b] = eig(B);

disp("The eigan vectors of A+A^T is:")
disp(vect_b)
disp("The eigan values of A+A^T is :")
disp(diag(val_b));