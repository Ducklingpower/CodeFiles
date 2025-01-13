function fortnite()
clc
close all
%% NOTE 
% Welch function, cleaning data
% white noise, 

ms = 300;
mf = 4;
mr = 4;
mfl = 4;
mrl = 4;
mfr = 4;
mrr = 4;
kfr =  30000;
krr =  30000;
kfl =  30000;
krl =  30000;
kfrt = 120000;
krrt = 120000;
kflt = 120000;
krlt = 120000;
lr =   0.717267;
lf =   0.808833;
laa = 0.635;
lbb = 0.635;
kft = 136000;
krt = 136000;
kf =  33275;
kr =  33275;
cf =  2000;
cr =  2000;
cfr = 2000;
crr = 2000;
cfl = 2000;
crl = 2000;
Lb = 0.734;
La = 0.828;

I_roll =  49.960975;
I_pitch = 283.33654;
I_yaw =   272.56808;
I=I_pitch;

T = 0.5;
r = .2;
f = 1;

rideHeight = 0;
sr= 0.001;
tmax=10;
t_span = 0:sr:tmax;


noise =randn(100000,1)*.01;




%%

IC = [0 0 0 0 0 0 0 0];
IC2 = [0 0 0 0 0 0 0 0 0 0 0 0 0 0];
[t,y] = ode45(@vert,t_span,IC);
[tt,yy] = ode45(@vert2,t_span,IC2);
y(:,1) = y(:,1)+rideHeight;
front = y(:,1)+La*y(:,7);
back = y(:,1)-Lb*y(:,7);
yy(:,1) = yy(:,1)+rideHeight;
fr = yy(:,1)+lf*yy(:,11)-laa*yy(:,13);
fl = yy(:,1)+lf*yy(:,11)+lbb*yy(:,13);
rr = yy(:,1)-lr*yy(:,11)+laa*yy(:,13);
rl = yy(:,1)-lr*yy(:,11)-laa*yy(:,13);

 S=[
 0 1 0 0 0 0 0 0 0 0 0 0 0 0;
 (-kfl-kfr-krl-krr)/ms (-cfl-cfr-crl-crr)/ms (kfl)/ms (cfl)/ms (kfr)/ms (cfr)/ms (krl)/ms (crl)/ms (krr)/ms (crr)/ms (-kfl*lf-kfr*lf+krl*lr+krr*lr)/ms (-cfl*lf-cfr*lf+crl*lr+crr*lr)/ms (-kfl*laa+kfr*laa+krl*laa-krr*laa)/ms (-cfl*laa+cfr*laa+crl*laa-crr*laa)/ms;
 0 0 0 1 0 0 0 0 0 0 0 0 0 0;
 (kfl)/mfl (cfl)/mfl (-kfl-kflt)/mfl (-cfl)/mfl 0 0 0 0 0 0 (kfl*lf)/mfl (cfl*lf)/mfl (kfl*laa)/mfl (cfl*laa)/mfl;
 0 0 0 0 0 1 0 0 0 0 0 0 0 0;
 (kfr)/mfr (cfr)/mfr 0 0 (-kfr-kfrt)/mfr (-cfr)/mfr 0 0 0 0 (kfr*lf)/mfr (cfr*lf)/mfr (kfr*laa)/mfr (cfr*laa)/mfr;
 0 0 0 0 0 0 0 1 0 0 0 0 0 0;
 (krl)/mrl (crl)/mrl 0 0 0 0 (-krl-krlt)/mrl (-crl)/mrl 0 0 (krl*lr)/mrl (crl*lr)/mrl (krl*laa)/mrl (crl*laa)/mrl;
 0 0 0 0 0 0 0 0 0 1 0 0 0 0;
 (krr)/mrr (crr)/mrr 0 0 0 0 0 0 (-krr-krrt)/mrr (-crr)/mrr (krr*lr)/mrr (crr*lr)/mrr (krr*laa)/mrr (crr*laa)/mrr;
 0 0 0 0 0 0 0 0 0 0 0 1 0 0;
 (-kfl*lf-kfr*lr+krl*lf+krr*lr)/I_pitch (-cfl*lf-cfr*lr+crl*lf+crr*lr)/I_pitch -(kfl*lf)/I -(cfl*lf)/I_pitch -(kfr*lr)/I_pitch -(cfr*lr)/I_pitch (krl*lf)/I_pitch (crl*lf)/I_pitch (krr*lr)/I_pitch (crr*lr)/I_pitch (-kfl*lf^2-kfr*lr^2-krl*lf^2-krr*lr^2)/I_pitch (-cfl*lf^2-cfr*lr^2-crl*lf^2-crr*lr^2)/I_pitch 0 0;
 0 0 0 0 0 0 0 0 0 0 0 0 0 1;
 (-kfl*laa-kfr*lbb+krl*laa+krr*lbb)/I_roll (-cfl*laa-cfr*lbb+crl*laa+crr*lbb)/I_roll -(kfl*laa)/I_roll -(cfl*laa)/I_roll (kfr*lbb)/I_roll (cfr*lbb)/I_roll -(krl*laa)/I_roll -(crl*laa)/I_roll (krr*lbb)/I_roll (crr*lbb)/I_roll 0 0 (-kfl*laa^2-kfr*lbb^2-krl*laa^2-krr*lbb^2)/I_roll (-cfl*laa^2-cfr*lbb^2-crl*laa^2-crr*lbb^2)/I_roll
  ];

 iVals = eig(S);
