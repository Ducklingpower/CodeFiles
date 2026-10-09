% compare_observer_variants - dual track v_y observer and k_us variants on the comp2 log (research only)
% 1 inverse:  the package's dual track observer (vehicle_model.m dualTrackObserver: brush inverse of the measured axle
%             Fy split, equal weights, IMU predict, tau 0.2 s), k_us at its slips
% 2 command:  same observer, k_us evaluated at the MPC's commanded a_lat (axle slip that gives the commanded axle force
%             at the observed tire loads), measured |vx r| when the command is missing; gate on |a_lat,cmd|
% 3 forward:  forward model observer (back pocket, README 9b): measured steering and yaw rate drive the per tire brush
%             (observed Fz) to predict v_y, the accelerometer a_y is the correction (scalar EKF); k_us at its slips
% 4 inverse EKF: variant 1 unchanged up to the four per tire v_y (corrected Fy split at its own previous slip, brush
%             inverse per tire, z_i = Vx_c,i tan(delta_i - alpha_i) - x_i r, IMU predict); the equal weight mean and the
%             fixed gain Ts/tau become a Kalman update: P += Q in the predict, each tire a measurement with
%             R_i = (dz/dalpha * sigma_F,i / (dF/dalpha))^2, dF/dalpha = Ca_i c_i sec^2(alpha_i) (closed form, c_i the
%             conditioning), sigma_F,i = sigA + sigR |Fy_i| (the Fy correction prior); a tire at its peak (c = 0) is skipped
% references: measured k_us (localization slips, steering offset removed), the MPC's k_us as run (debug_understeer)
% the MPC topics come from the comp2 bag: merge_rosbag2_folder_to_csv_v3.py --topics-file mpc_command_topics.yaml

setenv("VM_NO_PLOTS", "1");
run("vehicle_model.m");          % clears the workspace, then computes every package output on dataFile
setenv("VM_NO_PLOTS", "");

%% settings

mpcCsv  = "/home/elijah/PurdueRacing/bags/lagoona/comp2/mpc_command/2026-09-03_121638_merged.csv";
fwdQ    = 0.2;      % (m/s^2) forward model process noise on dv_y/dt (sweep 0.05 to 10: 0.05 to 0.2 best, k_us insensitive)
fwdR    = 0.5;      % (m/s^2) accelerometer a_y noise
ikfQ    = 0.5;      % (m/s^2) inverse EKF process noise: IMU a_y error in the v_y integration
                    % 2026-10-05 comp2: Q 0.2 to 100 all give v_y 0.205 to 0.209 m/s (variant 1 0.190); equal R per tire
                    % instead of the slope based R gives 0.190 to 0.198 (= variant 1, a fixed gain); sigma_F from the axle
                    % force instead of the tire force 0.215: the slope based R distrusts the inverse too much in the corners
nearLim = 12;       % (m/s^2) |vx r| above this is the near limit subset
turnR   = 30;       % (m) samples within this of a corner point belong to the corner

%% MPC lateral command and the k_us it used, on the vehicle_model.m samples

M    = readtable(mpcCsv);
tAbs = data.time_s;
rDes = interp1(M.time_s, M.mpc_desired_yawrate, tAbs, "linear", NaN);
kMpc = interp1(M.time_s, M.mpc_k_ug, tAbs, "previous", NaN);

vMpc = filter(0.3, [1 -0.7], data.odom_vx_mps);       % fbl_mpc curr_vel_cb: v = 0.7 v + 0.3 odom vx
aCmd = rDes .* max(vMpc, 8);                          % desired_yawrate = a_lat command / max(v, 8)
cmdOk = isfinite(aCmd);
aOp  = aCmd;  aOp(~cmdOk) = Fvx(~cmdOk) .* Fwz(~cmdOk);   % command where available, else measured vx r

%% 2 command: k_us at the commanded a_lat (observer and loads unchanged)
% steady state axle forces Fyf = m a lr / L, Fyr = m a lf / L; one axle slip alpha gives the force at both tires'
% observed loads, F(alpha, Fz_L) + F(alpha, Fz_R) = Fy_axle (bisection); C_axle = Fy_axle / tan(alpha)

FyCmd  = [m .* aOp .* lr ./ L, m .* aOp .* lf ./ L];
aCmdAx = nan(numel(t), 2);  CCmd = nan(numel(t), 2);
for ax = 1:2
    iL = 2*ax - 1;  iR = 2*ax;
    [aCmdAx(:,ax), CCmd(:,ax)] = axleSlipAt(FyCmd(:,ax), FzT(:,iL), FzT(:,iR), muB(ax), CaB(ax), obs.Fz0(ax), obs.pCa(ax), smallA);
