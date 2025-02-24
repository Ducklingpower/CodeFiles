function plotDistancePointToSegment(q, p1, p2)
    % Input:
    % q  - Point as a 2D vector [qx, qy]
    % p1 - Start point of the segment as [p1x, p1y]
    % p2 - End point of the segment as [p2x, p2y]
    
    % Vector from p1 to p2
    v = p2 - p1;
    
    % Vector from p1 to q
    w = q - p1;
    
    % Projection of w onto v, normalized by the length of v squared
    c1 = dot(w, v);
    c2 = dot(v, v);
    
    % Find the point on the line segment closest to q
    t = max(0, min(1, c1 / c2)); % Clamp t to the range [0, 1]
    
    % Closest point on the segment
    closestPoint = p1 + t * v;
    
    D = norm(closestPoint - q);
    % Plotting
    figure;
    hold on;
    grid on;
    
    % Plot the line segment
    plot([p1(1), p2(1)], [p1(2), p2(2)], 'b-', 'LineWidth', 2);
    text(p1(1), p1(2), 'p1', 'FontSize', 12, 'Color', 'blue');
    text(p2(1), p2(2), 'p2', 'FontSize', 12, 'Color', 'blue');
    
    % Plot the point q
    plot(q(1), q(2), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'red');
    text(q(1), q(2), 'q', 'FontSize', 12, 'Color', 'red');
    
    % Plot the closest point on the segment
    plot(closestPoint(1), closestPoint(2), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'green');
    text(closestPoint(1), closestPoint(2), 'Closest Point', 'FontSize', 12, 'Color', 'green');
    
    % Plot the line from q to the closest point
    plot([q(1), closestPoint(1)], [q(2), closestPoint(2)], 'k--', 'LineWidth', 1.5);
    
    % Labels and title
    title('Distance from Point to Line Segment');
    xlabel('X');
    ylabel('Y');
    legend('Line Segment', 'Point q', 'Closest Point on Segment', 'Distance Line');
    
    hold off;
end