road_func = zeros(1,1);
n=0;




%%
%4DOF
% figure('Name','MS, MSF, MSR, Front, Back')
% plot(t,y(:,1),'LineWidth',4)
% set(gca,'color',[.5 .5 .5])
% grid on
% hold on
% plot(t,y(:,3),'LineWidth',3)
% hold on
% plot(t,y(:,5),'LineWidth',2)
% hold on
% plot(t,front,lineWidth=2);
% hold on
% plot(t,back,LineWidth=2);
% hold on
% plot(t,road_func,LineWidth=2)
% legend('ms position',  'mTf position', 'mTr position','delta Front','delta Back','road' )
%%
% KE curve

% figure('Name','position velocity')
% grid on
% plot(yy(:,1),yy(:,2),"LineWidth",3)
% set(gca,'color',[.5 .5 .5])
% grid on
% title('position vs velocity')
%%
% eigan values
%
% figure('Name',"eigan Values")
% grid on
% plot(real(iVals),imag(iVals),'*',linewidth=2)
% set(gca,'color',[.5 .5 .5])
% grid on
% xlabel('real')
% ylabel('imaginary')

%%

%7DOF
figure(5)
% plot(t,road_func,LineWidth=2)
% hold on
plot(tt,yy(:,1),"LineWidth",1)
set(gca,'color',[.5 .5 .5])
grid on
hold on
plot(tt,yy(:,3),"LineWidth",1)
hold on
plot(tt,yy(:,5),"LineWidth",1)
hold on
plot(tt,yy(:,7),"LineWidth",1)
hold on
plot(tt,yy(:,9),"LineWidth",1)
hold on
plot(tt,fr);
hold on
plot(tt,fl);
hold on
plot(tt,rr);
hold on
plot(tt,rl);
legend( 'cg position', "fl mass", "fr mass","rl mass","rr mass",'fR position', 'fL position','RR postion','RL position' )
figure
plot(tt,yy(:,11))
hold on
plot(tt,yy(:,13))


%% FFT;


Y =fft(yy(:,1));
samples = tmax/sr;
Sfq = 1/sr;
Y_Onesided = abs(Y(1:samples/2+1));
k = 0:samples/2;
fq_niquist =k*Sfq/samples;

figure (Name='FFT')
stem(fq_niquist,Y_Onesided,LineWidth=0.5)
xlabel('Frequency')
ylabel('amp');
xlim([0 20])
ylim([0 1000])

%% Weltch

[Ywelch, xx] = pwelch(yy(:,1),[],[], 10000,Sfq);
[Ywelch1, xx1] = pwelch(yy(:,1), 2000,[],  10000,Sfq);
 [Ywelch2, xx2] = pwelch(yy(:,1), 2000,[],  10000,Sfq);
%  [Ywelch3, xx3] = pwelch(yy(:,1),  1200,[],  10000,Sfq);
%  [Ywelch4, xx4] = pwelch(yy(:,1), 1300,[],  10000,Sfq);
%  [Ywelch5, xx5] = pwelch(yy(:,1), 1400,[],  10000,Sfq);
%  [Ywelch6, xx6] = pwelch(yy(:,1), 1500,[],  10000,Sfq);
% figure(Name='weltch')
stem(fq_niquist,Y_Onesided./20000,LineWidth=0.5)
hold on

