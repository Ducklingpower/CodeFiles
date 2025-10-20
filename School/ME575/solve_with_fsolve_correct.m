function solve_with_fsolve_correct
  % x = [a0, b0, b1, b2, b3, b4]
  x0 = [900; 12474; 2759; 831; 3.3; 7.78];   % set BEFORE fsolve

  opts = optimoptions('fsolve','Display','iter', ...
      'SpecifyObjectiveGradient',true, ...
      'FunctionTolerance',1e-12, ...
      'StepTolerance',1e-12, ...
      'OptimalityTolerance',1e-12);

  [x, fval, exitflag, output] = fsolve(@F, x0, opts);

  a0=x(1); b0=x(2); b1=x(3); b2=x(4); b3=x(5); b4=x(6);

  fprintf('\nSolution (x = [a0 b0 b1 b2 b3 b4]):\n');
  fprintf('%.12f  %.12f  %.12f  %.12f  %.12f  %.12f\n', x);

  % verify by comparing coefficients
  [P,Q] = buildPolys(a0,b0,b1,b2,b3,b4);
  fprintf('\nP(s) coeffs (s^6..s^0):\n'); disp(P);
  fprintf('Q(s) coeffs (s^6..s^0):\n'); disp(Q);
  fprintf('max|P-Q| = %.3e\n', max(abs(P-Q)));
  fprintf('exitflag = %d\n', exitflag);
  disp(output);

  % ------------ nested functions -------------
  function [r,J] = F(x)
    a0=x(1); b0=x(2); b1=x(3); b2=x(4); b3=x(5); b4=x(6);

    % residuals (your equations, unchanged)
    r = [
      9 - 85.656 + a0 - b2;
      17 - 2868.48 + 8*b2 - b2*b3 - b2*b4 - b1;
      81 - 46854.4 + 8*b1 - b2*b3*b4 - b1*b3 - b1*b4 - b0;
      72 - 379392 + 8*b2*b3 + 8*b2*b4 + 8*b1*b3*b4 + 8*b0 ...
                   - b1*b3*b4 - b0*b3 - b0*b4;
      -1416960 + 72*a0 - b0*b3*b4 + 8*b0*b3 + 8*b0*b4 + 8*b1*b3*b4;
      -2560000 + 8*b0*b3*b4
    ];

    if nargout>1
      % analytic Jacobian
      % r1
      J = zeros(6,6);
      J(1,:) = [ 1, 0, 0, -1, 0, 0 ];

      % r2
      J(2,:) = [ 0, 0, -1, 8 - b3 - b4, -b2, -b2 ];

      % r3
      J(3,:) = [ 0, -1, 8 - b3 - b4, -b3*b4, -(b2*b4 + b1), -(b2*b3 + b1) ];

      % r4
      % 72 - 379392 + 8 b2 b3 + 8 b2 b4 + 8 b1 b3 b4 + 8 b0 - b1 b3 b4 - b0 b3 - b0 b4
      J(4,1) = 0;
      J(4,2) = 8 - b3 - b4;
      J(4,3) = 8*b3*b4 - b3*b4;             % = 7 b3 b4
      J(4,4) = 8*b3 + 8*b4;
      J(4,5) = 8*b2 + 8*b1*b4 - b1*b4 - b0; % = 8b2 + 7 b1 b4 - b0
      J(4,6) = 8*b2 + 8*b1*b3 - b1*b3 - b0; % = 8b2 + 7 b1 b3 - b0

      % r5
      % -1416960 + 72 a0 - b0 b3 b4 + 8 b0 b3 + 8 b0 b4 + 8 b1 b3 b4
      J(5,1) = 72;
      J(5,2) = -(b3*b4) + 8*b3 + 8*b4;
      J(5,3) = 8*b3*b4;
      J(5,4) = 0;
      J(5,5) = -b0*b4 + 8*b0 + 8*b1*b4;
      J(5,6) = -b0*b3 + 8*b0 + 8*b1*b3;

      % r6
      % -2560000 + 8 b0 b3 b4
      J(6,:) = [ 0, 8*b3*b4, 0, 0, 8*b0*b4, 8*b0*b3 ];
    end
  end

  function [P,Q] = buildPolys(a0,b0,b1,b2,b3,b4)
    % Q(s) = (s+20)^4 (s^2 + 5.656 s + 16)
    Q = conv(conv(conv([1 20],[1 20]), conv([1 20],[1 20])), [1 5.656 16]);

    % P(s) = ((s+1)(s+8))((s^3+9s)(s+a0)) + (-s+8)((b2 s^2 + b1 s + b0)((s+b3)(s+b4)))
    A = conv([1 1],[1 8]);          % s^2 + 9s + 8
    B = [1 0 9 0];                   % s^3 + 9 s
    C = [1 a0];                      % s + a0
    T1 = conv(A, conv(B, C));

    D = [-1 8];                      % -s + 8
    E = [b2 b1 b0];
    F = conv([1 b3],[1 b4]);         % [1, b3+b4, b3*b4]
    T2 = conv(D, conv(E, F));

    P = T1 + T2;
  end
end
