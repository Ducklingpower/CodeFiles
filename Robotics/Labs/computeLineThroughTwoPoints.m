function [a,b,c] = computeLineThroughTwoPoints(p1,p2)
%% Error statments 

if length(p1)~=2 
    error("Incorrect Dimentions for input in position 1")
elseif  length(p2)~=2 
    error("Incorrect Dimentions for input in position 2")
else
%% Line Calcs

x1 = p1(1); % point 1
y1 = p1(2);

x2 = p2(1); % point 2
y2 = p2(2);


A = y2-y1;
B = x2-x1;
C = -(A/B)*x1+y1;

M = [A,B];
M_mag = sqrt(M(1)^2 + M(2)^2);
m = M./(M_mag);

if M_mag<0.1
    error("Points need to have greater than 0.1 distance")
else 
end

%% outputs 

a = m(1);
b = m(2);
c = C;

%% Additional plotting 
PositionX = [x1,x2];
PositionY = [y1,y2];
x = min(PositionX):0.1:max(PositionX);
y = @(x) (m(1)/m(2))*x+C; 

figure
plot(x,y(x));
hold on
plot(x1,y1,"*");
hold on
plot(x2,y2,"*");
grid on
legend("Line connection","p1","p2")
xlow = min(PositionX)-1;
xup  = max(PositionX)+1;
ylow = min(PositionY)-1;
yup  = max(PositionY)+1;

xlim([xlow,xup])
ylim([ylow,yup])

end





