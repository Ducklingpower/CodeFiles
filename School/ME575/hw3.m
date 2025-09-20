clc
close all
clear 
%% part 1

t = 0:0.02:15;
y = -((3/2) * exp(-t)) + ((16/12)*exp(-2.*t)) - ((41/64)*cos(3.*t)-(3/65)*sin(3.*t));
yss = -((41/64)*cos(3.*t)-(3/65)*sin(3.*t));
yt = -((3/2) * exp(-t)) + ((16/12)*exp(-2.*t));

figure 
plot(t,y,LineWidth=3);
grid on 
hold on 
plot(t,yss,".",LineWidth=2)
plot(t,yt,LineWidth=3)
legend("Output y(y)","Pure steady state respones","Pure tansient respones")

%% part 2
K1 = 1;
K2 = 30;

for k = 1:4
s1(k) = lambertw(k, -(K1/3)*exp(1/3)) - 1/3;
s2(k) = lambertw(k, -(K2/3)*exp(1/3)) - 1/3;
end
transpose(s1)
transpose(s2)

%%
% plotting 

s = tf('s');


gr1 = (K1*exp(-s))/(3*s+1+exp(-s)*K1);
gd1 = (exp(-s))/(3*s+1+exp(-s)*K1);

gr2 = (K2*exp(-s))/(3*s+1+exp(-s)*K2);
gd2 = (exp(-s))/(3*s+1+exp(-s)*K2);


t = 0:0.01:15;

ref = ones(size(t));         
dis = sin(50*t);        

% Simulate response
y1_r = lsim(gr1, ref, t); % ref respones
y1_d = lsim(gd1, dis, t); % disterb respones
y1_total = y1_r + y1_d; % net respones

y2_r = lsim(gr2, ref, t); % ref respoens
y2_d = lsim(gd2, dis, t); % disterb respones
y2_total = y2_r + y2_d; % net respones


figure 
plot(t,y1_total,LineWidth =2)
grid on
legend("y(t) respones for K = 1")

figure
plot(t,y2_total,LineWidth =2)
grid on
legend("y(t) respones for K = 10")


%% part 3 

% plotting bode plot 
% Nyquist of L(s) = exp(-s)/(3s+1)

s = tf('s');

L = tf(1, [3 1]);      
L.InputDelay = 1;     

% Nyquist plot
figure; nyquist(L); grid on;
title('Nyquist Plot of L(s) = e^{-s}/(3s+1)');

hold on; plot(-1,0,'rx','MarkerSize',10,'LineWidth',2); hold off;

% bode plot (margins)
figure
margin(L)


%platting for gain increase of 30---

L = tf(30, [3 1]);      
L.InputDelay = 1;     

% Nyquist plot
figure; nyquist(L); grid on;
title('Nyquist Plot of L(s) = e^{-s}/(3s+1)');

hold on; plot(-1,0,'rx','MarkerSize',10,'LineWidth',2); hold off;

% bode plot (margins)
figure
margin(L)
