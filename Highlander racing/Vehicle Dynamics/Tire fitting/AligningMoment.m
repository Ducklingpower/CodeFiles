function A = AligningMoment(A,TireData,specified)


set1 = 1:1278;
set2 = 1278+1:1278*2;
set3 = 1278*2+1:1278*3;
set4 = 1278*3+1:1278*4;
set = 1:1278*4 ;

% run_set = set;
% 
% Data = load("lateral_tire_test.mat");
% 
% 
% MaxSet = Data;
% 
% 
% %creating a tire data matrix to bin the data
% TireData = zeros(5112,12,10); %TireData(set number or full test [4 sets],data out [fz fy SA ... etc], test number 1-10  )
% 
% % Binning the tire: There are 10 tests, 4 sets per Test. 40 sets total
% Test = 1;
% for j = 0:4:36
%     x = j;
%     y = j+4;
%     Set = [MaxSet.AMBTMP(1278*x + 1:1278*y) MaxSet.ET(1278*x + 1:1278*y) MaxSet.FX(1278*x + 1:1278*y) MaxSet.FY(1278*x +1:1278*y) MaxSet.FZ(1278*x + 1:1278*y) MaxSet.IA(1278*x + 1:1278*y) MaxSet.MX(1278*x + 1:1278*y) MaxSet.MZ(1278*x + 1:1278*y) MaxSet.SA(1278*x + 1:1278*y) MaxSet.SL(1278*x + 1:1278*y) MaxSet.SR(1278*x + 1:1278*y) MaxSet.V(1278*x + 1:1278*y)];
%     TireData(:,:,Test) = Set(:,:);
%     Test = Test+1;
% end


%% Averaging normal loads 

%Binning average nornal Loads 

NormalLoads = zeros(length(specified),4);
NormalLoads_vect = zeros(length(specified)*4,1);


i = [1 2 3 4];
for test = 1:10 
avg1 = mean(TireData(set1,5,test));
avg2 = mean(TireData(set2,5,test));
avg3 = mean(TireData(set3,5,test));
avg4 = mean(TireData(set4,5,test));

NormalLoads(test,1) = avg1;
NormalLoads(test,2) = avg2;
NormalLoads(test,3) = avg3;
NormalLoads(test,4) = avg4;

NormalLoads_vect(i(1)) = avg1;
NormalLoads_vect(i(2)) = avg2;
NormalLoads_vect(i(3)) = avg3;
NormalLoads_vect(i(4)) = avg4;

i = i + [4 4 4 4];
end

n = 0;
for j = 1:length(specified)
test= specified(j);   

    for i = 1:4
    Load_vect(i+n,1) = NormalLoads(test,i);
    end

 n = n+4;
 end





 %% Fitting Specified Data sets for D C B E Sy

%%%%%%%%%%%%%%%%%%%%%%%%% Magic formula %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% D =   1;   %% peak points, also depend on frequency. Test from max-min values
% C =  -1;  %% frequemncy
% B =   1;   %% how quickly it goes from low to high. Test from 0-1
% E = 1.1; %% rebound typically less than. Test from 0-1.1 small increments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






%Fitting bounds
%    [D    C B E   Sy]   
lb = [0 2.2 0 -2 -200];
up = [300 2.7 0.5 0 200];
%training Data
Fittedcoefs = zeros(4,5,length(specified));

set1 = 1:1278;
set2 = 1278+1:1278*2;
set3 = 1278*2+1:1278*3;
set4 = 1278*3+1:1278*4;
set = 1:1278*4 ;

for traing = 1:20
    for i = 1:length(specified)
    test = specified(i);
        if traing ==1

         % Fy = -1100N
   D = 90;  %x1
C = 2.4; %x2
B = 0.17;  %x3
E = -0.3;%x4
Sy = 0;
Sh = 0;
         Coef_set1 = [D C B E Sy]; %starting coef for lsq for Fy = -1100

         % Fy = -880N
     D = 90;  %x1
C = 2.4; %x2
B = 0.17;  %x3
E = -0.3;%x4
Sy = 0;
Sh = 0;
         Coef_set2 = [D C B E Sy]; %starting coef for lsq for Fy = -880N


         % Fy = -650N
      D = 90;  %x1
