function plotPathOnBFSTree(AdjTable, Parent, Path)
    % Number of nodes
    numNodes = numel(AdjTable);
    
    % Initialize source and target arrays for edges in the BFS tree
    source = [];
    target = [];
    for i = 1:numNodes
        if Parent(i) ~= 0 % Ignore nodes with no parent (root node or disconnected)
            source = [source, Parent(i)];
            target = [target, i];
        end
    end
    
    % Create the graph object for the BFS tree
    BFS_Tree = digraph(source, target);
    
    % Extract edges in the path
    pathEdgesSource = Path(1:end-1);
    pathEdgesTarget = Path(2:end);
    
    % Create a logical mask for edges in the path
    isPathEdge = ismember([source', target'], [pathEdgesSource', pathEdgesTarget'], 'rows');
    
    % Plot the BFS tree
    figure;
    h = plot(BFS_Tree, 'Layout', 'layered', 'ArrowSize', 10);
    hold on;
    
    % Highlight the edges in the path
    highlight(h, pathEdgesSource, pathEdgesTarget, 'EdgeColor', 'r', 'LineWidth', 2);
    
    % Customize node labels
    labelnode(h, 1:numNodes, string(1:numNodes));
    
    % Add title and labels
    title('BFS Tree with Highlighted Path');
    xlabel('X-axis');
    ylabel('Y-axis');
    hold off;
end
