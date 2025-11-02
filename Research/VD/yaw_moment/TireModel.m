function [Fx,Fy,Fz,Mx,My,Mz] = TireModel(fz_fl,fz_rl,fz_fr,fz_rr,alpha_fl,alpha_rl,alpha_fr,alpha_rr,Vx)

% addpath '/home/elijah/MATLAB Add-Ons/Toolboxes/MFeval/MFeval'

% % Load TIR files
% front_l_tir = '2024003_Firestone_Firehawk Left Front SC_RC__275_40R15_MF62_UM4.tir';
% rear_l_tir  = '2024003_Firestone_Firehawk Left Rear SC_RC__385_30R15_MF62_UM4.tir';
% 
% front_r_tir = '2024003_Firestone_Firehawk Right Front SC_RC__275_40R15_MF62_UM4.tir';
% rear_r_tir  = '2024003_Firestone_Firehawk Right Rear SC_RC_385_30R15_MF62_UM4.tir';
% 
% 
%  fl = mfeval(front_l_tir, [-fz_fl, 0, alpha_fl, 0, 0, Vx], 211);
%  rl  = mfeval(rear_l_tir, [-fz_rl, 0, alpha_rl, 0, 0, Vx], 211);
%  fr = mfeval(front_r_tir, [-fz_fr, 0, alpha_fr, 0, 0, Vx], 211);
%  rr  = mfeval(rear_r_tir, [-fz_rr, 0, alpha_rr, 0, 0, Vx], 211);




S_fl = load('LUT_Fy_fl.mat');
A_fl  = S_fl.LUT_Fy_fl.alpha;
FZ_fl = S_fl.LUT_Fy_fl.Fz_breaks;
FY_fl = S_fl.LUT_Fy_fl.Fy_table;
MZ_fl = S_fl.LUT_Fy_fl.Mz_table;

S_fr = load('LUT_Fy_fr.mat');
A_fr  = S_fr.LUT_Fy_fr.alpha;
FZ_fr = S_fr.LUT_Fy_fr.Fz_breaks;
FY_fr = S_fr.LUT_Fy_fr.Fy_table;
MZ_fr = S_fr.LUT_Fy_fr.Mz_table;

S_rl = load('LUT_Fy_rl.mat');
A_rl  = S_rl.LUT_Fy_rl.alpha;
FZ_rl = S_rl.LUT_Fy_rl.Fz_breaks;
FY_rl = S_rl.LUT_Fy_rl.Fy_table;
MZ_rl = S_rl.LUT_Fy_rl.Mz_table;

S_rr = load('LUT_Fy_rr.mat');
A_rr  = S_rr.LUT_Fy_rr.alpha;
FZ_rr = S_rr.LUT_Fy_rr.Fz_breaks;
FY_rr = S_rr.LUT_Fy_rr.Fy_table;
MZ_rr = S_rr.LUT_Fy_rr.Mz_table;


% Create a 2-D interpolant: first dim = Fz, second = alpha
FyLUT_fl = griddedInterpolant({FZ_fl, A_fl}, FY_fl, 'linear', 'nearest'); % linear interp, clamp outside
FyLUT_fr = griddedInterpolant({FZ_fr, A_fr}, FY_fr, 'linear', 'nearest');
FyLUT_rl = griddedInterpolant({FZ_rl, A_rl}, FY_rl, 'linear', 'nearest');
FyLUT_rr = griddedInterpolant({FZ_rr, A_rr}, FY_rr, 'linear', 'nearest');

MZLUT_fl = griddedInterpolant({FZ_fl, A_fl}, MZ_fl, 'linear', 'nearest'); % linear interp, clamp outside
MZLUT_fr = griddedInterpolant({FZ_fr, A_fr}, MZ_fr, 'linear', 'nearest');
MZLUT_rl = griddedInterpolant({FZ_rl, A_rl}, MZ_rl, 'linear', 'nearest');
MZLUT_rr = griddedInterpolant({FZ_rr, A_rr}, MZ_rr, 'linear', 'nearest');



% Calculate forces and moments for the right front and rear tires
fl = FyLUT_fl(-fz_fl, alpha_fl);
fr = FyLUT_fr(-fz_fr, alpha_fr);
rl = FyLUT_rl(-fz_rl, alpha_rl);
rr = FyLUT_rr(-fz_rr, alpha_rr);

fl_mz = MZLUT_fl(-fz_fl, alpha_fl);
fr_mz = MZLUT_fr(-fz_fr, alpha_fr);
rl_mz = MZLUT_rl(-fz_rl, alpha_rl);
rr_mz = MZLUT_rr(-fz_rr, alpha_rr);





 Fx.fl = 0;
 Fy.fl = fl;
 Fz.fl = 0;
 Mx.fl = 0;
 My.fl = 0;
 Mz.fl = fl_mz;

 Fx.fr = 0;
 Fy.fr = fr;
 Fz.fr = 0;
 Mx.fr = 0;
 My.fr = 0;
 Mz.fr = fr_mz;

 Fx.rl = 0;
 Fy.rl = rl;
 Fz.rl = 0;
 Mx.rl = 0;
 My.rl = 0;
 Mz.rl = rl_mz;

 Fx.rr = rr;
 Fy.rr = 0;
 Fz.rr = 0;
 Mx.rr = 0;
 My.rr = 0;
 Mz.rr = rr_mz;




 

end