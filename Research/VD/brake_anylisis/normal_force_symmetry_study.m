clc
close all
clear
% NORMAL FORCE SYMMETRY STUDY
%
% Question this answers: for the same |a_x|, does the strain gage report the
% same load transfer under acceleration as under braking? The pure-longitudinal
% model has no way to tell the two apart - it transfers m*a_x*h/L either way -
% so if the gages disagree between the two branches, the model cannot be right
% for both, and every mu built on it inherits the error with opposite sign on
% the two branches.
%
% Method, and why it is built this way:
%
%   1. Gate to pure longitudinal. |a_y| and steering small, so the lateral
%      transfer term is not smuggled into the longitudinal one.
%
%   2. Work inside NARROW speed bands and reference every bin to that band's
%      own near-zero-a_x datum. Aero load is a function of speed only, so
%      inside a band it is a constant that the subtraction removes. This
%      matters more than it looks: you brake from high speed and accelerate
%      from low speed, so a_x and v_x are correlated, and any study that pools
%      speeds hands the aero term straight to the accel/brake comparison.
%      The sweep at the bottom shows the result is flat in ClA because of this.
%
%   3. Report the transfer as the HALF-DIFFERENCE (rear - front)/2 as well as
%      per axle. The half-difference is what the model actually predicts
%      (m*a_x*h/L) and it cancels anything that loads both axles together -
%      heave, aero, a common gage drift.
%
%   4. Use the LEVELED longitudinal acceleration (oms_acc_x_hor_mps2), not the
%      body-frame one. See the a_x section below.
%
% Companion to notmal_force_estimation.m; the vehicle parameters and the
% filtering are kept identical so the numbers are directly comparable.

%% opening csv

data = readtable("/home/elijah/PurdueRacing/bags/lagoona/control_test/JULY_28_HardBraking_feedbackcontroller/csv_output/2026-07-28_130732_merged.csv");

mm = 20;

%% params (same as notmal_force_estimation.m)

vehicleParams.wheelbase = 2.9718;
vehicleParams.w_dist_f  = 0.42;
vehicleParams.cg_z      = 0.275;
vehicleParams.m         = 815;
vehicleParams.ACd       = 0.58;      % downforce area used by the main script
vehicleParams.aeroBal   = 0.33;      % front share used by the main script

L   = vehicleParams.wheelbase;
a   = vehicleParams.w_dist_f * L;
b   = L - a;
m   = vehicleParams.m;
cgh = vehicleParams.cg_z;
g   = 9.81;
rho = 1.225;

fz_fl_geo = 1679;   fz_fr_geo = 1679;
fz_rl_geo = 2318.6; fz_rr_geo = 2318.6;

% The gradient the model uses on BOTH branches. Everything below is a test of
% whether one number can serve both.
transferGradient_model = m * cgh / L;      % N per m/s^2

%% longitudinal acceleration source
% oms_acc_x_mps2 is body frame: it carries -g*sin(pitch), so on any grade or
% under body pitch it reads something other than the vehicle's longitudinal
% acceleration. oms_acc_x_hor_mps2 is the leveled channel and is the one that
% belongs in a load-transfer study. On this log the two differ by up to
% 0.5 m/s^2 at high |a_x|, which is ~40 N of transfer - small here, but it is
% free to get right, and the main script additionally adds a separate
% m*g*sin(pitch) grade term on top of the body-frame channel, which
% double-counts the same physics.
%
% Set this false to reproduce the main script's choice and see the difference.
use_leveled_ax = true;

if use_leveled_ax
    Fax = movmean(data.oms_acc_x_hor_mps2, mm);
    ax_label = "oms\_acc\_x\_hor\_mps2 (leveled)";
else
    Fax = movmean(data.oms_acc_x_mps2, mm);
    ax_label = "oms\_acc\_x\_mps2 (body frame)";
end

Fay   = movmean(data.a_y, mm);
Fvx   = movmean(data.oms_vel_x_kmh, mm) ./ 3.6;
steer = movmean(data.steer_wheel_ang_deg, mm);
pitch = movmean(data.oms_pitch_deg, mm);

t = data.time_s - data.time_s(1);

