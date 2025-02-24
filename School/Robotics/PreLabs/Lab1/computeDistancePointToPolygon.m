%Eric Perez
%Lab 1 problem 2 

function [minD,MinX,MinY] = computeDistancePointToPolygon(Poly,q)
[m,n] = size(Poly);
if n ~= 2
    error('Columns of Polygon does not equal 2');
end
distance = zeros(1,m);
for i = 1:m
   %distance(i) = norm(Poly(i) - q(i));
   distance(i) = sqrt((Poly(i,2)-q(2)).^2 + (q(1)-Poly(i,1)).^2);
end 


for i = 1:m
    x(i) = Poly(i,1);
    y(i) = Poly(i,2);
  
end
x(end+1)= x(1);
y(end+1)=y(1);
 plot(x,y,'b');
 hold on; 
 plot(q(1),q(2),'o');
 minD = min(distance);
IndexD = find(distance==minD);
MinX = x(IndexD);
MinY = y(IndexD);
end 