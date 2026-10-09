clc
close all
clear
% plot_vehicle_model_validation - the on-vehicle vehicle_model package outputs on the comp2 fastest lap
% data: the comp2 bag replayed at 1x through vehicle_model_node and the MPC acceleration_interface (ABS debug),
% recorded and merged with vehicle_model_validation_topics.yaml; the raw sensor channels come from the comp2 CSV
% colors: front left dark red, front right light red, rear left dark blue, rear right light blue,
% front axle red, rear axle blue, raw / reference data grey, corners C1 to C11 as dotted lines

%% settings

nodeCsv = "/home/elijah/PurdueRacing/bags/lagoona/comp2/node_replay/rec_vm_validation_csv/rec_vm_validation_merged.csv";
rawCsv  = "/home/elijah/PurdueRacing/bags/lagoona/comp2/compition_bags/2026-09-03_121638_merged.csv";
mpcCsv  = "/home/elijah/PurdueRacing/bags/lagoona/comp2/mpc_command/2026-09-03_121638_merged.csv";
figDir  = "/home/elijah/code/CodeFiles/Research/VD/Vehicle_modeling/validation_figs";

% Laguna Seca: lap timed at the C11 reference point, corners by position (odom x, y in m)
lapRef    = [100 144];
turnXY    = [-165 -270; -144 -518; -100 -302; 149 -345; 148 -797; 526 -743; 581 -361; 591 -281; 546 -233; 487 -73; 260 -78; 99 139];
turnNames = ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C8A", "C9", "C10", "C11"];

% package parameters (config/vehicle_model/params.yaml) used for the reference curves
m     = 815;   g = 9.81;   rho = 1.225;   ClA = 0.58;
mu    = 1.6;   Ca = [174000 290000];   pCa = [0.76 0.78];   Fz0 = [1679 2318.6];
L     = 2.9718;   lf = 0.58 * L;   lr = 0.42 * L;
lfMpc = 1.6785;   lrMpc = 1.2933;   % the MPC's own geometry, for its k_us from the logged Ca_eff

% colors
cT    = [0.55 0.00 0.00; 1.00 0.45 0.45; 0.00 0.20 0.60; 0.40 0.70 1.00];   % FL, FR, RL, RR
cA    = [0.85 0.10 0.10; 0.10 0.35 0.85];                                   % front, rear axle
cRaw  = [0.62 0.62 0.62];                                                   % raw / reference
cRaw2 = [0.80 0.80 0.80];
cK    = [0.15 0.15 0.15];                                                   % model / reference line
tireN = ["FL", "FR", "RL", "RR"];   tireS = ["fl", "fr", "rl", "rr"];
axN   = ["Front", "Rear"];          axS   = ["f", "r"];
r2d   = 180 / pi;

%% load and align on the raw 100 Hz grid

R = readtable(rawCsv);
N = readtable(nodeCsv);
M = readtable(mpcCsv);
tAbs = R.time_s;
t    = tAbs - tAbs(1);

lapWin = fastestLap(t, R.odom_px_m, R.odom_py_m, R.odom_vx_mps, lapRef);
lap    = t >= lapWin(1) & t <= lapWin(2);
tL     = t(lap) - lapWin(1);
fprintf("fastest lap: %.2f s (t = %.1f to %.1f s)\n", diff(lapWin), lapWin(1), lapWin(2));

tTurn = zeros(numel(turnNames), 1);
pxL = R.odom_px_m(lap);  pyL = R.odom_py_m(lap);
for c = 1:numel(turnNames)
    [~, j] = min(hypot(pxL - turnXY(c,1), pyL - turnXY(c,2)));
    tTurn(c) = tL(j);
end

% node and MPC columns on the lap samples (signals linear, flags and counters previous)
tq  = tAbs(lap);
nd  = @(col) interp1(N.time_s, N.(col), tq, "linear");
nf  = @(col) interp1(N.time_s, double(N.(col)), tq, "previous");
nb  = @(col) nf(col) > 0.5;   % flags: the merge script interpolates bool columns linearly
mp  = @(col) interp1(M.time_s, M.(col), tq, "linear");
raw = @(col) R.(col)(lap);

vx  = raw("odom_vx_mps");   vyLoc = raw("odom_vy_mps");   ay = raw("a_y");
if all(isnan(nd("dual_k_us")))
    error("node CSV has no samples on the fastest lap - check nodeCsv and the replay time base");