plot(xx,Ywelch,LineWidth=1.5)
xlim([0 50])
ylim([0 100])
hold on 
plot(xx1,Ywelch1,LineWidth=1.5)
xlim([0 50])
ylim([0 1])
hold on 
plot(xx2,Ywelch2,LineWidth=1.5)
xlim([0 50])
ylim([0 .1])
% hold on 
% plot(xx3,Ywelch3,LineWidth=1.5)
% xlim([0 50])
% ylim([0 1])
% hold on 
% plot(xx4,Ywelch4,LineWidth=1.5)
% xlim([0 50])
% ylim([0 1])
% hold on 
% plot(xx5,Ywelch5,LineWidth=1.5)
% xlim([0 50])
% ylim([0 1])
% hold on 
% plot(xx6,Ywelch6,LineWidth=1.5)
% xlim([0 50])
% ylim([0 .1])
% hold on 
% legend('FF','0','1','2','3','4','5','6')


%% PSD


psdx = (1/(Sfq*samples)) * Y_Onesided.^2;

psdx(2:end-1) = 2*psdx(2:end-1);

figure(Name='PSD')
plot(fq_niquist,pow2db(psdx))
grid on
title("Periodogram Using FFT")
xlabel("Frequency (Hz)")
ylabel("Power/Frequency (dB/Hz)")
ylim([-50 -20])
xlim([0 50])


hold on
psd_welch = (1/(Sfq*samples)) * Ywelch.^2;
psd_welch(2:end-1) = 2*psd_welch(2:end-1);
plot(xx,pow2db(psd_welch).*.5);



figure(Name='PSD')
plot(fq_niquist,psdx)
grid on
title("Periodogram Using FFT")
xlabel("Frequency (Hz)")
ylabel("Power/Frequency (dB/Hz)")

xlim([0 10])


figure
psd_welch = (1/(Sfq*samples)) * Ywelch.^2;
psd_welch(2:end-1) = 2*psd_welch(2:end-1);
plot(xx,psd_welch*.5);






%% 4DOF & 7DOF functions 

  function dxdt = vert(t,y)
A =[
  0 1 0 0 0 0 0 0;
  (-kf-kr)/ms (-cf-cr)/ms kf/ms cf/ms kr/ms cr/ms 0 0;
  0 0 0 1 0 0 0 0;
  kf/mf cf/mf (-kf-kft)/mf -cf/mf 0 0 0 0;
  0 0 0 0 0 1 0 0;
  kr/mr cr/mr 0 0 (-kr-krt)/mr -cr/mr 0 0
  0 0 0 0 0 0 0 1;
  (kf*La-kr*Lb)/I (cf*La-cr*Lb)/I (kr*La)/I (cf*La)/I -(kr*Lb)/I -(cr*Lb)/I (-kf*La^2 - kr*Lb^2)/I (-cr*Lb^2-cf*La^2)/I];
force = 1 ;% Fs Fr Ff
disp =  1 ;
B = [0 0; 1/ms 0; 0 0; 1/mf (kft/mf)*roadfr(t) ; 0 0 ; 1/mr (krt/mr)*roadrr(t); 0 0; 1/I 0 ];
U = [ force ; disp];
dxdt = A*y+  B*U;
  end
%% 7DOF
  function dxdt = vert2(t,y)
i = ceil(t*1000+1);

