function t=timeToDrain(R,l,dp,H1,H2,Cd,n)

A=(1/4)*pi*dp^2;
g=9.81;
V=(-2*l)/(Cd*A*sqrt(2*g));
%Y= @(h) (sqrt(2*R*h-(h.^2)))./(sqrt(h));
Y= @(h) sqrt(2*R-h);
I=trapezoid(Y,[H1 H2],n);
t=V*I;