function results = Lab3Stub()

%load Lab3Answers
errorMessages = {};
try
    [val1, nSteps1]= taylorcosine(pi/3,1e-3);
    results{1} = val1;
    results{2} = nSteps1;
    errorMessages{1} = '';
catch ME
    results{1} = NaN;
    results{2} = NaN;
    errorMessages{1} = strcat(' Problem 1 Run 1: ', ME.identifier, ': ', ME.message);
end
 
try
    [val2, nSteps2]= taylorcosine(pi/3,1e-8);
    results{3} = val2;
    results{4} = nSteps2;
    errorMessages{2} = '';
catch ME
    results{3} = NaN;
    results{4} = NaN;
    errorMessages{2} = strcat(' Problem 1 Run 2: ', ME.identifier,': ', ME.message);
end

f1 = @(x) x.^2-3*x+2;
f2 = @(x) x.^4+1.58*x.^3-8.3471*x.^2-5.3132*x.^1+6.8944;

try
    root1 = myBisection(f1,[1.3 3.0], 1e-2);
    results{5} = root1;
    errorMessages{3} = '';
catch ME
    results{5} = NaN;
    errorMessages{3} = strcat(' Problem 2 Run 1: ', ME.identifier,': ', ME.message);
end

try
    root2 = myBisection(f2,[1.3 3.0], 1e-5);
    results{6} = root2;
    errorMessages{4} = '';
catch ME
    results{6} = NaN;
    errorMessages{4} = strcat(' Problem 2 Run 1: ', ME.identifier,': ', ME.message);
end

try
    ratio1 = computeMachNumber(1.5,1.4);
    results{7} = ratio1;
    errorMessages{5} = '';
catch ME
    results{7} = NaN;
    errorMessages{5} = strcat(' Problem 3 Run 1: ', ME.identifier,': ', ME.message);
end

try
    ratio2 = computeMachNumber(2.0,1.4);
    results{8} = ratio2;
    errorMessages{6} = '';
catch ME
    results{8} = NaN;
    errorMessages{6} = strcat(errorMessages,' Problem 3 Run 2: ', ME.identifier,': ', ME.message);
end

results{9} = errorMessages;

% [refVal1, refNSteps]= taylorcosine(pi/3,1e-3);
% [refVal2, refNSteps]= taylorcosine(pi/3,1e-8);
% 
% f1 = @(x) x.^2-3*x+2;
% f2 = @(x) x.^4+1.58*x.^3-8.3471*x.^2-5.3132*x.^1+6.8944;
% 
% refRoot1 = myBisection(f1,[1.3 3.0], 1e-2);
% refRoot2 = myBisection(f2,[1.3 3.0], 1e-5);
% 
% refRat1 = computeMachNumber(1.5,1.4);
% refRat2 = computeMachNumber(2.0,1.4);