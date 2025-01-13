clear,
clc,
close all

load("C:\HR\HR24E\24E-VD\TTC Data\MAT Files\Round 9 Cornering\RunData_Cornering_Matlab_SI_Round9\B2356run5.mat")

mechTrail = 0.005;  %meters
scrubR = 0.0254;      %meters
SteeringRT = 0.01905;  %meters
pnumatic = 0.021428; %meters
pitManT = 0.100;  %meters
%%tt=-t;
Mz2 = FY.*pnumatic;
M_kingPinAxis = (FY.*(mechTrail))+(Mz2); %N-M
force_arm = M_kingPinAxis/pitManT;
torque = force_arm*SteeringRT;
torqueraw=force_arm;


counter = 0;
A=zeros(1000,1);
xx1= zeros(length(torqueraw),1);
xx2= zeros(length(torqueraw),1);
xx3= zeros(length(torqueraw),1);
ii=1;
for i = 1:length(torqueraw)
    if i==length(torqueraw)-11
        break
    else
    x1 = torqueraw(i);
    x2 = torqueraw(i+10);
    V = abs(x1-x2);
    end
    if (769.31>torqueraw(i))&&(torqueraw(i)>=769.3)    %%target point

            for j = 1:6000                        %%iterate backwards
               x1 = torqueraw(i-j);
               x2 = torqueraw(i-j-1);        
               V1 = abs(x1-x2);
                if V1>40                         %%max dist
                    break
                    else
                end
        xx1(i-j)= torqueraw(i-j);               %%inpute values
            end




       
             for j = 1:6000
               x11 = torqueraw(i+j);
               x22 = torqueraw(i+j+1);
              V2 = abs(x11-x22);
                if V2>69.2                  %%max dist
                    break
                    else
                end
        xx1(i+j)= torqueraw(i+j);            
            end

    else
    end


end



figure
plot(SA,torque,'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

figure
plot(SA,torqueraw,'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on 

plot(SA,xx1,'Color','r','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

% hold on 
% 
% plot(SA,xx2,'Color','b','Marker','.','LineStyle',':')
% grid on 
% title('SA-torque')
% xlabel('slip angle')
% ylabel('steering torque')
% 
% hold on 
% 
% plot(SA,xx3,'Color','black','Marker','.','LineStyle',':')
% grid on 
% title('SA-torque')
% xlabel('slip angle')
% ylabel('steering torque')

