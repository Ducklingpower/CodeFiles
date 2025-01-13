% Eric Perez
% ME 145 Lab 4

function [parents] = computeBFStree(AdjTable,start)

    [~,numNodes]= size(AdjTable);

     if start > numNodes
        error('start or goal is not within range of workspace')
     end

    parent = nan(numNodes, 1);
    
    Q = [start];
    S = [];
    T = [];

    parent(start) = 0;


    while ~isempty(Q)
        currentNode = Q(1);
        Q(1) = [];  % Remove the first value

        adjacentNodes = AdjTable{currentNode};

        [m,n] = size(adjacentNodes);
        for i = 1:n
            node = adjacentNodes(i);
            
            if isnan(parent(node))
                parent(node) = currentNode;
                Q(end+1) = node;
                S(end+1) = currentNode;
                T(end+1) = node;
            end
        end
    end

    parents = parent';
G = digraph(S,T);
plot(G)
end







