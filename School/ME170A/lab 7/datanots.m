

data=csvread('GHG.csv',1,1);
format short g

for i=1:31

    data(1,i)=1989+i;
end
sectors={'transpot','elctric','indestry','ag','commercial','res','u.s T'};
years=data(1,:);
emission=data(2:end,:);
totemission=sum(emission);
plot(years,totemission)

%pie(emission(:,end),sectors);

fid=fopen("GHG.csv",'r');
str=fgets(fid);
s{1}=str;
k=1;
while str~=-1

s{k}=str;
str=fgets(fid);
k=k+1;

end
