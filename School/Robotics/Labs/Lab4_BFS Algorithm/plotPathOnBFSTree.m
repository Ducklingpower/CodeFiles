function plotPathOnBFSTree(AdjTable, Parent, Path)
% Initialize
    numNodes = numel(AdjTable);
    source = [];
    target = [];
    for i = 1:numNodes
        if Parent(i) ~= 0 
            source = [source, Parent(i)];
            target = [target, i];
        end
    end
 
    BFS_Tree = digraph(source, target);
    pathEdgesSource = Path(1:end-1);
    pathEdgesTarget = Path(2:end);
    isPathEdge = ismember([source', target'], [pathEdgesSource', pathEdgesTarget'], 'rows');
    
  %% Plotting
    figure;
    h = plot(BFS_Tree, 'Layout', 'layered', 'ArrowSize', 10);
    hold on;
    highlight(h, pathEdgesSource, pathEdgesTarget, 'EdgeColor', 'r', 'LineWidth', 2);
    labelnode(h, 1:numNodes, string(1:numNodes));
    title('BFS Tree with Highlighted Path');
    xlabel('X-axis');
    ylabel('Y-axis');
    hold off;
end
