t= readtable('grades.xlsx');
varableNames=t.Properties.VariableNames;
data=t{:,:};%going through all rowsa and all colums turning into matrix

maxPoints=data(1,:);%first row contains the maximum points avalible
data=data(2:end,:);

meanData=mean(data);
stdData=std(data);
medinadata=median(data);
varData=var(data);

final=data(:,1);
midterm=data(:,2)
total=data(:,end);
plot(final,total,'ro')


quiz=data(:,3:end-4);

totquiz=sum(quiz');
totquiz=totquiz';
allscorse= [totquiz midterm final total];
C=corrcoef(allscorse);
c=corrcoef(final,total);%corilation between final amd total

x10percent=prctile(data,[10]);


histagram=his(data(:,end));%histagram
bplot=boxplot(data(:,end));%boxplot