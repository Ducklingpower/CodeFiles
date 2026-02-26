clc
close all
clear
%% rinning quater car sim model

ks = 100 * 12;  %lb/ft
cs = 1 * 12;    % lb/s/ft
ms = 1000/32.17; % slugs

kt = 1000 * 12; %lb/ft
ct = 0.01 * 12; %lb/ft/s
mu =100/32.17;  % slugs

%% runningn sim 

figure(Name='PSD')

sr= 0.001;
tmax=100;
t_span = 0:sr:tmax;
cs_n = 10:5:150;    % lb/s/ft
for n = 1:length(cs_n)
    cs = cs_n(n);
    output = sim("quater_car.slx",[0 tmax]);
    
    xu = output.xu.Data; % un sprung mass displacment
    xs = output.xs.Data; % sprung mass displacment
    %%
    
    %fft calcs
    
    Y =fft(xs);                  % two sided fft
    samples = tmax/sr;                   
    Sfq = 1/sr;                            
    k = 0:samples/2;                     
    fequencyXs =k*Sfq/samples;             
    Y_Onesideds = abs(Y(1:samples/2+1));   
    Y_Onesideds(1)=0;
    
    Y =fft(xu);                  % two sided fft
    samples = tmax/sr;                   
    Sfq = 1/sr;                          
    k = 0:samples/2;                      
    fequencyXu =k*Sfq/samples;            
    Y_Onesidedu = abs(Y(1:samples/2+1));   
    Y_Onesidedu(1)=0;
    
    
    %PSD calcs
    
    psdxs = (1/(Sfq*samples)) * Y_Onesideds.^2; %Power of ones sided fft.
    psdxs(2:end-1) = 2*psdxs(2:end-1);          %scaling
    pow2db(psdxs);          
    
    psdxu = (1/(Sfq*samples)) * Y_Onesidedu.^2; %Power of ones sided fft.
    psdxu(2:end-1) = 2*psdxu(2:end-1);          %scaling
    pow2db(psdxu);  %converting psdx to dB
    
    
    % figure (Name='FFT')
    % stem(fequencyXs,Y_Onesideds,LineWidth=0.5)
    % hold on
    % %stem(fequencyXu,Y_Onesidedu,LineWidth=0.5)
    % xlabel('Frequency')
    % ylabel('amp');
    % xlim([0 15])
    
    
    
    semilogy(fequencyXs,psdxs,LineWidth=2)
    hold on
    % semilogy(fequencyXu,psdxu)
    grid on
    title("Periodogram Using FFT")
    xlabel("Frequency (Hz)")
    ylabel("Power/Frequency (dB/Hz)")
    xlim([0 15])


    x_sprung_max(n) = max(psdxs);

    % cut off psdxs literlly 

    freq_low = find(fequencyXs == 4);
    frq_high = find(fequencyXu == 8);
    psdxs_cut = psdxs(freq_low:freq_low);
    x_sprung_min(n) = mean(psdxs_cut);

end
%%
figure

plot(cs_n,x_sprung_max/max(x_sprung_max),"o-",LineWidth=3)
hold on 
plot(cs_n,x_sprung_min/max(x_sprung_min),"o-",LineWidth=3)
xlabel("damping coefs")
ylabel("Normalized amplitude")
legend("Maxumum amplitude","minum amplitude in 4-8Hz riegon")

grid on



