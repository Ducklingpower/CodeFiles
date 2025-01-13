clc

x=[1 2 3 4 5];

y=[ 2 7 4 9 1];
xx=linspace(1,5);
yy=interp1(x,y,xx);
plot(xx,yy);
hold on 
plot(x,y,'ro')


