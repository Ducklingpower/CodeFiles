
bins=[1 2 3 4 5 6 7 8 9 10];
d=readtable('grades.xlsx');
data=d{:,:};
data=data(2:end,:);
data=data(:,end);
histo=zeros(length(bins)-1,1);
for i=1:length(bins)-1
    L=bins(i+1)-bins(i);
    h=data(i);

    histo(i)=L*h;
end