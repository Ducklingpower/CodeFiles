clc
close all
clear
% debug slip angle - axle slip angle and understeer gradient from tire models with the observed normal load
% trusted: axle Fy (force balance, vehicle_model.m), tire Fz (observer), IMU a_y, yaw rate, speed, steering
% not trusted online: odom vy, the measured slip angles are only the reference
%
% models (all use the observed normal load)
%   MPC brush      the controller's brush tire (mu 1.6, Ca 174k / 290k), closed form inverse of the controller
%   refit brush    same brush equation, mu(Fz) and Ca(Fz) as power laws fitted to the observed loads, still closed form
%   MF inverse     fitted Pacejka 1987 (MF fit), inverted with a lookup over slip (both tires at the axle slip)
%   MF at obs slip slip from the v_y observer (IMU integration pulled to the MF inverse where it is well conditioned),
%                  the MF run forward at that slip for the effective stiffness
%   brush observer the same v_y observer with the MPC brush or the refit brush (observed Fz) in place of the MF,
%                  closed form throughout: the brush inverse is the controller's cubic and the trust in it is exact,
%                  dFy/dtan(alpha) = Ca (1 - tan(alpha)/t_th)^2, t_th = 3 mu Fz / Ca, so conditioning = (1 - |tan a|/t_th)^2
% understeer gradient: the MPC's own calculation (demand m a_y split by lf, lr, effective stiffness Fy / tan(alpha)),
% for MF at obs slip the stiffness is the MF force at the observer slip / tan(observer slip)
% measured: slip from the odom v_y, k_us = (alpha_f - alpha_r) / a_y

%% settings

here      = fileparts(mfilename("fullpath"));
matFile   = fullfile(here, "tire_fit_data_2026.mat");    % evaluation log (vehicle_model.m output, current observer)
fitFile   = fullfile(here, "tire_fit_data_2025.mat");    % brush refit log
csvFile   = "/home/elijah/PurdueRacing/bags/lagoona/comp2/compition_bags/2026-09-03_121638_merged.csv";
cacheFile = fullfile(here, "debug_slip_angle_data.mat"); % IMU a_y and odom v_y from the CSV, read once

% fitted Pacejka 1987, same as vehicle_model.m / tire_fz_plots.m, c = [C a1 ... a8], Fz kN, alpha deg
pacFy = [1.38674 -126.23 1932.29 2160.01 1.77721 0.234871 -1.61212e-05 -0.0966109 -0.522512;   % front
         1.34461 -92.2527 1910.84 3000.88 1.48429 0.25844 0.000450439 0.136008 -2.1887];       % rear

% MPC brush tire and understeer gradient, fbl_mpc_controller config/vehicle_model_param.yaml (UnicycleModel)
mpcP.m    = 815.0;   mpcP.lf = 1.6785;   mpcP.lr = 1.2933;   mpcP.coh = 0.275;
mpcP.mu   = [1.6 1.6];                   % friction_coefficient
mpcP.Ca   = [174000 290000];             % ca, axle cornering stiffness (N/rad)
mpcP.Fz   = [3256 4615];                 % normal_load (N), also the reference load of the refit
mpcP.kMax = 0.0012;                      % max_understeer_gradient

% refit brush, per axle: mu = mu0 (Fz/Fz0)^q from the peak envelope, Ca = Ca0 (Fz/Fz0)^p fitted on near pure cornering
% ASSUMPTION: offline fit against the measured slip (the only slip with a scale independent of the tire model)
fitStride = 5;                            % use every 5th sample in the stiffness fit
muSlip    = 2;                            % (deg) peak friction envelope from samples above this slip
muPct     = 95;                           % percentile of |Fy|/Fz taken as the peak in each load bin

aGrid   = 0:0.02:12;     % (deg) MF inverse lookup grid
vMin    = 10;            % (m/s) samples used
fcSig   = 1.3;           % (Hz) low pass on the IMU a_y and odom v_y (same as vehicle_model.m fc)
tauObs  = 0.2;           % (s) v_y observer pull time to the MF slip (chosen: full trust, tau 0.2 s)
brTau   = 0.2;           % (s) brush observer pull time (chosen: full trust, tau 0.2 s), a list here sweeps it
% trust in the tire model inside the observers: trust = max(trustFloor, conditioning^trustPow)
% conditioning = local slope / initial slope of the tire curve at the inverted slip (1 steep, 0 at the peak)
% more trust: trustPow < 1 (raises it everywhere below the peak), trustFloor > 0 (keeps some pull even at the peak),
% or a shorter tauObs / brTau (every bit of trust pulls harder)
trustPow   = 1;
trustFloor = 1;          % chosen: full trust, the observer is a complementary filter (IMU fast, tire model slow, ~tau)
trustPowGrid   = [0.25 0.5 1 2];        % trust sweep
trustFloorGrid = [0 0.1 0.25 0.5 0.75 0.9 1];   % 1 = always full trust (the inverse, only filtered by tau)
tauGrid        = [0.01 0.02 0.05 0.1 0.2 0.5 1 2];   % (s) observer pull time sweep, MPC brush observer
% dual track observer (per tire), its own trust: it needs the conditioning (full trust lets one saturated tire set v_y)
% swept: floor 0 / 0.1 / 1, power 1 / 2 / 4, tau 0.2 / 0.5 / 1 s, best: floor 0, power 2, tau 0.2 s
dtTrustPow   = 2;
dtTrustFloor = 0;
dtTau        = 0.2;
tauFloors      = [0 0.1 1];                         % trust floors shown in the tau sweep
kAyMin  = 4;             % (m/s^2) k_us only above this lateral acceleration (undefined near straight running)
cornerR = 60;            % (m) samples within this distance of a corner label count for that corner

lapRef    = [100 144];   % lap timing point (C11)
turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];

cRef = [0.60 0.20 0.60];   % purple, measured
cMpc = [0.85 0.10 0.10];   % red, MPC brush observed Fz
cRfb = [0.55 0.35 0.10];   % brown, refit brush
cMf  = [0.92 0.41 0.20];   % orange, MF inverse
cObs = [0.00 0.45 0.74];   % blue, MF at observer slip
cFix = [0.00 0.39 0.00];   % dark green, MPC fixed load (for reference lines)
cU   = [0.45 0.45 0.45];   % grey
cObM = [1 1 1];            % white, MPC brush observer
cObR = [0.30 0.75 0.65];   % teal, refit brush observer

%% data

d  = load(matFile);
vp = d.vehicleParams;
L  = vp.wheelbase;
lf = (1 - vp.w_dist_f) * L;
lr = vp.w_dist_f * L;

if isfile(cacheFile)
    X = load(cacheFile).X;
else
    o = detectImportOptions(csvFile);
    o.SelectedVariableNames = ["a_y", "odom_vy_mps"];
    o = setvartype(o, o.SelectedVariableNames, "double");
    T = readtable(csvFile, o);
    X.ay = T.a_y;
    X.vy = T.odom_vy_mps;
    save(cacheFile, "X");
end

t    = d.t;
Ts   = median(diff(t));
n    = numel(t);
vx   = d.Fvx;
r    = d.wz;                                         % yaw rate, filtered like vehicle_model.m
dl   = d.delta;                                      % road wheel angle (rad)
Fz   = max(d.Fz_dual_obs, 0);                        % observed tire loads, a lifted tire carries 0
FzAx = [Fz(:,1) + Fz(:,2), Fz(:,3) + Fz(:,4)];
Fy   = [d.Fyf, d.Fyr];                               % trusted axle Fy (force balance)
ayI  = lpf(fillmissing(X.ay, "nearest"), fcSig, Ts); % IMU lateral acceleration (gravity compensated channel)
vyLoc = lpf(fillmissing(X.vy, "nearest"), fcSig, Ts); % localization v_y (odom), reference only
aRef = [mean([d.alpha_fl, d.alpha_fr], 2), mean([d.alpha_rl, d.alpha_rr], 2)];   % measured axle slip (rad)
ok   = vx > vMin & all(isfinite([Fy, Fz, r, dl, aRef]), 2);
aL   = vx .* r;                                      % lateral acceleration v r, the MPC's input stand in
use  = ok & abs(aL) > kAyMin;

fprintf("samples %d, used (v > %d m/s) %d, |a_y| > %d: %d\n", n, vMin, nnz(ok), kAyMin, nnz(use));

%% refit brush on the 2025 log with the observed normal load
% Fy_axle = brush(alpha_measured, Fz_axle, mu(Fz), Ca(Fz)), least squares on near pure cornering samples

f   = load(fitFile);
FzF = max(f.Fz_dual_obs, 0);
FzF = [FzF(:,1) + FzF(:,2), FzF(:,3) + FzF(:,4)];
aF  = [mean([f.alpha_fl, f.alpha_fr], 2), mean([f.alpha_rl, f.alpha_rr], 2)];
FyF = [f.Fyf, f.Fyr];
selF = f.Fvx > vMin & abs(f.Fax) < 2 & abs(f.ay_tire) > 2 & all(isfinite([FzF, aF, FyF]), 2);
selF = find(selF);  selF = selF(1:fitStride:end);

opts = optimoptions("lsqnonlin", "Display", "off");
axNamesP = ["front axle", "rear axle"];
rb   = zeros(2, 4);                                  % [mu0 q Ca0 p] per axle
zR   = zeros(2, 2);                                  % axle load range of the mu envelope, mu is held outside it
% stage 1, peak friction: 95th percentile of |Fy|/Fz in axle load bins where |alpha| > 2 deg, power law in Fz
%          (a plain least squares fit pulls mu down, the brush cannot follow the long linear range of the real tire)
% stage 2, cornering stiffness: least squares of the brush force with mu(Fz) from stage 1 held fixed
fprintf("\nrefit brush on the 2025 log, observed axle load (mu = mu0 (Fz/Fz0)^q from the peak envelope, Ca = Ca0 (Fz/Fz0)^p by least squares)\n");
for ax = 1:2
    z0 = mpcP.Fz(ax);
    s2 = f.Fvx > vMin & abs(f.Fax) < 2 & all(isfinite([FzF, aF, FyF]), 2) & abs(rad2deg(aF(:,ax))) > muSlip;
    edges = prctile(FzF(s2,ax), 0:10:100);  zb = zeros(0,1);  mb = zeros(0,1);
    for k = 1:numel(edges) - 1
        sb = s2 & FzF(:,ax) >= edges(k) & FzF(:,ax) < edges(k+1);
        if nnz(sb) > 50, zb(end+1,1) = median(FzF(sb,ax)); mb(end+1,1) = prctile(abs(FyF(sb,ax)) ./ FzF(sb,ax), muPct); end %#ok<AGROW>
    end
    pm = [ones(numel(zb),1), log(zb / z0)] \ log(mb);
    rb(ax,1:2) = [exp(pm(1)), pm(2)];
    zR(ax,:)   = [min(zb), max(zb)];
    muA = rb(ax,1) .* (min(max(FzF(selF,ax), zR(ax,1)), zR(ax,2)) / z0).^rb(ax,2);
    res = @(x) FyF(selF,ax) - brushFy(aF(selF,ax), FzF(selF,ax), muA, x(1) .* (FzF(selF,ax) / z0).^x(2));
    rb(ax,3:4) = lsqnonlin(res, [mpcP.Ca(ax), 0], [0.3*mpcP.Ca(ax) -1], [2*mpcP.Ca(ax) 1.5], opts);
    r0 = FyF(selF,ax) - brushFy(aF(selF,ax), FzF(selF,ax), mpcP.mu(ax), mpcP.Ca(ax));
    fprintf("%-10s mu0 %.3f q %+.3f (envelope %.2f-%.2f over Fz %.0f-%.0f N)   Ca0 %6.0f N/rad p %+.3f   rms %4.0f N (MPC brush at observed Fz %4.0f N)\n", ...
        axNamesP(ax), rb(ax,1:2), min(mb), max(mb), min(zb), max(zb), rb(ax,3:4), rms(res(rb(ax,3:4))), rms(r0));