Ffz_fl = movmean(data.fl_load_n, mm);
Ffz_fr = movmean(data.fr_load_n, mm);
Ffz_rl = movmean(data.rl_load_n, mm);
Ffz_rr = movmean(data.rr_load_n, mm);

Pf  = movmean(data.front_brake_pressure_kpa, mm);
Pr  = movmean(data.rear_brake_pressure_kpa, mm);
Trq = movmean(data.est_drive_torque_nm, mm);

%% zeroing the gages
% Same convention as the main script: force the reading near the start of the
% recording onto the geometric static load. This only moves the offset, so it
% cannot affect any gradient below, but it puts the absolute levels on the same
% footing as the model.

gage_zero = [Ffz_fl(min(100,height(data))), Ffz_fr(min(100,height(data))), ...
             Ffz_rl(min(100,height(data))), Ffz_rr(min(100,height(data)))];

Fz_fl = Ffz_fl - (gage_zero(1) - fz_fl_geo);
Fz_fr = Ffz_fr - (gage_zero(2) - fz_fr_geo);
Fz_rl = Ffz_rl - (gage_zero(3) - fz_rl_geo);
Fz_rr = Ffz_rr - (gage_zero(4) - fz_rr_geo);

front_axle = Fz_fl + Fz_fr;
rear_axle  = Fz_rl + Fz_rr;
half_diff  = (rear_axle - front_axle) / 2;     % the aero-immune transfer metric

fprintf("gage zero offsets removed [N]: FL %+.0f  FR %+.0f  RL %+.0f  RR %+.0f\n", ...
    gage_zero(1)-fz_fl_geo, gage_zero(2)-fz_fr_geo, ...
    gage_zero(3)-fz_rl_geo, gage_zero(4)-fz_rr_geo);

%% pure-longitudinal gate
% A steady gate as well as a lateral one: |d a_x/dt| large means the suspension
% is still moving to the new attitude, and mixing ramp-in samples with settled
% ones smears the two branches toward each other.

dt_series = gradient(t);
dt_series(dt_series <= 0) = median(dt_series(dt_series > 0));
dax = movmean(gradient(Fax) ./ dt_series, mm);

ay_max_pure   = 1.5;      % m/s^2
steer_max     = 5;        % deg
dax_max       = 3.0;      % m/s^3
vx_min        = 14;       % m/s

pureLong = abs(Fay) < ay_max_pure ...
         & abs(steer) < steer_max ...
         & abs(dax) < dax_max ...
         & abs(pitch) < 15 ...              % drops OMS attitude dropouts
         & Fvx > vx_min ...
         & isfinite(Fax) & isfinite(front_axle) & isfinite(rear_axle);

fprintf("pure-longitudinal gate (|a_y|<%.1f, |steer|<%g deg, |da_x/dt|<%g, v_x>%g): %d of %d samples (%.1f%%)\n", ...
    ay_max_pure, steer_max, dax_max, vx_min, sum(pureLong), height(data), ...
    100*sum(pureLong)/height(data));

%% aero, measured on the samples that have no longitudinal force to confound it
% Fitting downforce on near-zero-a_x samples only keeps the load-transfer term
% out of the aero coefficient. This is reported because the main script's
% ACd = 0.58 turns out to be well short of what the gages see, which biases
% every normalized force at speed - though it does so on BOTH branches, so it
% is not what makes accel and braking disagree.

coast = pureLong & abs(Fax) < 1.0;

Xc = [ones(sum(coast),1), Fvx(coast).^2];
cf = Xc \ front_axle(coast);
cr = Xc \ rear_axle(coast);

k_aero_total = cf(2) + cr(2);

fprintf("\n=== downforce measured on |a_x|<1 samples (n=%d) ===\n", sum(coast));
fprintf("  front  W0 %6.0f N   dFz/d(vx^2) %+.3f N/(m/s)^2\n", cf(1), cf(2));
fprintf("  rear   W0 %6.0f N   dFz/d(vx^2) %+.3f N/(m/s)^2\n", cr(1), cr(2));
fprintf("  total  %.3f N/(m/s)^2 -> ClA %.2f m^2, %.0f%% front\n", ...
    k_aero_total, k_aero_total/(0.5*rho), 100*cf(2)/k_aero_total);
