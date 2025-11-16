%% 
clc
close all
clear

%% Opening CVS data

data = readtable('data.csv'); % Load the CSV data into a table 

% vehicle speed, odometry.global_filter.twist.twist.linear.x
% vehicle speed = col(58)

% Strain-gage(fr tire), rapter_dbw_interface.tire_report.fr_wheel_load 
% Strain-gage(fl tire) = col(68)
% Strain-gage(fr tire) = col(76)
% Strain-gage(rl tire) = col(84)
% Strain-gage(rr tire) = col(92)

% vehcile position, odometry.global_filter.pose.pose.position.x
% pos.x = col(31)
% pos.y = col(32)

vehicleSpeed = data{:, 58};     % Extract vehicle speed from the data

strainGageFlTire = data{:, 68}; % Extract strain-gage for front left tire
strainGageFrTire = data{:, 76}; % Extract strain-gage for front right tire
strainGageRlTire = data{:, 84}; % Extract strain-gage for front left tire
strainGageRrTire = data{:, 92}; % Extract strain-gage for front left tire

positionX = data{:, 31};        % Extract vehicle position x-coordinate
positionY = data{:, 32};        % Extract vehicle position y-coordinate


figure 
plot(positionX,positionY)
xlabel('Position X (m)');
ylabel('Position Y (m)');
title('Vehicle Position Trajectory');
grid on;


%% data anylisis

%lap one stright away constant vel

% lap 1, 56500, +4000
% lap 2, 85600, +2800
% lap 3, 110250,+3200
% lap 4, 133100,+3000
% lap 5, 156200,+2400
% lap 6, 178800,+2200

areo_data = [0 0];
if true
    figure 
    
    start_pos = 21000;
    add = 2000;
    end_pos   = start_pos+add;
    
    plot(positionX,positionY)
    hold on
    for i = start_pos:end_pos
        plot(positionX(i,1),positionY(i,1),"*")
        hold on
       
    end
    xlabel('Position X (m)');
    ylabel('Position Y (m)');
    title('Vehicle Position Trajectory');
    grid on;

end
%
% lap 1, 56500, +4000: 71000, +2600
% lap 2, 85600, +2800: 98200, +1300
% lap 3, 110250,+3200: 121700,+1300
% lap 4, 133100,+3000
% lap 5, 156200,+2400
% lap 6, 178800,+2200
lap_data = [21000 2000;
            30000 2000;
            38700 3000;
            56500 4000;
            71000 2600;
            85600 2800;
            98200 1300;
            110250 3200;
            121700 1300
            133100 3000;
            156200 2400;
            178800 2200];

% lap_data = [21000 2000;
%             30000 2000;
%             38700 3000;
%             56500 4000;
%             71000 2600;
%             85600 2800;
%             98200 1300;
%             110250 3200;
%             133100 3000];

for k = 1:length(lap_data)
    figure
    tiledlayout(2,1)
    nexttile
    legends = true;
    n = 0;

    start_pos = lap_data(k,1);
    end_pos = start_pos+lap_data(k,2);

    for i = start_pos:end_pos
        if isnan(strainGageFlTire(i-1,1)) 
           
        elseif isnan(positionX(i,1))
    
        elseif isnan(vehicleSpeed(i,1))
        
        else
        n = n+1;
        plot(i, strainGageFlTire(i-1,1),'.','Color',[1 0.5 0])
        fl_normal_force(n,1) = strainGageFlTire(i-1,1);
        hold on
        plot(i, strainGageRlTire(i-1,1),'.','Color',[0 1 1])
        rl_normal_force(n,1) = strainGageRlTire(i-1,1);
        hold on
        plot(i, strainGageFrTire(i-1,1),'.','Color',[0.2 1 0.2])   
        fr_normal_force(n,1) = strainGageFrTire(i-1,1);
        hold on
        plot(i, strainGageRrTire(i-1,1),'.','Color',[0.7 0.2 1])  
        rr_normal_force(n,1) = strainGageRrTire(i-1,1);
        hold on
    
        if legends
            legend("fl tire load","fr tire load","rl tire load","rr tire load")
            legend('AutoUpdate','off');
            legends = false;
        end
            
        end
        
    end
    
    
    nexttile
    legends = true;
    n=0;
    for i = start_pos:end_pos
        if isnan(strainGageFlTire(i-1,1)) 
           
        elseif isnan(positionX(i,1))
    
        elseif isnan(vehicleSpeed(i,1))
        
        else
        n=1+n;
        hold on
        plot(i,vehicleSpeed(i,1),'.','Color',[1 0 0])
        vehicle_vel(n,1) = vehicleSpeed(i,1);
    
    
        if legends
            legend("lap 1, vehcile speed")
            legend('AutoUpdate','off');
            legends = false;
        end
            
        end
        
    end
    %
    % figure
    % Netforce = fl_normal_force+fr_normal_force+rl_normal_force+rr_normal_force - (4400+3770+3525+3425);
    % L = length(Netforce);
    % plot(1:L,Netforce)
    
    
    N_fl = mean(fl_normal_force);
    N_rl = mean(rl_normal_force);
    N_fr = mean(fr_normal_force);
    N_rr = mean(rr_normal_force);
    
    % Calculate the total normal force
    Netforce_avg = N_fl + N_fr + N_rl + N_rr - (4400+3770+3525+3425)
    v_x = mean(vehicle_vel);
    
    areo_data(k+1,1) = Netforce_avg;
    areo_data(k+1,2) = v_x;
end


%% plotting doen force vs velocity


figure
plot(areo_data(:,2),areo_data(:,1),".-")

V2 = areo_data(:,2).^2;
p = polyfit(V2, areo_data(:,1), 1);     % p(1) ~ k, p(2) ~ offset
k = p(1);


X = V2.^2;          
c = V2 \ areo_data(:,1);        

hold on
plot(areo_data(:,2),areo_data(:,2).^2 * k )
hold on
plot(areo_data(:,2),areo_data(:,2).^2 * c )
ACdK = k*2/ 1.225;
ACdC = c*2/1.225;


%% orrrr

areo_data([5 7 9 11 12 13], :) = [];


figure
plot(areo_data(:,2),areo_data(:,1),".-")

V2 = areo_data(:,2).^2;
p = polyfit(V2, areo_data(:,1), 1);     % p(1) ~ k, p(2) ~ offset
k = p(1);


X = V2.^2;          
c = V2 \ areo_data(:,1);        

hold on
plot(areo_data(:,2),areo_data(:,2).^2 * k )
hold on
plot(areo_data(:,2),areo_data(:,2).^2 * c )
ACdK1 = k*2/ 1.225;
ACdC1 = c*2/1.225;

