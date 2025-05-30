clc
close all
clear 
%% Params

m1 = 1; %kg
m2 = 0.338; %kg top plate

k1 = 20000; %N/m
k2 = 450; %N/m

c1 = 1; %Ns/m
c2 = 2.1; %Ns/m the damper !!!


%% Mass/Stiffness matrices

M = [m1  0 ; 
     0  m2];

K = [k1+k2  -k2 ;
       -k2   k2 ];


[Evect,Eval] = eig(K,M);
NaturalFrequency = diag(sqrt(Eval)) / (2 * pi);



%% state space dx/dt = Ax+Bu  y = Cx+Du


IC = [0 0 0 0]; % Initial conditions

A = [      0             1            0         0   ;
     (-k1-k2)/(m1) (-c1-c2)/(m1)    k2/m1     c2/m1 ;
           0             0            0         1   ;
         k2/m2         c2/m2       -k2/m2    -c2/m2];





%% ODE solve

% Opening data
data = readmatrix('Testing1.txt')./100 - 0.123;

M = data(499:end,:);

delta = -0.0839;



% signal one
x_init = [0; 0; delta; 0]; %[x , x_dot]
StateSpace = @(t, x1) A*x1;
[tspan, x1] = ode45(StateSpace, 0:.01: 10, x_init);
x1 = x1';

% 
% figure(1)
% plot(tspan,x1(3,:),linewidth = 2)
% grid on 
% legend("Top plate","Bottem plate")

%% Plotting real vs numeric
figure(2)
plot((0:length(M)-1)./100,M(:,3),LineWidth=1)
hold on
plot((0:length(M)-1)./100,M(:,2),LineWidth=1)
hold on

xT = (M(:,3)+M(:,2))/(2);
plot((0:length(M)-1)./100,xT(:))
grid on
hold on
plot(tspan,x1(3,:),linewidth = 2)
xlabel("seconds");
ylabel("m");
legend("Measured", "Measured", "Measured","Numeric")


%% Natral freq 

N = readmatrix('NatralFreqTest.txt')./100 - 0.123;

figure(3)

plot((0:length(N)-1)./100,N(:,2))
hold on
plot((0:length(N)-1)./100,N(:,3))

x = (0:length(N(:,1)))./100;
y = 0.01*sin((2*pi*x)*5.41);

hold on
plot(x,y,LineWidth=3)


% fft________________________________________________________

x = N(:,2);      
Fs = 100;              
N = length(x);           % Number of samples
t = (0:N-1)/Fs;          % Time vector (optional)

% Compute FFT
Y = fft(x);
f = Fs*(0:(N/2))/N;
P = abs(Y/N);            
P1 = P(1:N/2+1);         
P1(2:end-1) = 2*P1(2:end-1);  

% obatin natral freq of systsem
figure;
plot(f, P1,LineWidth=2);
xlabel('Frequency (Hz)');
ylabel('|P(f)|');
title('FFT');
grid on;


%% FFT noise spectrum

% static noise
data = readmatrix('staticNoise.txt')./100;
figure;
for i = 1:4
x = data(:,i);      
Fs = 100;              
N = length(x);           % Number of samples
t = (0:N-1)/Fs;          % Time vector (optional)

% Compute FFT
Y = fft(x);
f = Fs*(0:(N/2))/N;
P = abs(Y/N);            
P1 = P(1:N/2+1);         
P1(2:end-1) = 2*P1(2:end-1);  

% obatin natral freq of systsem
semilogy(f, P1);
xlabel('Frequency (Hz)');
ylabel('|P(f)|');
title('FFT');
grid on;
hold on

end
hold off



figure(Name="static noise")
plot((1:length(data(:,1)))./100,data(:,1),".")
hold on
plot((1:length(data(:,1)))./100,data(:,2),".")
hold on
plot((1:length(data(:,1)))./100,data(:,3),".")
hold on
plot((1:length(data(:,1)))./100,data(:,4),".")
grid on

% dynamic noise
data = readmatrix('dynamicNoise.txt');
figure
for i = 1:4
x = data(1:end-1,i);      
Fs = 100;              
N = length(x);           % Number of samples
t = (0:N-1)/Fs;          % Time vector (optional)

% Compute FFT
Y = fft(x);
f = Fs*(0:(N/2))/N;
P = abs(Y/N);            
P1 = P(1:N/2+1);         
P1(2:end-1) = 2*P1(2:end-1);  

% obatin natral freq of systsem

