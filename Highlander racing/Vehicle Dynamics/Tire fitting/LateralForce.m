function [A,TireData,NormalLoads,NormalLoads_vect,IA_Zero] = LateralForce(Data,FittingTests)



%Setting A values to zero

ay1  = 0;
ay2  = 0;
ay3  = 0;
ay4  = 0;
ay5  = 0;
ay6  = 0;
ay7  = 0;
ay8  = 0;
ay9  = 0;
ay10 = 0;
ay11 = 0;
ay12 = 0;
ay13 = 0;

az1  = 0;
az2  = 0;
az3  = 0;
az4  = 0;
az5  = 0;
az6  = 0;
az7  = 0;
az8  = 0;
az9  = 0;
az10 = 0;
az11 = 0;
az12 = 0;
az13 = 0;

ax1  = 0;
ax2  = 0;
ax3  = 0;
ax4  = 0;
ax5  = 0;
ax6  = 0;
ax7  = 0;
ax8  = 0;
ax9  = 0;
ax10 = 0;
ax11 = 0;
ax12 = 0;
ax13 = 0;



A = [ay1 ay2 ay3 ay4 ay5 ay6 ay7 ay8 ay9 ay10 ay11 ay12 ay13; % Lateral Coefss
     az1 az2 az3 az4 az5 az6 az7 az8 az9 az10 az11 az12 az13;
     ax1 ax2 ax3 ax4 ax5 ax6 ax7 ax8 ax9 ax10 ax11 ax12 ax13];



%% Data sorting

% 3-dimensional matrix TireData: 3rd dimension is the test #
%There are 10 test total

%loading data
MaxSet = Data;


%creating a tire data matrix to bin the data
TireData = zeros(5112,12,10); %TireData(set number or full test [4 sets],data out [fz fy SA ... etc], test number 1-10  )

% Binning the tire: There are 10 tests, 4 sets per Test. 40 sets total
Test = 1;
for j = 0:4:36
    x = j;
    y = j+4;
    Set = [MaxSet.AMBTMP(1278*x + 1:1278*y) MaxSet.ET(1278*x + 1:1278*y) MaxSet.FX(1278*x + 1:1278*y) MaxSet.FY(1278*x +1:1278*y) MaxSet.FZ(1278*x + 1:1278*y) MaxSet.IA(1278*x + 1:1278*y) MaxSet.MX(1278*x + 1:1278*y) MaxSet.MZ(1278*x + 1:1278*y) MaxSet.SA(1278*x + 1:1278*y) MaxSet.SL(1278*x + 1:1278*y) MaxSet.SR(1278*x + 1:1278*y) MaxSet.V(1278*x + 1:1278*y)];
    TireData(:,:,Test) = Set(:,:);
    Test = Test+1;
end

TireData(:,4,:) = TireData(:,4,:)*0.7;

clear vars Test x y j set


%% Concatinate data

NewDataFY = load("FyDataMFEVAL.mat") % loading FY data
NewDataFY = NewDataFY.Fy_LUT(:).*-1;
NewDataSA = transpose(linspace(-15,15,1278));
NewDataSA = [NewDataSA NewDataSA NewDataSA NewDataSA NewDataSA NewDataSA NewDataSA];
NewDataSA = NewDataSA(:);


extraSet = 7; % seven new FY sets
extraSet = 2; % seven new FY sets

ZeroM = zeros(1278*extraSet,12,10);

TireData = cat(1,TireData,ZeroM); % increse sets ure test by + (extra sets)

% adding new FY and SA

for i = 1:10
    for j = 1:1278*extraSet
        TireData((1278*4)+j,4,i) = NewDataFY(j);
    end

end

for i = 1:10
    for j = 1:1278*extraSet
        TireData((1278*4)+j,4,i) = NewDataFY(j);
    end

end

for i = 1:10
    for j = 1:1278*extraSet
        TireData((1278*4)+j,9,i) = NewDataSA(j);
    end

end

% adding loads FZ to data
fz25 = ones(1278,1)*-25;
fz50 = ones(1278,1)*-50;
fz75 = ones(1278,1)*-75;
fz100 = ones(1278,1)*-100;
fz125 = ones(1278,1)*-125;
fz150 = ones(1278,1)*-150;
fz175 = ones(1278,1)*-175;

