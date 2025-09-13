x = 1:0.1:100
y = sin(x);


figure 

for i = 1:length(y)
plot(x(1,i),y(1,i),"*")
hold on
pause(0.01)
grid
end