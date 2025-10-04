%close(loopbar)
clear all
close all
clc
tStart = tic;

%% ARB Adjustment Values
% Front

% 0.049" Bar:
% 135.58
% 122.022
% 108.464
% 94.906
% 81.348

% 0.028" Bar:
% 87.919
% 79.127
% 70.335
% 61.543
% 52.751

% Rear

% 0.049" Bar:
% 59.6552
% 43.3856
% 27.116

% 0.028" Bar:
% 39.661
% 28.845
% 18.028

%% inputs:

% simParams
simParams.deltaMax = 21;                % max and min delta values for YMD
simParams.deltaResolution = 0.5;        % resolution of delta values for YMD
simParams.betaMax = 10;                  % max and min betas
simParams.betaResolution = 0.5;         % betas resolution
simParams.g = 9.81;                     % gravity
simParams.Vx = 10;                      % 24. forward velocity
simParams.plotGraphs = true;            % plot YMD graphs for each iteration
simParams.YMDcount = 1;                 % number of YMDs being generated
simParams.airDensity = 1.225;           % (kg/m^3)
simParams.Fy_scaler = 0.9;
simParams.combinedTrack = true;

% vehicleParams
vehicleParams.wheelbase = 1.5621;       % 1. wheelbase             (m)
vehicleParams.w_dist_f = 0.47;          % 2. mass dsitribution     (-)
vehicleParams.t_f = 1.27;               % 3. front track           (m)
vehicleParams.t_r = 1.2446;             % 4. rear track            (m)
vehicleParams.wheelRate_f = 33274.1;    % 5. (N/m)
vehicleParams.wheelRate_r = 36776.6;    % 6. (N/m)
vehicleParams.ARB_f = 0;           % 7. (Nm/deg)
vehicleParams.ARB_r = 59.66;            % 8. (Nm/deg)
vehicleParams.cg_z = 0.3;               % 9. cg height             (m)
vehicleParams.rc_f = 0.04191;           % 10. roll center front     (m)
vehicleParams.rc_r = 0.05334;           % 11. roll center rear      (m)
vehicleParams.toe_f = 0;                % 12. toe front (- = out)   (deg)
vehicleParams.toe_r = 0;                % 13. toe rear (- = out)   (deg)
vehicleParams.m = 300;                  % 14. vehicle mass          (kg)
vehicleParams.toe_comp_f = 0.01;        % 15. toe comliance front   (deg/Nm) *0.05 max
vehicleParams.toe_comp_r = 0.01;        % 16. toe comliance rear    (deg/Nm) *0.05 max
vehicleParams.mech_trail_f = 0.008;     % 17. mech trail front      (m)
vehicleParams.mech_trail_r = 0.008;     % 18. mech trail rear       (m)
vehicleParams.frontalArea = 1.124;      % 19. frontal area          (m^2)
vehicleParams.Cd = 1.4;                 % 20. drag coef             (-)
vehicleParams.Cl = -2.5;                % 21. lift coef             (-)
vehicleParams.aeroBalance = 0.425;      % 22. frontal aero load     (-)
vehicleParams.copShift = 0;             % 23. balance shift with Vx (%/(m/s))

% parameter to vary

testParameterXNum = 24;
testParameterXVals = linspace(10, 15, 6);

twoInput = false;

if twoInput
    testParameterYNum = 16;
    testParameterYVals = linspace(0, 0.1, 7);
    simParams.YMDcount = length(testParameterXVals) * length(testParameterYVals);
else
    testParameterYNum = 0;
    testParameterYVals = 0;
    simParams.YMDcount = length(testParameterXVals);
end

%% tire model caching

FyMz_Optimized = true; % choose to run cached tire model or not

