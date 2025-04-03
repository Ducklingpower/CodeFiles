clc
close all
clear

% --- Setup ---
port = "COM3";                 % Your Arduino COM port
baud = 9600;
s = serialport(port, baud);
configureTerminator(s, "LF");
flush(s);
pause(2);                      % Let Arduino reset

% --- Initialize Data ---
timeHistory = [];
angleHistory = [];
Tstart = tic;

% --- Plot Setup ---
figure;
xlabel("Time (s)");
ylabel("Servo Angle (°)");
title("Live Servo Response");
grid on;
ylim([0 180]);
hold on;

% --- Loop to send random angles and plot response ---
numSteps = 50;

theta = [0 180 0 180 0 180 0 180 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5 0 5];

for i = 1:numSteps
    % angle = randi([30, 150]);
    angle = theta(i);
    writeline(s, num2str(angle));

    % Read echo back from Arduino
   
    response = readline(s);
    servoAngle = str2double(response);

    % Store data
    timeHistory(end+1) = toc(Tstart);
    angleHistory(end+1) = servoAngle;

    % Plot live
    plot(timeHistory, angleHistory, 'b.-');
    drawnow;

    
end

% --- Cleanup ---
clear s
