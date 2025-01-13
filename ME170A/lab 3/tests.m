
x=.75;
terms=10;
y=0;
for i=1:terms
    y=y+(((x+i)/i)^i);
end
A=y