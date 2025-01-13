%862274334
%perez, elijah
%Me18A assignment 4
%10/25/2022
function [rootX,rootY,error,iterations]= newtonRaphsonMethod (f,fprime,iguess,tol,maxIter)
err=2;
x0=iguess;%this is xi

curIter=0;
while err>tol && curIter <= maxIter

x01=f(x0);%this isf(xi)
x02=fprime(x0);%this f'(xi)
x1=x0-(x01/x02);%this is xi+1
err=abs((x1-x0)/x1);
x0=x1;
curIter=curIter+1;
end
rootX=x0;
rootY=f(x0);
error=err;
iterations=curIter-1;

end



