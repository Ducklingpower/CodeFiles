function B=myInverse(A)
[R,C]=size(A);
Z=zeros(R);
B=zeros(R,C);
for i=1:R
    Z(i,i)=1;%finds identity matrix
end
[L,U,P]=luDecomposition(A);
%if A B=I, then AX=b

for i=1:R
    b=Z(:,i);
    %sets b to a specific Colum
    
   Y=forwardSubstitution(L,b,P);
    %solve for Y 
    %solving for x with y will give us the resulting inverse colume 
    X=backSubstitution(U,Y);
   
    B(:,i)=X;
    %now we can use X to substitute 
end

