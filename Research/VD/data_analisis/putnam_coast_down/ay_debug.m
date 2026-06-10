clc
close all
clear

%% ============================================================
%  DEBUG: Fay vs ay_tire
%
%  Goal:
%  Find why filtered IMU lateral accel Fay does not match
%  curvature + bank tire lateral accel ay_tire in banked corners.
%
%  This script compares:
%     1) Fay
%     2) Fay +/- bank term
%     3) delay-corrected Fay
%     4) fitted Fay correction
%     5) fitted bank coefficient for ay_tire
%
%  Important:
%  This script is diagnostic only.
%  It does not calculate tire forces.
%% ============================================================

%% Load data

data = readtable('/home/elijah/PurdueRacing/bags/lagoona/comp/csv_output/2025-07-24_175839_merged.csv');

%% Settings

mm = 20;
g = 9.81;

vx_min = 10.0;          % only compare at meaningful speed
bank_thresh = 0.35;     % m/s^2, defines "banked" region
maxShift = 60;          % samples for delay sweep

%% Filtered data, one time only

t = data.time_s(:);
t = t - t(1);

Ft = movmean(t, mm, 'omitnan');

Fay = movmean(data.a_y(:), mm, 'omitnan');

Fvx = movmean(data.odom_vx_mps(:), mm, 'omitnan');
Fvy = movmean(data.odom_vy_mps(:), mm, 'omitnan');

Fwz = movmean(data.odom_wz_rads(:), mm, 'omitnan');
Fwx = movmean(data.odom_wx_rads(:), mm, 'omitnan');
Fwy = movmean(data.odom_wy_rads(:), mm, 'omitnan');

Fqx = movmean(data.odom_qx(:), mm, 'omitnan');
Fqy = movmean(data.odom_qy(:), mm, 'omitnan');
Fqz = movmean(data.odom_qz(:), mm, 'omitnan');
Fqw = movmean(data.odom_qw(:), mm, 'omitnan');

x_pos = data.odom_px_m(:);
y_pos = data.odom_py_m(:);

%% Euler angles

Fq = [Fqw Fqx Fqy Fqz];
Feul = quat2eul(Fq, 'ZYX');   % [yaw pitch roll]

Fyaw   = Feul(:,1);
Fpitch = Feul(:,2);
Froll  = Feul(:,3);

%% Curvature-based lateral acceleration

V = sqrt(Fvx.^2 + Fvy.^2);

% Since kappa_yaw = yaw_rate / V:
% ay_curve = V^2 * kappa_yaw = V * yaw_rate
kappa_yaw = nan(size(V));

curv_valid = isfinite(V) & V > vx_min & isfinite(Fwz);
kappa_yaw(curv_valid) = Fwz(curv_valid) ./ V(curv_valid);

ay_curve = V.^2 .* kappa_yaw;

% Equivalent, usually numerically cleaner:
ay_curve_direct = V .* Fwz;

%% Bank term

theta = Fpitch;
phi   = Froll;

bank_term = g .* cos(theta) .* sin(phi);

% Raw tire lateral acceleration candidate
ay_tire_raw = ay_curve + bank_term;

%% Valid masks

valid = isfinite(Fay) & ...
        isfinite(ay_curve) & ...
        isfinite(ay_curve_direct) & ...
        isfinite(ay_tire_raw) & ...
        isfinite(bank_term) & ...
        isfinite(V) & V > vx_min;

banked_valid = valid & abs(bank_term) > bank_thresh;
flat_valid   = valid & abs(bank_term) <= bank_thresh;

fprintf("\n================ DEBUG SETUP ================\n")
fprintf("Total valid samples:       %d\n", sum(valid))
fprintf("Banked valid samples:      %d\n", sum(banked_valid))
fprintf("Flat/low-bank samples:     %d\n", sum(flat_valid))
fprintf("Mean abs bank term:        %.4f m/s^2\n", mean(abs(bank_term(valid)), 'omitnan'))
fprintf("Max abs bank term:         %.4f m/s^2\n", max(abs(bank_term(valid))))
fprintf("=============================================\n\n")

%% ============================================================
%  Part 1:
%  Compare raw Fay to ay_curve and ay_tire_raw
%% ============================================================

rmse_Fay_vs_curve_all  = rmse(Fay, ay_curve, valid);
rmse_Fay_vs_tire_all   = rmse(Fay, ay_tire_raw, valid);

rmse_Fay_vs_curve_bank = rmse(Fay, ay_curve, banked_valid);
rmse_Fay_vs_tire_bank  = rmse(Fay, ay_tire_raw, banked_valid);

rmse_Fay_vs_curve_flat = rmse(Fay, ay_curve, flat_valid);
rmse_Fay_vs_tire_flat  = rmse(Fay, ay_tire_raw, flat_valid);

