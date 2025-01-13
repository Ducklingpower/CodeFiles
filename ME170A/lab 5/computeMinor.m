%862274334
%perez Elijah
%Me18A
%10/31/2022

function [status,Results]=computeMinor(a,row,col)
[R,C]=size(a);
if R~=C
    Results=[];
    status=0;
else
a(row,:)=[];
a(:,col)=[];
[s,Results]=computeDeterminant(a);
status=1;
end
