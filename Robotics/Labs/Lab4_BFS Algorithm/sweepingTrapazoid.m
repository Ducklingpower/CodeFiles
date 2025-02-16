clc
close all
clear 
%% Input 

%Workspace

Ymax   = 5;
Ymin   =-5;
Xwidth =10;

W = [Ymax Ymin Xwidth]; % Assume (0,0) is origin


%extracting work space
w1 = [-W(3)/2 W(1)];
w2 = [W(3)/2 W(1)];
w3 = [W(3)/2 W(2)];
w4 = [-W(3)/2 W(2)];
w5 = [-W(3)/2 W(1)];


WorkSpace = [w1; w2; w3; w4; w5];

% Obsticles

Q1 = [-4 4 ;-2 4 ;0 0 ; -1 -3;-3 -2];
Q2 = [1 1; 2 1; 4 3; 3 5; 2 4];

P(:,:,1) = Q1;
P(:,:,2) = Q2;



%% algo

% Getting all x and y Vales
n=0;
for i =1:length(P(1,1,:))
    for j =1:length(P)
    n = n+1;
    Px(n) = P(j,1,i);
    Py(n) = P(j,2,i);
    end
end


% getting points from left to right

for i =1:length(Px)
    xmin = min(Px);
    finder = find(Px ==xmin);
  
    if length(finder)>=2
        for j = 2:length(finder)
            finder(j) =[];
        end
    else
    end

    Px(finder) = [];
    STGx(i) = xmin;
    STGy(i) = Py(finder);
    Py(finder) = [];
end

% Creaing verticle line

for i = 1:length(STGx)
VLine(1,1,i) =  [STGx(i) Ymax];
VLine(2,2,i) =  [STGx(i) Ymin];
end


figure
plot(WorkSpace(:,1),WorkSpace(:,2),LineWidth=3);
grid on
hold on
for j =1: length(P(1,1,:))
X = P(:,1,j);
Y = P(:,2,j);
fill(X,Y,[rand(1) rand(1) rand(1)])
hold on 
end
hold on
plot(STGx,STGy,"*",LineWidth=3)

legend("Work space","Obsticle 1","Obsticle 2","Vetex")
