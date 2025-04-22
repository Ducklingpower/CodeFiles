clc 
close all 
clear 
%%
Data = load("lateral_tire_test.mat");
MaxSet = Data;
Test = 1;
for j = 0:4:36
    x = j;
    y = j+4;
    Set = [MaxSet.AMBTMP(1278*x + 1:1278*y) MaxSet.ET(1278*x + 1:1278*y) MaxSet.FX(1278*x + 1:1278*y) MaxSet.FY(1278*x +1:1278*y) MaxSet.FZ(1278*x + 1:1278*y) MaxSet.IA(1278*x + 1:1278*y) MaxSet.MX(1278*x + 1:1278*y) MaxSet.MZ(1278*x + 1:1278*y) MaxSet.SA(1278*x + 1:1278*y) MaxSet.SL(1278*x + 1:1278*y) MaxSet.SR(1278*x + 1:1278*y) MaxSet.V(1278*x + 1:1278*y)];
    TireData(:,:,Test) = Set(:,:);
    Test = Test+1;
end

clear vars Test x y j set

%% Averaging normal loads 

%Binning average nornal Loads 
specified = [1,2,3,4,5,6,7,8,9,10];

set1 = 1:1278;
set2 = 1278+1:1278*2;
set3 = 1278*2+1:1278*3;
set4 = 1278*3+1:1278*4;
set = 1:1278*4;

NormalLoads = zeros(length(specified),4);
NormalLoads_vect = zeros(length(specified)*4,1);


i = [1 2 3 4];
for test = 1:10 
avg1 = mean(TireData(set1,5,test));
avg2 = mean(TireData(set2,5,test));
avg3 = mean(TireData(set3,5,test));
avg4 = mean(TireData(set4,5,test));

NormalLoads(test,1) = avg1;
NormalLoads(test,2) = avg2;
NormalLoads(test,3) = avg3;
NormalLoads(test,4) = avg4;

NormalLoads_vect(i(1)) = avg1;
NormalLoads_vect(i(2)) = avg2;
NormalLoads_vect(i(3)) = avg3;
NormalLoads_vect(i(4)) = avg4;

i = i + [4 4 4 4];
end

n = 0;
for j = 1:length(specified)
test= specified(j);   

    for i = 1:4
    Load_vect(i+n,1) = NormalLoads(test,i);
    end

 n = n+4;
end

%% Manuel labor


figure 
plot(TireData(set,9,5),TireData(set,8,5),".")
grid on





%% working on adding data 

%%
clc
close all
clear

Data = load("lateral_tire_test.mat");
MaxSet = Data;
Test = 1;
for j = 0:4:36
    x = j;
    y = j+4;
    Set = [MaxSet.AMBTMP(1278*x + 1:1278*y) MaxSet.ET(1278*x + 1:1278*y) MaxSet.FX(1278*x + 1:1278*y) MaxSet.FY(1278*x +1:1278*y) MaxSet.FZ(1278*x + 1:1278*y) MaxSet.IA(1278*x + 1:1278*y) MaxSet.MX(1278*x + 1:1278*y) MaxSet.MZ(1278*x + 1:1278*y) MaxSet.SA(1278*x + 1:1278*y) MaxSet.SL(1278*x + 1:1278*y) MaxSet.SR(1278*x + 1:1278*y) MaxSet.V(1278*x + 1:1278*y)];
    TireData(:,:,Test) = Set(:,:);
    Test = Test+1;
end


% concade data




