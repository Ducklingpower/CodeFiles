
tiledlayout(2,1);
coefs = [1 0 -1j 0 1 ];
roots1 = roots(coefs);
nexttile
scatter(real(roots1),imag(roots1),'filled');
xlabel('real numbers')
ylabel('Imagninary numbers')


nexttile
coefs2 = [1 -1 0 2 -1 -1 0 1 1];
roots2 = roots(coefs2);
scatter(real(roots2),imag(roots2),"red","filled");
xlabel('real numbers')
ylabel('Imagninary numbers')





