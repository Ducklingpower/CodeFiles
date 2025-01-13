function Y=forwardSubstitution(L,b,P)

B=P*b;
[R,C]=size(B);
Y=zeros(R,1);
y=0;
Y(1)=B(1);
for i=2:R
x=B(i);
y=0;
    for j=1:R-1
        y=-L(i,j)*Y(j)+y;
    end
    Y(i)=x+y;
end