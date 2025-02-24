syms t x(t)
dsolve(exp(2*t)*diff(x(t))+x(t) -cos(t) == 0, x(0)==4)
pretty(ans)

%syms t x(t)
%dsolve(exp(1+x^2*(t))*diff(x(t))-t*x^3*(t)-1==0,x(5)==0)
%(ans)
%does not give an answer:(

tiledlayout(2,1)

[t,x] = ode45(@odefun,[0 2],4);
nexttile
plot(t,x);

odefun = @(t,x)(t.*x.^3+1)/(exp(1+x.^2));S
nexttile
[t,x] = ode45(odefun,[5 7], 0);
plot(t,x);



