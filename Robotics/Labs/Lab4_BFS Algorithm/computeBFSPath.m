function [Path,G,Parent] = computeBFSPath(AdjTable, vstart, vgoal)
    % Compute the BFS tree and the graph representation
    [Parent, G] = computeBFSTree(AdjTable, vstart);
    
    % Initialize the path with the goal vertex
    Path = [];
    
    % Start from the goal and backtrack using the Parent vector
    current = vgoal;
    while current ~= vstart
        if Parent(current) == 0 % If no parent exists, vgoal is not reachable
            error('No path exists between vstart and vgoal.');
        end
        % Prepend the current node to the Path
        Path = [current, Path];
        % Move to the parent node
        current = Parent(current);
    end
    
    % Add the start node to the Path
    Path = [vstart, Path];
end