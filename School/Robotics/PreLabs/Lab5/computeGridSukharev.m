% Eric Perez
% ME 145 Lab 5


function [Grid] = computeGridSukharev(n)
    k = sqrt(n);
    if k ~= floor(k)
        error('n is not a perfect square.');
    end
    Grid = zeros(n, 2);
    int = 1;
    for i = 0:k-1
        for j = 0:k-1
            Grid(int, :) = [(i + 0.5) / k, (j + 0.5) / k];
            int = int + 1;
        end
    end


plot(Grid(:,1), Grid(:,2),'o')
grid on;
end
