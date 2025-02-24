x=linspace(-pi, pi,100);
y=linspace(-pi,pi,100);
funcString= '@(X,Y) sin(X.^2+Y.^2)';

[X,Y]=meshgrid(x,y);
func=str2func(funcString);%converts 
z=func(X,Y);
surf(x,y,z);
%mesh
