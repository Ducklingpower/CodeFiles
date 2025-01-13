function X=backSubstitution(U,Y)

[R,C]=size(Y);
X=zeros(R,1);
X(R)=Y(R)/U(R,R); % only for first iter
K=0;
for i=R-1:-1:1
    K=0;% reset K every new row
    for j=i+1:R
        UX=(U(i,j)*X(j));
        K=UX+K;
    end
    X(i)=(Y(i)-K)/U(i,i);
end


end