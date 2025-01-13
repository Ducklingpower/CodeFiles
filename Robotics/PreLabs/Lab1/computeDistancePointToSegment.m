% Eric Perez
% ME145 lab 1
function [distance] = computeDistancePointToSegment(P1,P2,q)
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
q1 = q(1);
Mag = sqrt((x2 - x1).^2 + (y2 - y1).^2);
if Mag <= 0.1
    error('The two point are less than 0.1 away from each other')
end
q2 = q(2);
m = (y2 - y1)/(x2-x1);
a = m;
b = -1;
c = y1 - a*x1;
mq = (-1/m);
aq = mq;
bq = -1;
cq = q2 - aq*q1;
xpq = (c-cq)/(mq-m);
ypq = mq*xpq + cq;
minx = min(x1,x2);
maxx = max(x1,x2);
if xpq >= minx && xpq <= maxx
distance = sqrt((ypq-q2).^2 + (q1-xpq).^2);
else
     distance = 1/0;
end
end