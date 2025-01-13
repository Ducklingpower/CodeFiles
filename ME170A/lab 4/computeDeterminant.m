function [status, Results]=computeDeterminant(a)

[R,C]=size(a);

if R~=C
    status=0;
    Results=[];
elseif R==2
   Results= (a(1,1)*a(2,2))-(a(2,1)*a(1,2));
  
   status=1;

else
x=a(1,:);
y=a(:,1);
F=zeros(R,C)
Minor=F(x,y)-a

end

    