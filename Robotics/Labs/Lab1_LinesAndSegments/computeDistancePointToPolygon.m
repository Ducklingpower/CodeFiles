function [D,Segment] = computeDistancePointToPolygon(P,q)
%% Error checking
if length(P(1,:)) ~= 2
error ("Dimensions of P must be [x1 y1, x2 y2, ... xn yn]")

elseif length(q) ~= 2
    error ("Dimensions of q must be in the form [x,y]")
end




%% Solving all solutons 
for i = 1:length(P(:,1))+1

    Counter(i) = i ;
end
Counter(end) = 1;


for i = 1:length(P(:,1))

    p1 = P(Counter(i),:);
    p2 = P(Counter(i+1),:);

    [dist(i),point(i,:)] = computeDistancePointToSegment(q,p1,p2);
end


%% output
D = min(dist);

finder  = dist == D;
point   = point(finder,:);

if length(point(:,1)) == 1
Segment(1,:) = P(finder,:);
point2 = find(finder ==1)+1;
Segment(2,:) = P(point2,:);
else 
Segment = point(1,:);
end



%% Plotting 
figure 
X = P(:,1);
Y = P(:,2);
fill(X,Y,[0.8 0.7 0.8])
hold on 
plot(q(1),q(2),"*")
hold on
plot([point(1,1),q(1)],[point(1,2),q(2)])%Short line
xlim([-10,10])
ylim([-10,10])
grid on
axis normal;
axis square;


end