fprintf("================ RAW COMPARISON ================\n")
fprintf("Fay vs ay_curve      all:    %.4f m/s^2\n", rmse_Fay_vs_curve_all)
fprintf("Fay vs ay_tire_raw   all:    %.4f m/s^2\n\n", rmse_Fay_vs_tire_all)

fprintf("Fay vs ay_curve      banked: %.4f m/s^2\n", rmse_Fay_vs_curve_bank)
fprintf("Fay vs ay_tire_raw   banked: %.4f m/s^2\n\n", rmse_Fay_vs_tire_bank)

fprintf("Fay vs ay_curve      flat:   %.4f m/s^2\n", rmse_Fay_vs_curve_flat)
fprintf("Fay vs ay_tire_raw   flat:   %.4f m/s^2\n", rmse_Fay_vs_tire_flat)
fprintf("================================================\n\n")

%% ============================================================
%  Part 2:
%  Try direct Fay corrections to match ay_tire_raw
%% ============================================================

Fay_none  = Fay;
Fay_plus  = Fay + bank_term;
Fay_minus = Fay - bank_term;

fprintf("================ SIMPLE FAY CORRECTIONS ================\n")
fprintf("Target: ay_tire_raw = ay_curve + bank_term\n\n")

fprintf("RMSE Fay none   all:    %.4f\n", rmse(Fay_none,  ay_tire_raw, valid))
fprintf("RMSE Fay plus   all:    %.4f\n", rmse(Fay_plus,  ay_tire_raw, valid))
fprintf("RMSE Fay minus  all:    %.4f\n\n", rmse(Fay_minus, ay_tire_raw, valid))

fprintf("RMSE Fay none   banked: %.4f\n", rmse(Fay_none,  ay_tire_raw, banked_valid))
fprintf("RMSE Fay plus   banked: %.4f\n", rmse(Fay_plus,  ay_tire_raw, banked_valid))
fprintf("RMSE Fay minus  banked: %.4f\n", rmse(Fay_minus, ay_tire_raw, banked_valid))
fprintf("=========================================================\n\n")

%% ============================================================
%  Part 3:
%  Delay sweep
%% ============================================================

shifts = -maxShift:maxShift;

rmse_delay_tire  = nan(size(shifts));
rmse_delay_curve = nan(size(shifts));

for k = 1:length(shifts)
    Fay_shift = shiftSignalNoWrap(Fay, shifts(k));

    valid_shift = valid & isfinite(Fay_shift);

    rmse_delay_tire(k)  = rmse(Fay_shift, ay_tire_raw, valid_shift);
    rmse_delay_curve(k) = rmse(Fay_shift, ay_curve, valid_shift);
end

[best_rmse_tire, idx_tire] = min(rmse_delay_tire);
best_shift_tire = shifts(idx_tire);

[best_rmse_curve, idx_curve] = min(rmse_delay_curve);
best_shift_curve = shifts(idx_curve);

fprintf("================ DELAY SWEEP ================\n")
fprintf("Best shift for Fay vs ay_tire_raw: %d samples, RMSE %.4f\n", ...
    best_shift_tire, best_rmse_tire)
fprintf("Best shift for Fay vs ay_curve:    %d samples, RMSE %.4f\n", ...
    best_shift_curve, best_rmse_curve)
fprintf("=============================================\n\n")

% Use the best shift against ay_tire_raw for correction testing
Fay_shifted = shiftSignalNoWrap(Fay, best_shift_tire);

valid_shifted = valid & isfinite(Fay_shifted);
banked_valid_shifted = banked_valid & isfinite(Fay_shifted);
flat_valid_shifted   = flat_valid & isfinite(Fay_shifted);

%% ============================================================
%  Part 4:
%  Fit correction to make Fay match ay_tire_raw
%
%  Model:
%     ay_tire_raw ≈ c_fay * Fay_shifted + c_bank * bank_term + bias
%
%  This answers:
%     "What correction to Fay makes it match my current ay_tire?"
%% ============================================================

y = ay_tire_raw(valid_shifted);
X = [Fay_shifted(valid_shifted), bank_term(valid_shifted), ones(sum(valid_shifted),1)];

coef = X \ y;

c_fay  = coef(1);
c_bank = coef(2);
bias   = coef(3);

Fay_fit_to_tire = c_fay .* Fay_shifted + c_bank .* bank_term + bias;

fprintf("================ FIT FAY TO ay_tire_raw ================\n")
fprintf("Model: ay_tire_raw = c_fay*Fay_shifted + c_bank*bank_term + bias\n\n")
fprintf("c_fay:  %.4f\n", c_fay)
fprintf("c_bank: %.4f\n", c_bank)
fprintf("bias:   %.4f m/s^2\n\n", bias)