NewDataFZ = [fz25 fz50 fz75 fz100 fz125 fz150 fz175];
NewDataFZ = NewDataFZ(:);


for i = 1:10
    for j = 1:1278*extraSet
        TireData((1278*4)+j,5,i) = NewDataFZ(j);
    end

end




%%
set1 = 1:1278;
set2 = 1278+1:1278*2;
set3 = 1278*2+1:1278*3;
set4 = 1278*3+1:1278*4;
set5 = 1278*4+1:1278*5;
set6 = 1278*5+1:1278*6;
set7 = 1278*6+1:1278*7;
set8 = 1278*7+1:1278*8;
set9 = 1278*8+1:1278*9;
set10 = 1278*9+1:1278*10;
set11= 1278*10+1:1278*11;

% need to add more sets with data



set = 1:1278*(extraSet+4) ;

run_set = set;

% figure(1)
% plot(TireData(run_set,9,7),TireData(run_set,5,7));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,5,1));



%% specify tests to fit 

specified = [1 5 9 10]; % No IC
%specified = [1 2 3 4 5 6 7 8 9 10
specified =1;

specified = FittingTests;


%% Averaging normal loads 

%Binning average nornal Loads 

NormalLoads = zeros(length(specified),4);
NormalLoads_vect = zeros(length(specified)*4,1);


% i = [1 2 3 4 5 6 7 8 9 10 11];
i = [1 2 3 4 5 6];
for test = 1:10 
avg1 = mean(TireData(set1,5,test));
avg2 = mean(TireData(set2,5,test));
avg3 = mean(TireData(set3,5,test));
avg4 = mean(TireData(set4,5,test));
avg5 = mean(TireData(set5,5,test));
avg6 = mean(TireData(set6,5,test));
% avg7 = mean(TireData(set7,5,test));
% avg8 = mean(TireData(set8,5,test));
% avg9 = mean(TireData(set9,5,test));
% avg10 = mean(TireData(set10,5,test));
% avg11 = mean(TireData(set11,5,test));


NormalLoads(test,1)  = avg1;
NormalLoads(test,2)  = avg2;
NormalLoads(test,3)  = avg3;
NormalLoads(test,4)  = avg4;
NormalLoads(test,5)  = avg5;
NormalLoads(test,6)  = avg6;
% NormalLoads(test,7)  = avg7;
% NormalLoads(test,8)  = avg8;
% NormalLoads(test,9)  = avg9;
% NormalLoads(test,10) = avg10;
% NormalLoads(test,11) = avg11;


NormalLoads_vect(i(1)) = avg1;
NormalLoads_vect(i(2)) = avg2;
NormalLoads_vect(i(3)) = avg3;
NormalLoads_vect(i(4)) = avg4;
NormalLoads_vect(i(5)) = avg5;
NormalLoads_vect(i(6)) = avg6;
% NormalLoads_vect(i(7)) = avg7;
% NormalLoads_vect(i(8)) = avg8;
% NormalLoads_vect(i(9)) = avg9;
% NormalLoads_vect(i(10)) = avg10;
% NormalLoads_vect(i(11)) = avg11;


% i = i + [11 11 11 11 11 11 11 11 11 11 11];
i = i + [6 6 6 6 6 6];
end







n = 0;
for j = 1:length(specified)
test= specified(j);   

    % for i = 1:11
    for i = 1:6
    Load_vect(i+n,1) = NormalLoads(test,i);
    end

 % n = n+11;
 n = n+6;
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
lb = [0 -3 0 0 -200];
up = [3000 2 2 2 200];

%training Data
Fittedcoefs = zeros(4+extraSet,5,length(specified));


for traing = 1:20
    for i = 1:length(specified)
    test = specified(i);
        if traing ==1

         % Fy = -1100N
         D  = 3000;  %x1
         C  = -1.5;  %x2
         B  = .5;    %x3
         E  = .4;    %x4
         Sy = -20;
         Sh = 0;
         Coef_set1 = [D C B E Sy]; %starting coef for lsq for Fy = -1100

         % Fy = -880N
         D  = 3000;  %x1
         C  = -1.5;  %x2
         B  = .5;    %x3
         E  = .4;    %x4
         Sy = -20;
         Sh = 0;
         Coef_set2 = [D C B E Sy]; %starting coef for lsq for Fy = -880N


         % Fy = -650N
         D  = 2000;  %x1
         C  = -1.5;  %x2
         B  = .2;    %x3
         E  = .4;    %x4
         Sy = -20;
         Sh = 0;

         if i == 9
            D = 1000;
         else
         end

         Coef_set3 = [D C B E Sy]; %starting coef for lsq for Fy = -650


         % Fy = -200N
         D = 3000;  %x1
         C = -1.5; %x2
         B = .5;  %x3
         E = .4;%x4
         Sy = -20;
         Sh = 0;
         Coef_set4 = [D C B E Sy]; %starting coef for lsq for Fy = -200


         D = 100;  %x1
         C = -1.5; %x2
         B = .5;  %x3
         E = .4;%x4
         Sy = -20;
         Sh = 0;

         Coef_set5 = [D C B E Sy];
         Coef_set6 = [D C B E Sy];
         % Coef_set7 = [D C B E Sy];
         % Coef_set8 = [D C B E Sy];
         % Coef_set9 = [D C B E Sy];
         % Coef_set10 = [D C B E Sy];
         % Coef_set11 = [D C B E Sy];
        else
         Coef_set1 = Fittedcoefs(1,:,test) ;
         Coef_set2 = Fittedcoefs(2,:,test) ;
         Coef_set3 = Fittedcoefs(3,:,test) ;
         Coef_set4 = Fittedcoefs(4,:,test) ;
         Coef_set5 = Fittedcoefs(5,:,test) ;
         Coef_set6 = Fittedcoefs(6,:,test) ;
         % Coef_set7 = Fittedcoefs(7,:,test) ;
         % Coef_set8 = Fittedcoefs(8,:,test) ;
         % Coef_set9 = Fittedcoefs(9,:,test) ;
         % Coef_set10 = Fittedcoefs(10,:,test) ;
         % Coef_set11 = Fittedcoefs(11,:,test) ;
        end

    MF = @(x,SA)x(1).*sin(-1.55.*atan(x(3).*((1-x(4)).*(SA+Sh)+(x(4)/x(3)).*atan(x(3).*(SA+Sh))))) + x(5);

    fit_set1 = lsqcurvefit(MF,Coef_set1,TireData(set1,9,test),TireData(set1,4,test),lb,up); % Fitting set 1
    fit_set2 = lsqcurvefit(MF,Coef_set2,TireData(set2,9,test),TireData(set2,4,test),lb,up); % Fitting set 2
    fit_set3 = lsqcurvefit(MF,Coef_set3,TireData(set3,9,test),TireData(set3,4,test),lb,up); % Fitting set 3
    fit_set4 = lsqcurvefit(MF,Coef_set4,TireData(set4,9,test),TireData(set4,4,test),lb,up); % Fitting set 4

    % adding more sets: from mfeVal
    fit_set5 = lsqcurvefit(MF,Coef_set5,TireData(set5,9,test),TireData(set5,4,test),lb,up); % Fitting set 4
    fit_set6 = lsqcurvefit(MF,Coef_set6,TireData(set6,9,test),TireData(set6,4,test),lb,up); % Fitting set 4
    % fit_set7 = lsqcurvefit(MF,Coef_set7,TireData(set7,9,test),TireData(set7,4,test),lb,up); % Fitting set 4
    % fit_set8 = lsqcurvefit(MF,Coef_set8,TireData(set8,9,test),TireData(set8,4,test),lb,up); % Fitting set 4
    % fit_set9 = lsqcurvefit(MF,Coef_set9,TireData(set9,9,test),TireData(set9,4,test),lb,up); % Fitting set 4
    % fit_set10 = lsqcurvefit(MF,Coef_set10,TireData(set10,9,test),TireData(set10,4,test),lb,up); % Fitting set 4
    % fit_set11 = lsqcurvefit(MF,Coef_set11,TireData(set11,9,test),TireData(set11,4,test),lb,up); % Fitting set 4


    % Fittedcoefs(:,:,test) = [fit_set1;fit_set2;fit_set3;fit_set4;fit_set5;fit_set6;fit_set7;fit_set8;fit_set9;fit_set10;fit_set11];
      Fittedcoefs(:,:,test) = [fit_set1;fit_set2;fit_set3;fit_set4;fit_set5;fit_set6];



    end
end

% FittedCoefs([Coefs],set number, test number)


%% check fits with plots

D = 500;  %x1
C = -1.7; %x2
B = .15;  %x3
E = .4;%x4
Sy = -20;
Sh = 0;
Coef_setx = [D C B E Sy];

for i = 1:length(specified)
    test = specified(i);

    figure(Name = "Fit check!")
    plot(TireData(set,9,test),TireData(set,4,test),".");%plotting raw data
    hold on
    plot(TireData(set1,9,1),MF(Fittedcoefs(1,:,test),TireData(set1,9,1)),linewidth=3)
    hold on
    plot(TireData(set2,9,1),MF(Fittedcoefs(2,:,test),TireData(set2,9,1)),linewidth=3)
    hold on
    plot(TireData(set3,9,1),MF(Fittedcoefs(3,:,test),TireData(set3,9,1)),linewidth=3)
    hold on
    plot(TireData(set4,9,1),MF(Fittedcoefs(4,:,test),TireData(set4,9,1)),linewidth=3)
    hold on
    plot(TireData(set5,9,1),MF(Fittedcoefs(5,:,test),TireData(set5,9,1)),'--',linewidth=3)
    hold on
    plot(TireData(set6,9,1),MF(Fittedcoefs(6,:,test),TireData(set6,9,1)),'--',linewidth=3)
    % hold on
    % plot(TireData(set7,9,1),MF(Fittedcoefs(7,:,test),TireData(set7,9,1)),'--',linewidth=3)
    % hold on
    % plot(TireData(set8,9,1),MF(Fittedcoefs(8,:,test),TireData(set8,9,1)),'--',linewidth=3)
    % hold on
    % plot(TireData(set9,9,1),MF(Fittedcoefs(9,:,test),TireData(set9,9,1)),'--',linewidth=3)
    % hold on
    % plot(TireData(set10,9,1),MF(Fittedcoefs(10,:,test),TireData(set10,9,1)),'--',linewidth=3)
    % hold on
    % plot(TireData(set11,9,1),MF(Fittedcoefs(11,:,test),TireData(set11,9,1)),'--',linewidth=3)
    %legend('Raw data',"fitted set 1","fitted set 2","fitted set 3","fitted set 4","fitted set 5","fitted set 6","fitted set 7","fitted set 8","fitted set 9","fitted set 10","fitted set 11");
     legend('Raw data',"fitted set 1","fitted set 2","fitted set 3","fitted set 4","fitted set 5","fitted set 6");

    % hold on 
    % plot(TireData(set3,9,1),MF(Coef_setx,TireData(set3,9,1)))
    % pause(0.5)

end


%% Fitting equation for ay1 and ay2 (regression) 

% Developing X matrix 
 polysize = 2;
 X = zeros((4+extraSet)*length(specified),polysize);
 

 n=-(4+extraSet);
 for j = 1:length(specified)
     test= specified(j);
     n = n+(4+extraSet);

    for i = 1:(4+extraSet)
        X(i+n,1) = NormalLoads(test,i);
        X(i+n,2) = NormalLoads(test,i).^2;

     end
 end

% filling in D: Creating a vector of all the fitted D coefs

D_vect = zeros((4+extraSet)*length(specified),1);
n=0;
for j =1:length(specified)
test = specified(j);

    for i = 1:(4+extraSet)
    n = n+1;
    D_vect(n) =  Fittedcoefs(i,1,test);
    
    end

end


% Solving for B = [ay1 ay2]
B = inv((transpose(X)*X)) * transpose(X)*D_vect;
B2 = pinv(X)*D_vect;

ay1 = B(2);
ay2 = B(1);
A(1,1) = ay1;
A(1,2) = ay2;

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



%% fitting AY3, Ay4, AY5 using LSQ

ay3 = -1;
ay4 = -100;
ay5 = -80;

B_set = [ay3 ay4 ay5]; 
BCE_eq = @(x,Fz) x(1)*sin(x(2)*atan(x(3)*Fz));


% optain B coefs vect
BCE_vect = zeros((4+extraSet)*length(specified),1);
n=0;

for j =1:length(specified)
    test = specified(j);

    for i = 1:(4+extraSet)
        n = n+1;
        BCE_vect(n) =  Fittedcoefs(i,3,test);
    
    end

end



for i = 1:length(D_vect)
    B_vect(i) = BCE_vect(i)/(C*D_vect(i));

end

BCoefs= lsqcurvefit(BCE_eq,B_set,Load_vect(:),B_vect(:)); 

% Validation
% 
% figure(Name = 'Testing fitted coefs for BCE')
% 
%     plot(Load_vect,B_vect,"o",Linewidth =1)
%     hold on
%     plot(Load_vect(:),BCE_eq(BCoefs,Load_vect),"x")



Ay3 = BCoefs(1);
Ay4 = BCoefs(2);
Ay5 = BCoefs(3);

A(1,3) = Ay3;
A(1,4) = Ay4;
A(1,5) = Ay5;


%% Solving for Ay6 Ay7 Ay8 (refine this process)


% Developing M matrix 
polysize = 3;
M = zeros((4+extraSet)*length(specified),polysize);

test=1;
n=-(4+extraSet);
for j = 1:length(specified)
     test= specified(j);
     n = n+(4+extraSet);

    for i = 1:(4+extraSet)
     M(i+n,3) = 1;
     M(i+n,2) = NormalLoads(test,i);
     M(i+n,1) = NormalLoads(test,i).^2;

     end
end


% filling in E
E_vect = zeros((4+extraSet)*length(specified),1);

n=0;
for j =1:length(specified)
    test = specified(j);

    for i = 1:(4+extraSet)
        n = n+1;
        E_vect(n) =  Fittedcoefs(i,4,test);
    
    end
end


% Solving for E = [ay6 ay7 ay8]
ECoefs = inv((transpose(M)*M)) * transpose(M)*E_vect;
ECoefs2 = pinv(M)*E_vect;
data = M*ECoefs;

Ay6 = ECoefs(1);
Ay7 = ECoefs(2);
Ay8 = ECoefs(3);

A(1,6) = Ay6; 
A(1,7) = Ay7; 
A(1,8) = Ay8; 



%%%%% Validation 

figure

n=0;
for j =1:length(specified)
    for i = 1:(4+extraSet)
        n = n+1;
        plot(NormalLoads(j,i),data(n),"*")
        hold on
        plot(NormalLoads(j,i),E_vect(n),"o")
    end
end

legend("Output from fitted coefs a1 a2", "Fitted D coefs")


figure 
% l = [1 2 3 4 5 6 7 8 9 10 11];
l = [1 2 3 4 5 6];
for n = 1:length(specified)
    test = specified(n);
    plot(l,Fittedcoefs(:,4,test),"*",linewidth = 2)
    % l = l + [11 11 11 11 11 11 11 11 11 11 11];
    l = l + [6 6 6 6 6 6];
    hold on
end
hold on
x = 1:(4+extraSet)*length(specified);
plot(x,data(:),"x",linewidth = 2)
grid on

legend("x = numerical ","* = raw data ")


%% futher data seperation Manual labor IA

% figure
% plot(TireData(run_set,9,1),TireData(run_set,6,1));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,6,2));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,6,3));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,6,4));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,6,5));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,6,6));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,6,7));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,6,8));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,6,9));
% hold on
% plot(TireData(run_set,9,1),TireData(run_set,6,10));


