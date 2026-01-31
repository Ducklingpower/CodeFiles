function y = Integrate(signal,step_size,IC)

x = signal;
dt = step_size;

y = zeros(length(signal),1);
area = IC;
y(1) = IC;
for i = 1:length(signal)
    if i ==length(signal)
        y(i) = area;
    else
        area = (x(i) + x(i+1))/2 * dt+ area; 
        y(i) =area;
    end
end
