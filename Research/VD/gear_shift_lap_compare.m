clc; clear; close all

%% Lap comparison for the simulated gear shift schemes
% Each run is aligned on its own frenet s = 0 crossing, so t = 0 is the start of
% a lap in every file and the runs are directly comparable.

%% Files
runs = [ ...
    struct("file", "/home/elijah/PurdueRacing/sim_new_gear_shifting/24_psi_new.csv", "label", "new shifting")
    struct("file", "/home/elijah/PurdueRacing/sim_new_gear_shifting/24_psi_old.csv", "label", "old shifting")];

run_colour = [0.00 0.45 0.74
              0.85 0.33 0.10];

num_runs = numel(runs);

%% Topics
topic.s        = "/planning/current_frenet_s/data";
topic.gear     = "/raptor_dbw_interface/pt_report/current_gear";
topic.rpm      = "/raptor_dbw_interface/pt_report/engine_rpm";
topic.velocity = "/odometry/global_filtered/twist/twist/linear/x";
topic.pos_x    = "/odometry/global_filtered/pose/pose/position/x";
topic.pos_y    = "/odometry/global_filtered/pose/pose/position/y";

signal_names = fieldnames(topic);

%% Segment of interest
% This one runs through the start/finish line, so it wraps: s climbs to the end
% of the track, resets to 0, then climbs to the end value.
segment_s_start = 3228;
segment_s_end   = 205;

%% Load each run
for r = 1:num_runs

    fprintf("Loading %s\n", runs(r).file);

    fid = fopen(runs(r).file, "r");
    if fid < 0
        error("Cannot open log: %s", runs(r).file)
    end
    header = split(string(fgetl(fid)), ",");
    fclose(fid);

    raw = readmatrix(runs(r).file, "NumHeaderLines", 1);

    time_col = find_column(header, "__time", runs(r).file);
    t_all    = raw(:, time_col);

    col = struct();
    for k = 1:numel(signal_names)
        name     = signal_names{k};
        col.(name) = find_column(header, topic.(name), runs(r).file);
    end

    % Every topic is logged on its own rows, so the frenet s timestamps become
    % the shared time base and everything else is resampled onto it. Gear is a
    % held value rather than a continuous one, so it gets previous-neighbour.
    [t_base, s] = sparse_series(t_all, raw(:, col.s));

    gear     = resample_topic(t_all, raw(:, col.gear),     t_base, "previous");
    rpm      = resample_topic(t_all, raw(:, col.rpm),      t_base, "linear");
    velocity = resample_topic(t_all, raw(:, col.velocity), t_base, "linear");
    pos_x    = resample_topic(t_all, raw(:, col.pos_x),    t_base, "linear");
    pos_y    = resample_topic(t_all, raw(:, col.pos_y),    t_base, "linear");

    % Align on the first s = 0 and take the lap that starts there.
    lap_start = find_lap_starts(s);

    if numel(lap_start) < 2
        error("%s: found %d s = 0 crossings, two are needed for a full lap.", ...
            runs(r).file, numel(lap_start))
    end

    t          = t_base - t_base(lap_start(1));
    lap_time   = diff(t(lap_start));
    lap_window = lap_start(1) : lap_start(2) - 1;

    % Segment bounds. The end value is smaller than the start value, so the
    % search for it only succeeds after s has reset through the lap boundary.
    i_segment_start = first_upcrossing(s, segment_s_start, lap_start(1));
    if isempty(i_segment_start)
        error("%s: s never reaches %g after the first lap start.", ...
            runs(r).file, segment_s_start)
    end

    i_segment_end = first_upcrossing(s, segment_s_end, i_segment_start);
    if isempty(i_segment_end)
        error("%s: the log ends before s comes back round to %g.", ...
            runs(r).file, segment_s_end)
    end

    t_segment_start = crossing_time(t, s, i_segment_start, segment_s_start);
    t_segment_end   = crossing_time(t, s, i_segment_end,   segment_s_end);

    runs(r).t        = t;
    runs(r).s        = s;
    runs(r).gear     = gear;
    runs(r).rpm      = rpm;
    runs(r).velocity = velocity;
    runs(r).pos_x    = pos_x;
    runs(r).pos_y    = pos_y;

    runs(r).lap_time      = lap_time;
    runs(r).lap_time_shown = lap_time(1);
    runs(r).lap_window    = lap_window;

    runs(r).segment_window  = i_segment_start : i_segment_end;
    runs(r).segment_time    = t_segment_end - t_segment_start;
    runs(r).segment_start_x = interp1(t, pos_x, t_segment_start);
    runs(r).segment_start_y = interp1(t, pos_y, t_segment_start);
    runs(r).segment_end_x   = interp1(t, pos_x, t_segment_end);
    runs(r).segment_end_y   = interp1(t, pos_y, t_segment_end);

    fprintf("  %6.1f s of data, %d complete laps, track length ~%.0f m\n", ...
        t(end) - t(1), numel(lap_time), max(s));
