%% SIM_PLOT.m
% Plots ACC test data from two CSV logs (defender + attacker).
%
%   DEFENDER figure:  desired vs actual velocity, throttle (cmd vs measured),
%                     engine rpm, current gear
%   ATTACKER figure:  desired vs actual velocity, speed scaling, ACC vs MPC
%                     accel commands, ACC-enable bool, following distance,
%                     following time, throttle (cmd vs measured)
%
% Engine torque/power are NOT computed: wheel_torque_total (and every other
% torque channel) logs as identically zero in these runs, so there is no valid
% torque source to back-calculate from.
%
% Channels are logged on their own timestamps and interpolated onto a common
% time base per file. Missing columns warn and plot blank rather than erroring;
% channels that load but are constant over the whole log also warn, since a
% flat trace otherwise looks like real data.
%
% The two files were exported with different time-column names ('__time' vs
% 'time'), so the time column is resolved per file from cfg.timeCandidates.
% ---------------------------------------------------------------------------

clear; clc; close all;

%% ========================= CONFIG =========================
% ---- files ----
cfg.defenderFile = '/home/elijah/PurdueRacing/sim-acc/scaling/defender_R1_time.csv';
cfg.attackerFile = '/home/elijah/PurdueRacing/sim-acc/scaling/attacker_R1_time.csv';
% ---- time handling (shared) ----
cfg.timeUnits      = 'auto';    % 'auto' | 'seconds' | 'nanoseconds'
cfg.zeroStart      = true;
cfg.timeCandidates = {'__time','time'};   % first one present in a file wins
% ---- DEFENDER channel names ----
def.desiredVel  = '/planning/desired_velocity/data';
def.actualVel   = '/odometry/global_filtered/twist/twist/linear/x';
def.engineRpm   = '/raptor_dbw_interface/pt_report/engine_rpm';
def.throttleCmd = '/raptor_dbw_interface/accelerator_pedal_cmd/pedal_cmd';  % commanded [%]
def.throttlePos = '/raptor_dbw_interface/pt_report/throttle_position';      % measured  [%]
def.gear        = '/raptor_dbw_interface/pt_report/current_gear';           % integer gear
% ---- ATTACKER channel names ----
att.desiredVel   = def.desiredVel;      % shared channel names
att.actualVel    = def.actualVel;
att.engineRpm    = def.engineRpm;       % present in the log, not currently plotted
att.throttleCmd  = def.throttleCmd;
att.throttlePos  = def.throttlePos;
att.speedScaling = '/planning/acc_speed_scaler/data';
att.accAccelCmd  = '/control/acc/acc_acc_command/accelerator_cmd';
att.mpcAccelCmd  = '/control/fbl_mpc/desired_acceleration/data';
att.accEnable    = '/planning/enable_distance_acc/data';   % boolean 0/1
att.oppVelocity    = '/planning/follow_car_speed/data';    % opponent car velocity [m/s]
att.followDistance = '/planning/follow_car_dist/data';     % following distance [m]
% Calculated following time = following distance / opponent velocity.
% Set cfg.followTimeConst to a numeric constant [s] to override with a fixed
% value instead of calculating; [] calculates from distance/velocity.
cfg.followTimeConst = [];   % e.g. 1.5 for a fixed headway, or [] to calculate
%% ==========================================================

%% ======================= DEFENDER =======================
[Dt, Dhdr, DtAll] = loadFile(cfg.defenderFile, cfg.timeCandidates, cfg.timeUnits);
DtMaster = masterTime(DtAll);
Dt0 = DtMaster(1)*cfg.zeroStart;

dVdes   = getChan(Dt, Dhdr, DtAll, DtMaster, def.desiredVel,  'linear');
dVact   = getChan(Dt, Dhdr, DtAll, DtMaster, def.actualVel,   'linear');
dRpm    = getChan(Dt, Dhdr, DtAll, DtMaster, def.engineRpm,   'linear');
dThrCmd = getChan(Dt, Dhdr, DtAll, DtMaster, def.throttleCmd, 'linear');
dThrPos = getChan(Dt, Dhdr, DtAll, DtMaster, def.throttlePos, 'linear');
dGear   = getChan(Dt, Dhdr, DtAll, DtMaster, def.gear,        'previous'); % hold discrete gear

