% Eric Perez
% ME 145 Lab 4

function [parents] = computeBFStreeHelp(AdjTable,start)
 % Number of nodes in the graph, assuming each index has a cell
    numNodes = numel(AdjTable);

    % Initialize the parent array with NaNs to indicate no parent
    parents = nan(numNodes, 1);

    % Create a queue for BFS
    Q = [start];

    % Set the parent of the start node as 0 or itself (here we use 0 to denote the root)
    parents(start) = 0;

    % While there are nodes in the queue
    while ~isempty(Q)
        % Dequeue the first node
        currentNode = Q(1);
        Q(1) = [];  % Remove the first element

        % Get all adjacent nodes from the adjacency table
        adjacentNodes = AdjTable{currentNode};

        % Iterate over each adjacent node
        [m,n] = size(adjacentNodes);
        for i = 1:n
            node = adjacentNodes(i);
            % Check if the node has not been visited
            if isnan(parents(node))
                % Mark the parent of the node
                parents(node) = currentNode;
                % Enqueue the node
                Q(end+1) = node;
            end
        end
    end
end