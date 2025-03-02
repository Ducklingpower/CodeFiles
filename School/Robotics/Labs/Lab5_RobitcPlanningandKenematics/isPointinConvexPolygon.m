function TF = isPointinConvexPolygon(q,P)

if length(P(1,1,:)) ~=1
error("One Polygon at a time please!")
end

if length(q) ~= 2
    error("Point q must be two dimentional (x,y)")
end

TF = 1;
Info = [1:length(P) 1]; 
for i = 1:length(P)

    info1 = Info(i);
    info2 = Info(i+1);
    InnerVector = [-(P(info2,2)-P(info1,2)) P(info2,1)-P(info1,1)];
    % PCurrent = [P(info1,1) P(info1,2)];
    % Pnext    = [P(info2,1) P(info2,2)];
    V = [q(1)-InnerVector(1) q(2)-InnerVector(2)];
    DP = InnerVector(1)*V(1) + InnerVector(2)*V(2);

    if DP>0
        TF = 0;
        break
    end
end

end