semilogy(f, P1);
xlabel('Frequency (Hz)');
ylabel('|P(f)|');
title('FFT');
grid on;
hold on
end
%% testing averging;



% Opening data
data = readmatrix('Testing1.txt')./100 - 0.123;
M = data(499:end,:);
delta = -0.0839;

figure
plot((0:length(M)-1)./100,M(:,2))
hold on
plot((0:length(M)-1)./100,M(:,3))

x1 = M(:,2);
x2 = M(:,3);

avg1 = (x1+x2)/2;
avg2 = (x1+x2+avg1)/(3) + 0.01;
avg3 = (x1+x2+avg1+avg2)/4 + 0.01;
avg4 = (x1+x2+avg1+avg2+avg3)/5 + 0.01;

hold on
plot((0:length(M)-1)./100,avg1)
hold on
plot((0:length(M)-1)./100,avg2)
hold on
plot((0:length(M)-1)./100,avg3)
hold on
plot((0:length(M)-1)./100,avg4,"o")

%% sweept sine 
close all


swept = readmatrix('sweepaAir.txt') ; % x1 v1 x2 v2
swept = swept(1:1000,:)
% swept = movmean(swept,3);


figure;
hold on;
plot(0:length(swept)-1, swept(:,1), 'DisplayName','x1');
plot(0:length(swept)-1, swept(:,2), 'DisplayName','v1');
plot(0:length(swept)-1, swept(:,3), 'DisplayName','x2');
plot(0:length(swept)-1, swept(:,4), 'DisplayName','v2');
plot(0:length(swept)-1, swept(:,1)+swept(:,3), 'DisplayName','x2')
xlabel('Time (samples)');
ylabel('Amplitude');
title('Time-Domain Signals');
legend;
grid on;


Fs = 100; 
data = swept;  
figure;
set(gca,"XScale","log")
hold on;
for i = 1:2
    x = data(:,i)+data(:,i*2);          
    N = length(x);          
    f = Fs*(0:(N/2))/N;     

    Y = fft(x);
    P2 = abs(Y/N);       
    P1 = P2(1:N/2+1);       
    P1(2:end-1) = 2*P1(2:end-1); 
    semilogy(f, P1);
    hold on
    XX = movmean(P1,5);
    semilogx(f, XX, Linewidth = 2);
end
xlabel('Frequency (Hz)');
ylabel('Amplitude');
title('Power Spectral Density (FFT)');
legend;
grid on;
hold off

Fs = 100; 
data = swept;  

figure;
set(gca,"XScale","log")
hold on;

for i = 1:2
    % Sum x and v signals (e.g., x1+v1 or x2+v2)
    x = data(:,i)+data(:,2*i);          
    N = length(x);          
    f = Fs*(0:(N/2))/N;     

    % FFT and power spectrum
    Y = fft(x);
    P2 = abs(Y/N).^2;            % Power = |FFT|^2 / N^2, but here we keep |FFT|^2 / N
    P1 = P2(1:N/2+1);       
    P1(2:end-1) = 2 * P1(2:end-1); 

    % Plot in dB scale
    semilogx(f, 10*log10(P1));
end

xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title('Power Spectrum (dB)');
legend;
grid on;
hold off;




%% bode
m1 = 1; %kg
m2 = 0.338; %kg top plate

k1 = 20000; %N/m
k2 = 450; %N/m

c1 = 1; %Ns/m
c2 = 2.1; %Ns/m the damper !!!

A = [      0             1            0         0   ;
     (-k1-k2)/(m1) (-c1-c2)/(m1)    k2/m1     c2/m1 ;
           0             0            0         1   ;
         k2/m2         c2/m2       -k2/m2    -c2/m2];

B = [0; k1/m1; 0; 0];  

C = [0, 0, 1, 0];      

D = 0;

sys = ss(A, B, C, D);

% Bode plot

f_Hz = logspace(-1, 2, 500);     
w_rad = 2 * pi * f_Hz;            

figure;
bodeplot(sys, w_rad);
grid on;
setoptions(bodeplot(sys), 'FreqUnits', 'Hz');  % Optional: force Hz on axis label
title('Bode Plot in Hz');


%% FFT ploting
close all
figure;
for k = 1:5
    clearvars swept
    if k ==1 
swept = readmatrix('sweep0deg.txt') .*10; % x1 v1 x2 v2
Fs = 100; 
    elseif k == 2
swept = readmatrix('sweep22deg.txt').*5 ; % x1 v1 x2 v2
Fs = 100; 
    elseif k ==3
