function [results, errorMessages] = Lab6Stub()
% clear all;
% clc;
% close all;

errorMessages = cell(1,11);

L3 = [1 0 0; 2 1 0; -2 2 1];
y3f = [1 -2 2]';
b3 = L3*y3f;
P3 = eye(3);
%b3 = [1 2 3]';
try
    y3 = forwardSubstitution(L3,b3,P3);
    results{1} = y3;
    
catch ME
    results{1} = NaN;
    errorMessages{1} = strcat(' forward Substitution: ', ME.identifier, ' : ', ME.message);
end

U4 = [1 -1 1;0 2 3; 0 0 3];
y4f = [1 -2 3]';
b4 = U4*y4f;
try
    y4 = backSubstitution(U4,b4);
    results{2} = y4;
catch ME
    results{2} = NaN;
    errorMessages{2} = strcat(' back Substitution: ', ME.identifier, ' : ', ME.message);
end

A1 = [1 3 4 -5; 2 1 -3 4; 4 -1 2 1; 3 -2 -1 3];
x1 = [1 -1 2 3]';

B1 = A1*x1;

try
    [L1, U1, P1] = luDecomposition(A1);
    results{3}{1} = L1;
    results{3}{2} = U1;
    results{3}{3} = P1;
catch ME
    results{3}{1} = NaN;
    results{3}{2} = NaN;
    results{3}{3} = NaN;
    errorMessages{3} = strcat(' LU Decomposition: Run 1:  ', ME.identifier, ' : ', ME.message);

end

try
x11 = solveLinearSystem(A1,B1);
results{4} = x11;
catch ME
    results{4} = NaN;
    errorMessages{4} = strcat(' solveLinearSystem: Run 1: ', ME.identifier, ' : ', ME.message);
end

A2 = [3 -1 2 3 4; 
      1 -2 -3 4 1;
      5 -2 3 1 -2;
      -2 3 4 -5 1;
      -3 -1 -2 4 5];
x2 = [-1 2 -3 1 -2]';
B2 = A2*x2;

try
    [L2, U2, P2] = luDecomposition(A2);
    results{5}{1} = L2;
    results{5}{2} = U2;
    results{5}{3} = P3;
catch ME
    results{5}{1} = NaN;
    results{5}{2} = NaN;
    results{5}{3} = NaN;
    errorMessages{5} = strcat(' LU Decomposition: Run 2:  ', ME.identifier, ' : ', ME.message);

end

try
    x21 = solveLinearSystem(A2,B2);
    results{6} = x21;
catch ME
    results{6} = NaN;
    errorMessages{6} = strcat(' solveLinearSystem: Run 1: ', ME.identifier, ' : ', ME.message);
end

try
    L3inv = myInverse(L3);
    results{7} = L3inv;
catch ME
    results{7} = NaN;
    errorMessages{7} = strcat(' myInverse: Run 1: ', ME.identifier, ' : ', ME.message);
end

try
    A2inv = myInverse(A2);
    results{8} = A2inv;
catch ME
    results{8} = NaN;
    errorMessages{8} = strcat(' myInverse: Run 2: ', ME.identifier, ' : ', ME.message);
end

try
    A1det = myDeterminant(A1);
    results{9} = A1det;
catch ME
    results{9} = NaN;
    errorMessages{9} = strcat(' myDeterminant: Run 1: ', ME.identifier, ' : ', ME.message);
end

try
    A2det = myDeterminant(A2);
    results{10} = A2det;
catch ME
    results{10} = NaN;
    errorMessages{10} = strcat(' myDeterminant: Run 2: ', ME.identifier, ' : ', ME.message);
end

loads = [10 20 10];
try
f =  computeForcesInTruss(loads);
results{11} = f;
catch ME
    results{11} = NaN;
    errorMessages{11} = strcat(' computeForcesInTruss: ', ME.identifier, ' : ', ME.message);
end