tD = DtMaster - Dt0;

figure('Color','w','Name','Defender — R1 ACC Test');

axD(1) = subplot(4,1,1);
plot(tD, dVdes, 'b--', 'LineWidth', 1.2); hold on;
plot(tD, dVact, 'k',   'LineWidth', 1.2); hold off; grid on;
ylabel('Velocity [m/s]'); title('Defender: Desired vs Actual Velocity');
legend({'Desired','Actual'}, 'Location','best');

axD(2) = subplot(4,1,2);
plot(tD, dThrCmd, 'Color',[0.85 0.33 0.10], 'LineWidth', 1.0); hold on;
plot(tD, dThrPos, 'Color',[0.30 0.30 0.30], 'LineWidth', 1.0); hold off; grid on;
ylabel('Throttle [%]'); title('Throttle: Command vs Measured');
legend({'Command','Measured'}, 'Location','best');

axD(3) = subplot(4,1,3);
plot(tD, dRpm, 'b', 'LineWidth', 1.0); grid on;
ylabel('Engine RPM'); title('Engine Speed');

axD(4) = subplot(4,1,4);
stairs(tD, dGear, 'Color',[0.20 0.60 0.30], 'LineWidth', 1.2); grid on;
ylabel('Gear'); xlabel('Time [s]'); title('Current Gear');
gLo = min(dGear); gHi = max(dGear);
if isfinite(gLo) && isfinite(gHi)
    ylim([gLo-0.5 gHi+0.5]); yticks(gLo:gHi);
end

linkaxes(axD, 'x');

%% ======================= ATTACKER =======================
[At, Ahdr, AtAll] = loadFile(cfg.attackerFile, cfg.timeCandidates, cfg.timeUnits);
AtMaster = masterTime(AtAll);
At0 = AtMaster(1)*cfg.zeroStart;

aVdes   = getChan(At, Ahdr, AtAll, AtMaster, att.desiredVel,   'linear');
aVact   = getChan(At, Ahdr, AtAll, AtMaster, att.actualVel,    'linear');
aThrCmd = getChan(At, Ahdr, AtAll, AtMaster, att.throttleCmd,  'linear');
aThrPos = getChan(At, Ahdr, AtAll, AtMaster, att.throttlePos,  'linear');
aScale  = getChan(At, Ahdr, AtAll, AtMaster, att.speedScaling, 'linear');
aAcc    = getChan(At, Ahdr, AtAll, AtMaster, att.accAccelCmd,  'linear');
aMpc    = getChan(At, Ahdr, AtAll, AtMaster, att.mpcAccelCmd,  'linear');
aEn     = getChan(At, Ahdr, AtAll, AtMaster, att.accEnable,    'previous'); % boolean
aOppV   = getChan(At, Ahdr, AtAll, AtMaster, att.oppVelocity,  'linear');
aFollowDist = getChan(At, Ahdr, AtAll, AtMaster, att.followDistance, 'linear');

tA = AtMaster - At0;

% following distance is measured (channel above); following time is CALCULATED
% as distance / opponent velocity, unless overridden by a constant.
if isempty(cfg.followTimeConst)
    aFollowTime = aFollowDist ./ aOppV;
    aFollowTime(abs(aOppV) < 0.1) = NaN;   % guard divide-by-~zero at low speed
else
    aFollowTime = cfg.followTimeConst * ones(size(tA));
end

figure('Color','w','Name','Attacker — R1 ACC Test', ...
       'Position',[100 40 900 950]);

axA(1) = subplot(7,1,1);
plot(tA, aVdes, 'b--', 'LineWidth', 1.2); hold on;
plot(tA, aVact, 'k',   'LineWidth', 1.2); hold off; grid on;
ylabel('Vel [m/s]'); title('Attacker: Desired vs Actual Velocity');
legend({'Desired','Actual'}, 'Location','best');

axA(2) = subplot(7,1,2);
plot(tA, aScale, 'Color',[0.4 0.2 0.6], 'LineWidth', 1.0); grid on;
ylabel('Speed Scaling'); title('Speed Scaling');

axA(3) = subplot(7,1,3);
plot(tA, aAcc, 'LineWidth', 1.0, 'Color',[0.85 0.33 0.10]); hold on;
plot(tA, aMpc, 'LineWidth', 1.0, 'Color',[0.00 0.45 0.74]); hold off; grid on;
ylabel('Accel [m/s^2]'); title('ACC vs MPC Acceleration Commands');
legend({'ACC','MPC'}, 'Location','best');

