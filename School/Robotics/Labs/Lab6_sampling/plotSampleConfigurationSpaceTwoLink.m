function Grid = plotSampleConfigurationSpaceTwoLink(L1,L2,W,xo,yo,r,sampling_method,n)
%% Define method and obtaining grid
if strcmp(sampling_method, 'Sukharev')
    Grid = computeGridSukharev(n);
    Grid = Grid';
elseif strcmp(sampling_method, 'Random')
    Grid = computeGridRandom(n);

elseif strcmp(sampling_method, 'Halton')
    Grid = computeGridHalton(n);

else
    error("Unknown sampling method")
end

%% Defining possible configuration expansion

alpha_net = (Grid(:,1) * 2 - 1) * pi;
beta_net = (Grid(:,2) * 2 - 1) * pi;


%% Define Geometry
for i =1:length(alpha_net)

alpha = alpha_net(i);
beta = beta_net(i);
% Position
x1 = L1 .* cos(alpha);
y1 = L1 .* sin(alpha);

x2 = x1 + L2 .* cos(alpha + beta);
y2 = y1 + L2 .* sin(alpha + beta);

% Define link 1 body

xx1 = 0 - W.*cos(alpha-pi/2);
xx2 = 0 - W.*cos(alpha+pi/2);
xx4 = x1 + W.*cos(alpha+pi/2);
xx3 = x1 + W.*cos(alpha-pi/2);

yy1 = 0 - W .*sin(alpha-pi/2);
yy2 = 0 - W .*sin(alpha+pi/2);
yy3 = y1 + W .*sin(alpha-pi/2);
yy4 = y1 + W .*sin(alpha+pi/2);

Link1 = [[xx1 xx2 xx3 xx4]' [yy1 yy2 yy3 yy4]'];

% Define Body Link 2

xx1 = x1 - W.*cos(alpha+beta+pi/2);
xx2 = x1 - W.*cos(alpha+beta-pi/2);
xx4 = x2 - W.*cos(alpha+beta+pi/2);
xx3 = x2 - W.*cos(alpha+beta-pi/2);

yy1 = y1 - W .*sin(alpha+beta-pi/2);
yy2 = y1 - W .*sin(alpha+beta+pi/2);
yy3 = y2 + W .*sin(alpha+beta-pi/2);
yy4 = y2 + W .*sin(alpha+beta+pi/2);

Link2 = [[xx1 xx2 xx3 xx4]' [yy1 yy2 yy3 yy4]'];

% Define obsticle as a poly with alot of points

theta = linspace(0,2*pi, 100);
semi0x = xo + r.*cos(theta);
semi0y = yo + r.*sin(theta);

obsticle = [[semi0x'] [semi0y']];

%--------------------------------------------------------------------------

%Link 1 end
theta = linspace(alpha-pi/2,alpha+pi/2 , 100);
semi0x = x1 + W.*cos(theta);
semi0y = y1 + W.*sin(theta);
Link1_end = [[semi0x'] [semi0y']];

%Link 2 start
theta = linspace(alpha+beta-pi/2,alpha+beta+pi/2 , 100);
semi0x = x1 - W.*cos(theta);
semi0y = y1 - W.*sin(theta);
Link2_start = [[semi0x'] [semi0y']];

% Semi circle link 2 end
theta = linspace(beta+alpha-pi/2,beta+alpha+pi/2 , 100);
semi0x = x2 + W.*cos(theta);
semi0y = y2 + W.* sin(theta);
Link2_end = [[semi0x'] [semi0y']];


[TF1 TF2] = checkCollisionTwoLink(L1,L2,W,alpha,beta,xo,yo,r);

if TF1 ==1
    black(i,1) = alpha*(180./pi);
    black(i,2) = beta*(180./pi);
    red(i,1) = 0;
    red(i,2) = 0;
    blue(i,2) = 0;
    blue(i,1) = 0;

elseif TF2 ==1
    black(i,1) = 0;
    black(i,2) = 0;
    red(i,1) = alpha*(180./pi);
    red(i,2) = beta*(180./pi);
    blue(i,1) = 0;
    blue(i,2) = 0;

else
    black(i,1) = 0;
    black(i,2) = 0;
    red(i,1) = 0;
    red(i,2) = 0;
    blue(i,1) = alpha*(180./pi);
    blue(i,2) = beta*(180./pi);
end

end

plot(black(:,1), black(:,2), 'ko', 'MarkerFaceColor', 'k') % Black circles
hold on
plot(red(:,1), red(:,2), 'ro', 'MarkerFaceColor', 'r') % Red circles
hold on
plot(blue(:,1), blue(:,2), 'bo', 'MarkerFaceColor', 'b') % Blue circles
hold on
grid on

end
