hFig = figure;
ax = axes(hFig);
x = linspace(0, 10, 100);
y = sin(x);
plot(ax, x, y, 'o-'); hold on; % Original plot

% Create a figure for live plotting
hFig2 = figure;
live_ax = axes(hFig2);
live_plot = plot(live_ax, NaN, NaN, 'r.-', 'MarkerSize', 10);
xlim(live_ax, [0, 10]); % Set x-axis limits
ylim(live_ax, [0, 200]); % Adjust based on expected values
title(live_ax, 'Live Calculation Plot');
xlabel(live_ax, 'X Value');
ylabel(live_ax, 'Calculated Value');

% Set mouse move callback
set(hFig, 'WindowButtonMotionFcn', @(src, event) mouseMove(live_plot));

function mouseMove(live_plot)
    C = get(gca, 'CurrentPoint');  % Get mouse position
    x_hover = C(1,1);
    y_hover = C(1,2);
    
    % Example Calculation: f(x, y) = x^2 + y^2
    result = x_hover^2 + y_hover^2;
    
    % Export variables to workspace
    assignin('base', 'hover_x', x_hover);
    assignin('base', 'hover_y', y_hover);
    assignin('base', 'hover_calc', result);
    
    % Update title dynamically
    title(gca, sprintf('X: %.2f, Y: %.2f | Calc: %.2f', x_hover, y_hover, result));
    
    % Update live plot
    xData = get(live_plot, 'XData');
    yData = get(live_plot, 'YData');
    
    % Append new data point
    xData = [xData, x_hover];
    yData = [yData, result];
    
    % Update plot
    set(live_plot, 'XData', xData, 'YData', yData);
    drawnow; % Force MATLAB to update the plot immediately
end