end

% per tire and per axle package outputs
for i = 1:4
    s = tireS(i);
    sx(:,i)      = nd("dual_slip_ratio_x_" + s);      %#ok<SAGROW>
    kap(:,i)     = nd("dual_kappa_" + s);             %#ok<SAGROW>
    aHat(:,i)    = nd("dual_slip_angle_obs_" + s);    %#ok<SAGROW>  slip_angle_hat
    aKin(:,i)    = nd("dual_slip_angle_kin_" + s);    %#ok<SAGROW>
    fzHat(:,i)   = nd("dual_fz_obs_" + s);            %#ok<SAGROW>  fz_hat
    fzMdl(:,i)   = nd("dual_fz_model_" + s);          %#ok<SAGROW>
    fx(:,i)      = nd("dual_fx_" + s);                %#ok<SAGROW>
    fy(:,i)      = nd("dual_fy_corrected_" + s);      %#ok<SAGROW>
    lifted(:,i)  = nb("dualdbg_lifted_" + s);         %#ok<SAGROW>
    sat(:,i)     = nb("dualdbg_saturated_" + s);      %#ok<SAGROW>
end
for a = 1:2
    s = axS(a);
    aHatAx(:,a)  = nd("bike_slip_angle_obs_" + s);    %#ok<SAGROW>
    aKinAx(:,a)  = nd("bike_slip_angle_kin_" + s);    %#ok<SAGROW>
    fzHatAx(:,a) = nd("bike_fz_obs_" + s);            %#ok<SAGROW>
    fyAx(:,a)    = nd("bike_fy_" + s);                %#ok<SAGROW>
end
vyBike = nd("bike_vy_obs");   vyDual = nd("dual_vy_obs");
kBike  = nd("bike_k_us");     kDual  = nd("dual_k_us");
kValid  = nb("dualdbg_k_us_valid");
running = nb("dualdbg_observer_running");

% ABS: activations are the steps of the trigger counters
absF = [0; diff(nf("abs_front_count"))] > 0;
absR = [0; diff(nf("abs_rear_count"))] > 0;
pF = raw("front_brake_pressure_kpa");   pR = raw("rear_brake_pressure_kpa");

% raw strain gages (bias corrected for the plot: shifted to the observed load median over the lap)
gage = [raw("fl_load_n"), raw("fr_load_n"), raw("rl_load_n"), raw("rr_load_n")];
gage = fillmissing(gage, "previous");
gageCorr = gage - median(gage - fzHat, "omitnan");

% wheel speeds (raw)
vw = [raw("fl_speed_kmh"), raw("fr_speed_kmh"), raw("rl_speed_kmh"), raw("rr_speed_kmh")] ./ 3.6;

% MPC k_us as run and its unclamped value from the logged effective stiffness
kMpc     = mp("mpc_k_ug");
kMpcCalc = m .* (lrMpc .* mp("mpc_ca_r_eff") - lfMpc .* mp("mpc_ca_f_eff")) ./ ((lfMpc + lrMpc) .* mp("mpc_ca_f_eff") .* mp("mpc_ca_r_eff"));
downforce = 0.5 * rho * ClA .* vx.^2;
az = raw("a_z");   % accel_filtered, gravity removed
r  = raw("odom_wz_rads");

% measured k_us from the localization slips (reference): (alpha_f - alpha_r - straight line offset) / a_y
dAlpha   = aKinAx(:,1) - aKinAx(:,2);
straight = vx > 10 & abs(ay) < 1;
kMeas    = (dAlpha - median(dAlpha(straight), "omitnan")) ./ movmean(ay, 25);
kMeas(abs(vx .* r) <= 4) = NaN;

%% figures

if ~exist(figDir, "dir"), mkdir(figDir); end
fig = figure("Name", "Vehicle model validation, comp2 fastest lap", "Position", [40 40 1600 1000]);
theme(fig, "light");
tg = uitabgroup(fig);
corners = @(ax) markCorners(ax, tTurn, turnNames);

