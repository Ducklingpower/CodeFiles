T_in = 8;  
k = 1;
theta = linspace(0,3.14,100);
T_re = T_in*k*(1+tan(theta).^2);
plot(T_re,theta);
