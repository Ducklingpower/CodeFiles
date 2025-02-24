
%862274334
%perez, elijah
%Me18A assignment 7
%11/17/2022
function p=myPolyFit(x,y)

Lx=length(x);
Ly=length(y);

A=zeros(Lx,Ly);

for i=1:Lx
    for j=1:Ly
        A(i,j)=x(i);
    end
end 


for i=1:Lx
    A(:,i)=A(:,i).^(i-1);
end

y=y';
[p]= solveLinearEquations(A,y);
end