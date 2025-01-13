function Project_Q1()


clear ,
clc,
close all

y_prime = @(t,y) cos(t)^2+sin(t)*y;
time  = [0,50];
[t,y] = RK4(y_prime,time,0);

[tt,yy] = ode45(y_prime,time,0);

function  [storage2,storage]= RK4(funcHandle,t_span,IC)
   
step_size = 0.1;
y = IC; 
t1 = t_span(1);
t2 = t_span(2);
t = t1;
storage = zeros(length(t1:step_size:t2),1);
storage2=zeros(length(t1:step_size:t2),1);
k = 1;
for i = t1:step_size:t2
    
storage(k,1) = y;
k1 = funcHandle(t,y);
k2 = funcHandle(t+(step_size/2),y+(step_size*(k1/2)));
k3 = funcHandle(t+(step_size/2),y+(step_size*(k2/2)));
k4 = funcHandle(t+(step_size),y+(step_size*k3));
y = y+(step_size./6).*(k1+2*k2+2*k3+k4);
t = t+step_size;

storage2(k,1) = i;
k=k+1;
end

end



figure('Name','o is RK4 and line is ode45')
grid
plot(t,y,"o",'LineWidth',1)
title('o is RK4 and line is ode45')
hold on 
plot(tt,yy,"linewidth",1.5)
end