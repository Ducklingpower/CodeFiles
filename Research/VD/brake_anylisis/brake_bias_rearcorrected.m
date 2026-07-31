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

%% tire grip and bias policy
P.muF = 1.15;
P.muR = 1.15;


P.k = 0.95;

% Absolute rear tire-force ceiling.
P.rearSafety = 0.95;

%% maximum total deceleration versus speed
vGrid = linspace(5, 80, 300).';
nV = numel(vGrid);

aMaxTotal = zeros(nV,1);
aMaxBrake = zeros(nV,1);
aDrag     = zeros(nV,1);
biasF     = zeros(nV,1);
biasP     = zeros(nV,1);
Pf_v      = zeros(nV,1);
Pr_v      = zeros(nV,1);
utilF_v   = zeros(nV,1);
utilR_v   = zeros(nV,1);
limitTag  = strings(nV,1);

for i = 1:nV
    [aMaxTotal(i), s] = maxDecelAtSpeed(vGrid(i), P);

    aDrag(i)     = dragForce(vGrid(i), P) / P.m;
    aMaxBrake(i) = max(aMaxTotal(i) - aDrag(i), 0);

    biasF(i)    = s.biasF;
    biasP(i)    = s.biasP;
    Pf_v(i)     = s.Pf;
    Pr_v(i)     = s.Pr;
    utilF_v(i)  = s.utilF;
    utilR_v(i)  = s.utilR;
    limitTag(i) = s.limit;
end

figure('Name','Maximum braking versus speed','Position',[60 60 950 850]);

axA(1) = subplot(3,1,1);
plot(vGrid, aMaxTotal/P.g, 'LineWidth', 1.8); hold on;
plot(vGrid, aMaxBrake/P.g, '--', 'LineWidth', 1.5);
plot(vGrid, aDrag/P.g, ':', 'LineWidth', 1.5);
grid on;
ylabel('Deceleration [g]');
legend('total vehicle decel','brake-generated decel','aero-drag decel', ...
       'Location','best');
title(sprintf(['Maximum straight-line deceleration: P_{max}=%.0f kPa, ' ...
               '\\mu_F=%.2f, \\mu_R=%.2f'], ...
               P.Pmax, P.muF, P.muR));

axA(2) = subplot(3,1,2);
plot(vGrid, biasP, 'LineWidth', 1.8); hold on;
plot(vGrid, biasF, '--', 'LineWidth', 1.5);
grid on;
ylabel('Front share [-]');
legend('pressure bias','force bias','Location','best');

axA(3) = subplot(3,1,3);
plot(vGrid, Pf_v, 'LineWidth', 1.8); hold on;
plot(vGrid, Pr_v, 'LineWidth', 1.8);
yline(P.Pmax, 'k--', 'P_{max}');
grid on;
xlabel('Speed [m/s]');
ylabel('Pressure [kPa]');
legend('front','rear','Location','best');

linkaxes(axA,'x');

%% axle utilization at the maximum
figure('Name','Axle utilization at maximum braking','Position',[80 80 900 560]);

plot(vGrid, utilF_v, 'LineWidth', 1.8); hold on;
plot(vGrid, utilR_v, 'LineWidth', 1.8);
yline(P.muF, '--', '\mu_F');
yline(P.rearSafety*P.muR, '--', 'rear ceiling');
grid on;
xlabel('Speed [m/s]');
ylabel('F_x/F_z [-]');
legend('front utilization','rear utilization','Location','best');
title('Axle utilization at maximum achievable deceleration');

%% two-dimensional bias schedule
aGrid = linspace(0, 1.02*max(aMaxTotal), 260).';
[VV, AA] = meshgrid(vGrid, aGrid);

biasP_map = nan(size(VV));
biasF_map = nan(size(VV));

for i = 1:numel(VV)
    s = biasAtCommand(AA(i), VV(i), P);

    if s.feasible && s.FxNeed > 0
        biasP_map(i) = s.biasP;
        biasF_map(i) = s.biasF;
    end
