function X=solveLinearSystem(A,b)
[L,U,P]=luDecomposition(A);
Y=forwardSubstitution(L,b,P);
X=backSubstitution(U,Y);
end
