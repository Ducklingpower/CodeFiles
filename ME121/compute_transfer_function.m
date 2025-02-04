function TF = compute_transfer_function(s, m1, m2, c1, c2, k1, k2)
    % Define symbolic variables
    syms X1 X2 F

    % Define the given equations
    eq1 = X1 == (X2*(s*c1 + k1) + F) / (s^2*m1 + s*c1 + k1);
    eq2 = X2 == (X1*(s*c1 + k1) - F) / (s^2*m2 + s*(c2 + c1) + (k2 + k1));

    % Solve the system of equations for X1 and X2
    [solX1, solX2] = solve([eq1, eq2], [X1, X2]);

    % Compute (X1 - X2) / F
    TF = simplify((solX1 - solX2) / F);
end