function TF = doTwoSegmentsIntersect(p1,p2,p3,p4)

if length(p1)~=2
    error("Must be two dimension points")
end

TF = 0;

Segment1 = [p1;p2];
Segment2 = [p3;p4];

x1 = p1(1);
x2 = p2(1);
x3 = p3(1);
x4 = p4(1);

y1 = p1(2);
y2 = p2(2);
y3 = p3(2);
y4 = p4(2);

num1 = (x4-x3)*(y1-y3)-(y4-y3)*(x1-x3); 
den1 = (y4-y3)*(x2-x1)-(x4-x3)*(y2-y1);

num2 = (x2-x1)*(y3-y1)-(y2-y1)*(x3-x1);
den2 = (y2-y1)*(x4-x3)-(y4-y3)*(x2-x1);


if den1 ~= 0 
   S1 = num1/den1;
    if den2~=0
       S2 = num2/den2;
    end


    if (S1>=0) && (S1<=1) && (S2>=0) && (S2<=1)
        TF = 1;
    end
 
else
    
end

% 
% figure
% plot(Segment1(:,1),Segment1(:,2),LineWidth=2);
% hold on
% plot(Segment2(:,1),Segment2(:,2),LineWidth=2);
% grid on
% legend("Segment 1", "Segment 2")
% title("True of False Value = " + TF)


end



