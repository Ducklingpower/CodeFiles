clc 

clear
%% Yaw Moment Diagram

% Vehicle params ----------------------------------------------------------


% vehicleParams (unknowns = -1) 
% All information comes from the Vehicle Parameter spred sheet
% Addition Calculations are made

vehicleParams.wheelbase   = 2.9718;      % wheelbase (m)  [2971.8 mm]
vehicleParams.w_dist_f    = 0.42;        % front weight distribution [42%]
vehicleParams.t_f         = 1.638762;    % front track (m)  [1638.762 mm]
vehicleParams.t_r         = 1.5239686;   % rear track (m)   [1523.9686 mm]

% Wheel rates computed from springs & motion ratios at 0 mm:
% avg stiffness*(motion_ratio)^2

vehicleParams.wheelRate_f = 2.985553732e5;  % (N/m)
vehicleParams.wheelRate_r = 3.941321827e5;  % (N/m)

vehicleParams.ARB_f       = 0;             % (Nm/deg)  TBD
vehicleParams.ARB_r       = 0;              % (Nm/deg)  no anti roll bar in rear

vehicleParams.cg_z        = 0.275;          % CG height (m)  [275 mm]
vehicleParams.rc_f        = 0.1202436;      % roll center front (m) 
vehicleParams.rc_r        = 0.0016628;      % roll center rear  (m) 

vehicleParams.toe_f       = -0.451;         % toe front (deg, - = out) 
vehicleParams.toe_r       = -0.451;         % toe rear  (deg, - = out)

vehicleParams.m           = 630;            % vehicle mass (kg)  [base vehicle mass]

vehicleParams.mech_trail_f = 0;             % mech trail front (m) TBD
vehicleParams.mech_trail_r = 0;             % mech trail rear  (m) TBD

vehicleParams.frontalArea = 1 ;             % frontal area (m^2) TBD
vehicleParams.Cd          = 0.0;            % drag coeff (-)     TBD
vehicleParams.Cl          = 0.0;            % ift coeff (-)      TBD
vehicleParams.ACd         = 0.58;           % Area*coef down force      TBD
vehicleParams.aeroBalance = .33;            % frontal aero load (-) 33% avg
vehicleParams.copShift    = 0;              % balance shift with Vx (%/(m/s))TBD





% sim paramters -----------------------------------------------------------

simParams.deltaMax = 8;                % max and min delta values for YMD
simParams.deltaResolution = 1;          % resolution of delta values for YMD
simParams.betaMax = 4;                 % max and min betas
simParams.betaResolution = 0.5;           % betas resolution
simParams.gravity = 9.81;               % gravity
simParams.Vx = 60;                      % forward velocity (assume const)
simParams.plotGraphs = false;            % plot YMD graphs for each iteration
simParams.YMDcount = 1;                 % number of YMDs being generated
simParams.airDensity = 1.225;           % (kg/m^3)

%% running YMD func

YMD_out = YMD_calc(simParams,vehicleParams);
%% plottting data

output_Ay = YMD_out.Ay;
output_N  = YMD_out.N;
n = length(output_Ay(:,1));
m = length(output_Ay(1,:));
C1 = linspace(0.3,1,n);
C2 = linspace(0.3,1,m);

betaMax = simParams.betaMax;
betaRes = simParams.betaResolution;
deltaMax = simParams.deltaMax;
deltaRes = simParams.deltaResolution;

deltas = -deltaMax:deltaRes:deltaMax;
betas  = betaMax:-betaRes:-betaMax;



figure

%markers
mid_point = ceil(n/2);
for j = 1:m
A_y = output_Ay(mid_point, j)./9.81;
N   = output_N(mid_point,j);
lbl = sprintf('Beta = %d', betas(j));
plot(A_y, N, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [1,C2(j),0], 'MarkerEdgeColor','k','DisplayName',lbl)
hold on
end


mid_point = ceil(m/2);
for i = 1:n
A_y = output_Ay(i,mid_point)./9.81;
N   = output_N(i,mid_point);
lbl = sprintf('Delta = %d', deltas(i));
plot(A_y, N, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [C1(i),0,1], 'MarkerEdgeColor','k','DisplayName',lbl)
end
legend('show')
legend('AutoUpdate','off');   % lock legend


% actual lines
for j = 1:length(output_N(1,:))
hold on
plot(output_Ay(:, j)./9.81, output_N(:, j),"Color",[1,C2(j),0])
end
grid on
for i = 1:length(output_N(:,1))
plot(output_Ay(i, :)./9.81, output_N(i, :),"Color",[C1(i),0,1])
hold on
end

xlabel('Lateral Acceleration (g)');
ylabel('Yaw Moment (Nm)');
title('Yaw Moment Diagram');


% only for astetics 
mid_point = ceil(n/2);
for j = 1:m
A_y = output_Ay(mid_point, j)./9.81;
N   = output_N(mid_point,j);
lbl = sprintf('Beta = %d', betas(j));
plot(A_y, N, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [1,C2(j),0], 'MarkerEdgeColor','k','DisplayName',lbl)
hold on
end


mid_point = ceil(m/2);
for i = 1:n
A_y = output_Ay(i,mid_point)./9.81;
N   = output_N(i,mid_point);
lbl = sprintf('Delta = %d', deltas(i));
plot(A_y, N, 'o', 'MarkerSize', 8, 'MarkerFaceColor', [C1(i),0,1], 'MarkerEdgeColor','k','DisplayName',lbl)
end

%% mutliple YMD


vi = 15:20:75; 

figure; hold on; grid on; view(3)
for k = 1:length(vi)

simParams.Vx = vi(k);
vx_b = simParams.Vx * ones(size(output_N));   % instead of ones(length(betas))
vx_d = simParams.Vx * ones(size(output_N));
YMD_out = YMD_calc(simParams,vehicleParams);
output_Ay = YMD_out.Ay;
output_N  = YMD_out.N;
n = length(output_Ay(:,1));
m = length(output_Ay(1,:));

C1 = linspace(0.3,1,n);
C2 = linspace(0.3,1,m);
C3 = linspace(0.3,1,length(vi));

Cr = [.5,1,.1,1];
Cg = [1,.8,1,0.1];
Cb = [1,.1,.2,0.1];

    for j = 1:length(output_N(1,:))
    hold on
    plot3(output_Ay(:, j)./9.81, output_N(:, j),vx_b(:,j),"Color",[Cr(k),Cg(k),Cb(k)])
    end
    grid on
    for i = 1:length(output_N(:,1))
    plot3(output_Ay(i, :)./9.81, output_N(i, :),vx_d(i,:),"Color",[Cr(k),Cg(k),Cb(k)])
    hold on
    end

end


xlabel("A_y g")
ylabel('Yaw Moment (Nm)');
zlabel("Vx m/s")
title('Yaw Moment Diagram');



