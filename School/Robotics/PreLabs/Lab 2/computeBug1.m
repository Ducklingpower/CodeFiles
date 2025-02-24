%Eric Perez
%Lab 2: Bug 1

function [sequence,pathLength,time] = computeBug1(start,goal,stepSize,ObstaclesList)
currentPosition = start;
sequence = currentPosition;
pathLength = 0;
 T = 1;
% compute distance between each point
distance = @(p1,p2) norm(p1 - p2);
k=1;
int = 0;
Q = 0;
distanceArray = [];
timeArray = [];
tStart= tic;
stepSize3 = stepSize;
while distance(currentPosition, goal) > stepSize

    Q = Q + 1;
    minGoal(Q) = distance(currentPosition, goal);
    minGoalIndex = find(minGoal == min(minGoal));
    % Move directly towards the goal
    [O L] = size(ObstaclesList);
    for i = 1:L
    q = currentPosition;
    Poly = cell2mat(ObstaclesList{i}');
    [~,Minseg,MinVertexDistance] = computeTangentVectorToPolygon(Poly,currentPosition);

    closestSegment(i) = Minseg; 
    MinVertex(i) = MinVertexDistance;
    end
     closestVertexP = min(MinVertex);
     closestSegmentP = min(closestSegment);
     closeIndexV = find(MinVertex == closestVertexP);
     closeIndexS = find(closestSegment == closestSegmentP);
     ClosestOBC = cell2mat(ObstaclesList{closeIndexS}');
     plot(start(1,1),start(1,2),'Or');
    hold on
    plot(goal(1,1),goal(1,2),'Or');
    hold on
     P = ClosestOBC;
    q = currentPosition;
 [U,~,~] = computeTangentVectorToPolygon(P,q);




    if closestSegmentP <= stepSize3 || closestVertexP <= stepSize
        
                
              nextPos = currentPosition + stepSize3 * U;
              PrevU(k,:) = round(U,2);
              sequence = [sequence; nextPos];
              currentPosition = nextPos;
             
              PositionAtOB(T,:) = currentPosition;
               pathLength = pathLength + stepSize;
              time = toc(tStart);
              timeArray = [timeArray, time];
              distanceArrayPlot = distance(currentPosition,goal);
              distanceArray = [distanceArray, distanceArrayPlot];
              T = T +1;


                        % plot
            figure(1)
           hold on
          plot(sequence(k,1),sequence(k,2),'Og')
     
             k = k +1;
               if closeIndexS == L && time > 4
               stepSize3 = 0.045;
              end
              if closestVertexP <= stepSize
            
              
              nextPos = currentPosition + stepSize3 *  PrevU(k-1,:) ;
              sequence = [sequence; nextPos];


              currentPosition = nextPos;
      
              PositionAtOB(T,:) = currentPosition;
              T = T +1;
                Contact = k - T;
              int = 6;
               pathLength = pathLength + stepSize;
                     time = toc(tStart);
              timeArray = [timeArray, time];
               distanceArrayPlot = distance(currentPosition,goal);
              distanceArray = [distanceArray, distanceArrayPlot];

              % plot
            figure(1)
           hold on
          plot(sequence(k,1),sequence(k,2),'Og')
   
             k = k +1;

              end
              while int > 5
              if  distance(PositionAtOB(1,:), currentPosition) <= stepSize
                     ShortestPointToGoal = sequence(minGoalIndex,:);
                     for R = 1: minGoalIndex - Contact

                     sequence(k+R,:) = sequence(Contact+R,:);
                     currentPosition = sequence(k+R,:);
     
               pathLength = pathLength + stepSize;
                     time = toc(tStart);
              timeArray = [timeArray, time];
               distanceArrayPlot = distance(currentPosition,goal);
              distanceArray = [distanceArray, distanceArrayPlot];

               % plot
            figure(1)
           hold on
          plot(sequence(k+R,1),sequence(k+R,2),'O')
             k = k +1;
            
                     end
                      k = k +R;
                     while distance(ShortestPointToGoal,currentPosition) < 0.4
                
                      nextPos = currentPosition + stepSize * (goal - currentPosition) / distance(currentPosition, goal);
                    sequence = [sequence; nextPos];

                     pathLength = pathLength + stepSize;
                    currentPosition = nextPos;
                 
                               time = toc(tStart);
              timeArray = [timeArray, time];
               distanceArrayPlot = distance(currentPosition,goal);
              distanceArray = [distanceArray, distanceArrayPlot];

               % plot
            figure(1)
           hold on
          plot(sequence(k,1),sequence(k,2),'Og')
    
             k = k +1;
                     end

                     break
              else
                 break
              end 
             
              end
                
    else 
        nextPos = currentPosition + stepSize * (goal - currentPosition) / distance(currentPosition, goal);
        sequence = [sequence; nextPos];

         pathLength = pathLength + stepSize;
        currentPosition = nextPos;
         time = toc(tStart);
         timeArray = [timeArray, time];
          distanceArrayPlot = distance(currentPosition,goal);
              distanceArray = [distanceArray, distanceArrayPlot];
         % plot
            figure(1)
           hold on
          plot(sequence(k,1),sequence(k,2),'Og')
          title('Path Taken By Robot')
     
             k = k +1;

    end

end
hold off;
figure(2)
scatter(timeArray,distanceArray);
title('Distance From Robot Positon To Goal')
xlabel('Time')
ylabel('Distance')
         end
                 
        
