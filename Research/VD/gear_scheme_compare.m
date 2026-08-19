clc; clear; close all

%% Comparative plots for two gear-shift schemes

logs.og_early = struct("file", "/home/elijah/PurdueRacing/og_gear.csv",         "label", "og_gear early");
logs.g1_early = struct("file", "/home/elijah/PurdueRacing/gear1.csv",           "label", "gear1 early");
logs.og_min   = struct("file", "/home/elijah/PurdueRacing/og_gear_micurve.csv", "label", "og_gear mincurve");
logs.g1_min   = struct("file", "/home/elijah/PurdueRacing/mincurve_gear1.csv",  "label", "gear1 mincurve");


runs = [logs.g1_early; logs.og_min];

run_colour = [0.00 0.45 0.74
              0.85 0.33 0.10];

% One colour per run, cycled if runs outnumbers the rows above.
colour_of = @(r) run_colour(mod(r-1, size(run_colour,1)) + 1, :);


time_offset = [0 1857];

if numel(time_offset) ~= numel(runs)
    error("time_offset has %d entries but there are %d runs", ...
        numel(time_offset), numel(runs))
end

T_interval = [0 Inf];

% Topic names
topic.v_des    = "/planning/desired_velocity/data";
topic.v_act    = "/odometry/global_filtered/twist/twist/linear/x";
topic.rpm      = "/raptor_dbw_interface/pt_report/engine_rpm";
topic.gear     = "/raptor_dbw_interface/pt_report/current_gear";
topic.yaw_rate = "/odometry/global_filtered/twist/twist/angular/z";
topic.throttle = "/raptor_dbw_interface/pt_report/throttle_position";
topic.pos_x    = "/odometry/global_filtered/pose/pose/position/x";
topic.pos_y    = "/odometry/global_filtered/pose/pose/position/y";

%% Load

signal_names = fieldnames(topic);

for r = 1:numel(runs)

    fid = fopen(runs(r).file, "r");
    if fid < 0
        error("Cannot open log: %s", runs(r).file)
    end
    header = split(string(fgetl(fid)), ",");
    fclose(fid);

    raw = readmatrix(runs(r).file);

    time_col = find(header == "__time", 1);
    if isempty(time_col)
        error("No __time column in %s", runs(r).file)
    end

    t_all  = raw(:, time_col);
    t_zero = min(t_all) + time_offset(r);

    for s = 1:numel(signal_names)
        name = signal_names{s};
        col  = find(header == topic.(name), 1);
        if isempty(col)
            error("Topic %s not found in %s", topic.(name), runs(r).file)
        end
        [t, v] = sparse_series(t_all, raw(:,col), t_zero);
        runs(r).(name) = struct("t", t, "v", v);
    end

    % Velocity tracking error. Desired and actual are published on separate
    % clocks, so desired is resampled onto the actual-velocity timestamps
    % before differencing.
    v_des_resampled = interp1(runs(r).v_des.t, runs(r).v_des.v, ...
                              runs(r).v_act.t, "linear", "extrap");
    runs(r).v_err = struct("t", runs(r).v_act.t, ...
                           "v", v_des_resampled - runs(r).v_act.v);

    fprintf("Loaded %-10s %6d rows, %.1f s, %d signals\n", ...
        runs(r).label, size(raw,1), runs(r).v_act.t(end), numel(signal_names));
end

%% Trim to the plot window
% T_interval gates the data itself, not just the axis limits, so the autoscaled
% y-ranges and the summary statistics below describe the window asked for
% rather than the whole run. Trimming happens after v_err is built, so the
% resampling there still sees each run's full time base.
%
% The interval is on the offset-adjusted clock, the same numbers the panels and
% the map labels show. A negative start is legal and reaches back before a
% run's zero, which is the pre-offset part of a run with a nonzero time_offset.
field_names = [signal_names; {'v_err'}];

for r = 1:numel(runs)
    for s = 1:numel(field_names)
        name = field_names{s};
        sig  = runs(r).(name);
        keep = sig.t >= T_interval(1) & sig.t <= T_interval(2);
        runs(r).(name) = struct("t", sig.t(keep), "v", sig.v(keep));
    end

    if isempty(runs(r).v_act.t)
        error("Run %s has no samples in T_interval = [%g %g]", ...
            runs(r).label, T_interval(1), T_interval(2))
    end

    fprintf("Window %-10s %6d velocity samples, %.1f to %.1f s\n", ...
        runs(r).label, numel(runs(r).v_act.t), ...
        runs(r).v_act.t(1), runs(r).v_act.t(end));
end

%% Comparison figure
panels = [ ...
    struct("field","v_des",   "name","Velocity [m/s]",      "stair",false)
    struct("field","rpm",     "name","Engine Speed [RPM]",  "stair",false)
    struct("field","gear",    "name","Gear",                "stair",true)
    struct("field","yaw_rate","name","Yaw Rate [rad/s]",    "stair",false)
    struct("field","throttle","name","Throttle [%]",        "stair",false)
    struct("field","pos_x",   "name","X Position [m]",      "stair",false)];

