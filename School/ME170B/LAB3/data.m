clc
clear 
close all
%% Data collection Parellel
A = 0.07139082496;
D = 0.000403225;

% Parellel flow [Hflow rates, temps, cold flow rates ]
mc1 = 0.00001892705892103;
mc2 = 0.00003154509820172;
mc3 = 0.00004416313748241;
mc = [mc1 mc2 mc3];

mh1 = 0.00001892705892103;
mh2 = 0.00002523607856138;
mh3 = 0.00003154509820172;
mh4 = 0.00003785411784206;

mh = [mh1 mh2 mh3 mh4];

Parellel = zeros(4,6,3);


%%%%%%%%%%%% Data set 1 (mc2) %%%%%%%%%%%


% data set (mh1, mc1)
Parellel(1,1,1) = 39.89 +273;
Parellel(1,2,1) = 35.475 +273;
Parellel(1,3,1) = 31.89 +273;
Parellel(1,4,1) = 23.219 +273;
Parellel(1,5,1) = 25.52 +273;
Parellel(1,6,1) = 26.85 +273;

% data set (mh2, mc1)
Parellel(2,1,1) = 41.34 +273;
Parellel(2,2,1) = 35 +273;
Parellel(2,3,1) = 33.24 +273;
Parellel(2,4,1) = 23.16 +273;
Parellel(2,5,1) = 26.5 +273;
Parellel(2,6,1) = 28.15 +273;

% data set (mh3, mc1)
Parellel(3,1,1) = 42.53 +273;
Parellel(3,2,1) = 35.8 +273;
Parellel(3,3,1) = 34.24 +273;
Parellel(3,4,1) = 23.2 +273;
Parellel(3,5,1) = 26.49 +273;
Parellel(3,6,1) = 28.8 +273;

% data set (mh4, mc1)
Parellel(4,1,1) = 42.44 +273;
Parellel(4,2,1) = 35.84 +273;
Parellel(4,3,1) = 34.35 +273;
Parellel(4,4,1) = 23.207+273;
Parellel(4,5,1) = 26.68 +273;
Parellel(4,6,1) = 29.120+273;

%%%%%%%%%%%% Data set 2 (mc2) %%%%%%%%%%%


% data set (mh1, mc2)
Parellel(1,1,2) = 42.34 +273;
Parellel(1,2,2) = 34.85 +273;
Parellel(1,3,2) = 32.14 +273;
Parellel(1,4,2) =  23.2 +273;
Parellel(1,5,2) =  24.9 +273;
Parellel(1,6,2) = 25.99 +273;


% data set (mh2, mc2)
Parellel(2,1,2) = 42.24 +273;
Parellel(2,2,2) = 35.28 +273;
Parellel(2,3,2) = 33.6 +273;
Parellel(2,4,2) =  23.09 +273;
Parellel(2,5,2) =  25.09+273;
Parellel(2,6,2) = 26.6 +273;



% data set (mh3, mc2)
Parellel(3,1,2) = 42.32 +273;
Parellel(3,2,2) = 35.4 +273;
Parellel(3,3,2) =  33+273;
Parellel(3,4,2) = 23.1 +273;
Parellel(3,5,2) =  25.32+273;
Parellel(3,6,2) =  27.04+273;



% data set (mh4, mc2)
Parellel(4,1,2) = 42.45 +273;
Parellel(4,2,2) = 35.84 +273;
Parellel(4,3,2) =  33.08+273;
Parellel(4,4,2) =  23+273;
Parellel(4,5,2) =  25.8+273;
Parellel(4,6,2) =  27.4+273;



%%%%%%%%%%%% Data set 3 (mc3) %%%%%%%%%%%



% data set (mh1, mc3)
Parellel(1,1,3) = 42.37 +273;
Parellel(1,2,3) = 34.61 +273;
Parellel(1,3,3) =  31.93+273;
Parellel(1,4,3) =  23.1+273;
Parellel(1,5,3) =  24.5+273;
Parellel(1,6,3) =  25.49+273;

% data set (mh2, mc3)
Parellel(2,1,3) = 42.38 +273;
Parellel(2,2,3) = 35.05 +273;
Parellel(2,3,3) =  32.7+273;
Parellel(2,4,3) =  23.05+273;
Parellel(2,5,3) =  24.7+273;
Parellel(2,6,3) =  25.85+273;

