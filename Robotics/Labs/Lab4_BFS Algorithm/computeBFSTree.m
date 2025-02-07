function [Parent,G] = computeBFSTree(AdjTable,vStart)


%% Intilize

Parent = nan(1,length(AdjTable));
Parent(vStart) = 0;

Que = [];
Que(1) = vStart;

Node   = [];
Branch = [];

while length(Que)>0
    vCurrent = Que(1);
    Que(1) = [];
    AttatchedNodes = AdjTable{vCurrent};
    
    for i = 1:length(AttatchedNodes)
        visit = AttatchedNodes(i);


        if isnan(Parent(visit(1))) 
            Parent(visit(1)) = vCurrent;
            Que(end+1) = visit(1);


            Node(end+1)   = vCurrent;
            Branch(end+1) = visit;
        end
    end
end

G = digraph(Node,Branch);
end