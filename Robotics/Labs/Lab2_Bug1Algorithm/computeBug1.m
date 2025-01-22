function Path = computeBug1(Pstart,Pgoal,Obsticle,stepsize)


%% creating algebraic line from start to goal
[a,b,c] = computeLineThroughTwoPoints(Pstart,Pgoal);

x1 = Pstart(1);
y1 = Pstart(2);

x2 = Pgoal(1);
y2 = Pgoal(2);


PositionX = [x1,x2];
PositionY = [y1,y2];
x = min(PositionX):stepsize:max(PositionX);
Start_to_Goal = @(x) (a/b)*x+c;  % Direct line from start to goal
%% main line intersection to line segment

x1 = Pstart(1); 
y1 = Pstart(2);
x2 = Pgoal(1);  
y2 = Pgoal(2);


x3 = P1(1);     
y3 = P1(2);
x4 = P2(1);     
y4 = P2(2);
 
denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

% Checking for parallel lines
if denominator == 0
    intersection = []; 
    return;
end

t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denominator;
u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denominator;

if u >= 0 && u <= 1
        intersect_x = x1 + t * (x2 - x1);
        intersect_y = y1 + t * (y2 - y1);
        intersection = [intersect_x, intersect_y];
    else
        intersection = []; % Void lol
end


% %% Solving near obsticle (Aka nearest segment) 
% for i = 1:length(Obsticle(1,1,:))
% 
% P = Obsticle(:,:,i);
% 
% [D(i),Segment(:,i)] = computeDistancePointToPolygon(P,Pstart);
% 
% end
% 
% finder = find(min(D) == D);
% NearestSegment = Segment(finder,:);
% 
% 
% %% Creating line of nearest segment 
% 
% [a,b,c] = computeLineThroughTwoPoints(Pstart,Pgoal);
% 
% x1 = Pstart(1);
% y1 = Pstart(2);
% 
% x2 = Pgoal(1);
% y2 = Pgoal(2);
% 
% 
% PositionX = [x1,x2];
% PositionY = [y1,y2];
% x = min(PositionX):stepsize:max(PositionX);
% Start_to_Goal = @(x) (a/b)*x+c;  % Direct line from start to goal
% 
% 

end