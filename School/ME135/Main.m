clc
close all
clear
%% Extracting input data

% Define temperature range in Fahrenheit
temperatures_F = 0:1:150;

% Convert temperatures to Celsius
temperatures_C = (temperatures_F - 32) * 5 / 9;

% Antoine equation constants for water
A = 8.07131;
B = 1730.63;
C = 233.426;

% Calculate pressure in mmHg using Antoine equation
pressures_mmHg = 10 .^ (A - (B ./ (C + temperatures_C)));

% Convert pressure to bar (1 mmHg = 0.00133322 bar)
pressures_bar = pressures_mmHg * 0.00133322;

% Combine temperature and pressure into a table
water_table = table(temperatures_F', pressures_bar', ...
    'VariableNames', {'Temperature_F', 'Pressure_bar'});

% Display the table
disp(water_table);

% Optionally, save the table to a file
writetable(water_table, 'WaterSaturationTable.csv');


%% 

Outside = readtable("OutSideData.xlsx");
Out = table2array(Outside);

To  = Out(:,1);
HRo = Out(:,2)./100;
Po  = Out(:,3).*3386.39;

for i = 1:length(Out(:,3))
    checker = isnan(Po);
    if checker(i) ==1
        Po(i) = Po(i-1);
    else
    end

end

for i = 1:length(Out(:,1))
checker = isnan(To);
    if checker(i) == 1
        To(i) = To(i-1);
    else
    end
end

for i = 1:length(Out(:,2))
checker = isnan(HRo);
    if checker(i) == 1
        HRo(i) = HRo(i-1);
    else
    end
end


%% Solving for outside states
% Solving for Psat

Psat_o = zeros(length(To),1);
for i = 1:length(To)

Tcurrent = To(i);
finder = find(Tcurrent==temperatures_F);
Psat_o(i) = pressures_bar(finder)*10^5;

end

% To, pvo, wo, ho, vo

% Temp F to C
for i = 1:length(To)
To(i) = (To(i) - 32) * 5/9 ;
end

wo = zeros(length(To),1);
wo_sat = zeros(length(To),1);
ho = zeros(length(To),1);
vo = zeros(length(To),1);

for i = 1:length(Psat_o)
       
    pvo = Psat_o(i)*HRo(i);
    delta = Po(i) - pvo;
     
    if delta ==0
        wo(i) =0;
        wo_sat(i) = 0;
    else 
        wo(i) = 0.622*((pvo)/(delta));
        wo_sat(i) = 0.622*((Psat_o(i))/(Po(i)-Psat_o(i)));
    end

    ho(i) = 1005*To(i)+wo(i)*(2500+1.9976*To(i));
    vo(i) = ((To(i)+273)*(1+wo(i)))/((pvo/462)+((Po(i)-pvo)/287));
    vo(1)= 0.8299;


    Vdot = 1.903/60;
    Vdot = 600/3600;
    mdot(i) = Vdot/vo(i);

end


%% all states


%Master For loop


for i = 1:length(To)

    if 22<= To(i) && To(i)<= 26  % off calculates


    %states inside calcs
    wi(i) = 0;
    hi(i) = 0;
    Ti(i) = To(i);

    %states 1 calcs
    w1(i) = 0;
    h1(i) = 0;

    %states 3 calcs 
    x(i) = 0;
    w3(i) = 0;

    %heating loads

    Qc(i) = 0;
    Qh(i) = 0;
    Qs(i) = 0;
    Ql(i) = 0;


    %
    Hum(i) = 0;
    else % On Calculations


    %State in calcs 

    if 22>= To(i) % 22C
    Tcurrent = 22;
    finder = find(Tcurrent==temperatures_F);
    Psat = pressures_bar(finder)*10^5;
    pvi = Psat*0.5;
    wi(i) = (pvi)/(Po(i)-pvi);
    hi(i) = 1005*Tcurrent+wi(i)*(2500+1.996*To(i));
    Ti(i) = 22;

    % cooling load
    Qh(i) = mdot(i)*(hi(i)-ho(i));
    Qc(i) = 0;
    Qs(i) = (1005+wi(i)*1.996)*(To(i)-Ti(i));
    Ql(i) = Qc(i) - Qs(i);


    elseif 26<=To(i)
    Tcurrent = 26;
    finder = find(Tcurrent==temperatures_F);
    Psat = pressures_bar(finder)*10^5;
    pvi = Psat*0.5;
    wi(i) = (pvi)/(Po(i)-pvi);
    hi(i) = 1005*Tcurrent+wi(i)*(2500+1.996*To(i));
    Ti(i) = 26;

    %Heating load
    Qh(i) = 0;
    Qc(i) = mdot(i)*(ho(i)-hi(i));
    Qs(i) = (1005+wi(i)*1.996)*(Ti(i)-To(i));
    Ql(i) = Qh(i) - Qs(i);



    else 
    Tcurrent = To(i);
    finder = find(Tcurrent==temperatures_F);
    Psat = pressures_bar(finder)*10^5;
    pvi = Psat*0.5;
    wi(i) = (pvi)/(Po(i)-pvi);
    hi(i) = 1.005*Tcurrent+wi(i)*(2500+1.996*To(i));


    end 




    % Calcs for state 1
   
    if wo_sat(i) <= wi(i)

        h1(i) = hi(i);
        w1(i) = wo_sat(i);

        hum(i) = mdot(wo(i)-wi(i));

    else 
        h1 = 1.005*To(i)+wi(i)*(2500+1.997*To(i));
        w1(i) = wi(i);
        hum(i) = 0;
        hum(i) = mdot(i)*(wo(i)-wi(i));
    end


    % Cacls for states 3 (after coil)

    if 22>= To(i)
       T2 = 65;
       T1 = To(i);
       T3 = 22;
       x(i) = (T3-T2)/(T1-T2);


    elseif 26<=To(i)
       T2 = 15;
       T1 = To(i);
       T3 = 22;
       x(i) = (T3-T2)/(T1-T2);

    end

    if To(i) <=22
    w3(i) = w1(i);

    elseif To(i)>=26
    finder = find(T2==temperatures_F);
    Psat2 = pressures_bar(finder)*10^5;
    w2 = 0.622*(Psat2)/(Po(i)-Psat2);
    w3(i) = x(i)*(w1(i)-w2)+w2;

    hum(i) = mdot(i)*(w2-w3(i));

    end

   
    end
