%862274334
%perez Elijah
%Me18A
%10/31/2022

function [status, results]=computeCofactor(a,row,col)
[R,C]=size(a);
if R~=C
    results=[];
    status=0;
else 
    a(row,:)=[];
    a(:,col)=[];
 
    cofactor=(-1)^(row+col)*(a);
    [s,results]=computeDeterminant(cofactor);
    status=1;
end

end

