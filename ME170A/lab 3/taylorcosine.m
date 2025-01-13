% 862274334
%perez elijah
%Me 18A assignment 3
%october 17 2022

function [val,nsteps]=taylorcosine(x,tal)
n=0;
error=1;
val=0;
nsteps=0;
while error >= tal
    %taylor poly of cos
   
    val= val+ ((-1)^(n)*((x)^(2*n)))/(factorial(2*n));
     n=n+1;
error=abs(((val)-(cos(x)))/(cos(x)));
nsteps= nsteps+1;
end

end

%x=cos(x)

