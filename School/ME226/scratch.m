clc
clear
close all

p = 20000;
i = 0.00001;
n = 60;
A = 412.02;

p1 = 1000000;
while p <  p1
i =i+0.000001;
    p1 = A*((i+1)^(n)-1)/(i*(i+1)^(n));
    
end


%%
clc
clear
close all

p = 500000*0.25;
n =0;
po = 0;
while p > po 

     n = 1+n;
    po = 2387.08*(((0.003333+1)^n-1)/(0.003333*(1.003333)^n));

    error = abs(p-po);
end

%%


clc
clear
close all
A = 1610.45;
I = 0.012552257;
p = 300000;
po=0;

n=0;
while p > po 

     n = 1+n;
     P1  =      A*(((I+1)^n)-1)/(I*(I+1)^n);
     P2  =      A*(((I+1)^n)-1)/(I*(I+1)^n);
     P3  = 1.25*A*(((I+1)^n)-1)/(I*(I+1)^n);

     po = P1+P2+P3;

end

n=3*(n-1);



%%

clc 
close all
clear

% Given values
building_cost = 8000000; % Present worth cost of building
furnishing_cost = 800000; % Initial furnishing cost, replaced every 5 years
furnishing_replacement_interval = 5; % Replacement interval for furnishings in years
annual_OM_cost = 800000; % Annual operating and maintenance costs
room_rate = 60; % Room rate per day
occupancy_rate = 0.80; % Average daily occupancy rate
num_units = 200; % Number of motel units
days_per_year = 365; % Number of operating days per year
planning_horizon = 15; % Planning horizon in year
MARR = 0.12; % Minimum Acceptable Rate of Return (12%)
salvage_value_percentage = 0.15; % Salvage value percentage of original building cost
furnishing_salvage_value = 0; % No salvage value for furnishings

% Step 1: Calculate total annual revenue from room rentals
annual_revenue = room_rate * num_units * days_per_year * occupancy_rate;

% Step 2: Calculate Present Worth (PW) of all costs and revenues
% PW of operating and maintenance costs (annual series)
PW_OM_costs = annual_OM_cost * ((1 - (1 + MARR)^-planning_horizon) / MARR);

% PW of revenue (annual series)
PW_revenue = annual_revenue * ((1 - (1 + MARR)^-planning_horizon) / MARR);

% PW of furnishing replacements (single payments at year 5 and 10)
PW_furnishing_replacements = 0;
for i = furnishing_replacement_interval:furnishing_replacement_interval:planning_horizon-1
    PW_furnishing_replacements = PW_furnishing_replacements + furnishing_cost / (1 + MARR)^i;
end

% PW of salvage value of building (at year 15)
salvage_value = salvage_value_percentage * building_cost;
PW_salvage_value = salvage_value / (1 + MARR)^planning_horizon;

% Total Present Worth (revenues minus costs and expenses)
total_PW = PW_revenue - (building_cost + PW_OM_costs + PW_furnishing_replacements - PW_salvage_value);

% Display the result
fprintf('The Equivalent Present Worth (EPW) is: $%.2f\n', total_PW);

