function inside = isPointInConvexPolygon(q, P)
    n = size(P, 1);
    inside = true; % Assume the point is inside the polygon

    for i = 1:n
        p1 = P(i, :);
        p2 = P(mod(i, n) + 1, :); % grab first point once n is maximum

        % Compute the interior normal vector
        normal = [- (p2(2) - p1(2)), (p2(1) - p1(1))];

        % Compute the vector from p1 to q
        pq = [q(1) - p1(1), q(2) - p1(2)];

        % dot product
        dot_product = normal(1) * pq(1) + normal(2) * pq(2);

        % If any dot product is negative, the point is outside the polygon
        if dot_product < 0
            inside = false;
            return;
        end
    end

end