clc;
clear;
close all;

%% vehicle
P.m  = 815;
P.g  = 9.81;
P.h  = 0.35;
P.lf = 1.723644;
P.lr = 1.248156;
P.L  = P.lf + P.lr;
P.mf = P.m * P.lr / P.L;
P.mr = P.m * P.lf / P.L;

%% aero
P.rho     = 1.225;
P.CdA     = 1.33;
P.ACdLift = 0.58;
P.aeroBal = 0.33;

%% brake system
P.A_caliper_mm2 = 4486.0;
P.mu_k    = 0.4;
P.R_lever = 0.134;
P.Rw_f    = 0.30;
P.Rw_r    = 0.31;
P.Pmax    = 4000;

P.kF = P.A_caliper_mm2 * 1e-3 * P.mu_k * P.R_lever / P.Rw_f;
P.kR = P.A_caliper_mm2 * 1e-3 * P.mu_k * P.R_lever / P.Rw_r;

%% tire grip
% MEASURED, from the longitudinal slip curve in notmal_force_estimation.m: the
% 90th percentile of |Fx/Fz| over |kappa| = 0.02 to 0.05, the band the peak
% sits in. Read the envelope section at the end of that script for how each
% number is arrived at and how much it can be trusted.
%
% Both are the BRAKING branch, because that is the only thing this file
% schedules. The rear also reads on the drive branch, higher (about 1.39) and
% without any dependence on the brake split, but that is the number for a
% traction limit, not a brake bias.
%
% They are only as good as the cg height they were divided by: these come from
% cg_z = 0.35, matching P.h below. That is not a coincidence to preserve
% casually - if P.h changes here, the mu that belongs with it changes too, and
% the same is true of vehicleParams.cg_z in the other script.
%
% Together they reproduce the split-independent braking total to a few percent,
% which is the check that they are not both wrong in the same direction.
%
% The old 0.9/0.9 is kept below. Note it was not simply "too low" - it was too
% low at both ends but by different amounts, and it is the RATIO that sets the
% schedule this file writes.
P.muF = 0.95;
P.muR = 1.35;

% P.muF = 0.9;    % the assumption this file used before the measurement
% P.muR = 0.9;

% Rear mu on the DRIVE branch, for the traction limit rather than the brake
% schedule. This is the split-independent one - the car being RWD makes the
% whole of Fx rear, so no brake bias divides into it - and it reads higher than
% the braking number. It is also a lower bound: the drive branch had not rolled
% over by the end of the data it came from.
P.muR_drive = 1.45;

% LATERAL grip, per axle. Same role as muF/muR above, but for cornering.
%
% Tire values, supplied rather than fitted from this log.
%
% AXLE-level mu, which is the right quantity here and the only lateral grip
% number the log could support anyway. Per-TIRE lateral mu is not observable
% from axle forces plus an assumed left/right split - whatever load sensitivity
% you assume comes straight back out as the answer - so this file stays at axle
% level deliberately.
%
% Cross-check against the data. The corrected notmal_force_estimation.m reads
% the 95th percentile of |Fy_axle / Fz_axle| over |a_y| > 6 m/s^2 as
%
%       measured   front 1.385   rear 1.531     ratio f/r 0.90
%       tire       front 1.500   rear 1.750     ratio f/r 0.86
%
% The tire numbers are 8-14% higher, which is the expected direction: the log
% only reaches the peak where the driver actually took the car there, so a
% percentile over real laps is a lower bound on the tire. The RATIO is what
% sets the balance, and the two agree to 4% - both rear-biased. That agreement
% is the check worth having, and it only holds with the corrected l_f / l_r;
% before that fix the same data read front 1.888 / rear 1.104, ratio 1.71.
P.muYf = 1.50;
P.muYr = 1.75;

% Rear share of the brake force, as a multiplier on the rear's LOAD share:
% Fxr/Fx = k*Fzr / (Fzf + k*Fzr). k = 1 splits force in proportion to load,
% which puts both axles at the same utilisation ONLY when their grip is equal.
% It no longer is. Setting k = P.muR/P.muF splits in proportion to GRIP
% instead, which is what makes the two axles saturate together and is the
% ideal-bias case the envelope in notmal_force_estimation.m draws.
%
% Left at 1 deliberately: moving to grip-proportional asks the rear to do
% considerably more of the braking, and how much rear-lock margin to give up
% is a stability call, not a maths one.
P.k = 1;
P.rearSafety = 1;   % rear never uses more than 90% of its grip

% Nothing about the driveline appears anywhere in this file. Both limits it
% computes - braking and acceleration - are grip and F = ma: tire forces, aero,
% load transfer, and for braking the caliper pressure ceiling. Engine braking
% and engine-limited acceleration are real, and they belong to the driveline
% scripts (notmal_force_estimation.m carries the engine-brake term on its decel
% envelope; gear_shift_optimise.m has engine-limited acceleration). What a car
% actually does is those intersected with these.

%% acceleration and velocity sweep
aGrid = 0:0.004:40;
vGrid = linspace(0,100,400);

nA = numel(aGrid);
nV = numel(vGrid);

aMax = zeros(1,nV);
biasF = zeros(1,nV);
biasP = zeros(1,nV);
Pf_v = zeros(1,nV);
Pr_v = zeros(1,nV);
utilF_v = zeros(1,nV);
utilR_v = zeros(1,nV);
limitTag = strings(1,nV);
limitFound = false(1,nV);
biasP_map = nan(nA,nV);
Pf_map = nan(nA,nV);
Pr_map = nan(nA,nV);

for ia = 1:nA
    a_cmd = aGrid(ia);

    for iv = 1:nV
        if limitFound(iv)
            continue
        end

        v = vGrid(iv);
        Fd = 0.5*P.rho*P.CdA*v^2;
        DF = 0.5*P.rho*P.ACdLift*v^2;

        Fzf = P.mf*P.g + P.m*a_cmd*P.h/P.L + DF*P.aeroBal;
        Fzr = P.mr*P.g - P.m*a_cmd*P.h/P.L + DF*(1-P.aeroBal);
        Fzf = max(Fzf,0);
        Fzr = max(Fzr,0);

        % Total retarding force the tires must make, less what drag is
        % already doing.
        Fx_need = P.m*a_cmd - Fd;

        if Fx_need <= 0
            % Drag alone already makes the commanded decel.
            feasible = true;
            Fxf = 0;
            Fxr = 0;
            Pf = 0;
            Pr = 0;
            bF = NaN;
            bP = NaN;
            uF = 0;
            uR = 0;
            limit = "drag only";
        else
            W = Fzf + P.k*Fzr;
            Fxr_nom = Fx_need*P.k*Fzr/max(W,eps);
            Fxr_cap = min(P.rearSafety*P.muR*Fzr,2*P.kR*P.Pmax);
            Fxr = min(Fxr_nom,Fxr_cap);
            Fxf = Fx_need - Fxr;

            FxfGrip = P.muF*Fzf;
            FxfPress = 2*P.kF*P.Pmax;
            feasible = Fxf <= min(FxfGrip,FxfPress);

            if feasible
                if Fxr_nom <= Fxr_cap
                    limit = "balanced";
                else
                    limit = "rear-capped";
                end
            elseif FxfGrip <= FxfPress
                limit = "front grip";
            else
                limit = "front pressure";
            end

            Pf = Fxf/(2*P.kF);
            Pr = Fxr/(2*P.kR);
            bP = Pf/max(Pf+Pr,eps);
            bF = Fxf/max(Fxf+Fxr,eps);
            uF = Fxf/max(Fzf,eps);
            uR = Fxr/max(Fzr,eps);
        end

        if feasible
            biasP_map(ia,iv) = bP;
            Pf_map(ia,iv) = Pf;
            Pr_map(ia,iv) = Pr;
            aMax(iv) = a_cmd;
            biasF(iv) = bF;
            biasP(iv) = bP;
            Pf_v(iv) = Pf;
            Pr_v(iv) = Pr;
            utilF_v(iv) = uF;
            utilR_v(iv) = uR;
        else
            limitTag(iv) = limit;
            limitFound(iv) = true;
        end
    end
end

limitTag(~limitFound) = "search limit";

fprintf('solved: a_max %.2f-%.2f m/s^2\n',min(aMax),max(aMax));