C = 2.4; %x2
B = 0.17;  %x3
E = -0.3;%x4
Sy = 0;
Sh = 0;

         if i == 9
            D = 1000;
         else
         end

         Coef_set3 = [D C B E Sy]; %starting coef for lsq for Fy = -650


         % Fy = -200N
         D = 100;  %x1
         C = 2.4; %x2
         B = .25;  %x3
         E = 2;%x4
         Sy = 0;
         Sh = 0;
         Coef_set4 = [D C B E Sy]; %starting coef for lsq for Fy = -200
        else
         Coef_set1 = Fittedcoefs(1,:,test) ;
         Coef_set2 = Fittedcoefs(2,:,test) ;
         Coef_set3 = Fittedcoefs(3,:,test) ;
         Coef_set4 = Fittedcoefs(4,:,test) ;
        end

    MF = @(x,SA)x(1).*sin(2.4.*atan(x(3).*((1-x(4)).*(SA+Sh)+(x(4)/x(3)).*atan(x(3).*(SA)))));
    
 

    fit_set1 = lsqcurvefit(MF,Coef_set1,TireData(set1,9,test),TireData(set1,8,test),lb,up); % Fitting set 1
    fit_set2 = lsqcurvefit(MF,Coef_set2,TireData(set2,9,test),TireData(set2,8,test),lb,up); % Fitting set 2
    fit_set3 = lsqcurvefit(MF,Coef_set3,TireData(set3,9,test),TireData(set3,8,test),lb,up); % Fitting set 3
    fit_set4 = lsqcurvefit(MF,Coef_set4,TireData(set4,9,test),TireData(set4,8,test),lb,up); % Fitting set 4


    Fittedcoefs(:,:,test) = [fit_set1;fit_set2;fit_set3;fit_set4];



    end
end

% FittedCoefs([Coefs],set number, test number)


%% check fits with plots
% 
% D = 60;  %x1
% C = 2.4; %x2
% B = 0.17;  %x3
% E = -0.3;%x4
% Sy = 0;
% Sh = 0;
% Coef_setx = [D C B E Sy];
% 
% for i = 1:length(specified)
%     test = specified(i);
% 
%     figure(Name = "Fit check!")
%     plot(TireData(set,9,test),TireData(set,8,test),".");%plotting raw data
%     hold on
%     plot(TireData(set1,9,1),MF(Fittedcoefs(1,:,test),TireData(set1,9,1)),linewidth=3)
%     hold on
%     plot(TireData(set2,9,1),MF(Fittedcoefs(2,:,test),TireData(set2,9,1)),linewidth=3)
%     hold on
%     plot(TireData(set3,9,1),MF(Fittedcoefs(3,:,test),TireData(set3,9,1)),linewidth=3)
%     hold on
%     plot(TireData(set4,9,1),MF(Fittedcoefs(4,:,test),TireData(set4,9,1)),linewidth=3)
%     legend('Raw data',"fitted set 1","fitted set 2","fitted set 3","fitted set 4");
% 
%     hold on 
%     plot(TireData(set3,9,1),MF(Coef_setx,TireData(set3,9,1)),"black")
%     pause(0.5)
% 
% end


%% Fitting equation for ay1 and ay2 (regression) 

% Developing X matrix 
 polysize = 2;
 X = zeros(4*length(specified),polysize);
 

 n=-4;
 for j = 1:length(specified)
     test= specified(j);
     n = n+4;

    for i = 1:4
        X(i+n,1) = NormalLoads(test,i);
        X(i+n,2) = NormalLoads(test,i).^2;

     end
 end

% filling in D: Creating a vector of all the fitted D coefs

D_vect = zeros(4*length(specified),1);
n=0;
for j =1:length(specified)
test = specified(j);

    for i = 1:4
    n = n+1;
    D_vect(n) =  Fittedcoefs(i,1,test);
    
    end

end


% Solving for B = [ay1 ay2]
B = inv((transpose(X)*X)) * transpose(X)*D_vect;
B2 = pinv(X)*D_vect;

az1 = B(2);
az2 = B(1);
A(2,1) = az1;
A(2,2) = az2;

data = X*B; % projected D values from best fitted Ay1 and Ay2


% Validation 
% figure
% 
% n=0;
% for j =1:length(specified)
%     for i = 1:4
%         n = n+1;
%         plot(NormalLoads(j,i),data(n),"*")
%         hold on
%         plot(NormalLoads(j,i),D_vect(n),"o")
%     end
% end
% 
% legend("Output from fitted coefs a1 a2", "Fitted D coefs")


%% Non linear fit of az3 az4 az5
% 
% upperBound = [-9*10^-1 -0.001 -0.001];
% lowerBound = [-9*10^-12 -0.000001 -0.000001];

az3 = -8;
az4 = -0.00001;
az5 = -0.0005;

B_set = [az3 az4 az5]; 
BCD_eq = @(x, Fz) (x(1) * Fz.^2 + x(2) * Fz) ./ exp(x(3) * Fz);


% optain B coefs vect
BCD_vect = zeros(4*length(specified),1);
n=0;

for j =1:length(specified)
    test = specified(j);

    for i = 1:4
        n = n+1;
        BCD_vect(n) =  Fittedcoefs(i,3,test);
    
    end

end



for i = 1:length(D_vect)
    B_vect(i) = BCD_vect(i)/(C*D_vect(i));

end
% 
% BCoefs= lsqcurvefit(BCD_eq,B_set,Load_vect(:),B_vect(:),lowerBound,upperBound); 

BCoefs= lsqcurvefit(BCD_eq,B_set,Load_vect(:),B_vect(:)); 

%Validation

