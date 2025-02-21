function W = plotWorkspaceWithPath(AdjTable, Parent, Path)
  
% Initilization
    numNodes = numel(AdjTable);
    source = [];
    target = [];
    
    
    for i = 1:numNodes
        for j = 1:numel(AdjTable{i})
            if AdjTable{i}(j) ~= i 
                source = [source, i];
                target = [target, AdjTable{i}(j)];
            end
        end
    end

    edgeTable = table(source', target', 'VariableNames', {'Source', 'Target'});
    edgeTable = unique(sortrows(sort(edgeTable.Variables, 2), 1), 'rows');
    W = graph(edgeTable(:, 1), edgeTable(:, 2));
    
    %% Plottingggg
    figure;
    h = plot(W, 'Layout', 'force', 'NodeLabel', 1:numNodes);
    hold on;
    
    if ~isempty(Path)
        pathEdgesSource = Path(1:end-1);
        pathEdgesTarget = Path(2:end);
        highlight(h, pathEdgesSource, pathEdgesTarget, 'EdgeColor', 'r', 'LineWidth', 2);
    end
    title('Workspace Graph with Highlighted Path');
    xlabel('X-axis');
    ylabel('Y-axis');
    hold off;
end