%% CSV export: bias lookup table + max decel vs speed
% Breakpoints for the exported tables. Coarser than the solver grid on
% purpose - the solver runs at da = 0.004 m/s^2 over 400 speeds, which is
% 4e6 cells and useless as a CSV.
LUT.v = 0:1:100;      % speed breakpoints [m/s]
LUT.a = 0:0.25:20;   % commanded decel breakpoints [m/s^2]
                     % a_max peaks near 18 m/s^2 with the current grip and
                     % Pmax - raise this ceiling if you loosen either

outDir = fileparts(mfilename('fullpath'));
if isempty(outDir)
    outDir = pwd;    % running the cell by hand rather than the file
end
outDir = fullfile(outDir,'lut');
if ~exist(outDir,'dir')
    mkdir(outDir);
end

% Nearest-neighbour sample of the solved maps. The solver grid is much finer
% than the breakpoints (0.004 m/s^2 vs 0.25, 0.163 m/s vs 1.0), so the
% sampling error is far inside the breakpoint spacing, and unlike interp2 it
% does not smear NaN out of the infeasible region into valid cells.
[~,ivLut] = min(abs(vGrid(:).' - LUT.v(:)),[],2);
[~,iaLut] = min(abs(aGrid(:).' - LUT.a(:)),[],2);

biasP_lut = biasP_map(iaLut,ivLut);
Pf_lut    = Pf_map(iaLut,ivLut);
Pr_lut    = Pr_map(iaLut,ivLut);

% NaN in these maps = infeasible (above a_max); zero pressure on both axles
% = drag alone already makes the commanded decel, so bias is undefined.
brakesOn = isfinite(Pf_lut) & (Pf_lut + Pr_lut) > 0;

biasF_lut = nan(size(Pf_lut));
biasF_lut(brakesOn) = P.kF*Pf_lut(brakesOn) ./ ...
    (P.kF*Pf_lut(brakesOn) + P.kR*Pr_lut(brakesOn));

% Fill the undefined cells so a lookup always returns something usable, even
% if the driver/controller asks for a decel the car cannot make. Held along
% constant speed, i.e. down each column. Two different holes:
%
%   above a_max       infeasible. Hold bias AND pressures from a_max - that
%                     is the saturation behaviour you want anyway: a request
%                     past the limit returns the a_max answer for that speed.
%
%   below drag cut-in aero drag alone already makes the commanded decel, so
%                     the pressures are genuinely zero and stay zero. Only
%                     the ratio is 0/0, so hold the bias from the lowest
%                     decel that actually uses the brakes.
nLa = numel(LUT.a);
nLv = numel(LUT.v);

plotSolved  = false(nLa,nLv);   % masks for fig 4 - the plot masks share the
plotHeldTop = false(nLa,nLv);   % boundary row with the solved region so the
plotHeldBot = false(nLa,nLv);   % surfaces meet instead of leaving a gap
srcHeldTop  = false(nLa,nLv);
srcHeldBot  = false(nLa,nLv);

aLoLut = nan(1,nLv);  biasLoLut = nan(1,nLv);
aHiLut = nan(1,nLv);  biasHiLut = nan(1,nLv);

for iv = 1:nLv
    ib = find(brakesOn(:,iv));
    if isempty(ib)
        continue
    end
    lo = ib(1);
    hi = ib(end);

    biasP_lut(hi+1:end,iv) = biasP_lut(hi,iv);
    biasF_lut(hi+1:end,iv) = biasF_lut(hi,iv);
    Pf_lut(hi+1:end,iv)    = Pf_lut(hi,iv);
    Pr_lut(hi+1:end,iv)    = Pr_lut(hi,iv);
    srcHeldTop(hi+1:end,iv) = true;

    biasP_lut(1:lo-1,iv) = biasP_lut(lo,iv);
    biasF_lut(1:lo-1,iv) = biasF_lut(lo,iv);
    srcHeldBot(1:lo-1,iv) = true;

    plotSolved(lo:hi,iv)  = true;
    plotHeldTop(hi:end,iv) = true;
    plotHeldBot(1:lo,iv)   = true;

    aLoLut(iv) = LUT.a(lo);  biasLoLut(iv) = biasP_lut(lo,iv);
    aHiLut(iv) = LUT.a(hi);  biasHiLut(iv) = biasP_lut(hi,iv);
end

nBad = nnz(~isfinite(biasP_lut));
if nBad > 0
    warning('bias LUT still has %d undefined cells after fill',nBad);
end

srcTag = strings(nLa,nLv);
srcTag(brakesOn)   = "solved";
srcTag(srcHeldTop) = "held_above_amax";
srcTag(srcHeldBot) = "held_below_drag";

% 1) grid form - rows = commanded decel, columns = speed, cells = bias
biasGridTbl = array2table(biasP_lut,'VariableNames',compose('%g',LUT.v));
biasGridTbl = addvars(biasGridTbl,LUT.a(:),'Before',1, ...
    'NewVariableNames','decel_mps2');

writetable(biasGridTbl,fullfile(outDir,'brake_bias_map_grid.csv'));

% 1b) grid form again, with the bias floored at biasFloor
% Identical to the table above in every respect - same breakpoints, same
% solved cells, same held fill - except that no cell is allowed to sit below
% an even split. Wherever the solve asked for more rear than front, the
% clipped map hands the controller biasFloor instead.
%
% The clamp is applied HERE, on the way to the file, and nowhere upstream:
% biasP_lut itself is untouched, so every figure, print and long-form export
% that reads it still shows what the physics actually wanted. Only this one
% CSV, and the surface drawn from it below, carry the floor.
%
% The comparison leaves NaN alone (NaN < x is false), so a column the solver
% never got brakes onto stays undefined rather than silently becoming 0.5.
biasFloor = 0.5;

biasP_lut_clipped = biasP_lut;
biasP_lut_clipped(biasP_lut_clipped < biasFloor) = biasFloor;
nClipped = nnz(biasP_lut < biasFloor);

clippedGridTbl = array2table(biasP_lut_clipped,'VariableNames',compose('%g',LUT.v));
clippedGridTbl = addvars(clippedGridTbl,LUT.a(:),'Before',1, ...
    'NewVariableNames','decel_mps2');

writetable(clippedGridTbl,fullfile(outDir,'clipped_brake_bias_map_grid.csv'));

% 2) long form - one row per (speed, decel) breakpoint pair, no NaN, with a
%    source column so you can tell a solved cell from a held one
[VVlut,AAlut] = meshgrid(LUT.v,LUT.a);

biasLongTbl = table( ...
    VVlut(:), ...
    AAlut(:), ...
    AAlut(:)/P.g, ...
    biasP_lut(:), ...
    biasF_lut(:), ...
    Pf_lut(:), ...
    Pr_lut(:), ...
    srcTag(:), ...
    'VariableNames',{ ...
    'speed_mps', ...
    'decel_mps2', ...
    'decel_g', ...
    'bias_pressure', ...
    'bias_force', ...
    'Pf_kPa', ...
    'Pr_kPa', ...
    'source'});

biasLongTbl = sortrows(biasLongTbl,{'speed_mps','decel_mps2'});
writetable(biasLongTbl,fullfile(outDir,'brake_bias_map_long.csv'));

% 3) max decel vs speed. Two columns and nothing else, on a 4 m/s grid, in the
%    same shape as the engine-potential files in GGV_stuff - v_mps and
%    ax_max_mps2 - so the three curves can be read by one loader and put on one
%    pair of axes.
%
%    SIGNED: deceleration is negative a_x, so the column can be used as it
%    stands. Everything that used to ride along here (bias, pressures,
%    utilisation, what limited it) is per (speed, decel) cell in the long-form
%    bias file above, and on the console.
%
%    Interpolated onto the output grid rather than recomputed - the solver runs
%    at 0.25 m/s spacing, so a 4 m/s sample of it is exact to well inside the
%    solver's own decel step.
vOut = (0:4:max(vGrid)).';

maxDecelTbl = table( ...
    vOut, ...
    interp1(vGrid,-aMax,vOut,'linear'), ...
    'VariableNames',{'v_mps','ax_max_mps2'});

% maxDecelTbl is no longer written here. Max decel, max accel and max lateral
% are all exported together by the GRIP-SCALED LIMIT SET section near the end,
% which writes the nominal case and four derated ones from a single loop.

fprintf('CSV written to %s\n',outDir);
fprintf('  brake_bias_map_grid.csv   %d decel x %d speed breakpoints\n',nLa,nLv);
fprintf('  clipped_brake_bias_map_grid.csv   same grid, bias floored at %.2f (%d of %d cells raised)\n', ...
    biasFloor,nClipped,nLa*nLv);
