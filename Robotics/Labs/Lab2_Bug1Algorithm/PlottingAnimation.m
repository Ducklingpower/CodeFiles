
%%
close all


figure 


for j =1: length(P(1,1,:))
X = P(:,1,j);
Y = P(:,2,j);
fill(X,Y,[0.8 0.7 0.8])
hold on 
end

plot(Pgoal(1),Pgoal(2),"*")
hold on

plot(Pstart(1),Pstart(2),"*")
hold on

xlim([-1,6])
ylim([-1,6])
grid on
axis normal;
axis square;

for i = 1:length(Path)
plot(Path(i,1),Path(i,2),"*",LineWidth=2)
hold on
pause(0.1)

end

