function plotEnvironment(L1, L2, W, alpha, beta, xo, yo, r)
    
%% Calculate the positions of the links
    x1 = L1 * cos(alpha);
    y1 = L1 * sin(alpha);

    x2 = x1 + L2 * cos(alpha + beta);
    y2 = y1 + L2 * sin(alpha + beta);

   
%% Plotting

% Link 2 -----------------------------------------------------------------

% plot semi circle on link2 front
theta = linspace(alpha+beta-pi/2,alpha+beta+pi/2 , 100);
semi0x = x1 - W*cos(theta);
semi0y = y1 - W *sin(theta);
fill(semi0x, semi0y,[0.9290 0.6940 0.1250])
hold on

% Semi circle link 2 end
theta = linspace(beta+alpha-pi/2,beta+alpha+pi/2 , 100);
semi2x = x2 + W*cos(theta);
semi2y = y2 + W * sin(theta);
fill(semi2x, semi2y,[0.9290 0.6940 0.1250])

% plotting square
xx1 = x1 - W*cos(alpha+beta+pi/2);
xx2 = x1 - W*cos(alpha+beta-pi/2);
xx4 = x2 - W*cos(alpha+beta+pi/2);
xx3 = x2 - W*cos(alpha+beta-pi/2);

yy1 = y1 - W *sin(alpha+beta-pi/2);
yy2 = y1 - W *sin(alpha+beta+pi/2);
yy3 = y2 + W *sin(alpha+beta-pi/2);
yy4 = y2 + W *sin(alpha+beta+pi/2);

fill([xx1 xx2 xx3 xx4],[yy2 yy1 yy4 yy3],[0.8500 0.3250 0.0980])


% Link 1 ------------------------------------------------------------------


 %plot first semi circle on link1
theta = linspace(alpha-pi/2,alpha+pi/2 , 100);
semi0x = 0 - W*cos(theta);
semi0y = 0 - W *sin(theta);
fill(semi0x, semi0y,[0 0.4470 0.7410])
hold on

%plot semi circle on link1 end
theta = linspace(alpha-pi/2,alpha+pi/2 , 100);
semi0x = x1 + W*cos(theta);
semi0y = y1 + W *sin(theta);
fill(semi0x, semi0y,[0 0.4470 0.7410])
hold on


%plotting square

xx1 = 0 - W*cos(alpha-pi/2);
xx2 = 0 - W*cos(alpha+pi/2);
xx4 = x1 + W*cos(alpha+pi/2);
xx3 = x1 + W*cos(alpha-pi/2);

yy1 = 0 - W *sin(alpha-pi/2);
yy2 = 0 - W *sin(alpha+pi/2);
yy3 = y1 + W *sin(alpha-pi/2);
yy4 = y1 + W *sin(alpha+pi/2);

fill([xx1 xx2 xx3 xx4],[yy1 yy2 yy3 yy4],[0.3010 0.7450 0.9330])

%% Plotting Obsticle 


theta = linspace(0,2*pi, 100);
semi0x = xo + r*cos(theta);
semi0y = yo + r *sin(theta);
fill(semi0x, semi0y,[0.6350 0.0780 0.1840])
hold on


xlim([-L2-L1-1 L2+L1+1])
ylim([-L2-L1-1 L2+L1+1])
axis square
grid on
   
end