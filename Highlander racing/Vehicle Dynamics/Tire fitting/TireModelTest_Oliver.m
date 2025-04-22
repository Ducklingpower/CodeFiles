clc
close all
clear all 
%%
Nsteps = 100;

Fzs = linspace(100, 1000, 10);
SAs = linspace(0, 15, Nsteps);

for i=1:length(Fzs)
    for j=1:length(SAs)
        OutputFy(i, j) = LateralTireModel(Fzs(i), SAs(j)); % OutputFy(Fzs, SAs)
    end
end

hold on
for m=1:length(Fzs)
    plot(SAs, OutputFy(m, :))
end

for l=1:length(Fzs)
    maxes(l) = max(OutputFy(l, :));
    SAs95p(l) = interp1(OutputFy(l, :), SAs, (0.95*maxes(l)));
    plot(SAs95p(l), 0.95*maxes(l), 'x')
    [~, peakSAsIndexes(l)] = max(OutputFy(l, :));
    peakSAs = SAs(peakSAsIndexes);
    mus(l) = maxes(l) / Fzs(l);
end
%% Plotting

figure

plot(Fzs, mus)
title("normal load vs mu")
xlabel("Fz")
ylabel("mu")

figure

plot(Fzs, SAs)
title("normal load vs peak SAs")
xlabel("Fz")
ylabel("peak SA")

figure

plot(Fzs, SAs95p)
title("normal load vs 95% peak SAs")
xlabel("Fz")
ylabel("peak SA")