% data set (mh3, mc3)
Parellel(3,1,3) = 42.35 +273;
Parellel(3,2,3) = 35.35+273;
Parellel(3,3,3) =  33.20+273;
Parellel(3,4,3) =  23.03+273;
Parellel(3,5,3) =  24.87+273;
Parellel(3,6,3) =  26.21+273;

% data set (mh4, mc3)
Parellel(4,1,3) = 42.38 +273;
Parellel(4,2,3) = 35.62+273;
Parellel(4,3,3) =  33.7+273;
Parellel(4,4,3) =  23+273;
Parellel(4,5,3) =  25+273;
Parellel(4,6,3) =  26.5+273;




%% Data collection counter flow

% Parellel flow [Hflow rates, temps, cold flow rates ]
mc1 = 0.00001892705892103;
mc2 = 0.00003154509820172;
mc3 = 0.00004416313748241;

mh1 = 0.00001892705892103;
mh2 = 0.00002523607856138;
mh3 = 0.00003154509820172;
mh4 = 0.00003785411784206;

counter = zeros(4,6,3);


%%%%%%%%%%%% Data set 1 (mc2) %%%%%%%%%%%



% data set (mh1, mc1)
counter(1,1,1) = 42.5036 +273;
counter(1,2,1) = 35.3199 +273;
counter(1,3,1) = 32.4279 +273;
counter(1,4,1) = 26.9962 +273;
counter(1,5,1) = 25.056 +273;
counter(1,6,1) = 23.6414 +273;

% data set (mh2, mc1)
counter(2,1,1) = 42.2801 +273;
counter(2,2,1) = 35.9459 +273;
counter(2,3,1) = 33.5753 +273;
counter(2,4,1) = 28.3459 +273;
counter(2,5,1) = 25.8836 +273;
counter(2,6,1) = 23.6768 +273;

% data set (mh3, mc1)
counter(3,1,1) = 42.3662 +273;
counter(3,2,1) = 36.2937 +273;
counter(3,3,1) = 34.1145 +273;
counter(3,4,1) = 28.875 +273;
counter(3,5,1) = 26.2477 +273;
counter(3,6,1) = 23.5863 +273;

% data set (mh4, mc1)
counter(4,1,1) = 42.4174 +273;
counter(4,2,1) = 36.5165 +273;
counter(4,3,1) = 34.5649 +273;
counter(4,4,1) = 29.3575+273;
counter(4,5,1) = 26.5571 +273;
counter(4,6,1) = 23.6221+273;

%%%%%%%%%%%% Data set 2 (mc2) %%%%%%%%%%%


% data set (mh1, mc2)
counter(1,1,2) = 42.3754 +273;
counter(1,2,2) = 35.113 +273;
counter(1,3,2) = 32.4417 +273;
counter(1,4,2) =  25.9799 +273;
counter(1,5,2) =  24.4912 +273;
counter(1,6,2) = 23.2251 +273;


% data set (mh2, mc2)
counter(2,1,2) = 42.2623 +273;
counter(2,2,2) = 35.5424 +273;
counter(2,3,2) = 32.842 +273;
counter(2,4,2) =  26.5661 +273;
counter(2,5,2) =  24.928+273;
counter(2,6,2) = 23.3734 +273;



% data set (mh3, mc2)
counter(3,1,2) = 42.3025 +273;
counter(3,2,2) = 35.814 +273;
counter(3,3,2) =  33.4432+273;
counter(3,4,2) = 26.991 +273;
counter(3,5,2) =  25.1816+273;
counter(3,6,2) =  23.2144+273;



% data set (mh4, mc2)
counter(4,1,2) = 42.3025 +273;
counter(4,2,2) = 36.0426 +273;
counter(4,3,2) = 33.8658+273;
counter(4,4,2) =  27.3452+273;
counter(4,5,2) =  25.3981+273;
counter(4,6,2) =  23.267+273;



%%%%%%%%%%%% Data set 3 (mc3) %%%%%%%%%%%

% data set (mh1, mc3)
counter(1,1,3) = 42.2421 +273;
counter(1,2,3) = 34.9019 +273;
counter(1,3,3) =  32.5844+273;
counter(1,4,3) =  25.6723+273;
counter(1,5,3) =  24.4821+273;
counter(1,6,3) =  23.2735+273;

% data set (mh2, mc3)
counter(2,1,3) = 42.3029 +273;
counter(2,2,3) = 35.326 +273;
counter(2,3,3) =  32.4519+273;
counter(2,4,3) =  25.9992+273;
counter(2,5,3) =  24.6881+273;
counter(2,6,3) =  23.377+273;

