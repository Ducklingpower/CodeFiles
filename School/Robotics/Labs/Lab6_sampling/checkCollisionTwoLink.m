function TF = checkCollisionTwoLink(L1,L2,W,alpha,beta,xo,yo,r)

%% Position
x1 = L1 * cos(alpha);
y1 = L1 * sin(alpha);

x2 = x1 + L2 * cos(alpha + beta);
y2 = y1 + L2 * sin(alpha + beta);

%% Check rectangle first (easy)

% Define link 1 body

xx1 = 0 - W*cos(alpha-pi/2);
xx2 = 0 - W*cos(alpha+pi/2);
xx4 = x1 + W*cos(alpha+pi/2);
xx3 = x1 + W*cos(alpha-pi/2);

yy1 = 0 - W *sin(alpha-pi/2);
yy2 = 0 - W *sin(alpha+pi/2);
yy3 = y1 + W *sin(alpha-pi/2);
yy4 = y1 + W *sin(alpha+pi/2);

Link1 = [[xx1 xx2 xx3 xx4]' [yy1 yy2 yy3 yy4]'];

% Define Body Link 2

xx1 = x1 - W*cos(alpha+beta+pi/2);
xx2 = x1 - W*cos(alpha+beta-pi/2);
xx4 = x2 - W*cos(alpha+beta+pi/2);
xx3 = x2 - W*cos(alpha+beta-pi/2);

yy1 = y1 - W *sin(alpha+beta-pi/2);
yy2 = y1 - W *sin(alpha+beta+pi/2);
yy3 = y2 + W *sin(alpha+beta-pi/2);
yy4 = y2 + W *sin(alpha+beta+pi/2);

Link2 = [[xx1 xx2 xx3 xx4]' [yy1 yy2 yy3 yy4]'];



%% Define obsticle as a poly with alot of points

theta = linspace(0,2*pi, 100);
semi0x = xo + r*cos(theta);
semi0y = yo + r *sin(theta);

obsticle = [[semi0x'] [semi0y']];

%--------------------------------------------------------------------------

%Link 1 end
theta = linspace(alpha-pi/2,alpha+pi/2 , 100);
semi0x = x1 + W*cos(theta);
semi0y = y1 + W *sin(theta);
Link1_end = [[semi0x'] [semi0y']];

%Link 2 start
theta = linspace(alpha+beta-pi/2,alpha+beta+pi/2 , 100);
semi0x = x1 - W*cos(theta);
semi0y = y1 - W *sin(theta);
Link2_start = [[semi0x'] [semi0y']];

% Semi circle link 2 end
theta = linspace(beta+alpha-pi/2,beta+alpha+pi/2 , 100);
semi0x = x2 + W*cos(theta);
semi0y = y2 + W * sin(theta);
Link2_end = [[semi0x'] [semi0y']];

%% Check for collisions

TF1 = doTwoConvexPolygonsIntersect(obsticle,Link1);
TF2 = doTwoConvexPolygonsIntersect(obsticle,Link2);
TF3 = doTwoConvexPolygonsIntersect(obsticle,Link1_end);
TF4 = doTwoConvexPolygonsIntersect(obsticle,Link2_start);
TF5 = doTwoConvexPolygonsIntersect(obsticle,Link2_end);


if  (TF1 ==1) || (TF2 == 1) || (TF3 ==1) || (TF4 ==1) || (TF5 == 1)
    TF = 1;
else 
    TF = 0;
end

end