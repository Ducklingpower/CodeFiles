clear all
close all
clc

f1 = @(x) 3*x^4;
f2 = @(x) x*cos(x);

D1 = deriv(f1,1,5,0.01,2);
D2 = deriv(f2,pi/6,3,0.001,2);

taylor = taylorCoefficients(f2,pi/6,3,0.001);

I1 = trapezoid(f1,[0 1],100);
I2 = trapezoid(f2,[0 pi],100);

[x1,I1c] = cumulativeTrapezoid(f1,[0 1],100);
[x2,I2c] = cumulativeTrapezoid(f2,[0 pi],100);

t1 = timeToDrain(1,3,5e-2,1,0,0.9,100);
t2 = timeToDrain(1,3,5e-2,1.5,0.75,0.9,100);
t3 = timeToDrain(1,3,5e-2,0,1,0.9,100);

y = [0 0.00025 0.00075 0.001 0.0015 0.00225 0.0025];
u = [0 0.1797 0.4922 0.625 0.8438 1.0547 1.0938];

tau = computeShearStress(y,u);

load Lab8_answers

errorD1 = abs(mean(D1_ans) - mean(D1))/mean(D1_ans)*100;
errorD2 = abs(mean(D2_ans) - mean(D2))/mean(D2_ans)*100;
errortaylor = abs(mean(taylor_ans) - mean(taylor))/mean(taylor_ans)*100;
errorI1 = abs(mean(I1_ans) - mean(I1))/mean(I1_ans)*100;
errorI2 = abs(mean(I2_ans) - mean(I2))/mean(I2_ans)*100;
errorx1 = abs(mean(x1_ans) - mean(x1))/mean(x1_ans)*100;
errorx2 = abs(mean(x2_ans) - mean(x2))/mean(x2_ans)*100;
errorI1c = abs(mean(I1c_ans) - mean(I1c))/mean(I1c_ans)*100;
errorI2c = abs(mean(I2c_ans) - mean(I2c))/mean(I2c_ans)*100;
errort1 = abs(t1_ans - t1)/t1_ans*100;
errort2 = abs(t2_ans - t2)/t2_ans*100;
errort3 = abs(t3_ans - t3)/t3_ans*100;
errortau = abs(tau_ans - tau)/tau_ans*100;

fprintf('Deriv 1 Error: %0.2f percent\n',abs(errorD1))
fprintf('Deriv 2 Error: %0.2f percent\n',abs(errorD2))
fprintf('Taylor Coefficients Error: %0.2f percent\n',abs(errortaylor))
fprintf('Trapezoid 1 Error: %0.2f percent\n',abs(errorI1))
fprintf('Trapezoid 2 Error: %0.2f percent\n',abs(errorI2))
fprintf('Cumulative Trapezoid 1 Error (x1): %0.2f percent\n',abs(errorx1))
fprintf('Cumulative Trapezoid 1 Error (I1): %0.2f percent\n',abs(errorI1c))
fprintf('Cumulative Trapezoid 2 Error (x2): %0.2f percent\n',abs(errorx2))
fprintf('Cumulative Trapezoid 2 Error (I2): %0.2f percent\n',abs(errorI2c))
fprintf('Time To Drain 1 Error: %0.2f percent\n',abs(errort1))
fprintf('Time To Drain 2 Error: %0.2f percent\n',abs(errort2))
fprintf('Time To Drain 3 Error: %0.2f percent\n',abs(errort3))
fprintf('Compute Shear Stress Error: %0.2f percent\n',abs(errortau))


