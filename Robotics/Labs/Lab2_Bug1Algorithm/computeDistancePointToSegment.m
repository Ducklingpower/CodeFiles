
function [D,point] = computeDistancePointToSegment(q,p1,p2)

%% Error statments 
if length(p1)~=2 
    error("Incorrect Dimentions for input in position 2")
elseif  length(p2)~=2 
    error("Incorrect Dimentions for input in position 3")
elseif  length(q)~=2 
    error("Incorrect Dimentions for input in position 1")
else
%% Line Calcs

x1 = p1(1); % point 1
y1 = p1(2);
x2 = p2(1); % point 2
y2 = p2(2);


S = [x2,y2] - [x1,y1];
W = q-[x1,y1];
Z = (dot(W,S))/(dot(S,S)); % scalar 0-1 if with in segment
Zvec= p1+S*Z;




%% output
if Z>0 && Z<=1
    
    point = Zvec;
    D = norm(W-Zvec);
    D = norm(W-S*Z);

elseif Z>1
    D = norm(q-p2);
    point = p2;
else 
    D = norm(q-p1);
    point = p1;
end


%% Final error statements
if D < 0.1
    error("point must be 0.1 away from segment")
elseif norm(S)<0.1
    error("Segment length must be greater than 0.1 ")
end


%% Additional plotting 
% figure
% 
% plot([x1,x2],[y1,y2]);%S
% hold on 
% plot(x1,y1,"*")
% hold on
% plot(x2,y2,"*")
% hold on
% plot(q(1),q(2),"*")
% hold on
% plot([point(1),q(1)],[point(2),q(2)])%Short line
% grid on
% legend("segment","p1","p2","q")
% 
% xlim([-10,10])
% ylim([-10,10])
end