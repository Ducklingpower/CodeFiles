%% Given Parameters
Area = 168.4;    %Surface Area of HX
Cpc = 2.05; %specific heat of COLD fluid
Cph = 2.4; %specific heat of HOT fluid
mc = 22;    %Mass flow cold fluid
mh = 17;  %Mass flow hot fluid
Tci = 3;  
Thi = 151;
U = 315; %overall heat transfer coefficient
%check
%% Calculating Cmin, Cmax, and Cr
Cc = mc*Cpc*1000;
Ch = mh*Cph*1000;
Cmin = -1;
Cmax = -1;
Cr = -1;
if (Cc < Ch)
       Cmin = Cc;
       Cmax = Ch;
       Cr = Cmin / Cmax;
elseif (Cc > Ch)
       Cmin = Ch;
       Cmax = Cc;
       Cr = Cmin / Cmax;
else
       Cr = 1;       
end
%% Computing NTU
NTU = U*Area/Cmin;
%% Computing Epsilon (effectiveness)
%epsilon = 1 - exp(((NTU^0.22)/Cr) * (exp(-Cr*(NTU^0.78))-1));
p = exp(-Cr*(NTU^0.78))-1;
r = (1/Cr)*(NTU^0.22)*p;
epsilon = 1-exp(r);
%% Computing Exit Temps (Tco, Tho)
Tco = Tci + (epsilon*Cmin*(Thi-Tci))/Cc;
Tho = Thi - (epsilon*Cmin*(Thi-Tci))/Ch;
%% Computing Q
Q = Cpc*mc*(Tco-Tci);
%% Print Results
fprintf("Q = " + Q +"\n")
fprintf("Tco = " + Tco +"\n")
fprintf("Tho = " + Tho +"\n")
fprintf("Epsilon = " + epsilon +"\n")