end
kusOkC = obsOkD & abs(aOp) > obs.kAyMin;
k_us_cmd = kusFn(CCmd);  k_us_cmd(~kusOkC) = obs.kusStatic;

%% 3 forward: forward model observer, measured steering and yaw rate in, accelerometer a_y as the correction

FxT = [Fx_fl, Fx_fr, Fx_rl, Fx_rr];
gB  = g .* cos(pitch) .* sin(roll);                   % bank: the tires also hold this, a_kin = F/m - gB
fwd = struct("lf", lf, "lr", lr, "ft", ft, "rt", rt, "m", m, "mu", muB, "Ca", CaB, "Fz0", obs.Fz0, "pCa", obs.pCa, ...
             "Q", (fwdQ * Ts)^2, "R", fwdR^2);
[vy_fwd, Fy_fwd] = forwardObserver(Fvx, Fwz, Fay, gB, dW, FzT, FxT, Ts, obsOkD, fwd);
[VxF, VyF] = tireKin(Vx, vy_fwd, Fwz, dW, lf, lr, ft, rt);
alpha_fwd = -atan2(VyF, VxF);  alpha_fwd(~obsOkD,:) = NaN;
k_us_fwd = kusFn(dualStiffness(alpha_fwd, FzT, muB, CaB, obs.Fz0, obs.pCa, smallA));  k_us_fwd(~kusOkD) = obs.kusStatic;

% axle force of the forward model (vehicle frame front) against the force balance
FyFwdAx = [Fy_fwd(:,1) .* cos(dW(:,1)) + Fy_fwd(:,2) .* cos(dW(:,2)), Fy_fwd(:,3) + Fy_fwd(:,4)];
FyBalAx = [Fyf .* cos(delta) + Fxf .* sin(delta), Fyr];

%% 1 inverse: the package's observer, from vehicle_model.m

vy_dual_inv = vy_dual_obs;  alpha_inv = alpha_obs;  alpha_inv_ax = alpha_obs_ax;  k_us_inv = k_us_dual;

%% 4 inverse EKF: the variant 1 chain, Kalman blend and gain

ikf = struct("lf", lf, "lr", lr, "ft", ft, "rt", rt, "xArm", [lf lf -lr -lr], "mu", muB, "Ca", CaB, "Fz0", obs.Fz0, ...
             "pCa", obs.pCa, "sigA", obs.sigA, "sigR", obs.sigR, "Q", (ikfQ * Ts)^2, "tau", 0.2, "kalman", true);
[vy_ikf, Fy_ikf, ikfGain, ikfUsed, ikfP] = inverseKalman(Fyf, Fyr, FzT, Vx, Fvx, Fwz, Fay, dW, Ts, obsOkD, ikf);
[VxI, VyI] = tireKin(Vx, vy_ikf, Fwz, dW, lf, lr, ft, rt);
alpha_ikf = -atan2(VyI, VxI);  alpha_ikf(~obsOkD,:) = NaN;
k_us_ikf = kusFn(dualStiffness(alpha_ikf, FzT, muB, CaB, obs.Fz0, obs.pCa, smallA));  k_us_ikf(~kusOkD) = obs.kusStatic;
aAx_ikf = [mean(alpha_ikf(:,1:2), 2), mean(alpha_ikf(:,3:4), 2)];

% check: the same function with the Kalman part off (fixed gain Ts/tau, equal weights) must reproduce variant 1
ikfFix = ikf;  ikfFix.kalman = false;
vy_fix = inverseKalman(Fyf, Fyr, FzT, Vx, Fvx, Fwz, Fay, dW, Ts, obsOkD, ikfFix);
fprintf("\ncheck: inverse EKF code with the Kalman part off vs variant 1, max |v_y diff| %.2e m/s\n", max(abs(vy_fix - vy_dual_inv), [], "omitnan"));

%% scores

