clc
clear 
close all
%%
Data1 = readtable('Gym.xlsx','Sheet','Sheet1');
Data2 = readtable('Gym.xlsx','Sheet','Sheet2');
Data3 = readtable('Gym.xlsx','Sheet','Sheet3');
Data4 = readtable('Gym.xlsx','Sheet','Sheet4');
Data5 = readtable('Gym.xlsx','Sheet','Sheet5');

Data1(:,1) = [];
Data2(:,1) = [];
Data3(:,1) = [];
Data4(:,1) = [];
Data5(:,1) = [];

Data1 = table2array(Data1);
Data2 = table2array(Data2);
Data3 = table2array(Data3);
Data4 = table2array(Data4);
Data5 = table2array(Data5);
 

Bench2 = [Data1 Data2 Data3 Data4 Data5]

%% Input Bench DATA
Bench = zeros(4,4,52);
for i = 1:4
    for j = 1:4
Bench(i,j,1) = Data1(i,j);
    end
end

for i = 1:4
    for j = 1:4
Bench(i,j,2) = Data2(i,j);
    end
end

for i = 1:4
    for j = 1:4
Bench(i,j,3) = Data3(i,j);
    end
end

for i = 1:4
    for j = 1:4
Bench(i,j,4) = Data4(i,j);
    end
end

for i = 1:4
    for j = 1:4
Bench(i,j,5) = Data5(i,j);
    end
end

%% Plot DATA

plot(1:length(Bench2),Bench2(1,:),Linewidth=2)
hold on
plot(1:length(Bench2),Bench2(2,:),Linewidth=2)
legend("# of Reps","weight")

plot(1:length(Bench2),Bench2(1,:),Linewidth=2)



