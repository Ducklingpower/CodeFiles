clc
close all
clear 
%% Part 1 plot enviroment
% plotEnvironment(L1, L2, W, alpha, beta, xo, yo, r)

figure
L1 = 4;
L2 = 4;
W  = 0.2; %  width
xo = 2;
yo = -1;
r  = 2;

alpha = pi/6;
beta  = pi/2;

plotEnvironment(L1, L2, W, alpha, beta, xo, yo, r)
[TF1,TF2] = checkCollisionTwoLink(L1,L2,W,alpha,beta,xo,yo,r)


%% Obstcile detection

L1 = 4;
L2 = 4;
W  = 0.2; %  width
alpha = 0;
beta =  0;
xo = 0;
yo = 3;
r  = 2;

TF = checkCollisionTwoLink(L1,L2,W,alpha,beta,xo,yo,r);

%% Sampling
L1 = 4;
L2 = 4;
W  = 0.2; %  width
alpha = 0;
beta =  0;
xo = 0;
yo = 3;
r  = 2;
n = 20^2;
 sampling_method = "Sukharev";
%sampling_method = "Halton";
% sampling_method = "Random";
[grid,blue] = plotSampleConfigurationSpaceTwoLink(L1,L2,W,xo,yo,r,sampling_method,n);

%% Running interactive animatioon
L1 = 4;
L2 = 10;
W  = 0.2; %  width
alpha = 0;
beta =  0;
xo = 4;
yo = 4;
r  = 2;
n = 100^2;

%%

L1 = 5;
L2 = 5;
W  = 0.2; %  width
alpha = 0;
beta =  0;
xo = 3;
yo = 6;
r  = 2;
n = 100^2;
 % sampling_method = "Sukharev";
%sampling_method = "Halton";
sampling_method = "Random";
LiveHoverPlot(L1,L2,W,xo,yo,r,n,sampling_method)

%%

[grid,blue] = plotSampleConfigurationSpaceTwoLink(L1,L2,W,xo,yo,r,sampling_method,n);

%%
adjacencyTable = createAdjacencyTable(blue, 0.15);

q1 = [0.5,2];
q2 = [-3,-3];
path = bfsPathWithNearestNode(q1,q2, blue, adjacencyTable);

plotGraphWithPath(blue, adjacencyTable, path)