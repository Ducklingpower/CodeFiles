function D= deriv(f,x0,n,h,options)

D=0;

if options==1
for i=0:n


      V=factorial(n)/(factorial(i)*(factorial(n-i)));
      D=(((-1)^i)*f(x0+(n-i)*h)*V)+D;


  

end
D=D*(1/(h^n));

elseif options==2
    z=zeros(1,n+1);
    for j=0:n
        D=0;
for i=0:j
      V=factorial(j)/(factorial(i)*(factorial(j-i)));
      D=(((-1)^i)*f(x0+(j-i)*h)*V)+D;
end
D=D*(1/(h^j));
z(j+1)=D;
    end
    D=z;
end
