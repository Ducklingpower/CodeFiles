% Eric Perez
% ME145 Lab 1
function [a,b,c] = computeLineThroughTwoPoints(P1,P2)
     [m1,n1] = size(P1);
     [m2,n2] = size(P2);
    if m1 ~= 1 || n1 ~= 2
        error('Wrong input format for P1');
    end 
    if m2 ~= 1 || n2 ~= 2
        error('Wrong input format for P2');
    end 

x1 = P1(1);
y1 = P1(2);
x2 = P2(1);
y2 = P2(2);
Mag = sqrt((x2 - x1).^2 + (y2 - y1).^2);
if Mag <= 0.1
    error('The two point are less than 0.1 away from each other')
end

a0 = (y2 - y1)/(x2-x1);
b0 = -1;
c0 = y1 - a0*x1;
s = sqrt(a0.^2 + b0.^2);
a = a0/s;
b = b0/s;
c = c0/s;
end