% data set (mh3, mc3)
counter(3,1,3) = 42.35 +273;
counter(3,2,3) = 35.35+273;
counter(3,3,3) =  33.20+273;
counter(3,4,3) =  25.03+273;
counter(3,5,3) =  24.87+273;
counter(3,6,3) =  26.21+273;

% data set (mh4, mc3)
counter(4,1,3) = 42.38 +273;
counter(4,2,3) = 35.62+273;
counter(4,3,3) =  33.7+273;
counter(4,4,3) =  26.4295+273;
counter(4,5,3) =  25.1494+273;
counter(4,6,3) =  23.3663+273;




% %% Solving for LMTD and U
% 
% %for parellel
% Thi = Parellel(:,1,:);
% Tho = Parellel(:,6,:);
% Tci = 20+273;
% Tco = 31+273;
% 
% delta1 = Thi-Tco;
% delta2 = Tho-Tci;
% 
% LMTDP = (delta2-delta1)./(log(delta2./delta1));
% QP = mh'.*4182.*(Thi-Tho);
% UP = QP./(A*LMTDP);
% C = mh*4182; 
% NTUP = (UP.*A)./(min(C));
% Cr =min(C)/max(C);
% eP = ((1-exp(-NTUP.*(1+Cr)))./(1+Cr))*100;
% mu = 8.9*10^(-12);
% Re = ((mh./A).*D)./(mu);
% 
% 
% % Ploting
% 
% 
% 
% dist = linspace(0,1.4986,6);
% 
% for j = 1:3
%     figure(Name="Temp vs dist (Parellel)")
%     for n =1:2
% 
%      if n ==1
%      for i = 1:4
%      plot(dist,Parellel(i,:,j)-273,linewidth=2)
%      hold on
% 
%      grid on
%      end
% 
% 
%      else
% 
%      for i = 1:4
%      plot(dist,Parellel(i,:,j)-273,"o",Color="black",LineWidth=1)
%      hold on
%      grid on
%      end
%      end
%     end
%      legend("Mass flow rate of hot water = 0.3","Mass flow rate of hot water = 0.4","Mass flow rate of hot water = 0.5","Mass flow rate of hot water = 0.6")
%      xlabel("Distance (m)")
%      ylabel("Temp (K)")
%      if j ==1
%         title("Mass flow rate of cool water = 0.3")
%      elseif j==2
%          title("Mass flow rate of cool water = 0.5")
%      else 
%          title("Mass flow rate of cool water = 0.7")
%      end
% end
% 
% m = 0.65;
% n = 0.4;
% eq = Re.^(m).*0.7^(n);
% 
% 
% figure(Name = "RE")
% plot(eq,UP(:,1,1),Linewidth= 2)
% hold on
% plot(eq,UP(:,1,1),"o",Linewidth= 2,Color="black")
% xlabel("Re_i^m \cdot 0.7^n")
% ylabel("U_i")
% title("U_i vs Re_i^m \cdot 0.7^n")
% grid on
% 
% figure(Name="effectiveness")
% for i = 1:3
% plot(NTUP(:,1,i),eP(:,1,i),LineWidth=2)
% hold on
% grid on
% end
% for i = 1:3
% plot(NTUP(:,1,i),eP(:,1,i),"*",Color="black")
% hold on
% grid on
% end
% legend("Mass flow rate of Cold water = 0.3","Mass flow rate of cold water = 0.5","Mass flow rate of cold water = 0.7","raw data points","raw data points","raw data points")
% ylabel("Effectivness")
% xlabel("NTU")
% 
% 
% 
% 
% %% Solving for LMTD and U
% 
% %for coounter
% Thi = counter(:,1,:);
% Tho = counter(:,6,:);
% Tci = 20+273;
% Tco = 31+273;
% 
% delta1 = Thi-Tco;
% delta2 = Tho-Tci;
% 
% LMTDC = (delta2-delta1)./(log(delta2./delta1));
% QC = mh'.*4182.*(Thi-Tho);
% UC = QC./(A*LMTDC);
% C = mh*4182; 
% NTUC = (UC.*A)./(min(C));
% Cr =min(C)/max(C);
% eC = ((1-exp(-NTUC.*(1+Cr)))./(1+Cr))*100;
% mu = 8.9*10^(-12);
% Re = ((mh./A).*D)./(mu);
% 
% 
% % Ploting
% 
% 
% 
% dist = linspace(0,1.4986,6);
% 
% for j = 1:3
%     figure(Name="Temp vs dist (Counter)")
%     for n =1:2
% 
%      if n ==1
%      for i = 1:4
%      plot(dist,counter(i,:,j)-273,linewidth=2)
%      hold on
% 
%      grid on
%      end
% 
% 
%      else
% 
%      for i = 1:4
%      plot(dist,counter(i,:,j)-273,"o",Color="black",LineWidth=1)
%      hold on
%      grid on
%      end
%      end
%     end
%      legend("Mass flow rate of hot water = 0.3","Mass flow rate of hot water = 0.4","Mass flow rate of hot water = 0.5","Mass flow rate of hot water = 0.6")
%      xlabel("Distance (m)")
%      ylabel("Temp (K)")
%      if j ==1
%         title("Mass flow rate of cool water = 0.3")
%      elseif j==2
%          title("Mass flow rate of cool water = 0.5")
%      else 
%          title("Mass flow rate of cool water = 0.7")
%      end
% end
% 
% m = 0.65;
% n = 0.4;
% eq = Re.^(m).*0.7^(n);
% 
% 
% figure(Name = "RE")
% plot(eq,UC(:,1,1),Linewidth= 2)
% hold on
% plot(eq,UC(:,1,1),"o",Linewidth= 2,Color="black")
% xlabel("Re_i^m \cdot 0.7^n")
% ylabel("U_i")
% title("U_i vs Re_i^m \cdot 0.7^n")
% grid on
% NTUC(3,1,3) = 4.85;
% eC(3,1,3) = 66.67;
% figure(Name="effectiveness")
% for i = 1:3
% plot(NTUC(:,1,i),eC(:,1,i),LineWidth=2)
% hold on
% grid on
% end
% 
% for i = 1:3
% plot(NTUC(:,1,i),eC(:,1,i),"*",Color="black")
% hold on
% grid on
% end
% legend("Mass flow rate of Cold water = 0.3","Mass flow rate of cold water = 0.5","Mass flow rate of cold water = 0.7","raw data points","raw data points","raw data points")
% ylabel("Effectivness")
% xlabel("NTU")

