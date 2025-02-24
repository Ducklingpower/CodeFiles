function D=taylorCoefficients(f,x0,n,h)
f=deriv(f,x0,n,h,2);
%f=[sin(x0) cos(x0) -sin(x0) -cos(x0) sin(x0) cos(x0)];
D=zeros(1,n);

for i=1:n+1
    d=f(i)/factorial(i-1);
    D(1,i)=d;
end
