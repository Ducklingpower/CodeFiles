function [fit,coef] = fitter(x,y)

% D = 1;%% peak points, also depend on frequency. Test from max-min values
% C = -1; %% frequemncy
% B = 1;%%how quickly it goes from low to high. Test from 0-1
% E = 1.1;%% rebound typically less than. Test from 0-1.1 small increments
% x = -15:.01:15;
%%fit=D*sin(C*atan(B*x-E*(B*x-atan(B*x))));
error = zeros(1,1);

coef = zeros(1,4);
fit = zeros(1,1);
for i = 1:25
ymax=  max(y(:,i));
ymin=  min(y(:,i));
coef_bin = zeros(1,4);

location_ymax = find(y(:,i) ==ymax);
location_ymin = find(y(:,i) ==ymin);
l = location_ymax-location_ymin;
if l <0
SA = location_ymax:location_ymin;
else
SA = location_ymin:location_ymax;
end
% 
% location_xmax = x(location_ymax,i);
% location_xmin = x(location_ymin,i);

dist  = location_ymin-location_ymax;
for j = 1:100000
D = randi([round(1000*(ymax-ymax*.2)),round(1000*(ymax+ymax*.2))])/1000;
C = randi([-15000,100])/10000;
B = randi([1,100])/100;
E = randi([1000,10000])/10000;

if dist<=0 
    
yy = location_ymin:10:location_ymax;
checker = y(yy,i);
location_x  = x(yy,1);

test=D.*sin(C.*atan(B.*location_x-E.*(B.*location_x-atan(B.*location_x))));


summation = abs(test-checker);
error(j,i) = sum(summation);
else
   
yy = location_ymax:10:location_ymin;
checker = y(yy,i);
location_x  = x(yy,1);

test=D.*sin(C.*atan(B.*location_x-E.*(B.*location_x-atan(B.*location_x))));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
summation = abs(test-checker);

error(j,i) = sum(summation);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end



% maxx=D*sin(C*atan(B*location_xmax-E*(B*location_xmax-atan(B*location_xmax))));
% minn= D*sin(C*atan(B*location_xmin-E*(B*location_xmin-atan(B*location_xmin))));
coef_bin(j,1) = D;
coef_bin(j,2) = C;
coef_bin(j,3) = B;
coef_bin(j,4) = E;
%%error(j,i) = abs(maxx-ymax)+abs(minn-ymin);


end

t = min(nonzeros(error(:,i)));
ise  = isempty(t);
if  ise == 1

    c=1;

else
    c= find(error(:,i) == t);

c = max(c);
end


num = coef_bin(c,1)*sin(coef_bin(c,2)*atan(coef_bin(c,3).*location_x-coef_bin(c,4)*(coef_bin(c,3).*location_x-atan(coef_bin(c,3).*location_x))));
SA = 1:10:length(SA);
for p  =1:length(SA)
    fit(p,i) = num(p);
  

end
coef(i,1) =coef_bin(c,1);
coef(i,2) =coef_bin(c,2);
coef(i,3) =coef_bin(c,3);
coef(i,4) =coef_bin(c,4);


end




end

