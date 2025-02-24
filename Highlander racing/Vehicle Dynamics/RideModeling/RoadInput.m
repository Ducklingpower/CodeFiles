clc
clear
close all
%%


sr= 0.01;
tmax=10;
t_span = 0:sr:tmax;
n = linspace(.001, 10, length(t_span));

x_i = 0;
v_i = 0;
a_i = 0;

acceloration_Func_long= @(t) 10.^(-t);
Vehic_acc_long = timeseries(acceloration_Func_long(t_span'),t_span);
Vehicle_acceloration_long = 0*Vehic_acc_long.data;
Vehicle_Velocity = zeros(1, length(t_span));
position = zeros(1, length(t_span));

for i = 1:length(t_span)
        Vehicle_Velocity(1,i) = v_i + Vehicle_acceloration_long(i,1).*t_span(1,i); % m/s 
        position(1,i) = x_i + v_i*t_span(1,i) + 0.5*Vehicle_acceloration_long(i,1).*t_span(1,i).^2;
end

w = -2; % waviness of road (-2 is ISO standard)
Class = 64; % Road Level Definition depending on A-F
P = (Class*10^-6)*((n/0.1)).^w; % Road Classification PSD
loglog(n,P);
A = sqrt(2)*sqrt(n.*P);
phi =  rand(size(t_span));
Road = zeros(1, length(t_span));
y=0;
bar = waitbar(1,"wait boy");

for p=  1:8
    x=1;
for j = 1:length(t_span)
    waitbar((length(t_span)-(length(t_span)-j))/(length(t_span)),bar,"wait boy")
for i=1:length(t_span)-(length(t_span)-j)
   
    y = y + (A(i)*sin(2*pi*n(i)*t_span(i)+phi(i)*p*10));
    
end
Road(j,p) = y;
y=0;
end
end
% Y = A.*sin(2*pi*n.*t_span + phi + position);
%%
figure(1)
plot(t_span, Road);
title("Estimated road input")
xlabel('time (seconds)');
ylabel('Road Profile Height');
legend("phi*1","phi*2","phi*3","phi*4","phi*5","phi*6","phi*7","phi*8")
%% PSD 
figure(2)
for p = 1:8
Y =fft(Road(:,p));                  % two sided fft
samples = tmax/sr;                    % num of samples
Sfq = 1/sr;                           % Sampling frequency 
k = 0:samples/2;                      % contant for one sided fft
fequencyX =k*Sfq/samples;             % Computing frequency x-axis, frequncy axis to plot fft on.
Y_Onesided = abs(Y(1:samples/2+1));   % One sided fft, y-axis
Y_Onesided(1)=0;


%PSD calcs

psdx = (1/(Sfq*samples)) * Y_Onesided.^2; %Power of ones sided fft.
psdx(2:end-1) = 2*psdx(2:end-1);          %scaling
pow2db(psdx);    %converting psdx to dB


title("Of sample road input")
loglog(fequencyX,psdx);
hold on
% 
% figure(3)
% title("sample psd")
% loglog(t_span,P)

end
hold on 
% loglog(t_span,P)
legend("phi*1","phi*2","phi*3","phi*4","phi*5","phi*6","phi*7","phi*8")
%%

figure(100)
plot(1:length(phi),phi(1,:),".")