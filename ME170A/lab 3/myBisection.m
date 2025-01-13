% 862274334
%perez elijah
%Me 18A assignment 3
%october 17 2022

function [est_root]= myBisection(f,aray,tal)

xl=aray(1);
xu=aray(2);
% xl = 1.3;
% xu = 3.0;

err=1;
xold=xl;

while err>tal
    xm= (xl+xu)/2;
xll=f(xl);
xmm=f(xm);
xuu=f(xu);

    A1=(xll)*(xmm);


    if A1<0
        xu=xm;

    else
        xl=xm;


    end


    xnew=xm;
    err=abs((xnew-xold)/(xnew));
    xold=xnew;
   
end
est_root=xm;
end