fprintf("  script %.3f N/(m/s)^2 -> ACd %.2f m^2, %.0f%% front\n", ...
    0.5*rho*vehicleParams.ACd, vehicleParams.ACd, 100*vehicleParams.aeroBal);
fprintf("  -> the script carries %.1fx too little downforce (%.0f N vs %.0f N at 40 m/s)\n", ...
    k_aero_total/(0.5*rho*vehicleParams.ACd), k_aero_total*40^2, ...
    0.5*rho*vehicleParams.ACd*40^2);

%% THE STUDY - measured transfer vs model, per speed band, per branch

speed_bands = [18 23; 23 28; 28 33; 33 40];
ax_edges    = -10:1:6;
min_bin     = 120;
min_datum   = 150;

binAx = []; binMeasHalf = []; binMeasF = []; binMeasR = []; binN = []; binVx = []; binBand = [];

fprintf("\n%s\n", repmat('=', 1, 104));
fprintf("MEASURED LOAD TRANSFER vs PURE-LONGITUDINAL MODEL   (a_x from %s)\n", ax_label);
fprintf("dFz is referenced to the |a_x|<0.5 datum of the SAME speed band, so aero cancels.\n");
fprintf("Model: front -%.1f*a_x, rear +%.1f*a_x, half-difference %.1f*a_x  [N]\n", ...
    transferGradient_model, transferGradient_model, transferGradient_model);
fprintf("%s\n", repmat('=', 1, 104));

for iBand = 1:size(speed_bands,1)

    inBand = pureLong & Fvx >= speed_bands(iBand,1) & Fvx < speed_bands(iBand,2);
    datum  = inBand & abs(Fax) < 0.5;

    if sum(datum) < min_datum
        fprintf("\n  v_x %g-%g m/s: datum too small (n=%d), skipped\n", ...
            speed_bands(iBand,1), speed_bands(iBand,2), sum(datum));
        continue
    end

    f0 = mean(front_axle(datum));
    r0 = mean(rear_axle(datum));
    h0 = mean(half_diff(datum));

    fprintf("\n  v_x %g-%g m/s   datum |a_x|<0.5: front %.0f N, rear %.0f N  (n=%d, mean v_x %.1f)\n", ...
        speed_bands(iBand,1), speed_bands(iBand,2), f0, r0, sum(datum), mean(Fvx(datum)));
    fprintf("  %7s %6s %5s | %10s %10s | %9s %7s %6s | %9s\n", ...
        "a_x", "n", "v_x", "dFz front", "dFz rear", "half-dif", "model", "ratio", "implied h");

    for iBin = 1:numel(ax_edges)-1

        sel = inBand & Fax >= ax_edges(iBin) & Fax < ax_edges(iBin+1);

        if sum(sel) < min_bin, continue, end

        axc = mean(Fax(sel));

        if abs(axc) < 0.8, continue, end       % too small to resolve a gradient

        dF   = mean(front_axle(sel)) - f0;
        dR   = mean(rear_axle(sel))  - r0;
        dH   = mean(half_diff(sel))  - h0;
        mdl  = axc * transferGradient_model;
        hImp = dH * L / (m * axc);

        fprintf("  %7.2f %6d %5.1f | %10.0f %10.0f | %9.0f %+7.0f %6.2f | %9.3f\n", ...
            axc, sum(sel), mean(Fvx(sel)), dF, dR, dH, mdl, dH/mdl, hImp);

        binAx(end+1,1)=axc; binMeasHalf(end+1,1)=dH; binMeasF(end+1,1)=dF; %#ok<SAGROW>
        binMeasR(end+1,1)=dR; binN(end+1,1)=sum(sel); binVx(end+1,1)=mean(Fvx(sel)); %#ok<SAGROW>
        binBand(end+1,1)=iBand; %#ok<SAGROW>
    end
end

%% branch summary
% Weighted least squares through the origin on each branch. Through the origin
% because a load transfer with no longitudinal acceleration is not a transfer.

isBrake = binAx < 0;
isAccel = binAx > 0;

grad = @(sel) sum(binN(sel).*binAx(sel).*binMeasHalf(sel)) / sum(binN(sel).*binAx(sel).^2);

