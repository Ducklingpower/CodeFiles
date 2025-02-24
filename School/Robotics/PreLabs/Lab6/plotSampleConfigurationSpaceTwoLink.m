% Eric Perez
 % lab 6
 function plotSampleConfigurationSpaceTwoLink(L1, L2, W, xo, yo, r, sampling_method,n) 
 
 alpha1 = [];
 alpha2 = [];
 alpha3 = [];
 beta1  = [];
 beta2  = [];
 beta3 = [];

if strcmp(sampling_method, 'Sukharev') %Sukharev Graph
     figure(1);
      [Grid] = computeGridSukharev(n);
       suka1 = (Grid(:,1)*(2*pi)) - pi;
       suka2 = (Grid(:,2)*(2*pi)) - pi;
     [SukaN,~] = size(Grid);
     close(figure(1));
     for i = 1:SukaN
         alpha = suka1(i);
         beta = suka2(i);
         [TF,collison] = checkCollisionTwoLink(L1, L2, W, alpha, beta, xo, yo, r);
         if (TF == true) && (collison == 1)
             alpha1(end+1) = alpha;
             beta1(end+1) = beta;
         elseif (TF == true) && (collison == 2)
             alpha2(end+1) = alpha;
             beta2(end+1) = beta;
         else (TF == true) && (collison == 0)
             alpha3(end+1) = alpha;
             beta3(end+1) = beta;
         end
     end

    elseif strcmp(sampling_method, 'Random')
       [Grid] = computeGridRandom(n);
       Ran1 = (Grid(:,1)*(2*pi)) - pi;
       Ran2 = (Grid(:,2)*(2*pi)) - pi;
     [RanN,~] = size(Grid);
     for i = 1:RanN
         alpha = Ran1(i);
         beta = Ran2(i);
         figure(2)
         [TF,collison] = checkCollisionTwoLink(L1, L2, W, alpha, beta, xo, yo, r);
         if (TF == true) && (collison == 1)
             alpha1(end+1) = alpha;
             beta1(end+1) = beta;
         elseif (TF == true) && (collison == 2)
             alpha2(end+1) = alpha;
             beta2(end+1) = beta;
         else (TF == true) && (collison == 0)
             alpha3(end+1) = alpha;
             beta3(end+1) = beta;
         end
     end
 else strcmp(sampling_method, 'Halton') % Grid Halton
      [Grid] = computeGridHalton(n, 2, 3);
       Hal1 = (Grid(:,1)*(2*pi)) - pi;
       Hal2 = (Grid(:,2)*(2*pi)) - pi;
     [HalN,~] = size(Grid);
     for i = 1:HalN
         alpha = Hal1(i);
         beta = Hal2(i);
         figure(2)
         [TF,collison] = checkCollisionTwoLink(L1, L2, W, alpha, beta, xo, yo, r);
         if (TF == true) && (collison == 1)
             alpha1(end+1) = alpha;
             beta1(end+1) = beta;
         elseif (TF == true) && (collison == 2)
             alpha2(end+1) = alpha;
             beta2(end+1) = beta;
         else (TF == true) && (collison == 0)
             alpha3(end+1) = alpha;
             beta3(end+1) = beta;
         end
     end             
 end 
 close(figure(1));
 figure;
  hold on
 plot(alpha1,beta1, 'ko');
 plot(alpha2,beta2, 'ro');
 plot(alpha3,beta3,'bo');
 end