fprintf('  brake_bias_map_long.csv   %d rows: %d solved, %d held above a_max, %d held below drag\n', ...
    height(biasLongTbl),nnz(brakesOn),nnz(srcHeldTop),nnz(srcHeldBot));
fprintf('  max_decel_vs_speed.csv    %d speeds at 4 m/s, a_x %.2f to %.2f m/s^2\n', ...
    height(maxDecelTbl),max(maxDecelTbl.ax_max_mps2),min(maxDecelTbl.ax_max_mps2));

%% max braking vs speed
figure;

axA(1) = subplot(3,1,1);
plot(vGrid,aMax,'b-'); hold on;
plot(vGrid,aMax./P.g,'r--');
grid on;
ylabel('Max decel');
legend('a_{max} [m/s^2]','a_{max} [g]','Location','best');
title(sprintf('Max braking vs speed  (P_{max} = %g kPa, \\mu = %.2f, k = %.2f, rearSafety = %.2f)', ...
    P.Pmax,P.muF,P.k,P.rearSafety));

axA(2) = subplot(3,1,2);
plot(vGrid,biasP,'b-'); hold on;
plot(vGrid,biasF,'g--');
grid on;
ylabel('Bias ');
legend('pressure bias','force bias','Location','best');

axA(3) = subplot(3,1,3);
plot(vGrid,Pf_v,'b-'); hold on;
plot(vGrid,Pr_v,'r-');
yline(P.Pmax,'k--','P_{max}');
grid on;
xlabel('Speed [m/s]');
ylabel('Line pressure [kPa]');
legend('front','rear','Location','best');

linkaxes(axA,'x');

%% limiting constraint
figure;

axB(1) = subplot(2,1,1);
plot(vGrid,utilF_v,'b-'); hold on;
plot(vGrid,utilR_v,'r-');
yline(P.muF,'b--','\mu_F');
yline(P.rearSafety*P.muR,'r--','rear ceiling');
grid on;
ylabel('Utilization F_x/F_z [-]');
legend('front','rear','Location','best');
title('Friction utilization at max braking');

axB(2) = subplot(2,1,2);
plot(vGrid,double(contains(limitTag,"pressure")),'k-');
grid on;
ylim([-0.2 1.2]);
yticks([0 1]);
yticklabels({'front grip','front pressure'});
ylabel('What caps a_{max}');
xlabel('Speed [m/s]');

linkaxes(axB,'x');

%% max acceleration vs speed
% Grip and F = ma, nothing else. No engine, no gearing, no torque map: this is
% what the TIRES allow, which is the ceiling any powertrain is working under.
% (Engine-limited acceleration lives in gear_shift_optimise.m, and the real
% number is the lower of the two.)
%
% The forces are the rear tires pushing and the air pushing back:
%
%     m*a = mu_R * Fz_r(v,a)  -  0.5*rho*CdA*v^2
%
% Implicit, because Fz_r carries the transfer term m*a*h/L - load moves onto the
% driven axle in proportion to the very acceleration being solved for. Solved by
% fixed point, which converges because each pass multiplies the error by
% mu*h/L, about 0.16 here.
%
% Both aero terms are in, and they pull opposite ways: downforce puts more load
% on the rear and helps, drag takes force straight off the top. With this car's
% CdA against its ACdLift the drag wins as speed rises, so the curve falls.
%
% One axle, because the car is RWD. And the rear grip is P.muR_drive rather
% than the P.muR the brake schedule runs on - different measurements of the
% same tire, and the drive one is both higher and free of any brake-split
% assumption.

aTire_v = zeros(1,nV);
FzrUp_v = zeros(1,nV);

accelTol     = 1e-9;
accelMaxIter = 200;

for iv = 1:nV

    v  = vGrid(iv);
    Fd = 0.5*P.rho*P.CdA*v^2;
    DF = 0.5*P.rho*P.ACdLift*v^2;

    a = 0;
    for iter = 1:accelMaxIter
        Fzr = max(P.mr*P.g + P.m*a*P.h/P.L + DF*(1-P.aeroBal),0);
        aNext = (P.muR_drive*Fzr - Fd)/P.m;
        if abs(aNext - a) < accelTol
            a = aNext;
            break
        end
        a = aNext;
    end

    aTire_v(iv) = a;
    FzrUp_v(iv) = max(P.mr*P.g + P.m*a*P.h/P.L + DF*(1-P.aeroBal),0);
end

aDrive_v = aTire_v;

fprintf('\nMAX ACCELERATION, grip-limited (mu_R drive %.3f, m %.0f kg)\n',P.muR_drive,P.m);
fprintf('  %.2f m/s^2 (%.2f g) at rest, %.2f at %.0f m/s\n', ...
    aDrive_v(1),aDrive_v(1)/P.g,aDrive_v(end),vGrid(end));

vTopIdx = find(aDrive_v <= 0,1);
if ~isempty(vTopIdx)
    fprintf('  rear grip meets drag at %.1f m/s - the tires cannot push past it\n', ...
        vGrid(vTopIdx));
end

% Two columns and nothing else, on the same 4 m/s grid and in the same shape as
% the engine-potential files: v_mps and ax_max_mps2. Positive, because this is
% acceleration. The loads and forces behind it are on the console and in the
% figure below rather than in the file.
accelTbl = table( ...
    vOut, ...
    interp1(vGrid,aDrive_v,vOut,'linear'), ...
    'VariableNames',{'v_mps','ax_max_mps2'});

% Written by the GRIP-SCALED LIMIT SET section, not here.

%% max acceleration plot
figure('Name','Max acceleration vs speed');

axC(1) = subplot(2,1,1);
plot(vGrid,aDrive_v,'-','LineWidth',2.2,'Color',[0.10 0.45 0.70]); hold on;
plot(vGrid,aDrive_v./P.g,'--','LineWidth',1.2,'Color',[0.67 0.23 0.30]);
yline(0,'-','Color',[0.5 0.5 0.5],'HandleVisibility','off');
grid on;
ylabel('Max acceleration');
legend('a_x [m/s^2]','a_x [g]','Location','best');
title(sprintf('Grip-limited acceleration  (\\mu_{R,drive} = %.3f, m = %.0f kg, CdA = %.2f, ACd = %.2f)', ...
    P.muR_drive,P.m,P.CdA,P.ACdLift));

axC(2) = subplot(2,1,2);
plot(vGrid,P.muR_drive*FzrUp_v,'-','LineWidth',1.6,'Color',[0.10 0.45 0.70]); hold on;
plot(vGrid,0.5*P.rho*P.CdA*vGrid.^2,'-','LineWidth',1.6,'Color',[0.67 0.23 0.30]);
grid on;
xlabel('Speed [m/s]');
ylabel('Force [N]');
legend('rear grip \mu_R F_{z,r}','aero drag','Location','best');
title('What sets the curve: grip rising with downforce, drag rising faster');

linkaxes(axC,'x');

%% acceleration and braking on one pair of axes
% The full longitudinal envelope: what the car can add and what it can shed at
% any speed, both from grip and F = ma.
%
% Nothing is exported from here - the two curves already went out as
% max_accel_vs_speed.csv and max_decel_vs_speed.csv, two columns each, which is
% what notmal_force_estimation.m reads back to draw them over its own measured
% envelope.

figure('Name','Longitudinal envelope: acceleration and braking');

plot(vGrid,aDrive_v,'-','LineWidth',2.2,'Color',[0.10 0.45 0.70]); hold on;
plot(vGrid,-aMax,'-','LineWidth',2.2,'Color',[0.67 0.23 0.30]);

yline(0,'-','Color',[0.5 0.5 0.5],'HandleVisibility','off');
grid on;
xlabel('Speed [m/s]');
ylabel('a_x [m/s^2]');
title('Longitudinal envelope');
legend('acceleration limit','braking limit','Location','best');

