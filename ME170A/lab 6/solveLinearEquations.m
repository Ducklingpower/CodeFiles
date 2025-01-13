function [vectorX]= solveLinearEquations(Coe_A,vectorB)

augmented=[Coe_A,vectorB];

row_ech_form=gaussElimination(augmented);
[R,C]=size(row_ech_form);
n=length(Coe_A);
vectorX=zeros(R,1);

vectorX(R)=row_ech_form(R,R+1)/row_ech_form(R,R);
for i=R:-1:2
vectorX(i-1)=row_ech_form(i-1,R+1)-row_ech_form(i-1,i-1+1:R)*vectorX(i-1+1:R,1)/row_ech_form(i-1,i-1);
%(x,n:R) is how we can extend out rows / cap at R 

end
end