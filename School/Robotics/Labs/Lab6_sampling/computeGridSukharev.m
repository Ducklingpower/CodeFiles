function Grid = computeGridSukharev(n)

k = sqrt(n);
% check for perfect squar

if k ~= floor(k)
error("n is not a perfect square!")
end

m=0.5;
p=0;

for i = 1:k
n=0;
    for j =1:k
    p = p+1;    
    Gridx(p) = n+0.5;
    Gridy(p) = m;
    n = n+1;
    end
m = m+1;
end

Grid = [Gridx./k; Gridy./k];

% figure
% plot(Grid(1,:),Grid(2,:),".",LineWidth=2)
% xlim([0 1])
% ylim([0 1])
% grid on
end