%% max lateral acceleration vs speed
% The cornering counterpart of the two longitudinal limits above: what a_y the
% TIRES allow at each speed, and which axle runs out first.
%
% AXLE LEVEL, on purpose. Each axle gets one lateral mu, exactly as the braking
% schedule gets one muF and one muR. No left/right split, no per-tire loads.
% That is not a shortcut to be replaced later - it is the honest limit of what
% this data supports. A dual-track lateral model needs mu(Fz) load sensitivity
% to do anything at all: with a constant mu the inside and outside tires sum to
% mu*(Fz_in + Fz_out) = mu*Fz_axle no matter how much load has transferred, so
% the extra structure returns the single-track answer with more steps.
%
% THE MODEL. Steady state, so no yaw acceleration and the moment about the CG
% balances:
%
%       Fyf * l_f = Fyr * l_r        and       Fyf + Fyr = m * a_y
%
%   ->  Fyf = m*a_y*l_r/L            Fyr = m*a_y*l_f/L
%
% The front carries l_r/L = 42% of the lateral force, the rear 58% - the same
% shares as the static weight, which is what "steady state" means here. Each
% axle is capped by its own grip, so
%
%       a_y,f_max = muYf * Fzf * L / (m * l_r)
%       a_y,r_max = muYr * Fzr * L / (m * l_f)
%
% and the car's limit is the smaller. Which one is smaller is the balance: front
% first is understeer, rear first is oversteer.
%
% NO LOAD TRANSFER TERM, and that is correct rather than an omission. Lateral
% transfer moves load ACROSS an axle, so it leaves the axle total - the only
% thing a single mu multiplies - unchanged. Longitudinal transfer is absent
% because this is the pure-cornering case, a_x = 0.
%
% EXPLICIT, no fixed point needed, unlike the acceleration solve: downforce
% depends on v alone, and with a_x = 0 nothing depends on a_y. The whole curve
% falls out in closed form.
%
% WHY IT IS NOT FLAT. At v = 0 both axles hit their limit at exactly mu*g,
% because the static load shares equal the mass shares. Aero breaks that tie:
% aeroBal = 0.33 puts 33% of downforce on the front while the front carries 42%
% of the mass, so downforce is biased REARWARD relative to the mass split and
% the car trends toward understeer as speed rises.

DF_v = 0.5*P.rho*P.ACdLift*vGrid.^2;

Fzf_lat = P.mf*P.g + DF_v*P.aeroBal;
Fzr_lat = P.mr*P.g + DF_v*(1-P.aeroBal);

ayFrontLimit = P.muYf .* Fzf_lat .* P.L ./ (P.m * P.lr);
ayRearLimit  = P.muYr .* Fzr_lat .* P.L ./ (P.m * P.lf);

ayMax_v = min(ayFrontLimit, ayRearLimit);

latLimitFront = ayFrontLimit <= ayRearLimit;   % true where the front gives up first

fprintf('\nMAX LATERAL ACCELERATION, grip-limited (mu_y front %.3f, rear %.3f)\n', ...
    P.muYf, P.muYr);
fprintf('  %.2f m/s^2 (%.2f g) at rest, %.2f m/s^2 (%.2f g) at %.0f m/s\n', ...
    ayMax_v(1), ayMax_v(1)/P.g, ayMax_v(end), ayMax_v(end)/P.g, vGrid(end));
fprintf('  downforce adds %.0f N by %.0f m/s, worth %+.2f g of lateral\n', ...
    DF_v(end), vGrid(end), (ayMax_v(end)-ayMax_v(1))/P.g);

if all(latLimitFront)
    fprintf('  the FRONT limits at every speed - understeer-limited throughout\n');
elseif ~any(latLimitFront)
    fprintf('  the REAR limits at every speed - oversteer-limited throughout\n');
else
    iCross = find(diff(latLimitFront) ~= 0, 1);
    axleNames = ["rear","front"];   % index by the logical + 1
    fprintf('  balance crosses at %.1f m/s: %s below, %s above\n', ...
        vGrid(iCross), ...
        axleNames(latLimitFront(1)+1), axleNames(latLimitFront(end)+1));
end

% How much lateral is left while the car also holds its speed. Pure cornering
% ignores that the rear has to push through drag to stay at v, and by 60 m/s
% that is a large slice of the rear's circle - so the pure number is optimistic
% at exactly the speeds where downforce makes it look best.
%
% Rear friction ellipse, front untouched (it makes no tractive force):
%
%       (Fx_r / (muR_drive*Fzr))^2 + (Fy_r / (muYr*Fzr))^2 = 1
%
% Solved for the lateral term, then converted back to a vehicle a_y through the
% same l_f/L share. The front limit is unchanged, so the trimmed limit is the
% smaller of it and the reduced rear.
FxDrag_v = 0.5*P.rho*P.CdA*vGrid.^2;

rearLongUtil = min(FxDrag_v ./ max(P.muR_drive*Fzr_lat, eps), 1);
rearLatScale = sqrt(max(1 - rearLongUtil.^2, 0));

ayRearLimit_trim = ayRearLimit .* rearLatScale;
ayMax_trim_v     = min(ayFrontLimit, ayRearLimit_trim);

fprintf('  holding speed costs the rear %.0f%% of its circle at %.0f m/s -> a_y %.2f g (vs %.2f g pure)\n', ...
    100*rearLongUtil(end), vGrid(end), ayMax_trim_v(end)/P.g, ayMax_v(end)/P.g);

% The balance can differ between the two cases, and does here: pure cornering is
% front-limited everywhere, but drag eats the rear's circle fast enough that
% above some speed the REAR becomes the limiting axle once the car also has to
% hold its speed. That is a stability statement, not a lap-time one, so it is
% worth its own line rather than being buried in the pure-cornering verdict.
latTrimFront = ayFrontLimit <= ayRearLimit_trim;

if all(latTrimFront)
    fprintf('  holding speed: FRONT still limits at every speed\n');
elseif ~any(latTrimFront)
    fprintf('  holding speed: REAR limits at every speed\n');
else
    iTrimCross = find(diff(latTrimFront) ~= 0, 1);
    fprintf('  holding speed: balance flips to the REAR above %.1f m/s (pure cornering never does)\n', ...
        vGrid(iTrimCross));
end

% Where the car actually operates. vGrid runs to 100 m/s, which this car does
% not see - the comp log tops out near 65 - so quote the in-range number too
% rather than letting the extrapolated end of the grid stand as the headline.
vRealIdx = find(vGrid <= 65, 1, 'last');

fprintf('  at 65 m/s (top of the measured range): %.2f g pure, %.2f g holding speed\n', ...
    ayMax_v(vRealIdx)/P.g, ayMax_trim_v(vRealIdx)/P.g);

%% max lateral acceleration plot
figure('Name','Max lateral acceleration vs speed');

axL(1) = subplot(2,1,1);
plot(vGrid,ayMax_v,'-','LineWidth',2.2,'Color',[0.10 0.45 0.70]); hold on;
plot(vGrid,ayMax_trim_v,'-','LineWidth',1.6,'Color',[0.85 0.45 0.10]);
plot(vGrid,ayFrontLimit,'--','LineWidth',1.2,'Color',[0.12 0.29 0.49]);
plot(vGrid,ayRearLimit,'--','LineWidth',1.2,'Color',[0.67 0.23 0.30]);
grid on;
ylabel('a_y [m/s^2]');
legend('a_y limit (pure cornering)','a_y limit (holding speed)', ...
    'front axle cap','rear axle cap','Location','best');
title(sprintf('Grip-limited lateral acceleration  (\\mu_{y,f} = %.3f, \\mu_{y,r} = %.3f, ACd = %.2f, aeroBal = %.2f)', ...
    P.muYf,P.muYr,P.ACdLift,P.aeroBal));

axL(2) = subplot(2,1,2);
plot(vGrid,double(~latLimitFront),'-','LineWidth',2.0,'Color',[0.10 0.45 0.70]); hold on;
plot(vGrid,double(~latTrimFront),'--','LineWidth',1.6,'Color',[0.85 0.45 0.10]);
grid on;
ylim([-0.2 1.2]);
yticks([0 1]);
yticklabels({'front (understeer)','rear (oversteer)'});
ylabel('Limiting axle');
xlabel('Speed [m/s]');
legend('pure cornering','holding speed','Location','best');

linkaxes(axL,'x');

%% CSV export: max lateral acceleration vs speed
% Two columns and the same 4 m/s grid as max_accel_vs_speed.csv and
% max_decel_vs_speed.csv, so it reads back exactly the same way.
%
% PURE CORNERING ONLY. The holding-speed variant is still computed and still
% plotted in the figure above, but it is deliberately not exported: this file is
% the tire limit, and a second column means every consumer has to decide which
% one it wants. Holding speed is a combined-slip question, and that belongs in a
% GG diagram rather than smuggled into a lateral-limit table.
latTbl = table( ...
    vOut, ...
    interp1(vGrid,ayMax_v,vOut,'linear'), ...
    'VariableNames',{'v_mps','ay_max_mps2'});

