function d=myDeterminant(A)
[L,U,P]=luDecomposition(A);
[R,C]=size(L);
detL=1;
for i=1:R
   detL= L(i,i)*detL;
end
detU=1;
[RR,CC]=size(U);
for i=1:RR
    detU=U(i,i)*detU;
end



[r,c]=size(A);
R=1;
Z=eye(r,r);
%finding P
x=0;
for i=1:r
    [Max,R]=max(abs(A(i:r,i)));
    %this Locates max number and row it is in
    row=A(i,:);%replaing rows;
    zow=Z(i,:);
    
    A(i,:)=A(R-1+i,:);%replacing row to top
    Z(i,:)=Z(R-1+i,:);
    Z(R+i-1,:)=zow;
    A(R+i-1,:)=row;%Now we set row to new row
    if R+i-1>R
        x=x+1;
    end
end
[I,J]=size(P);
PP=eye(I,J);
C=0;
for i=1:J

    if P(i,i)~=PP(i,i)
C=C+1;
    end
end

d=detL*detU*(-1)^(C+1);
end


