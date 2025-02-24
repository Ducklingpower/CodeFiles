function Grid = computeGridHalton(n, b1, b2)

     base = [b1,b2]; 
     

 for  k = 1:2
      seq= zeros(n, 1);
      TF = isprime(base(k));
  if TF == 1
    for i = 1:n
      f = 1 / base(k);
        r = 0;
        idx = i;
        while idx > 0
            r = r + f * mod(idx, base(k));
            idx = floor(idx / base(k));
            f = f / base(k);
        end
        seq(i) = r;
    end 
    Grid(:,k) = seq;
  else 
      error('Input b1 and b2 need to be prime values')
  end 
 end 
 plot(Grid(:,1), Grid(:,2),'o')
    grid on
end