axA(4) = subplot(7,1,4);
stairs(tA, aEn, 'k', 'LineWidth', 1.2); grid on;
ylabel('ACC Enable');
ylim([-0.1 1.1]); yticks([0 1]);
title('Distance ACC Enable');

axA(5) = subplot(7,1,5);
plot(tA, aFollowDist, 'Color',[0.30 0.50 0.70], 'LineWidth', 1.0); grid on;
ylabel('Dist [m]'); title('Following Distance');

axA(6) = subplot(7,1,6);
plot(tA, aFollowTime, 'Color',[0.60 0.40 0.10], 'LineWidth', 1.0); grid on;
ylabel('Time [s]');
if isempty(cfg.followTimeConst)
    title('Calculated Following Time');
else
    title(sprintf('Following Time (constant = %.3g s)', cfg.followTimeConst));
end

axA(7) = subplot(7,1,7);
plot(tA, aThrCmd, 'Color',[0.85 0.33 0.10], 'LineWidth', 1.0); hold on;
plot(tA, aThrPos, 'Color',[0.30 0.30 0.30], 'LineWidth', 1.0); hold off; grid on;
ylabel('Throttle [%]'); xlabel('Time [s]');
title('Throttle: Command vs Measured');
legend({'Command','Measured'}, 'Location','best');

linkaxes(axA, 'x');

%% ===================== LOCAL FUNCTIONS =====================
function [Traw, headers, tAll] = loadFile(path, timeCandidates, timeUnits)
    if ~isfile(path), error('CSV not found: %s', path); end
    try
        Traw = readtable(path, 'VariableNamingRule','preserve');
    catch
        Traw = readtable(path);
    end
    headers = Traw.Properties.VariableNames;
    timeCol = resolveTimeCol(headers, timeCandidates, path);
    tAll = convertTime(toNumericCol(Traw.(timeCol)), timeUnits);
end

function timeCol = resolveTimeCol(headers, candidates, path)
% Exports name the time column differently ('__time' from PlotJuggler, 'time'
% from others), so take the first candidate actually present in this file.
    if ischar(candidates) || isstring(candidates), candidates = cellstr(candidates); end
    for k = 1:numel(candidates)
        if ismember(candidates{k}, headers)
            timeCol = candidates{k}; return;
        end
    end
    error(['No time column found in %s.\nTried: %s\nAvailable columns:\n  %s'], ...
          path, strjoin(candidates, ', '), strjoin(headers, '\n  '));
end

function tM = masterTime(tAll)
    tM = unique(tAll(isfinite(tAll)));
    if numel(tM) < 2, error('Not enough valid timestamps in a file.'); end
end

function vi = getChan(Traw, headers, tAll, tq, colName, method)
    if nargin < 6 || isempty(method), method = 'linear'; end
    if ~ismember(colName, headers)
        warning('Channel "%s" not found; plotting as blank.', colName);
        vi = nan(size(tq)); return;
    end
    [t, v] = cleanChannel(tAll, toNumericCol(Traw.(colName)));
    if isscalar(unique(v))
        warning('Channel "%s" is constant (= %g) over the whole log.', colName, v(1));
    end
    vi = interp1(t, v, tq, method);
    vi = fillmissing(vi, 'nearest');
end

function [t, v] = cleanChannel(tAll, vAll)
    good = isfinite(tAll) & isfinite(vAll);
    t = tAll(good); v = vAll(good);
    if numel(t) < 2
        error('A channel has fewer than 2 valid samples after cleaning.');
    end
    [t, ~, ic] = unique(t);
    v = accumarray(ic, v, [], @mean);
end

function x = toNumericCol(c)
    if isnumeric(c), x = double(c(:)); return; end
    if iscell(c) || isstring(c), x = str2double(c(:)); return; end
    x = double(c(:));
end

function t = convertTime(t, units)
    switch lower(units)
        case 'seconds'
        case 'nanoseconds', t = t / 1e9;
        otherwise
            m = max(t(~isnan(t)));
            if ~isempty(m) && m > 1e11, t = t / 1e9; end
    end
end