% 1 slip ratios and ABS ------------------------------------------------------------------------------------------
tl = newTab(tg, "Slip ratio and ABS", 3, 1);
ax1 = nexttile(tl);  hold on
for i = 1:4, plot(tL, sx(:,i), "-", "Color", cT(i,:), "LineWidth", 1.1); end
grid on;  ylabel("s_x [-]");  ylim([-0.3 0.3]);
title("Slip ratio s_x per tire (wheel speed referenced, the ABS input)");
legend(tireN, "Location", "eastoutside");  corners(ax1);
ax2 = nexttile(tl);  hold on
plot(tL, pF, "-", "Color", cRaw, "LineWidth", 1.2);
plot(tL, pR, "-", "Color", cRaw2, "LineWidth", 1.2);
yl = max([pF; pR; 100]) * 1.05;
stem(tL(absF), yl * ones(nnz(absF),1), "v", "Color", cA(1,:), "MarkerFaceColor", cA(1,:), "LineWidth", 1.2);
stem(tL(absR), 0.9 * yl * ones(nnz(absR),1), "v", "Color", cA(2,:), "MarkerFaceColor", cA(2,:), "LineWidth", 1.2);
grid on;  ylabel("brake pressure [kPa]");  ylim([0 yl * 1.08]);
title(sprintf("Measured brake pressure (raw) and ABS activations from acceleration\\_interface (front %d, rear %d on this lap)", nnz(absF), nnz(absR)));
legend("front pressure (raw)", "rear pressure (raw)", "ABS front active", "ABS rear active", "Location", "eastoutside");
corners(ax2);
linkaxes([ax1 ax2], "x");  xlim(ax1, [0 tL(end)]);

% zoom on the largest braking slip of the lap
[~, jz] = min(min(sx, [], 2));
zw = tL >= tL(jz) - 1.5 & tL <= tL(jz) + 1.5;
tlz = tiledlayout(tl, 1, 2);  tlz.Layout.Tile = 3;
axz = nexttile(tlz);  hold on
for i = 1:4, plot(tL(zw), sx(zw,i), "-", "Color", cT(i,:), "LineWidth", 1.4); end
yline(-0.15, ":", "ABS engage 0.15", "Color", cK);  yline(-0.10, ":", "release 0.10", "Color", cK);
if any(absF & zw), xline(tL(absF & zw), "-", "Color", cA(1,:)); end
if any(absR & zw), xline(tL(absR & zw), "--", "Color", cA(2,:)); end
grid on;  xlabel("Time [s]");  ylabel("s_x [-]");
title(sprintf("Zoom: largest braking slip of the lap (t = %.1f s, %s)", tL(jz), nearestCorner(tL(jz), tTurn, turnNames)));
axz2 = nexttile(tlz);  hold on
plot(tL(zw), vx(zw), "-", "Color", cK, "LineWidth", 1.6);
for i = 1:4, plot(tL(zw), vw(zw,i), "-", "Color", cT(i,:), "LineWidth", 1.1); end
grid on;  xlabel("Time [s]");  ylabel("speed [m/s]");
title("Zoom: wheel speeds (raw, km/h / 3.6) against the vehicle speed");
legend(["v_x localization", tireN + " wheel"], "Location", "best");

% 2 speed, slip angles, lateral force -----------------------------------------------------------------------------
tl = newTab(tg, "Speed, slip angle, F_y", 4, 1);
axs = gobjects(4,1);
axs(1) = nexttile(tl);
plot(tL, vx, "-", "Color", cRaw, "LineWidth", 1.4);
grid on;  ylabel("v_x [m/s]");  title("Vehicle speed (localization, raw)");
axs(2) = nexttile(tl);  hold on
for i = 1:4, plot(tL, rad2deg(aHat(:,i)), "-", "Color", cT(i,:), "LineWidth", 1.1); end
grid on;  ylabel("\alpha [deg]");  title("Observed slip angle per tire \alpha_{hat} (dual track observer)");
legend(tireN, "Location", "eastoutside");
axs(3) = nexttile(tl);  hold on
for i = 1:4, plot(tL, fy(:,i), "-", "Color", cT(i,:), "LineWidth", 1.1); end
grid on;  ylabel("F_y [N]");  title("Lateral force per tire (axle F_y split by load, brush corrected)");
legend(tireN, "Location", "eastoutside");
axs(4) = nexttile(tl);  hold on
for a = 1:2, plot(tL, fyAx(:,a), "-", "Color", cA(a,:), "LineWidth", 1.3); end
grid on;  ylabel("F_y [N]");  title("Lateral force per axle (force and yaw moment balance on the measured a_y)");
legend(axN, "Location", "eastoutside");  xlabel(tl, "Time [s]");
for k = 1:4, corners(axs(k)); end
linkaxes(axs, "x");  xlim(axs(1), [0 tL(end)]);

