% Eric Perez
% lab 1 Problem 2
function [U,minSeg,MinVertexDistance] = computeTangentVectorToPolygon(P,q)
sizeP = size(P);
FirstSeg = [0,0];
SecondSeg = [0,0];
if sizeP(2) == 2
    [MinVertexDistance,Vx,Vy] = computeDistancePointToPolygon(P,q);
     VertexPoint = [Vx,Vy];
    for i = 1:sizeP(1)
        p1 = P(i,:);
        p2 = P(mod(i,sizeP(1))+1,:); %Next Vector

        %compute distance from 
        segmentDistance(i) = computeDistancePointToSegmentTA(p1,p2,q);
        P1(i,:) = p1;
        P2(i,:) = p2;
    end 
else 
   error('Wrong poly size');
end
minSeg = min(segmentDistance);
IndexSeg = find(segmentDistance==minSeg);
XP1 = P1(IndexSeg,1);
YP1 = P1(IndexSeg,2);
XP2 = P2(IndexSeg,1);
YP2 = P2(IndexSeg,2);
FirstSeg = [XP1,YP1];
SecondSeg = [XP2,YP2];

if minSeg < MinVertexDistance
    Changex = XP2 - XP1;
    Changey = YP2 - YP1;
    %M = sqrt((Changex).^2 + (Changey).^2);
     vector = [Changex,Changey];%Ux = Changex/M
    %Uy = Changey/M;
    %U =[-Uy,Ux] ;
    U = vector/ norm(vector);
    minSeg 
   %disp('MinSegmentDistance')
else 
    Changex = Vx - q(1);
    Changey = Vy - q(2);
    u = [-Changey, Changex]; % rotate 90 to make tangent
    Ux = u(1)/norm(u);
    Uy = u(2)/norm(u);
    U = [Ux,Uy];
    MinVertexDistance
    %disp('MinVertextDistance')

end
