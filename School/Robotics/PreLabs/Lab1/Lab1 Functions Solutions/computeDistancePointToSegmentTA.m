function distance = computeDistancePointToSegmentTA(p1, p2,q)
% computeDistancePointToSegment returns the distance between point q
%   and segment between points p1 and p2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cenk Oguz Saglam, January 13, 2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dist = @(p1,p2) norm(p1 - p2);
%Store the x and y components of point p
q_x=q(1);
q_y=q(2);

%Obtain the parameters defining the line passing through point p1 and p2
[a,b,c]=computeLineThroughTwoPointsTA(p1, p2);

%Projection
%Proof handwritten
c2=a*q_y-b*q_x;
p_x=(-a*c-b*c2)/(a^2+b^2);
p_y=(a*c2-b*c)/(a^2+b^2);

%Sort the x values of the two points forming the segment
X=[p1(1) p2(1)];
Y=[p1(2) p2(2)];
%I is the index of the point on the left
[p_left,I]=min(X);
p_right=X(3-I);

if p_left~=p_right      %If the segment is not vertical
    if p_x<p_left       %If the projection is closer to the point on the left
        %distance to the segment equals distance to the point on the left
        distance=dist(q,[p_left;Y(I)]);
    elseif p_x>p_right %If the projection is closer to the point on the right
        %distance to the segment equals distance to the point on the right
        distance=dist(q,[p_right;Y(3-I)]);
    else                %If the projection is on the segment
        %Calculate the distance as we did in computeDistancePointToLine.m
        distance=abs(a*q_x+b*q_y+c)/sqrt(a^2+b^2);
    end
else                    %If the segment is vertical
    %then sort the y values of the two points forming the segment
    X=[p1(1) p2(1)];
    Y=[p1(2) p2(2)];
    %I is the index of the point on the bottom
    [p_down,I]=min(Y);
    p_up=Y(3-I);
    
    if p_y<p_down       %If the projection is closer to the point on the bottom
        %distance to the segment equals distance to the point on the bottom
        distance=dist(q,[Y(I);p_down]);
    elseif p_y>p_up     %If the projection is closer to the point on the top
        %distance to the segment equals distance to the point on the top
        distance=dist(q,[X(3-I);p_up]);
    else                %If the projection is on the segment
        %Calculate the distance as we did in computeDistancePointToLine.m
        distance=abs(a*q_x+b*q_y+c)/sqrt(a^2+b^2);
    end
end