end

%%
close all
for i = 1:length(To)
Upper(i) = 26;
lower(i) = 22;
end

interval = [0 length(To)]; %[hrs hrs]



figure(Name = "test")
plot(1:length(To),w1,".");
hold on
plot(1:length(To),w3,".");
ylim([0 0.003])
xlabel("Time (hrs)")
ylabel("Realitive Huminity")
legend("\omega_1 state 1","\omega_3 state 3")


figure(Name = "X")
tiledlayout(2,1)
nexttile
plot(1:length(To),x,"*")
title("Bypass Factor vs time")
xlabel("Hrs")
ylabel("Bypass ratio")
xlim(interval)
nexttile
plot(1:length(To),To)
Ti_mean = movmean(Ti,12);
hold on
plot(1:length(To),Upper,".","Color","Black")
hold on
plot(1:length(To),lower,".","Color","Black")
hold on
plot(Ti_mean,LineWidth=3,Color="#D95319")
title("Temp vs Hrs")
hold on
xlim(interval)
xlabel("Hrs")
ylabel("Outside Temp")
legend("Outside Temp","Upper bound (Inside temp max = 26^o C)","Lower bound (Inside temp min = 22^o C)","Temp inside (6 hr, moving mean average)")


figure(name="inside temp")
plot(1:length(Ti),Ti)
To_mean = movmean(Ti,24*14);
hold on
plot(1:length(Ti),To_mean,"*",LineWidth = 2)
ylim([21.8,26.2])
xlabel("Hrs")
ylabel("Inside Temp")
legend("Temp inside","2 week mean moving averge Inside Temp")

for i = 1:length(ho)
delat_h(i) = ho(i)-hi(i);
end

%% Energy stuff
close all

Qc = Qc./2.4;
Qh =Qh./3.04;

nexttile
figure(Name = "Colling loads")
plot(1:length(To),Qc,Linewidth = 2)
grid on
xlabel("Time (hr)")
ylabel("Cooling load in W")
legend("Cooling load")

Qh(1) = 0;
figure(Name = "Heating loads")
plot(1:length(To),Qh,LineWidth=2)
grid on
xlabel("Time (hr)")
ylabel("Heating load in W")
legend("Heating load")



%% Total energy used 
QQ=0;
for i =1:length(To)
QQ = Qh(i)+ Qc(i);
Qtot(i) = QQ;
end

figure(Name = "total power")
plot(1:length(To),Qtot,LineWidth=2)
grid on
xlabel("Time (hr)")
ylabel("total sum of load in W")
legend("Total Power")

%% energy calc
x = 1:length(To);
energy = trapz(x,Qtot);


%% huminification

figure(Name = "huminification")
hum(1) = 0;
plot(1:length(To),hum,LineWidth=2)
grid on
xlabel("Time (hr)")
ylabel("m_f")
legend("M_f")

%% money calc 

% numeric integral

for i = 1:length(To)
Qch(i) = Qc(i)+Qh(i);
end

for i = 1:length(To)
Money(i) = Qch(i)*3600;
end

for i = 1:length(To)
Money(i) = (Money(i)/(3.6*10^6))*0.1729;
end

figure(Name = "Money")
plot(Money,linewidth=2)
grid on
ylabel("Money (USD)")
xlabel("hrs")

figure(Name = "Money")

sum = 0;
for i =1:length(To)
    sum = sum+Money(i);
Money_tot(i) = sum;
end

plot(Money_tot,linewidth=2)
grid on
ylabel("Money (USD)")
xlabel("hrs")
legend("Money total ")


% Money per month
sum= 0;
for i = 1:12

    if i == 1
    month = Money(1:24*30);
    else
    month = Money(24*30*(i-1):24*30*i);
    end
    n = 0;
    sum = 0;
    for j =1:length(month)
    n = month(j);

    sum = n+sum;
    
    end
    MoneyMonth(i) = sum;
end


%%



% Money_Month = [sum(Money(1:24*30));
%                sum(Money(24*30:24*30*2));
%                sum(Money(24*30*2:24*30*3));
%                sum(Money(24*30*3:24*30*4));
%                sum(Money(24*30*4:24*30*5));
%                sum(Money(24*30*5:24*30*6));
%                sum(Money(24*30*6:24*30*7));
%                sum(Money(24*30*7:24*30*8));
%                sum(Money(24*30*8:24*30*9));
%                sum(Money(24*30*9:24*30*10));
%                sum(Money(24*30*10:24*30*11));
%                sum(Money(24*30*11:24*30*12))];









