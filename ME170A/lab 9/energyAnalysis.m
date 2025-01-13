%% lab9 problem 1
T=readtable("energydata.xlsx");
%% part 1
data=T{:,:};

varibls=T.Properties.VariableNames;

year= data(:,1);
energy=data(:,2:end);

totalenergy=sum(energy');%total energy of all energy for each year
plot(year,totalenergy)
title('energy generated 2000-2020')

xlabel('year')
ylabel('total energy')


% part 2
coel=energy(:,1);
petrol=energy(:,2);
natural=energy(:,3);
other=energy(:,4);
nuclear=energy(:,5);
hydro=energy(:,6);
wood=energy(:,7);
waste=energy(:,8);
geothermal=energy(:,9);
solar=energy(:,10);
wind=energy(:,11);

fossil=[coel petrol natural other];
renewable=[hydro wood waste geothermal solar wind ];
energtype={'Fossle fuels','Nuclear power','renewable energy'};

figure 
tiledlayout(2,2)
pie(nexttile,[sum(fossil(1,:)) nuclear(1,:) sum(renewable(1,:))],energtype)
pie(nexttile,[sum(fossil(end,:)) nuclear(end,:) sum(renewable(end,:))],energtype)

pie(nexttile,[coel(1,:) petrol(1,:) natural(1,:) other(1,:) hydro(1,:) wood(1,:) waste(1,:) geothermal(1,:) solar(1,:) wind(1,:) nuclear(1,:)])
pie(nexttile,[coel(end,:) petrol(end,:) natural(end,:) other(end,:) hydro(end,:) wood(end,:) waste(end,:) geothermal(end,:) solar(end,:) wind(end,:) nuclear(end,:)])

%%noticed in increase in renuable energy
 

%% part3
%total energy produce in 20 years

totcoel=sum(energy(:,1));
totpetrol=sum(energy(:,2));
totnatural=sum(energy(:,3));
totother=sum(energy(:,4));
tothydro=sum(energy(:,6));
totwood=sum(energy(:,7));
totwaste=sum(energy(:,8));
totgeothermal=sum(energy(:,9));
totsolar=sum(energy(:,10));
totwind=sum(energy(:,11));
% here are the total energy produced in 20 years in fossil fueles. nuclear
% and renweable.

totnuclear=sum(energy(:,5));
totfossle=[totcoel totpetrol totnatural totother];
totrewable=[tothydro totwood totwaste totgeothermal totsolar totwind];





