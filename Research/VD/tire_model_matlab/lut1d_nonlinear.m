function y = lut1d_nonlinear(numPoints, tableX, tableY, x)
%LUT1D_NONLINEAR  Natural cubic-spline lookup, port of
%   HelperFunctions.lut1DNonlinear (Assets/Autonoma/Scripts/VehicleDynamics/
%   HelperFunctions.cs:142). Values outside the table are held flat at the
%   end points, exactly as the C# does.
%
%   Implemented from scratch (rather than MATLAB's spline(), which uses
%   not-a-knot end conditions) so the curve matches the sim bit-for-bit in
%   shape. Vectorised over x.

xa = double(tableX(:));
ya = double(tableY(:));
n  = numPoints - 1;                 % number of intervals

y = zeros(size(x));
if numPoints < 2
    y(:) = ya(1);
    return
end

h = diff(xa(1:numPoints));          % h(m) = X(m+1) - X(m)

% --- solve the natural-spline tridiagonal system (Burden & Faires) ------
alpha = zeros(numPoints,1);
for m = 2:n
    alpha(m) = 3/h(m)*(ya(m+1)-ya(m)) - 3/h(m-1)*(ya(m)-ya(m-1));
end

l  = zeros(numPoints,1);  mu = zeros(numPoints,1);  z = zeros(numPoints,1);
l(1) = 1;  mu(1) = 0;  z(1) = 0;
for m = 2:n
    l(m)  = 2*(xa(m+1)-xa(m-1)) - h(m-1)*mu(m-1);
    mu(m) = h(m)/l(m);
    z(m)  = (alpha(m) - h(m-1)*z(m-1))/l(m);
end
l(numPoints) = 1;  z(numPoints) = 0;

c = zeros(numPoints,1);  b = zeros(n,1);  d = zeros(n,1);
c(numPoints) = 0;
for m = n:-1:1
    c(m) = z(m) - mu(m)*c(m+1);
    b(m) = (ya(m+1)-ya(m))/h(m) - h(m)*(c(m+1) + 2*c(m))/3;
    d(m) = (c(m+1) - c(m))/(3*h(m));
end

% --- evaluate ------------------------------------------------------------
xs  = double(x(:));
lo  = xs <= xa(1);
hi  = xs >= xa(numPoints);
mid = ~lo & ~hi;

out       = zeros(numel(xs),1);
out(lo)   = ya(1);
out(hi)   = ya(numPoints);

if any(mid)
    xm = xs(mid);
    % first interval whose right edge is >= x, capped at the last interval
    idx = sum(xa(2:n).' < xm, 2) + 1;
    idx = min(max(idx,1), n);
    dx  = xm - xa(idx);
    out(mid) = ya(idx) + b(idx).*dx + c(idx).*dx.^2 + d(idx).*dx.^3;
end

y = reshape(out, size(x));
end
