function Grid = computeGridRandom(n)
    Grid = rand(n, 2);
    plot(Grid(:,1), Grid(:,2),'o')
    grid on
end
