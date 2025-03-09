function adjacencyTable = createAdjacencyTable(coords, radius)

    n = size(coords, 1);

    adjacencyTable = cell(n, 2);

    adjacencyMatrix = zeros(n);

    
    for i = 1:n
        adjacencyTable{i, 1} = i; 
        adjacencyTable{i, 2} = [];

        for j = 1:n
            if i ~= j
                dist = sqrt((coords(i, 1) - coords(j, 1))^2 + (coords(i, 2) - coords(j, 2))^2);
                if dist <= radius
                    adjacencyTable{i, 2} = [adjacencyTable{i, 2}, j];
                    adjacencyMatrix(i, j) = 1;
                end
            end
        end
    end

G = graph(adjacencyMatrix);
figure;
plot(G, 'XData', coords(:,1), 'YData', coords(:,2), ...
     'MarkerSize', 3, 'LineWidth', 1.5, 'EdgeColor', 'k', ...
     'NodeLabel', []); 
title(['Graph Representation (Radius = ', num2str(radius), ')']);
xlabel('X');
ylabel('Y');
grid on;

end
