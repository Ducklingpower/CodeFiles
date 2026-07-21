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
P.Pmax    = 3000;        

P.kF = P.A_caliper_mm2 * 1e-3 * P.mu_k * P.R_lever / P.Rw_f;
P.kR = P.A_caliper_mm2 * 1e-3 * P.mu_k * P.R_lever / P.Rw_r;

%% tire grip
% 1.15 is measured: rear tires hit Fx/Fz = 1.15 under full-throttle accel.
P.muF = 1.15;
P.muR = 1.15;

P.k = 0.95;              % rear utilization as a fraction of front
P.rearSafety = 0.95      % safty threshold

%% max braking vs speed
vGrid = linspace(5, 80, 300);
nV = numel(vGrid);

aMax = zeros(nV,1);
biasF = zeros(nV,1);
biasP = zeros(nV,1);
Pf_v = zeros(nV,1);
Pr_v = zeros(nV,1);
utilF_v = zeros(nV,1);
utilR_v = zeros(nV,1);
limitTag = strings(nV,1);

for i = 1:nV
    [aMax(i), s] = maxDecelAtSpeed(vGrid(i), P);
    biasF(i) = s.biasF;
    biasP(i) = s.biasP;
    Pf_v(i) = s.Pf;
    Pr_v(i) = s.Pr;
    utilF_v(i) = s.utilF;
    utilR_v(i) = s.utilR;
    limitTag(i) = s.limit;
end

figure('Name','Fig 1 - Max braking vs speed','Position',[60 60 900 850]);

axA(1) = subplot(3,1,1);
plot(vGrid, aMax, 'b-', 'LineWidth', 1.8); hold on;
plot(vGrid, aMax./P.g, 'r--', 'LineWidth', 1.2);
grid on; ylabel('Max decel');
legend('a_{max} [m/s^2]','a_{max} [g]','Location','best');
title(sprintf('Max braking vs speed  (P_{max} = %g kPa, \\mu = %.2f, k = %.2f, rearSafety = %.2f)', ...
      P.Pmax, P.muF, P.k, P.rearSafety));

axA(2) = subplot(3,1,2);
plot(vGrid, biasP, 'b-', 'LineWidth', 1.8); hold on;
plot(vGrid, biasF, 'g--', 'LineWidth', 1.4);
grid on; ylabel('Bias (front share)');
legend('pressure bias','force bias','Location','best');

axA(3) = subplot(3,1,3);
plot(vGrid, Pf_v, 'b-', 'LineWidth', 1.8); hold on;
plot(vGrid, Pr_v, 'r-', 'LineWidth', 1.8);
yline(P.Pmax, 'k--', 'P_{max}');
grid on; xlabel('Speed [m/s]'); ylabel('Line pressure [kPa]');
legend('front','rear','Location','best');

linkaxes(axA, 'x');

%% limiting constraint
figure('Name','Fig 2 - Limiting constraint & utilization','Position',[80 80 900 600]);

axB(1) = subplot(2,1,1);
plot(vGrid, utilF_v, 'b-', 'LineWidth', 1.8); hold on;
plot(vGrid, utilR_v, 'r-', 'LineWidth', 1.8);
yline(P.muF, 'b--', '\mu_F');
yline(P.rearSafety*P.muR, 'r--', 'rear ceiling');
grid on; ylabel('Utilization F_x/F_z [-]');
legend('front','rear','Location','best');
title('Friction utilization at max braking');

axB(2) = subplot(2,1,2);
plot(vGrid, double(contains(limitTag, "pressure")), 'k-', 'LineWidth', 2);
grid on; ylim([-0.2 1.2]); yticks([0 1]); yticklabels({'front grip','front pressure'});
ylabel('What caps a_{max}'); xlabel('Speed [m/s]');
linkaxes(axB, 'x');

%% bias map
aGrid = linspace(1, 25, 240);
[VV, AA] = meshgrid(vGrid, aGrid);
biasP_map = nan(size(VV));

for i = 1:numel(VV)
    s = biasAtCommand(AA(i), VV(i), P);
    if s.feasible
        biasP_map(i) = s.biasP;
    end
end