% 3 slip angle vs F_y and mu_y per axle ---------------------------------------------------------------------------
tl = newTab(tg, "Slip angle vs F_y, axle", 2, 2);
aGrid = linspace(0, 8, 200)';
for a = 1:2
    ok = running & isfinite(aHatAx(:,a)) & fzHatAx(:,a) > 300;
    nexttile(tl, a);  hold on
    scatter(rad2deg(aKinAx(ok,a)), fyAx(ok,a), 4, cRaw, "filled", "MarkerFaceAlpha", 0.35);
    scatter(rad2deg(aHatAx(ok,a)), fyAx(ok,a), 6, cA(a,:), "filled", "MarkerFaceAlpha", 0.5);
    for fzA = Fz0(a) * 2 * [0.6 1 1.4]
        f = brushFy(deg2rad(aGrid), fzA, mu, 2 * caTire(fzA / 2, Ca(a), Fz0(a), pCa(a)));
        plot([-flip(aGrid); aGrid], [-flip(f); f], "-", "Color", cK, "LineWidth", 1);
        text(aGrid(end), f(end), sprintf(" %.1f kN", fzA / 1000), "FontSize", 8);
    end
    grid on;  xlabel("\alpha [deg]");  ylabel("F_y [N]");  xlim([-8 8]);
    title(axN(a) + " axle: observed slip vs axle F_y, brush at 0.6 / 1 / 1.4 x static load");
    legend("localization kinematic slip (reference)", "observed slip \alpha_{hat}", "brush model", "Location", "northwest");
    nexttile(tl, a + 2);  hold on
    scatter(rad2deg(aKinAx(ok,a)), fyAx(ok,a) ./ fzHatAx(ok,a), 4, cRaw, "filled", "MarkerFaceAlpha", 0.35);
    scatter(rad2deg(aHatAx(ok,a)), fyAx(ok,a) ./ fzHatAx(ok,a), 6, cA(a,:), "filled", "MarkerFaceAlpha", 0.5);
    for fzA = Fz0(a) * 2 * [0.6 1 1.4]
        f = brushFy(deg2rad(aGrid), fzA, mu, 2 * caTire(fzA / 2, Ca(a), Fz0(a), pCa(a))) ./ fzA;
        plot([-flip(aGrid); aGrid], [-flip(f); f], "-", "Color", cK, "LineWidth", 1);
    end
    yline([-mu mu], ":", "\mu = 1.6", "Color", cK);
    grid on;  xlabel("\alpha [deg]");  ylabel("\mu_y = F_y / F_{z,hat}");  xlim([-8 8]);  ylim([-2 2]);
    title(axN(a) + " axle: observed slip vs \mu_y (axle F_y over observed axle load)");
end

% 4 slip angle vs F_y and mu_y per tire ---------------------------------------------------------------------------
tl = newTab(tg, "Slip angle vs F_y, tire", 2, 4);
for i = 1:4
    a  = 1 + (i > 2);
    ok = running & isfinite(aHat(:,i)) & fzHat(:,i) > 300;
    nexttile(tl, i);  hold on
    scatter(rad2deg(aKin(ok,i)), fy(ok,i), 4, cRaw, "filled", "MarkerFaceAlpha", 0.3);
    scatter(rad2deg(aHat(ok,i)), fy(ok,i), 6, cT(i,:), "filled", "MarkerFaceAlpha", 0.5);
    for fzT = Fz0(a) * [0.5 1 1.5]
        f = brushFy(deg2rad(aGrid), fzT, mu, caTire(fzT, Ca(a), Fz0(a), pCa(a)));
        plot([-flip(aGrid); aGrid], [-flip(f); f], "-", "Color", cK, "LineWidth", 1);
    end
    grid on;  xlabel("\alpha [deg]");  ylabel("F_y [N]");  xlim([-8 8]);
    title(tireN(i) + ": \alpha_{hat} vs F_y (brush at 0.5 / 1 / 1.5 x static)");
    nexttile(tl, i + 4);  hold on
    scatter(rad2deg(aKin(ok,i)), fy(ok,i) ./ fzHat(ok,i), 4, cRaw, "filled", "MarkerFaceAlpha", 0.3);
    scatter(rad2deg(aHat(ok,i)), fy(ok,i) ./ fzHat(ok,i), 6, cT(i,:), "filled", "MarkerFaceAlpha", 0.5);
    for fzT = Fz0(a) * [0.5 1 1.5]
        f = brushFy(deg2rad(aGrid), fzT, mu, caTire(fzT, Ca(a), Fz0(a), pCa(a))) ./ fzT;
        plot([-flip(aGrid); aGrid], [-flip(f); f], "-", "Color", cK, "LineWidth", 1);
    end
    yline([-mu mu], ":", "Color", cK);
    grid on;  xlabel("\alpha [deg]");  ylabel("\mu_y");  xlim([-8 8]);  ylim([-2.2 2.2]);
    title(tireN(i) + ": \alpha_{hat} vs \mu_y = F_y / F_{z,hat}");
