function eq=areMatrixEqual(a,b)

[numr,ncolums]= size (a);
eq=true;
for i=1:numr
for j=1:ncolums
    if a(i,j)~=b(i,j)
        eq=false;
        break;
       
    end
end
if eq==false
    break;
end
end