function [L, U]=gaussianElimination(a)
[R,C]=size(a);
L=eye(R);
if R==C 
    for j=1:R-1
        for i= j:R-1
            L(i+1,j)=a(i+1,j)/a(j,j);
            a(i+1,:)=a(i+1,:)-L(i+1,j)*a(j,:);
        end 
    end
U=a;
else 
    L=[];
    U=[];
end