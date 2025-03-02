clc
close all
clear
%% Part 1 Compute computeGridSukharev

% Varify test
n = 100; 
Grid = computeGridSukharev(n); %Functions plots for me 

% error test
n = 56; 
Grid = computeGridSukharev(n);

clear
clcD
%% Part 2 ComputeGridRandom

%Varify test
n = 100;
Grid = computeGridRandom(n);

%error test
n = 1:100;
Grid = computeGridRandom(n);

clear
clc
%% Part 3 CompueGridHalton

% varify test
n = 100;
b1 = 2;
b2 = 3;
Grid = computeGridHalton(n,b1,b2);

% error test
n = 100;
b1 = 4;
b2 = 8;
Grid = computeGridHalton(n,b1,b2);

clear
clc
%% Part 4 IsPointInConvexPolygon

% Varify 1 not in Polygon
P = [1 1; 0 1; 0 0; 1 0];
q = [3 3];
TF = isPointinConvexPolygon(q,P);

tiledlayout(1,2)
nexttile
fill(P(:,1),P(:,2),[rand(1) rand(1) rand(1)])
hold on
plot(q(1),q(2),'*',LineWidth=3)
xlim([-1 4])
ylim([-1 4])
grid on 
title("True of False Value = " + TF)

% Varify 2 in Polygon
P = [1 1; 0 1; 0 0; 1 0];
q = [0.5 0.75];
TF = isPointinConvexPolygon(q,P);

nexttile
fill(P(:,1),P(:,2),[rand(1) rand(1) rand(1)])
hold on
plot(q(1),q(2),'*',LineWidth=3)
xlim([-1 2])
ylim([-1 2])
grid on 
title("True of False Value = " + TF)
clc
clear

% Error check

% % erorr = too many polygons
% P1 = [1 1; 0 1; 0 0; 1 0];
% P2 = [2 2; 0 1; 2 1; 1 0];
% P(:,:,1) = P1;
% P(:,:,2) = P2;
% q = [0.5 0.75];
% TF = isPointinConvexPolygon(q,P);

% error = not 2d point
P = [1 1; 0 1; 0 0; 1 0];
q = [3 3 3];
TF = isPointinConvexPolygon(q,P);


%% Part 5

% Varify check
p1 = [0 0];
p2 = [5 5];
p3 = [2 0];
p4 = [7 9];

TF = doTwoSegmentsIntersect(p1,p2,p3,p4)

%Varify check 
p1 = [0 0];
p2 = [5 5];
p3 = [2 0];
p4 = [7 2];

TF = doTwoSegmentsIntersect(p1,p2,p3,p4)


% error check
p1 = [0 0 1];
p2 = [5 5 2];
p3 = [2 0 1];
p4 = [7 2 4];

TF = doTwoSegmentsIntersect(p1,p2,p3,p4)

%% Part 6

P2 = [1 1; 0 1; 0 0; 1 0];
P1 = [2 0.5+3; 0 0.5+3; -1 -1+3; 2 2];

P(:,:,1) = P1;
P(:,:,2) = P2;

for j = 1:length(P(1,1,:))
    X = P(:,1,j);
    Y = P(:,2,j);
    fill(X, Y, [rand(1) rand(1) rand(1)]);
    hold on
    grid on
end

TF = doTwoConvexPolygonsIntersect(P1,P2);

title("The TF value = "+ TF)

% Errorr check 

P2 = [1 1; 0 1; 0 0; 1 0];
P1 = [1 1; 1 0];

TF = doTwoConvexPolygonsIntersect(P1,P2);

title("The TF value = "+ TF)