clc
clear
close all
%% PartA
%% Params
ms=1085/2;    %kg
m1 = 40;      %kg
m2 = 40;      %kg
k1 = 10000;   %N/m  
k2 = 10000;   %N/m
c1 = 0;   
c2 = 0;
k1t = 150000; %N/m
k2t = 150000; %N/m
a1 = 0.7;     %m
a2 = 0.75;    %m
I = 820;      %kg m^2
kr = 0;

%% Problem 6 A,B,C
for i = 1:3
    if i ==1
    kr =0;
    elseif i == 2
    kr = 10000;

    elseif i == 3
    kr =50000;
    end

IC = [0 0 0 0 0 0 0 0];

%% Ax + BU

A =[0 0 0 0 1 0 0 0;
    0 0 0 0 0 1 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1;
    (-k1-k2)/ms (-a2*k2+a1*k1)/ms k1/ms k2/ms (-c1-c2)/ms (-a2*c2+a1*c1)/ms c1/ms c2/ms;
    (-a2*k2+a1*k1)/I (-(k1*a1^2) - (k2*a2^2) + kr)/I (-a1*k1)/I (a2*k2)/I (-a2*c2+a1*c1)/I (-(c1*a1^2)-(c2*a2^2))/I (-a1*c1)/I (a2*c2)/I;
    k1/m1 (-a1*k1)/m1 (-k1-k1t)/m1 0 c1/m1 (-a1*c1)/m1 (-c1)/m1 0;
    k2/m2 (a2*k2)/m2 0 (-k2-k2t)/m2 c2/m2 (a2*c2)/m2 0 (-c2)/m2;
];




B = [
   0 0
   0 0; 
   0 0;
   0 0;
   (k1t/m1) 0;%m1 tire
   0 (k1t/m2);%m2 tire 
   0 0;
   0 0;
   ];

C = [1 0 0 0 0 0 0 0 ;
     0 1 0 0 0 0 0 0 ;
     0 0 1 0 0 0 0 0 ;
     0 0 0 1 0 0 0 0 ;
     0 0 0 0 1 0 0 0 ;
     0 0 0 0 0 1 0 0 ;
     0 0 0 0 0 0 1 0 ;
     0 0 0 0 0 0 0 1 ;
    ];


D = zeros(8,2);

%% natral frequency:
AA = zeros(4,4);
AA(1,:) = A(5,1:4);
AA(2,:) = A(6,1:4);
AA(3,:) = A(7,1:4);
AA(4,:) = A(8,1:4);


eigan_vals = abs(eig(AA));
Natral_freq = (sqrt(eigan_vals))/(2*pi);

%% Mode shapes

M = [ms 0 0 0;
      0 I 0 0;
      0 0 m1 0;
      0 0 0 m2];
K = [k1+k2 a2*k2-a1*k1 -k1 -k2;
     a2*k2-a1*k1 k1*a1^2+k2*a2^2+kr a1*k1 -a2*k2;
     -k1 a1*k1 k1+k1t 0;
     -k2 -a2*k2 0 k2+k2t];

A1 = M^(-1)*K;
[EV,EVal] = eig(A1);
EVal  =(sqrt(EVal))/(2*pi);
mode = EV;

