% 862274334
%perez elijah
%Me 18A assignment 3
%october 17 2022


function Ma =computeMachNumber(A,k)
ma= 5; %initial guess for fzero

 %a=1/x;
% b=((2/(k+1))*(1+((k-1)/2)*x^2))^((k+1)/(2*(k-1)));
%c=(A);
%f=@(x) a*b-c
f=@(ma) (1./ma).*((2/(k+1))*(1+((k-1)/2)*ma.^2)).^((k+1)/(2*(k-1)))-A;
Ma=fzero(f,ma);



end