grad_brake = grad(isBrake);
grad_accel = grad(isAccel);

fprintf("\n%s\n", repmat('=', 1, 104));
fprintf("BRANCH SUMMARY - the answer to the question\n");
fprintf("%s\n", repmat('=', 1, 104));
fprintf("  model assumes           %6.1f N per m/s^2   (h = %.3f m) on both branches\n", ...
    transferGradient_model, cgh);
fprintf("  measured BRAKING        %6.1f N per m/s^2   ratio %.2fx   implied h = %.3f m   (%d bins)\n", ...
    grad_brake, grad_brake/transferGradient_model, grad_brake*L/m, sum(isBrake));
fprintf("  measured ACCELERATING   %6.1f N per m/s^2   ratio %.2fx   implied h = %.3f m   (%d bins)\n", ...
    grad_accel, grad_accel/transferGradient_model, grad_accel*L/m, sum(isAccel));
fprintf("\n  braking / accelerating asymmetry = %.2fx\n", grad_brake/grad_accel);
fprintf("  For the same |a_x| the gages report %.0f%% MORE transfer braking than accelerating.\n", ...
    100*(grad_brake/grad_accel - 1));
fprintf("  A single cg height cannot reproduce both branches: braking wants %.3f m, accel wants %.3f m.\n", ...
    grad_brake*L/m, grad_accel*L/m);

%% is the asymmetry an artifact of the aero assumption?
% Redo the branch gradients with an explicit aero term removed first, swept
% over a wide range of ClA. Because every bin is referenced to its own band's
% datum the answer barely moves, which is the point: this result does not rest
% on knowing the aero.

fprintf("\n%s\n", repmat('=', 1, 104));
fprintf("SENSITIVITY - does the asymmetry survive any plausible aero assumption?\n");
fprintf("%s\n", repmat('=', 1, 104));
fprintf("  %10s %12s %12s %10s %10s %11s\n", ...
    "ClA [m^2]", "brake grad", "accel grad", "brake h", "accel h", "asymmetry");

aero_front_share = cf(2) / k_aero_total;

for ClA = [0, 0.58, 1.0, k_aero_total/(0.5*rho), 2.0, 3.0]

    % aero contribution to the half-difference: (rear share - front share)/2
    hd = half_diff - (1 - 2*aero_front_share)/2 * 0.5*rho*ClA .* Fvx.^2;

    gb = branchGradient(hd, Fax, Fvx, pureLong, speed_bands, ax_edges, min_bin, min_datum, -1);
    ga = branchGradient(hd, Fax, Fvx, pureLong, speed_bands, ax_edges, min_bin, min_datum, +1);

    fprintf("  %10.2f %12.1f %12.1f %10.3f %10.3f %10.2fx\n", ...
        ClA, gb, ga, gb*L/m, ga*L/m, gb/ga);
end

%% what the asymmetry does to a rear mu
% Direction check, because the sign is what matters for the mu problem: under
% braking the real rear axle sheds MORE than the model says, so the model's
% rear F_z is too high and the rear mu is reported too low. Under acceleration
% the two nearly agree, so the accel side is barely touched. The asymmetry
% therefore pushes the two mu numbers apart exactly the way the main script
% reports them.

fprintf("\n%s\n", repmat('=', 1, 104));
fprintf("EFFECT ON A REAR mu\n");
fprintf("%s\n", repmat('=', 1, 104));

W_r_static = b*m*g/L;

for axTest = [-8 -6 5 3]

    Fz_model    = W_r_static + transferGradient_model*axTest;
    if axTest < 0
        Fz_measured = W_r_static + grad_brake*axTest;
    else
        Fz_measured = W_r_static + grad_accel*axTest;
    end

    fprintf("  a_x %+5.1f: model rear F_z %6.0f N, measured %6.0f N -> model is %+5.1f%%, so mu is reported %+5.1f%%\n", ...
        axTest, Fz_model, Fz_measured, ...
        100*(Fz_model/Fz_measured - 1), 100*(Fz_measured/Fz_model - 1));
end

