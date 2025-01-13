%862274334
%perez Elijah
%Me18A
%10/31/2022

function [status,results]=computeDeterminant(a)
x=0;
[R,C]=size(a);

if R~=C
    status=0;
    results=[];
elseif R==2
   y= (a(1,1)*a(2,2))-(a(2,1)*a(1,2));
results=y;
   status=1;

else
    
    for j=1:C
        z=a;
z(1,:)=[];
z(:,j)=[];
[s,w]= computeDeterminant(z);
Y=(-1)^(1+j)*w*a(1,j);
x=x+Y;

    end
    
    status=1;
    results=x;   
end
end
