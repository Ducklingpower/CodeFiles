clc
close all
clear
%%

s = tf('s');

plant      = (s+1)/((s+2)*(s+4));
%controllar = ((s+2)*(s+4)*(75*s+125))/(s^2 *(s+1)*(s+15));
% controllar = ((s+2)*(s+4)*(3*s+1))/(s^2 *(s+1)*(s+3));
controllar = ((s+2)*(s+4)*(48*s+64))/(s^2 *(s+1)*(s+12));
FeedForward = ((s^3 + 12*s^2 +48*s + 64))/((48*s+64)*(s/40 + 1)^2);


cltf = feedback(controllar*plant,1);
FT = minreal(FeedForward*cltf);

figure
margin(cltf)
grid on

figure
margin(FT)
grid on






