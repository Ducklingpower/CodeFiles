clear;
clc;
close all;
addpath(fullfile(pwd,'Functions'));
datamode = LongOrLat(); % Choose longetudinal or lateral mode
[fileid, pathname] = uigetfile({'*.mat;*.dat'},'File Selector');
if( isa(fileid, 'double') && isequal(fileid, 0) )
    % No file was chosen, so we return
    return
end
[AT, ET, FX, FY, FZ, IA, MX, MZ, N, NFX, NFY, P, RE, RL, RST, SA, SR, TSTC, TSTI, TSTO, V]...
    = ImportRawData( fullfile(pathname, fileid) );

mechTrail = 0.005;  %meters
scrubR = 0.0254;      %meters
SteeringRT = 0.01905;  %meters
pnumatic = 0.021428; %meters
pitManT = 0.100;  %meters
%%tt=-t;
Mz2 = FY.*pnumatic;
%ask Oliver bout (mechTrial+tt vs mechtrail)
M_kingPinAxis = (FY.*(mechTrail))+(Mz2); %N-M
force_arm = M_kingPinAxis/pitManT;
torque = force_arm*SteeringRT;

figure
plot(SA,torque)
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

min(FZ)
