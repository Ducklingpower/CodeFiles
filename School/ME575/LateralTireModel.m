function Fy = LateralTireModel(Fz,SA)

% Inputs
% [Fz,SA]

% Output
% Lateral Force Fy

load("TireModelCoefs.mat")

sh =0;

C = -1.57;


D = A(1,1)*Fz.^2 + A(1,2)*Fz;
BCD = A(1,3).*sin(A(1,4).*atan(A(1,5).*Fz));
B = BCD.*(C.*D);
E = A(1,6)*Fz.^2 + A(1,7)*Fz+ A(1,8);
phi = (1-E).*(SA+sh)+(E./B).*atan(B.*(SA+sh));

Fy = D.*sin(C.*atan(B.*phi));
Fy = Fy * 0.575;

end