function Mz = AligningTireModel(Fz,SA)

% Inputs
% [Fz,SA]

% Output
% Lateral Force Fy

load("TireModelCoefs.mat")

sh =0;

C = 2.4;
D = A(2,1)*Fz.^2 + A(2,2)*Fz;
BCD = A(2,3).*Fz.^(3) + A(2,4).*Fz.^(2) + A(2,5).*Fz + A(2,6);
B = BCD.*C.*D;
E = A(2,7)*Fz.^2 + A(2,8)*Fz+ A(2,9);
phi = (1-E).*(SA+sh)+(E./B).*atan(B.*(SA+sh));
Mz = D.*sin(C.*atan(B.*phi));

Mz = Mz*0.575;
end