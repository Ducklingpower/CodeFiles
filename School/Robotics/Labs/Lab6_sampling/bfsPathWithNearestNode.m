function path = bfsPathWithNearestNode(q1, q2, coords, adjacencyTable)
 
    n = size(coords, 1);

  
    [~, idxQ1] = ismember(q1, coords, 'rows');
    if idxQ1 == 0
        idxQ1 = findNearestNode(q1, coords);
        coords = [coords; q1]; 
        adjacencyTable{end+1, 1} = n + 1;
        adjacencyTable{end, 2} = adjacencyTable{idxQ1, 1};
        adjacencyTable{idxQ1, 2} = [adjacencyTable{idxQ1, 2}, n + 1];
        n = n + 1; 
    end

    [~, idxQ2] = ismember(q2, coords, 'rows');
    if idxQ2 == 0
        idxQ2 = findNearestNode(q2, coords);
        coords = [coords; q2]; 
        adjacencyTable{end+1, 1} = n + 1;
        adjacencyTable{end, 2} = adjacencyTable{idxQ2, 1}; 
        adjacencyTable{idxQ2, 2} = [adjacencyTable{idxQ2, 2}, n + 1];
        n = n + 1; 
    end
    path = bfsSearch(idxQ1, idxQ2, adjacencyTable);
end


function nearestIdx = findNearestNode(point, coords)
    distances = sqrt(sum((coords - point).^2, 2)); % Euclidean distance
    [~, nearestIdx] = min(distances);
end


function path = bfsSearch(startIdx, goalIdx, adjacencyTable)
    % Initialize BFS structures
    queue = [startIdx];
    visited = false(length(adjacencyTable), 1);
    visited(startIdx) = true;
    parent = zeros(length(adjacencyTable), 1);

    % BFS Loop
    while ~isempty(queue)
        current = queue(1);
        queue(1) = []; % Dequeue

        % If goal is reached, reconstruct the path
        if current == goalIdx
            path = reconstructPath(parent, goalIdx);
            return;
        end

        % Explore neighbors
        neighbors = adjacencyTable{current, 2};
        for i = 1:length(neighbors)
            neighbor = neighbors(i);
            if ~visited(neighbor)
                visited(neighbor) = true;
                parent(neighbor) = current;
                queue = [queue, neighbor]; % Enqueue
            end
        end
    end
    path = []; % No path found
end


function path = reconstructPath(parent, goalIdx)
    path = [];
    while goalIdx ~= 0
        path = [goalIdx, path]; % Prepend node to path
        goalIdx = parent(goalIdx);
    end
end
