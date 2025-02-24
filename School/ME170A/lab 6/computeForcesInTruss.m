function f=computeForcesInTruss(loads)
a=(sqrt(2))/2;
A=[
0 -1 0 0 0 1 0 0 0 0 0 0 0;
0 0 1 0 0 0 0 0 0 0 0 0 0;
-a 0 0 1 a 0 0 0 0 0 0 0 0;
-a 0 -1 0 -a 0 0 0 0 0 0 0 0;
0 0 0 -1 0 0 0 1 0 0 0 0 0;
0 0 0 0 0 0 1 0 0 0 0 0 0;
0 0 0 0 -a -1 0 0 a 1 0 0 0;
0 0 0 0 a 0 1 0 a 0 0 0 0;
0 0 0 0 0 0 0 0 0 -1 0 0 1;
0 0 0 0 0 0 0 0 0 0 1 0 0;
0 0 0 0 0 0 0 -1 -a 0 0 a 0;
0 0 0 0 0 0 0 0 -a 0 -1 -a 0;
0 0 0 0 0 0 0 0 0 0 0 -a -1];

p2 = loads(1,1);
p5=loads(1,2);
p6=loads(1,3);
b=[0; p2; 0 ;0;0;0;0;p5;0;p6;0;0;0];


R=1;
Z=eye(13);
%finding P
for i=1:13
    [Max,R]=max(abs(A(i:13,i)));
    %this Locates max number and row it is in
    row=A(i,:);%replaing rows;
    zow=Z(i,:);
    
    A(i,:)=A(R-1+i,:);%replacing row to top
    Z(i,:)=Z(R-1+i,:);
    Z(R+i-1,:)=zow;
    A(R+i-1,:)=row;%Now we set row to new row
end

    LU=A;


[L, U]=gaussianElimination(LU);
Y=forwardSubstitution(L,b,Z);
f=backSubstitution(U,Y);







