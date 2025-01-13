function lab

%calibration

theta = [0 10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180];
accel = [102.530
100.402
95.156
86.980
76.188
62.780
47.050
29.807
11.370
-7.100
-27.460
-45.856
-62.680
-78.107
-91.650
-102.118
-109.700
-113.860
-115.880];

figure(1)
title 'Calibration of accelerometer'
plot(theta,accel,"*");
hold on
plot(theta,accel);
grid on
xlabel('Angle in degrees')
ylabel('accelerometer output (Mv)')

%%

weight = [100 200 300 400 500 600];
deflection = [0 0.2 0.5 1 1.4 1.7];

figure(2)
title 'Spring delfection vs added mass'
plot(deflection,weight,"*");
hold on
plot(deflection,weight);
grid on
xlabel('Deflection (cm)')
ylabel('mass in grams')
%%

weight_added = [300 400 500 600];
freq = [4.78 4.3 3.96 3.67];

figure(3);
plot(freq,weight_added,'*');
title 'measurment of natral frequency'
grid on;
hold on 
plot(freq,weight_added);
xlabel('Natral frequency resposn (Hz)');
ylabel('Mass (g)');







end