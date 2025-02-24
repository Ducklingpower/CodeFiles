clc
clear
close all

T = readtable("Folds5x2_pp.ods");

AT = table2array(T(:,1));
V  = table2array(T(:,2));
AP = table2array(T(:,3));
RH = table2array(T(:,4));
PE = table2array(T(:,5));

all = zeros(9568+9568+9568,1);
PE2 = zeros(9568+9568+9568,1);
for k =1:38272
    if k<=9568
         all(k,1) = AT(k);
    elseif k == 9569 || k<=19136
        all(k,1) = V(k-9568);
    elseif k == 19137 || k<=28704
       all(k,1) = RH(k-19136);
%     else
%         all(k,1) = RH(k-28704);
    end

end

for k =1:38272
    if k<=9568
         PE2(k,1) = PE(k);
    elseif k == 9569 || k<=19136
        PE2(k,1) = PE(k-9568);
    elseif k == 19137 || k<=28704
       PE2(k,1) = PE(k-19136);
%     else
%         PE2(k,1) = PE(k-28704);
    end

end


rms= zeros(1,4);

figure(1)
tiledlayout(2,2)
mdl = fitlm(AT,PE);
hold on
nexttile
plot(mdl)
set(gca,'color',[.5 .5 .5])
grid on
rms(1,1) = mdl.Rsquared.Adjusted;

mdl = fitlm(V,PE);
nexttile
plot(mdl)
set(gca,'color',[.5 .5 .5])
grid on
rms(1,2) = mdl.Rsquared.Adjusted;

nexttile
mdl = fitlm(AP,PE);
hold on
plot(mdl)
 set(gca,'color',[.5 .5 .5])
grid on

rms(1,3) = mdl.Rsquared.Adjusted;

nexttile
mdl = fitlm(RH,PE);
hold on
plot(mdl)
 set(gca,'color',[.5 .5 .5])
grid on

figure(2)
mdl2 = fitlm(all,PE2);
hold on
plot(mdl2)
 set(gca,'color',[.5 .5 .5])
grid on
rms2 = mdl2.Rsquared.Adjusted;


rms(1,4) = mdl.Rsquared.Adjusted;
rms =  rms';
fprintf("The R squared for each data set in order is \n")
fprintf("%d \n ",rms(1,1))
fprintf("%d \n ",rms(2,1))
fprintf("%d \n ",rms(3,1))
fprintf("%d \n ",rms(4,1))

fprintf("The R squared for the multi varible linear regression data set is \n")
fprintf("%d \n ",rms2(1,1))
