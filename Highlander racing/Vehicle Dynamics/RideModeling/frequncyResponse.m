clc;
clear ;
close all;
figs = zeros(10,1);
figs(1) = 1;
figs(2) = 1;
figs(3) = 1;
figs(4) = 1;



m1 = 10;
m2 = 5;
m3 = 4;
m4 = 6;
m5 = 7;
m6 = 4;
m7 = 8;
m8 = 3;

k1 = 13000;
k2 = 16000;
k3 = 15000;
k4 = 11000;
k5 = 18000;
k6 = 12000;
k7 = 14000;
k8 = 19000;
k9 = 17000;
k10= 20000;

% freq rabge

w = 0:0.1:150;

M = diag([m1,m2,m3,m4,m5,m6,m7,m8]);
K = [k1+k2+k3 -k1 0 0 0 -k6 -k8 0;
    -k1 k1+k2 -k2 0 0 0 0 0;
     0 -k2 k2+k3 -k3 0 0 0 0;
     0 0 -k3 k3+k4+k7+k10 -k4 0 -k7 -k10;
     0 0 0 -k4 k4+k5 -k5 0 0;
     -k6 0 0 0 -k5 k5+k6+k9 -k9 0;
     -k8 0 0 -k7 0 -k9 k7+k8+k9 0;
     0 0 0 -k10 0 0 0 k10];

clearvars k1 k2 k3 k4 k5 k6 k7 k8 k9 k10 m1 m2 m3 m4 m5 m6 m7 m8


[H,wn] = calculateFRF(M,K,w,"N");


H11 = squeeze(H(1,1,:));

if figs(1)

    figure(1)
    semilogy(w,abs((H11)),linewidth=2)
    title('H11')
end



% frf knowns with foricing at m1 and m2;
H11 = H(1,1,:);
H12 = H(1,2,:);
H21 = H(2,1,:);
H22 = H(2,2,:);
H31 = H(3,1,:);
H32 = H(3,2,:);
H41 = H(4,1,:);
H42 = H(4,2,:);
H51 = H(5,1,:);
H52 = H(5,2,:);
H61 = H(6,1,:);
H62 = H(6,2,:);
H71 = H(7,1,:);
H72 = H(7,2,:);
H81 = H(8,1,:);
H82 = H(8,2,:);

Hk = [H21 H22;
      H31 H32];

Hu = [H11 H12;
      H71 H72;
      H81 H82];

for i = 1:length(w)
T(:,:,i) = Hu(:,:,i) / Hk(:,:,i);
end

f1 = [1;0];
f2 = [0;1];


for i=1:length(w)
xu1(:,:,i) = Hu(:,:,i)*f1;
xu2(:,:,i) = Hu(:,:,i)*f2;

xk1(:,:,i) = Hk(:,:,i)*f1;
xk2(:,:,i) = Hk(:,:,i)*f2;
end
xu = [xu1 xu2];
xk = [xk1 xk2];




