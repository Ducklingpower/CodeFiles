clc;
clear;
close all;

%% PLOT THE VEHICLE LIMITS
%
% One figure per engine map. Each figure shows acceleration, braking and
% cornering against speed, with all five grip levels drawn on each.
%
% Reads the GGV set written by build_vehicle_limit_ggv.m:
%
%     <ggvRoot>/vehicle_limit/engine<NN>/ggv_engine<NN>_mu<NNN>.csv
%     V_mps, ax_accel, ax_decel, ay
%
% ax_accel already carries the min() of engine potential and tyre propulsion, so
% the acceleration panel is the real limit rather than either source alone. That
% is why the acceleration curves bunch together at low speed and only separate
% higher up: where the engine is the binding limit, grip makes no difference and
% all five grip levels lie on top of each other.

ggvRoot = "/home/elijah/PurdueRacing/GGV_stuff";

engineLevels = ["06" "12" "18" "24" "30"];
gripLevels   = ["mu100" "mu095" "mu090" "mu085" "mu080"];

% Grip is an ordered magnitude, so it gets one hue dark to light rather than a
% rainbow - the reader should see the order in the colour itself.
gripCols = [ ...
    0.031 0.188 0.420; ...   % mu100, most grip
    0.098 0.357 0.612; ...
    0.192 0.510 0.741; ...
    0.420 0.682 0.839; ...
    0.647 0.816 0.902];      % mu080, least

for iEng = 1:numel(engineLevels)

    eng = engineLevels(iEng);

    v = []; axAcc = []; axDec = []; ay = []; shown = strings(0);

    for iMu = 1:numel(gripLevels)

        f = fullfile(ggvRoot, "vehicle_limit", "engine" + eng, ...
            "ggv_engine" + eng + "_" + gripLevels(iMu) + ".csv");

        if ~isfile(f)
            warning("plot_vehicle_limits:missingFile", ...
                "%s not found; that curve is left off.", f);
            continue
        end

        d = readmatrix(f);

        v     = d(:,1);
        axAcc = [axAcc, d(:,2)];
        axDec = [axDec, d(:,3)];
        ay    = [ay,    d(:,4)];
        shown = [shown, gripLevels(iMu)];
    end

    if isempty(shown)
        warning("plot_vehicle_limits:noData", ...
            "engine %s has no readable files; figure skipped.", eng);
        continue
    end

    cols = gripCols(1:numel(shown), :);

    figure("Name", "Engine " + eng, "NumberTitle", "off");

    tl = tiledlayout(1, 3, "TileSpacing", "compact", "Padding", "compact");

    ax1 = nexttile(tl);
    set(ax1, "ColorOrder", cols, "NextPlot", "replacechildren");
    plot(v, axAcc, "LineWidth", 1.8);
    grid on
    xlabel("Speed [m/s]");
    ylabel("a_x [m/s^2]");
    title("Acceleration");
    legend(shown, "Location", "best");

    ax2 = nexttile(tl);
    set(ax2, "ColorOrder", cols, "NextPlot", "replacechildren");
    plot(v, axDec, "LineWidth", 1.8);
    grid on
    xlabel("Speed [m/s]");
    ylabel("a_x [m/s^2]");
    title("Braking");

    ax3 = nexttile(tl);
    set(ax3, "ColorOrder", cols, "NextPlot", "replacechildren");
    plot(v, ay, "LineWidth", 1.8);
    grid on
    xlabel("Speed [m/s]");
    ylabel("a_y [m/s^2]");
    title("Cornering");

    title(tl, "Engine " + eng, "FontWeight", "bold");

    linkaxes([ax1 ax2 ax3], "x");

    fprintf("engine %s: %d grip levels, %d speeds, 0-%g m/s\n", ...
        eng, numel(shown), numel(v), v(end));
end
