function [ L, U , P]=luDecomposition(A)
[R,C]=size(A);

pivot=abs(A(:,1));
p1=pivot;

x=1;
B=A;
P=eye(R,C);
I=P;
MM=ones(R,1);

% while x<C
%  
%     M= pivot==max((p1));% max(p1): locates max number in p1, 
%     %pivot==max(p1): checks where the max number is located 
%     % M stores the information of Pivot=max(p1) in a logical array
%      
%      if M==MM
%      elseif sum(M)>1
%      else
%     B(x,:)=B(M,:);
%      B(M,:)=A(x,:);
% I(x,:)=I(M,:);
% 
% I(M,:)=P(x,:);
% 
%      end
%      if x==R
% x=x+1;
%      else
%           B(x,:)=0;
%  x=x+1;
%      pivot= abs(B(:,x));
% p1=pivot;
%      end
% 
%    
% end 
w=1;
Z=eye(R,R);
%finding P
for i=1:R
    [Max,w]=max(abs(A(i:R,i)));
    %this Locates max number and row it is in
    row=A(i,:);%replaing rows;
    zow=Z(i,:);
    A(i,:)=A(w-1+i,:);%replacing row to top
    Z(i,:)=Z(w-1+i,:);
    Z(w+i-1,:)=zow;
    A(w+i-1,:)=row;%Now we set row to new row
end

  PA=A;
[L,U]=gaussianElimination(PA);
P=Z;
end

