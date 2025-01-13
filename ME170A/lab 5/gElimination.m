%862274334
%perez Elijah
%Me18A
%10/31/2022
function row_ech_form=gElimination(a)
[R,C]=size(a);
for i=1:R
a(i,:)=a(i,:)/a(i,i);
for j=1:R-i
a(j+i,:)=a(j+i,:)-a(j+i,i)*a(i,:);
end
end
row_ech_form=a;
end