end

figure('Name','Pressure-bias schedule','Position',[100 100 950 650]);
pcolor(VV, AA/P.g, biasP_map);
shading interp;
cb = colorbar;
ylabel(cb, 'Front pressure share P_f/(P_f+P_r)');
hold on;
plot(vGrid, aMaxTotal/P.g, 'w-', 'LineWidth', 2.7);
plot(vGrid, aMaxTotal/P.g, 'k--', 'LineWidth', 1.1);

finiteBias = biasP_map(isfinite(biasP_map));
if ~isempty(finiteBias)
    levels = linspace(min(finiteBias), max(finiteBias), 9);
    [C,hC] = contour(VV, AA/P.g, biasP_map, levels, 'k-', 'LineWidth', 0.7);
    clabel(C, hC, 'FontSize', 8);
end

grid on;
xlabel('Speed [m/s]');
ylabel('Commanded total deceleration [g]');
title('Front pressure-bias schedule; white/black line is maximum feasible deceleration');

%% one-dimensional deceleration sweeps at selected speeds
vBias = [10 20 40 60 75];

figure('Name','Bias versus deceleration','Position',[120 120 950 760]);

axC(1) = subplot(2,1,1);
hold on;

axC(2) = subplot(2,1,2);
hold on;

for j = 1:numel(vBias)
    v = vBias(j);
    [aLim, ~] = maxDecelAtSpeed(v, P);
    aCoast = dragForce(v, P) / P.m;

    % Start where brake force becomes positive and sweep to maximum braking.
    aSweep = linspace(aCoast, aLim, 260);
    bP = nan(size(aSweep));

    for i = 1:numel(aSweep)
        s = biasAtCommand(aSweep(i), v, P);
        if s.feasible && s.FxNeed > 0
            bP(i) = s.biasP;
        end
    end

    aBrakeSweep = max(aSweep - aCoast, 0);

    plot(axC(1), aSweep/P.g, bP, 'LineWidth', 1.7, ...
         'DisplayName', sprintf('v = %.0f m/s',v));

    plot(axC(2), aBrakeSweep/P.g, bP, 'LineWidth', 1.7, ...
         'DisplayName', sprintf('v = %.0f m/s',v));
end

grid(axC(1),'on');
xlabel(axC(1),'Total vehicle deceleration [g]');
ylabel(axC(1),'Front pressure bias [-]');
legend(axC(1),'Location','best');
title(axC(1),'Bias schedule using measured/commanded total deceleration');

grid(axC(2),'on');
xlabel(axC(2),'Brake-generated deceleration [g]');
ylabel(axC(2),'Front pressure bias [-]');
legend(axC(2),'Location','best');
title(axC(2),'Bias schedule with aerodynamic drag removed');

%% maximum-braking stop
v0 = 75;
dt = 0.002;
maxSteps = ceil(20/dt);

sim.t     = zeros(maxSteps,1);
sim.v     = zeros(maxSteps,1);
sim.a     = zeros(maxSteps,1);
sim.s     = zeros(maxSteps,1);
sim.biasP = zeros(maxSteps,1);
sim.biasF = zeros(maxSteps,1);
sim.Pf    = zeros(maxSteps,1);
sim.Pr    = zeros(maxSteps,1);

v = v0;
distance = 0;
time = 0;
n = 0;

while v > 0 && n < maxSteps
    [a, s] = maxDecelAtSpeed(v, P);

    n = n + 1;
    sim.t(n)     = time;
    sim.v(n)     = v;
    sim.a(n)     = a;
    sim.s(n)     = distance;
    sim.biasP(n) = s.biasP;
    sim.biasF(n) = s.biasF;
    sim.Pf(n)    = s.Pf;
    sim.Pr(n)    = s.Pr;

    dtStep = min(dt, v/max(a,eps));
    distance = distance + v*dtStep - 0.5*a*dtStep^2;
    v = max(v - a*dtStep, 0);
    time = time + dtStep;
