function [u_x,u_y]=computeTangentVectorToPolygonTA(q,P)
% computeTangentVectorToPolygon(q,P) returns the unit vector tangent to the
%   the polygon defined by P, for the robot at q

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cenk Oguz Saglam, January 23, 2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize the distance as infinite
dist = @(p1,p2) norm(p1 - p2);
distance=inf;

% Copy the first point to the end to consider all segments
P(end+1,:)=P(1,:);
% Consider distances to all segments and take the minimum of them
% store which segment is closest.
for i=1:length(P(:,1))-1
   p1=P(i,:);
   p2=P(i+1,:);
   if computeDistancePointToSegmentTA(q, p2, p1)<distance
       distance=computeDistancePointToSegmentTA(q, p2, p1);
       segment=i;
   end
end

% Consider the closest segment
p1=P(segment,:);
p2=P(segment+1,:);

% If the closest point is a vertex, this section returns the number of that
% vertex. It returns vertex=0 if the closest point is not a vertex.
%==========================================================================
q_x = q(1);
q_y = q(2);
[a,b,c] = computeLineThroughTwoPointsTA(p1,p2);

% First, find the orthogonal projection of q onto the line
p_x = (b^2*q_x - a*b*q_y -a*c)/sqrt(a^2 + b^2);
p_y = (-a*b*q_x + a^2*q_y -b*c)/sqrt(a^2 + b^2);
% If projection is on the line segment, then distance is from q to p.
% Otherwise, it's the shorter of the distances from the endpoints
% of the segment.
bOnX = p_x >= min(p1(1),p2(1)) && p_x <= max(p1(1),p2(1));
bOnY = p_y >= min(p1(2),p2(2)) && p_y <= max(p1(2),p2(2));

if bOnX && bOnY
    vertex=0;
else
    dist1 = sqrt((q_x-p1(1))^2 + (q_y-p1(2))^2);
    dist2 = sqrt((q_x-p2(1))^2 + (q_y-p2(2))^2);
    [~,vertex] = min([dist1;dist2]);
    vertex=vertex+segment-1;
end
%==========================================================================

if ~vertex          % If closest point is a segment
    p1=P(segment,:);
    p2=P(segment+1,:);
    % then u is parallel to the segment
    u_x=(p2(1)-p1(1))/dist(p1,p2);
    u_y=(p2(2)-p1(2))/dist(p1,p2);
else                % If closest point is a vertex
    % then u is tangent the circle centered at the vertex,
    % passing through q
    v=P(vertex,:)-q';       % v is the vector from vertex to q
    l=sqrt(v(1)^2+v(2)^2);  % l will be used to normalize u
    % u is perpendicular to v and the robot is right turning
    u_x=v(2)/l;
    u_y=-v(1)/l;
end
