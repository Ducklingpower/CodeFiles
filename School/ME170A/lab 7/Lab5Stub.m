function [results, errorMessages] = Lab5Stub()

A = [3 -2 1 4; 2 -1 -1 2 ; 4 -2 -3 -4];
B = [8 3 0 1; 5 -3 -5 -2; -2 0 1 -3];
C = [2 -3; 5 -3; -1 -2; -3 3];
D = [3 -2 1 4; 2 -1 -1 2 ; 4 -2 -3 -4; -1 0 9 -2];

try
[st1, a1] = computeDeterminant(D);
results{1} = st1;
errorMessages{1} = '';
catch ME
    results{1}{1} = NaN;
    results{1}{2} = NaN;
    errorMessages{1} = strcat(' computeDeterminant: Run 2 :', ME.identifier, ' : ', ME.message);
end

try
[st2, a2] = computeDeterminant(D);
results{2}{1} = st2;
results{2}{2} = a2;
errorMessages{2} = '';
catch ME
    results{2}{1} = NaN;
    results{2}{2} = NaN;
    errorMessages{2} = strcat(' computeDeterminant: Run 2 :', ME.identifier, ' : ', ME.message);
end

try
[st3, a3] = computeMinor(D, 2, 1);
results{3}{1} = st3;
results{3}{2} = a3;
errorMessages{3} = '';
catch ME
    results{3}{1} = NaN;
    results{3}{2} = NaN;
    errorMessages{3} = strcat(' computeMinor :  ', ME.identifier, ' : ', ME.message);
end

try
[st4, a4] = computeCofactor(D,3,2);
results{4}{1} = st4;
results{4}{2} = a4;
errorMessages{4} = '';
catch ME
    results{4}{1} = NaN;
    results{4}{2} = NaN;
    errorMessages{4} = strcat(' computeCofactor :  ', ME.identifier, ' : ', ME.message);
end



E = [1 2 3 1 2; 
     3 1 2 3 3;
     2 2 1 2 5
     4 1 3 -2 5];
 try
     e5 = gaussianElimination(E);
     results{5} = e5;
     errorMessages{5} = '';
 catch ME
     results{5}{1} = NaN;
     results{5}{2} = NaN;
     errorMessages{5} = strcat(' gaussianElimination :  ', ME.identifier, ' : ', ME.message);
 end

L = [1 -2 1;
    3 1 -2;
    2 -2 1];
y = [-2 -1 1]';
M = L*y;

try
     e6 = solveLinearEquations(L,M);
     results{6} = e6;
     errorMessages{6} = '';
 catch ME
     results{6}{1} = NaN;
     results{6}{2} = NaN;
     errorMessages{6} = strcat(' solveLinearEquations Run 1 :  ', ME.identifier, ' : ', ME.message);
 end

F = [1 3 2 2 -3;
    -1 2 4 3 -1;
    5 3 2 -1 0;
    3 -2 3 1 2;
    2 -1 -3 1 4];

x = [-1; 2; 3; 1; -2];
G = F*x;

try
     e7 = solveLinearEquations(F,G);
     results{7} = e7;
     errorMessages{7} = '';
 catch ME
     results{7}{1} = NaN;
     results{7}{2} = NaN;
     errorMessages{7} = strcat(' solveLinearEquations Run 2 :  ', ME.identifier, ' : ', ME.message);
 end