end

fields = fieldnames(sim);
for i = 1:numel(fields)
    sim.(fields{i}) = sim.(fields{i})(1:n);
end

figure('Name','Maximum-braking stop','Position',[140 140 950 850]);

axD(1) = subplot(4,1,1);
plot(sim.t, sim.v, 'LineWidth', 1.8);
grid on;
ylabel('Speed [m/s]');
title(sprintf('Maximum braking from %.0f m/s: %.2f s and %.1f m', ...
      v0, time, distance));

axD(2) = subplot(4,1,2);
plot(sim.t, sim.a/P.g, 'LineWidth', 1.8);
grid on;
ylabel('Decel [g]');

axD(3) = subplot(4,1,3);
plot(sim.t, sim.biasP, 'LineWidth', 1.8); hold on;
plot(sim.t, sim.biasF, '--', 'LineWidth', 1.5);
grid on;
ylabel('Front share [-]');
legend('pressure bias','force bias','Location','best');

axD(4) = subplot(4,1,4);
plot(sim.t, sim.Pf, 'LineWidth', 1.8); hold on;
plot(sim.t, sim.Pr, 'LineWidth', 1.8);
yline(P.Pmax, 'k--', 'P_{max}');
grid on;
xlabel('Time [s]');
ylabel('Pressure [kPa]');
legend('front','rear','Location','best');

linkaxes(axD,'x');

%% numerical summary
fprintf('\n================ BRAKE ANALYSIS SUMMARY ================\n');
fprintf('Static front/rear distribution : %.1f%% / %.1f%%\n', ...
        100*P.mf/P.m, 100*P.mr/P.m);
fprintf('Per-tire pressure gain         : front %.3f N/kPa | rear %.3f N/kPa\n', ...
        P.kF, P.kR);
fprintf('Per-axle force at Pmax         : front %.0f N | rear %.0f N\n', ...
        2*P.kF*P.Pmax, 2*P.kR*P.Pmax);

fprintf('\n%6s %9s %9s %9s %9s %9s %9s %9s  %s\n', ...
        'v','total g','drag g','brake g','biasP','biasF','Pf','Pr','active limits');
fprintf('%6s %9s %9s %9s %9s %9s %9s %9s\n', ...
        '[m/s]','[-]','[-]','[-]','[-]','[-]','[kPa]','[kPa]');

for v = [10 20 30 40 50 60 70 75 80]
    [a, s] = maxDecelAtSpeed(v, P);
    ad = dragForce(v,P)/P.m;

    fprintf('%6.0f %9.3f %9.3f %9.3f %9.3f %9.3f %9.0f %9.0f  %s\n', ...
            v, a/P.g, ad/P.g, (a-ad)/P.g, ...
            s.biasP, s.biasF, s.Pf, s.Pr, s.limit);
end

fprintf('\nStop from %.0f m/s: %.2f s | %.1f m | peak %.3f g\n', ...
        v0, time, distance, max(sim.a)/P.g);
fprintf('========================================================\n');

%% axle normal loads
function [Fzf, Fzr] = axleLoads(aTotal, v, P)
    downforce = 0.5 * P.rho * P.ACdLift * v.^2;

    Fzf = P.mf*P.g ...
        + P.m*aTotal*P.h/P.L ...
        + P.aeroBal*downforce;

    Fzr = P.mr*P.g ...
        - P.m*aTotal*P.h/P.L ...
        + (1-P.aeroBal)*downforce;

    Fzf = max(Fzf,0);
    Fzr = max(Fzr,0);
end

%% aerodynamic drag
function Fdrag = dragForce(v, P)
    Fdrag = 0.5 * P.rho * P.CdA * v.^2;
end

