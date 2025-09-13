function pid_integrator_sim()
% PID control of an integrator plant: x_dot = u
% Reference xr is constant.
% No saturation, no derivative filtering.

%% --- Design target ---
xr     = 5;    % reference (constant)

                        
close all
% Assume Kp = 1 (scaling choice)
Kp     = 0.10;
Kd     = 0.5;      % formula we derived
Ki     = 0.5;       % formula we derived

Kp     = 0.15;
Kd     = 0.01;      % formula we derived
Ki     = 0.022;       % formula we derived

Kp = 1
Ki = 4.4;
Kd = 4.47*10^(-3)

fprintf('PID gains: Kp=%.3f, Ki=%.6f, Kd=%.3f\n',Kp,Ki,Kd);

%% --- Simulation setup ---
dt  = 0.01;     % step size [s]
Tf  = 50;      % final time [s]
N   = round(Tf/dt)+1;
t   = (0:N-1)'*dt;

x   = zeros(N,1);
u   = zeros(N,1);
e   = zeros(N,1);
I   = zeros(N,1);
D   = zeros(N,1);

% initial state
x(1) = 0;
last_error = 0;

%% --- Main loop ---
for k = 1:N
    % error
    e(k) = xr - x(k);

    % derivative of error
    if k==1
        de = 0;
    else
        de = (e(k) - e(k-1))/dt;
    end
    D(k) = Kd * de;

    % integral of error
    if k==1
        I(k) = Ki*dt*e(k);
    else
        I(k) = I(k-1) + Ki*dt*e(k);
    end

    % PID output
    u(k) = Kp*e(k) + I(k) + D(k);

    % plant: x_dot = u
    if k < N
        x(k+1) = x(k) + dt*u(k);
    end
end

%% --- Plots ---
figure('Name','PID on Integrator (no limits)','Color','w');

subplot(3,1,1);
plot(t,x,'LineWidth',1.6); hold on; yline(xr,'--');
ylabel('x(t)'); grid on; title('Response');

subplot(3,1,2);
plot(t,u,'LineWidth',1.6);
ylabel('u(t)'); grid on; title('Control input');

subplot(3,1,3);
plot(t,e,'LineWidth',1.6);
ylabel('e(t)'); xlabel('time [s]'); grid on; title('Error');

end
