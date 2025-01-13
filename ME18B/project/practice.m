%function B=practice(x,y)
x=[1 5 9 11];
y=[2 10 12 15];
f=zeros(length(y),length(y));

 for j=1:length(y)
      f(1,j)=y(j);
 end
 
 
 for j=1:length(y)-1

 for i=1:length(y)-j
     f(j+1,i)=(f(j,i+1)-f(j,i))/(x(j+i)-x(i));

 end
 end
x=linspace(1,11,100);
y=f(1,1)+f(2,1).*(x-x(1))+f(3,1).*(x-x(1)).*(x-x(2))+f(4,1).*(x-x(1)).*(x-x(2)).*(x-x(3));
plot(x,y)



% for i=1:length(y)-1
%  
% f(j,i)=(y(i+1)-y(i))/(x(i+1)-x(i));
% 
% end
% end