% The layout is a 5-column grid: the stacked time histories span the left
% three columns (60% of the width) and the track map spans the remaining two.
n_col     = 5;
n_col_ts  = 3;

figure("Position", [100 40 1800 950])
tl = tiledlayout(numel(panels), n_col, "TileSpacing", "compact", "Padding", "compact");

ax      = gobjects(numel(panels),1);
t_start = Inf;
t_end   = -Inf;

for p = 1:numel(panels)

    field = char(panels(p).field);
    ax(p) = nexttile(tl, (p-1)*n_col + 1, [1 n_col_ts]);
    hold on

    for r = 1:numel(runs)
        s = runs(r).(field);
        if ~isempty(s.t)
            t_start = min(t_start, s.t(1));
            t_end   = max(t_end,   s.t(end));
        end

        if panels(p).stair
            stairs(s.t, s.v, "LineWidth", 1.2, "Color", colour_of(r))
        elseif strcmp(field, "v_des")
            % desired dashed, actual solid, one colour per run
            plot(s.t, s.v, "--", "LineWidth", 1.0, "Color", colour_of(r))
            plot(runs(r).v_act.t, runs(r).v_act.v, "-", ...
                "LineWidth", 1.2, "Color", colour_of(r))
        else
            plot(s.t, s.v, "-", "LineWidth", 1.2, "Color", colour_of(r))
        end
    end

    ylabel(panels(p).name), grid on

    switch field
        case "v_des"
            % Two lines per run, in the order they were drawn.
            entries = strings(1, 2*numel(runs));
            entries(1:2:end) = [runs.label] + " desired";
            entries(2:2:end) = [runs.label] + " actual";
            legend(entries, ...
                "Location", "best", "NumColumns", 2, "Interpreter", "none")
            title("Gear Shift Scheme Comparison")
        case "pos_x"
            legend([runs.label], "Location", "best", "Interpreter", "none")
        case "gear"
            yticks(1:6)
    end
end

xlabel(ax(end), "Time [s]")
linkaxes(ax, "x")

% The data is already trimmed, so the window is just its extent, widened to a
% requested bound whenever that bound is finite and tighter than the data.
t_window = [max(T_interval(1), t_start) min(T_interval(2), t_end)];
xlim(ax(1), t_window)

%% Track map
% Position x and y are published in the same message but are pulled out as
% separate sparse series, so y is resampled onto the x timestamps before the
% pair is plotted. Both are already trimmed to T_interval, so the map shows the
% same stretch of track as the panels on the left.
nexttile(tl, n_col_ts + 1, [numel(panels) n_col - n_col_ts]);
hold on

for r = 1:numel(runs)

    % interp1 needs distinct, sorted sample points, which unique gives.
    [t_win, i_x] = unique(runs(r).pos_x.t);
    [t_y,   i_y] = unique(runs(r).pos_y.t);
    x_win = runs(r).pos_x.v(i_x);

    % Too narrow a window leaves nothing to interpolate along. The empty line
    % still consumes its legend entry, keeping the labels on the right runs.
    if numel(t_win) < 2 || numel(t_y) < 2
        plot(nan, nan, "-", "LineWidth", 1.2, "Color", colour_of(r))
        continue
    end

    y_win = interp1(t_y, runs(r).pos_y.v(i_y), t_win, "linear", "extrap");

    plot(x_win, y_win, "-", "LineWidth", 1.2, "Color", colour_of(r))
end

axis equal, grid on
xlabel("X [m]"), ylabel("Y [m]")
title("Track Map")
legend([runs.label], "Location", "best", "Interpreter", "none")

%% Summary
% Over the trimmed data, so these describe T_interval, not the whole run.
fprintf("\nWindow %.1f to %.1f s\n", t_window(1), t_window(2));
fprintf("%-10s %9s %9s %9s %8s %9s %8s\n", ...
    "run", "RMS err", "mean|e|", "max|e|", "shifts", "max rpm", "WOT %");
for r = 1:numel(runs)
    e   = runs(r).v_err.v;
    thr = runs(r).throttle.v;
    fprintf("%-10s %9.3f %9.3f %9.3f %8d %9.0f %8.1f\n", ...
        runs(r).label, ...
        sqrt(mean(e.^2)), mean(abs(e)), max(abs(e)), ...
        nnz(diff(round(runs(r).gear.v)) ~= 0), ...
        max(runs(r).rpm.v), ...
        100*nnz(thr >= 98)/numel(thr));
end

%% Local functions
function [t, v] = sparse_series(t_all, column, t_zero)
% Pull the populated samples out of one sparse topic column.
    ok = isfinite(column) & isfinite(t_all);
    t  = t_all(ok) - t_zero;
    v  = column(ok);
end