%% bias and pressure command at a requested total deceleration
function s = biasAtCommand(aCmd, v, P)
    [Fzf, Fzr] = axleLoads(aCmd, v, P);

    FxNeed = max(P.m*aCmd - dragForce(v,P), 0);

    FfGripCap = P.muF * Fzf;
    FrGripCap = P.rearSafety * P.muR * Fzr;

    FfPressureCap = 2 * P.kF * P.Pmax;
    FrPressureCap = 2 * P.kR * P.Pmax;

    FfCap = min(FfGripCap, FfPressureCap);
    FrCap = min(FrGripCap, FrPressureCap);

    if FfGripCap <= FfPressureCap
        frontCapType = "front grip";
    else
        frontCapType = "front pressure";
    end

    if FrGripCap <= FrPressureCap
        rearCapType = "rear grip";
    else
        rearCapType = "rear pressure";
    end

    s.feasible = FxNeed <= FfCap + FrCap + 1e-8;
    s.FxNeed = FxNeed;
    s.Fzf = Fzf;
    s.Fzr = Fzr;
    s.FfCap = FfCap;
    s.FrCap = FrCap;
    s.shortfall = max(FxNeed - FfCap - FrCap, 0);

    if FxNeed <= 1e-9
        s.Fxf = 0;
        s.Fxr = 0;
        s.Pf = 0;
        s.Pr = 0;
        s.biasP = NaN;
        s.biasF = NaN;
        s.utilF = 0;
        s.utilR = 0;
        s.limit = "drag only";
        return;
    end

    if ~s.feasible
        % Return the maximum available axle forces for diagnostics.
        Fxf = FfCap;
        Fxr = FrCap;
        limit = "infeasible: " + frontCapType + " + " + rearCapType;
    else
        % Preferred split: rear utilization = k * front utilization.
        FxrDesired = FxNeed * P.k * Fzr / max(Fzf + P.k*Fzr, eps);

        % Feasible interval for rear force after enforcing both axle caps.
        FxrMin = max(0, FxNeed - FfCap);
        FxrMax = min(FrCap, FxNeed);

        Fxr = min(max(FxrDesired, FxrMin), FxrMax);
        Fxf = FxNeed - Fxr;

        tol = 1e-6 * max(FxNeed,1);
        frontAtCap = abs(Fxf - FfCap) <= tol;
        rearAtCap  = abs(Fxr - FrCap) <= tol;

        if frontAtCap && rearAtCap
            limit = frontCapType + " + " + rearCapType;
        elseif frontAtCap
            limit = frontCapType;
        elseif rearAtCap
            limit = rearCapType;
        else
            limit = "balanced";
        end
    end

    Pf = Fxf / (2*P.kF);
    Pr = Fxr / (2*P.kR);

    s.Fxf = Fxf;
    s.Fxr = Fxr;
    s.Pf = Pf;
    s.Pr = Pr;
    s.biasP = Pf / max(Pf + Pr, eps);
    s.biasF = Fxf / max(Fxf + Fxr, eps);
    s.utilF = Fxf / max(Fzf, eps);
    s.utilR = Fxr / max(Fzr, eps);
    s.limit = limit;
end

%% maximum feasible total deceleration at one speed
function [aMax, s] = maxDecelAtSpeed(v, P)
    lo = 0;
    hi = 5;

    sHi = biasAtCommand(hi, v, P);

    while sHi.feasible && hi < 100
        lo = hi;
        hi = 2*hi;
        sHi = biasAtCommand(hi, v, P);
    end

    if sHi.feasible
        error('Could not bracket maximum deceleration at v = %.3f m/s.',v);
    end

    for i = 1:80
        mid = 0.5*(lo + hi);
        sMid = biasAtCommand(mid, v, P);

        if sMid.feasible
            lo = mid;
        else
            hi = mid;
        end
    end

    aMax = lo;
    s = biasAtCommand(aMax, v, P);
end