if FyMz_Optimized
    Fz_range = linspace(-3500, 100, 100); % Example range
    alpha_range = linspace(-50, 50, 100); % deg
    [Fz_grid, alpha_grid] = meshgrid(Fz_range, alpha_range);

    Fy_LUT = zeros(size(Fz_grid));
    for i = 1:numel(Fz_grid)
        Fy_LUT(i) = LateralTireModel(Fz_grid(i), alpha_grid(i));
    end

    Mz_LUT = zeros(size(Fz_grid));
    for i = 1:numel(Fz_grid)
        Mz_LUT(i) = AligningTireModel(Fz_grid(i), alpha_grid(i));
    end
else
    Fy_LUT = zeros(size(Fz_grid));
    Mz_LUT = zeros(size(Fz_grid));
end

%% MF5.2 model caching

Fz      = 0;               % vertical load         (N)
kappa	= 0;               % longitudinal slip 	(-) (-1 = locked wheel)
alpha	= 0;               % slip angle    	(radians)
gamma	= 0;               % inclination angle 	(radians)
phit 	= 0;               % turnslip            	(1/m)
Vx   	= 15;              % forward velocity   	(m/s)
P       = 97000;           % pressure              (Pa)

% Create a string with the name of the TIR file
TIRfile = 'C:\Users\22oli\Documents\wikifactory attempt 12\24E-VD\Calcs\Tire Models\MF 52 SAE V11 scaled.tir';

% Select a Use Mode
useMode = 111;

Fz_range = linspace(-3500, 100, 100); % Example range
alpha_range = deg2rad(linspace(-50, 50, 100)); % rad
[Fz_grid, alpha_grid] = meshgrid(Fz_range, alpha_range);

Fy_LUT = zeros(size(Fz_grid));

progress = 0;

cacheBar = waitbar(progress, 'starting');

for i = 1:numel(Fz_grid)

    if mod(i, 25) == 0 || i == 1
        progress = i / numel(Fz_grid);
        waitbar(progress, cacheBar, "Caching Tire Model... " + num2str(progress * 100) + "%")
    end

    Fz = -Fz_grid(i);
    alpha = alpha_grid(i);

    % Wrap all inputs in one matrix
    inputs = [Fz kappa alpha gamma phit Vx P];

    % Store the output from mfeval in a 2D Matrix
    output = mfeval(TIRfile, inputs, useMode);

    Fy_LUT(i) = -simParams.Fy_scaler * output(:, 2);

    %Fy_LUT(i) = LateralTireModel(Fz_grid(i), alpha_grid(i));
end

% surf(Fz_grid, alpha_grid, Fy_LUT)

close(cacheBar)

%% pre loop initializations

YMD_it = 0;

% YMD function loop