if i==1
mode1 = mode;
resonant1 = diag(EVal);
figure(Name='Mode shapes (Kr = 0)')
tiledlayout(2,2)
nexttile
plot([1 2 3 4],mode(1,:))
title([EVal(1,1)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(2,:))
title([EVal(2,2)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(3,:))
title([EVal(3,3)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(4,:))
title([EVal(4,4)] + "Hz")
grid on
elseif i==2
    mode2 =mode;
    resonant2 = diag(EVal);
   
figure(Name='Mode shapes (Kr = 10000)')
tiledlayout(2,2)
nexttile
plot([1 2 3 4],mode(1,:))
title([EVal(1,1)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(2,:))
title([EVal(2,2)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(3,:))
title([EVal(3,3)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(4,:))
title([EVal(4,4)] + "Hz")
grid on

elseif i==3
    resonant3 = diag(EVal);
    mode3 =mode;
    figure(Name='Mode shapes (Kr = 50000)')
tiledlayout(2,2)
nexttile
plot([1 2 3 4],mode(1,:))
title([EVal(1,1)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(2,:))
title([EVal(2,2)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(3,:))
title([EVal(3,3)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(4,:))
title([EVal(4,4)] + "Hz")
grid on
end
end

%% Ax + Bu
A =[0 0 0 0 1 0 0 0;
    0 0 0 0 0 1 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1;
    (-k1-k2)/ms (-a2*k2+a1*k1)/ms k1/ms k2/ms (-c1-c2)/ms (-a2*c2+a1*c1)/ms c1/ms c2/ms;
    (-a2*k2+a1*k1)/I (-(k1*a1^2) - (k2*a2^2) - kr)/I (-a1*k1)/I (a2*k2)/I (-a2*c2+a1*c1)/I (-(c1*a1^2)-(c2*a2^2))/I (-a1*c1)/I (a2*c2)/I;
    k1/m1 (-a1*k1)/m1 (-k1-k1t)/m1 0 c1/m1 (-a1*c1)/m1 (-c1)/m1 0;
    k2/m2 (a2*k2)/m2 0 (-k2-k2t)/m2 c2/m2 (a2*c2)/m2 0 (-c2)/m2;
];




B = [
   0 0
   0 0; 
   0 0;
   0 0;
   (k1t/m1) 0;%m1 tire
   0 (k1t/m2);%m2 tire 
   0 0;
   0 0;
   ];

C = [1 0 0 0 0 0 0 0 ;
     0 1 0 0 0 0 0 0 ;
     0 0 1 0 0 0 0 0 ;
     0 0 0 1 0 0 0 0 ;
     0 0 0 0 1 0 0 0 ;
     0 0 0 0 0 1 0 0 ;
     0 0 0 0 0 0 1 0 ;
     0 0 0 0 0 0 0 1 ;
    ];


D = zeros(8,2);





%% simulink
kr = -10000;

for i = 1:6
  
    kr = kr+10000;
sr= 0.00001;
tmax=30;
t_span = 0:sr:tmax;

T = .5;
r = 0.2;
f = 1;
% road stuff
roadfl = @(t) 0.1*cos(2*pi*(((r-f)/(2*T)*(t).^2)));
road_inputfl = timeseries(roadfl(t_span'),t_span);

roadfr = @(t) 0.1*sin(2*pi*(((r-f)/(2*T)*(t).^2 )));
road_inputfr = timeseries(roadfr(t_span'),t_span);


u_fl = road_inputfl;     %front left tire input
u_fr = road_inputfr;     %front right tire input

road_input_stored = zeros(length(u_fl.data),2);
road_input_stored(:,1) = u_fr.data;
road_input_stored(:,2) = u_fl.data;

time = u_fr.Time;



A =[0 0 0 0 1 0 0 0;
    0 0 0 0 0 1 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1;
    (-k1-k2)/ms (-a2*k2+a1*k1)/ms k1/ms k2/ms (-c1-c2)/ms (-a2*c2+a1*c1)/ms c1/ms c2/ms;
    (-a2*k2+a1*k1)/I (-(k1*a1^2) - (k2*a2^2) - kr)/I (-a1*k1)/I (a2*k2)/I (-a2*c2+a1*c1)/I (-(c1*a1^2)-(c2*a2^2))/I (-a1*c1)/I (a2*c2)/I;
    k1/m1 (-a1*k1)/m1 (-k1-k1t)/m1 0 c1/m1 (-a1*c1)/m1 (-c1)/m1 0;
    k2/m2 (a2*k2)/m2 0 (-k2-k2t)/m2 c2/m2 (a2*c2)/m2 0 (-c2)/m2;
];


output = sim('ME226Sim.slx',[0 tmax]);
states = output.states.data;


%% calcs



Y =fft(states(:,2));                      % two sided fft
samples = tmax/sr;                    % num of samples
Sfq = 1/sr;                           % Sampling frequency 
k = 0:samples/2;                      % contant for one sided fft
fequencyX =k*Sfq/samples;             % Computing frequency x-axis, frequncy axis to plot fft on.
Y_Onesided = abs(Y(1:samples/2+1));   % One sided fft, y-axis
Y_Onesided(1)=0;

figure(4)
plot(fequencyX,Y_Onesided,LineWidth=1)
xlabel('Frequency')
ylabel('amp');
xlim([0 5])
grid on

psdx = (1/(Sfq*samples)) * Y_Onesided.^2; %Power of ones sided fft.
psdx(2:end-1) = 2*psdx(2:end-1);          %scaling
pow2db(psdx);
hold on                            %converting psdx to dB
  legend('Kr = 0 ','Kr = 10000 ','Kr = 20000 ','Kr = 30000 ','Kr = 40000 ','Kr = 50000 ')

 figure(5)
plot(fequencyX,pow2db(psdx))
grid on
title("Periodogram Using FFT")
xlabel("Frequency (Hz)")
ylabel("Power/Frequency (dB/Hz)")
ylim([-50 45])
xlim([0 20])
hold on
  legend('Kr = 0 ','Kr = 10000 ','Kr = 20000 ','Kr = 30000 ','Kr = 40000 ','Kr = 50000 ')
end
%% Last part q6:
kr = 18790;
% for i = 1:200
%     kr = kr+5;

sr= 0.00001;
tmax=30;
t_span = 0:sr:tmax;

T = .5;
r = 0.2;
f = 1;
% road stuff
roadfl = @(t) 0.1*cos(2*pi*(((r-f)/(2*T)*(t).^2)));
road_inputfl = timeseries(roadfl(t_span'),t_span);

roadfr = @(t) 0.1*sin(2*pi*(((r-f)/(2*T)*(t).^2 )));
road_inputfr = timeseries(roadfr(t_span'),t_span);


u_fl = road_inputfl;     %front left tire input
u_fr = road_inputfr;     %front right tire input

road_input_stored = zeros(length(u_fl.data),2);
road_input_stored(:,1) = u_fr.data;
road_input_stored(:,2) = u_fl.data;

time = u_fr.Time;



A =[0 0 0 0 1 0 0 0;
    0 0 0 0 0 1 0 0;
    0 0 0 0 0 0 1 0;
    0 0 0 0 0 0 0 1;
    (-k1-k2)/ms (-a2*k2+a1*k1)/ms k1/ms k2/ms (-c1-c2)/ms (-a2*c2+a1*c1)/ms c1/ms c2/ms;
    (-a2*k2+a1*k1)/I (-(k1*a1^2) - (k2*a2^2) - kr)/I (-a1*k1)/I (a2*k2)/I (-a2*c2+a1*c1)/I (-(c1*a1^2)-(c2*a2^2))/I (-a1*c1)/I (a2*c2)/I;
    k1/m1 (-a1*k1)/m1 (-k1-k1t)/m1 0 c1/m1 (-a1*c1)/m1 (-c1)/m1 0;
    k2/m2 (a2*k2)/m2 0 (-k2-k2t)/m2 c2/m2 (a2*c2)/m2 0 (-c2)/m2;
];


output = sim('ME226Sim.slx',[0 tmax]);
states = output.states.data;






Y =fft(states(:,2));                      % two sided fft
samples = tmax/sr;                    % num of samples
Sfq = 1/sr;                           % Sampling frequency 
k = 0:samples/2;                      % contant for one sided fft
fequencyX =k*Sfq/samples;             % Computing frequency x-axis, frequncy axis to plot fft on.
Y_Onesided = abs(Y(1:samples/2+1));   % One sided fft, y-axis
Y_Onesided(1)=0;

Y_1 =fft(states(:,1));                      % two sided fft
samples = tmax/sr;                    % num of samples
Sfq = 1/sr;                           % Sampling frequency 
k = 0:samples/2;                      % contant for one sided fft
fequencyX_1 =k*Sfq/samples;             % Computing frequency x-axis, frequncy axis to plot fft on.
Y_Onesided_1 = abs(Y_1(1:samples/2+1));   % One sided fft, y-axis
Y_Onesided_1(1)=0;



figure(6)

plot(fequencyX,Y_Onesided,LineWidth=1)
xlabel('Frequency')
ylabel('amp');

hold on
plot(fequencyX_1,Y_Onesided_1,LineWidth=1)
xlim([0 12])
legend('Roll respons','Bounce respons')
grid on


psdx = (1/(Sfq*samples)) * Y_Onesided.^2; %Power of ones sided fft.
psdx(2:end-1) = 2*psdx(2:end-1);          %scaling
pow2db(psdx);

psdx_1 = (1/(Sfq*samples)) * Y_Onesided_1.^2; %Power of ones sided fft.
psdx_1(2:end-1) = 2*psdx_1(2:end-1);          %scaling
pow2db(psdx_1);
hold on                            %converting psdx to dB
 
 figure(7)
plot(fequencyX,pow2db(psdx))
grid on
title("Periodogram Using FFT")
xlabel("Frequency (Hz)")
ylabel("Power/Frequency (dB/Hz)")
hold on
plot(fequencyX,pow2db(psdx_1))
grid on
title("Periodogram Using FFT")
legend('Roll respons','Bounce respons')
ylim([-80 30])
xlim([0 20])
hold on

%% Mode shapes for kr = 18790
M = [ms 0 0 0;
      0 I 0 0;
      0 0 m1 0;
      0 0 0 m2];
K = [k1+k2 a2*k2-a1*k1 -k1 -k2;
     a2*k2-a1*k1 k1*a1^2+k2*a2^2+kr a1*k1 -a2*k2;
     -k1 a1*k1 k1+k1t 0;
     -k2 -a2*k2 0 k2+k2t];

A1 = M^(-1)*K;
[EV,EVal] = eig(A1);

mode = EV;


mode1 = mode;
resonant1 = Natral_freq;
EVal  =(sqrt(EVal))/(2*pi);

figure(Name='Mode shapes (Kr = 18790)')
tiledlayout(2,2)
nexttile
plot([1 2 3 4],mode(1,:))
title([EVal(1,1)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(2,:))
title([EVal(2,2)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(3,:))
title([EVal(3,3)] + "Hz")
grid on

nexttile
plot([1 2 3 4],mode(4,:))
title([EVal(4,4)] + "Hz")
grid on






