function Path = computeBug(Pstart,Pgoal,Obsticle,stepsize)
    %% initializing
    Pcurrent = Pstart;
    Path = Pstart;    
    CurrentObsticle = 0;
    
   while abs(Pcurrent(1,1) - Pgoal(1,1)) >  stepsize*1.5 && abs(Pcurrent(1,2) - Pgoal(1,2)) > stepsize*1.5
        if length(Path(:,1))>=2
        break
        else 
        end

        %% main line intersection to line segment
        
            for i = 1:length(Obsticle(:,1,1))+1
            Counter(i) = i ;
            end
            Counter(end) = 1;
            
        for j = 1:length(Obsticle(1,1,:))
            if j == CurrentObsticle
                if j == length(Obsticle(1,1,:))
                j= j+1;
                end
                
            else
                for i = 1:length(Obsticle(:,1,1))
                    
                    x1 = Pcurrent(1);
                    y1 = Pcurrent(2);     
                    x2 = Pgoal(1);
                    y2 = Pgoal(2);
                    P1 = Obsticle(Counter(i),:,j);
                    P2 = Obsticle(Counter(i+1),:,j);
                    
                    x3 = P1(1);     
                    y3 = P1(2);
                    x4 = P2(1);     
                    y4 = P2(2);
                    
                    denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
                    
                    % Checking for parallel lines
                    if denominator == 0
                        intersection(i,:,j) = [NaN NaN]; 
                        d(i,j) = 0;
                    end
                    
                    t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denominator;
                    u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denominator;
                    
                    if u >= 0 && u <= 1
                        intersect_x = x1 + t * (x2 - x1);
                        intersect_y = y1 + t * (y2 - y1);
                        intersection(i,:,j) = [intersect_x, intersect_y];
                        d(i,j) = norm([x1 y1]-[intersect_x intersect_y]);
                    else
                        intersection(i,:,j) = [NaN NaN]; % Void lol
                        d(i,j) = NaN;
                    end
                end
                
                if all(isnan(d(:,j)), 'all')
                    Obsticle_Hit =  [NaN NaN];
                else 
                    finder = find(min(d(:,j)) == d(:,j));
                    Obsticle_Hit = intersection(finder,:,j);% I dentifiy where hit is at
                    Obsticle_Hit = Obsticle_Hit(1,:);
                    PNext = Obsticle_Hit;
                    CurrentObsticle = j;
                    CurrentSegmentNumber = [Counter(finder) Counter(finder+1)] ;
    
                    if sqrt((Pgoal(1)-Pcurrent(1))^2+(Pgoal(2)-Pcurrent(2))^2) <= sqrt((PNext(1)-Pcurrent(1))^2+(PNext(2)-Pcurrent(2))^2)
                        Obsticle_Hit =  [NaN NaN];
                    else 
                    end
    
                break
                end
            end
        end
        
        if isnan(Obsticle_Hit)
            PNext = Pgoal;
            [a,b,c] = computeLineThroughTwoPoints(Pcurrent,PNext);
        
            x1 = Pcurrent(1);
            y1 = Pcurrent(2);
            x2 = PNext(1);
            y2 = PNext(2);
            PositionX = [x1,x2];
            
            Delta = sqrt((x1-x2)^2 + (y1 -y2)^2)/stepsize;
            x = linspace(min(PositionX),max(PositionX),Delta);
            
            Pcurrent_to_PNext = @(x) (a/b)*x+c;  % Direct line from start to goal
            
            n = 1;
             for i = length(Path(:,1)): length(Path(:,1))+length(x)-1
                Path(i,1) = x(n);
                Path(i,2) = Pcurrent_to_PNext(x(n));
                n = n+1;
            end
        
        break
        else
        end
        %% Going from point A to point B
        % Pcurrent = Path(end,:);

        if PNext == Pcurrent
            PNext    = [x2 y2];
            return
        end
    
        [a,b,c] = computeLineThroughTwoPoints(Pcurrent,PNext);
        x1 = Pcurrent(1);
        y1 = Pcurrent(2);  
        x2 = PNext(1);
        y2 = PNext(2);
        PositionX = [x1,x2];
        
        Delta = sqrt((x1-x2)^2 + (y1 -y2)^2)/stepsize;
        x = linspace(min(PositionX),max(PositionX),Delta);
        Pcurrent_to_PNext = @(x) (a/b)*x+c;  % Direct line from start to goal
        
        n = 1;
        for i = length(Path(:,1)): length(Path(:,1))+length(x)-1
            Path(i,1) = x(n);
            Path(i,2) = Pcurrent_to_PNext(x(n));
            n = n+1;
        end

        Pcurrent = Path(end,:);
          
    end
end