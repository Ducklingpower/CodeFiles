%% Exercise 7 - Double pendulum on a cart, u = 0
% Model taken directly from Section 2.2.6 of the notes:
%
%   (m0+m1+m2)*ydd - m1*l1*cos(th1)*th1dd - m2*l2*cos(th2)*th2dd ...
%        + m1*l1*sin(th1)*th1d^2 + m2*l2*sin(th2)*th2d^2 = u
%   -m1*l1*cos(th1)*ydd + m1*l1^2*th1dd + m1*l1*g*sin(th1)   = 0
%   -m2*l2*cos(th2)*ydd + m2*l2^2*th2dd + m2*l2*g*sin(th2)   = 0
%
% Both pendulums hang from the SAME pivot on the cart (Figure 2.11); they
% are coupled only through the cart motion y.  Angles are measured from the
% downward vertical, so th = 0 is the hanging (stable) configuration and
% th = 180 deg is inverted.
%
% States: q = [y; th1; th2],  z = [q; qdot].  Cart mass m0 = 2, u = 0.

clear; close all; clc;

m0    = 2;                 % cart mass
tspan = [0 40];            % simulation time
opts  = odeset('RelTol',1e-11,'AbsTol',1e-12);   % tight: response can be chaotic

%% Parameter sets:            m1    m2    l1    l2    g
P = struct('name',{'P1','P2','P3','P4'}, ...
           'm1'  ,{ 1,    1,    1,    1  }, ...
           'm2'  ,{ 1,    1,    0.5,  1  }, ...
           'l1'  ,{ 1,    1,    1,    0.5}, ...
           'l2'  ,{ 1,    0.99, 1,    1  }, ...
           'g'   ,{ 1,    1,    1,    1  });

%% Initial conditions (deg, deg/s):  th1      th2   dth1 dth2
ICdeg = [ -10      10     0 0    % IC1
           10      10     0 0    % IC2
          -90      90     0 0    % IC3
          -90.01   90     0 0    % IC4
          100     100     0 0    % IC5
          100.01  100     0 0    % IC6
          179.99    0     0 0];  % IC7
ICname = {'IC1','IC2','IC3','IC4','IC5','IC6','IC7'};

%% Required combinations
runs = { 1, [1 2 3 7]      % P1 : IC1, IC2, IC3, IC7
         4, [1 2 3 4] };   % P4 : IC1, IC2, IC3, IC4

%% Simulate + plot
sol = struct();
for r = 1:size(runs,1)
    p    = P(runs{r,1});
    ilst = runs{r,2};

    figure('Name',sprintf('%s  (m_0=%g)',p.name,m0),'Color','w', ...
           'Position',[100 60 1000 760]);
    tl = tiledlayout(numel(ilst),1,'TileSpacing','compact','Padding','compact');

    for k = 1:numel(ilst)
        i  = ilst(k);
        z0 = [0; deg2rad(ICdeg(i,1)); deg2rad(ICdeg(i,2)); ...
              0; deg2rad(ICdeg(i,3)); deg2rad(ICdeg(i,4))];

        [t,z] = ode45(@(t,z) cartpend(t,z,m0,p), tspan, z0, opts);

        sol(r,k).t  = t;       sol(r,k).z  = z;
        sol(r,k).P  = p.name;  sol(r,k).IC = ICname{i};

        % u = 0  ->  energy and total horizontal momentum are constant.
        % These drifts are the sanity check on the integration.
        [E,Px] = invariants(z,m0,p);
        fprintf('%s / %s :  dE = %.2e ,  dP = %.2e ,  max|y| = %.3f\n', ...
                p.name,ICname{i},max(E)-min(E),max(Px)-min(Px),max(abs(z(:,1))));

        nexttile; hold on; grid on;
        plot(t,rad2deg(z(:,2)),'LineWidth',1.2);
        plot(t,rad2deg(z(:,3)),'LineWidth',1.2);
        ylabel('angle [deg]');
        title(sprintf('%s , %s :  \\theta_1(0)=%g^\\circ , \\theta_2(0)=%g^\\circ', ...
              p.name,ICname{i},ICdeg(i,1),ICdeg(i,2)));
        legend('\theta_1','\theta_2','Location','eastoutside');
    end
    xlabel(tl,'time [s]');
    title(tl,sprintf('Two pendulums on a cart, u=0, %s',p.name),'FontWeight','bold');
end

%% Cart displacement (shows which ICs leave the cart stationary)
figure('Color','w','Position',[150 100 900 420]); hold on; grid on;
for r = 1:size(runs,1)
    for k = 1:numel(runs{r,2})
        plot(sol(r,k).t, sol(r,k).z(:,1), 'LineWidth',1.1, ...
             'DisplayName',sprintf('%s / %s',sol(r,k).P,sol(r,k).IC));
    end
end
xlabel('time [s]'); ylabel('cart displacement y'); legend('Location','eastoutside');
title('Cart motion (y \equiv 0 means the two pendulum reactions cancel exactly)');

%% Sensitivity overlay: IC3 vs IC4 under P4 (0.01 deg apart)
compare(sol,2,[3 4],'P4:  IC3 vs IC4   (\theta_1(0) differs by 0.01^\circ)');

%% ------------------------------------------------------------------
function dz = cartpend(~,z,m0,p)
% Notes' equations rearranged as  M(q)*qdd = f(q,qdot,u),  q = [y; th1; th2].
% Rows 2 and 3 have been divided through by m1*l1 and m2*l2 respectively.
u  = 0;
m1 = p.m1; m2 = p.m2; l1 = p.l1; l2 = p.l2; g = p.g;

th1 = z(2); th2 = z(3); dy = z(4); d1 = z(5); d2 = z(6);
c1 = cos(th1); s1 = sin(th1);
c2 = cos(th2); s2 = sin(th2);

M = [ m0+m1+m2 , -m1*l1*c1 , -m2*l2*c2 ;
     -c1       ,  l1       ,  0        ;
     -c2       ,  0        ,  l2       ];

f = [ u - m1*l1*s1*d1^2 - m2*l2*s2*d2^2 ;
     -g*s1                              ;
     -g*s2                              ];

qdd = M\f;
dz  = [dy; d1; d2; qdd];
end

function [E,Px] = invariants(z,m0,p)
m1 = p.m1; m2 = p.m2; l1 = p.l1; l2 = p.l2; g = p.g;
th1 = z(:,2); th2 = z(:,3); dy = z(:,4); d1 = z(:,5); d2 = z(:,6);
c1  = cos(th1); c2 = cos(th2);

T  = 0.5*m0*dy.^2 ...
   + 0.5*m1*(dy.^2 - 2*dy.*l1.*c1.*d1 + l1^2*d1.^2) ...
   + 0.5*m2*(dy.^2 - 2*dy.*l2.*c2.*d2 + l2^2*d2.^2);
V  = -m1*g*l1*c1 - m2*g*l2*c2;
E  = T + V;
Px = (m0+m1+m2)*dy - m1*l1*c1.*d1 - m2*l2*c2.*d2;
end

function compare(sol,r,kk,ttl)
figure('Color','w','Position',[200 120 950 520]);
tiledlayout(2,1,'TileSpacing','compact');
for j = 1:2
    nexttile(j); hold on; grid on;
    for k = kk
        plot(sol(r,k).t, rad2deg(sol(r,k).z(:,j+1)), ...
             'LineWidth',1.1,'DisplayName',sol(r,k).IC);
    end
    ylabel(sprintf('\\theta_%d [deg]',j)); legend('Location','best');
end
xlabel('time [s]'); sgtitle(ttl,'FontWeight','bold');
end