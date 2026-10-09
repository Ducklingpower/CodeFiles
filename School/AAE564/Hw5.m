clc
close all
clear
%% Hw 5
clear
clc

P = [2 1 1   1   1    1;
     2 1 1   1   0.99 1;
     2 1 0.5 1   1    1;
     2 1 1   0.5 1    1];

c = [1 -1];   

L = 1;

for p = 1:4
    m0 = P(p,1);
    m1 = P(p,2);
    m2 = P(p,3);
    l1 = P(p,4);
    l2 = P(p,5);
    g  = P(p,6);

    for e = 1:2

        ce = c(e);

        M = [m0+m1+m2, -m1*l1*ce, -m2*l2*ce;
             -m1*l1*ce, m1*l1^2, 0;
             -m2*l2*ce, 0, m2*l2^2];

        K = [0, 0, 0;
             0, m1*l1*g*ce, 0;
             0, 0, m2*l2*g*ce];

        A = [zeros(3), eye(3);
             -(M\K), zeros(3)];

        lambda = eig(A);
        lambda(abs(lambda) < 1e-10) = 0;

        fprintf('L%d eigenvalues:\n',L)
        disp(lambda)

        L = L + 1;
    end
end



%% part b Q8
clear

m0 = 2;
m1 = 1;
m2 = 1;
l1 = 0.5;
l2 = 1;
g  = 1;

dx0 = [0; 0.05; 0.05; 0; 0; 0];

for e = 1:2

    if e == 1
        thetae = 0;
        tf = 20;
        name = 'L7';
    else
        thetae = pi;
        tf = 5;
        name = 'L8';
    end

    c = cos(thetae);

    M = [m0+m1+m2, -m1*l1*c, -m2*l2*c;
         -m1*l1*c, m1*l1^2, 0;
         -m2*l2*c, 0, m2*l2^2];

    K = [0 0 0;
         0 m1*l1*g*c 0;
         0 0 m2*l2*g*c];

    A = [zeros(3) eye(3);
         -M\K zeros(3)];

    xeq = [0; thetae; thetae; 0; 0; 0];
    x0 = xeq + dx0;

    [tn,xn] = ode45(@(t,x) nonlinear(x,m0,m1,m2,l1,l2,g),[0 tf],x0);

    [tl,dxl] = ode45(@(t,x) A*x,[0 tf],dx0);

    xl = dxl + xeq';

    figure

    subplot(3,1,1)
    plot(tn,xn(:,1))
    hold on
    plot(tl,xl(:,1),'--')
    ylabel('y')
    legend('Nonlinear','Linear')
    grid on

    subplot(3,1,2)
    plot(tn,xn(:,2))
    hold on
    plot(tl,xl(:,2),'--')
    ylabel('\theta_1')
    grid on

    subplot(3,1,3)
    plot(tn,xn(:,3))
    hold on
    plot(tl,xl(:,3),'--')
    ylabel('\theta_2')
    xlabel('Time')
    grid on

    sgtitle(name)

end


function dx = nonlinear(x,m0,m1,m2,l1,l2,g)

th1 = x(2);
th2 = x(3);
dth1 = x(5);
dth2 = x(6);

M = [m0+m1+m2, -m1*l1*cos(th1), -m2*l2*cos(th2);
     -m1*l1*cos(th1), m1*l1^2, 0;
     -m2*l2*cos(th2), 0, m2*l2^2];

b = [-m1*l1*sin(th1)*dth1^2 - m2*l2*sin(th2)*dth2^2;
     -m1*l1*g*sin(th1);
     -m2*l2*g*sin(th2)];

ddq = M\b;

dx = [x(4);
      x(5);
      x(6);
      ddq];

end


%% Q9
clear

m0 = 2;
m1 = 1;
m2 = 1;
l1 = 0.5;
l2 = 1;
g = 1;

[A7,M7,K7] = linearModel(0,m0,m1,m2,l1,l2,g);
[A8,~,~] = linearModel(pi,m0,m1,m2,l1,l2,g);