end
lg = legend(nexttile(tl, 1), "localization kinematic slip (reference)", "observed", "brush model");
lg.Layout.Tile = "south";

% 5 slip ratio vs F_x and mu_x per tire ---------------------------------------------------------------------------
tl = newTab(tg, "Slip ratio vs F_x, tire", 2, 4);
for i = 1:4
    ok = isfinite(sx(:,i)) & vx > 10 & fzHat(:,i) > 300;
    nexttile(tl, i);  hold on
    scatter(100 * sx(ok,i), fx(ok,i), 5, cT(i,:), "filled", "MarkerFaceAlpha", 0.45);
    grid on;  xlabel("s_x [%]");  ylabel("F_x [N]");  xlim([-20 10]);
    title(tireN(i) + ": slip ratio vs F_x (wheel dynamics)");
    nexttile(tl, i + 4);  hold on
    scatter(100 * sx(ok,i), fx(ok,i) ./ fzHat(ok,i), 5, cT(i,:), "filled", "MarkerFaceAlpha", 0.45);
    grid on;  xlabel("s_x [%]");  ylabel("\mu_x = F_x / F_{z,hat}");  xlim([-20 10]);  ylim([-2.2 1.2]);
    title(tireN(i) + ": slip ratio vs \mu_x");
end

% 6 normal load: raw strain gage vs observer vs load model ---------------------------------------------------------
tl = newTab(tg, "Normal load, gage vs observer", 5, 1);
axn = gobjects(5,1);
for i = 1:4
    axn(i) = nexttile(tl);  hold on
    plot(tL, gageCorr(:,i), "-", "Color", cRaw, "LineWidth", 1.2);
    plot(tL, fzMdl(:,i), "--", "Color", cK, "LineWidth", 0.9);
    plot(tL, fzHat(:,i), "-", "Color", cT(i,:), "LineWidth", 1.4);
    grid on;  ylabel("F_z [N]");
    title(tireN(i) + ": strain gage (raw, offset removed for the plot), load model, observed F_{z,hat}");
    legend("strain gage (raw)", "load model", "observed", "Location", "eastoutside");
end
axn(5) = nexttile(tl);  hold on
plot(tL, m * (g + movmean(az, 25)) + downforce, "-", "Color", cRaw, "LineWidth", 1.0);
plot(tL, m * g + downforce, "-", "Color", cK, "LineWidth", 1.4);
plot(tL, sum(fzMdl, 2), "--", "Color", cK);
plot(tL, sum(fzHat, 2), "-", "Color", cA(1,:), "LineWidth", 1.3);
grid on;  ylabel("\Sigma F_z [N]");
title("Total normal load: m (g + a_z) + downforce from the raw accelerometer vs the sum of the model / observed loads");
legend("m (g + a_z) + downforce (raw a_z)", "m g + downforce", "load model", "observed", "Location", "eastoutside");
xlabel(tl, "Time [s]");
for k = 1:5, corners(axn(k)); end
linkaxes(axn, "x");  xlim(axn(1), [0 tL(end)]);

