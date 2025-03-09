function plotGraphWithPath(coords, adjacencyTable, path)

    n = size(coords, 1);
    adjacencyMatrix = zeros(n);

    for i = 1:n
        neighbors = adjacencyTable{i, 2};
        for j = 1:length(neighbors)
            adjacencyMatrix(i, neighbors(j)) = 1;
        end
    end

    % Create and plot the full graph (black edges)
    G = graph(adjacencyMatrix);
    figure;
    hold on;
    plot(G, 'XData', coords(:,1), 'YData', coords(:,2), ...
         'MarkerSize', 3, 'LineWidth', 1.5, 'EdgeColor', 'k', ...
         'NodeLabel', []); % Plot full graph in black

    % If a path is found, highlight it
    if ~isempty(path) && length(path) > 1
        % Extract only the path nodes' coordinates
        pathCoords = coords(path, :);

        % Plot the path separately using `plot` instead of `graph`
        plot(pathCoords(:,1), pathCoords(:,2), 'r-', 'LineWidth', 1); % Red line for path
        scatter(pathCoords(:,1), pathCoords(:,2), 20, 'ro', 'filled'); % Highlight path nodes
    end

    title('Graph Representation with Shortest Path');
    xlabel('X');
    ylabel('Y');
    grid on;
    hold off;
end
