x = 1:100;
y = 1:100;


for i = 1:3
    figure(1)
    x = x*2;

    plot(x,y)
 
    hold on
     legend(num2str(1),num2str(2),'hi')


    figure(2);
    plot(y,x)
    hold on
end