% 7 understeer gradient, downforce, lateral acceleration -----------------------------------------------------------
tl = newTab(tg, "Understeer gradient", 3, 1);
axk = gobjects(3,1);
axk(1) = nexttile(tl);  hold on
plot(tL, kMeas, ".", "Color", cRaw, "MarkerSize", 3);
plot(tL, kMpcCalc, "-", "Color", cRaw2, "LineWidth", 1.0);
plot(tL, kMpc, "-", "Color", cRaw, "LineWidth", 1.4);
plot(tL, kBike, "-", "Color", cA(2,:), "LineWidth", 1.2);
plot(tL, kDual, "-", "Color", cA(1,:), "LineWidth", 1.4);
kv = double(kValid);  kv(~kValid) = NaN;
plot(tL, -0.0002 * kv, "-", "Color", cK, "LineWidth", 3);
yline(0.0012, ":", "MPC clamp 0.0012", "Color", cK);
grid on;  ylabel("k_{us} [rad/(m/s^2)]");  ylim([-0.0005 0.0035]);
title("Understeer gradient: MPC as run (comp2 log) vs the vehicle model package");
legend("measured, localization slips (reference)", "MPC own calc, unclamped (from logged C_{a,eff})", "MPC as run (clamped)", "vehicle model bicycle", "vehicle model dual track", "k\_us\_valid (dynamic)", "Location", "eastoutside");
axk(2) = nexttile(tl);
plot(tL, downforce, "-", "Color", cA(1,:), "LineWidth", 1.3);
grid on;  ylabel("downforce [N]");  title("Total downforce 0.5 \rho C_LA v_x^2 (load model)");
axk(3) = nexttile(tl);
plot(tL, ay, "-", "Color", cRaw, "LineWidth", 1.2);
grid on;  ylabel("a_y [m/s^2]");  title("Lateral acceleration (accel\_filtered, raw)");
xlabel(tl, "Time [s]");
for k = 1:3, corners(axk(k)); end
linkaxes(axk, "x");  xlim(axk(1), [0 tL(end)]);

% 8 lateral velocity -----------------------------------------------------------------------------------------------
tl = newTab(tg, "Lateral velocity", 2, 1);
axv = gobjects(2,1);
axv(1) = nexttile(tl);  hold on
plot(tL, vyLoc, "-", "Color", cRaw, "LineWidth", 1.6);
plot(tL, vyBike, "-", "Color", cA(2,:), "LineWidth", 1.1);
plot(tL, vyDual, "-", "Color", cA(1,:), "LineWidth", 1.1);
grid on;  ylabel("v_y [m/s]");
title(sprintf("Lateral velocity: localization (reference) vs observers, lap rms error bicycle %.3f, dual track %.3f m/s", ...
    rms(vyBike(running) - vyLoc(running), "omitnan"), rms(vyDual(running) - vyLoc(running), "omitnan")));
legend("localization (reference)", "v_{y,hat} bicycle", "v_{y,hat} dual track", "Location", "eastoutside");
axv(2) = nexttile(tl);  hold on
plot(tL, vyBike - vyLoc, "-", "Color", cA(2,:));
plot(tL, vyDual - vyLoc, "-", "Color", cA(1,:));
yline(0, "-", "Color", cK);
grid on;  ylabel("v_{y,hat} - v_{y,loc} [m/s]");  title("Observer minus localization");
legend("bicycle", "dual track", "Location", "eastoutside");  xlabel(tl, "Time [s]");
for k = 1:2, corners(axv(k)); end
linkaxes(axv, "x");  xlim(axv(1), [0 tL(end)]);

% 9 tire utilization (friction circle) ------------------------------------------------------------------------------
tl = newTab(tg, "Friction circle, tire", 1, 4);
th = linspace(0, 2*pi, 200);
for i = 1:4
    ok = running & fzHat(:,i) > 300;
    nexttile(tl);  hold on
    scatter(fy(ok,i) ./ fzHat(ok,i), fx(ok,i) ./ fzHat(ok,i), 5, cT(i,:), "filled", "MarkerFaceAlpha", 0.45);
    plot(mu * cos(th), mu * sin(th), ":", "Color", cK, "LineWidth", 1.2);
    axis equal;  grid on;  xlim([-2.4 2.4]);  ylim([-2.4 2.4]);
    xlabel("\mu_y = F_y / F_{z,hat}");  ylabel("\mu_x = F_x / F_{z,hat}");
    title(tireN(i) + sprintf(": friction use (circle \\mu = %.1f)", mu));
end