% Written by the GRIP-SCALED LIMIT SET section, not here.

%% PURE-CORNERING LATERAL LIMIT, printed
% The tire limit on its own, without the holding-speed column beside it. Printed
% as well as exported because this is the curve the a_y work in
% notmal_force_estimation.m compares against, and reading it off the console
% beats opening the CSV to check what the current mu produced.
%
% Pure cornering means a_x = 0: no longitudinal transfer, and no share of the
% friction circle spent on F_x. Aero downforce is in, drag is not - drag only
% matters once the car has to hold its speed, which is the other column.

latPure = table( ...
    latTbl.v_mps, ...
    latTbl.ay_max_mps2, ...
    latTbl.ay_max_mps2 / P.g, ...
    'VariableNames',{'v_mps','ay_max_mps2','ay_max_g'});

fprintf('\nPURE-CORNERING LATERAL LIMIT  (mu_y front %.3f, rear %.3f, ACd %.2f, aeroBal %.2f)\n', ...
    P.muYf, P.muYr, P.ACdLift, P.aeroBal);
latAxleNames = ["rear","front"];   % index by the logical + 1
fprintf('Tires only, a_x = 0. Downforce in, drag out. Limiting axle: %s\n', ...
    latAxleNames(latLimitFront(1)+1));

disp(latPure);

fprintf('  at rest %.3f g  (= min(mu_yf, mu_yr) x g, since with no aero the load\n', ...
    ayMax_v(1)/P.g);
fprintf('  shares equal the mass shares and the smaller mu decides)\n');
fprintf('  at 65 m/s, the top of the measured range: %.3f g\n', ...
    interp1(vGrid, ayMax_v, 65) / P.g);

%% bias map, read back from the exported CSV
% Plotted from lut/brake_bias_map_grid.csv rather than from biasP_map still in
% memory. What a controller looks up is the FILE - its breakpoints, its held
% fill and all - so drawing the file checks the export as well as the solve. A
% figure sourced from memory can look right while the CSV is wrong.
%
% Because it is the file, nothing is blank: the region above a_max carries the
% held values the export puts there. The a_max line marks where the solved
% region ends and the fill begins.
biasCsvPath = fullfile(outDir,'brake_bias_map_grid.csv');

fid = fopen(biasCsvPath,'r');
biasCsvHeader = fgetl(fid);
fclose(fid);

biasCsvSpeed = str2double(strsplit(strtrim(biasCsvHeader),','));
biasCsvSpeed = biasCsvSpeed(2:end);      % first cell names the decel column

biasCsvRaw = readmatrix(biasCsvPath);
biasCsvRaw = biasCsvRaw(isfinite(biasCsvRaw(:,1)),:);

biasCsvDecel = biasCsvRaw(:,1);
biasCsvMap   = biasCsvRaw(:,2:end);

if numel(biasCsvSpeed) ~= size(biasCsvMap,2)
    error('brake_bias_schedule:biasCsvShape', ...
        '%s has %d bias columns but %d speed breakpoints in its header.', ...
        biasCsvPath,size(biasCsvMap,2),numel(biasCsvSpeed));
end

fprintf('bias map figure read back from %s (%d decel x %d speed)\n', ...
    biasCsvPath,numel(biasCsvDecel),numel(biasCsvSpeed));

[VV,AA] = meshgrid(biasCsvSpeed,biasCsvDecel);

figure('Name','Bias schedule, as written to CSV');
pcolor(VV,AA,biasCsvMap);
shading interp;
cb = colorbar;
ylabel(cb,'Pressure bias P_f/(P_f+P_r)');
hold on;
plot(vGrid,aMax,'w-','LineWidth',2);
plot(vGrid,aMax,'k--','LineWidth',1.2);

validBias = biasCsvMap(isfinite(biasCsvMap));
if ~isempty(validBias)
    % robust color limits: the rear-capped strip near the limit spikes the
    % bias toward ~0.9, which otherwise flattens all interior contrast.
    vb = sort(validBias(:));
    cLo = vb(1);
    cHi = vb(max(1,round(0.97*numel(vb))));
    if cHi <= cLo
        cHi = cLo + eps;
    end
    caxis([cLo cHi]);

    lv = linspace(cLo,cHi,9);
    [C,hC] = contour(VV,AA,biasCsvMap,lv,'k-');
    clabel(C,hC,'FontSize',8,'Color','k');
end

grid on;
xlabel('Speed [m/s]');
ylabel('Commanded decel [m/s^2]');
title('Bias schedule from brake\_bias\_map\_grid.csv (line = max achievable decel)');

%% 3D bias schedule surface  (bias vs speed & commanded long decel)
% Drawn from the exported LUT rather than the solver grid, so what you see is
% exactly what the CSV contains - including the held fill, which is the whole
% point: colour-mapped = solved from the physics, red = held down from a_max,
% amber = held up from the drag cut-in. Anything not colour-mapped is a value
% the controller can still use but that the vehicle cannot actually deliver.
figure('Name','Fig 4 - Bias schedule with held fill','Position',[160 120 950 620]);

Zsolved = biasP_lut;  Zsolved(~plotSolved)  = NaN;
Zheld   = biasP_lut;  Zheld(~plotHeldTop)   = NaN;
Zdrag   = biasP_lut;  Zdrag(~plotHeldBot)   = NaN;

hSolved = surf(VVlut,AAlut,Zsolved);
set(hSolved,'FaceColor','interp','EdgeColor',[0.25 0.25 0.25],'EdgeAlpha',0.15);
hold on;

hHeld = surf(VVlut,AAlut,Zheld);
set(hHeld,'FaceColor',[0.85 0.10 0.10],'EdgeColor',[0.35 0 0],'EdgeAlpha',0.15);

hDrag = surf(VVlut,AAlut,Zdrag);
set(hDrag,'FaceColor',[0.95 0.65 0.15],'EdgeColor',[0.40 0.25 0],'EdgeAlpha',0.15);

% edges of the genuinely solved region
plot3(LUT.v,aHiLut,biasHiLut,'k-','LineWidth',2);
plot3(LUT.v,aLoLut,biasLoLut,'k--','LineWidth',1.5);

hLeg(1) = plot3(NaN,NaN,NaN,'s','MarkerSize',10, ...
    'MarkerFaceColor',[0.20 0.50 0.80],'MarkerEdgeColor','none');
hLeg(2) = plot3(NaN,NaN,NaN,'s','MarkerSize',10, ...
    'MarkerFaceColor',[0.85 0.10 0.10],'MarkerEdgeColor','none');
hLeg(3) = plot3(NaN,NaN,NaN,'s','MarkerSize',10, ...
    'MarkerFaceColor',[0.95 0.65 0.15],'MarkerEdgeColor','none');
hLeg(4) = plot3(NaN,NaN,NaN,'k-','LineWidth',2);

legend(hLeg, ...
    {'calculated max decel', ...
     'dont ever want to be here ...', ...
     'drag will do the work ', ...
     'ax max'}, ...
    'Location','best');

cb = colorbar;
ylabel(cb,'Pressure bias P_f/(P_f+P_r)');
xlabel('Speed [m/s]');
ylabel('Commanded long. decel [m/s^2]');
zlabel('Brake bias');
title('bias');
grid on;
view(135,25);
axis tight;

%% 3D clipped bias schedule surface  (bias floored at biasFloor)
% The same surface as Fig 4, drawn from biasP_lut_clipped - i.e. from what
% clipped_brake_bias_map_grid.csv holds. Same three regions and the same
% colours: colour-mapped = solved from the physics, red = held down from
% a_max, amber = held up from the drag cut-in.
%
% The floor shows up as a flat shelf at biasFloor wherever the unclipped
% surface dipped below it. A grey wireframe of the unclipped surface is drawn
% underneath so you can see how far the clamp had to lift each cell; where the
% two coincide the clamp did nothing.
figure('Name','Fig 4b - Clipped bias schedule with held fill','Position',[200 100 950 620]);

ZsolvedC = biasP_lut_clipped;  ZsolvedC(~plotSolved)  = NaN;
ZheldC   = biasP_lut_clipped;  ZheldC(~plotHeldTop)   = NaN;
ZdragC   = biasP_lut_clipped;  ZdragC(~plotHeldBot)   = NaN;

