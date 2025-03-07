function Grid_random = computeGridRandom(n)

if length(n)~=1
error("n must be a single integer, n = # of points")
end

Grid_random = rand(n,2);
% figure
% plot(Grid_random(:,1),Grid_random(:,2),"*")
% xlim([0 1])
% ylim([0 1])
% grid on
end