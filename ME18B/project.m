a1 = 1;
a2 = 1;
theta  = 0:.01:3.14159;
theta1 = theta;
theta2 = theta+theta;

x = a1*cos(theta1)+a2*cos(theta2);
y = a1*sin(theta1)+a2*sin(theta2);

plot(x,y);


