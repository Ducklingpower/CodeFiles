function sum=forloop(a,b)
len=length(a);
x=0;

for i=1 :len
    x=x+(a(i)*b(i));
end
sum=x;