end
muFit = @(ax, z) rb(ax,1) .* (min(max(z, zR(ax,1)), zR(ax,2)) / mpcP.Fz(ax)).^rb(ax,2);   % no extrapolation of mu
CaFit = @(ax, z) rb(ax,3) .* (max(z, 1) / mpcP.Fz(ax)).^rb(ax,4);

%% axle slip from each model, from the trusted axle Fy and the observed load

aMpc = nan(n, 2);  aRfb = nan(n, 2);  aFix = nan(n, 2);
for ax = 1:2
    for j = find(ok)'
        aMpc(j,ax) = -inverseBrush(Fy(j,ax), FzAx(j,ax), mpcP.mu(ax), mpcP.Ca(ax));                       % controller sign negated
        aFix(j,ax) = -inverseBrush(Fy(j,ax), mpcP.Fz(ax), mpcP.mu(ax), mpcP.Ca(ax));                      % as the MPC, fixed load
        aRfb(j,ax) = -inverseBrush(Fy(j,ax), FzAx(j,ax), muFit(ax, FzAx(j,ax)), CaFit(ax, FzAx(j,ax)));
    end
end

aMf = nan(n, 2); U = nan(n, 2); Cn = zeros(n, 2);
for ax = 1:2
    [aMf(:,ax), U(:,ax), Cn(:,ax)] = axleInverse(pacFy(ax,:), Fy(:,ax), Fz(:, 2*ax-1:2*ax), aGrid, ok);
end

% v_y observer: IMU integration, pulled to the MF inverse where it is well conditioned
trustFn = @(c, tp, tf) max(tf, c .^ tp);
Wc = trustFn(Cn, trustPow, trustFloor);
straight = ok & abs(r) < 0.02 & abs(ayI) < 2;
ayBias = median(ayI(straight) - vx(straight) .* r(straight));
[vyO, aObs] = runObserver(aMf, Wc, tauObs, vx, r, dl, ayI, ayBias, lf, lr, Ts, ok, straight);

% brush observers: conditioning of the brush inverse is exact, (1 - |tan alpha| / t_th)^2, 0 when saturated
muMpcAx = repmat(mpcP.mu, n, 1);   CaMpcAx = repmat(mpcP.Ca, n, 1);
muRfbAx = [muFit(1, FzAx(:,1)), muFit(2, FzAx(:,2))];   CaRfbAx = [CaFit(1, FzAx(:,1)), CaFit(2, FzAx(:,2))];
CnMpc = brushCond(aMpc, Fy, FzAx, muMpcAx, CaMpcAx);
CnRfb = brushCond(aRfb, Fy, FzAx, muRfbAx, CaRfbAx);

fprintf("\nbrush observers (trust^%g, floor %g), rms error to the measured slip (deg): front all / util > 0.9, rear all / util > 0.9\n", trustPow, trustFloor);
hiU0 = ok & U(:,1) > 0.9;
WcM  = trustFn(CnMpc, trustPow, trustFloor);
WcR  = trustFn(CnRfb, trustPow, trustFloor);
bestBr = struct("mpc", [Inf 0], "rfb", [Inf 0]);   % [score tau]
for to = brTau
    [~, aT1] = runObserver(aMpc, WcM, to, vx, r, dl, ayI, ayBias, lf, lr, Ts, ok, straight);
    [~, aT2] = runObserver(aRfb, WcR, to, vx, r, dl, ayI, ayBias, lf, lr, Ts, ok, straight);
    e1 = rad2deg(aT1 - aRef);  e2 = rad2deg(aT2 - aRef);
    s1 = mean([rms(e1(ok,:), "omitnan"), rms(e1(hiU0,:), "omitnan")]);
    s2 = mean([rms(e2(ok,:), "omitnan"), rms(e2(hiU0,:), "omitnan")]);
    fprintf("  tau %.1f s: MPC brush %.2f/%.2f %.2f/%.2f   refit brush %.2f/%.2f %.2f/%.2f\n", to, ...
        rms(e1(ok,1), "omitnan"), rms(e1(hiU0,1), "omitnan"), rms(e1(ok,2), "omitnan"), rms(e1(hiU0,2), "omitnan"), ...
        rms(e2(ok,1), "omitnan"), rms(e2(hiU0,1), "omitnan"), rms(e2(ok,2), "omitnan"), rms(e2(hiU0,2), "omitnan"));
    if s1 < bestBr.mpc(1), bestBr.mpc = [s1 to]; end
    if s2 < bestBr.rfb(1), bestBr.rfb = [s2 to]; end
end
fprintf("best: MPC brush observer tau %.1f s, refit brush observer tau %.1f s\n", bestBr.mpc(2), bestBr.rfb(2));
[vyObsM, aObsM] = runObserver(aMpc, WcM, bestBr.mpc(2), vx, r, dl, ayI, ayBias, lf, lr, Ts, ok, straight);
[vyObsR, aObsR] = runObserver(aRfb, WcR, bestBr.rfb(2), vx, r, dl, ayI, ayBias, lf, lr, Ts, ok, straight);

%% trust sweep: more or less trust in the tire model, every observer
% rows: trustPow x trustFloor, columns per observer: front rms all / util > 0.9, rear rms all / util > 0.9

obsIn = {aMf, Cn, tauObs; aMpc, CnMpc, bestBr.mpc(2); aRfb, CnRfb, bestBr.rfb(2)};
obsNm = ["MF", "MPC brush", "refit brush"];
nP = numel(trustPowGrid);  nF = numel(trustFloorGrid);
trustRes = nan(nP, nF, 3, 4);   % [pow, floor, observer, (front all, front hi, rear all, rear hi)]
trustLap = cell(1, nF);         % MPC brush observer slip at trustPow, each floor, for the plot
fprintf("\ntrust sweep, rms error to the measured slip (deg), front all / util > 0.9 per observer\n");
fprintf("%-22s %s\n", "power, floor", sprintf("%-16s", obsNm));
for ip = 1:nP
    for jf = 1:nF
        line = "";
        for m = 1:3
            [~, aT] = runObserver(obsIn{m,1}, trustFn(obsIn{m,2}, trustPowGrid(ip), trustFloorGrid(jf)), obsIn{m,3}, ...
                vx, r, dl, ayI, ayBias, lf, lr, Ts, ok, straight);
            e = rad2deg(aT - aRef);
            trustRes(ip,jf,m,:) = [rms(e(ok,1), "omitnan"), rms(e(hiU0,1), "omitnan"), rms(e(ok,2), "omitnan"), rms(e(hiU0,2), "omitnan")];
            line = line + sprintf("%.2f / %.2f      ", trustRes(ip,jf,m,1:2));
            if m == 2 && trustPowGrid(ip) == trustPow, trustLap{jf} = aT; end
        end
        fprintf("pow %-5g floor %-5g    %s\n", trustPowGrid(ip), trustFloorGrid(jf), line);
    end
end

slipSet  = {aMpc, aRfb, aMf, aObs, aObsM, aObsR};
slipName = ["MPC brush, observed F_z", "refit brush, observed F_z", "MF inverse, observed F_z", "observer slip (MF + IMU)", ...
            "observer slip (MPC brush + IMU)", "observer slip (refit brush + IMU)"];
slipCol  = [cMpc; cRfb; cMf; cObs; cObM; cObR];

fprintf("\nslip rms error to the measured slip (deg), all samples (v > %d) / front utilization > 0.9\n", vMin);
hiU = ok & U(:,1) > 0.9;
for m = 1:numel(slipSet)
    e = rad2deg(slipSet{m} - aRef);
    fprintf("%-30s front %.2f / %.2f   rear %.2f / %.2f\n", slipName(m), rms(e(ok,1), "omitnan"), rms(e(hiU,1), "omitnan"), ...
        rms(e(ok,2), "omitnan"), rms(e(hiU,2), "omitnan"));
end