%%9a

[Q,D] = eig(K7,M7);
w2 = real(diag(D));

ids = find(w2 > 1e-8);
[~,j] = min(w2(ids));
q = real(Q(:,ids(j)));

q = 0.05*q/max(abs(q(2:3)));
x0a = [q; 0; 0; 0];

t = linspace(0,20,1000);

[~,xLa] = ode45(@(t,x) A7*x,t,x0a);
[~,xNa] = ode45(@(t,x) nonlinear(x,m0,m1,m2,l1,l2,g),t,x0a);

%%9a plots

figure

subplot(3,1,1)
plot(t,xNa(:,1))
hold on
plot(t,xLa(:,1),'--')
ylabel('y')
legend('Nonlinear','Linear')
grid on

subplot(3,1,2)
plot(t,xNa(:,2))
hold on
plot(t,xLa(:,2),'--')
ylabel('\theta_1')
grid on

subplot(3,1,3)
plot(t,xNa(:,3))
hold on
plot(t,xLa(:,3),'--')
ylabel('\theta_2')
xlabel('Time')
grid on

sgtitle('Part (a): L7 Periodic Mode')


%%9b

[V,D] = eig(A8);
lambda = real(diag(D));

[~,i] = min(lambda);
v = real(V(:,i));

x0b = 0.05*v/max(abs(v(2:3)));

xeq = [0; pi; pi; 0; 0; 0];
x0N = xeq + x0b;

t = linspace(0,6,1000);

[~,xLb] = ode45(@(t,x) A8*x,t,x0b);
[~,xNb] = ode45(@(t,x) nonlinear(x,m0,m1,m2,l1,l2,g),t,x0N);

xNb = xNb - xeq';

%%9b plots

figure

subplot(3,1,1)
plot(t,xNb(:,1))
hold on
plot(t,xLb(:,1),'--')
ylabel('\Delta y')
legend('Nonlinear','Linear')
grid on

subplot(3,1,2)
plot(t,xNb(:,2))
hold on
plot(t,xLb(:,2),'--')
ylabel('\Delta\theta_1')
grid on

subplot(3,1,3)
plot(t,xNb(:,3))
hold on
plot(t,xLb(:,3),'--')
ylabel('\Delta\theta_2')
xlabel('Time')
grid on

sgtitle('Part (b): L8 Decaying Mode')
%%9c

[~,i] = max(lambda);
v = real(V(:,i));

x0c = 0.05*v/max(abs(v(2:3)));

x0N = xeq + x0c;

t = linspace(0,3,1000);

[~,xLc] = ode45(@(t,x) A8*x,t,x0c);
[~,xNc] = ode45(@(t,x) nonlinear(x,m0,m1,m2,l1,l2,g),t,x0N);

xNc = xNc - xeq';

%%9c plots

figure

subplot(3,1,1)
plot(t,xNc(:,1))
hold on
plot(t,xLc(:,1),'--')
ylabel('\Delta y')
legend('Nonlinear','Linear')
grid on

subplot(3,1,2)
plot(t,xNc(:,2))
hold on
plot(t,xLc(:,2),'--')
ylabel('\Delta\theta_1')
grid on

subplot(3,1,3)
plot(t,xNc(:,3))
hold on
plot(t,xLc(:,3),'--')
ylabel('\Delta\theta_2')
xlabel('Time')
grid on

sgtitle('Part (c): L8 Growing Mode')


function [A,M,K] = linearModel(thetae,m0,m1,m2,l1,l2,g)

c = cos(thetae);

M = [m0+m1+m2, -m1*l1*c, -m2*l2*c;
     -m1*l1*c, m1*l1^2, 0;
     -m2*l2*c, 0, m2*l2^2];

K = [0 0 0;
     0 m1*l1*g*c 0;
     0 0 m2*l2*g*c];

A = [zeros(3) eye(3);
     -(M\K) zeros(3)];

end

