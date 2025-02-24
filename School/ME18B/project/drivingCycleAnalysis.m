
function stats=drivingCycleAnalysis(parameters,time,speeds)
stats=[0;0;0;0;0;0;0;0;0];




%---------------if statments----------------------------------------

if parameters(5)=="gasoline"
EFF=0.25;
hv=45;
D=730;
elseif parameters(5)=="diesel"
    EFF=0.25;
    hv=45;
    D=850;
elseif parameters(5)=="naturalgas"
EFF=0.25;
hv=50;
D=0.68;
elseif parameters(5)=="electric"
    EFF=0.8;
    D=730;
end
%----------------------values----------------------------------------


m=str2double(parameters(1));  %mass of car
A=str2double(parameters(2));  %frontal area of car
dg=str2double(parameters(3)); %drag coeficant
u=str2double(parameters(4));  %rolling friction
p=1.204;
g=9.81;           % accaloration due to gravity


%----------------------question 1-------------------------------------


distance=0;
for i=1:length(speeds)-1
tt=time(i+1)-time(i);
tt=tt/3600;
a=(speeds(i+1)-speeds(i))/tt;
distance=distance+(speeds(i)*tt+0.5*a*(tt^2));
end
stats(1)=distance;

%----------------------question 2--------------------------------------
F=zeros(length(speeds),1);
acc=zeros(length(speeds),1);

accel=diff(speeds)./diff(time);
for i=1:length(speeds)-1
tt=time(i+1)-time(i);%s
tt=tt/3600;%hours
a=(speeds(i+1)-speeds(i))/tt;%
a=(a)*(1609.344)*(1/3600)*(1/3600);%m/s^2
acc(i)=a;
if a>=0
else
    a=0;
end
v=speeds(i) /2.237; %converted to meters per sec
F(i)=(m*a)+(0.5*p*dg*A*(v^2))+(u*m*g);%N
F(i)=F(i)/1000;

end
n=find(F==max(F));
F=max(F);
stats(2)=F;

%--------------------------question 3-----------------------------------

% V=speeds(n)/2.237;%speed that corrilats to max force
% F=F*1000;
% maxpower=F*V;
% maxpower=maxpower/10;%convert to kW
F=zeros(length(speeds),1);
acc=zeros(length(speeds),1);
pp=zeros(length(speeds),1);
for i=1:length(speeds)-1
tt=time(i+1)-time(i);%s
tt=tt/3600;%hours
a=(speeds(i+1)-speeds(i))/tt;%
a=(a)*(1609.344)*(1/3600)*(1/3600);%m/s^2
acc(i)=a;
if a>=0
else
    a=0;
end
v=speeds(i) /2.237; %converted to meters per sec
F=(m*a)+(0.5*p*dg*A*(v^2))+(u*m*g);%N

pp(i)=(F*v)/1000;
end
maxpower=max(pp);

stats(3)=maxpower;


%----------------------question 4------------------------------------
n=length(time);
power=zeros(1,n);
E=0;

for i=1:n-1
tt=time(i+1)-time(i);%s
tt=tt/3600;%hours
a=(speeds(i+1)-speeds(i))/tt;%
a=(a)*(1609.344)*(1/3600)*(1/3600);%m/s^2
if a>=0
else
    a=0;
end
v=speeds(i) /2.237; %converted to meters per sec
F=(m*a)+(0.5*p*dg*A*(v^2))+(u*m*g);%N
    power(i)=(F*v);
end

for i=1:n-1
   E=(0.5*(power(i)+power(i+1))*(time(i+1)-time(i)))+E;
end

stats(4)=(E/1e+6)/EFF;


%---------------------------question 5------------------------------------
if parameters(5)=="electric"
    gallons=(stats(4))*(1/3.6)*(1/33.7);
   stats(5)=D*(gallons/264.2);
else
fultot=(stats(4))/hv;
stats(5)=fultot;
end
%------------------------question 6--------------------------------------
if EFF==0.8
    gallons=stats(4)*(1/3.6)*(1/33.7);
    stats(6)=gallons;
else
gallons=(fultot/D)*(264.172);
stats(6)=gallons;
end

%--------------------------question 7-------------------------------------
stats(7)=distance/gallons;

%--------------------------question 8--------------------------------------
stats(8)=(gallons*8887)/distance;

%-------------------------question 9--------------------------------------
stats(9)=gallons*8887;