hSolvedC = surf(VVlut,AAlut,ZsolvedC);
set(hSolvedC,'FaceColor','interp','EdgeColor',[0.25 0.25 0.25],'EdgeAlpha',0.15);
hold on;

hHeldC = surf(VVlut,AAlut,ZheldC);
set(hHeldC,'FaceColor',[0.85 0.10 0.10],'EdgeColor',[0.35 0 0],'EdgeAlpha',0.15);

hDragC = surf(VVlut,AAlut,ZdragC);
set(hDragC,'FaceColor',[0.95 0.65 0.15],'EdgeColor',[0.40 0.25 0],'EdgeAlpha',0.15);

% the unclipped surface underneath, as a mesh, to show what the floor lifted
hRaw = mesh(VVlut,AAlut,biasP_lut);
set(hRaw,'FaceColor','none','EdgeColor',[0.45 0.45 0.45],'EdgeAlpha',0.25);

% edges of the genuinely solved region, floored the same way
biasHiClip = biasHiLut;  biasHiClip(biasHiClip < biasFloor) = biasFloor;
biasLoClip = biasLoLut;  biasLoClip(biasLoClip < biasFloor) = biasFloor;

plot3(LUT.v,aHiLut,biasHiClip,'k-','LineWidth',2);
plot3(LUT.v,aLoLut,biasLoClip,'k--','LineWidth',1.5);

hLegC(1) = plot3(NaN,NaN,NaN,'s','MarkerSize',10, ...
    'MarkerFaceColor',[0.20 0.50 0.80],'MarkerEdgeColor','none');
hLegC(2) = plot3(NaN,NaN,NaN,'s','MarkerSize',10, ...
    'MarkerFaceColor',[0.85 0.10 0.10],'MarkerEdgeColor','none');
hLegC(3) = plot3(NaN,NaN,NaN,'s','MarkerSize',10, ...
    'MarkerFaceColor',[0.95 0.65 0.15],'MarkerEdgeColor','none');
hLegC(4) = plot3(NaN,NaN,NaN,'k-','LineWidth',2);
hLegC(5) = plot3(NaN,NaN,NaN,'-','Color',[0.45 0.45 0.45],'LineWidth',1.5);

legend(hLegC, ...
    {'calculated max decel', ...
     'dont ever want to be here ...', ...
     'drag will do the work ', ...
     'ax max', ...
     'unclipped surface'}, ...
    'Location','best');

cbC = colorbar;
ylabel(cbC,'Pressure bias P_f/(P_f+P_r)');
xlabel('Speed [m/s]');
ylabel('Commanded long. decel [m/s^2]');
zlabel('Brake bias');
title(sprintf('bias, clipped to a %.2f minimum',biasFloor));
grid on;
view(135,25);
axis tight;


%% rearSafety trade-off:  full grip (=1) vs margined rear (=0.9)
aMax_full = computeAMax(P,vGrid,aGrid,1.0);          % rear allowed to lock point
aMax_safe = aMax;                                    % current run (P.rearSafety)

figure('Name','Fig 5 - Rear-safety trade-off','Position',[140 140 900 520]);
plot(vGrid,aMax_full,'k-'); hold on;
plot(vGrid,aMax_safe,'r-');
grid on;
xlabel('Speed [m/s]');
ylabel('Max decel [m/s^2]');
legend('rearSafety = 1.0 (both axles lock together)', ...
       sprintf('rearSafety = %.2f (front locks first)',P.rearSafety), ...
       'Location','best');
lossPct = 100*mean((aMax_full-aMax_safe)./max(aMax_full,eps));
title(sprintf('Peak decel traded for rear margin  (avg loss %.1f%%)',lossPct));

%% stop simulation
v0 = 100;
dt = 0.002;
nStep = round(12/dt);

sim.t = zeros(nStep,1);
sim.v = zeros(nStep,1);
sim.a = zeros(nStep,1);
sim.s = zeros(nStep,1);
sim.biasP = zeros(nStep,1);
sim.biasF = zeros(nStep,1);
sim.Pf = zeros(nStep,1);
sim.Pr = zeros(nStep,1);
sim.Fzf = zeros(nStep,1);
sim.Fzr = zeros(nStep,1);

v = v0;
dist = 0;
n = 0;

for i = 1:nStep
    if v <= 0.5
        break
    end

    vLookup = min(max(v,vGrid(1)),vGrid(end));
    a = interp1(vGrid,aMax,vLookup);
    bP = interp1(vGrid,biasP,vLookup);
    bF = interp1(vGrid,biasF,vLookup);
    Pf = interp1(vGrid,Pf_v,vLookup);
    Pr = interp1(vGrid,Pr_v,vLookup);

    DF = 0.5*P.rho*P.ACdLift*v^2;
    Fzf = P.mf*P.g + P.m*a*P.h/P.L + DF*P.aeroBal;
    Fzr = P.mr*P.g - P.m*a*P.h/P.L + DF*(1-P.aeroBal);

    n = n + 1;
    sim.t(n) = (i-1)*dt;
    sim.v(n) = v;
    sim.a(n) = a;
    sim.s(n) = dist;
    sim.biasP(n) = bP;
    sim.biasF(n) = bF;
    sim.Pf(n) = Pf;
    sim.Pr(n) = Pr;
    sim.Fzf(n) = max(Fzf,0);
    sim.Fzr(n) = max(Fzr,0);

    dist = dist + v*dt - 0.5*a*dt^2;
    v = v - a*dt;
end

f = fieldnames(sim);
for i = 1:numel(f)
    sim.(f{i}) = sim.(f{i})(1:n);
end

figure;

axD(1) = subplot(4,1,1);
plot(sim.t,sim.v,'b-','LineWidth',1.8);
grid on;
ylabel('Speed [m/s]');
title(sprintf('Max braking from %.0f m/s: stop in %.2f s / %.1f m', ...
    v0,sim.t(end),sim.s(end)));

axD(2) = subplot(4,1,2);
plot(sim.t,sim.a,'b-','LineWidth',1.8); hold on;
plot(sim.t,sim.a./P.g,'r--','LineWidth',1.2);
grid on;
ylabel('Decel');
legend('[m/s^2]','[g]','Location','best');

axD(3) = subplot(4,1,3);
plot(sim.t,sim.biasP,'b-','LineWidth',1.8); hold on;
plot(sim.t,sim.biasF,'g--','LineWidth',1.4);
grid on;
ylabel('Bias (front)');
legend('pressure bias','force bias','Location','best');

axD(4) = subplot(4,1,4);
plot(sim.t,sim.Pf,'b-','LineWidth',1.8); hold on;
plot(sim.t,sim.Pr,'r-','LineWidth',1.8);
yline(P.Pmax,'k--','P_{max}');
grid on;
xlabel('Time [s]');
ylabel('Pressure [kPa]');
legend('front','rear','Location','best');

linkaxes(axD,'x');







%% front and rear axle limits vs mu

muSweep = linspace(0.4,1.5,111);
vTest = [20 40 60 70];

nMu = numel(muSweep);
nVT = numel(vTest);

aFrontLimit = zeros(nMu,nVT);
aRearLimit = zeros(nMu,nVT);
aVehicleLimit = zeros(nMu,nVT);

frontConstraint = strings(nMu,nVT);
rearConstraint = strings(nMu,nVT);
limitingAxle = strings(nMu,nVT);
limitingConstraint = strings(nMu,nVT);

aStep = aGrid(2)-aGrid(1);
forceTol = 1e-6;