% IA
% 0: test(1,2,5,6,9,10) Pure: 1,5,9,10
% 2: test(2,3,6,7)      
% 4: test(3,4,7,8)



IA_0 = zeros(length(set1),100);

% Filling in IA

IA_0(:,1) = TireData(set1,6,1);
IA_0(:,2) = TireData(set2,6,1);
IA_0(:,3) = TireData(set3,6,1);
IA_0(:,4) = TireData(set4,6,1);

IA_0(:,5) = TireData(set1,6,5);
IA_0(:,6) = TireData(set2,6,5);
IA_0(:,7) = TireData(set3,6,5);
IA_0(:,8) = TireData(set4,6,5);

IA_0(:,9) = TireData(set1,6,9);
IA_0(:,10) = TireData(set2,6,9);
IA_0(:,11) = TireData(set3,6,9);
IA_0(:,12) = TireData(set4,6,9);

IA_0(:,13) = TireData(set1,6,10);
IA_0(:,14) = TireData(set2,6,10);
IA_0(:,15) = TireData(set3,6,10);
IA_0(:,16) = TireData(set4,6,10);

IA_Zero = [1 5 9 10];

% figure(name = "IA = 0 Pure data")
% for i = 1:16
% plot(TireData(set1,9,1),IA_0(:,i),".");
% hold on
% end

end