for i=1:length(testParameterXVals)
    for j=1:length(testParameterYVals)

        YMD_it = YMD_it + 1;

        switch testParameterXNum
            case 0
                paramNameX = "null";
                unitX = "null";
            case 1
                paramNameX = "Wheelbase";
                unitX = " (m)";
                vehicleParams.wheelbase = testParameterXVals(i);

                if false
                    vehicleParams.m = vehicleParams.m + ((vehicleParams.wheelbase - 1.5621) * 11.1);

                end

            case 2
                paramNameX = "Mass Distribution";
                unitX = " (-)";
                vehicleParams.w_dist_f = testParameterXVals(i);              
            case 3
                paramNameX = "Front Track Width";
                unitX = " (m)";
                vehicleParams.t_f = testParameterXVals(i);

                if simParams.combinedTrack
                    vehicleParams.t_r = vehicleParams.t_f;             
                end

            case 4
                paramNameX = "Rear Track Width";
                unitX = " (m)";
                vehicleParams.t_r = testParameterXVals(i);
            case 5
                paramNameX = "Front Wheel Rate";
                unitX = " (N/m)";
                vehicleParams.wheelRate_f = testParameterXVals(i);
            case 6
                paramNameX = "Rear Wheel Rate";
                unitX = " (N/m)";
                vehicleParams.wheelRate_r = testParameterXVals(i);
            case 7
                paramNameX = "Front ARB Stiffness";
                unitX = " (Nm/deg)";
                vehicleParams.ARB_f = testParameterXVals(i);
            case 8
                paramNameX = "Rear ARB Stiffness";
                unitX = " (Nm/deg)";
                vehicleParams.ARB_r = testParameterXVals(i);
            case 9
                paramNameX = "CG Height";
                unitX = " (m)";
                vehicleParams.cg_z = testParameterXVals(i);
            case 10
                paramNameX = "Front Roll Center Height";
                unitX = " (m)";
                vehicleParams.rc_f = testParameterXVals(i);
            case 11
                paramNameX = "Rear Roll Center Height";
                unitX = " (m)";
                vehicleParams.rc_r = testParameterXVals(i);
            case 12
                paramNameX = "Front Toe Angle";
                unitX = " (deg)";
                vehicleParams.toe_f = testParameterXVals(i);
            case 13
                paramNameX = "Rear Toe Angle";
                unitX = " (deg)";
                vehicleParams.toe_r = testParameterXVals(i);
            case 14
                paramNameX = "Vehicle Mass";
                unitX = " (kg)";
                vehicleParams.m = testParameterXVals(i);
            case 15
                paramNameX = "Front Toe Compliance";
                unitX = " (deg/Nm)";
                vehicleParams.toe_comp_f = testParameterXVals(i);
            case 16
                paramNameX = "Rear Toe Compliance";
                unitX = " (deg/Nm)";
                vehicleParams.toe_comp_r = testParameterXVals(i);
            case 17
                paramNameX = "Front Mechanical Trail";
                unitX = " (m)";
                vehicleParams.mech_trail_f = testParameterXVals(i);
            case 18
                paramNameX = "Rear Mechanical Trail";
                unitX = " (m)";
                vehicleParams.mech_trail_r = testParameterXVals(i);
            case 19
                paramNameX = "Frontal Area";
                unitX = " (m^2)";
                vehicleParams.frontalArea = testParameterXVals(i);
            case 20
                paramNameX = "Drag Coef";
                unitX = " (-)";
                vehicleParams.Cd = testParameterXVals(i);
            case 21
                paramNameX = "Lift Coef";
                unitX = " (-)";
                vehicleParams.Cl = testParameterXVals(i);
            case 22
                paramNameX = "Aero Balance";
                unitX = " (-)";
                vehicleParams.aeroBalance = testParameterXVals(i);
            case 23
                paramNameX = "COP Shift";
                unitX = " ()";
                vehicleParams.copShift = testParameterXVals(i);
            case 24
                paramNameX = "Forward Velocity";
                unitX = " (m/s)";
                simParams.Vx = testParameterXVals(i);
        end

        switch testParameterYNum
            case 0
                paramNameY = "null";
                unitY = "null";
            case 1
                paramNameY = "Wheelbase";
                unitY = " (m)";
                vehicleParams.wheelbase = testParameterYVals(j);
            case 2
                paramNameY = "Mass Distribution";
                unitY = " (-)";
                vehicleParams.w_dist_f = testParameterYVals(j);
            case 3
                paramNameY = "Front Track Width";
                unitY = " (m)";
                vehicleParams.t_f = testParameterYVals(j);

                if simParams.combinedTrack
                    vehicleParams.t_r = vehicleParams.t_f;             
                end

            case 4
                paramNameY = "Rear Track Width";
                unitY = " (m)";
                vehicleParams.t_r = testParameterYVals(j);
            case 5
                paramNameY = "Front Wheel Rate";
                unitY = " (N/m)";
                vehicleParams.wheelRate_f = testParameterYVals(j);
            case 6
                paramNameY = "Rear Wheel Rate";
                unitY = " (N/m)";
                vehicleParams.wheelRate_r = testParameterYVals(j);
            case 7
                paramNameY = "Front ARB Stiffness";
                unitY = " (Nm/deg)";
                vehicleParams.ARB_f = testParameterYVals(j);
            case 8
                paramNameY = "Rear ARB Stiffness";
                unitY = " (Nm/deg)";
                vehicleParams.ARB_r = testParameterYVals(j);
            case 9
                paramNameY = "CG Height";
                unitY = " (m)";
                vehicleParams.cg_z = testParameterYVals(j);
            case 10
                paramNameY = "Front Roll Center Height";
                unitY = " (m)";
                vehicleParams.rc_f = testParameterYVals(j);
            case 11
                paramNameY = "Rear Roll Center Height";
                unitY = " (m)";
                vehicleParams.rc_r = testParameterYVals(j);
            case 12
                paramNameY = "Front Toe Angle";
                unitY = " (deg)";
                vehicleParams.toe_f = testParameterYVals(j);
            case 13
                paramNameY = "Rear Toe Angle";
                unitY = " (deg)";
                vehicleParams.toe_r = testParameterYVals(j);
            case 14
                paramNameY = "Vehicle Mass";
                unitY = " (kg)";
                vehicleParams.m = testParameterYVals(j);
            case 15
                paramNameY = "Front Toe Compliance";
                unitY = " (deg/Nm)";
                vehicleParams.toe_comp_f = testParameterYVals(j);
            case 16
                paramNameY = "Rear Toe Compliance";
                unitY = " (deg/Nm)";
                vehicleParams.toe_comp_r = testParameterYVals(j);
            case 17
                paramNameY = "Front Mechanical Trail";
                unitY = " (m)";
                vehicleParams.mech_trail_f = testParameterYVals(j);
            case 18
                paramNameY = "Rear Mechanical Trail";
                unitY = " (m)";
                vehicleParams.mech_trail_r = testParameterYVals(j);
            case 19
                paramNameY = "Frontal Area";
                unitY = " (m^2)";
                vehicleParams.frontalArea = testParameterYVals(j);
            case 20
                paramNameY = "Drag Coef";
                unitY = " (-)";
                vehicleParams.Cd = testParameterYVals(j);
            case 21
                paramNameY = "Lift Coef";
                unitY = " (-)";
                vehicleParams.Cl = testParameterYVals(j);
            case 22
                paramNameY = "Aero Balance";
                unitY = " (-)";
                vehicleParams.aeroBalance = testParameterYVals(j);
            case 23
                paramNameY = "COP Shift";
                unitY = " ()";
                vehicleParams.copShift = testParameterYVals(j);
            case 24
                paramNameY = "Forward Velocity";
                unitY = " (m/s)";
                simParams.Vx = testParameterYVals(j);
        end        

        outputStruct = YMDfunc(simParams, vehicleParams, Fy_LUT, Mz_LUT, Fz_grid, alpha_grid);

        entryStability(i, j) = outputStruct.entryStab;
        entryControl(i, j) = outputStruct.entryCon;
        apexStability(i, j) = outputStruct.apexStab;
        apexControl(i, j) = outputStruct.apexCon;
        balance(i, j) = outputStruct.yawMomentMaxLat;
        maxLatSS(i, j) = outputStruct.maxLatSS;

        alphaFL(i, j) = outputStruct.statesMaxLat.alphaFL;
        alphaFR(i, j) = outputStruct.statesMaxLat.alphaFR;
        alphaRL(i, j) = outputStruct.statesMaxLat.alphaRL;
        alphaRR(i, j) = outputStruct.statesMaxLat.alphaRR;

        Fz_FL(i, j) = outputStruct.statesMaxLat.FzFL;
        Fz_FR(i, j) = outputStruct.statesMaxLat.FzFR;
        Fz_RL(i, j) = outputStruct.statesMaxLat.FzRL;
        Fz_RR(i, j) = outputStruct.statesMaxLat.FzRR;

        Mz_FL(i, j) = outputStruct.statesMaxLat.MzFL;
        Mz_FR(i, j) = outputStruct.statesMaxLat.MzFR;
        Mz_RL(i, j) = outputStruct.statesMaxLat.MzRL;
        Mz_RR(i, j) = outputStruct.statesMaxLat.MzRR;

        zTorq_fl(i, j) = outputStruct.statesMaxLat.zTorq_fl;
        zTorq_fr(i, j) = outputStruct.statesMaxLat.zTorq_fr;
        zTorq_rl(i, j) = outputStruct.statesMaxLat.zTorq_rl;
        zTorq_rr(i, j) = outputStruct.statesMaxLat.zTorq_rr;

        Fy_FL(i, j) = outputStruct.statesMaxLat.FyFL;
        Fy_FR(i, j) = outputStruct.statesMaxLat.FyFR;
        Fy_RL(i, j) = outputStruct.statesMaxLat.FyRL;
        Fy_RR(i, j) = outputStruct.statesMaxLat.FyRR;

        FL_SAmod(i, j) = outputStruct.statesMaxLat.FL_SAmod;
        FR_SAmod(i, j) = outputStruct.statesMaxLat.FR_SAmod;
        RL_SAmod(i, j) = outputStruct.statesMaxLat.RL_SAmod;
        RR_SAmod(i, j) = outputStruct.statesMaxLat.RR_SAmod;

        G_capability(i, j) = outputStruct.maxLatNonSS;

        chassisTorque(i, j) = abs(((Fz_FL(i, j) * (vehicleParams.t_f/2)) - (Fz_FR(i, j) * (vehicleParams.t_f/2)))...
            - ((Fz_RL(i, j) * (vehicleParams.t_r/2)) - (Fz_RR(i, j) * (vehicleParams.t_r/2))));

        maxLatSS_delta(i, j) = outputStruct.statesMaxLat.delta;
        maxLatSS_beta(i, j) = outputStruct.statesMaxLat.beta;

        understeerAngle(i, j) = rad2deg(deg2rad(maxLatSS_delta(i, j)) - ((vehicleParams.wheelbase * maxLatSS(i, j)) / ((simParams.Vx) ^ 2)));

        fprintf("\ndelta: " + maxLatSS_delta(i, j))
        fprintf("\nbeta: " + maxLatSS_beta(i, j))

        fprintf("\nalpha FL: " + rad2deg(outputStruct.statesMaxLat.alphaFL))
        fprintf("\nalpha FR: " + rad2deg(outputStruct.statesMaxLat.alphaFR))
        fprintf("\nalpha RL: " + rad2deg(outputStruct.statesMaxLat.alphaRL))
        fprintf("\nalpha RR: " + rad2deg(outputStruct.statesMaxLat.alphaRR) + "\n")

        fprintf("YMD Counter: " + YMD_it +"\n") 
    end
