function [x,I]=cumulativeTrapezoid(f,limits,n)
a=limits(1);
b=limits(2);
X=linspace(a,b,n+1);
I=0;
z=zeros(1,n);
for i=1:n
   I=0.5*(f(X(i))+f(X(i+1)))*(X(i+1)-X(i))+I;
   z(1,i+1)=I;
end
I=z;
x=X;