%% engine braking - mis-SPLIT, not missing
% Not a normal-force result, but it falls out of the same gate and it is the
% largest single asymmetry between the two branches.
%
% Read this carefully, because it is easy to double-count: engine braking is
% ALREADY inside F_x_total, which the main script builds from measured
% deceleration. Nothing is missing from the total. The error is in the SPLIT.
% biasF is a brake-pressure ratio, so it divides the whole of F_x_total 53/47
% as though every newton of it came out of a caliper. Engine braking is a
% 100%-rear force, so the front is wrongly credited with biasF of it.
%
%   under-count on the rear = biasF * F_engine
%
% not the whole of F_engine. The caliper force is F_x_total - F_engine, and it
% is only that part that deserves the pressure split.
%
% Caveat on the magnitude: est_drive_torque_nm is an estimate, and the
% torque-to-force gain is the weak link. A force-balance fit over the no-brake
% samples returned R_eff ~ 0.356 m but was unstable across subsets (0.35-0.49 m)
% and implied a negative rolling resistance, so it is absorbing a bias
% somewhere. The sweep below brackets it.

fprintf("\n%s\n", repmat('=', 1, 104));
fprintf("ENGINE BRAKING - mis-split by biasF (rear axle, braking only)\n");
fprintf("%s\n", repmat('=', 1, 104));

R_r_sweep = [0.31 0.356 0.45];
onBrakes  = pureLong & (Pf + Pr) > 400;

fprintf("  %10s %6s %6s %10s %11s %11s %11s\n", ...
    "a_x band", "n", "biasF", "T_drive", "F_engine", "rear dFx", "rear mu");

for lo = [-9 -7 -5 -3]

    sel = onBrakes & Fax >= lo & Fax < lo+2;

    if sum(sel) < 150, continue, end

    vBar  = mean(Fvx(sel));
    biasF = mean( (Pf(sel)./0.30) ./ ((Pf(sel)./0.30) + (Pr(sel)./0.31)) );
    Fxt   = m*mean(Fax(sel)) + 0.5*rho*1.33*vBar^2;

    for R_r = R_r_sweep

        Fe        = mean(Trq(sel)) / R_r;      % engine braking, 100% rear
        rearScr   = (1 - biasF) * Fxt;                  % what the script assigns
        rearTrue  = (1 - biasF) * (Fxt - Fe) + Fe;      % pressure split on calipers only

        if R_r == R_r_sweep(1)
            band = sprintf("%+.0f..%+.0f", lo, lo+2);
            nStr = sprintf("%d", sum(sel));
            bStr = sprintf("%.3f", biasF);
        else
            band = ""; nStr = ""; bStr = "";
        end

        fprintf("  %10s %6s %6s %10.1f %11.0f %11.0f %+10.1f%%   (R_r %.3f)\n", ...
            band, nStr, bStr, mean(Trq(sel)), Fe, rearTrue - rearScr, ...
            100*(rearTrue/rearScr - 1), R_r);
    end
end

fprintf("\n  'rear dFx' is biasF*F_engine - the force wrongly credited to the front axle.\n");

%% fig N1 - the study, plotted
figure('Name','Fig N1 - Measured vs Model Load Transfer, accel and braking branches');

layoutN1 = tiledlayout(1, 2, "TileSpacing", "compact", "Padding", "compact");

axN1 = nexttile;
hold on
scatter(binAx(isBrake), binMeasHalf(isBrake), 60, [0.75 0.25 0.25], "filled", ...
    "DisplayName", "measured, braking");
scatter(binAx(isAccel), binMeasHalf(isAccel), 60, [0.15 0.40 0.65], "filled", ...
    "DisplayName", "measured, accelerating");

axSpan = linspace(min(binAx), max(binAx), 50);
plot(axSpan, transferGradient_model*axSpan, "k--", "LineWidth", 1.8, ...
    "DisplayName", sprintf("model, h = %.3f m", cgh));
plot(axSpan(axSpan<0), grad_brake*axSpan(axSpan<0), "-", "Color", [0.75 0.25 0.25], ...
    "LineWidth", 2, "DisplayName", sprintf("braking fit, h = %.3f m", grad_brake*L/m));
plot(axSpan(axSpan>0), grad_accel*axSpan(axSpan>0), "-", "Color", [0.15 0.40 0.65], ...
    "LineWidth", 2, "DisplayName", sprintf("accel fit, h = %.3f m", grad_accel*L/m));
