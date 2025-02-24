% Eric Perez
% ME 145 Lab 2

function [sequence] = bugBase(start,goal,sSize,obstaclesList)

robotPosition = start;          % Starting Position

sequence = [start];            % Initializing Robot Path 

% Distance from start to goal
distanceToGoal = @(p1,p2) norm(p1 -p2);
%distanceToGoal = norm(robotPosition - goal);

sizeOb = size(obstaclesList);
numObstacles = sizeOb(2);

q = robotPosition;

obstacleCollision = 0;
 while distanceToGoal(robotPosition,goal) > sSize

    for i=1:numObstacles
        % P(i,:) = cell2mat(obstaclesList{i}')      
        %cell2mat converts the cells from the obstacleList into a matrix, ' transposes, and i is for each index or each obstacle
        [distance,xvalue,yvalue] = computeDistancePointToPolygon(cell2mat(obstaclesList{i}'),q);
        % NEW CODE
        % [u,vertexDistance,minsegmentDistance] = computeTangentVectorToPolygon(cell2mat(obstaclesList{i}'),q);
        % vertexDistanceJ(i) = vertexDistance;
        % minsegmentDistanceJ(i) = minsegmentDistance
        % creates arrays of distance, xvalues, and yvalues
        distanceArray(i) = distance;        
        xvalueArray(i) = xvalue;
        yvalueArray(i) = yvalue;
    end

closestObstacle = min(distanceArray);
% finds the index associated with the closest obstacle
indexclosestObstacle = find(distanceArray == closestObstacle);      
xvalueclosestObstacle = xvalueArray(indexclosestObstacle);          
yvalueclosestObstacle = yvalueArray(indexclosestObstacle);
% uses cell2matrix conversion to find the polygon associated with the closest point
closestObstacle = cell2mat(obstaclesList{indexclosestObstacle}');
positionClosestPolygon = [xvalueclosestObstacle yvalueclosestObstacle];

    nextPosition = robotPosition + sSize*(goal-robotPosition) / distanceToGoal(robotPosition, goal);
    sequence = [sequence; nextPosition];
    robotPosition = nextPosition;
    distanceToClosestPolygon = norm(robotPosition - positionClosestPolygon);

% Attempting to use tangent vector to polygon
q = robotPosition;
P = closestObstacle;
[u,distancePoly] = computeTangentVectorToPolygon(P,q);

       if distancePoly < sSize 
            nextPosition = robotPosition + sSize * u;
            sequence = [sequence; nextPosition];
            robotPosition = nextPosition;
            obstacleCollision = 1;
            error('Failure: There is an obstacle lying between the start and goal');
       % break
       end 


 end 
  xvalueSequence = sequence(:,1);
  yvalueSequence = sequence(:,2);
  xvalueStart = start(1);
  yvalueStart = start(2);
  xvalueGoal = goal(1);
  yvalueGoal = goal(2);
  plot(xvalueStart,yvalueStart,'o');
  hold on
  plot(xvalueGoal,yvalueGoal,'o');
  plot(xvalueSequence,yvalueSequence,'o');
  disp('Success')

end 