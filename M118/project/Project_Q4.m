function Project_Q4()

clc;
clear;
close all;
function res = Problem_4_bvp4c(y0,yL,v)
Tinf = v(5);

D2 = v(6);

L = v(7);

T0 = v(3);

TL = v(4);

k = v(8);

h = v(1);

D1 = v(2);

a = (D2-D1)/L;


res = [y0(1)-T0; yL(1)-TL];

end

L = 8/100;
T0 = 150;
Tinf = 20;
D1 = 1.5/100;
D2 = 0.75/100;
k = 200;
h = 100;
TL = 40;
x = 0:0.001:L;
a = (D2-D1)/L;

%part 1 shooting
const = [h D1 T0 TL Tinf D2 L k];
s1 = (TL-T0)/L;
s2 = 0.8*s1;

[~,y1] = ode45(@function4,[0 L],[T0 s1],[],const);
[~,y2] = ode45(@function4,[0 L],[T0 s2],[],const);
hold on;
Ts2 = y2(end,1);
Ts1 = y1(end,1);



s = s1-(Ts1-TL)/(Ts1-Ts2)*(s1-s2);
[x1,y3] = ode45(@function4,[0 L],[T0 s],[],const);
figure(1)
plot(x1,y3(:,1),'*')
grid on
set(gca,'GridColor','r',linewidth = 2)
 set(gca,'color',[.5 .5 .5])




%BVP4C Matlab built in 
soli = bvpinit(x,[2 2]);
sol = bvp4c(@function4,@Problem_4_bvp4c,soli, [], const);
Tbvp = deval(sol,x);
plot(x,Tbvp(1,:),'r.');


%Finite difference method
NUM_ELEMENTS = 10;
xfds = linspace(0,L,NUM_ELEMENTS+2);
dxs =  xfds(2)-xfds(1);

for q = 1: NUM_ELEMENTS
    beta(q) = ((dxs^2)*4*h*(-Tinf))/(k*(D1+a*xfds(q)));
end
m = zeros(NUM_ELEMENTS);
m(1,1) = -2-(dxs^2/ ...
    (D1+a*xfds(1)))*4*h/k;
m(1,2) = 1+((a*dxs) ...
    /(D1+a*xfds(1)));
m(end,end-1) = 1-((a*dxs) ...
    /(D1+a*xfds(end)));
m(end,end) = -2-(dxs^2/ ...
    (D1+a*xfds(1)))*4*h/k;

for z = 2: NUM_ELEMENTS -1
    m(z,z-1) = 1-((a*dxs)/ ...
        (D1+a*xfds(z))); 
    m(z,z) = -2-(dxs^2/ ...
        (D1+a*xfds(z)))*4*h/k;
    m(z,z+1) = 1+((a*dxs) ...
        /(D1+a*xfds(z)));
end
C = zeros(NUM_ELEMENTS,1);C(1) = ((dxs^2*4*h) ...
    /(k*(D1+a*xfds(1))))*(TL-Tinf)+ T0*(((a*dxs) ...
    /(D1+a*xfds(1)))-1);
C(end) = ((dxs^2*4*h)/ ...
    (k*(D1+a*xfds(end))))*(TL-Tinf)-TL*(((a*dxs) ...
    /(D1+a*xfds(1)))+1);
Bs = beta' + C;Tfds = m \ Bs;Tfds = [T0; Tfds; TL];
plot(xfds,Tfds,'o',LineWidth=2);
hold on;
title('First Boundary Condition');
legend('Shooting','BVP4C','Finite Difference')


conts = [h D1 T0 0 Tinf D2 L k];
s1 = (T0-Tinf)/L;
s2 = 0.8*s1;
[~,y2] = ode45(@function4,[0 L],[T0 s2],[],conts);

[~,y1] = ode45(@function4,[0 L],[T0 s1],[],conts);




Ts1 = y1(end,1);
Ts2 = y2(end,1);
f1 = pi*D2*L*h*(Ts1-Tinf)+0.25*D2^2*k*pi*y1(end,2);
f2 = pi*D2*L*h*(Ts2-Tinf)+0.25*D2^2*pi*k*y2(end,2);
s = s1+((f1*(-s2+s1))/(f2-f1));
[x1,y3] = ode45(@function4,[0 L],[T0 s],[],const);

figure
plot(x1,y3(:,1),'x',LineWidth=2)
grid on

 set(gca,'color',[.5 .5 .5])
set(gca,'GridColor','r',linewidth = 2)

hold on;
function res = Problem_4_bvp4c2(y0,yL,~)

a = (D2-D1)/L;


res = [y0(1)-T0; yL(1)*h*pi*D2*L+0.25*pi*D2^2*k*yL(2) - h*Tinf*pi*D2*L];

end

soli = bvpinit(x,[2 2]);
sol = bvp4c(@function4,@Problem_4_bvp4c2,soli, [], const);
Tbvp = deval(sol,x);
plot(x,Tbvp(1,:),'r.');


NUM_ELEMENTS = 10;
xfds = linspace(0,L,NUM_ELEMENTS+2);
dxs =  xfds(2)-xfds(1);

for q = 1: NUM_ELEMENTS
    beta(q) = ((dxs^2)*4*h*(-Tinf)) ...
        /(k*(D1+a*xfds(q)));
end
m = zeros(NUM_ELEMENTS);
m(end,end) = (h+(k/dxs));
m(1,1) = -2-(dxs^2/(D1+a*xfds(1)))*4*h/k;
m(end,end-1) = -k/dxs;
m(1,2) = 1+((a*dxs) ...
    /(D1+a*xfds(1)));

for z = 2: NUM_ELEMENTS -1
   m(z,z-1) = 1-((a*dxs) ... 
       /(D1+a*xfds(z))); 
    m(z,z) = -2-(dxs^2/(D1+a*xfds(z)))*4*h/k;
    m(z,z+1) = 1+((a*dxs)/(D1+a*xfds(z)));
end
C = zeros(NUM_ELEMENTS,1);
C(1) = ((dxs^2*4*h)/(k*(D1+a*xfds(1))))*(TL-Tinf)+ T0*(((a*dxs)/(D1+a*xfds(1)))-1);
C(end) = h*Tinf;
Bs = beta' + C;
Tfds = m \ Bs;
Tfds = [T0; Tfds; TL];

plot(xfds,Tfds,'o',LineWidth=2);
hold on;
title('Second Boundary')
legend('Shoot method','BVP4C','Finite Difference')



    function dTdx = function4(x,T,~)
Dx = (D1+a*x);
dTdx = zeros(2,1);
T2 = T(2);
T1 = T(1);
dTdx(1) = T2;
dTdx(2) = (1/(Dx))*(((4*h)/k*(T1-Tinf))-(2*a*T2));
end



end