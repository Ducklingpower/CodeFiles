%862274334
%perez, elijah
%Me18A assignment 4
%10/25/2022
function [status, results]= subtractMatrices(a,b)
[R,C]=size(a);
[Rb,Cb]=size(b);

if R~=Rb || C~=Cb
    status=0;
    results=[];
else 
   status=1;
    for i=1:R
        for j=1:C
            X(i,j)=a(i,j)-b(i,j);
        end
    end
    results=X;
end

end