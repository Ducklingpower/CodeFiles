clc

clear 
%% Input 

%Workspace

Ymax   = 6;
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
Xobj = [Px;Px];

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
VLine(:,1,i) =  [STGx(i) Ymax];
VLine(:,2,i) =  [STGx(i) Ymin];

Vlinex(:,i) = [STGx(i) STGx(i)];
Vliney(:,i) = [Ymax Ymin];
end

% stoping the vertivcle line from going through the obsticle

n=0;
for i =1:length(P(1,1,:))
     
     Que = 1:length(P);
     Que = [length(P) Que 1];
    for j =1:length(P)
        n = n+1;

        P_current    = P(j,1,i);
        P_node_back  = P(Que(j),1,i);
        P_node_front = P(Que(j+2),1,i);

       if (P_current < min(P_node_front, P_node_back)) || (P_current > max(P_node_front, P_node_back))
            

       else 

           if mean(P(:,2,i)) > P(j,2,i)
                Vliney(:,n) = [P(j,2,i) Ymin];
           else
                Vliney(:,n) = [Ymax P(j,2,i)];
           end
           
        end
    end
end



%% Plotting

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
hold on

for i = 1:length(STGx)
plot(Xobj(:,i),Vliney(:,i),"black",linestyle = "--")
end

for i = 1:length(STGx)
plot(Xobj(:,i),Vliney(:,i),"b*")
end
legend("Work space","Obsticle 1","Obsticle 2","Vetex")

%% Getting polygons

%sweeping from left to right



n=0;
m=0;
xlast  = -W(3)/2;
ylast1 = Ymax;
ylast2 = Ymin;
for i =1:length(P(1,1,:))
     
     Que = 1:length(P);
     Que = [length(P) Que 1];
    for j =1:length(P)
        n = n+1;
        m = m+1;


        P_current    = [P(j,1,i) P(j,2,i)];
        P_node_back  = [P(Que(j),1,i) P(Que(j),2,i)];
        P_node_front = [P(Que(j+2),1,i) P(Que(j+2),2,i)];

       if (P_current(1) < min(P_node_front(1), P_node_back(1))) || (P_current(1) > max(P_node_front(1), P_node_back(1)))
            
            
        x1 = P(j,1,i);
        x2 = x1;
      
        x3 = xlast;
        x4 = x3;


        y1 =  Ymax;
        y2 =  Ymin;

        y3 = ylast1;
        y4 = ylast2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        x1 = P(j,1,i);
        x4 = x1;
      
        x2 = xlast;
        x3 = x2;


        y1 =  Ymax;

        if y3 == Ymin
        y4 =  Ymin;
        else
        y4 = P(j,2,i);
        end
        y2 = ylast1;
        y3 = ylast2;


        Poly(:,:,m) = [x1 x2 x3 x4; y1 y2 y3 y4];

       else 
 
          
        x1 = P(j,1,i);
        x4 = x1;
      
        x2 = xlast;
        x3 = x2;


        y1 =  Vliney(1,j);
        y4 =  Vliney(2,j);

        y2 = ylast1;
        y3 = P(Que(j),2,i);


        Poly(:,:,m) = [x1 x2 x3 x4; y1 y2 y3 y4];    
       end

        xlast  = x1;
        Ylast1 = y1;
        ylast2 = y3;
hold on
X = Poly(1,:,n);
Y = Poly(2,:,n);
fill(X,Y,[rand(1) rand(1) rand(1)])
hold on 
    end
end

