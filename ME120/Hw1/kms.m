m1 = 1;
m2 = 2;
k2 = 2;
k1 = 2;
b = 1;
A = zeros(2010,4);
n=0;
A3 = zeros(1,2010);
for k3 = -100:0.1:100
B = [0 1 0 0; (-k1 - k3)/m1, -b/m1, k3/m1, b/m1; 0 0 0 1; k3/m2, b/m2, (-k2-k3)/m2, -b/m2];
counter = 0;
n=n+1;
EIGEN = eig(B);
A(n,1)=EIGEN(1);
A(n,2)=EIGEN(2);
A(n,3)=EIGEN(3);
A(n,4)=EIGEN(4);
A3(1,n) = k3;
if EIGEN(1) <=0
    counter = counter +1;
end
if EIGEN(2) <=0 
    counter = counter +1;    
end
if EIGEN(3) <=0
    counter = counter +1;
end
if EIGEN(4) <=0
    counter = counter +1;
end
if counter == 4
    counter2=0;
    if EIGEN(1) ==0
    counter2 = counter2 +1;
    end
    if EIGEN(2) ==0 
    counter2 = counter2 +1;
    end
    if EIGEN(3) ==0
    counter2 = counter2 +1;
    end
    if EIGEN(4) ==0
    counter2 = counter2 +1;
    end
if counter2>=1
    break
end
else
end
end 
figure
grid on
plot(real(A),imag(A),":");
figure 
plot(1:2010,real(A(:,3)),":");
grid on
figure(10)
grid on
plot(A3,real(A(:,1)),"o")
grid on
hold on
plot(A3,real(A(:,2)),"o")
grid on
hold on 
plot(A3,real(A(:,3)),"o")
grid on
hold on
plot(A3,real(A(:,4)),"o")
hold on 
grid on


figure(11)
grid on
plot(A3,imag(A(:,1)),"o")
grid on
hold on
plot(A3,imag(A(:,2)),"o")
grid on
hold on 
plot(A3,imag(A(:,3)),"o")
grid on
hold on
plot(A3,imag(A(:,4)),"o")
hold on 
grid on

