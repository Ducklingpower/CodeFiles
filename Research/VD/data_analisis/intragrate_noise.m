clc
close all
clear
%%
  
t = 0:0.01:10; 
noise = randn(size(t)) * 0.0005;
y = sin(2*t) + noise;


window_size = 200;   % number of samples in the sliding window
y_int_window = zeros(size(t));

for k = 2:length(t)
    i_start = max(1, k-window_size+1);
    y_int_window(k) = trapz(t(i_start:k), y(i_start:k));
end



%% true numeric integration 

delta = 0.01;
y_integral = 0;
y_last = 0;
for i = 1:length(t)
  
    y_integral = y_integral + y(i) * delta;
    I(i) = y_integral;
end


figure
plot(t, y, 'DisplayName', 'Signal y')
hold on
plot(t, y_int_window, 'LineWidth', 2, 'DisplayName', 'Sliding Window Integral')
hold on 
plot(t,I)
grid on
xlabel('Time [s]')
ylabel('Amplitude')
title('Numeric Sliding Window Integral')
legend
