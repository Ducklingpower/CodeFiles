clc
close all
clear

%% Loading Raw Tire Data
Data = load("lateral_tire_test.mat");

%% Running Lateral Model

 specified = [1,2,3,4,5,6,7,8,9,10];
 specified = 1;
 specified = [5, 9, 10];

[A,TireData,NormalLoads,NormalLoads_vect,IA_Zero] = LateralForce(Data,specified);
                                                A = AligningMoment(A,TireData,specified);

save("TireModelCoefs","A")


% Notes

%%% About Lateral Model %%%

%TireData = [AMBTMP, ET, FX, FY, FZ, IA, MX, MZ, SA, SL, SR, V]

%Normal loads = 10x4 -> Colums = the 4 loads in a test, Rows = 10 tests total
%Normal Loads Vector = [test1 loads test2 ... test10 loads], same data in differnt form

%IA_zero = Specifies which tests have zero IA



%%% A Matrix Set up %%%

% A = [ay1 ay2 ay3 ay4 ay5 ay6 ay7 ay8 ay9 ay10 ay11 ay12 ay13;  Lateral Coefss
%      az1 az2 az3 az4 az5 az6 az7 az8 az9 az10 az11 az12 az13;
%      ax1 ax2 ax3 ax4 ax5 ax6 ax7 ax8 ax9 ax10 ax11 ax12 ax13];





%% Testing lateral Models Fit 

set = 1:1278*4;
for i = 1:length(specified)
    test = specified(i);
sh =0;
Fz = TireData(set,5,test);

C = -1.57;


D = A(1,1)*TireData(set,5,test).^2 + A(1,2)*TireData(set,5,test);
BCD = A(1,3).*sin(A(1,4).*atan(A(1,5).*Fz));
B = BCD.*(C.*D);
E = A(1,6)*TireData(set,5,test).^2 + A(1,7)*TireData(set,5,test)+ A(1,8);
phi = (1-E).*(TireData(set,9,test)+sh)+(E./B).*atan(B.*(TireData(set,9,test)+sh));
Fy = D.*sin(C.*atan(B.*phi));


figure(Name = "Lateral Model Fit Test")
plot(TireData(set,9,test),TireData(set,4,test),".")
hold on
plot(TireData(set,9,test),Fy(:),".")
grid on
legend("Tire data","Tire Model")
xlabel("Slip angle in degrees")
ylabel("Lateral Force in N")

end




%%

for i = 1:length(specified)
    test = specified(i);
sh =0;
Fz = TireData(set,5,test);

C = 2.4;

D = A(2,1)*TireData(set,5,test).^2 + A(2,2)*TireData(set,5,test);
BCD = (A(2,3) * Fz.^2 + A(2,4) * Fz) ./ exp(A(2,5) * Fz);


BCD = A(2,3).*Fz.^(3) + A(2,4).*Fz.^(2) + A(2,5).*Fz + A(2,6);



B = BCD.*(C.*D);
E = A(2,7)*TireData(set,5,test).^2 + A(2,8)*TireData(set,5,test)+ A(2,9);
phi = (1-E).*(TireData(set,9,test)+sh)+(E./B).*atan(B.*(TireData(set,9,test)+sh));
Fy = D.*sin(C.*atan(B.*phi));


figure(Name = "Lateral Model Fit Test")
plot(TireData(set,9,test),TireData(set,8,test),".")
hold on
plot(TireData(set,9,test),Fy(:),".")
grid on
legend("Tire data","Tire Model")
xlabel("Aligning Moment")
ylabel("Lateral Force in N")

end


%%
% test = 1;
% sh =0;
% figure(Name = "Lateral Model Fit Test")
% Fz=0;
% 
% tiledlayout(1,2)
%  nexttile
% for i = 1:230
% 
% Fz = Fz-5;
% 
% C = 2.4;
% 
% D = A(2,1)*Fz.^2 + A(2,2)*Fz;
% BCD = A(2,3).*Fz.^(3) + A(2,4).*Fz.^(2) + A(2,5).*Fz + A(2,6);
% B = BCD.*C.*D;
% E = A(2,7)*Fz.^2 + A(2,8)*Fz+ A(2,9);
% phi = (1-E).*((TireData(set,9,test))'+sh)+(E./B).*atan(B.*((TireData(set,9,test))'+sh));
% Mz = D.*sin(C.*atan(B.*phi));
% 
% 
% plot(TireData(set,9,test),Mz(:),".")
% grid on
% legend("Tire data","Tire Model")
% xlabel("Aligning Moment")
% ylabel("Lateral Force in N")
% hold on
% 
% legend('Fz = 0 N','Fz = -1150 N')
% 
% end
%  nexttile
%  Fz = 0;
% for i = 1:300
% 
% Fz = Fz-5;
% 
% C = 2.4;
% 
% D = A(2,1)*Fz.^2 + A(2,2)*Fz;
% BCD = A(2,3).*Fz.^(3) + A(2,4).*Fz.^(2) + A(2,5).*Fz + A(2,6);
% B = BCD.*C.*D;
% E = A(2,7)*Fz.^2 + A(2,8)*Fz+ A(2,9);
% phi = (1-E).*((TireData(set,9,test))'+sh)+(E./B).*atan(B.*((TireData(set,9,test))'+sh));
% Mz = D.*sin(C.*atan(B.*phi));
% 
% 
% plot(TireData(set,9,test),Mz(:),".")
% grid on
% legend("Tire data","Tire Model")
% xlabel("Aligning Moment")
% ylabel("Lateral Force in N")
% hold on
% 
% legend('Fz = 0 N','Fz = -1500 N')
% 
% end