%%

% Define the data points
NTU = [0.25 0.27 0.30 0.33 0.35 0.37 0.40 0.42 0.45 0.48 0.50];
Effectiveness = [0.22 0.24 0.26 0.28 0.29 0.31 0.32 0.34 0.36 0.37 0.38];

% Create the plot
figure;
scatter(NTU, Effectiveness, 'filled'); % Scatter plot with filled markers
hold on;

% Add a trendline
p = polyfit(NTU, Effectiveness, 1); % Fit a linear trendline
y_fit = polyval(p, NTU);
plot(NTU, y_fit, '--',Linewidth =2); % Add the dashed trendline

% Customize the plot
xlabel('NTU');
ylabel('Effectiveness');
title('Effectiveness vs NTU');
grid on;



%%
% Define the data points
NTU = [0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05];
Effectiveness = [0.40 0.42 0.45 0.47 0.50 0.52 0.55 0.57 0.59 0.60 0.62];

% Create the plot
figure;
scatter(NTU, Effectiveness, 'filled'); % Scatter plot with filled markers
hold on;

% Add a trendline
p = polyfit(NTU, Effectiveness, 1); % Fit a linear trendline
y_fit = polyval(p, NTU);
plot(NTU, y_fit, '--',Linewidth =2); % Add the dashed trendline

% Customize the plot
xlabel('NTU');
ylabel('Effectiveness');
title('Effectiveness vs NTU');
grid on;

%%
for i = 1:3
% Approximated y-values (temperatures) from the graph
temps_03 = [40, 35.5, 34, 24, 30-4, 34-7]; % Mass flow rate = 0.3
temps_04 = [41, 35.5, 31, 24, 30-4, 34.5-7]; % Mass flow rate = 0.4
temps_05 = [42, 36, 31, 24, 31-4, 36-7]; % Mass flow rate = 0.5
temps_06 = [43, 37.5, 32, 24, 33-4, 35-7]; % Mass flow rate = 0.6

temps_03 = Parellel(1,:,i); % Mass flow rate = 0.3
temps_04 = Parellel(2,:,i); % Mass flow rate = 0.4
temps_05 = Parellel(3,:,i); % Mass flow rate = 0.5
temps_06 = Parellel(4,:,i); % Mass flow rate = 0.6

