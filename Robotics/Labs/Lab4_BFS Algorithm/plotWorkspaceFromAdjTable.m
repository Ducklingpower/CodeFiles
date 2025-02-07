function W = plotWorkspaceWithPath(AdjTable, Parent, Path)
    % Number of nodes
    numNodes = numel(AdjTable);
    
    % Initialize source and target arrays for edges
    source = [];
    target = [];
    
    % Convert the adjacency table into source-target edge pairs
    for i = 1:numNodes
        for j = 1:numel(AdjTable{i})
            if AdjTable{i}(j) ~= i % Remove self-loops
                source = [source, i];
                target = [target, AdjTable{i}(j)];
            end
        end
    end
    
    % Remove duplicate edges
    edgeTable = table(source', target', 'VariableNames', {'Source', 'Target'});
    edgeTable = unique(sortrows(sort(edgeTable.Variables, 2), 1), 'rows');
    
    % Recreate the graph object
    W = graph(edgeTable(:, 1), edgeTable(:, 2));
    
    % Plot the workspace graph
    figure;
    h = plot(W, 'Layout', 'force', 'NodeLabel', 1:numNodes);
    hold on;
    
    % Highlight the edges in the path
    if ~isempty(Path)
        % Extract source and target for the path
        pathEdgesSource = Path(1:end-1);
        pathEdgesTarget = Path(2:end);
        
        % Highlight path on the graph
        highlight(h, pathEdgesSource, pathEdgesTarget, 'EdgeColor', 'r', 'LineWidth', 2);
    end
    
    % Customize the plot
    title('Workspace Graph with Highlighted Path');
    xlabel('X-axis');
    ylabel('Y-axis');
    hold off;
end