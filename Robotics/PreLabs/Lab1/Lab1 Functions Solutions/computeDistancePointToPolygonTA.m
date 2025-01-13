function [dist,Vx,Vy] = computeDistancePointToPolygonTA(q, P)
% computeDistancePointToPolygon(q, P) returns the distance between point q
%   and the polygon defined by P

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cenk Oguz Saglam, January 23, 2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize the distance as infinite
dist=inf;

% Copy the first point to the end to consider all segments
P(end+1,:)=P(1,:);
% Consider distances to all segments and take the minimum of them
for i=1:length(P(:,1))-1
   p1=P(i,:);
   p2=P(i+1,:);
   Vx = min(p1);
   Vy = min(p2);
   dist=min(dist,computeDistancePointToSegmentTA(q, p2, p1));
end
