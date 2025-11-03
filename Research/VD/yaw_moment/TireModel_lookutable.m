%% 
clc
close all
clear
f = waitbar(0,'Please wait...');
%% Interpulating tire model creating LUT
% creating look up tables
addpath '/home/elijah/MATLAB Add-Ons/Toolboxes/MFeval/MFeval'

alpha_breaks = linspace(-0.45, 0.45, 500); % radians % deg  (0.25° resolution)
Fz_breaks    = linspace(0, 5000, 500); % N

front_l_tir = '2024003_Firestone_Firehawk Left Front SC_RC__275_40R15_MF62_UM4.tir';
rear_l_tir  = '2024003_Firestone_Firehawk Left Rear SC_RC__385_30R15_MF62_UM4.tir';

front_r_tir = '2024003_Firestone_Firehawk Right Front SC_RC__275_40R15_MF62_UM4.tir';
rear_r_tir  = '2024003_Firestone_Firehawk Right Rear SC_RC_385_30R15_MF62_UM4.tir';

         


% --- Allocate tables ---
nA  = numel(alpha_breaks);
nFz = numel(Fz_breaks);

Fy_table = zeros(nFz, nA);  % IMPORTANT: rows = Fz, cols = alpha
Mz_table = zeros(nFz, nA);  % if you want Mz too (optional)

% --- Sweep and fill ---
for iF = 1:nFz
    Fz = Fz_breaks(iF);
    waitbar(iF/nFz,f,'Loading LUT data boy');
    for iA = 1:nA
        alpha = alpha_breaks(iA);

  
        outfl = mfeval(front_l_tir,[Fz, 0, alpha, 0, 0, 40], 211);
        outrl = mfeval(rear_l_tir,[Fz, 0, alpha, 0, 0, 40], 211);
        outfr = mfeval(front_r_tir,[Fz, 0, alpha, 0, 0, 40], 211);
        outrr = mfeval(rear_r_tir,[Fz, 0, alpha, 0, 0, 40], 211);



        Fy_table_fl(iF, iA) = outfl(2);
        Mz_table_fl(iF, iA) = outfl(6); 

        Fy_table_rl(iF, iA) = outrl(2);
        Mz_table_rl(iF, iA) = outrl(6); 

        Fy_table_fr(iF, iA) = outfr(2);
        Mz_table_fr(iF, iA) = outfr(6); 

        Fy_table_rr(iF, iA) = outrr(2);
        Mz_table_rr(iF, iA) = outrr(6); 
    end
end

% --- Save to a .mat for reuse ---

LUT_Fy_fl.Fy_table     = Fy_table_fl;  
LUT_Fy_fl.Mz_table     = Mz_table_fl;   

LUT_Fy_rl.Fy_table     = Fy_table_rl;  
LUT_Fy_rl.Mz_table     = Mz_table_rl;   

LUT_Fy_fr.Fy_table     = Fy_table_fr;  
LUT_Fy_fr.Mz_table     = Mz_table_fr;   

LUT_Fy_rr.Fy_table     = Fy_table_rr;  
LUT_Fy_rr.Mz_table     = Mz_table_rr;  

LUT_Fy_fl.alpha = alpha_breaks;
LUT_Fy_rl.alpha = alpha_breaks;
LUT_Fy_fr.alpha = alpha_breaks;
LUT_Fy_rr.alpha = alpha_breaks;

LUT_Fy_fl.Fz_breaks = Fz_breaks;
LUT_Fy_rl.Fz_breaks = Fz_breaks;
LUT_Fy_fr.Fz_breaks = Fz_breaks;
LUT_Fy_rr.Fz_breaks = Fz_breaks;


save('LUT_Fy_fl.mat', 'LUT_Fy_fl');
save('LUT_Fy_rl.mat', 'LUT_Fy_rl');
save('LUT_Fy_fr.mat', 'LUT_Fy_fr');
save('LUT_Fy_rr.mat', 'LUT_Fy_rr');


%% testing

% running LUT
S = load('LUT_Fy_fl.mat');
A  = S.LUT_Fy_fl.alpha;
FZ = S.LUT_Fy_fl.Fz_breaks;
FY = S.LUT_Fy_fl.Fy_table;
MZ = S.LUT_Fy_fl.Mz_table;

% Create a 2-D interpolant: first dim = Fz, second = alpha
FyLUT = griddedInterpolant({FZ, A}, FY, 'linear', 'nearest'); % linear interp, clamp outside
MZLUT = griddedInterpolant({FZ, A}, MZ, 'linear', 'nearest');


% Example query:

alpha_q = linspace(-0.45, 0.45, 1000);
Fz_q    = 4000;  % N
for i  =1:length(alpha_q)
Fy_q(1,i)    = FyLUT(Fz_q, alpha_q(i));
MZ_q(1,i)    = MZLUT(Fz_q, alpha_q(i));
end
%%
figure
plot(alpha_q(:),Fy_q(:))
hold on
plot(alpha_q(:),MZ_q(:))
hold on

figure
for i = 1:50
plot(A(:),MZ(i,:))
hold on
grid on
end

%% plotting

% Load the LUT
S = load('LUT_Fy_fl.mat');
LUT = S.LUT_Fy_fl;

% Extract data
alpha = LUT.alpha;      % radians
Fz    = LUT.Fz_breaks;  % N
Fy    = LUT.Fy_table;   % N
Mz    = LUT.Mz_table;   % N·m

% Convert slip angle to degrees (optional, just for nicer axes)
alpha_deg = rad2deg(alpha);

% Plot lateral force surface
figure;

surf(alpha_deg, Fz, Fy, 'EdgeColor','none');
xlabel('\alpha (deg)');
ylabel('F_z (N)');
zlabel('F_y (N)');
title('Lateral Force Surface (Front Left)');
colorbar; view(45,30); grid on;shading faceted

% Plot aligning moment surface
figure;
surf(alpha_deg, Fz, Mz, 'EdgeColor','none');
xlabel('\alpha (deg)');
ylabel('F_z (N)');
zlabel('M_z (N·m)');
title('Aligning Moment Surface (Front Left)');
colorbar; view(45,30); grid on;shading faceted


