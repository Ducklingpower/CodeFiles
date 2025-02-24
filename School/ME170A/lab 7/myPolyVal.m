%862274334
%perez, elijah
%Me18A assignment 7
%11/17/2022
function p=myPolyVal(p,x)
Lp=length(p);
Lx=length(x);
Z=zeros(1,Lx);
y=0;
for j=1:Lx
for i=1:Lp
     y=p(i)*(x(j).^(i-1))+y;
end 
Z(j)=y;
y=0;
end
p=Z;