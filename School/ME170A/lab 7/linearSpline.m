%862274334
%perez, elijah
%Me18A assignment 7
%11/17/2022
function yy=linearSpline(x,y,xx)
Lx=length(x);
Ly=length(y);
[R,C]=size(xx);
yy=zeros(1,C);


for j=1:C
for i=1:Lx-1
    if x(i)<=xx(j) && xx(j)<=x(i+1)
    M=(y(i+1)-y(i))./(x(i+1)-x(i));%slope
    fx=M*(xx(j)-x(i))+y(i);

yy(1,j)=fx;
    end
end
end
