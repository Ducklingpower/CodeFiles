clc
clear 
close all
%% Inputs
AdjTable  ={[2 10],[3 11 1],[4 2],[5 3],[6 12 4], [7 13 5],[8 14 6], [9 7], ...
            [15 8], [16 11 1],[2 10 17],[13 6 5],[14 6 12],[8 13 7],[19 9],[20 17 10],...
            [21 16 11],[22 14],[23 15],[24 21 16],[25 20 17],[30 18],[32 19],[25 20],...
            [26 24],[27 25],[28 26],[29 27],[30 28],[31 22 29],[32 30],[23 31]};

vstart = 1;
vGoal  = 32;



%% Inputs 

AdjTable = { [2, 5],[1, 3, 6],[2, 4, 8],[3, 10],[1, 7]...
    ,[2,7, 8],[5, 6],[3, 6, 9],[8, 10],[4, 9] };    

vstart = 1;
vGoal  = 9;
%% Run functions

[Path,G,Parent] = computeBFSPath(AdjTable,vstart,vGoal);

plotPathOnBFSTree(AdjTable, Parent, Path);

plotWorkspaceFromAdjTable(AdjTable,Parent, Path);
