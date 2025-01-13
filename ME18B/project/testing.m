p=spline([1 3 4 5 6 ],[1 2 4 7 10]);
coefs=p.coefs;
breaks = p.breaks;
yy=ppval(p,2);