hold off
grid on
box on
xline(0, "k:"); yline(0, "k:");
xlabel("a_x [m/s^2]");
ylabel("Load transfer (rear - front)/2  [N]");
title("Transfer vs a_x - one line cannot fit both branches", "FontWeight", "bold");
legend("Location", "northwest");
set(axN1, "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);

axN2 = nexttile;
hold on
plot(abs(binAx(isBrake)), abs(binMeasHalf(isBrake))./(abs(binAx(isBrake))*transferGradient_model), ...
    "o", "MarkerSize", 9, "MarkerFaceColor", [0.75 0.25 0.25], ...
    "MarkerEdgeColor", "k", "DisplayName", "braking");
plot(abs(binAx(isAccel)), abs(binMeasHalf(isAccel))./(abs(binAx(isAccel))*transferGradient_model), ...
    "s", "MarkerSize", 9, "MarkerFaceColor", [0.15 0.40 0.65], ...
    "MarkerEdgeColor", "k", "DisplayName", "accelerating");
yline(1, "k--", "LineWidth", 1.5, "DisplayName", "model");
hold off
grid on
box on
xlabel("|a_x| [m/s^2]");
ylabel("measured transfer / model transfer  [-]");
title("Same magnitude, two different answers", "FontWeight", "bold");
legend("Location", "best");
set(axN2, "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);

title(layoutN1, sprintf("Normal force symmetry study - braking %.2fx model, accelerating %.2fx model", ...
    grad_brake/transferGradient_model, grad_accel/transferGradient_model), "FontWeight", "bold");

%% fig N2 - per-axle absolute levels, measured against model
figure('Name','Fig N2 - Axle Load vs a_x, measured and model');

layoutN2 = tiledlayout(1, 2, "TileSpacing", "compact", "Padding", "compact");

W_f_static = a*m*g/L;

for iAxle = 1:2

    nexttile
    hold on

    if iAxle == 1
        meas = binMeasF; W0 = W_f_static; sgn = -1; nm = "Front axle";
    else
        meas = binMeasR; W0 = W_r_static; sgn = +1; nm = "Rear axle";
    end

    scatter(binAx(isBrake), W0 + meas(isBrake), 60, [0.75 0.25 0.25], "filled", ...
        "DisplayName", "measured, braking");
    scatter(binAx(isAccel), W0 + meas(isAccel), 60, [0.15 0.40 0.65], "filled", ...
        "DisplayName", "measured, accelerating");
    plot(axSpan, W0 + sgn*transferGradient_model*axSpan, "k--", "LineWidth", 1.8, ...
        "DisplayName", "pure-longitudinal model");

    hold off
    grid on
    box on
    xline(0, "k:");
    xlabel("a_x [m/s^2]");
    ylabel("Axle normal force [N]");
    title(nm, "FontWeight", "bold");
    legend("Location", "best");
    set(gca, "FontSize", 11, "LineWidth", 0.8, "GridAlpha", 0.20);
end

title(layoutN2, "Axle load vs a_x, aero referenced out inside each speed band", ...
    "FontWeight", "bold");


function gr = branchGradient(metric, Fax, Fvx, pureLong, bands, edges, minBin, minDatum, sgn)
% Weighted through-origin gradient of `metric` against a_x on one branch,
% referencing each speed band to its own near-zero-a_x datum.

    num = 0;
    den = 0;

    for iBand = 1:size(bands,1)

        inBand = pureLong & Fvx >= bands(iBand,1) & Fvx < bands(iBand,2);
        datum  = inBand & abs(Fax) < 0.5;

        if sum(datum) < minDatum, continue, end

        h0 = mean(metric(datum));

        for iBin = 1:numel(edges)-1

            sel = inBand & Fax >= edges(iBin) & Fax < edges(iBin+1);

            if sum(sel) < minBin, continue, end

            axc = mean(Fax(sel));

            if abs(axc) < 0.8 || sign(axc) ~= sgn, continue, end

            dH = mean(metric(sel)) - h0;
            n  = sum(sel);

            num = num + n*axc*dH;
            den = den + n*axc^2;
        end
    end

    gr = num / den;
end