swept = readmatrix('sweep66deg.txt').*2 ; % x1 v1 x2 v2
Fs = 100; 
    elseif k == 4
swept = readmatrix('sweep0deg2.txt').*10 ; % x1 v1 x2 v2
Fs = 93; 
    else
swept = readmatrix('sweep90deg.txt') ; % x1 v1 x2 v2
Fs = 108; 
    end

swept = swept(1:750,:)
swept = [swept;ones(2000,4)]



data = swept;  
set(gca,"XScale","log")
hold on;
for i = 1:1
    x = data(:,i)+data(:,i*2);          
    N = length(x);          
    f = Fs*(0:(N/2))/N;     

    Y = fft(x);
    P2 = abs(Y/N);       
    P1 = P2(1:N/2+1);       
    P1(2:end-1) = 2*P1(2:end-1); 
    % semilogy(f, P1);
    hold on
    XX = movmean(P1,3);
    semilogx(f, XX, Linewidth = 2);
end
xlabel('Frequency (Hz)');
ylabel('Amplitude');
title('Power Spectral Density (FFT)');
legend("1","2");
grid on;
hold on
end


%% PSD plots

figure;
for k = 1:5
    clearvars swept
    if k ==1 
swept = readmatrix('sweep0deg.txt') ; % x1 v1 x2 v2
Fs = 100; 
    elseif k == 2
swept = readmatrix('sweep22deg.txt') ; % x1 v1 x2 v2
Fs = 100; 
    elseif k ==3
swept = readmatrix('sweep66deg.txt') ; % x1 v1 x2 v2
Fs = 100; 
    elseif k == 4
swept = readmatrix('sweep0deg2.txt') ; % x1 v1 x2 v2
Fs = 93; 
    else
swept = readmatrix('sweep90deg.txt') ; % x1 v1 x2 v2
Fs = 108; 
    end

swept = swept(1:750,:)
swept = [swept;ones(2000,4)]
swept = movmean(swept,1);
data = swept;  

set(gca,"XScale","log")
hold on;

for i = 1:1
    % Sum x and v signals (e.g., x1+v1 or x2+v2)
    x = data(:,i)+data(:,2*i);          
    N = length(x);          
    f = Fs*(0:(N/2))/N;     

    % FFT and power spectrum
    Y = fft(x);
    P2 = abs(Y/N).^2;            % Power = |FFT|^2 / N^2, but here we keep |FFT|^2 / N
    P1 = P2(1:N/2+1);       
    P1(2:end-1) = 2 * P1(2:end-1); 

    % Plot in dB scale
    % semilogx(f, 10*log10(P1),Linewidth = 0.5);
    hold on
    XX = movmean(10*log10(P1),3);
    semilogy(f, XX, Linewidth = 1);
    
end

xlabel('Frequency (Hz)');
ylabel('Power (dB)');
title('Power Spectrum (dB)');
legend;
grid on;
hold off;


end
%% final plot
close all
figure;

colors = [
    0.45, 0.30, 0.60;  % deeper purple
    0.42, 0.40, 0.58;  % muted violet
    0.38, 0.52, 0.54;  % smoky green-violet
    0.34, 0.65, 0.49;  % mossy mint
    0.30, 0.75, 0.44;  % soft forest green
];


for k = 1:5
    % Load & scale
    switch k
        case 1
            swept = readmatrix('sweep0deg.txt') * 10; Fs = 100;
        case 2
            swept = readmatrix('sweep0deg2.txt') * 10; Fs = 93;
        case 3
            swept = readmatrix('sweep22deg.txt') * 5; Fs = 98;
        case 4
            swept = readmatrix('sweep66deg.txt') * 2; Fs = 96;
        case 5
            swept = readmatrix('sweep90deg.txt'); Fs = 103;
    end

    swept = swept(1:750, :);
    swept = [swept; ones(2500, 4)];

    x = swept(:,1) + swept(:,2);
    N = length(x);
    f = Fs * (0:(N/2)) / N;
    Y = fft(x);
    P2 = abs(Y/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2 * P1(2:end-1);
    XX = movmean(P1, 5);

    semilogx(f, XX, 'LineWidth', 4, 'Color', colors(k,:));
    hold on;
end

xlabel('Frequency (Hz)', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
title('Fast Fourier Transform', 'FontSize', 14);
legend({'0°','15°','33°','45°','88°'}, 'Location', 'northeast');
grid on;
set(gca, 'XScale', 'log');
set(gca, 'FontSize', 11);
