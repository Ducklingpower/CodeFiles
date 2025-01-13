function stress=computeShearStress(D,V)
%n=length(D);
%x=linspace(-D(n),D(n));
%q=linspace(0, 0.0025,100);

s=spline(D,V);
% vv=ppval(s,q);
% plot(D,V,"ro")
% hold on
% plot(q,vv)
coefs=s.coefs;
x=0;
%y=coefs(1,1)+coefs(1,2)*x+coefs(1,3)*x^2+coefs(1,4)*x^3;
%stress=coefs(1,3)+2*x*coefs(1,2)+3*coefs(1,1)*x^2;
st=coefs(1,3)+2*x*coefs(1,2)+3*coefs(1,1)*x^2;
stress=(8.90*10^-4)*(st);



