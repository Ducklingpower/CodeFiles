function y = Double_Integrate(signal,step_size,x_IC,v_IC)

x = signal;
dt = step_size;

y = zeros(length(signal),1);
area = v_IC;
y(1) = v_IC;
for i = 2:length(signal)
    if i ==length(signal)
        y(i) = area;
    else
        area = (x(i) + x(i+1))/2 * dt+ area; 
        y(i) =area;

    end

end

% integrate again --

x = y; 
area = x_IC;
y = zeros(length(signal),1);
y(1) = x_IC;
for i = 1:length(signal)
    if i ==length(signal)
        y(i) = area;
    else
        area = (x(i) + x(i+1))/2 * dt+ area; 
        y(i) =area;

    end

   
end