% 10 lateral load transfer vs a_y ----------------------------------------------------------------------------------
tl = newTab(tg, "Load transfer vs a_y", 1, 2);
ayG = linspace(-25, 25, 2);
for a = 1:2
    iL = 2 * a - 1;  iR = 2 * a;
    ok = running & isfinite(ay);
    nexttile(tl);  hold on
    scatter(ay(ok), (fzHat(ok,iR) - fzHat(ok,iL)) / 2, 5, cA(a,:), "filled", "MarkerFaceAlpha", 0.4);
    p = polyfit(ay(ok), (fzMdl(ok,iR) - fzMdl(ok,iL)) / 2, 1);
    plot(ayG, polyval(p, ayG), "-", "Color", cK, "LineWidth", 1.5);
    grid on;  xlabel("a_y [m/s^2]");  ylabel("(F_{z,R} - F_{z,L}) / 2 [N]");
    title(axN(a) + sprintf(" axle lateral load transfer: observed vs load model (%.0f N per m/s^2)", p(1)));
    legend("observed", "load model (steady state roll)", "Location", "northwest");
end

% 11 flags ---------------------------------------------------------------------------------------------------------
tl = newTab(tg, "Debug flags", 3, 1);
axf = gobjects(3,1);
axf(1) = nexttile(tl);  hold on
area(tL, double(running), "FaceColor", cRaw2, "EdgeColor", "none");
area(tL, 0.6 * double(kValid), "FaceColor", cA(1,:), "EdgeColor", "none", "FaceAlpha", 0.6);
grid on;  ylim([0 1.1]);  yticks([]);
title("Observer running (grey) and dynamic k\_us valid (red)");
axf(2) = nexttile(tl);  hold on
for i = 1:4, y = (5 - i) * ones(size(tL));  y(~sat(:,i)) = NaN;  plot(tL, y, "-", "Color", cT(i,:), "LineWidth", 6); end
grid on;  ylim([0.5 4.5]);  yticks(1:4);  yticklabels(flip(tireN));  title("Saturated tire (|F_y| >= \mu F_z in the brush)");
axf(3) = nexttile(tl);  hold on
for i = 1:4, y = (5 - i) * ones(size(tL));  y(~lifted(:,i)) = NaN;  plot(tL, y, "-", "Color", cT(i,:), "LineWidth", 6); end
grid on;  ylim([0.5 4.5]);  yticks(1:4);  yticklabels(flip(tireN));  title("Lifted tire (F_{z,hat} < 300 N)");
xlabel(tl, "Time [s]");
for k = 1:3, corners(axf(k)); end
linkaxes(axf, "x");  xlim(axf(1), [0 tL(end)]);

%% export every tab as a png

tabs = tg.Children;
for k = 1:numel(tabs)
    tg.SelectedTab = tabs(k);
    drawnow;
    exportgraphics(tabs(k), fullfile(figDir, sprintf("%02d_%s.png", k, regexprep(tabs(k).Title, "[^A-Za-z0-9]+", "_"))), "Resolution", 130);
end
fprintf("figures written to %s\n", figDir);


%% local functions

function tl = newTab(tg, name, rows, cols)
% new tab in the plot window with a tiled layout

    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact", "Padding", "compact");
end


function markCorners(ax, tTurn, names)
% dotted line and label at every corner

    xline(ax, tTurn, ":", names, "Color", [0.45 0.45 0.45], "LabelVerticalAlignment", "top", ...
        "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
end


function name = nearestCorner(tq, tTurn, names)
% the corner closest in time

    [~, j] = min(abs(tTurn - tq));
    name = "near " + names(j);
end


function f = brushFy(alpha, fz, mu, ca)
% brush lateral force magnitude (alpha > 0 -> F_y > 0), saturated past t_th = 3 mu F_z / C_a

    x = min(abs(tan(alpha)) ./ (3 * mu * fz / ca), 1);
    f = mu * fz .* (1 - (1 - x).^3);
end


function c = caTire(fz, caAxle, fz0, p)
% load sensitive cornering stiffness of one tire, C_a / 2 (F_z / F_z0)^p

    c = caAxle / 2 * (max(fz, 100) / fz0)^p;
end


function win = fastestLap(t, px, py, v, ref)
% laps timed between passes of the reference point (within 20 m, moving), the fastest complete lap [start end] (s)

    near = hypot(px - ref(1), py - ref(2)) < 20 & v > 5;
    tp   = t(diff([0; near]) == 1);
    tp   = tp([true; diff(tp) > 40]);
    [~, j] = min(diff(tp));
    win  = [tp(j), tp(j+1)];
end
