function P = cubicSplineCoefficients(x,y)
n=length(x);
N=n-1;
b=zeros(4*N,1);
A=zeros(4*N,4*N);
for i=1:n-1
    A(i,4*i)=1;
    b(i,1)=y(1,i);
    h=x(i+1)-x(i);
    for j=1:3
        A((n-1)+i,4*(i-1)+j)=h^(4-j);
    end
    a=y(i+1)-y(i);
    b((n-1)+i,1)=a;
end

for i=1:n-2
    h=x(i+1)-x(i);
    for j=1:3
        A(2*(n-1)+i,j+4*(i-1))=(4-j)*(h)^(3-j);
    end
    A((n-1)*2+i,4*(i+1)-1)=-1;
    for k=1:2
        A(3*(n-1)+i-1,(i-1)*4+k)=(4-k)*((h)^(2-k))*(3-k);
    end
    A(3*(n-1)+i-1,4*(i+1)-2)=-2;
end

A(4*(n-1)-1,1)=1;
A(4*(n-1)-1,5)=-1;
A(end,end-7)=1;
A(end,end-3)=-1;

sp=A\b;
sp=reshape(sp,4,n-1);
coefs=sp';
P.form='pp';
P.breaks =x;
P.coefs=coefs;
P.pieces=n-1;
P.order=n;
P.dim=1;



% n=length(x)-1;%number of segments
% A=zeros(n*4,n*4);
% 
% %puting a in patrics
% for i=1:4:n*4
%     A(i,i)=1;
% end
% 
% %puting a b c d in matrix
% m=1;
% for i=2:4:n*4
% for j=1:4
% 
% A(i,m)=1;
% m=m+1;
% end
% end
% 
% %puting in b 2c 3d 
% m=0;
% for i=3:4:n*4-4
%     p=1;
%     for j=1:3
%       m=m+1+p;  
%     bcd=[1 2 3];
%     A(i,m)=bcd(j);
% 
%     p=0;
%     end
% end
% 
% for i=3:4:n*4-4
% A(i,i+3)=-1;
% end
% % putting in c d in matrix
% m=0;
% for i=4:4:n*4-4
%     p=2;
%     
%     for j=1:2
%         m=m+1+p;
%     cd=[2,6];
%     A(i,m)=cd(j);
%     p=0;
%     end 
% end
% for i=4:4:n*4-4
% A(i,i+3)=-2;
% end
% % last 2 rows
% % A(n*4-1,3)=2;
% % A(n*4-1,4)=6;
% % A(n*4,n*4)=6;
% % A(n*4,n*4-1)=2;
% 
% A(n*4-1,4)=1;
% A(4*n-1,8)=-1;
% A(4*n,4*n-4)=1;
% A(4*n,4*n)=-1;
% 
% %solving for B
% B=zeros(n*4,1);
% B(1,1)=y(1);
% B(2,1)=y(2);
% q=1;
% Q=2;
% 
% 
% 
% for i=2:length(y)-1
% 
%   q=q+4;
%   k=0;
%     for j=q:q+1
% 
% B(j,1)=y(i+k);
% k=1;
%     end
% end
% 
% coefs=A\B;
% sp.coefs = coefs;
% sp.breaks = x;