for im = 1:nMu
    mu = muSweep(im);

    frontDone = false(1,nVT);
    rearDone = false(1,nVT);

    for ia = 1:nA
        a_cmd = aGrid(ia);

        for iv = 1:nVT
            v = vTest(iv);

            Fd = 0.5*P.rho*P.CdA*v^2;
            DF = 0.5*P.rho*P.ACdLift*v^2;

            Fzf = P.mf*P.g + P.m*a_cmd*P.h/P.L ...
                + DF*P.aeroBal;

            Fzr = P.mr*P.g - P.m*a_cmd*P.h/P.L ...
                + DF*(1-P.aeroBal);

            Fzf = max(Fzf,0);
            Fzr = max(Fzr,0);

            Fx_need = max(P.m*a_cmd-Fd,0);

            W = Fzf + P.k*Fzr;

            Fxr_req = Fx_need*P.k*Fzr/max(W,eps);
            Fxf_req = Fx_need-Fxr_req;

            FxfGripCap = mu*Fzf;
            FxrGripCap = P.rearSafety*mu*Fzr;

            FxfPressCap = 2*P.kF*P.Pmax;
            FxrPressCap = 2*P.kR*P.Pmax;

            FxfCap = min(FxfGripCap,FxfPressCap);
            FxrCap = min(FxrGripCap,FxrPressCap);

            if ~frontDone(iv)
                if Fxf_req <= FxfCap + forceTol
                    aFrontLimit(im,iv) = a_cmd;
                else
                    frontDone(iv) = true;

                    if FxfGripCap <= FxfPressCap
                        frontConstraint(im,iv) = "front grip";
                    else
                        frontConstraint(im,iv) = "front pressure";
                    end
                end
            end

            if ~rearDone(iv)
                if Fxr_req <= FxrCap + forceTol
                    aRearLimit(im,iv) = a_cmd;
                else
                    rearDone(iv) = true;

                    if FxrGripCap <= FxrPressCap
                        rearConstraint(im,iv) = "rear grip";
                    else
                        rearConstraint(im,iv) = "rear pressure";
                    end
                end
            end
        end

        if all(frontDone & rearDone)
            break
        end
    end

    for iv = 1:nVT
        if ~frontDone(iv)
            frontConstraint(im,iv) = "search limit";
        end

        if ~rearDone(iv)
            rearConstraint(im,iv) = "search limit";
        end

        aVehicleLimit(im,iv) = min( ...
            aFrontLimit(im,iv),aRearLimit(im,iv));

        if abs(aFrontLimit(im,iv)-aRearLimit(im,iv)) <= aStep
            limitingAxle(im,iv) = "both";
            limitingConstraint(im,iv) = ...
                frontConstraint(im,iv) + " / " + ...
                rearConstraint(im,iv);

        elseif aFrontLimit(im,iv) < aRearLimit(im,iv)
            limitingAxle(im,iv) = "front";
            limitingConstraint(im,iv) = ...
                frontConstraint(im,iv);

        else
            limitingAxle(im,iv) = "rear";
            limitingConstraint(im,iv) = ...
                rearConstraint(im,iv);
        end
    end
end

%% axle limit plot

figure;

nRow = ceil(numel(vTest)/2);
tiledlayout(nRow,2);

for iv = 1:nVT
    nexttile;

    plot(muSweep,aFrontLimit(:,iv), ...
        'b-','LineWidth',1.8);
    hold on;

    plot(muSweep,aRearLimit(:,iv), ...
        'r-','LineWidth',1.8);

    plot(muSweep,aVehicleLimit(:,iv), ...
        'k--','LineWidth',1.5);

    grid on;
    xlabel('\mu_x');
    ylabel('Deceleration limit [m/s^2]');
    title(sprintf('v = %.0f m/s',vTest(iv)));

    legend('Front limit','Rear limit', ...
        'First axle limit','Location','best');
end

%% limiting axle plot

limitNumber = zeros(nMu,nVT);
limitNumber(limitingAxle == "front") = 1;
limitNumber(limitingAxle == "both") = 2;
limitNumber(limitingAxle == "rear") = 3;

figure('Name','Limiting axle vs mu', ...
    'Position',[180 120 850 520]);

plot(muSweep,limitNumber,'LineWidth',1.8);
grid on;
ylim([0.8 3.2]);
yticks([1 2 3]);
yticklabels({'Front','Both','Rear'});
xlabel('\mu_x');
ylabel('First limiting axle');
legend(compose('v = %.0f m/s',vTest), ...
    'Location','best');
title('First axle to reach its grip or pressure limit');

%% mu / aero-drag sensitivity  (vx vs ax)
% Conservative bracket for working up to the limit on track: how far does the
% achievable decel curve fall if the tyres are worse than nominal AND the drag
% help we are counting on is not really there.
%
%   muDrop    absolute reduction applied to both muF and muR, keeping the 0.05
%             front/rear offset. nominal, -0.2, -0.4, -0.6.
%   dragKeep  fraction of nominal aero drag retained, 100% down to 0% in 20%
%             steps. Downforce (ACdLift) is deliberately held at nominal, so
%             this isolates the "free" decel that drag contributes and does
%             not also strip out the grip that downforce buys. Scale DF in
%             computeAMax too if you want a full aero bracket instead.
muDrop   = 0:0.2:0.6;
dragKeep = 1:-0.2:0;

nMuS   = numel(muDrop);
nDragS = numel(dragKeep);

aMaxSens = zeros(nV,nDragS,nMuS);

for im = 1:nMuS
    for id = 1:nDragS
        aSens = computeAMax(P,vGrid,aGrid,P.rearSafety, ...
            P.muF-muDrop(im),P.muR-muDrop(im),dragKeep(id));
        aMaxSens(:,id,im) = aSens(:);
    end
end

%% sensitivity envelope, resampled for the plots below
% The CSV exports that used to live here - decel_envelope_g_grid.csv,
% decel_envelope_g_long.csv and the per-aero-level a_max_drag*.csv set - have
% been removed. The LUT folder now carries the grip-scaled limit set instead,
% which is a cleaner statement of the same idea: one knob (grip fraction) rather
% than two crossed sweeps (mu drop x drag fraction). The sweep itself is kept
% because the figures below still draw it.
vExport = ceil(vGrid(1)/4)*4 : 4 : floor(vGrid(end)/4)*4;
nEx = numel(vExport);

gSens = zeros(nEx,nDragS,nMuS);
for im = 1:nMuS
    for id = 1:nDragS
        gSens(:,id,im) = interp1(vGrid,aMaxSens(:,id,im),vExport(:))/P.g;
    end
end

vAero = 0:4:72;

imNom = find(muDrop == 0,1);
if isempty(imNom)
    error('nominal mu case (muDrop = 0) is not in the sweep');
end

% Ordinal blue ramp, dark = full drag, light = none. Drag fraction is ordered
% magnitude, so it takes one hue light->dark and not a rainbow or a red/blue
% pair - the reader should see the order in the colour itself.
dragCols = [ ...
    0.051 0.212 0.420; ...   % 100% drag (nominal)
    0.063 0.259 0.506; ...   %  80%
    0.110 0.361 0.671; ...   %  60%
    0.165 0.471 0.839; ...   %  40%
    0.333 0.596 0.906; ...   %  20%
    0.525 0.714 0.937];      %   0%

figure('Name','Fig 9 - mu / aero-drag sensitivity','Position',[120 90 1050 720]);
tSens = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

yTop = 1.05*max(aMaxSens(:));

for im = 1:nMuS
    axS = nexttile;
    hold(axS,'on');

    hDrag = gobjects(1,nDragS);
    for id = 1:nDragS
        hDrag(id) = plot(vGrid,aMaxSens(:,id,im), ...
            'Color',dragCols(id,:));
    end

    grid on;
    axS.GridAlpha = 0.12;      % recessive grid, the curves carry the message
    axS.Box = 'off';
    xlim([vGrid(1) vGrid(end)]);
    ylim([0 yTop]);            % shared scale so the panels are comparable

    ttl = sprintf('\\mu_F = %.2f,  \\mu_R = %.2f', ...
        P.muF-muDrop(im),P.muR-muDrop(im));
    if muDrop(im) == 0
        ttl = [ttl '   (nominal)'];
    else
        ttl = sprintf('%s   (nominal - %.1f)',ttl,muDrop(im));
    end
    title(ttl);

    if im > nMuS-2
        xlabel('Speed v_x [m/s]');
    end
    if mod(im,2) == 1
        ylabel('Max decel a_x [m/s^2]');
    end

    if im == 1
        legend(hDrag,compose('%.0f%% aero drag',100*dragKeep), ...
            'Location','northwest','Box','off');
    end
end

title(tSens,sprintf(['Achievable decel envelope: tyre \\mu and aero-drag sensitivity' ...
    '   (P_{max} = %g kPa, rearSafety = %.2f)'],P.Pmax,P.rearSafety));

