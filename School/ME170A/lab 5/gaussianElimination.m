%862274334
%perez Elijah
%Me18A
%10/31/2022
% % function row_ech_form=gaussianElimination(a)
% % [R,C]=size(a);
% % for i=1:R
% % a(i,:)=a(i,:)/a(i,i);
% % for j=1:R-i
% % a(j+i,:)=a(j+i,:)-a(j+i,i)*a(i,:);
% % end
% % end
% % row_ech_form=a;
% % end
function [U]=gaussianElimination(a)
[R,C]=size(a);
K=eye(R);

    for j=1:R-1
        for i= j:R-1
            K(i+1,j)=a(i+1,j)/a(j,j);
            a(i+1,:)=a(i+1,:)-K(i+1,j)*a(j,:);
        end 
    end
U=a;

end