lapWin = fastestLap(t, px, py, Fvx, lapRef);
lap    = t >= lapWin(1) & t <= lapWin(2);
near   = obsOkD & abs(Fvx .* Fwz) > nearLim;
kMask  = isfinite(k_us_meas);                         % measured k_us valid (both models' dynamic gate)

aAx_cur = alpha_inv_ax;
aAx_fwd = [mean(alpha_fwd(:,1:2), 2), mean(alpha_fwd(:,3:4), 2)];
aAx_ref = [alpha_f, alpha_r];

r2d = 180 / pi;
rmsM = @(x, msk) sqrt(mean(x(msk).^2, "omitnan"));
kErr = @(k, msk) median(abs(k(msk) - k_us_meas(msk)), "omitnan");
kJit = @(k, msk) median(abs(diff(k(msk))), "omitnan");
kOver = @(k, msk) 100 * mean(k(msk) > 0.0012);

fprintf("\nMPC command available on %.1f %% of the observer samples; a_cmd vs vx r: rms %.2f m/s^2\n", ...
    100 * mean(cmdOk(obsOkD)), rmsM(aCmd - Fvx .* Fwz, obsOkD & cmdOk));

fprintf("\n%-34s %10s %10s %10s\n", "v_y rms vs localization (m/s)", "all", "|vx r|>12", "lap");
fprintf("%-34s %10.3f %10.3f %10.3f\n", "1 inverse (package, IMU predict)", rmsM(vy_dual_inv - Fvy, obsOkD), rmsM(vy_dual_inv - Fvy, near), rmsM(vy_dual_inv - Fvy, obsOkD & lap));
fprintf("%-34s %10.3f %10.3f %10.3f\n", "3 forward (steering in, a_y corr.)", rmsM(vy_fwd - Fvy, obsOkD), rmsM(vy_fwd - Fvy, near), rmsM(vy_fwd - Fvy, obsOkD & lap));
fprintf("%-34s %10.3f %10.3f %10.3f\n", "4 inverse EKF", rmsM(vy_ikf - Fvy, obsOkD), rmsM(vy_ikf - Fvy, near), rmsM(vy_ikf - Fvy, obsOkD & lap));

fprintf("\n%-34s %8s %8s %8s %8s  (all | |vx r|>12)\n", "slip rms vs localization (deg)", "FL", "FR", "RL", "RR");
fprintf("%-34s %s| %s\n", "1 inverse", sprintf("%8.2f ", r2d * rms(alpha_inv(obsOkD,:) - alphaKin(obsOkD,:), "omitnan")), sprintf("%5.2f ", r2d * rms(alpha_inv(near,:) - alphaKin(near,:), "omitnan")));
fprintf("%-34s %s| %s\n", "3 forward", sprintf("%8.2f ", r2d * rms(alpha_fwd(obsOkD,:) - alphaKin(obsOkD,:), "omitnan")), sprintf("%5.2f ", r2d * rms(alpha_fwd(near,:) - alphaKin(near,:), "omitnan")));
fprintf("%-34s %s| %s\n", "4 inverse EKF", sprintf("%8.2f ", r2d * rms(alpha_ikf(obsOkD,:) - alphaKin(obsOkD,:), "omitnan")), sprintf("%5.2f ", r2d * rms(alpha_ikf(near,:) - alphaKin(near,:), "omitnan")));
fprintf("%-34s front %.2f, rear %.2f deg (commanded steady state slip vs the localization axle slip)\n", "2 command, axle slip", ...
    r2d * rmsM(aCmdAx(:,1) - aAx_ref(:,1), obsOkD & cmdOk), r2d * rmsM(aCmdAx(:,2) - aAx_ref(:,2), obsOkD & cmdOk));

fprintf("\nF_y: forward model axle force vs the force balance, rms front %.0f N, rear %.0f N; per tire vs the corrected split %s N\n", ...
    rmsM(FyFwdAx(:,1) - FyBalAx(:,1), obsOkD), rmsM(FyFwdAx(:,2) - FyBalAx(:,2), obsOkD), ...
    sprintf("%.0f ", sqrt(mean((Fy_fwd(obsOkD,:) - Fy_tm(obsOkD,:)).^2, "omitnan"))));
fprintf("inverse EKF: tires used per sample (c > 0) %.2f on average, all four at the peak %.2f %% of the observer samples;\n", ...
    mean(ikfUsed(obsOkD)), 100 * mean(ikfUsed(obsOkD) == 0));
fprintf("             equivalent time constant Ts/K median %.3f s (variant 1: 0.2 s fixed), |vx r| > 12: %.3f s; sqrt(P) median %.3f m/s\n", ...
    median(Ts ./ ikfGain(obsOkD), "omitnan"), median(Ts ./ ikfGain(near), "omitnan"), median(sqrt(ikfP(obsOkD)), "omitnan"));

K = {"measured (reference)", k_us_meas; "MPC as run (static loads, clamp)", kMpc; "1 inverse (package observer)", k_us_inv; ...
     "2 command a_lat", k_us_cmd; "3 forward model", k_us_fwd; "4 inverse EKF", k_us_ikf};
fprintf("\n%-34s %9s %9s %9s %9s %9s %9s\n", "k_us (where measured is valid)", "median", "|err|", "|err|>12", "|err| lap", "jitter", "% >0.0012");
for i = 1:size(K, 1)
    k = K{i,2};
    fprintf("%-34s %9.5f %9.5f %9.5f %9.5f %9.1e %9.1f\n", K{i,1}, median(k(kMask), "omitnan"), kErr(k, kMask), kErr(k, kMask & near), ...
        kErr(k, kMask & lap), kJit(k, kMask), kOver(k, kMask));
end
fprintf("%-34s %s\n", "fallback used (all observer samples)", sprintf("inverse %.1f %%, command %.1f %%, forward %.1f %%", ...
    100 * mean(~kusOkD(obsOkD)), 100 * mean(~kusOkC(obsOkD)), 100 * mean(~kusOkD(obsOkD))));

% per corner medians (all laps, measured k_us valid, within turnR of the corner point)
kCorner = nan(numel(turnNames), size(K, 1));
for c = 1:numel(turnNames)
    inC = kMask & hypot(px - turnXY(c,1), py - turnXY(c,2)) < turnR;
    for i = 1:size(K, 1), kCorner(c,i) = median(K{i,2}(inC), "omitnan"); end
end
fprintf("\nk_us median per corner: %s\n", strjoin(string(K(:,1))', " | "));
for c = 1:numel(turnNames)
    fprintf("%-4s %s\n", turnNames(c), sprintf("%9.5f ", kCorner(c,:)));
end

%% plots, one window, one tab per plot

cRef = [0.60 0.20 0.60];   % purple, measured / localization (reference)
cMpc = [0.85 0.10 0.10];   % red, MPC as run
cCur = [1 1 1];            % white, 1 inverse (package)
cCmd = [0.85 0.33 0.10];   % orange, 2 command
cFwd = [0.30 0.75 0.93];   % cyan, 3 forward
cIkf = [0.47 0.67 0.19];   % green, 4 inverse EKF
cRaw = [0.75 0.75 0.75];   % grey, corner marks
kCol = [cRef; cMpc; cCur; cCmd; cFwd; cIkf];
tireN  = ["FL", "FR", "RL", "RR"];
axName = ["Front", "Rear"];

tLap  = t(lap) - lapWin(1);
tTurn = zeros(numel(turnNames), 1);
for c = 1:numel(turnNames)
    [~, j] = min(hypot(px(lap) - turnXY(c,1), py(lap) - turnXY(c,2)));
    tTurn(c) = tLap(j);
end

fig = figure("Name", "Observer variants", "Position", [50 50 1600 1100]);
tg  = uitabgroup(fig);

% tab: k_us on the fastest lap
tl = newTab(tg, "k_us", 3, 1);
axK = gobjects(3, 1);
axK(1) = nexttile(tl);
hold on
for i = 1:size(K, 1)
    plot(tLap, K{i,2}(lap), "-", "Color", kCol(i,:), "LineWidth", 1 + 0.5 * (i == 1));
end
yline(0.0012, "--", "Color", cRaw, "HandleVisibility", "off");
grid on
ylim([-0.001 0.004]);
ylabel("k_{us} [rad/(m/s^2)]");
title("Understeer gradient (fallback where not valid; measured only where |v_x r| > 4)");
legend(string(K(:,1)), "Location", "eastoutside");
axK(2) = nexttile(tl);
hold on
plot(tLap, aCmd(lap), "-", "Color", cCmd);
plot(tLap, Fvx(lap) .* Fwz(lap), "-", "Color", cRef);
grid on
ylabel("a_{lat} [m/s^2]");
title("Lateral acceleration: MPC command and measured v_x r");
legend("MPC command", "measured v_x r", "Location", "eastoutside");
axK(3) = nexttile(tl);
hold on
plot(tLap, K{3,2}(lap) - K{1,2}(lap), "-", "Color", cCur);
plot(tLap, K{4,2}(lap) - K{1,2}(lap), "-", "Color", cCmd);
plot(tLap, K{5,2}(lap) - K{1,2}(lap), "-", "Color", cFwd);
plot(tLap, K{6,2}(lap) - K{1,2}(lap), "-", "Color", cIkf);
plot(tLap, K{2,2}(lap) - K{1,2}(lap), "-", "Color", cMpc);
grid on
ylim([-0.002 0.002]);
ylabel("k_{us} - measured");
title("Error against the measured k_{us}");
legend("1 inverse", "2 command", "3 forward", "4 inverse EKF", "MPC as run", "Location", "eastoutside");
for k = 1:3, xline(axK(k), tTurn, ":", "Color", cRaw, "HandleVisibility", "off"); end
xline(axK(1), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xlabel(tl, "time in lap [s]");
linkaxes(axK, "x");
xlim(axK(1), [0 diff(lapWin)]);

% tab: k_us by corner
tl = newTab(tg, "k_us by corner", 1, 1);
nexttile(tl);
b = bar(categorical(turnNames, turnNames), kCorner, "grouped");
for i = 1:numel(b), b(i).FaceColor = kCol(i,:); end
yline(0.0012, "--", "Color", cRaw, "HandleVisibility", "off");
grid on
ylabel("median k_{us} [rad/(m/s^2)]");
title(sprintf("Understeer gradient per corner, all laps, within %d m of the corner point", turnR));
legend(string(K(:,1)), "Location", "northwest");

% tab: v_y and slips on the fastest lap
tl = newTab(tg, "v_y and slips", 4, 1);
axV = gobjects(4, 1);
axV(1) = nexttile(tl);
hold on
plot(tLap, Fvy(lap), "-", "Color", cRef, "LineWidth", 1.5);
plot(tLap, vy_dual_inv(lap), "-", "Color", cCur);
plot(tLap, vy_fwd(lap), "-", "Color", cFwd);
plot(tLap, vy_ikf(lap), "-", "Color", cIkf);
grid on
ylabel("v_y [m/s]");
title(sprintf("Lateral velocity: rms vs localization, inverse %.3f, forward %.3f, inverse EKF %.3f m/s (lap)", ...
    rmsM(vy_dual_inv - Fvy, obsOkD & lap), rmsM(vy_fwd - Fvy, obsOkD & lap), rmsM(vy_ikf - Fvy, obsOkD & lap)));
legend("localization (reference)", "1 inverse", "3 forward", "4 inverse EKF", "Location", "eastoutside");
for ax = 1:2
    axV(1 + ax) = nexttile(tl);
    hold on
    plot(tLap, r2d * aAx_ref(lap,ax), "-", "Color", cRef, "LineWidth", 1.5);
    plot(tLap, r2d * aAx_cur(lap,ax), "-", "Color", cCur);
    plot(tLap, r2d * aAx_fwd(lap,ax), "-", "Color", cFwd);
    plot(tLap, r2d * aAx_ikf(lap,ax), "-", "Color", cIkf);
    plot(tLap, r2d * aCmdAx(lap,ax), "-", "Color", cCmd);
    grid on
    ylabel("\alpha [deg]");
    title(sprintf("%s axle slip", axName(ax)));
    legend("localization (reference)", "1 inverse", "3 forward", "4 inverse EKF", "2 commanded steady state", "Location", "eastoutside");
end
axV(4) = nexttile(tl);
hold on
plot(tLap, r2d * alphaKin(lap,1), "-", "Color", cRef, "LineWidth", 1.5);
plot(tLap, r2d * alpha_inv(lap,1), "-", "Color", cCur);
plot(tLap, r2d * alpha_fwd(lap,1), "-", "Color", cFwd);
plot(tLap, r2d * alpha_ikf(lap,1), "-", "Color", cIkf);
grid on
ylabel("\alpha [deg]");
title("Front left tire slip");
legend("localization (reference)", "1 inverse", "3 forward", "4 inverse EKF", "Location", "eastoutside");
for k = 1:4, xline(axV(k), tTurn, ":", "Color", cRaw, "HandleVisibility", "off"); end
xline(axV(1), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xlabel(tl, "time in lap [s]");
linkaxes(axV, "x");
xlim(axV(1), [0 diff(lapWin)]);

% tab: F_y on the fastest lap
tl = newTab(tg, "F_y", 3, 2);
axF = gobjects(6, 1);
for ax = 1:2
    axF(ax) = nexttile(tl, ax);
    hold on
    plot(tLap, FyBalAx(lap,ax), "-", "Color", cRef, "LineWidth", 1.5);
    plot(tLap, FyFwdAx(lap,ax), "-", "Color", cFwd);
    grid on
    ylabel("F_y [N]");
    title(sprintf("%s axle lateral force (vehicle frame)", axName(ax)));
    legend("force balance", "3 forward model", "Location", "best");
end
for i = 1:4
    axF(2 + i) = nexttile(tl, 2 + i);
    hold on
    plot(tLap, Fy_tm(lap,i), "-", "Color", cCur);
    plot(tLap, Fy_fwd(lap,i), "-", "Color", cFwd);
    grid on
    ylabel("F_y [N]");
    title(sprintf("%s tire lateral force", tireN(i)));
    legend("corrected split (output)", "3 forward (brush at its slip)", "Location", "best");
end
for k = 1:6, xline(axF(k), tTurn, ":", "Color", cRaw, "HandleVisibility", "off"); end
xlabel(tl, "time in lap [s]");
linkaxes(axF, "x");
xlim(axF(1), [0 diff(lapWin)]);


% tab: inverse EKF internals on the fastest lap
tl = newTab(tg, "inverse EKF", 3, 1);
axI = gobjects(3, 1);
axI(1) = nexttile(tl);
semilogy(tLap, Ts ./ ikfGain(lap), "-", "Color", cIkf);
hold on
yline(0.2, "--", "Color", cCur, "HandleVisibility", "off");
grid on
ylim([0.01 10]);
ylabel("T_s / K [s]");
title("Equivalent time constant of the Kalman correction (dashed: the fixed 0.2 s of variant 1)");
axI(2) = nexttile(tl);
stairs(tLap, ikfUsed(lap), "-", "Color", cIkf);
grid on
ylim([-0.2 4.2]);
ylabel("tires");
title("Tires used as measurements (conditioning c > 0)");
axI(3) = nexttile(tl);
plot(tLap, sqrt(ikfP(lap)), "-", "Color", cIkf);
grid on
ylabel("\surd P [m/s]");
title("v_y uncertainty of the inverse EKF");
for k = 1:3, xline(axI(k), tTurn, ":", "Color", cRaw, "HandleVisibility", "off"); end
xline(axI(1), tTurn, ":", turnNames, "Color", cRaw, "LabelOrientation", "horizontal", "FontSize", 8, "HandleVisibility", "off");
xlabel(tl, "time in lap [s]");
linkaxes(axI, "x");
xlim(axI(1), [0 diff(lapWin)]);

function [vy, Fy, gain, nUsed, Pk] = inverseKalman(Fyf, Fyr, FzT, Vx, vx, r, ay, dW, Ts, ok, p)
% variant 1's dual track observer (vehicle_model.m dualTrackObserver) with a Kalman blend and gain:
% same Fy split at its own previous slip, brush inverse per tire, per tire v_y z_i and IMU predict; then P += Q and
% one scalar update per tire, R_i = (|Vx_c,i| sec^2(delta_i - alpha_i) sigma_F,i / (Ca_i c_i sec^2(alpha_i)))^2,
% a tire with c_i = 0 (at or past its peak) is skipped; p.kalman false: the original equal weight mean, gain Ts/tau

    n  = numel(vx);
    vy = nan(n, 1);  Fy = zeros(n, 4);  gain = nan(n, 1);  nUsed = zeros(n, 1);  Pk = nan(n, 1);
    vyk = 0;  P = 1;  aPrev = zeros(1, 4);
    ax = [1 1 2 2];
    for k = 2:n
        if ~ok(k), vyk = 0; P = 1; aPrev = zeros(1, 4); continue, end
        CaK = brushCa(FzT(k,:), p.Ca(ax) / 2, p.Fz0(ax), p.pCa(ax));
        F0 = zeros(1, 4);
        for i = 1:4, F0(i) = brushFy(aPrev(i), FzT(k,i), p.mu(ax(i)), CaK(i)); end
        [Fy(k,1), Fy(k,2)] = axleCorrect(Fyf(k), F0(1), F0(2), p.sigA, p.sigR);
        [Fy(k,3), Fy(k,4)] = axleCorrect(Fyr(k), F0(3), F0(4), p.sigA, p.sigR);
        VxC = [vx(k) - r(k) * p.ft / 2, vx(k) + r(k) * p.ft / 2, vx(k) - r(k) * p.rt / 2, vx(k) + r(k) * p.rt / 2];
        z = nan(1, 4);  R = inf(1, 4);
        for i = 1:4
            [ai, ci] = brushInv(Fy(k,i), FzT(k,i), p.mu(ax(i)), CaK(i));
            z(i) = VxC(i) * tan(dW(k,i) - ai) - p.xArm(i) * r(k);
            if ci > 0
                sigF = p.sigA + p.sigR * abs(Fy(k,i));
                R(i) = (abs(VxC(i)) * sec(dW(k,i) - ai)^2 * sigF / (CaK(i) * ci * sec(ai)^2))^2;
            end
        end
        % predict with the IMU
        vyk = vyk + (ay(k) - vx(k) * r(k)) * Ts;
        if p.kalman
            P  = P + p.Q;
            P0 = P;
            for i = find(isfinite(z) & isfinite(R))
                Kg  = P / (P + R(i));
                vyk = vyk + Kg * (z(i) - vyk);
                P   = (1 - Kg) * P;
            end
            gain(k)  = 1 - P / P0;
            nUsed(k) = sum(isfinite(z) & isfinite(R));
            Pk(k)    = P;
        else
            vT = mean(z(isfinite(z)));
            if isfinite(vT), vyk = vyk + (Ts / p.tau) * (vT - vyk); end
            gain(k) = Ts / p.tau;
        end
        vy(k) = vyk;
        [vxt, vyt] = tireKin(Vx(k), vyk, r(k), dW(k,:), p.lf, p.lr, p.ft, p.rt);
        aPrev = -atan2(vyt, vxt);  aPrev(~isfinite(aPrev)) = 0;
    end
end

function [vy, Fy] = forwardObserver(vx, r, ay, gB, dW, FzT, FxT, Ts, ok, p)
% forward model v_y observer (scalar EKF): predict v_y with the per tire brush driven by the measured steering and yaw
% rate, correct with the accelerometer; h(v_y) = lateral tire force / m - bank term, dv_y/dt = h - vx r
% the gain falls to 0 where dF/dalpha -> 0 (tire peak), there the steering driven prediction carries v_y

    n  = numel(vx);
    vy = nan(n, 1);  Fy = nan(n, 4);
    vyk = 0;  P = 1;
    ax = [1 1 2 2];
    for k = 2:n
        if ~ok(k), vyk = 0; P = 1; continue, end
        Ca = brushCa(FzT(k,:), p.Ca(ax) / 2, p.Fz0(ax), p.pCa(ax));
        h  = @(v) lateralForce(vx(k), v, r(k), dW(k,:), FzT(k,:), FxT(k,:), Ca, p) / p.m - gB(k);
        dh = @(v) (h(v + 1e-3) - h(v - 1e-3)) / 2e-3;
        % predict
        vyk = vyk + (h(vyk) - vx(k) * r(k)) * Ts;
        F   = 1 + dh(vyk) * Ts;
        P   = F * P * F + p.Q;
        % correct with the accelerometer
        H   = dh(vyk);
        Kg  = P * H / (H * P * H + p.R);
        vyk = vyk + Kg * (ay(k) - h(vyk));
        P   = (1 - Kg * H) * P;
        vy(k) = vyk;
        [~, Fy(k,:)] = lateralForce(vx(k), vyk, r(k), dW(k,:), FzT(k,:), FxT(k,:), Ca, p);
    end
end


function [Fsum, Fy] = lateralForce(vx, vy, r, dW, Fz, Fx, Ca, p)
% per tire brush force at the tire's kinematic slip, summed in the vehicle frame (Fy cos delta + Fx sin delta)

    [vxt, vyt] = tireKin(vx, vy, r, dW, p.lf, p.lr, p.ft, p.rt);
    a  = -atan2(vyt, vxt);
    mu = p.mu([1 1 2 2]);
    Fy = zeros(1, 4);
    for i = 1:4, Fy(i) = brushFy(a(i), Fz(i), mu(i), Ca(i)); end
    Fsum = sum(Fy .* cos(dW) + Fx .* sin(dW));
end


function [alpha, C] = axleSlipAt(FyAx, FzL, FzR, mu, CaAxle, Fz0, pCa, smallA)
% axle slip alpha with brush(alpha, Fz_L) + brush(alpha, Fz_R) = FyAx (both tires, observed loads), bisection;
% past the axle's peak the slip of the later saturating tire; C = |FyAx| / tan(alpha)

    CaL = brushCa(FzL, CaAxle / 2, Fz0, pCa);  CaR = brushCa(FzR, CaAxle / 2, Fz0, pCa);
    tthMax = max(3 .* mu .* max(FzL, 100) ./ CaL, 3 .* mu .* max(FzR, 100) ./ CaR);
    target = abs(FyAx);
    lo = zeros(size(FyAx));  hi = atan(tthMax);
    for it = 1:50
        mid = 0.5 * (lo + hi);
        F   = abs(brushFy(mid, FzL, mu, CaL)) + abs(brushFy(mid, FzR, mu, CaR));
        low = F < target;
        lo(low) = mid(low);  hi(~low) = mid(~low);
    end
    alpha = sign(FyAx) .* 0.5 .* (lo + hi);
    a1 = max(abs(alpha), smallA);
    C  = (abs(brushFy(a1, FzL, mu, CaL)) + abs(brushFy(a1, FzR, mu, CaR))) ./ tan(a1);
    alpha(~isfinite(FyAx)) = NaN;  C(~isfinite(FyAx)) = NaN;
end


function C = dualStiffness(alpha, FzT, mu, CaB, Fz0, pCa, smallA)
% dual track secant axle stiffness, as vehicle_model.m: C_axle = (|brush(alpha_L)| + |brush(alpha_R)|) / tan(|mean slip|)

    C = zeros(size(alpha, 1), 2);
    for ax = 1:2
        Fs = zeros(size(alpha, 1), 1);
        for i = 2*ax-1:2*ax
            Fs = Fs + abs(brushFy(max(abs(alpha(:,i)), smallA), FzT(:,i), mu(ax), brushCa(FzT(:,i), CaB(ax) / 2, Fz0(ax), pCa(ax))));
        end
        C(:,ax) = Fs ./ tan(max(abs(mean(alpha(:,2*ax-1:2*ax), 2)), smallA));
    end
end


% ---- copies of the vehicle_model.m functions (same code) ----

function [VxT, VyT] = tireKin(vx, vy, r, dW, lf, lr, ft, rt)
    VxC = [vx - r .* (ft/2), vx + r .* (ft/2), vx - r .* (rt/2), vx + r .* (rt/2)];
    VyC = [vy + r .* lf, vy + r .* lf, vy - r .* lr, vy - r .* lr];
    VxT =  VxC .* cos(dW) + VyC .* sin(dW);
    VyT = -VxC .* sin(dW) + VyC .* cos(dW);
end


function Fy = brushTireForce(slip_angle, Fz, mu, Ca)
    Fz       = max(100.0, Fz);
    Fy_max   = mu .* Fz;
    alpha    = tan(slip_angle);
    a_thresh = 3.0 .* Fy_max ./ Ca;
    term1 = -Ca .* alpha;
    term2 = (Ca .* Ca) ./ (3.0 .* mu .* Fz) .* abs(alpha) .* alpha;
    term3 = -(Ca .* Ca .* Ca) ./ (27.0 .* mu .* mu .* Fz .* Fz) .* alpha .* alpha .* alpha;
    Fy    = term1 + term2 + term3;
    sat     = abs(alpha) > a_thresh;
    sgn     = 2 .* (slip_angle >= 0.0) - 1;
    Fy_sat  = -Fy_max .* sgn;
    Fy(sat) = Fy_sat(sat);
end


function Ca = brushCa(Fz, Ca0, Fz0, p)
    Ca = Ca0 .* (max(Fz, 100) ./ Fz0) .^ p;
end


function Fy = brushFy(alpha, Fz, mu, Ca)
    Fy = brushTireForce(-alpha, Fz, mu, Ca);
end


function [alpha, cn] = brushInv(Fy, Fz, mu, Ca)
    Fz = max(Fz, 100);
    Fm = mu .* Fz;
    tth = 3 .* Fm ./ Ca;
    u  = abs(Fy) ./ Fm;
    us = min(u, 1);
    alpha = sign(Fy) .* atan(tth .* (1 - (1 - us).^(1/3)));
    cn = (1 - us).^(2/3);
    cn(u >= 1 | ~isfinite(cn)) = 0;
end


function [fL, fR] = axleCorrect(S, fL, fR, sigA, sigR)
    PL = (sigA + sigR .* abs(fL)).^2;
    PR = (sigA + sigR .* abs(fR)).^2;
    r  = S - (fL + fR);
    fL = fL + r .* PL ./ (PL + PR);
    fR = fR + r .* PR ./ (PL + PR);
end


function win = fastestLap(t, px, py, v, ref)
    near = hypot(px - ref(1), py - ref(2)) < 20 & v > 5;
    tp   = t(diff([0; near]) == 1);
    tp   = tp([true; diff(tp) > 40]);
    [~, j] = min(diff(tp));
    win  = [tp(j), tp(j+1)];
end


function tl = newTab(tg, name, rows, cols)
    tab = uitab(tg, "Title", name);
    tl  = tiledlayout(tab, rows, cols, "TileSpacing", "compact");
end
