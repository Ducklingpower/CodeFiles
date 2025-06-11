function animate_cart_pendulum(x1, x2, x3, x4)
    % Animate an inverted pendulum on a cart.
    % x1 = cart position
    % x2 = pendulum angle (in radians), with 0 = upright
    % x3, x4 = velocities (not used in animation)

    % Convert from upright-linearized (theta = 0) to standard (theta = pi is down)


    n = length(x1);
    if any([length(x2), length(x3), length(x4)] ~= n)
        error('All input vectors must be the same length');
    end

    % Parameters
    l = 1;                    % Distance to CoM
    pend_length = 2 * l;      % Full pendulum length
    cart_width = 1.0;
    cart_height = 0.4;
    wheel_radius = 0.1;
    ball_radius = 0.3;

    % Set up figure
    figure;
    axis equal;
    grid on;
    xlim([-15 15]);
    ylim([-5.5 5.5]);
    xlabel('x');
    ylabel('y');
    title('Inverted Pendulum on a Cart (Reversed X-Axis Swing)');

    % Draw static track for visual stability
    line([-7 7], [0 0], 'Color', [0.6 0.6 0.6], 'LineStyle', '--');

    % Initialize cart
    cart = rectangle('Position', [x1(1)+ pend_length * sin(x2(1))-cart_width/2, 0, cart_width, cart_height], ...
                     'FaceColor', [0.2 0.2 0.8]);

    % Initialize wheels
    wheel1 = rectangle('Position', [x1(1)+ pend_length * sin(x2(1))-0.3-wheel_radius, -wheel_radius, ...
                                    2*wheel_radius, 2*wheel_radius], ...
                       'Curvature', [1 1], 'FaceColor', 'k');
    wheel2 = rectangle('Position', [x1(1)+ pend_length * sin(x2(1))+0.3-wheel_radius, -wheel_radius, ...
                                    2*wheel_radius, 2*wheel_radius], ...
                       'Curvature', [1 1], 'FaceColor', 'k');

    % Initialize pendulum rod
    pendulum = line([0, 0], [0, 0], 'LineWidth', 4, 'Color', [0.8 0.1 0.1]);

    % Initialize pendulum mass (tip)
    tip_x = x1(1);  % ← REVERSED
    tip_y = cart_height + pend_length * cos(x2(1));
    ball = rectangle('Position', [tip_x - ball_radius, tip_y - ball_radius, ...
                                  2 * ball_radius, 2 * ball_radius], ...
                     'Curvature', [1 1], 'FaceColor', 'black');

    % Animation loop
    for k = 1:n
        % Cart position
        cx = x1(k)+ pend_length * sin(x2(k));
        cy = 0;

        % Pendulum tip (REVERSED x direction)
        tip_x = x1(k) ;  % ← REVERSED
        tip_y = cart_height + pend_length * cos(x2(k));

        % Update cart and wheels
        cart.Position = [cx - cart_width/2, cy, cart_width, cart_height];
        wheel1.Position = [cx - 0.3 - wheel_radius, -wheel_radius, 2*wheel_radius, 2*wheel_radius];
        wheel2.Position = [cx + 0.3 - wheel_radius, -wheel_radius, 2*wheel_radius, 2*wheel_radius];

        % Update pendulum rod (from cart center to reversed tip)
        pendulum.XData = [cx, tip_x];
        pendulum.YData = [cart_height, tip_y];

        % Update pendulum tip mass
        ball.Position = [tip_x - ball_radius, tip_y - ball_radius, ...
                         2 * ball_radius, 2 * ball_radius];

        drawnow;
        pause(0.01);  % adjust speed here
    end
end
