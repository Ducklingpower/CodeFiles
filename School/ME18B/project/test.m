clear all
close all
clc

x = -2:3;
y = randi([-5 5],size(x));

p = cubicSplineCoefficients(x,y);
[n,m] = size(p.coefs);
plot(x,y,'ko','MarkerFaceColor','k')
grid on; hold on
for i = 1:n
    P = p.coefs(i,:);
    xx = x(i):0.01:x(i+1);
    yy = P(1)*(xx - x(i)).^3 + P(2)*(xx -x(i)).^2 + P(3)*(xx - x(i)) + P(4);
    plot(xx,yy,'b-')
end
y_interp = cubicSplineInterpolation(p,x);
plot(x,y_interp,'cp','MarkerFaceColor','c')
y_interp2 = cubicSplineInterpolation(p,[-1.5 0.5 2.5]);
plot([-1.5 0.5 2.5],y_interp2,'rs','MarkerFaceColor','r')

pp = spline(x,y);
for i = 1:n
    P = pp.coefs(i,:);
    xx = x(i):0.01:x(i+1);
    yy = P(1)*(xx - x(i)).^3 + P(2)*(xx -x(i)).^2 + P(3)*(xx - x(i)) + P(4);
    plot(xx,yy,'g-')
end