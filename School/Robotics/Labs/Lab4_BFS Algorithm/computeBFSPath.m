function [Path,G,Parent] = computeBFSPath(AdjTable, vstart, vgoal)
    [Parent, G] = computeBFSTree(AdjTable, vstart);
    Path = [];
    current = vgoal;
    while current ~= vstart
        if Parent(current) == 0
            error('No path exists between vstart and vgoal.');
        end
        
        Path = [current, Path];
        current = Parent(current);
    end

    Path = [vstart, Path];
end