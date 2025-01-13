clc
clear
close all

ms = 1085;

mfl = 40;
mrl = 40;
mfr = 40;
mrr = 40;

kfr =  10000;
krr =  10000;
kfl =  10000;
krl =  10000;

kft = 150000;
krt = 150000;

cfr = 1000;
crr = 1000;
cfl = 1000;
crl = 1000;

lr  =   1;
lf  =   1;
laa =   0.7;
lbb =   0.75;

I_roll  =   820;
I_pitch =   820;
I_yaw   =   820;

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

roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) 0.5*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.175;
road_inputfr = timeseries(roadfr(t_span'),t_span);

road_inputfr.data(1:20000,1)=0;
road_inputfr.data(30134:tmax*10000+1,1)=0;

roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) 0.5*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.175;
road_inputrr = timeseries(roadfr(t_span'),t_span);

road_inputrr.data(1:20000,1)=0;
road_inputrr.data(30134:tmax*10000+1,1)=0;




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
road_in = output.input.data;



figure
plot(1:length(road_in),states(:,1),LineWidth=1);
grid on
hold on
plot(1:length(road_in),states(:,13),LineWidth=1)
hold on
plot(1:length(road_in),road_in(:,2),LineWidth=1);
legend('car position','Roll response','Pot Hole')
xlabel('Time (seconds)')
ylabel('Response')
xlim([0,8*10000])
%% debth respons

n =0;
for i =1:5
n = n+0.1;
roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);

road_inputfr.data(1:20000,1)=0;
road_inputfr.data(30134:tmax*10000+1,1)=0;

roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);

road_inputrr.data(1:20000,1)=0;
road_inputrr.data(30134:tmax*10000+1,1)=0;

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


output = sim('fortniteV2Sim.slx',[0 tmax]);

states = output.states.data;
road_in = output.input.data;



figure(2)
plot(1:length(road_in),states(:,1),LineWidth=1);
grid on
hold on
legend('0.054 m','0.105 m','1.62 m', '2.17 m', '2.71 m', '3.25 m')
xlabel('time')
ylabel('displacment (m)')

figure(3)
plot(1:length(road_in),-states(:,13),LineWidth=1)
grid on
hold on
legend('0.054 m','0.105 m','1.62 m', '2.17 m', '2.71 m', '3.25 m')
xlabel('time')
ylabel('radians')

figure(7)
plot(1:length(road_in),road_in(:,2),LineWidth=1)
grid on
hold on
xlim([1*10000,4*10000])
legend('0.054 m','0.105 m','1.62 m', '2.17 m', '2.71 m', '3.25 m')
xlabel('time')
ylabel('debth')

end

%% length respons

n =0.5;
m = 0;
for i =1:4
m = m+0.5;
roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);

road_inputfr.data(1:20000,1)=0;
road_inputfr.data(30134:tmax*10000+1,1)=0;

roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);

if i == 1
m = 0.5;

roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);
roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);

road_inputfr.data(1:20000,1)=0;
road_inputfr.data(40000:tmax*10000+1,1)=0;

road_inputrr.data(1:20000,1)=0;
road_inputrr.data(40000:tmax*10000+1,1)=0;


elseif i == 2
    m = 1;


roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);
roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);


    road_inputfr.data(1:20000,1)=0;
road_inputfr.data(30000:tmax*10000+1,1)=0;

road_inputrr.data(1:20000,1)=0;
road_inputrr.data(30000:tmax*10000+1,1)=0;
elseif i == 3
    m=2;

    roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);
roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);
      road_inputfr.data(1:20000,1)=0;
road_inputfr.data(25000:tmax*10000+1,1)=0;

road_inputrr.data(1:20000,1)=0;
road_inputrr.data(25000:tmax*10000+1,1)=0;
elseif i== 4
    m=4;

roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);
roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);

      road_inputfr.data(1:20000,1)=0;
road_inputfr.data(22500:tmax*10000+1,1)=0;

road_inputrr.data(1:20000,1)=0;
road_inputrr.data(22500:tmax*10000+1,1)=0;
end




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


output = sim('fortniteV2Sim.slx',[0 tmax]);

states = output.states.data;
road_in = output.input.data;



figure(4)
if i ==1
tiledlayout(2,2)
else
end
nexttile
plot(1:length(road_in),states(:,1),LineWidth=1);
grid on
hold on
plot(1:length(road_in),-states(:,13),LineWidth=1)
hold on
plot(1:length(road_in),road_in(:,2),LineWidth=1)
grid on
legend('Bounce (m)','Roll (m)','Road profile')
xlim([1*10000,10*10000])
xlabel('Time')
ylabel('Respons')

end

%% hole freq

n =0.5;
m = 0;
for i =1:4
roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);

road_inputfr.data(1:20000,1)=0;
road_inputfr.data(30134:tmax*10000+1,1)=0;

roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);

if i == 1
m = 0.5;

roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);
roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);

road_inputfr.data(1:20000,1)=0;
%road_inputfr.data(40000:tmax*10000+1,1)=0;

road_inputrr.data(1:20000,1)=0;
%road_inputrr.data(40000:tmax*10000+1,1)=0;


elseif i == 2
    m = 1;


roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);
roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);


    road_inputfr.data(1:20000,1)=0;
%road_inputfr.data(30000:tmax*10000+1,1)=0;

road_inputrr.data(1:20000,1)=0;
%road_inputrr.data(30000:tmax*10000+1,1)=0;
elseif i == 3
    m=1.2;

    roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);
roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);
      road_inputfr.data(1:20000,1)=0;
%road_inputfr.data(25000:tmax*10000+1,1)=0;

road_inputrr.data(1:20000,1)=0;
%road_inputrr.data(25000:tmax*10000+1,1)=0;
elseif i== 4
    m=15;

roadfl = @(t) 0;
road_inputfl = timeseries(roadfl(t_span'),t_span);
roadfr = @(t) n*(0.2*cos(t*2*pi*m)+0.01*sin(2*pi*t*20*m)+0.1*sin(2*pi*t*2*m+1)+0.05*cos(2*pi*t*3*m))-0.35*n;
road_inputfr = timeseries(roadfr(t_span'),t_span);
roadrl = @(t) 0;
road_inputrl = timeseries(roadfl(t_span'),t_span);
roadrr = @(t) @(t) n*(0.2*cos(t*2*pi)+0.01*sin(2*pi*t*20)+0.1*sin(2*pi*t*2+1)+0.05*cos(2*pi*t*3))-0.35*n;
road_inputrr = timeseries(roadfr(t_span'),t_span);

      road_inputfr.data(1:20000,1)=0;
%road_inputfr.data(22500:tmax*10000+1,1)=0;

road_inputrr.data(1:20000,1)=0;
%road_inputrr.data(22500:tmax*10000+1,1)=0;

end




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


output = sim('fortniteV2Sim.slx',[0 tmax]);

states = output.states.data;
road_in = output.input.data;



figure(8)
if i==1
tiledlayout(2,2)
else
end
nexttile
plot(1:length(road_in),states(:,1),LineWidth=1);
grid on
hold on
plot(1:length(road_in),-states(:,13),LineWidth=1)

hold on
plot(1:length(road_in),road_in(:,2),LineWidth=1)
title(m+"Hz")
legend('Bounce','Roll','Road Profile')
xlim([0,10*10000])
xlabel('Time (seconds)')
ylabel('Response')


end