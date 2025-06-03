% === CONFIGURATION ===
port = "COM4";           % Replace with your Arduino COM port
baudRate = 115200;
numPoints = 500;
updateInterval = 5;

% === SERIAL SETUP ===
s = serialport(port, baudRate);
flush(s);

% === DATA BUFFER ===
dataBuffer = NaN(numPoints, 4);
sampleCounter = 0;

% === COLOR MAP ===
colors = [...
    0.7  0    1  ;  % neon purple
    0    1    0.3;  % neon green
    0.3  0.8  1  ;  % neon blue
    1    1    1  ]; % white

% === LABELS & PLOT SETUP ===
labels = ["Displacement 1 (cm)", "Displacement 2 (cm)", ...
          "Relative Velocity", "Servo Angle (deg)"];
ylims = [0 15; 3 13; -2 3; 50 100];

figure('Name', 'Live Suspension Data', 'NumberTitle', 'off', 'Color', 'k');
tiledlayout(2,2);

plots = gobjects(1,4);
axesHandles = gobjects(1,4);

for i = 1:4
    axesHandles(i) = nexttile;
    plots(i) = plot(NaN(numPoints, 1), 'Color', colors(i,:), 'LineWidth', 1.5);
    title(labels(i), 'Color', 'w');
    ylabel(labels(i), 'Color', 'w');
    xlabel("Sample", 'Color', 'w');
    ylim(axesHandles(i), ylims(i,:));
    grid on;

    % Black background, white axes
    set(axesHandles(i), 'Color', 'k', ...
                        'XColor', 'w', ...
                        'YColor', 'w', ...
                        'GridColor', [0.4 0.4 0.4]);
end

% === LIVE LOOP ===
while true
    try
        line = readline(s);
        vals = sscanf(line, '%f\t%*f\t%f\t%*f\t%f\t%f');
        % %f -> disp1
        % %*f -> skip vel1
        % %f -> disp2
        % %*f -> skip vel2
        % %f -> relative_velocity
        % %f -> servoAngle

        if numel(vals) == 4
            dataBuffer = [dataBuffer(2:end, :); vals'];
            sampleCounter = sampleCounter + 1;

            if mod(sampleCounter, updateInterval) == 0
                for i = 1:4
                    set(plots(i), 'YData', dataBuffer(:, i), 'XData', 1:numPoints);
                end
                drawnow limitrate;
            end
        end
    catch ME
        disp("Serial read error:");
        disp(ME.message);
        break;
    end
end