fprintf("RMSE shifted Fay only       all:    %.4f\n", rmse(Fay_shifted, ay_tire_raw, valid_shifted))
fprintf("RMSE fitted Fay correction  all:    %.4f\n\n", rmse(Fay_fit_to_tire, ay_tire_raw, valid_shifted))

fprintf("RMSE shifted Fay only       banked: %.4f\n", rmse(Fay_shifted, ay_tire_raw, banked_valid_shifted))
fprintf("RMSE fitted Fay correction  banked: %.4f\n\n", rmse(Fay_fit_to_tire, ay_tire_raw, banked_valid_shifted))

fprintf("RMSE shifted Fay only       flat:   %.4f\n", rmse(Fay_shifted, ay_tire_raw, flat_valid_shifted))
fprintf("RMSE fitted Fay correction  flat:   %.4f\n", rmse(Fay_fit_to_tire, ay_tire_raw, flat_valid_shifted))
fprintf("========================================================\n\n")

%% ============================================================
%  Part 5:
%  Fit the bank coefficient inside ay_tire itself
%
%  Model:
%     Fay_shifted ≈ ay_curve + c_bank_ref*bank_term + bias_ref
%
%  This answers:
%     "Is my bank term in ay_tire too large, too small,
%      wrong sign, or unnecessary?"
%% ============================================================

y_ref = Fay_shifted(valid_shifted) - ay_curve(valid_shifted);
X_ref = [bank_term(valid_shifted), ones(sum(valid_shifted),1)];

coef_ref = X_ref \ y_ref;

c_bank_ref = coef_ref(1);
bias_ref   = coef_ref(2);

ay_tire_fit_bank = ay_curve + c_bank_ref .* bank_term + bias_ref;

fprintf("================ FIT BANK TERM INSIDE ay_tire ================\n")
fprintf("Model: Fay_shifted = ay_curve + c_bank_ref*bank_term + bias_ref\n\n")
fprintf("c_bank_ref: %.4f\n", c_bank_ref)
fprintf("bias_ref:   %.4f m/s^2\n\n", bias_ref)

fprintf("RMSE raw ay_tire       all:    %.4f\n", rmse(ay_tire_raw, ay_tire_raw, valid_shifted))
fprintf("RMSE Fay vs raw tire   all:    %.4f\n", rmse(Fay_shifted, ay_tire_raw, valid_shifted))
fprintf("RMSE Fay vs fit tire   all:    %.4f\n\n", rmse(Fay_shifted, ay_tire_fit_bank, valid_shifted))

fprintf("RMSE Fay vs raw tire   banked: %.4f\n", rmse(Fay_shifted, ay_tire_raw, banked_valid_shifted))
fprintf("RMSE Fay vs fit tire   banked: %.4f\n\n", rmse(Fay_shifted, ay_tire_fit_bank, banked_valid_shifted))

fprintf("RMSE Fay vs raw tire   flat:   %.4f\n", rmse(Fay_shifted, ay_tire_raw, flat_valid_shifted))
fprintf("RMSE Fay vs fit tire   flat:   %.4f\n", rmse(Fay_shifted, ay_tire_fit_bank, flat_valid_shifted))
fprintf("==============================================================\n\n")

fprintf("INTERPRETATION:\n")
fprintf("If c_bank_ref is close to 1, your current ay_tire bank term is reasonable.\n")
fprintf("If c_bank_ref is close to 0, measured roll should not be used directly as road bank.\n")
fprintf("If c_bank_ref is negative, the bank sign convention is likely wrong.\n")
fprintf("If 0 < c_bank_ref < 1, measured roll probably includes chassis roll, not pure road bank.\n\n")

%% ============================================================
%  Plots
%% ============================================================

%% Plot 1: Fay vs acceleration candidates

figure
tiledlayout(4,1, 'TileSpacing', 'compact', 'Padding', 'compact')

nexttile
plot(t, Fay, 'LineWidth', 1.1)
hold on
plot(t, ay_curve, 'LineWidth', 1.1)
plot(t, ay_tire_raw, 'LineWidth', 1.1)
grid on
ylabel("a_y [m/s^2]")
legend("Fay", "ay curve = V*r", "ay tire raw = V*r + bank", ...
    'Location', 'best')
title("Raw Fay vs Curvature and Bank-Corrected ay")

nexttile
plot(t, bank_term, 'LineWidth', 1.1)
grid on
ylabel("bank term [m/s^2]")
title("Bank Term: g cos(\theta) sin(\phi)")

nexttile
plot(t, Fay - ay_curve, 'LineWidth', 1.1)
hold on
plot(t, Fay - ay_tire_raw, 'LineWidth', 1.1)
grid on
ylabel("error [m/s^2]")
legend("Fay - ay curve", "Fay - ay tire raw", 'Location', 'best')
title("Error Signals")

