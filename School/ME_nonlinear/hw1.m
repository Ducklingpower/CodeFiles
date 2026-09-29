clc
close all
clear

%% Common parameter
F0_over_m = 1.0;

%% =========================================================
%  Part (i)
%  x0 = 0.5, wn = 5, w = 2
%% =========================================================

x0 = 0.5;
wn = 5.0;
w = 2.0;

A = F0_over_m/(wn^2 - w^2);
C = x0 - A;

t = linspace(0,2*pi,2000);

x = C*cos(wn*t) + A*cos(w*t);
xdot = -C*wn*sin(wn*t) - A*w*sin(w*t);

% x(t)
figure
plot(t,x)
grid on
xlabel('t')
ylabel('x(t)')
title('(i) x_0 = 0.5')

% xdot(t)
figure
plot(t,xdot)
grid on
xlabel('t')
ylabel('\dot{x}(t)')
title('(i) xdot')

% Phase plane
figure
plot(x,xdot)
grid on
xlabel('x')
ylabel('\dot{x}')
title('(i) Phase Plane')

%% Part (i): choose x0 so there is no free response

x0_noFree = A;

x_noFree = A*cos(w*t);

figure
plot(t,x_noFree)
grid on
xlabel('t')
ylabel('x(t)')
title('(i) No Free Response')

fprintf('Part (i)\n')
fprintf('A = %.6f\n',A)
fprintf('x0 for no free response = %.6f\n\n',x0_noFree)


%% =========================================================
%  Part (ii)
%  x0 = 0.5, wn = 0.5, w = 4
%% =========================================================

x0 = 0.5;
wn = 0.5;
w = 4.0;

A = F0_over_m/(wn^2 - w^2);
C = x0 - A;

t = linspace(0,4*pi,3000);

x = C*cos(wn*t) + A*cos(w*t);
xdot = -C*wn*sin(wn*t) - A*w*sin(w*t);

% x(t)
figure
plot(t,x)
grid on
xlabel('t')
ylabel('x(t)')
title('(ii) x_0 = 0.5')

% xdot(t)
figure
plot(t,xdot)
grid on
xlabel('t')
ylabel('\dot{x}(t)')
title('(ii) xdot')

% Phase plane
figure
plot(x,xdot)
grid on
xlabel('x')
ylabel('\dot{x}')
title('(ii) Phase Plane')

%% Part (ii): choose x0 so there is no free response

x0_noFree = A;

x_noFree = A*cos(w*t);

figure
plot(t,x_noFree)
grid on
xlabel('t')
ylabel('x(t)')
title('(ii) No Free Response')

fprintf('Part (ii)\n')
fprintf('A = %.6f\n',A)
fprintf('x0 for no free response = %.6f\n',x0_noFree)