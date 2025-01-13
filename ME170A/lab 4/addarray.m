function [sum]=addarray(A)
x=1;
sum=A(1);
while x<numel(A)
   x=x+1;
    sum= sum +A(x);
end
end

