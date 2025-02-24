function[intersect,intersectPoint] = doTwoSegmentsIntersect(P1,P2,P3,P4)
intersect = false;
intersectPoint = false;
x1 = P1(1);
y1 = P1(2);

x2 = P2(1);
y2 = P2(2);

x3 = P3(1);
y3= P3(2);

x4 = P4(1);
y4 = P4(2);
P1x = [x1,x2];
P2x = [x3,x4];
P1y = [y1,y2];
P2y = [y3,y4];


plot(P1x,P1y);
hold on
plot(P2x,P2y,'-r');

numA =(x4 - x3)*(y1 - y3) - (y4 - y3)*(x1 - x3);
denA = (y4 - y3)*(x2 - x1) - (x4 - x3)*(y2 - y1);

numB = (x2 - x1)*(y3-y1) - (y2-y1)*(x3 - x1);
denB = (y2 - y1)*(x4 - x3) - (y4 - y3)*(x2-x1);

sa = numA/denA;
sb = numB/denB;
intersectPoint1 = P1 + sa*(P2 - P1);
intersectPoint2 = P3 + sb*(P4 - P3);

if (denA ~= 0)
     if (sa >= 0) && (sa <= 1) && (sb >= 0) && (sb <= 1)
     intersect = true;
     intersectPoint = intersectPoint1;
     end
end


end