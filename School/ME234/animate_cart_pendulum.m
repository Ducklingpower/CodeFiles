function animate_cart_pendulum(x1, x2, x3, x4)
    % Inputs:
    % x1 - cart position
    % x2 - pendulum angle (radians)
    % x3 - cart velocity (not used in animation)
    % x4 - angular velocity (not used in animation)

    n = length(x1);
    if any([length(x2), length(x3), length(x4)] ~= n)
        error('All input vectors must be the same length');
    end

    % Parameters
    l = 1;                  % Distance to pendulum CoM
    pend_length = 2 * l;    % Total pendulum length
    cart_width = 1;
    cart_height = 0.5;
    wheel_radius = 0.1;
    ball_radius = 0.25;

    % Create figure
    figure;
    axis equal;
    grid on;
    xlim([-7 7]);
    ylim([-1 3]);
    xlabel('x');
    ylabel('y');
    title('Inverted Pendulum on a Cart');

    % Initialize cart
    cart = rectangle('Position', [x1(1)-cart_width/2, 0, cart_width, cart_height], ...
                     'FaceColor', [0.2 0.2 0.8]);

    % Initialize wheels
    wheel1 = rectangle('Position', [x1(1)-0.3-wheel_radius, -wheel_radius, ...
                      2*wheel_radius, 2*wheel_radius], ...
                      'Curvature', [1 1], 'FaceColor', 'k');
    wheel2 = rectangle('Position', [x1(1)+0.3-wheel_radius, -wheel_radius, ...
                      2*wheel_radius, 2*wheel_radius], ...
                      'Curvature', [1 1], 'FaceColor', 'k');

    % Initialize pendulum
    pendulum = line([0, 0], [0, 0], 'LineWidth', 4, 'Color', [0.8 0.1 0.1]);

    % Initialize pendulum mass (ball at the tip)
    pend_tip_x = x1(1) + pend_length * sin(x2(1));
    pend_tip_y = cart_height + pend_length * cos(x2(1));
    ball = rectangle('Position', [pend_tip_x - ball_radius, pend_tip_y - ball_radius, ...
                                  2 * ball_radius, 2 * ball_radius], ...
                     'Curvature', [1 1], 'FaceColor', 'black');

    % Animation loop
    for k = 1:n
        % Update cart
        cart.Position = [x1(k)-cart_width/2, 0, cart_width, cart_height];

        % Update wheels
        wheel1.Position = [x1(k)-0.3-wheel_radius, -wheel_radius, 2*wheel_radius, 2*wheel_radius];
        wheel2.Position = [x1(k)+0.3-wheel_radius, -wheel_radius, 2*wheel_radius, 2*wheel_radius];

        % Compute pendulum tip
        pend_x = x1(k) + pend_length * sin(x2(k));
        pend_y = cart_height + pend_length * cos(x2(k));

        % Update pendulum rod
        set(pendulum, 'XData', [x1(k), pend_x], 'YData', [cart_height, pend_y]);

        % Update pendulum tip mass (ball)
        ball.Position = [pend_x - ball_radius, pend_y - ball_radius, 2 * ball_radius, 2 * ball_radius];

        drawnow;
        pause(0.0001);
    end
end
