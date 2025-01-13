x=[1 3 5 7 ];
y=[1 5 3 10 ];
sp=cubicSplineCoefficients(x,y);
xx=[2 3 4 6 ];
yy=cubicSplineInterpolation(sp,xx);
YY=spline(x,y);

XX=ppval(YY,xx);