figure('Name','Fig 3 - Pressure bias map','Position',[100 100 900 620]);
pcolor(VV, AA, biasP_map); shading interp;
cb = colorbar; ylabel(cb, 'Pressure bias P_f/(P_f+P_r)');
hold on;
plot(vGrid, aMax, 'w-', 'LineWidth', 2.5);
plot(vGrid, aMax, 'k--', 'LineWidth', 1.2);
lv = linspace(min(biasP_map(:)), max(biasP_map(:)), 9);
[~, hC] = contour(VV, AA, biasP_map, lv, 'k-', 'LineWidth', 0.75);
clabel([], hC, 'FontSize', 8, 'Color', 'k');
grid on;
xlabel('Speed [m/s]'); ylabel('Commanded decel [m/s^2]');
title('Bias schedule (line = max achievable decel, blank above it = infeasible)');

%% stop simulation
v0 = 75;
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

v = v0; dist = 0; n = 0;
for i = 1:nStep
    if v <= 0.5, break; end
    [a, s] = maxDecelAtSpeed(v, P);

    n = n + 1;
    sim.t(n) = (i-1)*dt;
    sim.v(n) = v;
    sim.a(n) = a;
    sim.s(n) = dist;
    sim.biasP(n) = s.biasP;
    sim.biasF(n) = s.biasF;
    sim.Pf(n) = s.Pf;
    sim.Pr(n) = s.Pr;
    sim.Fzf(n) = s.Fzf;
    sim.Fzr(n) = s.Fzr;

    dist = dist + v*dt - 0.5*a*dt^2;
    v = v - a*dt;
end

f = fieldnames(sim);
for i = 1:numel(f), sim.(f{i}) = sim.(f{i})(1:n); end

figure('Name','Fig 4 - Max-braking stop','Position',[120 120 950 900]);

axD(1) = subplot(4,1,1);
plot(sim.t, sim.v, 'b-', 'LineWidth', 1.8);
grid on; ylabel('Speed [m/s]');
title(sprintf('Max braking from %.0f m/s: stop in %.2f s / %.1f m', v0, sim.t(end), sim.s(end)));

axD(2) = subplot(4,1,2);
plot(sim.t, sim.a, 'b-', 'LineWidth', 1.8); hold on;
plot(sim.t, sim.a./P.g, 'r--', 'LineWidth', 1.2);
grid on; ylabel('Decel');
legend('[m/s^2]','[g]','Location','best');

axD(3) = subplot(4,1,3);
plot(sim.t, sim.biasP, 'b-', 'LineWidth', 1.8); hold on;
plot(sim.t, sim.biasF, 'g--', 'LineWidth', 1.4);
grid on; ylabel('Bias (front)');
legend('pressure bias','force bias','Location','best');

axD(4) = subplot(4,1,4);
plot(sim.t, sim.Pf, 'b-', 'LineWidth', 1.8); hold on;
plot(sim.t, sim.Pr, 'r-', 'LineWidth', 1.8);
yline(P.Pmax, 'k--', 'P_{max}');
grid on; xlabel('Time [s]'); ylabel('Pressure [kPa]');
legend('front','rear','Location','best');

linkaxes(axD, 'x');



%% mu sensitivity
muSweep = linspace(0.7, 1.3, 60);
vTest = [20 40 60 75];
aMu = zeros(numel(muSweep), numel(vTest));

for j = 1:numel(vTest)
    for i = 1:numel(muSweep)
        Pt = P; Pt.muF = muSweep(i); Pt.muR = muSweep(i);
        aMu(i,j) = maxDecelAtSpeed(vTest(j), Pt);
    end
end

figure('Name','Fig 6 - Sensitivity to assumed tire mu','Position',[160 160 850 520]);
plot(muSweep, aMu, 'LineWidth', 1.8);
grid on; xlabel('Assumed tire \mu_x [-]'); ylabel('Max decel [m/s^2]');
legend(compose('v = %g m/s', vTest), 'Location','best');
title('Max decel vs assumed \mu (flat = pressure-limited, sloped = grip-limited)');
xline(0.7, 'k--', 'measured braking \mu_R');
xline(1.15,'k--', 'measured accel \mu_R');

%% summary

fprintf('Per-tire gain      : front %.3f N/kPa | rear %.3f N/kPa\n', P.kF, P.kR);
fprintf('At Pmax=%g kPa     : front %.0f N/tire | rear %.0f N/tire\n', P.Pmax, P.kF*P.Pmax, P.kR*P.Pmax);
fprintf('At Pmax, per axle  : front %.0f N | rear %.0f N | total %.0f N\n', ...
        2*P.kF*P.Pmax, 2*P.kR*P.Pmax, 2*(P.kF+P.kR)*P.Pmax);
fprintf('Brake-only decel   : %.2f m/s^2 (%.2f g), drag excluded\n', ...
        2*(P.kF+P.kR)*P.Pmax/P.m, 2*(P.kF+P.kR)*P.Pmax/(P.m*P.g));

