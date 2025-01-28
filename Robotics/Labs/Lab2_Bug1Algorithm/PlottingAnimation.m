clc
close all
clear

Pstart = [0 0];
Pgoal  = [5 3];
P(:,:,1) = [1 0; 1 2 ; 3 0];
P(:,:,2) = [2 3; 4 1; 5 2];
stepsize = 0.1;

tic;
Path = computeBug(Pstart,Pgoal,P,stepsize);
close all
%% Plotting dist vs time

computation_time = toc;

x_path = Path(:, 1);
y_path = Path(:, 2);
x_goal = Pgoal(1);
y_goal = Pgoal(2);

distances_to_goal = sqrt((x_path - x_goal).^2 + (y_path - y_goal).^2);

% Calculate total path length
path_segments = sqrt(diff(x_path).^2 + diff(y_path).^2); % Length of each segment
total_path_length = sum(path_segments);

time_steps = linspace(0, computation_time, length(distances_to_goal)); % Simulated time steps

figure;
plot(time_steps, distances_to_goal, '-o', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Distance to Goal');
title('Distance to Goal as a Function of Time');
grid on;
axis normal;
axis square;

% Display results
fprintf('Total Path Length: %.2f units\n', total_path_length);
fprintf('Computation Time: %.4f seconds\n', computation_time);
 %%

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
title("Path from start to goal")
xlabel("X position")
ylabel("Y position")
grid on
axis normal;
axis square;

for i = 1:length(Path)
plot(Path(i,1),Path(i,2),"*",LineWidth=2)
hold on
pause(0.1)

end
