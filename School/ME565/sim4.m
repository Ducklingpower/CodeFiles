clc 
clear
close all
%% params 
figure
%%
C1 = 140; % lb/deg
C2 = 140; % lb/deg
W = 3000; %lb
I = 40000; % lbs-ft^2
x1 = 4.5; % ft
x2 = 3.5; % ft
L = x1+x2;

% conversion 
m = W / 32.2; % slugs
I = 40000/32.17 ;% slug ft^2
C1 = C1* 180/pi; % lb/rad
C2 = C2* 180/pi; % lb/rad

U_mph = [30 60]; % mph
c = [linspace(1,1,length(U_mph))' zeros(length(U_mph),1) zeros(length(U_mph),1)];

n = [3];

%% loop

% state space loop

for k = 1:length(n)


    if n(k) == 1
        x1 = 3.5; % ft
        x2 = 4.5; % ft
    
    elseif n(k) == 2 % crit at 50.6 mph
        x1 = 4.5; % ft
        x2 = 3.5; % ft
    else
        x1 = 4.5; % ft
        x2 = 4.5; % ft
    end


    for i =1: length(U_mph)
        u = U_mph(i)*1.466667 ; % ft/s
        % state space 
        A = [(-C1-C2)/(m*u) ((-x1*C1 + x2*C2)/(m*u))-u;
              ((-x1*C1 + x2*C2)/(I*u)) ((-x1^2*C1 - x2^2*C2)/(I*u))];   
        B = [(C1/m); (x1*C1)/(I)];   
        C = eye(2,2);
        D = zeros(2,1);
        t = 0:0.01:9; 
        sys = ss(A, B, C, D);
        [num,den] = ss2tf(A,B,[0,1],0);
        TF_yaw_rate = tf([num],[den])

        % steadt state yaw rate 
        K2 = -m*(x1*C1-x2*C2)/(C1*C2*L)
        ss_yaw_rate_respones = (u)/(L + u^2*K2);


       

        % steering calc input real life 

        rate_max = 180;   % deg/s
        delta_hw = zeros(size(t));
        
        for l = 1:length(t)-1
            if t(l) < 3
                delta_des = 45;
            elseif t(l) < 6
                delta_des = -45;
            elseif t(l) < 9
                delta_des = 0;
            else
                delta_des = 0;
            end
        
            % error to target
            err = delta_des - delta_hw(l);
            max_step = rate_max * 0.01;
        
            if abs(err) <= max_step
                delta_hw(l+1) = delta_des;   % hit target exactly
            else
                delta_hw(l+1) = delta_hw(l) + sign(err)*max_step;
            end
        end

        delta_hw = delta_hw.* (pi/180);

        % steering input calc for steady state about R
        Radius = 400; %ft
        delta_angle_rad = ((x1+x2) + K2*u^2)/(Radius);





        % Kss = -A\B;
        % kv = Kss(1);
        % kr = Kss(2);
        % delta_angle_rad = u / sqrt((Radius^2)*(kr^2) - kv^2);
        
       
        delta =  ones(length(t),1).* delta_angle_rad;% rads
        x0 = [0; 0];      % initial lateral velocity and yaw rate
        [y,t,x] = lsim(sys, delta_hw, t, x0);
        beta = -atan(y(:,1)./u);
        
        % eigs
        eigenvalues = eig(A);
        
    
        % yaw rate tranfer function
        Ca = C1+C2;
        Cb = x1*C1-x2*C2;
        Cc = x1^2*C1 + x2^2*C2;
        r_tf = tf([C1*x1*m*u^2 C1*C2*u*L],[m*u^2*I (m*u*Cc+I*u*Ca) C1*C2*L^2-m*u^2*Cb])
    






        
        % 
        % % for bode plot
        % bode(TF_yaw_rate)
        % grid on
        % hold on
        % title("Bode plot of yaw rate respones")
        % 
        % Plot for pole locations
        
        % plot(real(eigenvalues),imag(eigenvalues), "*",LineWidth=3)
        % hold on
        % title('Pole locations')
        % grid on
        % 
        % plot for ss respones values vel sweep
        % if n(k) == 1
        %     plot(U_mph(i),ss_yaw_rate_respones,"*",LineWidth=3,Color="r")
        %     hold on
        %     grid on
        % elseif n(k) == 2
        %     plot(U_mph(i),ss_yaw_rate_respones,"*",LineWidth=3,Color="b")
        %     hold on
        %     grid on
        % else
        %     plot(U_mph(i),ss_yaw_rate_respones,"*",LineWidth=3,Color="g")
        %     hold on
        %     grid on
        %     xlabel("mph")
        %     ylabel("ss yaw rate respons")
        % 
        % end
        % 



        dt = 0.01;

        vy = y(:,1);     
        r  = y(:,2);      
        psi = zeros(length(t),1);
        X   = zeros(length(t),1);
        Y   = zeros(length(t),1);
        
        for j = 1:length(t)-1
            psi(j+1) = psi(j) + r(j)*dt;
        
            Xdot = u*cos(psi(j)) - vy(j)*sin(psi(j));
            Ydot = u*sin(psi(j)) + vy(j)*cos(psi(j));
        
            X(j+1) = X(j) + Xdot*dt;
            Y(j+1) = Y(j) + Ydot*dt;
        end
       


        % plot for part 3
        % 
        % if n(k) == 1
        %     plot(U_mph(i),delta_angle_rad,"*",LineWidth=3,Color="r")
        %     hold on
        %     grid on
        % elseif n(k) == 2
        %     plot(U_mph(i),delta_angle_rad,"*",LineWidth=3,Color="b")
        %     hold on
        %     grid on
        % else
        %     plot(U_mph(i),delta_angle_rad,"*",LineWidth=3,Color="g")
        %     hold on
        %     grid on
        %     xlabel("mph")
        %     ylabel("ss yaw rate respons")
        % 
        % end
        % 
        % 


        % % plot postion
        % plot(X, Y, 'LineWidth', 2, color=[0 c(i) 0]);
        % xlabel('X Position (ft)');
        % ylabel('Y Position (ft)');
        % title('Vehicle Trajectory');
        % grid on;
        % hold on



        % plot for part 4
        plot(t,delta_hw * (180/pi),"*",LineWidth=2)
        grid on 
        xlabel("time")
        ylabel("steering angle in deg")


            
        
        
        % printing the steady state yaw rate respnes at speed u
        fprintf('Steady state yaw rate response at speed %.4f: %.4f\n', U_mph(i), ss_yaw_rate_respones);
        fprintf('Eigenvalues for U = %.4f mph: %+.4f%+.4fi and %+.4f%+.4fi\n', ...
        U_mph(i), real(eigenvalues(1)), imag(eigenvalues(1)), ...
        real(eigenvalues(2)), imag(eigenvalues(2)));
    
    end
end

%% plotting

figure
plot(t,y(:,1), Linewidth = 2)
hold on
plot(t,y(:,2),Linewidth = 2)
hold off
legend("lateral vel","yaw rate")


figure
plot(t,beta(:,1),Linewidth = 2)
hold on
plot(t,y(:,2),Linewidth = 2)
legend("body slip","yaw rate")
grid on


figure 
% plot postion
plot(X, Y, 'LineWidth', 2, color=[1 0 0]);
xlabel('X Position (ft)');
ylabel('Y Position (ft)');
title('Vehicle Trajectory');
grid on;
hold on