% New x-axis (distance) for the transformed lines
new_distances = [0, 0.75, 1.5];

% Extract first three and last three points for each line
% Line 03
line1_03 = temps_03(1:3); % First three points
line2_03 = temps_03(4:6); % Last three points

% Line 04
line1_04 = temps_04(1:3);
line2_04 = temps_04(4:6);

% Line 05
line1_05 = temps_05(1:3);
line2_05 = temps_05(4:6);

% Line 06
line1_06 = temps_06(1:3);
line2_06 = temps_06(4:6);

% Plot the transformed lines
figure;
% Define hex colors for the lines
color_03 = "#0072BD"; % Soft blue
color_04 = 	"#D95319"; % Soft teal
color_05 = 	"#EDB120"; % Muted yellow
color_06 = '#AF7AC5'; % Soft purple

% Line 03
plot(new_distances, line1_03, '-o', 'Color', color_03, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.3 ');
hold on;
plot(new_distances, line2_03, '--o', 'Color', color_03, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.3');

% Line 04
plot(new_distances, line1_04, '-o', 'Color', color_04, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.4 ');
plot(new_distances, line2_04, '--o', 'Color', color_04, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.4 ');

% Line 05
plot(new_distances, line1_05, '-o', 'Color', color_05, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.5 ');
plot(new_distances, line2_05, '--o', 'Color', color_05, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.5 ');

% Line 06
plot(new_distances, line1_06, '-o', 'Color', color_06, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.6 ');
plot(new_distances, line2_06, '--o', 'Color', color_06, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.6 ');

% Customize the plot
xlabel('Distance (m)');
ylabel('Temperature (K)');
title('Temperature vs distance');
legend('Location', 'Best');
grid on;

end




%%

%%
for i = 1:3
% Approximated y-values (temperatures) from the graph
temps_03 = [40, 35.5, 34, 24, 30-4, 34-7]; % Mass flow rate = 0.3
temps_04 = [41, 35.5, 31, 24, 30-4, 34.5-7]; % Mass flow rate = 0.4
temps_05 = [42, 36, 31, 24, 31-4, 36-7]; % Mass flow rate = 0.5
temps_06 = [43, 37.5, 32, 24, 33-4, 35-7]; % Mass flow rate = 0.6

temps_03 = counter(1,:,i); % Mass flow rate = 0.3
temps_04 = counter(2,:,i); % Mass flow rate = 0.4
temps_05 = counter(3,:,i); % Mass flow rate = 0.5
temps_06 = counter(4,:,i); % Mass flow rate = 0.6

% New x-axis (distance) for the transformed lines
new_distances = [0, 0.75, 1.5];

% Extract first three and last three points for each line
% Line 03
line1_03 = temps_03(1:3); % First three points
line2_03 = temps_03(4:6); % Last three points

% Line 04
line1_04 = temps_04(1:3);
line2_04 = temps_04(4:6);

% Line 05
line1_05 = temps_05(1:3);
line2_05 = temps_05(4:6);

% Line 06
line1_06 = temps_06(1:3);
line2_06 = temps_06(4:6);

% Plot the transformed lines
figure;
% Define hex colors for the lines
color_03 = "#0072BD"; % Soft blue
color_04 = 	"#D95319"; % Soft teal
color_05 = 	"#EDB120"; % Muted yellow
color_06 = '#AF7AC5'; % Soft purple

% Line 03
plot(new_distances, line1_03, '-o', 'Color', color_03, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.3 ');
hold on;
plot(new_distances, line2_03, '--o', 'Color', color_03, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.3');

% Line 04
plot(new_distances, line1_04, '-o', 'Color', color_04, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.4 ');
plot(new_distances, line2_04, '--o', 'Color', color_04, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.4 ');

% Line 05
plot(new_distances, line1_05, '-o', 'Color', color_05, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.5 ');
plot(new_distances, line2_05, '--o', 'Color', color_05, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.5 ');

% Line 06
plot(new_distances, line1_06, '-o', 'Color', color_06, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.6 ');
plot(new_distances, line2_06, '--o', 'Color', color_06, 'LineWidth', 2, 'DisplayName', 'Flow rate = 0.6 ');

% Customize the plot
xlabel('Distance (m)');
ylabel('Temperature (K)');
title('Temperature vs distance');
legend('Location', 'Best');
grid on;

end

