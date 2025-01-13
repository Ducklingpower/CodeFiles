clc
clear 
Po = 101.325;



To = 44; %Celsius
Psat = 9.112;
RH = 1.6835/ Psat;

Pv = Psat*(RH);
Pa = Po-Pv;
omega = 0.622 * Pv/(Po-Pv);
h = 1.005*To + omega*(2500 + 1.9*To);
v = (To+273)*(1+omega)/((Pa*1000)/287+(Pv*1000)/462);
% 
% Tdry = 44;
% Twet = 24;
% Psat_wet = 2.986;
% hvTd = 2581 ;
% hvTw = 2545;
% hfTw = 100.6;
% w2 = 0.622*Psat_wet/(Po-Psat_wet);
% omega = (1.005*(Twet-Tdry) + w2*(hvTw-hfTw))/(hvTd-hfTw);
% 
% 
% Pv = (omega * Po)/(0.622+omega);

