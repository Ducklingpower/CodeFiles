function row_ech_form=gaussElimination(a)
[R,C]=size(a);
for i=1:R
a(i,:)=a(i,:)/a(i,i);
for j=1:R-i
a(j+i,:)=a(j+i,:)-a(j+i,i)*a(i,:);
end
end
row_ech_form=a;
end