clc
close all
clear 
%% Part 1 plot enviroment

L1 = 4;
L2 = 4;
W  = 0.2; %  width
alpha = pi/4;
beta = pi/4;
xo = 0;
yo = 8.2;
r  = 0.1;

% plotEnvironment(L1, L2, W, alpha, beta, xo, yo, r)
% Animation
figure
frames = 300;
alpha = linspace(0,pi,frames);
beta  = linspace(0,4*pi,frames);

for i = 1:frames
plotEnvironment(L1, L2, W, alpha(i), beta(i), xo, yo, r)
TF = checkCollisionTwoLink(L1,L2,W,alpha(i),beta(i),xo,yo,r);
if TF ==1
    break
end
pause(0.0001)
clf
end

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

