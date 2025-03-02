function Grid = computeGridHalton(n,b1,b2)

Grid = zeros(n,2);
B = [b1 b2];
for i = 1:2 
   if isprime(B(i))
        for j = 1:n
            num = 1/B(i);
            m = 0;
            delta = j;
            while delta>0
                m = m+num*mod(delta,B(i));
                delta = floor(delta/B(i));
                num = num/B(i);
            end
        Grid(j,i) = m;
        end
    else
        error("Please make sure b1 and b2 are both prime numbers")
    end
end
figure
plot(Grid(:,1),Grid(:,2),"*")
grid on
xlim([0 1])
ylim([0 1])

end
