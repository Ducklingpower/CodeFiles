function y=cubicSplineInterpolation(P,x)
y=zeros(1,length(x));
I=0;
[rr,cc]=size(P.coefs);
%need to find the xvalues that corrilate with Y values for Ax=Y
ppp=zeros(rr*cc,1);
q=0;
qq=0;
w=0;
for i=1:rr
    t=P.coefs(i,:);
    qq=qq+1;
    for j=1:4
w=w+1;
        ppp((w))=t(j);
    end
q=1;
end
   P.coefs=ppp;

for i=1:length(x)
r=find(P.breaks<x(i));
XB=r(end);

number=(XB-1)*4;

a=P.coefs(number+1);
b=P.coefs(number+2);
c=P.coefs(number+3);
d=P.coefs(number+4);
x1=(x(i)-P.breaks(XB));%/(P.breaks(XB+1)-P.breaks(XB));

y(i)=d+c*(x1)+b*((x1)^2)+a*((x1)^3);
end