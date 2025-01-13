% Eric Perez
% ME 145 Lab 4

function [Path] = computeBFSpath(AdjTable,start,goal)

    [~,numNodes]= size(AdjTable);
    if start > numNodes || goal > numNodes
        error('start or goal is not within range of workspace')
    end
    parents = nan(numNodes, 1);

    
    Q = [start];
    BFSNodesPlot = []; % nodes of BFS tree
    BFSAdjNodesPlot = []; % Adj nodes
   
    NodesPlot = []; % nodes for workspace
   AdjNodesPlot = []; % adj nodes

    parents(start) = 0;

    while ~isempty(Q)
        currentNode = Q(1);
        Q(1) = [];  % Remove the first value

        adjacentNodes = AdjTable{currentNode};

        [m,n] = size(adjacentNodes);
        for i = 1:n
            node = adjacentNodes(i);
            AdjNodesPlot(end+1) = node;
             NodesPlot(end+1) = currentNode;
             j = length(AdjNodesPlot);

           for k = 1:j             % looks for duplicate combinations
               if NodesPlot(end) ==  AdjNodesPlot(k)
                NodesPlot(end) = [];
                 AdjNodesPlot(end) = [];
                 weight = [];
                break
               end
           end
              
      
            
            if isnan(parents(node))
                parents(node) = currentNode;
                Q(end+1) = node;
                 BFSNodesPlot(end+1) = currentNode;
                BFSAdjNodesPlot(end+1) = node;
                
            end  
            if node == goal
                Path = [node]
                while parents(node) ~= 0
                    node = parents(node);
                    Path = [node,Path];
                end
                
           end
   
        end
    end

BFStreePlot = digraph(BFSNodesPlot,BFSAdjNodesPlot);
WorkSpacePlot = graph(NodesPlot,AdjNodesPlot);

L = plot(BFStreePlot);
figure
h = plot(WorkSpacePlot);
highlight(h,Path,'EdgeColor','g','NodeColor','g')
highlight(L,Path,'EdgeColor','g','NodeColor','g')
labelnode(h,[Path(1) Path(end)],{'start' 'end'})

end
