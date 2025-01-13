function Y=myfactorialrecursion(x)
Y=-1;
if x==1 %this is how it knows whne to stop when x==1
    Y=1;
else

Y=x*myfactorialrecursion(x-1);%calling function in Y


end