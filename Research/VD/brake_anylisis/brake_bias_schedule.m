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
P.muF = 1.15;
P.muR = 1.15;
P.k = 1;
P.rearSafety = 1;   % rear never uses more than 90% of its grip 

%% acceleration and velocity sweep
aGrid = 0:0.004:40;
vGrid = linspace(5,80,400);

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

%% max braking vs speed
figure;

axA(1) = subplot(3,1,1);
plot(vGrid,aMax,'b-','LineWidth',1.8); hold on;
plot(vGrid,aMax./P.g,'r--','LineWidth',1.2);
grid on;
ylabel('Max decel');
legend('a_{max} [m/s^2]','a_{max} [g]','Location','best');
title(sprintf('Max braking vs speed  (P_{max} = %g kPa, \\mu = %.2f, k = %.2f, rearSafety = %.2f)', ...
    P.Pmax,P.muF,P.k,P.rearSafety));

axA(2) = subplot(3,1,2);
plot(vGrid,biasP,'b-','LineWidth',1.8); hold on;
plot(vGrid,biasF,'g--','LineWidth',1.4);
grid on;
ylabel('Bias (front share)');
legend('pressure bias','force bias','Location','best');

axA(3) = subplot(3,1,3);
plot(vGrid,Pf_v,'b-','LineWidth',1.8); hold on;
plot(vGrid,Pr_v,'r-','LineWidth',1.8);
yline(P.Pmax,'k--','P_{max}');
grid on;
xlabel('Speed [m/s]');
ylabel('Line pressure [kPa]');
legend('front','rear','Location','best');

linkaxes(axA,'x');

%% limiting constraint
figure;

axB(1) = subplot(2,1,1);
plot(vGrid,utilF_v,'b-','LineWidth',1.8); hold on;
plot(vGrid,utilR_v,'r-','LineWidth',1.8);
yline(P.muF,'b--','\mu_F');
yline(P.rearSafety*P.muR,'r--','rear ceiling');
grid on;
ylabel('Utilization F_x/F_z [-]');
legend('front','rear','Location','best');
title('Friction utilization at max braking');

axB(2) = subplot(2,1,2);
plot(vGrid,double(contains(limitTag,"pressure")),'k-','LineWidth',2);
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
plot(vGrid,aMax,'w-','LineWidth',2.5);
plot(vGrid,aMax,'k--','LineWidth',1.2);

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
    [C,hC] = contour(VV,AA,biasMap,lv,'k-','LineWidth',0.75);
    clabel(C,hC,'FontSize',8,'Color','k');
end

grid on;
xlabel('Speed [m/s]');
ylabel('Commanded decel [m/s^2]');
title('Bias schedule (line = max achievable decel, blank above it = infeasible)');

%% 3D bias schedule surface  (bias vs speed & commanded long decel)
figure;
% downsample to a readable grid spacing so the mesh lines are visible
vSkip = 12;
aSkip = 50;
vIdx = 1:vSkip:nV;
aIdx = 1:aSkip:numel(aMap);

VVg = VV(aIdx,vIdx);
AAg = AA(aIdx,vIdx);
biasGrid = biasMap(aIdx,vIdx);

hSurf = surf(VVg,AAg,biasGrid);
set(hSurf,'FaceColor','interp','EdgeColor','k','LineWidth',0.5);
hold on;

% trace of the max achievable decel along the surface
biasAtMax = interp2(VV,AA,biasMap,vGrid,aMax);
plot3(vGrid,aMax,biasAtMax,'w-','LineWidth',3);
plot3(vGrid,aMax,biasAtMax,'k--','LineWidth',1.2);

cb = colorbar;
ylabel(cb,'Pressure bias P_f/(P_f+P_r)');
xlabel('Speed [m/s]');
ylabel('Commanded long. decel [m/s^2]');
zlabel('Brake bias (front share)');
title('Required brake bias vs speed and longitudinal decel');
grid on;
view(135,25);
axis tight;

%% rearSafety trade-off:  full grip (=1) vs margined rear (=0.9)
aMax_full = computeAMax(P,vGrid,aGrid,1.0);          % rear allowed to lock point
aMax_safe = aMax;                                    % current run (P.rearSafety)

figure('Name','Fig 5 - Rear-safety trade-off','Position',[140 140 900 520]);
plot(vGrid,aMax_full,'k-','LineWidth',1.8); hold on;
plot(vGrid,aMax_safe,'r-','LineWidth',1.8);
grid on;
xlabel('Speed [m/s]');
ylabel('Max decel [m/s^2]');
legend('rearSafety = 1.0 (both axles lock together)', ...
       sprintf('rearSafety = %.2f (front locks first)',P.rearSafety), ...
       'Location','best');
lossPct = 100*mean((aMax_full-aMax_safe)./max(aMax_full,eps));
title(sprintf('Peak decel traded for rear margin  (avg loss %.1f%%)',lossPct));

%% stop simulation
v0 = 70;
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

%% helper: max decel vs speed for a given rear-safety factor
function aMax = computeAMax(P,vGrid,aGrid,rearSafety)
    nA = numel(aGrid);
    nV = numel(vGrid);
    aMax = zeros(1,nV);
    limitFound = false(1,nV);

    for ia = 1:nA
        a_cmd = aGrid(ia);
        for iv = 1:nV
            if limitFound(iv)
                continue
            end

            v = vGrid(iv);
            Fd = 0.5*P.rho*P.CdA*v^2;
            DF = 0.5*P.rho*P.ACdLift*v^2;

            Fzf = max(P.mf*P.g + P.m*a_cmd*P.h/P.L + DF*P.aeroBal,0);
            Fzr = max(P.mr*P.g - P.m*a_cmd*P.h/P.L + DF*(1-P.aeroBal),0);

            Fx_need = P.m*a_cmd - Fd;
            if Fx_need <= 0
                aMax(iv) = a_cmd;
                continue
            end

            W = Fzf + P.k*Fzr;
            Fxr_nom = Fx_need*P.k*Fzr/max(W,eps);
            Fxr_cap = min(rearSafety*P.muR*Fzr,2*P.kR*P.Pmax);
            Fxr = min(Fxr_nom,Fxr_cap);
            Fxf = Fx_need - Fxr;

            FxfGrip = P.muF*Fzf;
            FxfPress = 2*P.kF*P.Pmax;
            if Fxf <= min(FxfGrip,FxfPress)
                aMax(iv) = a_cmd;
            else
                limitFound(iv) = true;
            end
        end
    end
end