fprintf('\n%6s %9s %7s %9s %9s %9s %9s %8s %8s  %s\n', ...
        'v','aMax','aMax','biasP','biasF','Pf','Pr','utilF','utilR','limited by');
fprintf('%6s %9s %7s %9s %9s %9s %9s %8s %8s\n', ...
        '[m/s]','[m/s^2]','[g]','[-]','[-]','[kPa]','[kPa]','[-]','[-]');
for v = [10 20 30 40 50 60 70 75]
    [a, s] = maxDecelAtSpeed(v, P);
    fprintf('%6.0f %9.2f %7.2f %9.3f %9.3f %9.0f %9.0f %8.2f %8.2f  %s\n', ...
            v, a, a/P.g, s.biasP, s.biasF, s.Pf, s.Pr, s.utilF, s.utilR, s.limit);
end

fprintf('\nStop from %.0f m/s : %.2f s | %.1f m | peak %.2f m/s^2 (%.2f g)\n', ...
        v0, sim.t(end), sim.s(end), max(sim.a), max(sim.a)/P.g);
fprintf('Bias over the stop : %.3f at %.0f m/s -> %.3f at %.0f m/s\n', ...
        sim.biasP(1), sim.v(1), sim.biasP(end), sim.v(end));


%% load transfer
function [Fzf, Fzr] = axleLoads(a, v, P)
    DF = 0.5 * P.rho * P.ACdLift * v.^2;
    Fzf = P.mf*P.g + (P.m .* a .* P.h) ./ P.L + DF .* P.aeroBal;
    Fzr = P.mr*P.g - (P.m .* a .* P.h) ./ P.L + DF .* (1 - P.aeroBal);
    Fzf = max(Fzf, 0);
    Fzr = max(Fzr, 0);
end

%% force balance
function Fd = dragForce(v, P)
    Fd = 0.5 * P.rho * P.CdA * v.^2;
end

%% bias split
function s = biasAtCommand(a_cmd, v, P)
    [Fzf, Fzr] = axleLoads(a_cmd, v, P);
    W = Fzf + P.k*Fzr;

    Fx_need = P.m*a_cmd - dragForce(v, P);
    if Fx_need <= 0
        s.feasible = true; s.biasP = NaN; s.biasF = NaN;
        s.Fxf = 0; s.Fxr = 0; s.Fzf = Fzf; s.Fzr = Fzr;
        s.Pf = 0; s.Pr = 0; s.utilF = 0; s.utilR = 0; s.limit = "drag only";
        return;
    end

    Fxr_nom = Fx_need * P.k * Fzr / max(W, eps);
    Fxr_cap = min(P.rearSafety * P.muR * Fzr, 2*P.kR*P.Pmax);
    Fxr = min(Fxr_nom, Fxr_cap);
    Fxf = Fx_need - Fxr;

    FxfGrip = P.muF * Fzf;
    FxfPress = 2*P.kF*P.Pmax;

    if Fxf <= min(FxfGrip, FxfPress)
        s.feasible = true;
        if Fxr_nom <= Fxr_cap
            s.limit = "balanced";
        else
            s.limit = "rear-capped";
        end
    else
        s.feasible = false;
        if FxfGrip <= FxfPress
            s.limit = "front grip";
        else
            s.limit = "front pressure";
        end
    end

    s.Fxf = Fxf;  s.Fxr = Fxr;
    s.Fzf = Fzf;  s.Fzr = Fzr;
    s.Pf = Fxf / (2*P.kF);
    s.Pr = Fxr / (2*P.kR);
    s.biasP = s.Pf / max(s.Pf + s.Pr, eps);
    s.biasF = Fxf / max(Fxf + Fxr, eps);
    s.utilF = Fxf / max(Fzf, eps);
    s.utilR = Fxr / max(Fzr, eps);
end

%% max decel
function [aMax, s] = maxDecelAtSpeed(v, P)
    % feasibility is monotone in a, so bisect on it
    lo = 0; hi = 40;
    for i = 1:80
        mid = 0.5*(lo+hi);
        if biasAtCommand(mid, v, P).feasible
            lo = mid;
        else
            hi = mid;
        end
    end
    aMax = lo;
    s = biasAtCommand(aMax, v, P);

    sNext = biasAtCommand(min(aMax + 1e-3, 40), v, P);
    if ~sNext.feasible
        s.limit = sNext.limit;
    end
end
