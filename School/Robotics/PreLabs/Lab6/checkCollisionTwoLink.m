 % Eric Perez
 % lab 6
 function [TF,collision] = checkCollisionTwoLink(L1, L2, W, alpha, beta, xo, yo, r) 
     collision = 0;
    % Calculate the positions of the links
    x1 = L1 * cos(alpha);
    y1 = L1 * sin(alpha);
    x2 = x1 + L2 * cos(alpha + beta);
    y2 = y1 + L2 * sin(alpha + beta);

    hold on;
    theta = linspace(0, 2*pi, 100);
    semi0x = 0 + W*cos(theta);

    semi0y = 0 + W *sin(theta);
    fill(semi0x, semi0y, 'b')
    semi0 = [semi0x;semi0y]';
 
    semi2x = x2 + W*cos(theta);
    semi2y = y2 + W * sin(theta);
    fill(semi2x, semi2y, 'r')
    semi2 = [semi2x;semi2y]';

    xdiff1 = x1;
    ydiff1 = y1;

    direct1 = [-ydiff1, xdiff1];
    unit1 = direct1 / norm(direct1);

  TP1x = 0 + W*unit1(1);
  TP1y = 0 + W*unit1(2);
  BP1x = 0 - W*unit1(1);
  BP1y = 0 - W*unit1(2);
  plot(TP1x,TP1y,'o');
  plot(BP1x,BP1y,'o');
  TP2x = x1 +  W*unit1(1);
  TP2y = y1 + W*unit1(2);
  BP2x = x1 - W*unit1(1);
  BP2y = y1 - W*unit1(2);
  plot(TP2x,TP2y,'o');
  plot(BP2x,BP2y,'o');

  x = [TP1x TP2x  BP2x BP1x];
  y = [TP1y TP2y BP2y BP1y];
  Link1 = [x(1) y(1); x(4) y(4);x(3) y(3);x(2) y(2)];
  fill(x,y,'b');

  xdiff2 = x2-x1;
  ydiff2 = y2-y1;

  direct2 = [-ydiff2, xdiff2];
  unit2 = direct2 / norm(direct2);
  TP3x = x1 +  W*unit2(1);
  TP3y = y1 + W*unit2(2);
  BP3x = x1 - W*unit2(1);
  BP3y = y1 - W*unit2(2);
  plot(TP3x,TP3y,'o');
  plot(BP3x,BP3y,'o');
  TP4x = x2 +  W*unit2(1);
  TP4y = y2 + W*unit2(2);
  BP4x = x2 - W*unit2(1);
  BP4y = y2 - W*unit2(2);
  plot(TP4x,TP4y,'o');
  plot(BP4x,BP4y,'o');
  
   semi1x = x1 + W*cos(theta);
    semi1y = y1 + W * sin(theta);
   fill(semi1x, semi1y, 'r')
   semi1 = [semi1x;semi1y]';

   x = [BP3x BP4x  TP4x TP3x];
   y = [BP3y BP4y  TP4y TP3y];
 Link2 = [x(1) y(1); x(4) y(4);x(3) y(3);x(2) y(2)];
   fill(x,y,'r');


     % Plot the obstacle
    x_circle = xo + r*cos(theta);
    y_circle = yo + r * sin(theta);
    obstacle = [x_circle;y_circle]';
    [n,~] = size(obstacle);
    fill(x_circle, y_circle, 'k'); % Circular obstacle

    % Plot settings
    axis equal;
    xlim([-L1-L2, L1+L2]);
    ylim([-L1-L2, L1+L2]);
    xlabel('X');
    ylabel('Y');
    title('Two-Link Manipulator with Circular Obstacle');
    hold off;
    TF = false;
    for i = 1:n                     %checking if obstacle hits link1
    q = obstacle(i,:);
    P = Link1;
    inside = isPointInConvexPolygon(q, P);
        if inside == true
        TF = true;
        collision = 1;
        return;
        end
    end 

    for i = 1:n                     %checking if obstacle hits link2
    q = obstacle(i,:);
    P = Link2;
    inside = isPointInConvexPolygon(q, P);
        if inside == true
        TF = true;
        collision = 2;
         return;
        end
    end 

    for i = 1:n                     %checking if obstacle hits semi0
    q = obstacle(i,:);
    P = semi0;
     inside = isPointInConvexPolygon(q, P);
       if inside == true
        TF = true;
        collision = 1;
         return;
        end
    end 
     for i = 1:n                     %checking if obstacle hits semi1
    q = obstacle(i,:);
    P = semi1;
     inside = isPointInConvexPolygon(q, P);
       if inside == true
        TF = true;
        collision = 2;
         return;
        end
     end 
      for i = 1:n                     %checking if obstacle hits semi2
    q = obstacle(i,:);
    P = semi2;
     inside = isPointInConvexPolygon(q, P);
       if inside == true
        TF = true;
        collision = 2;
         return;
        end
     end 


end