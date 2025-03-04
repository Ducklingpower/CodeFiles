clc
close all
clear
%% Params

m1 = 1; %kg
m2 = 5; %kg

k1 = 2000; %N/m
k2 = 500; %N/m

c1 = 100; %Ns/m
c2 = 20; %Ns/m

%% Mass/Stiffness matrices

M = [m1  0 ; 
     0  m2];

K = [k1+k2  -k2 ;
       -k2   k2 ];


[Evect,Eval] = eig(K,M);
NaturalFrequency = diag(sqrt(Eval)) / (2 * pi);



%% state space dx/dt = Ax+Bu  y = Cx+Du


IC = [0 0 0 0]; % Initial conditions

A = [      0             1            0         0   ;
     (-k1-k2)/(m1) (-c1-c2)/(m1)    k2/m1     c2/m1 ;
           0             0            0         1   ;
         k2/m2         c2/m2       -k2/m2    -c2/m2];


A_Nodamp = [      0             1            0         0   ;
            (-k1-k2)/(m1) (-c1-0)/(m1)    k2/m1     0/m1 ;
                  0             0            0         1   ;
                k2/m2         0/m2       -k2/m2    -0/m2];

B = [  0     0     0   ;
     -1/m1 k1/m1 c1/m1 ;
       0     0     0   ;
      1/m2   0     0  ];

C = [1 0 0 0 ;
     0 1 0 0 ;
     0 0 1 0 ;
     0 0 0 1];

% D = 0 No feed through neededd
D = zeros(4,3);

%% For sky model 


m_sky = m2; %kg


k_sky = k2; %N/m

c_sky = 40; %Ns/m


A_sky = [      0           1      ;
        -k_sky/m_sky -c_sky/m_sky];

B_sky = [      0      ;
          k_sky/m_sky];

C_sky = [ 1 0  ;
          0 1 ];

D_sky = zeros(2,1);


%% Time-span and sampling rate
sr= 0.001;
tmax=5.9;
t_span = 0:sr:tmax;

% parameters for swept sign Might just use chirp
    T = 0.5;
    r = 0.2;
    f = 1;

%% Road input (janky) as a function meters + accleoration vehicle acceloration Input

noiseLevel = 0;
noise =rand(100000,1)*noiseLevel;
                         
%Vehicle acceloration a(t)
    acceloration_Func_long= @(t) 0;                                      %m/s^2 long                       
    Vehic_acc_long = timeseries(acceloration_Func_long(t_span'),t_span);
    Vehicle_acceloration_long = Vehic_acc_long.data;

% Calc velocity and position
    x_i = 0;
    v_i = 1;    

    for i = 1:length(t_span)
        Vehicle_Velocity(1,i) = v_i + Vehicle_acceloration_long(i,1).*t_span(1,i); % m/s 
        position(1,i) = x_i + v_i*t_span(1,i) + 0.5*Vehicle_acceloration_long(i,1).*t_span(1,i).^2;
    end

% road input y(t) dy(t)/dt

    y_input   = @(x) 1*sin((1/2)*pi*(x));
    y_input_t = timeseries(y_input(position'),t_span); % Y(t)

    dy_input    = @(x) 1*cos((1/2)*pi*(x));
    dy_input_dt = timeseries(dy_input(position'),t_span); % dY(t)/dt

% Sky hook control damping vals
Cmax = 100;
Cmin = 20;

C_vect = ones(length(t_span),2);
C_vect(:,1) = C_vect(:,1).*Cmax;
C_vect(:,2) = C_vect(:,2).*Cmin;

C_vect_t = timeseries(C_vect,t_span);

% force inpurt F(t)

    force_input   = @(t) t*0;
    force_input_t = timeseries(force_input(t_span),t_span); 
    
   
    input_storage = zeros(length(y_input_t.data),3);   % stores input
    input_storage(:,1) = y_input_t.data;               % inserting y(t)
    input_storage(:,2) = dy_input_dt.data;             % inserting dy(t)/dt
    input_storage(:,3) = force_input_t.data;
 
    time = y_input_t.Time;
    
    
%% running simulink, extracting from simulink

output = sim('Model_sim.slx',[0 tmax]);

%% Obtain states
statesControlled   = output.statesControlled.data;
statesUncontrolled = output.statesUncontrolled.data;
Inputs = output.Inputs.data;

%%
figure(1)

plot(time,statesControlled(:,3),LineWidth=2); % Mass 2
hold on
plot(time,statesUncontrolled(:,3),LineWidth=2); % Mass 2
hold on
plot(time,Inputs(:,2),LineWidth=2); % Y input
grid on
legend("m_2 position Controlled","m_2 positon Uncontrolled","Y(t)")
xlabel("Time");
ylabel("Displacment")
%% Energy Calcs

%Power to whole system at time step delta
delta_Y = 0;
for i = 2:length(statesControlled(:,1))
delta_Y(i) = Inputs(i-1,2)-Inputs(i,2);
end

E_system = -(k1.*(Inputs(:,2)- statesControlled(:,1)) + c1.*(Inputs(:,2)-statesControlled(:,2)) ) .*delta_Y' ; % J

KE_system = (1/2).*(m1).*(statesControlled(:,2).^2) + (1/2).*(m2).*(statesControlled(:,4).^2);
PE_system = (1/2).*k2.*(statesControlled(:,3)-statesControlled(:,1)).^2 + (1/2).*k1.*(statesControlled(:,1)-Inputs(:,2)).^2;
Etot_system = KE_system+PE_system;

E_stored = 0;
for i = 2:length(Etot_system)
E_stored(i) = E_stored(i-1)+ Etot_system(i);
end

figure(name = "Power")
 plot(time,E_system,LineWidth=2);
 hold on 
plot(time,KE_system,LineWidth=2);
hold on
plot(time,PE_system,LineWidth=2);
grid on
plot(time,Etot_system,"black",LineWidth=1);
legend("Energy Input","KE","PE","System Energy")
title("Energy of system")
xlabel("Time");
ylabel("Energy J")

figure(name = "Energy storage")
title("Energy stored")
stem(time,E_stored,LineWidth=1)
hold on
plot(time,E_stored,LineWidth=5)
grid on
xlabel("Time");
ylabel("Total Energy J")




















