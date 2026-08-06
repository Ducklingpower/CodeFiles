function [Fx, Fy, info] = tire_forces(p, sy, sx, Fz, tyreTempC)
%TIRE_FORCES  Combined-slip tyre forces -- 1:1 port of
%   WheelController.calcTyreForcesNonlinear()
%   (Assets/Autonoma/Scripts/VehicleDynamics/WheelController.cs:181).
%
%   [Fx, Fy] = TIRE_FORCES(p, sy, sx, Fz)
%       p   parameter struct from tire_params()
%       sy  slip angle  [rad]  (sim: sy = atan(-vy/|vx|), relaxation-lagged)
%       sx  slip ratio  [-]    (sim: sx = (omega*R - vx)/|vx|, lagged)
%       Fz  vertical load [N]
%   sy/sx/Fz may be any mix of scalars and arrays of compatible size
%   (implicit expansion); the outputs take the broadcast size.
%
%   [Fx, Fy] = TIRE_FORCES(p, sy, sx, Fz, T) uses tyre temperature T [degC]
%   for the grip scaling when p.useThermal is true.
%
%   [Fx, Fy, info] = ... also returns S, By, Bx, DxEff, DyEff,
%   thermalScaling and the linear-range cornering stiffness Cy_alpha [N/rad].
%
%   THE MODEL
%     S    = sqrt(sy^2 + sx^2)                     combined slip magnitude
%     By   = tan(pi/(2*Cy))/syPeak                 stiffness from peak slip
%     Dy_e = Dy + Dy2*(Fz_clamped - FzNom)/FzNom   load sensitivity
%     Fy   = k_T * Fz * (sy/S) * Dy_e * sin(Cy*atan(By*S))
%     Fx   = k_T * Fz * (sx/S) * Dx_e * sin(Cx*atan(Bx*S))
%   i.e. a Pacejka magic formula with no curvature term E and no horizontal
%   or vertical shifts (Sh/Sv), with the friction circle enforced by the
%   sy/S and sx/S direction cosines rather than a separate weighting fn.
%
%   QUIRKS WORTH KNOWING BEFORE YOU TUNE
%   * S mixes an angle in radians with a dimensionless slip ratio, so the
%     lateral/longitudinal split is only "isotropic" in those units.
%   * Load sensitivity is clamped to Fz in [FzNom/3, 3*FzNom], but the Fz
%     that multiplies the force is NOT clamped: past 3*FzNom the peak mu
%     stops falling and Fy keeps growing linearly with load.
%   * There is no camber, no Mz, no relaxation here (relaxation lives in
%     WheelController.calcSySx and is a pure lag -- it does not change these
%     steady-state curves).

if nargin < 5 || isempty(tyreTempC)
    tyreTempC = p.tAmb;
end

Fz = max(Fz, 0);                        % calcFz clamps Fz >= 0

S    = sqrt(sy.^2 + sx.^2);
Sden = max(S, 1e-4);                    % Mathf.Max(S, 0.0001f)
sy_S = sy ./ Sden;
sx_S = sx ./ Sden;

By = tan(pi/(2*p.Cy)) / p.syPeak;
Bx = tan(pi/(2*p.Cx)) / p.sxPeak;

% --- temperature -> grip scaling (calcThermalScaling, WheelController.cs:210)
if p.useThermal
    Tclamped       = min(max(tyreTempC, 0), 199);   % as clamped in calcTyreTemp
    thermalScaling = lut1d_nonlinear(p.numPointsFrictionMap, ...
                        p.thermalFrictionMapInput, p.thermalFrictionMapOutput, Tclamped);
else
    thermalScaling = 1;
end

% --- load-sensitive peak friction ---------------------------------------
FzLoad = min(max(Fz, p.FzNom/3), p.FzNom*3);
DyEff  = p.Dy + p.Dy2*(FzLoad - p.FzNom)/p.FzNom;
DxEff  = p.Dx + p.Dx2*(FzLoad - p.FzNom)/p.FzNom;

% --- forces --------------------------------------------------------------
Fy = thermalScaling .* Fz .* sy_S .* DyEff .* sin(p.Cy*atan(By*S));
Fx = thermalScaling .* Fz .* sx_S .* DxEff .* sin(p.Cx*atan(Bx*S));

Fy(isnan(Fy)) = 0;
Fx(isnan(Fx)) = 0;

if nargout > 2
    info = struct();
    info.S              = S;
    info.By             = By;
    info.Bx             = Bx;
    info.DyEff          = DyEff;
    info.DxEff          = DxEff;
    info.thermalScaling = thermalScaling;
    % slope of Fy at sy -> 0 (pure lateral): d/dsy [Fz*D*sin(C*atan(B*sy))]
    info.Cy_alpha       = thermalScaling .* Fz .* DyEff * p.Cy * By;   % [N/rad]
    info.Cx_kappa       = thermalScaling .* Fz .* DxEff * p.Cx * Bx;   % [N/-]
end
end
