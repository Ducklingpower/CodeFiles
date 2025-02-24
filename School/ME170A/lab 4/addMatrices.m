%862274334
%perez, elijah
%Me18A assignment 4
%10/25/2022
function [status, results]= addMatrices(a,b)

[R,C]=size(a);%size of matrics a
[Rb,Cb]=size(b);%size of matrics b

if R~=Rb || C~=Cb
    status=0;
    x=[];
else
for i=1:R  % where C/R are some number of the size of the matrices
for j=1:C
   x(i,j)=a(i,j)+b(i,j);
   status=1;
end
end
end
results=x;
end



