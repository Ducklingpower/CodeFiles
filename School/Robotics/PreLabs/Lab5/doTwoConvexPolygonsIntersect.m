function [TF] = doTwoConvexPolygonsIntersect(P1,P2)
[n1,~] = size(P1);
[n2,~] = size(P2);
TF = false;

polysize1 = size(P1);
if polysize1(2)~=2
    error ('P1 input size is incorrect')
end
polysize2 = size(P2);
if polysize2(2)~=2
    error ('P2 input size is incorrect')
end
 
for i = 1:n1
    v1 = P1(i,:);
    v1Next = P1(mod(i,n1)+1,:);
    for j = 1:n2
        v2 = P2(j,:);
    v2Next = P2(mod(j,n2)+1,:);
        if (v1 == v2)
        TF = true;
        end
          
        [intersect,~] = doTwoSegmentsIntersect(v1, v1Next,v2,v2Next);

        if intersect == true
            TF = true;
        end 

    end 
end
end 
