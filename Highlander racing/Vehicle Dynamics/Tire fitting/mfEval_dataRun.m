clc
clear
close all

% Number of points
nPoints = 3000;

% Pure lateral test case
Fz      = ones(nPoints,1).*1400;            % vertical load         (N)
kappa	= ones(nPoints,1).*0;               % longitudinal slip 	(-) (-1 = locked wheel)
alpha	= linspace(deg2rad(-15),deg2rad(15), nPoints)';         % slip angle    	(radians)
gamma	= ones(nPoints,1).*deg2rad(0);               % inclination angle 	(radians)
phit 	= ones(nPoints,1).*0;               % turnslip            	(1/m)
Vx   	= ones(nPoints,1).*11;              % forward velocity   	(m/s)
P       = ones(nPoints,1).*97000;           % pressure              (Pa)

% Create a string with the name of the TIR file
TIRfile = 'C:\Users\elija\OneDrive\Documents\CodeFiles\Highlander racing\Vehicle Dynamics\Tire fitting\MF 52 SAE V11 scaled modified pure.tir';

% Select a Use Mode
useMode = 111;

%Fzs = linspace(100, 1400, 5);
Fzs = 200;

scale = 0.9;

    Fz = ones(nPoints,1).*Fzs(1);

    % Wrap all inputs in one matrix
    inputs = [Fz kappa alpha gamma phit Vx P];

    % Store the output from mfeval in a 2D Matrix
    output = mfeval(TIRfile, inputs, useMode);

    % Extract variables from output MFeval. For more info type "help mfeval"
    Fx = output(:, 1);
    Fy = -scale * output(:,2);
    Mz = output(:,6);
    SR = output(:,7);
    Mx = output(:,4);
    SA = rad2deg(output(:,8)); % Convert to degrees
    t = output(:,16);
    muy = output(:, 18);


figure
plot(SA, Fy)
   

%% exporting data