%% GRIP-SCALED LIMIT SET  ->  lut/
%
% The whole vehicle limit envelope at five grip levels: max acceleration, max
% deceleration and max lateral, each as a two-column v_mps / a file on the same
% 4 m/s grid. Fifteen files.
%
% THE 100% CASE IS THE ULTIMATE LIMIT. mu100 uses the friction values set at the
% top of this file exactly as they stand - muF/muR for braking, muR_drive for
% traction, muYf/muYr for cornering. That is the most the tires can ever give,
% and nothing the car does on track should exceed it.
%
% The other four scale every one of those mu by a fixed fraction of NOMINAL, not
% compounding: 95%, 90%, 85%, 80% of the mu100 values. So mu080 is 0.80 x the
% nominal mu, not 0.95^4. That keeps the label honest - "mu085" really is 85% of
% the ultimate grip - and makes the set usable as a confidence bracket: pick the
% level that matches how much of the tire you actually trust on the day.
%
% Scaling mu is NOT the same as scaling the resulting acceleration. Load transfer
% and aero both re-solve at the new grip, and for acceleration the fixed point
% shifts too, so a 5% grip cut does not give a 5% acceleration cut. Braking also
% carries a caliper pressure ceiling that does not scale with grip at all - at
% the higher grip levels the front can become pressure-limited rather than
% grip-limited, and then extra mu buys nothing. That is exactly why these are
% solved rather than multiplied.
%
% What is NOT in here any more: the aero-drag percentage sweep. One grip knob is
% a clearer bracket than mu-drop crossed with drag-fraction, and drag is a
% property of the car rather than something to derate.

gripScale = [1.00 0.95 0.90 0.85 0.80];

vLUT = (0:4:max(vGrid)).';

fprintf('\nGRIP-SCALED LIMIT SET -> %s\n', outDir);
fprintf('  %-7s %-6s %-6s %-6s %-6s %-6s | %8s %8s %8s\n', ...
    'file', 'muF', 'muR', 'muRdrv', 'muYf', 'muYr', ...
    'ax_drive', 'ax_brake', 'ay_max');

for iG = 1:numel(gripScale)

    sG  = gripScale(iG);
    tag = sprintf('mu%03d', round(100*sG));

    % --- max deceleration, positive m/s^2 in the file ---
    aDecelG = computeAMax(P, vGrid, aGrid, P.rearSafety, sG*P.muF, sG*P.muR);

    % --- max acceleration, rear grip against drag, fixed point ---
    aAccelG = computeADrive(P, vGrid, sG*P.muR_drive);

    % --- max lateral, pure cornering, closed form ---
    DFg  = 0.5*P.rho*P.ACdLift*vGrid.^2;
    ayFg = sG*P.muYf .* (P.mf*P.g + DFg*P.aeroBal)     .* P.L ./ (P.m * P.lr);
    ayRg = sG*P.muYr .* (P.mr*P.g + DFg*(1-P.aeroBal)) .* P.L ./ (P.m * P.lf);
    aLatG = min(ayFg, ayRg);

    % Decel is written NEGATIVE, matching the sign convention the unsuffixed
    % max_decel_vs_speed.csv always used and what the GGV consumers downstream
    % expect. computeAMax returns a positive magnitude, so it is negated here.
    accelG = interp1(vGrid,  aAccelG, vLUT, 'linear');
    decelG = interp1(vGrid, -aDecelG, vLUT, 'linear');
    latG   = interp1(vGrid,  aLatG,   vLUT, 'linear');

    writetable(table(vLUT, accelG, 'VariableNames',{'v_mps','ax_max_mps2'}), ...
        fullfile(outDir, sprintf('max_accel_vs_speed_%s.csv', tag)));

    writetable(table(vLUT, decelG, 'VariableNames',{'v_mps','ax_max_mps2'}), ...
        fullfile(outDir, sprintf('max_decel_vs_speed_%s.csv', tag)));

    writetable(table(vLUT, latG, 'VariableNames',{'v_mps','ay_max_mps2'}), ...
        fullfile(outDir, sprintf('max_lat_accel_vs_speed_%s.csv', tag)));

    fprintf('  %-7s %-6.3f %-6.3f %-6.3f %-6.3f %-6.3f | %8.2f %8.2f %8.2f\n', ...
        tag, sG*P.muF, sG*P.muR, sG*P.muR_drive, sG*P.muYf, sG*P.muYr, ...
        max(accelG), min(decelG), max(latG));
end

fprintf('  %d files, %d speeds each at 4 m/s (0-%g m/s)\n', ...
    3*numel(gripScale), numel(vLUT), vLUT(end));

%% results table

[MU,VT] = ndgrid(muSweep,vTest);

axleLimitTable = table( ...
    MU(:), ...
    VT(:), ...
    aFrontLimit(:), ...
    aRearLimit(:), ...
    aVehicleLimit(:), ...
    limitingAxle(:), ...
    frontConstraint(:), ...
    rearConstraint(:), ...
    limitingConstraint(:), ...
    'VariableNames',{ ...
    'mu', ...
    'speed_mps', ...
    'front_limit_mps2', ...
    'rear_limit_mps2', ...
    'first_limit_mps2', ...
    'limiting_axle', ...
    'front_constraint', ...
    'rear_constraint', ...
    'limiting_constraint'});

%% selected mu values

muReport = [0.7 0.9 1.15 1.3];
reportRows = false(height(axleLimitTable),1);

for i = 1:numel(muReport)
    [~,im] = min(abs(muSweep-muReport(i)));

    reportRows = reportRows | ...
        abs(axleLimitTable.mu-muSweep(im)) < 1e-10;
end

disp(axleLimitTable(reportRows,:));

%% helper: grip-limited acceleration vs speed, for a given rear drive mu
%
% Same fixed point as the "max acceleration vs speed" section, factored out so
% the grip sweep can call it per level:
%
%     m*a = mu_R * Fz_r(v,a) - drag
%
% implicit because Fz_r carries the m*a*h/L transfer term. Converges because each
% pass multiplies the error by mu*h/L, about 0.17 at nominal grip.
function aDrive = computeADrive(P, vGrid, muRdrive)

    v  = vGrid(:).';
    Fd = 0.5*P.rho*P.CdA*v.^2;
    DF = 0.5*P.rho*P.ACdLift*v.^2;

    aDrive = zeros(1,numel(v));

    for iv = 1:numel(v)

        a = 0;

        for iter = 1:200
            Fzr   = max(P.mr*P.g + P.m*a*P.h/P.L + DF(iv)*(1-P.aeroBal), 0);
            aNext = (muRdrive*Fzr - Fd(iv))/P.m;

            if abs(aNext - a) < 1e-9
                a = aNext;
                break
            end

            a = aNext;
        end

        aDrive(iv) = a;
    end
end


%% helper: max decel vs speed, for a given rear-safety factor, tyre mu and
%  aero-drag fraction. muF/muR/dragKeep default to the nominal P values, so
%  the original computeAMax(P,vGrid,aGrid,rearSafety) call still works.
%
%  Vectorised over speed rather than looped: the sensitivity sweep calls this
%  24 times over a 10001-point decel grid, which is too slow element-by-element.
function aMax = computeAMax(P,vGrid,aGrid,rearSafety,muF,muR,dragKeep)
    if nargin < 5 || isempty(muF),      muF = P.muF;  end
    if nargin < 6 || isempty(muR),      muR = P.muR;  end
    if nargin < 7 || isempty(dragKeep), dragKeep = 1; end

    v = vGrid(:).';
    nV = numel(v);

    Fd = dragKeep*0.5*P.rho*P.CdA*v.^2;
    DF = 0.5*P.rho*P.ACdLift*v.^2;

    FxfPress = 2*P.kF*P.Pmax;
    FxrPress = 2*P.kR*P.Pmax;

    aMax = zeros(1,nV);
    active = true(1,nV);   % speeds still below their limit

    for ia = 1:numel(aGrid)
        if ~any(active)
            break
        end
        a_cmd = aGrid(ia);

        Fzf = max(P.mf*P.g + P.m*a_cmd*P.h/P.L + DF*P.aeroBal,0);
        Fzr = max(P.mr*P.g - P.m*a_cmd*P.h/P.L + DF*(1-P.aeroBal),0);

        Fx_need = P.m*a_cmd - Fd;

        W = Fzf + P.k*Fzr;
        Fxr_nom = Fx_need.*P.k.*Fzr./max(W,eps);
        Fxr_cap = min(rearSafety*muR*Fzr,FxrPress);
        Fxf = Fx_need - min(Fxr_nom,Fxr_cap);

        % drag alone covers the demand, or the front can still take its share
        ok = (Fx_need <= 0) | (Fxf <= min(muF*Fzf,FxfPress));

        good = active & ok;
        aMax(good) = a_cmd;
        active = good;
    end
end