AA =[
 0 1 0 0 0 0 0 0 0 0 0 0 0 0;
 (-kfl-kfr-krl-krr)/ms (-cfl-cfr-crl-crr)/ms (kfl)/ms (cfl)/ms (kfr)/ms (cfr)/ms (krl)/ms (crl)/ms (krr)/ms (crr)/ms (-kfl*lf-kfr*lf+krl*lr+krr*lr)/ms (-cfl*lf-cfr*lf+crl*lr+crr*lr)/ms (-kfl*laa+kfr*laa+krl*laa-krr*laa)/ms (-cfl*laa+cfr*laa+crl*laa-crr*laa)/ms;
 0 0 0 1 0 0 0 0 0 0 0 0 0 0;
 (kfl)/mfl (cfl)/mfl (-kfl-kflt)/mfl (-cfl)/mfl 0 0 0 0 0 0 (kfl*lf)/mfl (cfl*lf)/mfl (kfl*laa)/mfl (cfl*laa)/mfl;
 0 0 0 0 0 1 0 0 0 0 0 0 0 0;
 (kfr)/mfr (cfr)/mfr 0 0 (-kfr-kfrt)/mfr (-cfr)/mfr 0 0 0 0 (kfr*lf)/mfr (cfr*lf)/mfr (kfr*laa)/mfr (cfr*laa)/mfr;
 0 0 0 0 0 0 0 1 0 0 0 0 0 0;
 (krl)/mrl (crl)/mrl 0 0 0 0 (-krl-krlt)/mrl (-crl)/mrl 0 0 (krl*lr)/mrl (crl*lr)/mrl (krl*laa)/mrl (crl*laa)/mrl;
 0 0 0 0 0 0 0 0 0 1 0 0 0 0;
 (krr)/mrr (crr)/mrr 0 0 0 0 0 0 (-krr-krrt)/mrr (-crr)/mrr (krr*lr)/mrr (crr*lr)/mrr (krr*laa)/mrr (crr*laa)/mrr;
 0 0 0 0 0 0 0 0 0 0 0 1 0 0;
 (-kfl*lf-kfr*lr+krl*lf+krr*lr)/I_pitch (-cfl*lf-cfr*lr+crl*lf+crr*lr)/I_pitch -(kfl*lf)/I_pitch -(cfl*lf)/I_pitch -(kfr*lr)/I_pitch -(cfr*lr)/I_pitch (krl*lf)/I_pitch (crl*lf)/I_pitch (krr*lr)/I_pitch (crr*lr)/I_pitch (-kfl*lf^2-kfr*lr^2-krl*lf^2-krr*lr^2)/I_pitch (-cfl*lf^2-cfr*lr^2-crl*lf^2-crr*lr^2)/I_pitch 0 0;
 0 0 0 0 0 0 0 0 0 0 0 0 0 1;
 (-kfl*laa-kfr*lbb+krl*laa+krr*lbb)/I_roll (-cfl*laa-cfr*lbb+crl*laa+crr*lbb)/I_roll -(kfl*laa)/I_roll -(cfl*laa)/I_roll (kfr*lbb)/I_roll (cfr*lbb)/I_roll -(krl*laa)/I_roll -(crl*laa)/I_roll (krr*lbb)/I_roll (crr*lbb)/I_roll 0 0 (-kfl*laa^2-kfr*lbb^2-krl*laa^2-krr*lbb^2)/I_roll (-cfl*laa^2-cfr*lbb^2-crl*laa^2-crr*lbb^2)/I_roll
  ];


B = [
   0 0 0 0 0;
   1/ms 0 0 0 0 ;
   0 0 0 0 0;
   1/mfl (kft/mfl) 0 0 0 ;
   0 0 0 0 0;
   1/mfr 0 (krt/mfr) 0 0 ;
   0 0 0 0 0;
   1/mrl 0  0 (krt/mfr) 0 ;
   0 0 0 0 0;
   1/mrr 0 0 0 (krt/mrr);
   0 0 0 0 0;
   1/I_pitch 0 0 0 0;
   0 0 0 0 0;
   1/I_roll 0 0 0 0];
U= [1 ;
   noise(i)+roadf(t);
   noise(i)+ roadf(t); 
   noise(i)+ roadf(t);
   noise(i)+ roadf(t)
    ];

dxdt = AA*y +  B*U;




  
  end

%% external input force functions

function output = F(t)
      if t > 1.0 && t < 1.1
          output = 100;
      else
          output = 0;
      end
  end
function output = F_f(t)
      if t > 1 && t < 2
          output = 1;
      else
          output = 0;
      end
end
function output = F_r(t)
      if t > 1.2 && t < 1.3
          output = 0;
         
      else
          output =0;
      end
  end
function output = moment(t)
      if t > 1 && t < 1.1
          output = 0;
        
      else
          output = 0;
      end
end

%% Road input functions


function output = road(t) 
output = 0.5*sin(2*pi*t*10);
end

%--------------------------------------------------------------------------
function output = roadf(t) 


output = 0.3*sin(2*pi*(((r-f)/(2*T)*t^2))) ;%+ 1*sin(10*2*pi*t)+1*sin(25*2*pi*t); %+ 2*10*sin(2*pi*(f*t^1.4+((r-f)/(2*T)*t^2)));



end

function output = roadr(t)
output = 0.1*cos(2*pi*t*5-t^2);

end

%--------------------------------------------------------------------------
function output = roadfr(t)
      if t >= 1.1 && t <= 7
           
        output = 0.025;
      elseif t >= 8 && t <= 10
          
        output = 0.025;
      else
          output = 0;
      end
end
function output = roadfl(t)
      if t >= 1.2 && t <= 5
            
        output = 0.025;
      elseif t >= 8 && t <= 10
            
        output = 0.025;
      else
          output = 0;
      end
  end
   function output = roadrr(t)
      if t >= 1.3 && t <= 5
         
        output = 0.025;
      elseif t >= 8 && t <= 10
           
        output = 0.025;
      else
          output = 0;
      end
     
  end
 function [output] = roadrl(t)
      if t >= 1.5 && t <= 5
         
        output = 0.025;
      elseif t >= 8 && t <= 10
           
        output = 0.025;
      else
          output = 0;
      end
     
 end

    



end