end

if num_runs == 2 && isequal(runs(1).s, runs(2).s) && isequal(runs(1).rpm, runs(2).rpm)
    warning("The two runs hold identical data, so every trace will lie on top of itself.")
end

%% Figure: one lap from s = 0
lap_title = strings(1, num_runs);
for r = 1:num_runs
    lap_title(r) = sprintf("%s %.2f s", runs(r).label, runs(r).lap_time_shown);
end

figure("Name", "One lap from s = 0", "Position", [100 60 1200 900])
tl_lap = tiledlayout(4, 1, "TileSpacing", "compact", "Padding", "compact");

title(tl_lap, "Lap from Frenet s = 0    " + join(lap_title, "    "), ...
    "FontWeight", "bold", "FontSize", 13, "Interpreter", "none")

ax_lap = gobjects(4, 1);

ax_lap(1) = nexttile;
hold on
for r = 1:num_runs
    idx = runs(r).lap_window;
    stairs(runs(r).t(idx), runs(r).gear(idx), "LineWidth", 1.2, "Color", run_colour(r,:))
end
ylabel("Gear"), grid on
yticks(1:6)
legend([runs.label], "Location", "best", "Interpreter", "none")

ax_lap(2) = nexttile;
hold on
for r = 1:num_runs
    idx = runs(r).lap_window;
    plot(runs(r).t(idx), runs(r).rpm(idx), "LineWidth", 1.2, "Color", run_colour(r,:))
end
ylabel("Engine Speed [RPM]"), grid on

ax_lap(3) = nexttile;
hold on
for r = 1:num_runs
    idx = runs(r).lap_window;
    plot(runs(r).t(idx), runs(r).velocity(idx), "LineWidth", 1.2, "Color", run_colour(r,:))
end
ylabel("Velocity X [m/s]"), grid on

ax_lap(4) = nexttile;
hold on
for r = 1:num_runs
    idx = runs(r).lap_window;
    plot(runs(r).t(idx), runs(r).s(idx), "LineWidth", 1.2, "Color", run_colour(r,:))
end
ylabel("Frenet s [m]"), xlabel("Time [s]"), grid on

% Lap end markers. The times themselves are in the figure title.
for k = 1:numel(ax_lap)
    for r = 1:num_runs
        xline(ax_lap(k), runs(r).lap_time_shown, "--", ...
            "Color", run_colour(r,:), "LineWidth", 1.2, "HandleVisibility", "off")
    end
end

linkaxes(ax_lap, "x")
xlim(ax_lap(1), [0 max([runs.lap_time_shown])])

%% Figure: segment through the start/finish line
figure("Name", "Segment comparison", "Position", [150 100 1000 800])
hold on

for r = 1:num_runs
    idx = runs(r).segment_window;
    plot(runs(r).pos_x(idx), runs(r).pos_y(idx), "LineWidth", 2, "Color", run_colour(r,:))
end