end

if ~twoInput
    grid on
    figure
    subplot(2, 2, 1)
    hold on
    plot(testParameterXVals, entryStability(:, 1), 'red')
    plot(testParameterXVals, entryControl(:, 1), 'blue')
    title(paramNameX + " vs Entry Stability and Control")
    xlabel(paramNameX + unitX)
    ylabel("Yaw Moment (Nm/deg)")
    legend('Entry Stability', "Entry Control", 'Location', 'best')

    subplot(2, 2, 2)
    hold on
    plot(testParameterXVals, apexStability(:, 1), 'red')
    plot(testParameterXVals, apexControl(:, 1), 'blue')
    title(paramNameX + " vs Apex Stability and Control")
    xlabel(paramNameX + unitX)
    ylabel("Yaw Moment (Nm/deg)")
    legend('Apex Stability', "Apex Control", 'Location', 'best')

    subplot(2, 2, 3)
    hold on
    plot(testParameterXVals, balance(:, 1), 'red')
    title(paramNameX + " vs Balance")
    xlabel(paramNameX + unitX)
    ylabel("Balance (Nm/deg)")

    subplot(2, 2, 4)
    hold on
    plot(testParameterXVals, maxLatSS(:, 1)./simParams.g, 'blue')
    title(paramNameX + " vs Steady State Grip")
    xlabel(paramNameX + unitX)
    ylabel("Lateral Acceleration (g)")

    fileName = strcat(paramNameX + " Control Stability and Balance 2D.fig");
    savefig("Figures/" + fileName)

    figure
    subplot(2, 2, 1)
    hold on
    plot(testParameterXVals, rad2deg(alphaFL(:, 1)), 'red')
    plot(testParameterXVals, rad2deg(alphaFR(:, 1)), 'blue')
    plot(testParameterXVals, rad2deg(alphaRL(:, 1)), 'green')
    plot(testParameterXVals, rad2deg(alphaRR(:, 1)), 'magenta')
    title(paramNameX + " vs Slip Angles")
    xlabel(paramNameX + unitX)
    ylabel("Slip Angle (deg)")
    legend("SA Front Left", "SA Front Right", "SA Rear Left", "SA Rear Right", 'Location', 'best')

    subplot(2, 2, 2)
    hold on
    plot(testParameterXVals, -Fz_FL(:, 1), 'red')
    plot(testParameterXVals, -Fz_FR(:, 1), 'blue')
    plot(testParameterXVals, -Fz_RL(:, 1), 'green')
    plot(testParameterXVals, -Fz_RR(:, 1), 'magenta')
    title(paramNameX + " vs Normal Load")
    xlabel(paramNameX + unitX)
    ylabel("Normal Load (N)")
    legend("Fz Front Left", "Fz Front Right", "Fz Rear Left", "Fz Rear Right", 'Location', 'best')

    subplot(2, 2, 3)
    hold on
    plot(testParameterXVals, Fy_FL(:, 1), 'red')
    plot(testParameterXVals, Fy_FR(:, 1), 'blue')
    plot(testParameterXVals, Fy_RL(:, 1), 'green')
    plot(testParameterXVals, Fy_RR(:, 1), 'magenta')
    plot(testParameterXVals, Fy_FL(:, 1) + Fy_FR(:, 1), 'cyan')
    plot(testParameterXVals, Fy_RL(:, 1) + Fy_RR(:, 1), 'yellow')
    title(paramNameX + " vs Lateral Force")
    xlabel(paramNameX + unitX)
    ylabel("Lateral Force (N)")
    legend("Fy Front Left", "Fy Front Right", "Fy Rear Left", "Fy Rear Right", "Fy Front", "Fy Rear", 'Location', 'best')

    subplot(2, 2, 4)
    hold on
    plot(testParameterXVals, maxLatSS_delta(:, 1), 'cyan')
    plot(testParameterXVals, maxLatSS_beta(:, 1), 'black')
    title(paramNameX + " vs Steering and Sideslip")
    xlabel(paramNameX + unitX)
    ylabel("Angle (deg)")
    legend("Delta", "Beta", 'Location', 'best')

    fileName = strcat(paramNameX + " Tire Forces and Angles 2D.fig");
    savefig("Figures/" + fileName)

    figure
    subplot(2, 2, 1)
    hold on
    plot(testParameterXVals, zTorq_fl(:, 1), 'red')
    plot(testParameterXVals, zTorq_fr(:, 1), 'blue')
    plot(testParameterXVals, zTorq_rl(:, 1), 'green')
    plot(testParameterXVals, zTorq_rr(:, 1), 'magenta')
    title(paramNameX + " vs Aligning Moment")
    xlabel(paramNameX + unitX)
    ylabel("Aligning Moment (Nm)")
    legend("Mz Front Left", "Mz Front Right", "Mz Rear Left", "Mz Rear Right", 'Location', 'best')

    subplot(2, 2, 2)
    hold on
    plot(testParameterXVals, chassisTorque(:, 1), 'red')
    title(paramNameX + " vs Chassis Torque")
    xlabel(paramNameX + unitX)
    ylabel("Chassis Torque (Nm)")

    subplot(2, 2, 3)
    hold on
    plot(testParameterXVals, G_capability(:, 1) ./ simParams.g, 'red')
    title(paramNameX + " vs Max Cornering Capability")
    xlabel(paramNameX + unitX)
    ylabel("Cornering Capability (g)")

    subplot(2, 2, 4)
    hold on
    plot(testParameterXVals, rad2deg(FL_SAmod(:, 1)), 'red')
    plot(testParameterXVals, rad2deg(FR_SAmod(:, 1)), 'blue')
    plot(testParameterXVals, rad2deg(RL_SAmod(:, 1)), 'green')
    plot(testParameterXVals, rad2deg(RR_SAmod(:, 1)), 'magenta')
    title(paramNameX + " vs Slip Angle Modification")
    xlabel(paramNameX + unitX)
    ylabel("Slip Angle Modification (deg)")
    legend("Front Left", "Front Right", "Rear Left", "Rear Right", 'Location', 'best')
    
    fileName = strcat(paramNameX + " Misc Data 2D.fig");
    savefig("Figures/" + fileName)
   