% figure(Name = 'Testing fitted coefs for BCE')
% 
%     plot(Load_vect,B_vect,"o",Linewidth =1)
%     hold on
%     plot(Load_vect(:),BCD_eq(BCoefs,Load_vect),"x")



Az3 = BCoefs(1);
Az4 = BCoefs(2);
Az5 = BCoefs(3);


% % testing

% Given data
x = Load_vect;
y = B_vect;

% Use MATLAB's fit function for advanced curve fitting
% Select a custom model, such as exponential, quadratic, or cubic
fitType = 'poly3'; % Choose 'poly3' for cubic polynomial, or 'exp1', 'poly2', etc.
[fitResult, gof] = fit(x, y', fitType);

A(2,3) = fitResult.p1;
A(2,4) = fitResult.p2;
A(2,5) = fitResult.p3;
A(2,6) = fitResult.p4;
% Display the fit parameters and goodness-of-fit metrics
disp('Fitted model parameters:');
disp(fitResult);
disp('Goodness-of-fit:');
disp(gof);

% Generate fitted data for plotting
x_fit = linspace(min(x), max(x), 100); % Smooth range for x values
y_fit = feval(fitResult, x_fit); % Compute fitted y values

% % Plot the data and fitted model
% figure;
% scatter(x, y, 'o', 'DisplayName', 'Observed Data'); % Original data points
% hold on;
% plot(x_fit, y_fit, 'r-', 'LineWidth', 2, 'DisplayName', ['Fitted Model: ', fitType]); % Fitted curve
% xlabel('X Values');
% ylabel('Y Values');
% title('Advanced Best Fit Model');
% legend('Location', 'best');
% grid on;






%% Solving for Ay7 Ay8 Ay9 (refine this process)


% Developing M matrix 
polysize = 3;
M = zeros(4*length(specified),polysize);

test=1;
n=-4;
for j = 1:length(specified)
     test= specified(j);
     n = n+4;

    for i = 1:4
     M(i+n,3) = 1;
     M(i+n,2) = NormalLoads(test,i);
     M(i+n,1) = NormalLoads(test,i).^2;

     end
end


% filling in E
E_vect = zeros(4*length(specified),1);

n=0;
for j =1:length(specified)
    test = specified(j);

    for i = 1:4
        n = n+1;
        E_vect(n) =  Fittedcoefs(i,4,test);
    
    end
end


% Solving for E = [ay6 ay7 ay8]
ECoefs = inv((transpose(M)*M)) * transpose(M)*E_vect;
ECoefs2 = pinv(M)*E_vect;
data = M*ECoefs;

Az7 = ECoefs(1);
Az8 = ECoefs(2);
Az9 = ECoefs(3);

A(2,7) = Az7; 
A(2,8) = Az8; 
A(2,9) = Az9; 



%%%% Validation 

% figure
% 
% n=0;
% for j =1:length(specified)
%     for i = 1:4
%         n = n+1;
%         plot(NormalLoads(j,i),data(n),"*")
%         hold on
%         plot(NormalLoads(j,i),E_vect(n),"o")
%     end
% end
% 
% legend("Output from fitted coefs a1 a2", "Fitted D coefs")
% 
% 
% figure 
% l = [1 2 3 4];
% for n = 1:length(specified)
%     test = specified(n);
%     plot(l,Fittedcoefs(:,4,test),"*",linewidth = 2)
%     l = l + [4 4 4 4];
%     hold on
% end
% hold on
% x = 1:4*length(specified);
% plot(x,data(:),"x",linewidth = 2)
% grid on
% 
% legend("x = numerical ","* = raw data ")

%% Testing lateral Models Fit 


% for i = 1:length(specified)
%     test = specified(i);
% sh =0;
% Fz = TireData(set,5,test);
% 
% C = 2.4;
% 
% D = A(2,1)*TireData(set,5,test).^2 + A(2,2)*TireData(set,5,test);
% BCD = (A(2,3) * Fz.^2 + A(2,4) * Fz) ./ exp(A(2,5) * Fz);
% 
% BCD = fitResult.p1.*Fz.^(3) + fitResult.p2.*Fz.^(2) + fitResult.p3.*Fz + fitResult.p4
% BCD = A(2,3).*Fz.^(3) + A(2,4).*Fz.^(2) + A(2,5).*Fz + A(2,6);
% 
% 
% BCD = feval(fitResult, Fz);
% B = BCD.*(C.*D);
% E = A(2,7)*TireData(set,5,test).^2 + A(2,8)*TireData(set,5,test)+ A(2,9);
% phi = (1-E).*(TireData(set,9,test)+sh)+(E./B).*atan(B.*(TireData(set,9,test)+sh));
% Fy = D.*sin(C.*atan(B.*phi));
% 
% 
% figure(Name = "Lateral Model Fit Test")
% plot(TireData(set,9,test),TireData(set,8,test),".")
% hold on
% plot(TireData(set,9,test),Fy(:),".")
% grid on
% legend("Tire data","Tire Model")
% xlabel("Aligning Moment")
% ylabel("Lateral Force in N")
% 
% end



end
