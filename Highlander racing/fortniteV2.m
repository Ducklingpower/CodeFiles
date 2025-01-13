
%% Params
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

cfr = 2000;
crr = 2000;
cfl = 2000;
crl = 2000;

lr  =   0.717267;
lf  =   0.808833;
laa =   0.635;
lbb =   0.635;

I_roll  =   49.960975;
I_pitch =   283.33654;
I_yaw   =   272.56808;

T = 0.5;
r = 0.2;
f = 1;

rideHeight = 0;

%% Time span and sampling rate
sr= 0.0001;
tmax=10;
t_span = 0:sr:tmax;

%% Road input (janky)
noiseLevel = 0;
noise =rand(100000,1)*noiseLevel;


roadfl = @(t) 0.1*sin(2*pi*(((r-f)/(2*T)*t.^2 ))) + noise(ceil(t*100+2000+1));
road_inputfl = timeseries(roadfl(t_span'),t_span);

roadfr = @(t) 0.1*sin(2*pi*(((r-f)/(2*T)*t.^2 ))) + noise(ceil(t*100+4000+1));
road_inputfr = timeseries(roadfr(t_span'),t_span);

roadrr = @(t) 0.1*sin(2*pi*(((r-f)/(2*T)*t.^2 ))) + noise(ceil(t*100+2000+1));
road_inputrr = timeseries(roadrr(t_span'),t_span);

roadrl = @(t) 0.1*sin(2*pi*(((r-f)/(2*T)*t.^2 ))) + noise(ceil(t*100+2000+1));
road_inputrl = timeseries(roadrl(t_span'),t_span);


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

N = [10 0];
phase = 5;

Nfl1 = 1;
Nfl2 = 0;
Nfl3 = 1;

Nfr1 = 1;
Nfr2 = 0;
Nfr3 = 1;

Nrl1 = 1;
Nrl2 = 0;
Nrl3 = 1;

Nrr1 = 1;
Nrr2 = 0;
Nrr3 = 1;



%% State space 
IC = [0 0 0 0 0 0 0 0 0 0 0 0 0 0];

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

B = [
   0 0 0 0 ;
   0 0 0 0 ;
   0 0 0 0 ;
   (kft/mfl) 0 0 0 ;  %front left tire
   0 0 0 0;
   0 (kft/mfr) 0 0 ;  %front right tire
   0 0 0 0 ;
   0  0 (krt/mfr) 0 ; %rear left tire
   0 0 0 0;
   0 0 0 (krt/mrr);   %rear right tire
   0 0 0 0;
   0 0 0 0;
   0 0 0 0;
   0 0 0 0];

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
      0 0 0 0 0 0 0 0 0 0 0 0 0 1 ];


D = zeros(14,4);
%% running simulink, extracting from simulink


output = sim('fortniteV2Sim.slx',[0 tmax]);

states = output.states.data;

%% calulations


% Solving ride height and corner locations

states(:,1) = states(:,1)+rideHeight;
fr = states(:,1)+lf*states(:,11)-laa*states(:,13);
fl = states(:,1)+lf*states(:,11)+lbb*states(:,13);
rr = states(:,1)-lr*states(:,11)+laa*states(:,13);
rl = states(:,1)-lr*states(:,11)-laa*states(:,13);



%fft calcs

Y =fft(states(:,1));                      % two sided fft
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



% 
% 
% figure (Name='FFT')
% stem(fequencyX,Y_Onesided,LineWidth=0.5)
% xlabel('Frequency')
% ylabel('amp');
% xlim([0 30])
% 
% 
% figure(Name='PSD')
% plot(fequencyX,pow2db(psdx))
% grid on
% title("Periodogram Using FFT")
% xlabel("Frequency (Hz)")
% ylabel("Power/Frequency (dB/Hz)")
% ylim([-50 -20])
% xlim([0 50])

%


