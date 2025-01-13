x=input('Enter a shipping service. ground=1, 2nd day= 2, or overnight=3');

if x==1
G=input('Enter weight of package'); %ground section
if G <=2 && G>0
    fprintf('The price is $1.50 with a weight of %0.2f\n',G)%price for ground 0-2
elseif G>2 && G<=10
   P=1.5+((0.50*(ceil(G))-1));%price for ground 2-10
fprintf('The price is %0.2f $ with a weight of %0.2f\n',P,G)
elseif G>10 && G<=50
    P=5.50+((0.3*(ceil(G))-3));%price for ground 10-50
    fprintf('the price is %0.2f $ with a weight of %0.2f\n',P,G)
elseif G>50
    fprintf('service is not available for packages over 50 lb\n')
elseif G<0
    fprintf('must input a positive number\n')
end%end of ground section



elseif x==2 % section for 2nd day 
    G=input('enter weight of package');
   if G<=2 && G>0
       fprintf('the price is 3$ with a weight of %0.2f\n',G) %if packing is below 2
   elseif G>2 && G<=10
       P= 3.00+(0.9*(ceil(G))-1.8);
       fprintf('The price is $%0.2f with a weight of %0.2f\n',P,G)
   elseif G>10 && G<=50
       fprintf('The price is $%0.2f with a weight of %0.2f\n',P,G)
       elseif G>50
    fprintf('service is not available for packages over 50 lb\n')
    elseif G<0
    fprintf('must input a positive number\n')
   end



elseif x==3%over night service 
     G=input('enter weight of package');
if G<=2 && G>0
    fprintf('The price is $18 with a weight of %.2f\n',G)
elseif G>2 && G<=10
    P=18+((6*(ceil(G)))-12);
    fprintf('The price is %.2f with a weight of %.2f\n',P,G)
elseif G>10
   fprintf('Overnight service is not available for packages over 10lb\n')
   elseif G<0
    fprintf('must input a positive number\n')
end
else 
    fprintf('Must enter 1,2, or 3\n')

end


