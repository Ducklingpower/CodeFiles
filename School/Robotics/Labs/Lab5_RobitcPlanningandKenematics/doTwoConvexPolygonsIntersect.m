function TF = doTwoConvexPolygonsIntersect(P1,P2)

% if length(P1(:,1)) <=2
%     error("P1 must be a polygon ")
% end
% 
% if length(P2(:,1)) <=2
%     error("P2 must be a polygon ")
% end

TF = 0;

LengthsP1 = length(P1);
LengthsP2 = length(P2);

Index1 = [1:LengthsP1 1];
Index2 = [1:LengthsP2 1];

for j = 1:LengthsP1
point1_current = P1(Index1(j),:);
point1_next    = P1(Index2(j+1),:);

    for i = 1:LengthsP2
        point2_current = P2(Index2(i),:);
        point2_next    = P2(Index2(i+1),:);
        Intersection_Check = doTwoSegmentsIntersect(point1_current,point1_next,point2_current,point2_next);

        if Intersection_Check == 1
            TF = 1;
            break
        end
    end
    if TF == 1
        break
    end
end

end