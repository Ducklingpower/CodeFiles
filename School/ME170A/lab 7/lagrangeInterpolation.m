%862274334
%perez, elijah
%Me18A assignment 7
%11/17/2022
function yy=lagrangeInterpolation(x,y,xx)
Lx=length(x);
Ly=length(y);
[R,C]=size(xx);
top=1;
bottom=1;
fx=zeros(Lx);
yy=zeros(1,C);

for k=1:C

for j=1:Lx
    xj=x;
     xj(j)=[];
for i=1:Lx-1
    
top= (xx(k)-xj(i))*top;% top

bottom=(x(j)-xj(i))*bottom;
end
fx(j,k)=(top/bottom)*y(j);
top=1;
bottom=1;
end
w=sum(fx(:,k));
yy(k)=w;

end

end


   
  