nexttile
plot(t, V, 'LineWidth', 1.1)
grid on
xlabel("time [s]")
ylabel("V [m/s]")
title("Vehicle Speed")

%% Plot 2: delay sweep

figure
plot(shifts, rmse_delay_tire, 'LineWidth', 1.2)
hold on
plot(shifts, rmse_delay_curve, 'LineWidth', 1.2)
grid on
xlabel("Fay shift [samples]")
ylabel("RMSE [m/s^2]")
legend("Fay vs ay tire raw", "Fay vs ay curve", 'Location', 'best')
title("Delay Sweep")

%% Plot 3: fitted corrections

figure
tiledlayout(3,1, 'TileSpacing', 'compact', 'Padding', 'compact')

nexttile
plot(t, ay_tire_raw, 'LineWidth', 1.1)
hold on
plot(t, Fay_shifted, 'LineWidth', 1.1)
plot(t, Fay_fit_to_tire, 'LineWidth', 1.1)
grid on
ylabel("a_y [m/s^2]")
legend("ay tire raw", "Fay shifted", "Fay fitted to tire", ...
    'Location', 'best')
title("Can Fay Be Corrected to Match ay tire?")

nexttile
plot(t, Fay_shifted - ay_tire_raw, 'LineWidth', 1.1)
hold on
plot(t, Fay_fit_to_tire - ay_tire_raw, 'LineWidth', 1.1)
grid on
ylabel("error [m/s^2]")
legend("Fay shifted - tire", "Fay fitted - tire", ...
    'Location', 'best')
title("Fay Correction Error")

nexttile
plot(t, bank_term, 'LineWidth', 1.1)
grid on
xlabel("time [s]")
ylabel("bank term [m/s^2]")
title("Bank Term")

%% Plot 4: corrected ay_tire bank coefficient

figure
tiledlayout(3,1, 'TileSpacing', 'compact', 'Padding', 'compact')

nexttile
plot(t, Fay_shifted, 'LineWidth', 1.1)
hold on
plot(t, ay_tire_raw, 'LineWidth', 1.1)
plot(t, ay_tire_fit_bank, 'LineWidth', 1.1)
grid on
ylabel("a_y [m/s^2]")
legend("Fay shifted", "ay tire raw", "ay tire fitted bank", ...
    'Location', 'best')
title("Should ay tire Use Full Measured Roll as Bank?")

nexttile
plot(t, Fay_shifted - ay_tire_raw, 'LineWidth', 1.1)
hold on
plot(t, Fay_shifted - ay_tire_fit_bank, 'LineWidth', 1.1)
grid on
ylabel("error [m/s^2]")
legend("Fay - raw tire", "Fay - fitted tire", ...
    'Location', 'best')
title("ay tire Error Before/After Bank Coefficient Fit")

nexttile
plot(t, bank_term, 'LineWidth', 1.1)
grid on
xlabel("time [s]")
ylabel("bank term [m/s^2]")
title("Bank Term")

%% Plot 5: error correlation with bank term

figure
scatter(bank_term(valid_shifted), ...
        Fay_shifted(valid_shifted) - ay_tire_raw(valid_shifted), ...
        8, t(valid_shifted), 'filled')
grid on
xlabel("bank term [m/s^2]")
ylabel("Fay shifted - ay tire raw [m/s^2]")
title("Does Error Correlate with Bank Term?")
colorbar

%% Plot 6: track colored by mismatch

error_raw = Fay_shifted - ay_tire_raw;
error_fit = Fay_shifted - ay_tire_fit_bank;

figure
tiledlayout(1,2, 'TileSpacing', 'compact', 'Padding', 'compact')

nexttile
scatter(x_pos(valid_shifted), y_pos(valid_shifted), 8, error_raw(valid_shifted), 'filled')
axis equal
grid on
xlabel("x [m]")
ylabel("y [m]")
title("Track Colored by Fay - Raw ay tire")
colorbar

nexttile
scatter(x_pos(valid_shifted), y_pos(valid_shifted), 8, error_fit(valid_shifted), 'filled')
axis equal
grid on
xlabel("x [m]")
ylabel("y [m]")
title("Track Colored by Fay - Fitted ay tire")
colorbar

%% Local helper functions

function e = rmse(a, b, mask)
    d = a(mask) - b(mask);
    e = sqrt(mean(d.^2, 'omitnan'));
end

function y = shiftSignalNoWrap(x, shift)
    y = nan(size(x));

    if shift > 0
        y(1+shift:end) = x(1:end-shift);
    elseif shift < 0
        s = abs(shift);
        y(1:end-s) = x(1+s:end);
    else
        y = x;
    end
end