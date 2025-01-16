function u = computeTangentVectorToPolygon(P,q)

[D,Segment] = computeDistancePointToPolygon(P,q);

if length(Segment(:,2)) ==2
x1 = Segment(1,1); % point 1
y1 = Segment(1,2);
x2 = Segment(2,1); % point 2
y2 = Segment(2,2);

S = [x2,y2] - [x1,y1];
else 
vx = Segment(1,1); % point 1
vy = Segment(1,2);
r = D;

end


%% Output 
if length(Segment(:,2)) ==2
u = S / (sqrt(S(1)^2+S(2)^2)); % Parellel u unit vec to segment 
else % cirlce time

phi = atan2(vy-q(2),vx-q(1));
u = [-r*sin(phi) -r*cos(phi)]/r;
hold on
th = 0:pi/50:2*pi;
xunit = r * cos(th) + vx;
yunit = r * sin(th) + vy;
plot(xunit, yunit);

end







end