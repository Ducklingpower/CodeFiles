clc;
clear;
close all;
%% Paramsss
ms = 300;

mfl = 4;
mrl = 4;
mfr = 4;
mrr = 4;

kfr =  30000;
krr =  30000;
kfl =  30000;
krl =  30000;

kft = 136000;
krt = 136000;

cfr = 200;
crr = 200;
cfl = 200;
crl = 200;

lr  =   0.7;
lf  =   0.8;
laa =   0.635;
lbb =   0.635;

I_roll  =   49.960975;
I_pitch =   283.33654;
I_yaw   =   272.56808;



%% Mass and stifness matrix
M = zeros(7,7);

M(1,1) = ms;
M(2,2) = mfl;
M(3,3) = mfr;
M(4,4) = mrl;
M(5,5) = mrr;
M(6,6) = I_pitch;
M(7,7) = I_roll;

K =[
 (-kfl-kfr-krl-krr) (kfl) (kfr) (krl) (krr) (-kfl*lf-kfr*lf+krl*lr+krr*lr) (-kfl*laa+kfr*laa+krl*laa-krr*laa) ;
 (kfl) (-kfl-kft) 0 0 0 (kfl*lf) (kfl*laa);
 (kfr) 0 (-kfr-kft) 0 0 (kfr*lf) (kfr*laa);
 (krl) 0 0 (-krl-krt) 0 (krl*lr) (krl*laa);
 (krr) 0 0 0 (-krr-krt) (krr*lr) (krr*laa);
 (-kfl*lf-kfr*lr+krl*lf+krr*lr) -(kfl*lf) -(kfr*lr) (krl*lf) (krr*lr) (-kfl*lf^2-kfr*lr^2-krl*lf^2-krr*lr^2) 0;
 (-kfl*laa-kfr*lbb+krl*laa+krr*lbb) -(kfl*laa) (kfr*lbb) -(krl*laa) (krr*lbb) 0 (-kfl*laa^2-kfr*lbb^2-krl*laa^2-krr*lbb^2)
  ];

C =[
 (-cfl-cfr-crl-crr) (cfl) (cfr) (crl) (crr) (-cfl*lf-cfr*lf+crl*lr+crr*lr) (-cfl*laa+cfr*laa+crl*laa-crr*laa);
 (cfl) (-cfl) 0 0 0 (cfl*lf) (cfl*laa);
 (cfr) 0 (-cfr) 0 0 (cfr*lf) (cfr*laa);
 (crl) 0 0 (-crl) 0 (crl*lr) (crl*laa);
 (crr) 0 0 0 (-crr) (crr*lr) (crr*laa);
 (-cfl*lf-cfr*lr+crl*lf+crr*lr) -(cfl*lf) -(cfr*lr) (crl*lf) (crr*lr) (-cfl*lf^2-cfr*lr^2-crl*lf^2-crr*lr^2) 0;
 (-cfl*laa-cfr*lbb+crl*laa+crr*lbb) -(cfl*laa) (cfr*lbb) -(crl*laa) (crr*lbb) 0 (-cfl*laa^2-cfr*lbb^2-crl*laa^2-crr*lbb^2)
  ];
K=-K;
C = -C;

A1 = M^(-1)*K;
[EV,EVal] = eig(A1);
EVal  =(sqrt(EVal))/(2*pi);
NatralFrequency = diag(EVal);

%% Transfer function matrix [H] and modes

w = 0:0.001:250;                     %frequency limit radians

[H,wn] = calculateFRF(M,K,w,"N");   % output is in radians per sec
H = (H)./(2*pi);
wn = wn./(2*pi);
w = w/(2*pi);

figure(2)
    for i = 1:1
     semilogy(w,abs(squeeze(H(1,1,:))),linewidth=2)
     grid on
     hold on
   ylabel('log(H34)')
   xlabel('Frequency (Hz)')
     title('Frequency Respones Function')
    end



%% Time span and sampling rate
sr= 0.0001;
tmax=40;
t_span = 0:sr:tmax;

% parameters for swept sign
    T = 0.5;
    r = 0.2;
    f = 1;

rideHeight = 0;

