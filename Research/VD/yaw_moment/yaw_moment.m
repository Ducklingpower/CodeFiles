clc 
close all
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

vehicleParams.ARB_f       = -1;          % (Nm/deg)  TBD
vehicleParams.ARB_r       = 0;           % (Nm/deg)  no anti roll bar in rear

vehicleParams.cg_z        = 0.275;       % CG height (m)  [275 mm]
vehicleParams.rc_f        = 0.025;       % roll center front (m) averge 25 mm TBD NEED
vehicleParams.rc_r        = 0.045;       % roll center rear  (m) averge 45 mm TBD NEED

vehicleParams.toe_f       = -0.451;      % toe front (deg, - = out) 
vehicleParams.toe_r       = -0.451;      % toe rear  (deg, - = out)

vehicleParams.m           = 630;        % vehicle mass (kg)  [base vehicle mass]

vehicleParams.mech_trail_f = 0;         % mech trail front (m) TBD
vehicleParams.mech_trail_r = 0;         % mech trail rear  (m) TBD

vehicleParams.frontalArea = 1.47 ;      % frontal area (m^2) TBD
vehicleParams.Cd          = 0.7;         % drag coeff (-)     TBD
vehicleParams.Cl          = 0;           % ift coeff (-)     TBD
vehicleParams.aeroBalance = .33;         % frontal aero load (-) 33% avg
vehicleParams.copShift    = -1;          % balance shift with Vx (%/(m/s))TBD





% sim paramters -----------------------------------------------------------

simParams.deltaMax = 10;                % max and min delta values for YMD
simParams.deltaResolution = 1;          % resolution of delta values for YMD
simParams.betaMax = 5;                 % max and min betas
simParams.betaResolution = 0.5;         % betas resolution
simParams.gravity = 9.81;                 % gravity
simParams.Vx = 10;                      % forward velocity (assume const)
simParams.plotGraphs = true;            % plot YMD graphs for each iteration
simParams.YMDcount = 1;                 % number of YMDs being generated
simParams.airDensity = 1.225;           % (kg/m^3)

%% running YMD func

YMD_out = YMD_calc(simParams,vehicleParams);









