function D = computeDistancePointToPolygon(P,q)

for i = 1:length(P(:,1))+1

    Counter(i) = i ;
end

Counter(end) = 1;
%% Solving all solutons 
for i = 1:length(P(:,1))

    p1 = P(Counter(i),:);
    p2 = P(Counter(i+1),:);

    [dist(i),point(i,:)] = computeDistancePointToSegment(q,p1,p2);
end

%% output
D = min(dist);
finder = find(dist == D);
point = point(finder,:);


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


end


