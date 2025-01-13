%862274334
%perez, elijah
%Me18A assignment 4
%10/25/2022

function [status, results]=multiplyMatrices(a,b)
[R,C]=size(a);
[Rb,Cb]=size(b);
M=zeros(R,Cb); %creats a matrix with (0,0) so we can add later
%Z=0;
if C~=Rb
    results=[];
    status=0;
else
    status=1;
for x=1:R
    for i=1:Cb
        for j=1:C
            
        M(x,i)=M(x,i)+a(x,j)*b(j,i);      
       
        end
    end
end
    results=M;
end

end

