function Path = computeBug2(Pstart, Pgoal, Obsticle, stepsize)
% COMPUTEBUG1 - Computes the path of a robot using Bug1 algorithm.
% Pstart: Starting point [x, y].
% Pgoal: Goal point [x, y].
% Obsticle: 3D matrix representing obstacles.
% stepsize: Step size for moving towards the goal.

%% Initialization
x1 = Pstart(1);
y1 = Pstart(2);
x2 = Pgoal(1);
y2 = Pgoal(2);

Pcurrent = Pstart;
Path = Pstart;

CurrentObsticle = 0;

for i = 1:length(Obsticle(:, 1, 1)) + 2
    % Check if close enough to the goal
    if abs(Pcurrent(1) - Pgoal(1)) < stepsize * 1.5 && abs(Pcurrent(2) - Pgoal(2)) < stepsize * 1.5
        break;
    end

    %% Check line intersection with obstacle segments
    Counter = 1:length(Obsticle(:, 1, 1)) + 1;
    Counter(end) = 1; % Close the loop

    for j = 1:length(Obsticle(1, 1, :))
        if j == CurrentObsticle
            if j == length(Obsticle(1, 1, :))
                j = j + 1;
            end
        else
            for i = 1:length(Obsticle(:, 1, 1))
                % Line parameters
                x1 = Pcurrent(1);
                y1 = Pcurrent(2);
                x2 = Pgoal(1);
                y2 = Pgoal(2);

                % Obstacle segment endpoints
                P1 = Obsticle(Counter(i), :, j);
                P2 = Obsticle(Counter(i + 1), :, j);

                x3 = P1(1); y3 = P1(2);
x4 = P2(1); y4 = P2(2);

                denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

                % Check for parallel lines
                if denominator == 0
                    intersection(i, :, j) = [NaN, NaN];
                    d(i, j) = 0;
                else
                    t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denominator;
                    u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denominator;

                    if u >= 0 && u <= 1
                        intersect_x = x1 + t * (x2 - x1);
                        intersect_y = y1 + t * (y2 - y1);
                        intersection(i, :, j) = [intersect_x, intersect_y];
                        d(i, j) = norm([x1, y1] - [intersect_x, intersect_y]);
                    else
                        intersection(i, :, j) = [NaN, NaN];
                        d(i, j) = NaN;
                    end
                end
            end

            % Determine nearest obstacle hit
            if all(isnan(d(:, j)), 'all')
                Obsticle_Hit = [NaN, NaN];
            else
                finder = find(min(d(:, j)) == d(:, j));
                Obsticle_Hit = intersection(finder, :, j);
                Obsticle_Hit = Obsticle_Hit(1, :);
                PNext = Obsticle_Hit;
                CurrentObsticle = j;
                CurrentSegmentNumber = [Counter(finder), Counter(finder + 1)];

                if sqrt((Pgoal(1) - Pcurrent(1))^2 + (Pgoal(2) - Pcurrent(2))^2) <= ...
                   sqrt((PNext(1) - Pcurrent(1))^2 + (PNext(2) - Pcurrent(2))^2)
                    Obsticle_Hit = [NaN, NaN];
                end
                break;
            end
        end
    end

    %% Path update logic
    if isnan(Obsticle_Hit)
        PNext = Pgoal;
        [a, b, c] = computeLineThroughTwoPoints(Pcurrent, PNext);

        x1 = Pcurrent(1);
        y1 = Pcurrent(2);

        x2 = PNext(1);
        y2 = PNext(2);

        PositionX = [x1, x2];
        PositionY = [y1, y2];

        Delta = sqrt((x1 - x2)^2 + (y1 - y2)^2) / stepsize;
        x = linspace(min(PositionX), max(PositionX), Delta);

        Pcurrent_to_PNext = @(x) (a / b) * x + c; % Direct line

        n = 1;
        for i = length(Path(:, 1)):length(Path(:, 1)) + length(x) - 1
            Path(i, 1) = x(n);
            Path(i, 2) = Pcurrent_to_PNext(x(n));
            n = n + 1;
        end
        break;
    end

    %% Update current point
    if PNext == Pcurrent
        PNext = [x2, y2];
    end

    [a, b, c] = computeLineThroughTwoPoints(Pcurrent, PNext);

    x1 = Pcurrent(1);
    y1 = Pcurrent(2);

    x2 = PNext(1);
    y2 = PNext(2);

    PositionX = [x1, x2];
    PositionY = [y1, y2];

    Delta = sqrt((x1 - x2)^2 + (y1 - y2)^2) / stepsize;
    x = linspace(min(PositionX), max(PositionX), Delta);

    Pcurrent_to_PNext = @(x) (a / b) * x + c; % Direct line

    n = 1;
    for i = length(Path(:, 1)):length(Path(:, 1)) + length(x) - 1
        Path(i, 1) = x(n);
        Path(i, 2) = Pcurrent_to_PNext(x(n));
        n = n + 1;
    end

    Pcurrent = Path(end, :);

    if abs(Pcurrent(1) - Pgoal(1)) < stepsize * 1.5 && abs(Pcurrent(2) - Pgoal(2)) < stepsize * 1.5
        break;
    end
end

%% Visualization
figure;
for j = 1:length(Obsticle(1, 1, :))
    hold on;
    X = Obsticle(:, 1, j);
    Y = Obsticle(:, 2, j);
    fill(X, Y, [0.8, 0.7, 0.8]);
    xlim([-10, 10]);
    ylim([-10, 10]);
    grid on;
    axis square;
end
plot(Path(:, 1), Path(:, 2), "o");
hold on;
plot(Pstart(1), Pstart(2), "*");
hold on;
plot(Pgoal(1), Pgoal(2), "*");
grid on;
legend("Path", "Start", "Goal");

end

