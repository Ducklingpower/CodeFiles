function [results, errorMessages] = Lab4Stub()

f1 = @(x)(x.^2-3*x+2);
df1 = @(x)(2*x-3);
guess = 3;
errTol = 1e-6;
maxIter = 100;
try
    r = newtonRaphsonMethod(f1,df1,guess,errTol,maxIter);
    results{1} = r;
    errorMessages{1} = '';
catch ME
    results{1} = NaN;
    errorMessages{1} = strcat(' newtonRaphsonMethod: ', ME.identifier, ' : ', ME.message);
end

f2 = @(x)exp(-x).*sin(2*x) + 1;
df2 = @(x) exp(-x).*(2*cos(2*x)-sin(2*x));
errTol2 = 1e-6;
maxIter2 = 100;
try
    r2 = newtonRaphsonMethod(f2,df2,-2, errTol2, maxIter2 );
    results{2}= r2;
    errorMessage{2} = '';
catch ME
    results{2} = NaN;
    errorMessages{2} = strcat(' newtonRaphsonMethod: ', ME.identifier, ' : ', ME.message);
end
    
    
    
D = 0.9e-2;
eps = 10e-6;
rho = 1e3;
mu = 0.85e-3;
V = 1;

try
[f1,Re1] = computeFrictionFactor(V, [D eps],[rho mu]); % turbulent
results{3}{1} = f1;
results{3}{2} = Re1;
errorMessages{3} = '';
catch ME
    results{3}{1} = NaN;
    results{3}{2} = NaN;
    errorMessages{3} = strcat(' computeFrictionFactor: Run 1  :', ME.identifier, ' : ', ME.message);
end


mu = 0.085;
V = 0.3;
try
[f2,Re2] = computeFrictionFactor(V, [D eps],[rho mu]); % laminar
results{4}{1} = f2;
results{4}{2} = Re2;
errorMessages{4} = '';
catch ME
    results{4}{1} = NaN;
    results{4}{2} = NaN;
    errorMessages{4} = strcat(' computeFrictionFactor: Run 2  :', ME.identifier, ' : ', ME.message);
end

mu = 0.00085;
V = 0.3;
try
[f3,Re3] = computeFrictionFactor(V, [D eps],[rho mu]); % transition
results{5}{1} = f3;
results{5}{2} = Re3;
errorMessages{5} = '';

catch ME
    results{5}{1} = NaN;
    results{5}{2} = NaN;
    errorMessages{5} = strcat(' computeFrictionFactor: Run 3 :', ME.identifier, ' : ', ME.message);
end

A = [3 -2 1 4; 2 -1 -1 2 ; 4 -2 -3 -4];
B = [8 3 0 1; 5 -3 -5 -2; -2 0 1 -3];
C = [2 -3; 5 -3; -1 -2; -3 3];
D = [3 -2 1 4; 2 -1 -1 2 ; 4 -2 -3 -4; -1 0 9 -2];

try
[st1, a1] = addMatrices(A,C); % Invalid input
results{6} = st1;
errorMessages{6} = '';
catch ME
    results{6}{1} = NaN;
    results{6}{2} = NaN;
    errorMessages{6} = strcat(' addMatrices: Run 1 :', ME.identifier, ' : ', ME.message);
end
    
try
[st2, a2] = addMatrices(A,B);
results{7}{1} = st2;
results{7}{2} = a2;
errorMessages{7} = '';
catch ME
    results{7}{1} = NaN;
    results{7}{2} = NaN;
    errorMessages{7} = strcat(' addMatrices: Run 2 :', ME.identifier, ' : ', ME.message);
end

try
[st3, a3] = subtractMatrices(A,C);
results{8} = st3;
%results{7}{2} = st3;
errorMessages{8} = '';
catch ME
    results{8}{1} = NaN;
    results{8}{2} = NaN;
    errorMessages{8} = strcat(' subtractMatrices: Run 1 :', ME.identifier, ' : ', ME.message);
end

try
[st4, a4] = subtractMatrices(A,B);
results{9}{1} = st4;
results{9}{2} = a4;
errorMessages{9} = '';
catch ME
    results{9}{1} = NaN;
    results{9}{2} = NaN;
    errorMessages{9} = strcat(' subtractMatrices: Run 2 :', ME.identifier, ' : ', ME.message);
end

try
[st5, a5] = multiplyMatrices(A,B);
results{10} = st5;
%results{9}{2} = st5;
errorMessages{10} = '';
catch ME
    results{10}{1} = NaN;
    results{10}{2} = NaN;
    errorMessages{10} = strcat(' multiplyMatrices: Run 1 :', ME.identifier, ' : ', ME.message);
end

try
[st6, a6] = multiplyMatrices(A,C);
results{11}{1} = st6;
results{11}{2} = a6;
errorMessages{11} = '';
catch ME
    results{11}{1} = NaN;
    results{11}{2} = NaN;
    errorMessages{11} = strcat(' multiplyMatrices: Run 2 :', ME.identifier, ' : ', ME.message);
end

try
    [st7, a7] = transposeMatrix(C);
    results{12} = a7;
    errorMessages{12} = '';
catch ME 
    results{12}{1} = NaN;
    results{12}{2} = NaN;
    errorMessages{12} = strcat(' transpose Matrix :', ME.identifier, ' : ', ME.message);
end
% try
% [st7, a7] = computeDeterminant(A);
% results{12} = st7;
% errorMessages{12} = '';
% catch ME
%     results{12}{1} = NaN;
%     results{12}{2} = NaN;
%     errorMessages{12} = strcat(' computeDeterminant: Run 1 :', ME.identifier, ' : ', ME.message);
% end
% 
% try
% [st8, a8] = computeDeterminant(D);
% results{13}{1} = st8;
% results{13}{2} = a8;
% errorMessages{13} = '';
% catch ME
%     results{13}{1} = NaN;
%     results{13}{2} = NaN;
%     errorMessages{13} = strcat(' computeDeterminant: Run 2 :', ME.identifier, ' : ', ME.message);
% end
% 
% try
% [st9, a9] = computeMinor(D, 2, 1);
% results{14}{1} = st9;
% results{14}{2} = a9;
% errorMessages{14} = '';
% catch ME
%     results{14}{1} = NaN;
%     results{14}{2} = NaN;
%     errorMessages{14} = strcat(' computeMinor :  ', ME.identifier, ' : ', ME.message);
% end
% 
% try
% [st10, a10] = computeCofactor(D,3,2);
% results{15}{1} = st10;
% results{15}{2} = a10;
% errorMessages{15} = '';
% catch ME
%     results{15}{1} = NaN;
%     results{15}{2} = NaN;
%     errorMessages{15} = strcat(' computeCofactor :  ', ME.identifier, ' : ', ME.message);
% end