for r = 1:num_runs

    if r == 1
        marker_visibility = "on";   % one legend entry for the pair, not one per run
    else
        marker_visibility = "off";
    end

    plot(runs(r).segment_start_x, runs(r).segment_start_y, "o", "MarkerSize", 11, ...
        "MarkerFaceColor", [0.20 0.75 0.20], "MarkerEdgeColor", "k", ...
        "HandleVisibility", marker_visibility)

    plot(runs(r).segment_end_x, runs(r).segment_end_y, "s", "MarkerSize", 11, ...
        "MarkerFaceColor", "r", "MarkerEdgeColor", "k", ...
        "HandleVisibility", marker_visibility)
end

text(runs(1).segment_start_x, runs(1).segment_start_y, ...
    sprintf("  start, s = %g", segment_s_start), "FontWeight", "bold")
text(runs(1).segment_end_x, runs(1).segment_end_y, ...
    sprintf("  end, s = %g", segment_s_end), "FontWeight", "bold")

segment_label = strings(1, num_runs);
for r = 1:num_runs
    segment_label(r) = sprintf("%s, %.3f s", runs(r).label, runs(r).segment_time);
end

axis equal, grid on
xlabel("X [m]"), ylabel("Y [m]")
title(sprintf("Segment s = %g to s = %g, through the start/finish line", ...
    segment_s_start, segment_s_end))
legend([segment_label, ...
        sprintf("Start, s = %g", segment_s_start), ...
        sprintf("End, s = %g", segment_s_end)], ...
    "Location", "best", "Interpreter", "none")

%% Summary
fprintf("\nLAP TIMES, aligned on frenet s = 0\n")
for r = 1:num_runs
    fprintf("  %-14s %s\n", runs(r).label, ...
        join(compose("%.3f s", runs(r).lap_time'), ", "));
end

fprintf("\nSEGMENT s = %g to s = %g\n", segment_s_start, segment_s_end)
for r = 1:num_runs
    fprintf("  %-14s %.3f s\n", runs(r).label, runs(r).segment_time);
end

if num_runs == 2
    fprintf("  %-14s %+.3f s\n", "difference", runs(2).segment_time - runs(1).segment_time);
end

%% Local functions

function col = find_column(header, name, file)
    col = find(header == name, 1);
    if isempty(col)
        error("Topic %s not found in %s", name, file)
    end
end

function [t, v] = sparse_series(t_all, column)
% Pull the populated samples out of one sparse topic column.
    is_sample = isfinite(column) & isfinite(t_all);
    t         = t_all(is_sample);
    v         = column(is_sample);
end

function values = resample_topic(t_all, column, t_base, method)
% One topic's samples, put onto the shared time base.
    [t_topic, v_topic] = sparse_series(t_all, column);
    values = interp1(t_topic, v_topic, t_base, method, "extrap");
end

function lap_start = find_lap_starts(s)
% First sample of every new lap, where frenet s resets from the end of the track
% back to zero.
    min_reset_drop = 0.5 * max(s);

    is_reset = false(numel(s), 1);

    for i = 2:numel(s)
        step = s(i) - s(i-1);
        if step < -min_reset_drop
            is_reset(i) = true;
        end
    end

    lap_start = find(is_reset);
end

function idx = first_upcrossing(s, threshold, from_index)
% First sample after from_index where s rises through threshold. Empty if the
% log ends first.
    idx = [];

    for i = from_index+1 : numel(s)
        if s(i-1) < threshold && s(i) >= threshold
            idx = i;
            return
        end
    end
end

function t_cross = crossing_time(t, s, idx, threshold)
% Interpolated between the two samples that bracket the crossing, because s is
% logged in whole metres and would otherwise quantise the segment time.
    s_before = s(idx-1);
    s_after  = s(idx);
    t_before = t(idx-1);
    t_after  = t(idx);

    fraction = (threshold - s_before) / (s_after - s_before);
    t_cross  = t_before + fraction * (t_after - t_before);
end
