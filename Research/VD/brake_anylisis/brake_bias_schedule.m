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
%P.muF = 1.1;
%P.muR = 1.15
% P.muF = 0.85;
% P.muR = 0.85;
P.muF = 0.9;
P.muR = 0.9;

P.k = 1;
P.rearSafety = 1;   % rear never uses more than 90% of its grip 

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

        Fx_need = P.m*a_cmd - Fd;

        if Fx_need <= 0
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

% 3) max achievable decel vs speed, with the bias/pressures that produce it
maxDecelTbl = table( ...
    vGrid(:), ...
    vGrid(:)*3.6, ...
    aMax(:), ...
    aMax(:)/P.g, ...
    biasP(:), ...
    biasF(:), ...
    Pf_v(:), ...
    Pr_v(:), ...
    utilF_v(:), ...
    utilR_v(:), ...
    limitTag(:), ...
    'VariableNames',{ ...
    'speed_mps', ...
    'speed_kph', ...
    'a_max_mps2', ...
    'a_max_g', ...
    'bias_pressure', ...
    'bias_force', ...
    'Pf_kPa', ...
    'Pr_kPa', ...
    'util_front', ...
    'util_rear', ...
    'limited_by'});

writetable(maxDecelTbl,fullfile(outDir,'max_decel_vs_speed.csv'));

fprintf('CSV written to %s\n',outDir);
fprintf('  brake_bias_map_grid.csv   %d decel x %d speed breakpoints\n', ...
    nLa,nLv);
fprintf('  brake_bias_map_long.csv   %d rows: %d solved, %d held above a_max, %d held below drag\n', ...
    height(biasLongTbl),nnz(brakesOn),nnz(srcHeldTop),nnz(srcHeldBot));
fprintf('  max_decel_vs_speed.csv    %d speeds, a_max %.2f-%.2f m/s^2\n', ...
    nV,min(aMax),max(aMax));

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

%% bias map
mapRows = aGrid >= 1 & aGrid <= 25;
aMap = aGrid(mapRows);
biasMap = biasP_map(mapRows,:);
[VV,AA] = meshgrid(vGrid,aMap);

figure;
pcolor(VV,AA,biasMap);
shading interp;
cb = colorbar;
ylabel(cb,'Pressure bias P_f/(P_f+P_r)');
hold on;
plot(vGrid,aMax,'w-');
plot(vGrid,aMax,'k--');

validBias = biasMap(isfinite(biasMap));
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
    [C,hC] = contour(VV,AA,biasMap,lv,'k-');
    clabel(C,hC,'FontSize',8,'Color','k');
end

grid on;
xlabel('Speed [m/s]');
ylabel('Commanded decel [m/s^2]');
title('Bias schedule (line = max achievable decel, blank above it = infeasible)');

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

%% CSV export: sensitivity envelope, speed vs g
% Speed on clean 4 m/s increments, snapped inside whatever range vGrid covers
% so this keeps working if the sweep range moves. Decel in g, which is what you
% actually read off a trace at the track.
vExport = ceil(vGrid(1)/4)*4 : 4 : floor(vGrid(end)/4)*4;
nEx = numel(vExport);

gSens = zeros(nEx,nDragS,nMuS);
for im = 1:nMuS
    for id = 1:nDragS
        gSens(:,id,im) = interp1(vGrid,aMaxSens(:,id,im),vExport(:))/P.g;
    end
end

% 1) grid form - one row per speed, one column per (mu, drag) case
gridData = zeros(nEx,nDragS*nMuS);
gridVars = strings(1,nDragS*nMuS);
c = 0;
for im = 1:nMuS
    for id = 1:nDragS
        c = c + 1;
        gridData(:,c) = gSens(:,id,im);
        gridVars(c) = sprintf('g_muF%s_drag%d', ...
            strrep(sprintf('%.2f',P.muF-muDrop(im)),'.','p'), ...
            round(100*dragKeep(id)));
    end
end

sensGridTbl = array2table(gridData,'VariableNames',gridVars);
sensGridTbl = addvars(sensGridTbl,vExport(:),'Before',1, ...
    'NewVariableNames','speed_mps');
writetable(sensGridTbl,fullfile(outDir,'decel_envelope_g_grid.csv'));

% 2) long form - one row per (speed, mu, drag) case
[VVs,IDs,IMs] = ndgrid(vExport(:),1:nDragS,1:nMuS);

sensLongTbl = table( ...
    VVs(:), ...
    VVs(:)*3.6, ...
    reshape(muDrop(IMs),[],1), ...
    reshape(P.muF-muDrop(IMs),[],1), ...
    reshape(P.muR-muDrop(IMs),[],1), ...
    reshape(100*dragKeep(IDs),[],1), ...
    gSens(:), ...
    gSens(:)*P.g, ...
    'VariableNames',{ ...
    'speed_mps', ...
    'speed_kph', ...
    'mu_drop', ...
    'muF', ...
    'muR', ...
    'aero_drag_pct', ...
    'a_max_g', ...
    'a_max_mps2'});

sensLongTbl = sortrows(sensLongTbl, ...
    {'mu_drop','aero_drag_pct','speed_mps'}, ...
    {'ascend','descend','ascend'});
writetable(sensLongTbl,fullfile(outDir,'decel_envelope_g_long.csv'));

fprintf('  decel_envelope_g_grid.csv %d speeds (%g:%g:%g m/s) x %d cases\n', ...
    nEx,vExport(1),4,vExport(end),nDragS*nMuS);
fprintf('  decel_envelope_g_long.csv %d rows, %.2f-%.2f g\n', ...
    height(sensLongTbl),min(gSens(:)),max(gSens(:)));

%% CSV export: one file per aero level, nominal tyre mu
% Six two-column files - speed and the max decel the car can make at that
% speed - dropped in their own folder so the set can be handed off as one
% thing. Grip is held at nominal (muF = 1.1, muR = 1.15) in every file; the
% only thing that changes file to file is how much aero drag is left, 100%
% down to 0% in 20% steps. That sweep is already solved above, so this just
% reads the muDrop = 0 page of aMaxSens and resamples it onto clean speeds.
vAero = 0:4:72;

aeroDir = fullfile(outDir,'aero_sweep');
if ~exist(aeroDir,'dir')
    mkdir(aeroDir);
end

imNom = find(muDrop == 0,1);
if isempty(imNom)
    error('nominal mu case (muDrop = 0) is not in the sweep');
end
if vAero(end) > vGrid(end)
    error('vAero runs to %g m/s but the solver only covers %g m/s', ...
        vAero(end),vGrid(end));
end

fprintf('aero sweep CSV written to %s  (muF = %.2f, muR = %.2f)\n', ...
    aeroDir,P.muF,P.muR);

for id = 1:nDragS
    aAero = interp1(vGrid,aMaxSens(:,id,imNom),vAero(:));

    aeroTbl = table(vAero(:),aAero, ...
        'VariableNames',{'speed_mps','a_max_mps2'});

    fName = sprintf('a_max_drag%03d.csv',round(100*dragKeep(id)));
    writetable(aeroTbl,fullfile(aeroDir,fName));

    fprintf('  %-20s %3.0f%% aero drag, %d speeds, %.2f-%.2f m/s^2\n', ...
        fName,100*dragKeep(id),numel(vAero),min(aAero),max(aAero));
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