else
    
    grid on
    surf(testParameterYVals, testParameterXVals, balance)
    title(paramNameX + " vs " + paramNameY + " vs Balance")
    ylabel(paramNameX + unitX)
    xlabel(paramNameY + unitY)
    zlabel("Balance (Nm/deg)")

    fileName = strcat(paramNameX + " " + paramNameY + " Balance 3D.fig");
    savefig("Figures/" + fileName)

    figure
    surf(testParameterYVals, testParameterXVals, maxLatSS/simParams.g)
    title(paramNameX + " vs " + paramNameY + " vs Max Lat Steady State")
    ylabel(paramNameX + unitX)
    xlabel(paramNameY + unitY)
    zlabel("Lateral Acceleration (g)")

    fileName = strcat(paramNameX + " " + paramNameY + " Max Lat SS 3D.fig");
    savefig("Figures/" + fileName)

    figure
    surf(testParameterYVals, testParameterXVals, G_capability/simParams.g)
    title(paramNameX + " vs " + paramNameY + " vs Max Cornering Capability")
    ylabel(paramNameX + unitX)
    xlabel(paramNameY + unitY)
    zlabel("Lateral Acceleration (g)")

    fileName = strcat(paramNameX + " " + paramNameY + " Lat Capability 3D.fig");
    savefig("Figures/" + fileName)

    figure
    surf(testParameterYVals, testParameterXVals, entryStability)
    title(paramNameX + " vs " + paramNameY + " vs Entry Stability")
    ylabel(paramNameX + unitX)
    xlabel(paramNameY + unitY)
    zlabel("Stability (Nm)")

    fileName = strcat(paramNameX + " " + paramNameY + " Entry Stability 3D.fig");
    savefig("Figures/" + fileName)

    figure
    surf(testParameterYVals, testParameterXVals, entryControl)
    title(paramNameX + " vs " + paramNameY + " vs Entry Control")
    ylabel(paramNameX + unitX)
    xlabel(paramNameY + unitY)
    zlabel("Stability (Nm)")

    fileName = strcat(paramNameX + " " + paramNameY + " Entry Control 3D.fig");
    savefig("Figures/" + fileName)

    figure
    surf(testParameterYVals, testParameterXVals, apexStability)
    title(paramNameX + " vs " + paramNameY + " vs Apex Stability")
    ylabel(paramNameX + unitX)
    xlabel(paramNameY + unitY)
    zlabel("Stability (Nm)")

    fileName = strcat(paramNameX + " " + paramNameY + " Apex Stability 3D.fig");
    savefig("Figures/" + fileName)

    figure
    surf(testParameterYVals, testParameterXVals, apexControl)
    title(paramNameX + " vs " + paramNameY + " vs Apex Control")
    ylabel(paramNameX + unitX)
    xlabel(paramNameY + unitY)
    zlabel("Stability (Nm)")

    fileName = strcat(paramNameX + " " + paramNameY + " Apex Control 3D.fig");
    savefig("Figures/" + fileName)
end

tEnd = toc(tStart);
minutes = floor(tEnd/60);
seconds = mod(tEnd, 60);

if minutes > 60
    fprintf("Elapsed Time: " + (minutes/60) + " hours")
else
    fprintf("Elapsed Time: " + minutes + " min " + seconds + " sec")
end