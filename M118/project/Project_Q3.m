
function Project_Q3()
clear
close all
   lamda  = 5;%wave length of 5m
   v      = 2;%speed of 3m/s
   w      = (2*pi*v)/(lamda);
   m      = 250;             
   c      = 1000;               
   k      = 1600;              
            
   IC     = [0;0];
   t      = 0:.01:15;
[time,position] = ode45(@Vroom,t,IC);

figure('Name','Q3,P(c)')
plot(time,position(:,1))
title('Q3,P(c)')
grid on
xlabel('time')
ylabel('position')
[time,position] = ode45(@Vroom2,t,IC);

figure('Name','Q3,P(d)')
plot(time,position(:,1))
title('Q3,P(d)')
grid on
xlabel('time')
ylabel('position')

function dxdt = Vroom(t,x)                 
    dxdt(1) = x(2);
    dxdt(2) = -(k/m)*x(1)-(c/m)*x(2)+F(t);
    dxdt    = dxdt';
end

function dxdt = Vroom2(t,x)
     dxdt(1) = x(2);
     dxdt(2) = -(k/m)*x(1)-(c/m)*x(2)+F2(t);
        dxdt = dxdt';
end
function output = F(t)
         output = (k*0.5*cos(t*w)-c*0.5*w*sin(t*w))/m;
end

function output = F2(t)
    z      = .5*abs(cos(w.*v.*t));
    z_dot  = (-v.*w.*0.5.*cos(v.*w.*t).*sin(v.*w.*t))./(abs(cos(v.*w.*t)));
     output = (k.*z+c.*z_dot)./m;
%     output = z;
end
% 
% xx=F2(t);
%     figure(3)
%     plot(t,F2(t))
end
