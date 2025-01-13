a1 = 1;
a2 = 1;
theta1  = 0:.01:3.14159;
theta2 = 0:.01:3.14159;
alpha = theta1+theta2;

x = a1*cos(theta1)+a2*cos(alpha);
y = a1*sin(theta1)+a2*sin(alpha);

plot(x,y);
