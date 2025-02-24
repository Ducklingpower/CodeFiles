function I= trapezoid(f, limits, n)
a=limits(1);
b=limits(2);
x=linspace(a,b,n+1);
I=0;
for i=1:n
   I=0.5*(f(x(i))+f(x(i+1)))*(x(i+1)-x(i))+I;
end