%% Road input (janky) as a function meters + accleoration vehicle acceloration Input

noiseLevel = 0;
noise =rand(100000,1)*noiseLevel;
                         
%Vehicle acceloration a(t)
    acceloration_Func_long= @(t) 0;                                      %m/s^2 long                       
    Vehic_acc_long = timeseries(acceloration_Func_long(t_span'),t_span);
    Vehicle_acceloration_long = Vehic_acc_long.data;

    acceloration_Func_lat= @(t) 0;                                      %m/s^2 lat                       
    Vehic_acc_lat = timeseries(acceloration_Func_lat(t_span'),t_span);
    Vehicle_acceloration_lat = Vehic_acc_lat.data;


% Calc velocity and position
    x_i = 0;
    v_i = 1;    

    for i = 1:length(t_span)
        Vehicle_Velocity(1,i) = v_i + Vehicle_acceloration_long(i,1).*t_span(1,i); % m/s 
        position(1,i) = x_i + v_i*t_span(1,i) + 0.5*Vehicle_acceloration_long(i,1).*t_span(1,i).^2;
    end


% road inputs r(x)
    % roadfl = @(x) 1*sin(2*pi*(((r-f)/(2*T)*x.^2 ))) + noise(ceil(x*1+2000+1));
    % road_inputfl = timeseries(roadfl(position'),t_span);
    % 
    % roadfr = @(x) 1*sin(2*pi*(((r-f)/(2*T)*x.^2 ))) + noise(ceil(x*1+2000+1));
    % road_inputfr = timeseries(roadfr(position'),t_span);
    % 
    % roadrr = @(x) 1*sin(2*pi*(((r-f)/(2*T)*x.^2 ))) + noise(ceil(x*1+2000+1));
    % road_inputrr = timeseries(roadrr(position'),t_span);
    % 
    % roadrl = @(x) 1*sin(2*pi*(((r-f)/(2*T)*x.^2 ))) + noise(ceil(x*1+2000+1));
    % road_inputrl = timeseries(roadrl(position'),t_span);

    roadfl = @(x) 1*sin(2*pi*(x));
    road_inputfl = timeseries(roadfl(position'),t_span);

    roadfr = @(x) 0.5*sin(2*pi*(x)*2);
    road_inputfr = timeseries(roadfr(position'),t_span);

    roadrr = @(x) 2*cos(2*pi*(x));
    road_inputrr = timeseries(roadrr(position'),t_span);

    roadrl = @(x) 1*sin(2*pi*(x)*2+pi/4);
    road_inputrl = timeseries(roadrl(position'),t_span);


    u_fl = road_inputfl;     %front left tire input
    u_fr = road_inputfr;     %front right tire input
    u_rl = road_inputrl;     %rear left tire input
    u_rr = road_inputrr;     %rear right tire input
    road_input_stored = zeros(length(u_fl.data),4);
    road_input_stored(:,1) = u_fr.data;
    road_input_stored(:,2) = u_fl.data;
    road_input_stored(:,3) = u_rr.data;
    road_input_stored(:,4) = u_rl.data;
    time = u_fr.Time;




%% State space 

% inital conditions
    IC = [0 0 0 0 0 0 0 0 0 0 0 0 0 0];
    

%State matrix    
    A =[
     0 1 0 0 0 0 0 0 0 0 0 0 0 0;
     (-kfl-kfr-krl-krr)/ms (-cfl-cfr-crl-crr)/ms (kfl)/ms (cfl)/ms (kfr)/ms (cfr)/ms (krl)/ms (crl)/ms (krr)/ms (crr)/ms (-kfl*lf-kfr*lf+krl*lr+krr*lr)/ms (-cfl*lf-cfr*lf+crl*lr+crr*lr)/ms (-kfl*laa+kfr*laa+krl*laa-krr*laa)/ms (-cfl*laa+cfr*laa+crl*laa-crr*laa)/ms;
     0 0 0 1 0 0 0 0 0 0 0 0 0 0;
     (kfl)/mfl (cfl)/mfl (-kfl-kft)/mfl (-cfl)/mfl 0 0 0 0 0 0 (kfl*lf)/mfl (cfl*lf)/mfl (kfl*laa)/mfl (cfl*laa)/mfl;
     0 0 0 0 0 1 0 0 0 0 0 0 0 0;
     (kfr)/mfr (cfr)/mfr 0 0 (-kfr-kft)/mfr (-cfr)/mfr 0 0 0 0 (kfr*lf)/mfr (cfr*lf)/mfr (kfr*laa)/mfr (cfr*laa)/mfr;
     0 0 0 0 0 0 0 1 0 0 0 0 0 0;
     (krl)/mrl (crl)/mrl 0 0 0 0 (-krl-krt)/mrl (-crl)/mrl 0 0 (krl*lr)/mrl (crl*lr)/mrl (krl*laa)/mrl (crl*laa)/mrl;
     0 0 0 0 0 0 0 0 0 1 0 0 0 0;
     (krr)/mrr (crr)/mrr 0 0 0 0 0 0 (-krr-krt)/mrr (-crr)/mrr (krr*lr)/mrr (crr*lr)/mrr (krr*laa)/mrr (crr*laa)/mrr;
     0 0 0 0 0 0 0 0 0 0 0 1 0 0;
     (-kfl*lf-kfr*lr+krl*lf+krr*lr)/I_pitch (-cfl*lf-cfr*lr+crl*lf+crr*lr)/I_pitch -(kfl*lf)/I_pitch -(cfl*lf)/I_pitch -(kfr*lr)/I_pitch -(cfr*lr)/I_pitch (krl*lf)/I_pitch (crl*lf)/I_pitch (krr*lr)/I_pitch (crr*lr)/I_pitch (-kfl*lf^2-kfr*lr^2-krl*lf^2-krr*lr^2)/I_pitch (-cfl*lf^2-cfr*lr^2-crl*lf^2-crr*lr^2)/I_pitch 0 0;
     0 0 0 0 0 0 0 0 0 0 0 0 0 1;
     (-kfl*laa-kfr*lbb+krl*laa+krr*lbb)/I_roll (-cfl*laa-cfr*lbb+crl*laa+crr*lbb)/I_roll -(kfl*laa)/I_roll -(cfl*laa)/I_roll (kfr*lbb)/I_roll (cfr*lbb)/I_roll -(krl*laa)/I_roll -(crl*laa)/I_roll (krr*lbb)/I_roll (crr*lbb)/I_roll 0 0 (-kfl*laa^2-kfr*lbb^2-krl*laa^2-krr*lbb^2)/I_roll (-cfl*laa^2-cfr*lbb^2-crl*laa^2-crr*lbb^2)/I_roll
      ];


% Road inputs and external forces
    B = [
       0 0 0 0 0 0;
       0 0 0 0 0 0;
       0 0 0 0 0 0;
       (kft/mfl) 0 0 0 0 0;   %front left tire
       0 0 0 0 0 0;
       0 (kft/mfr) 0 0 0 0;   %front right tire
       0 0 0 0 0 0;
       0  0 (krt/mfr) 0 0 0;  %rear left tire
       0 0 0 0 0 0;
       0 0 0 (krt/mrr) 0 0;   %rear right tire
       0 0 0 0 0 0;
       0 0 0 0 1/I_pitch 0;   %Pitch
       0 0 0 0 0 0;
       0 0 0 0 0 1/I_roll];   %Roll


% Outputs 
    C = [1 0 0 0 0 0 0 0 0 0 0 0 0 0 ; 
          0 1 0 0 0 0 0 0 0 0 0 0 0 0 ;
          0 0 1 0 0 0 0 0 0 0 0 0 0 0 ;
          0 0 0 1 0 0 0 0 0 0 0 0 0 0 ;
          0 0 0 0 1 0 0 0 0 0 0 0 0 0 ;
          0 0 0 0 0 1 0 0 0 0 0 0 0 0 ;
          0 0 0 0 0 0 1 0 0 0 0 0 0 0 ;
          0 0 0 0 0 0 0 1 0 0 0 0 0 0 ;
          0 0 0 0 0 0 0 0 1 0 0 0 0 0 ;
          0 0 0 0 0 0 0 0 0 1 0 0 0 0 ;
          0 0 0 0 0 0 0 0 0 0 1 0 0 0 ;
          0 0 0 0 0 0 0 0 0 0 0 1 0 0 ;
          0 0 0 0 0 0 0 0 0 0 0 0 1 0 ;
          0 0 0 0 0 0 0 0 0 0 0 0 0 1 ;
          (-kfl-kfr-krl-krr)/ms (-cfl-cfr-crl-crr)/ms (kfl)/ms (cfl)/ms (kfr)/ms (cfr)/ms (krl)/ms (crl)/ms (krr)/ms (crr)/ms (-kfl*lf-kfr*lf+krl*lr+krr*lr)/ms (-cfl*lf-cfr*lf+crl*lr+crr*lr)/ms (-kfl*laa+kfr*laa+krl*laa-krr*laa)/ms (-cfl*laa+cfr*laa+crl*laa-crr*laa)/ms];



    D = zeros(15,6);
    D(15,5) = 1/ms;
%% running simulink, extracting from simulink


output = sim('RideModel_sim.slx',[0 tmax]);

states = output.states.data;
systemInputs = output.input.data;


%% calulations


% Solving ride height and corner locations

states(:,1) = states(:,1)+rideHeight;
fr = states(:,1)+lf*states(:,11)-laa*states(:,13);
fl = states(:,1)+lf*states(:,11)+lbb*states(:,13);
rr = states(:,1)-lr*states(:,11)+laa*states(:,13);
rl = states(:,1)-lr*states(:,11)-laa*states(:,13);



%fft calcs

Y =fft(states(:,1));                  % two sided fft
samples = tmax/sr;                    % num of samples
Sfq = 1/sr;                           % Sampling frequency 
k = 0:samples/2;                      % contant for one sided fft
fequencyX =k*Sfq/samples;             % Computing frequency x-axis, frequncy axis to plot fft on.
Y_Onesided = abs(Y(1:samples/2+1));   % One sided fft, y-axis
Y_Onesided(1)=0;


%PSD calcs

psdx = (1/(Sfq*samples)) * Y_Onesided.^2; %Power of ones sided fft.
psdx(2:end-1) = 2*psdx(2:end-1);          %scaling
pow2db(psdx);                             %converting psdx to dB


figure (Name='FFT')
stem(fequencyX,Y_Onesided,LineWidth=0.5)
xlabel('Frequency')
ylabel('amp');
xlim([0 15])


figure(Name='PSD')
semilogy(fequencyX,psdx)
grid on
title("Periodogram Using FFT")
xlabel("Frequency (Hz)")
ylabel("Power/Frequency (dB/Hz)")
xlim([0 15])

figure(Name = "Time doamin Respones")
plot(t_span,states(:,1),LineWidth=2)
hold on
plot(t_span,states(:,13),LineWidth=2)
hold on
plot(t_span,states(:,11),LineWidth=2)
grid on
title("Time Domain Respons")
xlabel("Time (s)")
ylabel("Position")
legend("m_s","\phi (Roll)","\theta (Pitch)")
%% varify road input reaches obove 200hz

Y =fft(systemInputs(:,1));                  % two sided fft
samples = tmax/sr;                    % num of samples
Sfq = 1/sr;                           % Sampling frequency 
k = 0:samples/2;                      % contant for one sided fft
fequencyX =k*Sfq/samples;             % Computing frequency x-axis, frequncy axis to plot fft on.
Y_Onesided = abs(Y(1:samples/2+1));   % One sided fft, y-axis
Y_Onesided(1)=0;


%PSD calcs

psdx = (1/(Sfq*samples)) * Y_Onesided.^2; %Power of ones sided fft.
psdx(2:end-1) = 2*psdx(2:end-1);          %scaling
pow2db(psdx);   

figure (Name='FFT')
stem(fequencyX,Y_Onesided,LineWidth=0.5)
xlabel('Frequency')
ylabel('amp');
xlim([0 15])


figure(Name='PSD')
semilogy(fequencyX,psdx)
grid on
title("Periodogram Using FFT")
xlabel("Frequency (Hz)")
ylabel("Power/Frequency (dB/Hz)")
xlim([0 15])

figure(100)
plot(t_span,systemInputs(:,1))
