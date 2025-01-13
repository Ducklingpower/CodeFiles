%862274334
%perez, elijah
%Me18A assignment 4
%10/25/2022

function [status, results]= transposeMatrix(A)
[R,C]=size(A);
%Z=zeros(R,C);
status=1;
for i=1:R
    for j=1:C
        Z(j,i)=A(i,j);%switched the C and R
        results=Z;
    end
end