%% understeer gradient from each model (the MPC's calculation) and measured from slip

vIn   = max(vx, 10);                 % fbl_mpc.cpp passes max(v, 10)
yawIn = aL ./ max(vIn, 5);           % linearization_law: yaw_rate = a_lat / max(v, 5)
kFix = nan(n,1); kMpc = nan(n,1); kRfb = nan(n,1); kMf = nan(n,1); kObs = nan(n,1); kObM = nan(n,1); kObR = nan(n,1);
P = mpcP;
small = deg2rad(0.1);
for j = find(use)'
    [~, kFix(j)] = mpcUndersteer(yawIn(j), vIn(j), 0.0, mpcP, false);    % fixed load, unclamped (reference)
    P.Fz = FzAx(j,:);  P.mu = mpcP.mu;  P.Ca = mpcP.Ca;
    [~, kMpc(j)] = mpcUndersteer(yawIn(j), vIn(j), 0.0, P, false);
    P.mu = [muFit(1, FzAx(j,1)), muFit(2, FzAx(j,2))];
    P.Ca = [CaFit(1, FzAx(j,1)), CaFit(2, FzAx(j,2))];
    [~, kRfb(j)] = mpcUndersteer(yawIn(j), vIn(j), 0.0, P, false);
    kMf(j) = mfUndersteer(yawIn(j), vIn(j), FzAx(j,:), mpcP, pacFy);
    C = zeros(1, 2);
    for ax = 1:2
        aj = max(abs(aObs(j,ax)), small);
        C(ax) = (pac87Fy(pacFy(ax,:), rad2deg(aj), Fz(j,2*ax-1) / 1000) + pac87Fy(pacFy(ax,:), rad2deg(aj), Fz(j,2*ax) / 1000)) / tan(aj);
    end
    kObs(j) = mpcP.m * (mpcP.lr * C(2) - mpcP.lf * C(1)) / ((mpcP.lr + mpcP.lf) * C(1) * C(2));
    % brush at its own observer slip, observed axle load: C = |F_brush(alpha_obs)| / tan(alpha_obs)
    C1 = zeros(1, 2);  C2 = zeros(1, 2);
    for ax = 1:2
        a1 = max(abs(aObsM(j,ax)), small);  a2 = max(abs(aObsR(j,ax)), small);
        C1(ax) = abs(brushFy(a1, FzAx(j,ax), muMpcAx(j,ax), CaMpcAx(j,ax))) / tan(a1);
        C2(ax) = abs(brushFy(a2, FzAx(j,ax), muRfbAx(j,ax), CaRfbAx(j,ax))) / tan(a2);
    end
    kObM(j) = mpcP.m * (mpcP.lr * C1(2) - mpcP.lf * C1(1)) / ((mpcP.lr + mpcP.lf) * C1(1) * C1(2));
    kObR(j) = mpcP.m * (mpcP.lr * C2(2) - mpcP.lf * C2(1)) / ((mpcP.lr + mpcP.lf) * C2(1) * C2(2));
end
kMeas = (aRef(:,1) - aRef(:,2)) ./ ayI;   kMeas(~use) = NaN;
% the measured slip difference carries the steering offset (left / right turns read differently), the offset is the
% median slip difference on straight running, alpha_f - alpha_r = delta - L r / v there, so no v_y is involved
dOff   = median(aRef(straight,1) - aRef(straight,2), "omitnan");
kMeasC = (aRef(:,1) - aRef(:,2) - dOff) ./ ayI;   kMeasC(~use) = NaN;
fprintf("\nsteering offset in the measured slip difference (straight running): %.3f deg\n", rad2deg(dOff));

kSet  = {kMeas, kMeasC, kFix, kMpc, kRfb, kMf, kObs, kObM, kObR};
kName = ["measured from slip", "measured from slip, steering offset removed", "MPC brush, fixed F_z (as run, unclamped)", ...
         "MPC brush, observed F_z", "refit brush, observed F_z", "MF inverse, observed F_z", "MF at observer slip", "MPC brush at its observer slip", "refit brush at its observer slip"];
kCol  = [cRef; cRef * 0.5 + 0.5; cFix; cMpc; cRfb; cMf; cObs; cObM; cObR];

fprintf("\nundersteer gradient, |a_y| > %d (rad/(m/s^2)): median, median |k_us - measured (offset removed)|, above the 0.0012 clamp, jitter\n", kAyMin);
for m = 1:numel(kSet)
    dk = diff(kSet{m});  dk = dk(use(2:end) & use(1:end-1));
    fprintf("%-46s %8.5f %8.5f %5.1f%% %9.2e\n", kName(m), median(kSet{m}(use), "omitnan"), ...
        median(abs(kSet{m}(use) - kMeasC(use)), "omitnan"), 100 * mean(kSet{m}(use) > mpcP.kMax), rms(dk, "omitnan"));
end

% per corner
nC = numel(turnNames);
kCorner = nan(nC, numel(kSet)); FzCorner = nan(nC, 2);
for c = 1:nC
    s = use & hypot(d.px - turnXY(c,1), d.py - turnXY(c,2)) < cornerR;
    if nnz(s) < 50, continue, end
    for m = 1:numel(kSet), kCorner(c,m) = median(kSet{m}(s), "omitnan"); end
    FzCorner(c,:) = median(FzAx(s,:));
end
fprintf("\nmedian k_us per corner, |a_y| > %d\n%-5s %11s | %s\n", kAyMin, "", "Fz f/r [N]", sprintf("%10s ", "meas", "meas-off", "fixed", "MPC obs", "refit", "MF inv", "MF@obs", "MPCb@obs", "refit@obs"));
for c = 1:nC
    fprintf("%-5s %5.0f/%5.0f | %s\n", turnNames(c), FzCorner(c,:), sprintf("%10.5f ", kCorner(c,:)));
end

%% fastest lap

lapWin = fastestLap(t, d.px, d.py, vx, lapRef);
lap  = t >= lapWin(1) & t <= lapWin(2);
tl0  = t(lap) - lapWin(1);
tTurn = zeros(nC, 1);
for c = 1:nC
    [~, m] = min(hypot(d.px(lap) - turnXY(c,1), d.py(lap) - turnXY(c,2)));
    tTurn(c) = tl0(m);
end

%% plots, one window, one tab per plot

fig = figure("Name", "Debug slip angle", "Position", [50 50 1500 1100]);
tg  = uitabgroup(fig);
axNames = ["Front axle", "Rear axle"];

% tab 1: normal load, slip, understeer gradient on the fastest lap
tl  = newTab(tg, "Fastest lap", 6, 1);
axL = gobjects(6, 1);
for ax = 1:2
    axL(ax) = nexttile(tl);
    hold on
    plot(tl0, FzAx(lap,ax), "-", "Color", cObs, "LineWidth", 1.2);
    yline(mpcP.Fz(ax), "--", "Color", cFix, "LineWidth", 1.5);
    grid on
    ylabel("F_z [N]");
    title(axNames(ax) + " normal load");
    legend("observed", "MPC fixed load", "Location", "northwest");
end
for ax = 1:2
    axL(2+ax) = nexttile(tl);
    hold on
    plot(tl0, rad2deg(aRef(lap,ax)), "-", "Color", cRef, "LineWidth", 2);
    for m = 1:numel(slipSet)
        plot(tl0, rad2deg(slipSet{m}(lap,ax)), "-", "Color", slipCol(m,:), "LineWidth", 1.0);
    end
    grid on
    ylim([-8 8]);
    ylabel("\alpha [deg]");
    title(axNames(ax) + " slip");
    legend(["measured (odom v_y)", slipName], "Location", "northwest", "NumColumns", 2, "FontSize", 7);
end
axL(5) = nexttile(tl);
hold on
for m = 1:numel(kSet)
    plot(tl0, kSet{m}(lap), "-", "Color", kCol(m,:), "LineWidth", 1.0 + 0.8 * (m <= 2));
end
yline(mpcP.kMax, "w--", "MPC clamp");
grid on
ylim([-0.002 0.005]);
ylabel("k_{us} [rad/(m/s^2)]");
title("Understeer gradient, |a_y| > " + kAyMin);
legend(kName, "Location", "northwest", "NumColumns", 2, "FontSize", 7);
axL(6) = nexttile(tl);
plot(tl0, aL(lap), "w-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axL, "x");
xlim(axL(1), [0 diff(lapWin)]);
title(tl, sprintf("Normal load, axle slip and understeer gradient, fastest lap %.1f s", diff(lapWin)));

% tab: compare old vs new, the same plots as the fastest lap tab with only the MPC brush steps
% old: MPC brush at the fixed load, then the observed load, new: the MPC brush observer (observed load + IMU)
cmpSlip = {aFix, aMpc, aObsM};
cmpK    = {kFix, kMpc, kObM};
cmpName = ["MPC brush, fixed F_z (old, as run)", "MPC brush, observed F_z", "observed brush model + observed F_z"];
cmpCol  = [cFix; cMpc; cObM];
eFixF = rad2deg(aFix - aRef);
fprintf("\ncompare old vs new, rms slip error (deg) all / front util > 0.9, fastest lap: front, rear\n");
for m = 1:3
    e = rad2deg(cmpSlip{m} - aRef);
    fprintf("%-46s front %.2f / %.2f / %.2f   rear %.2f / %.2f / %.2f\n", cmpName(m), rms(e(ok,1), "omitnan"), rms(e(hiU,1), "omitnan"), ...
        rms(e(ok & lap,1), "omitnan"), rms(e(ok,2), "omitnan"), rms(e(hiU,2), "omitnan"), rms(e(ok & lap,2), "omitnan"));
end

tl  = newTab(tg, "Compare old vs new", 5, 1);
axC = gobjects(5, 1);
axC(1) = nexttile(tl);
hold on
plot(tl0, sum(FzAx(lap,:), 2), "-", "Color", cObs, "LineWidth", 1.2);
yline(sum(mpcP.Fz), "--", "Color", cFix, "LineWidth", 1.5);
grid on
ylabel("F_z [N]");
title("Total normal load, front + rear");
legend("observed", "MPC fixed load", "Location", "northwest");
for ax = 1:2
    axC(1+ax) = nexttile(tl);
    hold on
    plot(tl0, rad2deg(aRef(lap,ax)), "-", "Color", cRef, "LineWidth", 2);
    for m = 1:3
        plot(tl0, rad2deg(cmpSlip{m}(lap,ax)), "-", "Color", cmpCol(m,:), "LineWidth", 1.0 + 1.0 * (m == 3));
    end
    grid on
    ylim([-8 8]);
    ylabel("\alpha [deg]");
    title(axNames(ax) + " slip");
    legend(["measured (odom v_y)", cmpName], "Location", "northwest", "FontSize", 7);
end
axC(4) = nexttile(tl);
hold on
plot(tl0, kMeas(lap),  "-", "Color", cRef * 0.4 + 0.6, "LineWidth", 1.2);
plot(tl0, kMeasC(lap), "-", "Color", cRef, "LineWidth", 2);
for m = 1:3
    plot(tl0, cmpK{m}(lap), "-", "Color", cmpCol(m,:), "LineWidth", 1.0 + 1.0 * (m == 3));
end
yline(mpcP.kMax, "w--", "MPC clamp");
grid on
ylim([-0.002 0.005]);
ylabel("k_{us} [rad/(m/s^2)]");
title("Understeer gradient, |a_y| > " + kAyMin);
legend(["measured from slip", "measured from slip, steering offset removed", cmpName], "Location", "northwest", "FontSize", 7, "NumColumns", 2);
axC(5) = nexttile(tl);
plot(tl0, aL(lap), "w-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axC, "x");
xlim(axC(1), [0 diff(lapWin)]);
title(tl, sprintf("Compare old vs new, MPC brush, fastest lap %.1f s", diff(lapWin)));

%% per tire slip: measured (dual track), brush observer (dual track), brush inverse of the split tire forces
% dual track kinematics as vehicle_model.m: corner speeds vx -/+ r t/2, front corners rotated by delta,
% alpha = -atan2(Vy_tire, Vx_tire), with the observer v_y in place of the odom v_y
% tire force split of the force balance axle Fy:
%   normal load split   Fy_i = Fy_axle Fz_i / (Fz_L + Fz_R)
%   brush corrected     each tire's brush (Ca/2, mu, its observed Fz) at its observer slip sets the left / right shape,
%                       axleCorrect spreads the residual to the axle total (sigA, sigR as vehicle_model.m)
% then each tire's slip from the closed form brush inverse at its own load
% ASSUMPTION: per tire brush = MPC axle brush with half the axle cornering stiffness, same mu
ft = vp.t_f;  rt = vp.t_r;
sigA = 200;  sigR = 0.2;
aTref = [d.alpha_fl, d.alpha_fr, d.alpha_rl, d.alpha_rr];      % measured per tire slip (rad)
aTobs = dualTrackSlip(vyObsM, vx, r, dl, lf, lr, ft, rt);       % brush observer per tire slip
aTloc = dualTrackSlip(vyLoc,  vx, r, dl, lf, lr, ft, rt);       % check: localization v_y through the same kinematics
fprintf("\nper tire slip: dual track check with localization v_y vs vehicle_model.m slip, rms %.3f deg\n", ...
    rms(rad2deg(aTloc(ok,:) - aTref(ok,:)), "all", "omitnan"));

FyNL = zeros(n, 4);  FyBC = zeros(n, 4);  F0 = zeros(n, 4);
for ax = 1:2
    L = 2*ax - 1;  R = 2*ax;
    shL = Fz(:,L) ./ (Fz(:,L) + Fz(:,R));  shL(~isfinite(shL)) = 0.5;
    FyNL(:,L) = Fy(:,ax) .* shL;
    FyNL(:,R) = Fy(:,ax) .* (1 - shL);
    for i = [L R]
        F0(:,i) = brushFy(aTobs(:,i), Fz(:,i), mpcP.mu(ax), mpcP.Ca(ax) / 2);   % brush at the observer slip
    end
    F0(~isfinite(F0)) = 0;
    [FyBC(:,L), FyBC(:,R)] = axleCorrect(Fy(:,ax), F0(:,L), F0(:,R), sigA, sigR);
end
aTnl = nan(n, 4);  aTbc = nan(n, 4);
for i = 1:4
    ax = ceil(i/2);
    for j = find(ok)'
        aTnl(j,i) = -inverseBrush(FyNL(j,i), Fz(j,i), mpcP.mu(ax), mpcP.Ca(ax) / 2);
        aTbc(j,i) = -inverseBrush(FyBC(j,i), Fz(j,i), mpcP.mu(ax), mpcP.Ca(ax) / 2);
    end
end
% force weighted axle slip from the observer: each tire's observer slip weighted by the force it carries
% (brush corrected split), alpha_axle = sum(|Fy_i| alpha_i) / sum(|Fy_i|), the same value drawn on both tires of the axle
% the tire doing the work counts most, which suits nonlinear tires better than a normal load weighting
% each tire's contribution w_i alpha_i, w_i = |Fy_i| / (|Fy_L| + |Fy_R|), the two contributions add up to the axle slip
aTfw = nan(n, 4);  aTct = nan(n, 4);
for ax = 1:2
    L = 2*ax - 1;  R = 2*ax;
    wL = abs(FyBC(:,L)) ./ (abs(FyBC(:,L)) + abs(FyBC(:,R)));
    eq = ~isfinite(wL);  wL(eq) = 0.5;
    aTct(:,L) = wL .* aTobs(:,L);
    aTct(:,R) = (1 - wL) .* aTobs(:,R);
    aTfw(:,L) = aTct(:,L) + aTct(:,R);  aTfw(:,R) = aTfw(:,L);
end
tireNames = ["FL", "FR", "RL", "RR"];
tSet  = {aTobs, aTnl, aTbc};
tName = ["observed brush model + observed F_z (dual track)", "brush inverse, normal load split", "brush inverse, brush corrected split"];
tCol  = [cObM; cMpc; cMf];
fprintf("per tire slip rms error to the measured slip (deg), all samples / own axle utilization > 0.9\n");
for m = 1:3
    line = "";
    for i = 1:4
        e  = rad2deg(tSet{m}(:,i) - aTref(:,i));
        hi = ok & U(:,ceil(i/2)) > 0.9;
        line = line + sprintf("%s %.2f / %.2f   ", tireNames(i), rms(e(ok), "omitnan"), rms(e(hi), "omitnan"));
    end
    fprintf("  %-50s %s\n", tName(m), line);
end
line = "";
for i = 1:4
    e  = rad2deg(aTfw(:,i) - aTref(:,i));
    hi = ok & U(:,ceil(i/2)) > 0.9;
    line = line + sprintf("%s %.2f / %.2f   ", tireNames(i), rms(e(ok), "omitnan"), rms(e(hi), "omitnan"));
end
fprintf("  %-50s %s\n", "observer, force weighted axle slip", line);

% tab: per tire slip and the tire force split
tl  = newTab(tg, "Per tire slip", 5, 2);
axP = gobjects(9, 1);
for i = 1:4
    axP(i) = nexttile(tl);
    hold on
    plot(tl0, rad2deg(aTref(lap,i)), "-", "Color", cRef, "LineWidth", 2);
    for m = 1:3
        plot(tl0, rad2deg(tSet{m}(lap,i)), "-", "Color", tCol(m,:), "LineWidth", 1.0 + 1.0 * (m == 1));
    end
    plot(tl0, rad2deg(aTct(lap,i)), "-", "Color", [0.00 0.45 0.85], "LineWidth", 1.5);
    grid on
    ylim([-8 8]);
    ylabel("\alpha [deg]");
    title(tireNames(i) + " slip");
    if i == 1, legend(["measured (odom v_y, dual track)", tName, "observer, tire contribution w_i \alpha_i (w_i = |F_{y,i}| / \Sigma|F_y|, the axle pair adds to the axle slip)"], ...
            "Location", "northwest", "FontSize", 7); end
end
for i = 1:4
    axP(4+i) = nexttile(tl);
    hold on
    plot(tl0, FyNL(lap,i), "-", "Color", cMpc, "LineWidth", 1.0);
    plot(tl0, FyBC(lap,i), "-", "Color", cMf,  "LineWidth", 1.0);
    plot(tl0, F0(lap,i),   ":", "Color", cObM, "LineWidth", 1.0);
    grid on
    ylabel("F_y [N]");
    title(tireNames(i) + " lateral force split");
    if i == 1, legend("normal load split", "brush corrected split", "brush at observer slip (before correction)", "Location", "northwest", "FontSize", 7); end
end
axP(9) = nexttile(tl, [1 2]);
plot(tl0, aL(lap), "w-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axP, "x");
xlim(axP(1), [0 diff(lapWin)]);
title(tl, sprintf("Per tire slip, measured vs observer vs brush inverse of the split force, fastest lap %.1f s", diff(lapWin)));

%% dual track understeer gradient: slip from the brush observer, force from each tire at its own observed load
% axle slip = mean of the two tires (observer, dual track kinematics), axle stiffness C = (|F_L| + |F_R|) / tan(axle slip)
% then the MPC k_us formula; bicycle versions use the axle slip and the axle load (no left / right load transfer)
%   MPC brush    mu 1.6, Ca/2 per tire (axle: Ca), stiffness does not change with load
%   refit brush  per tire as half an axle at twice the tire load: mu(2 Fz_i), Ca(2 Fz_i)/2 (axle: mu(Fz), Ca(Fz))
%   MF           fitted Pacejka per tire at its own load (axle: two tires at Fz_axle / 2)
aAxO  = [mean(aTobs(:,1:2), 2), mean(aTobs(:,3:4), 2)];
tanAx = tan(max(abs(aAxO), small));
dtName = ["MPC brush", "refit brush", "MF"];
kDT = cell(1, 3);  kBI = cell(1, 3);
for m = 1:3
    Cd = zeros(n, 2);  Cb = zeros(n, 2);
    for ax = 1:2
        Fs = zeros(n, 1);
        for i = 2*ax-1:2*ax
            ai = max(abs(aTobs(:,i)), small);
            switch m
                case 1, Fi = brushFy(ai, Fz(:,i), mpcP.mu(ax), mpcP.Ca(ax) / 2);
                case 2, Fi = brushFy(ai, Fz(:,i), muFit(ax, 2 * Fz(:,i)), CaFit(ax, 2 * Fz(:,i)) / 2);
                case 3, Fi = pac87Fy(pacFy(ax,:), rad2deg(ai), Fz(:,i) / 1000);
            end
            Fs = Fs + abs(Fi);
        end
        Cd(:,ax) = Fs ./ tanAx(:,ax);
        aa = max(abs(aAxO(:,ax)), small);
        switch m
            case 1, Fb = brushFy(aa, FzAx(:,ax), mpcP.mu(ax), mpcP.Ca(ax));
            case 2, Fb = brushFy(aa, FzAx(:,ax), muFit(ax, FzAx(:,ax)), CaFit(ax, FzAx(:,ax)));
            case 3, Fb = 2 * pac87Fy(pacFy(ax,:), rad2deg(aa), FzAx(:,ax) / 2000);
        end
        Cb(:,ax) = abs(Fb) ./ tanAx(:,ax);
    end
    kd = mpcP.m .* (mpcP.lr .* Cd(:,2) - mpcP.lf .* Cd(:,1)) ./ ((mpcP.lr + mpcP.lf) .* Cd(:,1) .* Cd(:,2));
    kb = mpcP.m .* (mpcP.lr .* Cb(:,2) - mpcP.lf .* Cb(:,1)) ./ ((mpcP.lr + mpcP.lf) .* Cb(:,1) .* Cb(:,2));
    kd(~use) = NaN;  kb(~use) = NaN;
    kDT{m} = kd;  kBI{m} = kb;
end

LT = [abs(Fz(:,1) - Fz(:,2)) ./ FzAx(:,1), abs(Fz(:,3) - Fz(:,4)) ./ FzAx(:,2)];   % lateral load transfer ratio
fprintf("\ndual track vs bicycle k_us (observer slip), |a_y| > %d: median, median |k - measured (offset removed)|, above clamp, jitter\n", kAyMin);
for m = 1:3
    for v = 1:2
        if v == 1, kk = kBI{m}; tag = "bicycle (axle load)"; else, kk = kDT{m}; tag = "dual track (tire loads)"; end
        dk = diff(kk); dk = dk(use(2:end) & use(1:end-1));
        fprintf("  %-12s %-24s %8.5f %8.5f %5.1f%% %9.2e\n", dtName(m), tag, median(kk(use), "omitnan"), ...
            median(abs(kk(use) - kMeasC(use)), "omitnan"), 100 * mean(kk(use) > mpcP.kMax), rms(dk, "omitnan"));
    end
end
kDTC = nan(nC, 7);  LTC = nan(nC, 2);
for c = 1:nC
    sc = use & hypot(d.px - turnXY(c,1), d.py - turnXY(c,2)) < cornerR;
    if nnz(sc) < 50, continue, end
    kDTC(c,1) = median(kMeasC(sc), "omitnan");
    for m = 1:3
        kDTC(c,1+m) = median(kBI{m}(sc), "omitnan");
        kDTC(c,4+m) = median(kDT{m}(sc), "omitnan");
    end
    LTC(c,:) = median(LT(sc,:), "omitnan");
end
fprintf("per corner: load transfer f/r | measured | bicycle MPC refit MF | dual MPC refit MF\n");
for c = 1:nC
    fprintf("  %-4s %4.2f/%4.2f | %8.5f | %8.5f %8.5f %8.5f | %8.5f %8.5f %8.5f\n", turnNames(c), LTC(c,:), kDTC(c,:));
end

% tab: dual track understeer gradient
dtCol = [cObM; cRfb; cMf];
tl  = newTab(tg, "Dual track k_us", 4, 1);
axD = nexttile(tl);
hold on
plot(tl0, kMeasC(lap), "-", "Color", cRef, "LineWidth", 2, "DisplayName", "measured from slip, steering offset removed");
for m = 1:3
    plot(tl0, kDT{m}(lap), "-",  "Color", dtCol(m,:), "LineWidth", 1.0 + 1.0 * (m == 1), "DisplayName", dtName(m) + ", dual track (tire loads)");
    plot(tl0, kBI{m}(lap), "--", "Color", dtCol(m,:), "LineWidth", 1.0, "DisplayName", dtName(m) + ", bicycle (axle load)");
end
yline(mpcP.kMax, "w--", "MPC clamp", "HandleVisibility", "off");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
grid on
ylim([-0.002 0.005]);
xlim([0 diff(lapWin)]);
ylabel("k_{us} [rad/(m/s^2)]");
title(sprintf("Understeer gradient from the brush observer slip, dual track (solid) vs bicycle (dashed), fastest lap, |a_y| > %d", kAyMin));
legend("Location", "northwest", "FontSize", 7, "NumColumns", 3);
axD2 = nexttile(tl);
hold on
plot(tl0, LT(lap,1), "-", "Color", cObs, "LineWidth", 1.2);
plot(tl0, LT(lap,2), "--", "Color", cObs, "LineWidth", 1.2);
grid on
ylim([0 1.05]);
xlim([0 diff(lapWin)]);
xlabel("time in lap [s]");
ylabel("|F_{zL} - F_{zR}| / F_z [-]");
title("Lateral load transfer ratio (observed)");
legend("front", "rear", "Location", "northwest");
linkaxes([axD axD2], "x");
nexttile(tl);
b = bar(categorical(turnNames, turnNames), kDTC, "grouped");
b(1).FaceColor = cRef;
for m = 1:3
    b(1+m).FaceColor = dtCol(m,:) * 0.5 + 0.5;
    b(4+m).FaceColor = dtCol(m,:);
end
yline(mpcP.kMax, "w--", "MPC clamp");
grid on
ylabel("median k_{us} [rad/(m/s^2)]");
title("Per corner, whole log, |a_y| > " + kAyMin + " (light: bicycle, dark: dual track)");
legend(["measured, offset removed", dtName + ", bicycle", dtName + ", dual track"], "Location", "northwest", "FontSize", 7, "NumColumns", 2);
nexttile(tl);
b = bar(categorical(turnNames, turnNames), LTC, "grouped");
b(1).FaceColor = [0.30 0.60 0.90]; b(2).FaceColor = [0.10 0.30 0.60];
grid on
ylabel("median load transfer [-]");
title("Lateral load transfer ratio per corner");
legend("front", "rear", "Location", "northwest");
title(tl, "Dual track vs bicycle understeer gradient, brush observer slip");

%% dual track v_y observer: each tire tells the observer v_y, weighted by its load share and how well conditioned it is
% per tire: force balance axle Fy split by observed load (independent of the observer), the tire's MPC brush (Ca/2, mu 1.6,
% its observed Fz) inverted for its slip, then its own kinematics give a v_y:
%   front  alpha_i = delta - atan2(vy + lf r, Vx_i)  ->  vy_i = Vx_i tan(delta - alpha_i) - lf r,  Vx_i = vx -/+ r t_f/2
%   rear   alpha_i = -atan2(vy - lr r, Vx_i)         ->  vy_i = -Vx_i tan(alpha_i) + lr r
% weight w_i = trust(conditioning_i) * Fz_i / Fz_axle, a lifted tire (Fz ~ 0) carries no weight, the loaded tire sets v_y
% overall trust = the larger axle sum of w_i, same IMU integration as the bicycle observer (own trust settings dtTrust*)
% then every tire's slip from the dual track kinematics, an unloaded tire keeps about the slip of the loaded one
aTi = nan(n, 4);  cTi = zeros(n, 4);  vyTi = nan(n, 4);  sTi = zeros(n, 4);
VxC = [vx - r .* (ft/2), vx + r .* (ft/2), vx - r .* (rt/2), vx + r .* (rt/2)];
for i = 1:4
    ax = ceil(i/2);
    for j = find(ok)'
        aTi(j,i) = -inverseBrush(FyNL(j,i), Fz(j,i), mpcP.mu(ax), mpcP.Ca(ax) / 2);
    end
    cTi(:,i) = brushCond(aTi(:,i), FyNL(:,i), Fz(:,i), mpcP.mu(ax), mpcP.Ca(ax) / 2);
    if ax == 1
        vyTi(:,i) = VxC(:,i) .* tan(dl - aTi(:,i)) - lf .* r;
    else
        vyTi(:,i) = -VxC(:,i) .* tan(aTi(:,i)) + lr .* r;
    end
    sTi(:,i) = Fz(:,i) ./ FzAx(:,ax);
end
sTi(~isfinite(sTi)) = 0.5;
wTi  = trustFn(cTi, dtTrustPow, dtTrustFloor) .* sTi;
vyTd = sum(wTi .* vyTi, 2, "omitnan") ./ sum(wTi .* isfinite(vyTi), 2);
wTd  = max([wTi(:,1) + wTi(:,2), wTi(:,3) + wTi(:,4)], [], 2);
[vyDT, aDTax] = runObserverVy(vyTd, wTd, dtTau, vx, r, dl, ayI, ayBias, lf, lr, Ts, ok);
aTdt = dualTrackSlip(vyDT, vx, r, dl, lf, lr, ft, rt);

% k_us: bicycle form (axle slip, axle load) and dual track form (tire slips, tire loads), MPC brush and MF
kDO = cell(1, 4);   % [bicycle obs + bicycle MPC brush, dual obs + bicycle MPC brush, dual obs + dual MPC brush, dual obs + dual MF]
kDO{1} = kObM;
aAxD  = [mean(aTdt(:,1:2), 2), mean(aTdt(:,3:4), 2)];
tanD  = tan(max(abs(aAxD), small));
Cb = zeros(n, 2);  Cdb = zeros(n, 2);  Cdm = zeros(n, 2);
for ax = 1:2
    aa = max(abs(aAxD(:,ax)), small);
    Cb(:,ax) = abs(brushFy(aa, FzAx(:,ax), mpcP.mu(ax), mpcP.Ca(ax))) ./ tanD(:,ax);
    for i = 2*ax-1:2*ax
        ai = max(abs(aTdt(:,i)), small);
        Cdb(:,ax) = Cdb(:,ax) + abs(brushFy(ai, Fz(:,i), mpcP.mu(ax), mpcP.Ca(ax) / 2));
        Cdm(:,ax) = Cdm(:,ax) + abs(pac87Fy(pacFy(ax,:), rad2deg(ai), Fz(:,i) / 1000));
    end
    Cdb(:,ax) = Cdb(:,ax) ./ tanD(:,ax);
    Cdm(:,ax) = Cdm(:,ax) ./ tanD(:,ax);
end
kfun = @(C) mpcP.m .* (mpcP.lr .* C(:,2) - mpcP.lf .* C(:,1)) ./ ((mpcP.lr + mpcP.lf) .* C(:,1) .* C(:,2));
kDO{2} = kfun(Cb);  kDO{3} = kfun(Cdb);  kDO{4} = kfun(Cdm);
for m = 2:4, kDO{m}(~use) = NaN; end
kDOname = ["bicycle observer, bicycle MPC brush k_{us}", "dual track observer, bicycle MPC brush k_{us}", ...
           "dual track observer, dual track MPC brush k_{us}", "dual track observer, dual track MF k_{us}"];

fprintf("\ndual track observer vs bicycle (brush) observer, rms to measured: v_y [m/s] all / fastest lap\n");
fprintf("  bicycle observer     %.3f / %.3f\n", rms(vyObsM(ok) - vyLoc(ok), "omitnan"), rms(vyObsM(ok & lap) - vyLoc(ok & lap), "omitnan"));
fprintf("  dual track observer  %.3f / %.3f\n", rms(vyDT(ok) - vyLoc(ok), "omitnan"), rms(vyDT(ok & lap) - vyLoc(ok & lap), "omitnan"));
fprintf("per tire slip rms (deg): all / own axle util > 0.9 / tire nearly unloaded (Fz < 300 N)\n");
for v = 1:2
    if v == 1, A = aTobs; nm = "bicycle observer"; else, A = aTdt; nm = "dual track observer"; end
    line = "";
    for i = 1:4
        e  = rad2deg(A(:,i) - aTref(:,i));
        hi = ok & U(:,ceil(i/2)) > 0.9;
        lo = ok & Fz(:,i) < 300;
        line = line + sprintf("%s %.2f/%.2f/%.2f  ", tireNames(i), rms(e(ok), "omitnan"), rms(e(hi), "omitnan"), rms(e(lo), "omitnan"));
    end
    fprintf("  %-20s %s\n", nm, line);
end
fprintf("k_us, |a_y| > %d: median, median |k - measured (offset removed)|, above clamp, jitter\n", kAyMin);
for m = 1:4
    dk = diff(kDO{m}); dk = dk(use(2:end) & use(1:end-1));
    fprintf("  %-50s %8.5f %8.5f %5.1f%% %9.2e\n", strrep(strrep(kDOname(m), "_{us}", "_us"), "\", ""), median(kDO{m}(use), "omitnan"), ...
        median(abs(kDO{m}(use) - kMeasC(use)), "omitnan"), 100 * mean(kDO{m}(use) > mpcP.kMax), rms(dk, "omitnan"));
end

% tab: dual track observer
cDT = [0.00 0.45 0.85];   % blue, dual track observer
tl  = newTab(tg, "Dual track observer", 7, 2);
axQ = gobjects(11, 1);
for i = 1:4
    axQ(i) = nexttile(tl);
    hold on
    plot(tl0, rad2deg(aTref(lap,i)), "-", "Color", cRef, "LineWidth", 2);
    plot(tl0, rad2deg(aTobs(lap,i)), "-", "Color", cObM, "LineWidth", 1.5);
    plot(tl0, rad2deg(aTdt(lap,i)),  "-", "Color", cDT,  "LineWidth", 1.5);
    plot(tl0, rad2deg(aTi(lap,i)),   ":", "Color", cMpc, "LineWidth", 0.8);
    grid on
    ylim([-8 8]);
    ylabel("\alpha [deg]");
    title(tireNames(i) + " slip");
    if i == 1, legend("measured (odom v_y)", "bicycle observer", "dual track observer", "this tire's brush inverse (input)", ...
            "Location", "northwest", "FontSize", 7); end
end
for ax = 1:2
    axQ(4+ax) = nexttile(tl);
    hold on
    plot(tl0, wTi(lap,2*ax-1), "-", "Color", cDT, "LineWidth", 1.2);
    plot(tl0, wTi(lap,2*ax),   "-", "Color", cMpc, "LineWidth", 1.2);
    grid on
    ylim([0 1.05]);
    ylabel("weight [-]");
    title(axNames(ax) + ": tire weight in the dual track observer, trust x load share");
    legend(tireNames(2*ax-1), tireNames(2*ax), "Location", "northwest", "FontSize", 7);
end
for ax = 1:2
    axQ(6+ax) = nexttile(tl);
    hold on
    plot(tl0, Fz(lap,2*ax-1), "-", "Color", cDT, "LineWidth", 1.2);
    plot(tl0, Fz(lap,2*ax),   "-", "Color", cMpc, "LineWidth", 1.2);
    yline(300, "w:", "300 N");
    grid on
    ylabel("F_z [N]");
    title(axNames(ax) + ": observed tire load");
    legend(tireNames(2*ax-1), tireNames(2*ax), "Location", "northwest", "FontSize", 7);
end
axQ(9) = nexttile(tl, [1 2]);
hold on
plot(tl0, vyLoc(lap),  "-", "Color", cRef, "LineWidth", 2);
plot(tl0, vyObsM(lap), "-", "Color", cObM, "LineWidth", 1.5);
plot(tl0, vyDT(lap),   "-", "Color", cDT,  "LineWidth", 1.5);
grid on
ylim([-3 3]);
ylabel("v_y [m/s]");
title("Lateral velocity");
legend("measured (localization)", "bicycle observer", "dual track observer", "Location", "northwest", "FontSize", 7);
axQ(10) = nexttile(tl, [1 2]);
hold on
plot(tl0, kMeasC(lap), "-", "Color", cRef, "LineWidth", 2, "DisplayName", "measured from slip, steering offset removed");
cK = [cObM; cDT; [0.55 0.35 0.10]; cMf];
for m = 1:4
    plot(tl0, kDO{m}(lap), "-", "Color", cK(m,:), "LineWidth", 1.0 + 1.0 * (m <= 2), "DisplayName", kDOname(m));
end
yline(mpcP.kMax, "w--", "MPC clamp", "HandleVisibility", "off");
grid on
ylim([-0.002 0.005]);
ylabel("k_{us} [rad/(m/s^2)]");
title("Understeer gradient, |a_y| > " + kAyMin);
legend("Location", "northwest", "FontSize", 7, "NumColumns", 2);
axQ(11) = nexttile(tl, [1 2]);
plot(tl0, aL(lap), "w-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axQ, "x");
xlim(axQ(1), [0 diff(lapWin)]);
title(tl, sprintf("Dual track v_y observer (each tire weighted by conditioning^%g x load share, tau %g s) vs bicycle observer, fastest lap %.1f s", dtTrustPow, dtTau, diff(lapWin)));

% tab 2: the tire models, axle force vs slip at several loads, with the 2026 data
tl = newTab(tg, "Tire models", 2, 2);
aLine  = 0:0.05:8;
zLine  = {[2500 3500 4500], [3500 5000 6500]};
for ax = 1:2
    nexttile(tl);
    hold on
    s = ok & abs(ayI) > 2 & abs(d.Fax) < 2;
    scatter(abs(rad2deg(aRef(s,ax))), abs(Fy(s,ax)), 2, [0.82 0.82 0.82], "filled");
    for z = zLine{ax}
        plot(aLine, -brushTireForce(deg2rad(aLine), z, mpcP.mu(ax), mpcP.Ca(ax)), "-", "Color", cMpc, "LineWidth", 1.2);
        plot(aLine, -brushTireForce(deg2rad(aLine), z, muFit(ax, z), CaFit(ax, z)), "-", "Color", cRfb, "LineWidth", 1.2);
        plot(aLine, 2 * pac87Fy(pacFy(ax,:), aLine, z / 2000), "-", "Color", cMf, "LineWidth", 1.2);
        text(aLine(end), 2 * pac87Fy(pacFy(ax,:), aLine(end), z / 2000), sprintf(" %d N", z), "FontSize", 8);
    end
    grid on
    xlim([0 8]);
    xlabel("axle slip [deg]");
    ylabel("axle |F_y| [N]");
    title(axNames(ax) + ": models at three axle loads, 2026 data (measured slip, force balance F_y)");
    legend("data", "MPC brush", "refit brush", "MF (two tires at F_z / 2)", "Location", "southeast");
end
zz = linspace(1000, 9000, 200);
nexttile(tl);
hold on
for ax = 1:2
    ls = ["-", "--"];
    plot(zz, mpcP.mu(ax) * ones(size(zz)), ls(ax), "Color", cMpc, "LineWidth", 1.5);
    plot(zz, muFit(ax, zz), ls(ax), "Color", cRfb, "LineWidth", 1.5);
    plot(zz, (pacFy(ax,2) .* zz / 2000 + pacFy(ax,3)) / 1000, ls(ax), "Color", cMf, "LineWidth", 1.5);
end
grid on
xlabel("axle F_z [N]");
ylabel("\mu peak [-]");
title("Peak friction vs axle load (solid front, dashed rear)");
legend("MPC brush front", "refit brush front", "MF front", "MPC brush rear", "refit brush rear", "MF rear", "Location", "northeast");
nexttile(tl);
hold on
for ax = 1:2
    plot(zz, mpcP.Ca(ax) * ones(size(zz)) / 1000, ls(ax), "Color", cMpc, "LineWidth", 1.5);
    plot(zz, CaFit(ax, zz) / 1000, ls(ax), "Color", cRfb, "LineWidth", 1.5);
    plot(zz, 2 * pacFy(ax,4) .* sin(pacFy(ax,5) .* atan(pacFy(ax,6) .* zz / 2000)) * 180/pi / 1000, ls(ax), "Color", cMf, "LineWidth", 1.5);
end
grid on
xlabel("axle F_z [N]");
ylabel("C_\alpha [kN/rad]");
title("Axle cornering stiffness vs axle load (solid front, dashed rear)");
legend("MPC brush front", "refit brush front", "MF front", "MPC brush rear", "refit brush rear", "MF rear", "Location", "northwest");

% tab: the observers against the measured values (localization v_y and the slip built from it)
obsV = {vyO, vyObsM, vyObsR};
obsA = {aObs, aObsM, aObsR};
obsN = ["observer, MF + IMU", "observer, MPC brush + IMU", "observer, refit brush + IMU"];
obsC = [cObs; cObM; cObR];
% trust in the tire model inside each observer: conditioning^power of the best conditioned axle (1 steep, 0 at the peak)
obsW = {max(Wc, [], 2), max(WcM, [], 2), max(WcR, [], 2)};
fprintf("\nobservers vs measured, rms (all samples / fastest lap): v_y [m/s], front slip [deg], rear slip [deg]\n");
for m = 1:3
    fprintf("%-30s v_y %.3f / %.3f   front %.2f / %.2f   rear %.2f / %.2f\n", obsN(m), ...
        rms(obsV{m}(ok) - vyLoc(ok), "omitnan"), rms(obsV{m}(ok & lap) - vyLoc(ok & lap), "omitnan"), ...
        rms(rad2deg(obsA{m}(ok,1) - aRef(ok,1)), "omitnan"), rms(rad2deg(obsA{m}(ok & lap,1) - aRef(ok & lap,1)), "omitnan"), ...
        rms(rad2deg(obsA{m}(ok,2) - aRef(ok,2)), "omitnan"), rms(rad2deg(obsA{m}(ok & lap,2) - aRef(ok & lap,2)), "omitnan"));
end

tl  = newTab(tg, "Observers vs measured", 7, 1);
axO = gobjects(7, 1);
axO(1) = nexttile(tl);
hold on
plot(tl0, vyLoc(lap), "-", "Color", cRef, "LineWidth", 2);
for m = 1:3, plot(tl0, obsV{m}(lap), "-", "Color", obsC(m,:), "LineWidth", 1.0); end
grid on
ylim([-3 3]);
ylabel("v_y [m/s]");
title("Lateral velocity");
legend(["measured (localization, filtered " + fcSig + " Hz)", obsN], "Location", "northwest", "FontSize", 7);
for ax = 1:2
    axO(1+ax) = nexttile(tl);
    hold on
    plot(tl0, rad2deg(aRef(lap,ax)), "-", "Color", cRef, "LineWidth", 2);
    for m = 1:3, plot(tl0, rad2deg(obsA{m}(lap,ax)), "-", "Color", obsC(m,:), "LineWidth", 1.0); end
    grid on
    ylim([-8 8]);
    ylabel("\alpha [deg]");
    title(axNames(ax) + " slip");
    legend(["measured (from localization v_y)", obsN], "Location", "northwest", "FontSize", 7);
end
for ax = 1:2
    axO(3+ax) = nexttile(tl);
    hold on
    for m = 1:3, plot(tl0, rad2deg(obsA{m}(lap,ax) - aRef(lap,ax)), "-", "Color", obsC(m,:), "LineWidth", 1.0); end
    yline(0, "w-");
    grid on
    ylim([-2 2]);
    ylabel("\Delta\alpha [deg]");
    title(axNames(ax) + " slip error, observer - measured");
    legend(obsN, "Location", "northwest", "FontSize", 7);
end
axO(6) = nexttile(tl);
hold on
for m = 1:3, plot(tl0, obsW{m}(lap), "-", "Color", obsC(m,:), "LineWidth", 1.0); end
grid on
ylim([0 1.05]);
ylabel("trust [-]");
title("Trust in the tire model inside each observer (best conditioned axle, 1 = steep curve, 0 = at the peak)");
legend(obsN, "Location", "southwest", "FontSize", 7);
axO(7) = nexttile(tl);
plot(tl0, aL(lap), "w-");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8);
grid on
xlabel("time in lap [s]");
ylabel("v r [m/s^2]");
title("Lateral acceleration");
linkaxes(axO, "x");
xlim(axO(1), [0 diff(lapWin)]);
title(tl, sprintf("Observers vs measured, fastest lap %.1f s", diff(lapWin)));

% tab: trust sweep
tl = newTab(tg, "Trust sweep", 3, 3);
for m = 1:3
    for row = 1:2
        nexttile(tl, (row - 1) * 3 + m);
        hold on
        axl = ["front", "rear"];
        cP  = lines(nP);
        for ip = 1:nP
            plot(trustFloorGrid, squeeze(trustRes(ip,:,m,2*row-1)), "-o", "Color", cP(ip,:), "LineWidth", 1.2, ...
                "DisplayName", "all samples, pow " + trustPowGrid(ip));
            plot(trustFloorGrid, squeeze(trustRes(ip,:,m,2*row)), "--s", "Color", cP(ip,:), "LineWidth", 1.0, ...
                "DisplayName", "util > 0.9, pow " + trustPowGrid(ip));
        end
        grid on
        xlabel("trust floor");
        ylabel("rms error [deg]");
        title("Observer " + obsNm(m) + ": " + axl(row) + " slip error");
        if m == 1, legend("Location", "best", "FontSize", 6); end
    end
end
nexttile(tl, 7, [1 3]);
hold on
cF = parula(nF + 1);
for jf = 1:nF
    plot(tl0, rad2deg(trustLap{jf}(lap,1) - aRef(lap,1)), "-", "Color", cF(jf,:), "LineWidth", 1.0, ...
        "DisplayName", sprintf("floor %g", trustFloorGrid(jf)));
end
yline(0, "w-", "HandleVisibility", "off");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
grid on
ylim([-2 2]);
xlim([0 diff(lapWin)]);
xlabel("time in lap [s]");
ylabel("\Delta\alpha front [deg]");
title(sprintf("MPC brush observer, front slip error (observer - measured) for each trust floor, trust power %g, fastest lap", trustPow));
legend("Location", "northwest", "FontSize", 7);
title(tl, "Trust sweep: trust = max(floor, conditioning^{power}), solid all samples, dashed front utilization > 0.9");

% tab: understeer gradient of the MPC brush observer for each trust floor, against the measured k_us
% k_us from the brush at its observer slip and the observed axle load: C = |F_brush(alpha_obs)| / tan(alpha_obs),
% then the MPC formula, same as "MPC brush at its observer slip" (trust power trustPow, floors trustFloorGrid)
kTrust = cell(1, nF);
fprintf("\nMPC brush observer k_us vs trust floor (trust power %g), |a_y| > %d: median, median |k - measured (offset removed)|, above clamp, jitter\n", trustPow, kAyMin);
for jf = 1:nF
    C = zeros(n, 2);
    for ax = 1:2
        aa = max(abs(trustLap{jf}(:,ax)), small);
        C(:,ax) = abs(brushFy(aa, FzAx(:,ax), muMpcAx(:,ax), CaMpcAx(:,ax))) ./ tan(aa);
    end
    kT = mpcP.m .* (mpcP.lr .* C(:,2) - mpcP.lf .* C(:,1)) ./ ((mpcP.lr + mpcP.lf) .* C(:,1) .* C(:,2));
    kT(~use) = NaN;
    kTrust{jf} = kT;
    dk = diff(kT);  dk = dk(use(2:end) & use(1:end-1));
    fprintf("  floor %-5g %8.5f %8.5f %5.1f%% %9.2e\n", trustFloorGrid(jf), median(kT(use), "omitnan"), ...
        median(abs(kT(use) - kMeasC(use)), "omitnan"), 100 * mean(kT(use) > mpcP.kMax), rms(dk, "omitnan"));
end

tl = newTab(tg, "k_us vs trust", 3, 1);
axT = nexttile(tl);
hold on
plot(tl0, kMeas(lap),  "-", "Color", cRef * 0.4 + 0.6, "LineWidth", 1.2, "DisplayName", "measured from slip");
plot(tl0, kMeasC(lap), "-", "Color", cRef, "LineWidth", 2.0, "DisplayName", "measured from slip, steering offset removed");
for jf = 1:nF
    plot(tl0, kTrust{jf}(lap), "-", "Color", cF(jf,:), "LineWidth", 1.1, "DisplayName", sprintf("MPC brush observer, trust floor %g", trustFloorGrid(jf)));
end
yline(mpcP.kMax, "w--", "MPC clamp", "HandleVisibility", "off");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
grid on
ylim([-0.002 0.004]);
xlim([0 diff(lapWin)]);
xlabel("time in lap [s]");
ylabel("k_{us} [rad/(m/s^2)]");
title(sprintf("Understeer gradient, MPC brush at its observer slip (observed F_z) for each trust floor, trust power %g, fastest lap, |a_y| > %d", trustPow, kAyMin));
legend("Location", "northwest", "FontSize", 7, "NumColumns", 2);
axW = nexttile(tl);
hold on
for jf = 1:nF
    wUsed = max(trustFn(CnMpc, trustPow, trustFloorGrid(jf)), [], 2);   % trust used in the correction (best axle)
    plot(tl0, wUsed(lap), "-", "Color", cF(jf,:), "LineWidth", 1.1, "DisplayName", sprintf("trust floor %g", trustFloorGrid(jf)));
end
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
grid on
ylim([0 1.05]);
xlim([0 diff(lapWin)]);
xlabel("time in lap [s]");
ylabel("trust [-]");
title(sprintf("Trust used in the MPC brush observer, max(floor, conditioning^{%g}) of the best axle (1 = tire model, 0 = IMU only)", trustPow));
legend("Location", "southwest", "FontSize", 7, "NumColumns", nF);
linkaxes([axT axW], "x");
nexttile(tl);
kTC = nan(nC, nF + 1);
for c = 1:nC
    sc = use & hypot(d.px - turnXY(c,1), d.py - turnXY(c,2)) < cornerR;
    if nnz(sc) < 50, continue, end
    kTC(c,1) = median(kMeasC(sc), "omitnan");
    for jf = 1:nF, kTC(c,jf+1) = median(kTrust{jf}(sc), "omitnan"); end
end
b = bar(categorical(turnNames, turnNames), kTC, "grouped");
b(1).FaceColor = cRef;
for jf = 1:nF, b(jf+1).FaceColor = cF(jf,:); end
yline(mpcP.kMax, "w--", "MPC clamp");
grid on
ylabel("median k_{us} [rad/(m/s^2)]");
title("Per corner, whole log, |a_y| > " + kAyMin);
legend(["measured, steering offset removed", compose("trust floor %g", trustFloorGrid)], "Location", "northwest", "FontSize", 7);
title(tl, "k_us vs trust in the tire model, MPC brush observer");

% tab: settling time (tau) sweep of the MPC brush observer, for a few trust floors
% short tau + full trust collapses the observer onto the raw brush inverse, long tau leans on the IMU integration
nT = numel(tauGrid);  nTF = numel(tauFloors);
tauRes = nan(nT, nTF, 4);        % [tau, floor, (front all, front util > 0.9, k_us |error| median, k_us above clamp %)]
tauLap = cell(nT, 1);  tauK = cell(nT, 1);   % slip and k_us at the last floor (full trust) for the traces
eRaw = rad2deg(aMpc - aRef);
fprintf("\ntau sweep, MPC brush observer (trust power %g): front slip rms all / util > 0.9 [deg], k_us median |error|, above clamp\n", trustPow);
fprintf("raw MPC brush inverse (no observer): front %.2f / %.2f\n", rms(eRaw(ok,1), "omitnan"), rms(eRaw(hiU0,1), "omitnan"));
for jf = 1:nTF
    for it = 1:nT
        [~, aT] = runObserver(aMpc, trustFn(CnMpc, trustPow, tauFloors(jf)), tauGrid(it), vx, r, dl, ayI, ayBias, lf, lr, Ts, ok, straight);
        e  = rad2deg(aT - aRef);
        kT = kAtSlip(aT, FzAx, muMpcAx, CaMpcAx, mpcP, use, small);
        tauRes(it,jf,:) = [rms(e(ok,1), "omitnan"), rms(e(hiU0,1), "omitnan"), median(abs(kT(use) - kMeasC(use)), "omitnan"), ...
                           100 * mean(kT(use) > mpcP.kMax)];
        if jf == nTF, tauLap{it} = aT; tauK{it} = kT; end
        fprintf("  floor %-4g tau %-5g  front %.2f / %.2f   k_us |error| %.5f, above clamp %4.1f%%\n", tauFloors(jf), tauGrid(it), tauRes(it,jf,:));
    end
end

tl = newTab(tg, "Tau sweep", 3, 2);
cTF = lines(nTF);
nexttile(tl);
hold on
for jf = 1:nTF
    plot(tauGrid, tauRes(:,jf,1), "-o", "Color", cTF(jf,:), "LineWidth", 1.2, "DisplayName", sprintf("all samples, floor %g", tauFloors(jf)));
    plot(tauGrid, tauRes(:,jf,2), "--s", "Color", cTF(jf,:), "LineWidth", 1.2, "DisplayName", sprintf("util > 0.9, floor %g", tauFloors(jf)));
end
yline(rms(eRaw(hiU0,1), "omitnan"), "w:", "raw inverse, util > 0.9", "HandleVisibility", "off");
yline(rms(eRaw(ok,1), "omitnan"), "w-.", "raw inverse, all", "HandleVisibility", "off");
set(gca, "XScale", "log");
grid on
xlabel("observer tau [s]");
ylabel("front slip rms error [deg]");
title("Front slip error vs tau");
legend("Location", "best", "FontSize", 7);
nexttile(tl);
hold on
for jf = 1:nTF
    yyaxis left
    plot(tauGrid, tauRes(:,jf,3), "-o", "Color", cTF(jf,:), "LineWidth", 1.2, "DisplayName", sprintf("|error|, floor %g", tauFloors(jf)));
    yyaxis right
    plot(tauGrid, tauRes(:,jf,4), "--s", "Color", cTF(jf,:), "LineWidth", 1.0, "DisplayName", sprintf("above clamp, floor %g", tauFloors(jf)));
end
yyaxis left;  ylabel("k_{us} median |k - measured| [rad/(m/s^2)]");
yyaxis right; ylabel("above clamp [%]");
set(gca, "XScale", "log");
grid on
xlabel("observer tau [s]");
title("Understeer gradient vs tau (measured with the steering offset removed)");
legend("Location", "best", "FontSize", 7);
cTau = parula(nT + 1);
axS1 = nexttile(tl, [1 2]);
hold on
for it = 1:nT
    plot(tl0, rad2deg(tauLap{it}(lap,1) - aRef(lap,1)), "-", "Color", cTau(it,:), "LineWidth", 1.0, "DisplayName", sprintf("tau %g s", tauGrid(it)));
end
plot(tl0, eRaw(lap,1), ":", "Color", [0.5 0.5 0.5], "DisplayName", "raw MPC brush inverse");
yline(0, "w-", "HandleVisibility", "off");
grid on
ylim([-3 3]);
ylabel("\Delta\alpha front [deg]");
title(sprintf("Front slip error (observer - measured), full trust (floor %g), fastest lap", tauFloors(end)));
legend("Location", "northwest", "FontSize", 7, "NumColumns", 3);
axS2 = nexttile(tl, [1 2]);
hold on
plot(tl0, kMeasC(lap), "-", "Color", cRef, "LineWidth", 2, "DisplayName", "measured, steering offset removed");
for it = 1:nT
    plot(tl0, tauK{it}(lap), "-", "Color", cTau(it,:), "LineWidth", 1.0, "DisplayName", sprintf("tau %g s", tauGrid(it)));
end
yline(mpcP.kMax, "w--", "MPC clamp", "HandleVisibility", "off");
xline(tTurn, ":", turnNames, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
grid on
ylim([-0.002 0.004]);
xlabel("time in lap [s]");
ylabel("k_{us} [rad/(m/s^2)]");
title(sprintf("Understeer gradient, MPC brush at its observer slip, full trust (floor %g), |a_y| > %d", tauFloors(end), kAyMin));
legend("Location", "northwest", "FontSize", 7, "NumColumns", 3);
linkaxes([axS1 axS2], "x");
xlim(axS1, [0 diff(lapWin)]);
title(tl, "Observer settling time sweep, MPC brush observer");

% tab 3: understeer gradient by corner
tl = newTab(tg, "k_us by corner", 2, 1);
nexttile(tl);
b = bar(categorical(turnNames, turnNames), kCorner, "grouped");
for m = 1:numel(kSet), b(m).FaceColor = kCol(m,:); end
yline(mpcP.kMax, "w--", "MPC clamp");
grid on
ylabel("median k_{us} [rad/(m/s^2)]");
title("Understeer gradient per corner, |a_y| > " + kAyMin + ", whole log");
legend(kName, "Location", "northwest");
nexttile(tl);
b = bar(categorical(turnNames, turnNames), FzCorner, "grouped");
b(1).FaceColor = [0.30 0.60 0.90]; b(2).FaceColor = [0.10 0.30 0.60];
hold on
yline(mpcP.Fz(1), "--", "Color", cFix, "LineWidth", 1.2);
yline(mpcP.Fz(2), ":", "Color", cFix, "LineWidth", 1.2);
grid on
ylabel("median axle F_z [N]");
title("Observed axle load per corner (lines: MPC fixed loads)");
legend("front", "rear", "MPC front", "MPC rear", "Location", "northwest");


function [vyO, Ao] = runObserverVy(vyT, wT, tauO, vx, r, dl, ayI, ayBias, lf, lr, Ts, ok)
% v_y observer with a given tire model v_y (vyT) and trust (wT): IMU integration pulled to vyT with weight wT

    n   = numel(vx);
    vyO = zeros(n, 1);
    for k = 2:n
        dv = (ayI(k) - ayBias - vx(k) * r(k)) * Ts;
        if ~ok(k) || ~isfinite(dv), vyO(k) = 0; continue, end
        vyO(k) = vyO(k-1) + dv;
        if isfinite(vyT(k)) && isfinite(wT(k))
            vyO(k) = vyO(k) + (Ts / tauO) * wT(k) * (vyT(k) - vyO(k));
        end
    end
    Ao = [dl - atan((vyO + lf .* r) ./ max(vx, 1)), -atan((vyO - lr .* r) ./ max(vx, 1))];
    Ao(~ok,:) = NaN;
end


function [vyO, Ao, vyT, wT] = runObserver(Ain, Wc, tauO, vx, r, dl, ayI, ayBias, lf, lr, Ts, ok, straight) %#ok<INUSD>
% v_y observer: IMU integration dvy/dt = a_y - bias - vx r, pulled to the tire model v_y with weight Wc (best axle)

    n   = numel(vx);
    vyF = vx .* tan(dl - Ain(:,1)) - lf .* r;
    vyR = -vx .* tan(Ain(:,2)) + lr .* r;
    vyT = (Wc(:,1) .* vyF + Wc(:,2) .* vyR) ./ (Wc(:,1) + Wc(:,2) + 1e-6);
    wT  = max(Wc, [], 2);
    vyO = zeros(n, 1);
    for k = 2:n
        dv = (ayI(k) - ayBias - vx(k) * r(k)) * Ts;
        if ~ok(k) || ~isfinite(dv), vyO(k) = 0; continue, end
        vyO(k) = vyO(k-1) + dv;
        if isfinite(vyT(k))
            vyO(k) = vyO(k) + (Ts / tauO) * wT(k) * (vyT(k) - vyO(k));
        end
    end
    Ao = [dl - atan((vyO + lf .* r) ./ max(vx, 1)), -atan((vyO - lr .* r) ./ max(vx, 1))];
    Ao(~ok,:) = NaN;
end


function [k_us, k_raw, Cf, Cr, af, ar] = mpcUndersteer(yaw_rate, velocity, acceleration, P, clampOn)
% UnicycleModelLogic::under_steer_coefficient + effective_stiffness, line for line
% P: m, lf, lr, coh, mu [f r], Fz [f r] (normal_load), Ca [f r], kMax
% af, ar: the axle slip angles the inverse brush gives (rad, our sign alpha > 0 -> Fy > 0), for debugging, not in the C++

    Fz_f = P.Fz(1) - P.m * acceleration * P.coh / (P.lr + P.lf);
    Fz_r = P.Fz(2) + P.m * acceleration * P.coh / (P.lr + P.lf);
    if velocity < 0.1 || abs(yaw_rate) < 0.00001
        % singular case, should return to the gradient near zero
        small_slip = 0.001;
        Cf = brushTireForce(small_slip, Fz_f, P.mu(1), P.Ca(1)) / small_slip;
        Cr = brushTireForce(small_slip, Fz_r, P.mu(2), P.Ca(2)) / small_slip;
        af = 0;
        ar = 0;
    else
        Fy_target = P.m * velocity * yaw_rate;
        % need to check which tire will saturate first here
        max_fyf = P.mu(1) * Fz_f;
        max_fyr = P.mu(2) * Fz_r;
        if abs(max_fyf * P.lf / P.lr) > abs(max_fyr)
            % rear saturate first, check rear first
            Fyr = max(min(Fy_target * P.lf / (P.lr + P.lf), max_fyr), -max_fyr);
            Fyf = Fyr * P.lr / P.lf;
        else
            % front saturate first, check front first
            Fyf = max(min(Fy_target * P.lr / (P.lr + P.lf), max_fyf), -max_fyf);
            Fyr = Fyf * P.lf / P.lr;
        end
        alpha_f = inverseBrush(Fyf, Fz_f, P.mu(1), P.Ca(1));
        alpha_r = inverseBrush(Fyr, Fz_r, P.mu(2), P.Ca(2));
        Cf = Fyf / tan(alpha_f);
        Cr = Fyr / tan(alpha_r);
        af = -alpha_f;   % controller slip angle is ours negated
        ar = -alpha_r;
    end
    Cf = abs(Cf);
    Cr = abs(Cr);

    k_us  = (P.m * (P.lr * Cr - P.lf * Cf)) / ((P.lr + P.lf) * Cf * Cr);
    k_raw = k_us;
    if clampOn && P.kMax > 0 && k_us > P.kMax
        k_us = P.kMax;
    end
end


function [k_us, Cf, Cr, af, ar] = mfUndersteer(yaw_rate, velocity, FzAx, P, pacFy)
% same steps as the MPC effective_stiffness / under_steer_coefficient, with our fitted Pacejka in place of the brush
% ASSUMPTION: each axle is two tires at half the observed axle load, no left/right load transfer (as the MPC bicycle)
% ASSUMPTION: past the peak the axle sits at the peak slip angle (the MPC does the same with the brush threshold)

    aGrid = (0:0.01:15)';   % (deg)
    Fax = zeros(numel(aGrid), 2);
    for ax = 1:2
        Fax(:,ax) = 2 * pac87Fy(pacFy(ax,:), aGrid, FzAx(ax) / 2000);
    end
    [Fpk, ipk] = max(Fax);

    if velocity < 0.1 || abs(yaw_rate) < 0.00001
        small = 0.001;   % (rad)
        Cf = 2 * pac87Fy(pacFy(1,:), rad2deg(small), FzAx(1) / 2000) / small;
        Cr = 2 * pac87Fy(pacFy(2,:), rad2deg(small), FzAx(2) / 2000) / small;
        af = 0;
        ar = 0;
    else
        Fy_target = P.m * velocity * yaw_rate;
        if abs(Fpk(1) * P.lf / P.lr) > abs(Fpk(2))
            Fyr = max(min(Fy_target * P.lf / (P.lr + P.lf), Fpk(2)), -Fpk(2));
            Fyf = Fyr * P.lr / P.lf;
        else
            Fyf = max(min(Fy_target * P.lr / (P.lr + P.lf), Fpk(1)), -Fpk(1));
            Fyr = Fyf * P.lf / P.lr;
        end
        F = [Fyf, Fyr];
        C = zeros(1, 2);
        for ax = 1:2
            if abs(F(ax)) >= Fpk(ax)
                a = aGrid(ipk(ax));
            else
                a = interp1(Fax(1:ipk(ax),ax), aGrid(1:ipk(ax)), abs(F(ax)));   % inverse on the rising side
            end
            C(ax) = abs(F(ax)) / tan(deg2rad(a));
            A(ax) = sign(F(ax)) * deg2rad(a);   %#ok<AGROW> signed axle slip angle (rad)
        end
        Cf = C(1);
        Cr = C(2);
        af = A(1);
        ar = A(2);
    end

    k_us = (P.m * (P.lr * Cr - P.lf * Cf)) / ((P.lr + P.lf) * Cf * Cr);
end


function [a, u, cn, aPk] = axleInverse(c, F, FzLR, aGrid, ok)
% axle slip where Pac(alpha, FzL) + Pac(alpha, FzR) = F, both tires at the axle slip, rising side
% u = |F| / axle peak, cn = local slope / initial slope at the answer (0 at or past the peak)

    n = numel(F);
    a = nan(n, 1); u = nan(n, 1); cn = zeros(n, 1); aPk = nan(n, 1);
    idx = find(ok);
    da  = aGrid(2) - aGrid(1);
    for s = 1:5000:numel(idx)
        j  = idx(s:min(s + 4999, numel(idx)));
        Fg = pac87Fy(c, aGrid, FzLR(j,1) / 1000) + pac87Fy(c, aGrid, FzLR(j,2) / 1000);   % [samples, grid]
        [Fpk, ipk] = max(Fg, [], 2);
        Fa = abs(F(j));
        u(j)   = Fa ./ Fpk;
        aPk(j) = deg2rad(aGrid(ipk))';
        col = 1:numel(aGrid);
        hit = Fg >= Fa & col <= ipk;
        [has, k] = max(hit, [], 2);
        sat = ~has | Fa >= Fpk;
        k   = max(k, 2);
        lin = sub2ind(size(Fg), (1:numel(j))', k);
        lo  = sub2ind(size(Fg), (1:numel(j))', k - 1);
        aa  = aGrid(k - 1)' + (Fa - Fg(lo)) ./ (Fg(lin) - Fg(lo)) * da;
        aa(sat) = aGrid(ipk(sat))';
        slope = (Fg(lin) - Fg(lo)) / da;
        s0    = Fg(:,2) / da;
        cc    = min(max(slope ./ s0, 0), 1);
        cc(sat) = 0;
        a(j)  = sign(F(j)) .* deg2rad(aa);
        cn(j) = cc;
    end
end


function [win, lapTimes] = fastestLap(t, px, py, v, ref)
% laps timed between passes of the reference point (within 20 m, moving), fastest complete lap

    near = hypot(px - ref(1), py - ref(2)) < 20 & v > 5;
    tp   = t(diff([0; near]) == 1);
    tp   = tp([true; diff(tp) > 40]);
    lapTimes = diff(tp);
    [~, j]   = min(lapTimes);
    win      = [tp(j), tp(j+1)];
end


function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact");
end


function [mid, med] = binMed(x, y, edges, nMin)
% median of y in each bin of x, bins with fewer than nMin samples left out

    mid = 0.5 * (edges(1:end-1) + edges(2:end));
    med = nan(size(mid));
    for b = 1:numel(mid)
        s = x >= edges(b) & x < edges(b+1) & isfinite(y);
        if nnz(s) >= nMin
            med(b) = median(y(s));
        end
    end
    keep = isfinite(med);
    mid  = mid(keep);
    med  = med(keep);
end


function y = lpf(x, fc, Ts)
% first order Tustin low pass, same as vehicle_model.m, starts settled at the first sample

    Kt = tan(pi * fc * Ts);
    a1 = (1 - Kt) / (1 + Kt);
    b  =      Kt  / (1 + Kt);
    x  = fillmissing(x, "previous");
    x  = fillmissing(x, "next");
    y  = filter([b b], [1 -a1], x - x(1,:)) + x(1,:);
end


function Fy = pac87Fy(c, alpha, Fz)
% Bakker, Nyborg, Pacejka 1987 (tires.pdf), alpha in deg, Fz in kN, c = [C a1 ... a8]

    Fz  = max(Fz, 0.01);
    D   = c(2) .* Fz.^2 + c(3) .* Fz;
    BCD = c(4) .* sin(c(5) .* atan(c(6) .* Fz));
    B   = BCD ./ (c(1) .* D);
    E   = c(7) .* Fz.^2 + c(8) .* Fz + c(9);
    phi = (1 - E) .* alpha + E ./ B .* atan(B .* alpha);
    Fy  = D .* sin(c(1) .* atan(B .* phi));
end


function alpha_out = inverseBrush(Fy_target, Fz, mu, Ca)
% UnicycleModelLogic::inverse_brush_tire_slip, line for line (slip angle in rad, controller sign)

    Fz     = max(100.0, Fz);
    Fy_max = mu * Fz;
    if Ca > 0 && mu > 0 && Fz > 0, a_th = 3.0 * Fy_max / Ca; else, a_th = 0.0; end

    if abs(Fy_target) >= Fy_max || a_th <= 0.0
        sgn_alpha = -1.0 * (Fy_target > 0.0) + 1.0 * (Fy_target < 0.0);
        alpha_out = atan(sgn_alpha * a_th);
        return
    end

    s  = -1.0 * (Fy_target > 0.0) + 1.0 * (Fy_target < 0.0);   % slip angle sign
    k1 = Ca;
    k2 = (Ca * Ca) / (3.0 * mu * Fz);
    k3 = (Ca * Ca * Ca) / (27.0 * mu * mu * Fz * Fz);

    % solve: k3*a^3 - s*k2*a^2 + k1*a + Fy = 0
    A = k3; B = -s * k2; C = k1; D = Fy_target;
    a = B / A; b = C / A; c = D / A;

    % depressed cubic y^3 + p y + q = 0 with a = y - a/3
    a_over_3 = a / 3.0;
    p = b - a * a_over_3;
    q = 2.0 * a_over_3^3 - a_over_3 * b + c;
    disc = 0.25 * q * q + (p * p * p) / 27.0;

    if disc >= 0.0
        sqrt_disc = sqrt(disc);
        u = nthroot(-0.5 * q + sqrt_disc, 3);
        v = nthroot(-0.5 * q - sqrt_disc, 3);
        cand = u + v - a_over_3;
    else
        r   = 2.0 * sqrt(-p / 3.0);
        phi = acos((-0.5 * q) / sqrt(-(p * p * p) / 27.0));
        cand = r * cos((phi + 2.0 * pi * (0:2)) / 3.0) - a_over_3;
    end

    % pick the root with correct sign and inside [0, a_th]
    sb = @(x) x < 0 || (x == 0 && 1 / x < 0);   % std::signbit
    best = cand(1);
    best_cost = 1e300;
    for aa = cand
        cost = 0.0;
        if sb(aa) ~= sb(s), cost = cost + 1e3; end
        if abs(aa) > a_th, cost = cost + (abs(aa) - a_th) * 100.0; end
        cost = cost + abs(abs(aa) - min(abs(aa), a_th));
        if cost < best_cost, best_cost = cost; best = aa; end
    end
    alpha = min(abs(best), a_th);
    if sb(s), alpha = -alpha; end                % std::copysign
    alpha_out = atan(alpha);
end


function Fy = brushTireForce(slip_angle, Fz, mu, Ca)
% line for line from the C++, vectorised

    Fz       = max(100.0, Fz);
    Fy_max   = mu .* Fz;
    alpha    = tan(slip_angle);
    a_thresh = 3.0 .* Fy_max ./ Ca;

    term1 = -Ca .* alpha;
    term2 = (Ca .* Ca) ./ (3.0 .* mu .* Fz) .* abs(alpha) .* alpha;
    term3 = -(Ca .* Ca .* Ca) ./ (27.0 .* mu .* mu .* Fz .* Fz) .* alpha .* alpha .* alpha;
    Fy    = term1 + term2 + term3;

    sat     = abs(alpha) > a_thresh;                          % saturation
    sgn     = 2 .* (slip_angle >= 0.0) - 1;
    Fy_sat  = -Fy_max .* sgn;
    Fy(sat) = Fy_sat(sat);
end


function a = dualTrackSlip(vy, vx, r, dl, lf, lr, ft, rt)
% per tire slip from the body v_y, dual track kinematics as vehicle_model.m, [FL FR RL RR] (rad)

    Vx  = vx;  Vx(abs(Vx) < 4) = NaN;
    VyF = vy + r .* lf;
    VyR = vy - r .* lr;
    VxC = [Vx - r .* (ft/2), Vx + r .* (ft/2), Vx - r .* (rt/2), Vx + r .* (rt/2)];
    VxT = [VxC(:,1) .* cos(dl) + VyF .* sin(dl), VxC(:,2) .* cos(dl) + VyF .* sin(dl), VxC(:,3), VxC(:,4)];
    VyT = [-VxC(:,1) .* sin(dl) + VyF .* cos(dl), -VxC(:,2) .* sin(dl) + VyF .* cos(dl), VyR, VyR];
    a   = -atan2(VyT, VxT);
end


function [fL, fR] = axleCorrect(S, fL, fR, sigA, sigR)
% spread the axle residual S - (fL + fR) by each tire's prior variance (same as vehicle_model.m)

    PL = (sigA + sigR .* abs(fL)).^2;
    PR = (sigA + sigR .* abs(fR)).^2;
    r  = S - (fL + fR);

    fL = fL + r .* PL ./ (PL + PR);
    fR = fR + r .* PR ./ (PL + PR);
end


function k = kAtSlip(a, FzAx, mu, Ca, P, use, small)
% understeer gradient from the brush at the given axle slip: C = |F_brush(alpha)| / tan(alpha), then the MPC formula

    C = zeros(size(a));
    for ax = 1:2
        aa = max(abs(a(:,ax)), small);
        C(:,ax) = abs(brushFy(aa, FzAx(:,ax), mu(:,ax), Ca(:,ax))) ./ tan(aa);
    end
    k = P.m .* (P.lr .* C(:,2) - P.lf .* C(:,1)) ./ ((P.lr + P.lf) .* C(:,1) .* C(:,2));
    k(~use) = NaN;
end


function cn = brushCond(a, F, FzAx, mu, Ca)
% conditioning of the brush inverse, local slope / initial slope = (1 - |tan alpha| / t_th)^2, t_th = 3 mu Fz / Ca
% 0 at or past saturation (|F| >= mu Fz)

    tth = 3 .* mu .* max(FzAx, 100) ./ Ca;
    cn  = (1 - min(abs(tan(a)) ./ tth, 1)).^2;
    cn(abs(F) >= mu .* max(FzAx, 100)) = 0;
    cn(~isfinite(cn)) = 0;
end


function Fy = brushFy(alpha, Fz, mu, Ca)
% brush axle force with our slip sign (alpha in rad, alpha > 0 -> Fy > 0), the controller's slip is ours negated

    Fy = brushTireForce(-alpha, Fz, mu, Ca);
end
