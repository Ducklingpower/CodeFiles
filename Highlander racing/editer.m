clear,
clc,
close all

load("C:\HR\HR24E\24E-VD\TTC Data\MAT Files\Round 9 Cornering\RunData_Cornering_Matlab_SI_Round9\B2356run5.mat")

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%                  Notes:
%%%                         
%%%                         make better graphs
%%%                         turn into function
%%%                         clean up code
                            
                            

%%%%%%%%%%%%%%%%%%%%%%%%%%%%






mechTrail = 0.005;  %meters
scrubR = 0.0254;      %meters
SteeringRT = 0.01905;  %meters
pnumatic = 0.021428; %meters
pitManT = 0.100;  %meters
%%tt=-t;
Mz2 = FY.*pnumatic;
M_kingPinAxis = (FY.*(mechTrail))+(Mz2); %N-M
force_arm = M_kingPinAxis/pitManT;
torque = force_arm*SteeringRT;
torqueraw=force_arm;
ogtorqueraw = torqueraw;
xtorqueraw=torqueraw;


counter = 0;
A=zeros(1000,1);
xx1= zeros(length(torqueraw),1);
xx2= zeros(length(torqueraw),1);
xx3= zeros(length(torqueraw),1);
xx4= zeros(length(torqueraw),1);
xx5= zeros(length(torqueraw),1);
xx6= zeros(length(torqueraw),1);
xx7= zeros(length(torqueraw),1);
xx8= zeros(length(torqueraw),1);
xx9= zeros(length(torqueraw),1);
xx10= zeros(length(torqueraw),1);
xx11= zeros(length(torqueraw),1);
xx12= zeros(length(torqueraw),1);
xx13= zeros(length(torqueraw),1);
xx14= zeros(length(torqueraw),1);
xx15= zeros(length(torqueraw),1);
xx16= zeros(length(torqueraw),1);


xxx = zeros(length(torqueraw),100);%this will hold data for each graph
xxn = zeros(length(torqueraw),100);

n1=0;
tester=0;
cc=3;
counter_top=0;
counter_bottem=0;
final_check_counter=0;
for i = 1:100

 final_check_counter=final_check_counter+1;
  
  
  n1= max(torqueraw);
  position = find(torqueraw==n1);
if n1==0
    n1 = min(torqueraw);
    position = find(torqueraw==n1);
    if n1 ==0
        break
    else 
    end
else
end
            for j = 0:length(torqueraw)-position                  %%iterate backwards
               
 
               if position-j-13<=0
               break
               else
               y1 = torqueraw(position-j);
               y2 = torqueraw(position-j-1); 
               y3 = torqueraw(position-j-2);
               y4 = torqueraw(position-j-3);
               y5 = torqueraw(position-j-4);
               y6 = torqueraw(position-j-5);
               y7 = torqueraw(position-j-7);
               y8 = torqueraw(position-j-8); 
               y9 = torqueraw(position-j-9);
               y10 = torqueraw(position-j-10);
               y11 = torqueraw(position-j-11);
               y12 = torqueraw(position-j-12);
               y13 = torqueraw(position-j-13);

               counter_top = counter_top+1;
               end
            dy1 = abs(y1-y2);
            dy2 = abs(y2-y3);
            dy3 = abs(y3-y4);
            dy4= abs(y4-y5);
            dy5= abs(y5-y6);
            dy6= abs(y6-y7);
            dy7= abs(y7-y8);
            dy8= abs(y8-y9);
            dy9= abs(y9-y10);
            dy10= abs(y10-y11);
            dy11= abs(y11-y12);
            dy12= abs(y12-y13);
          

            dyc1= abs(dy1-dy2);
             dyc2= abs(dy2-dy3);
             dyc3= abs(dy3-dy4);
             dyc4= abs(dy4-dy5);
             dyc5= abs(dy5-dy6);
             dyc6= abs(dy6-dy7);
             dyc7= abs(dy7-dy8);
             dyc8= abs(dy8-dy9);
             dyc9= abs(dy9-dy10);
             dyc10= abs(dy10-dy11);
             dyc11= abs(dy11-dy12);

             dycAvg1=(dyc3+dyc4+dyc5)/(3);
            dycAvg2=(dyc6+dyc7+dyc8)/(3);
            dycAvg3=(dyc9+dyc10+dyc11)/(3);
            dycAvg4=(dycAvg1+dycAvg2+dycAvg3)/(3);
            dyAvg1= (dy1+dy2+dy3+dy4)/4;
            dyAvg2= (dy5+dy6+dy7+dy8)/4;
            dyAvg3= (dy9+dy10+dy11+dy12)/4;
            dyAvg4 = (dyAvg1 + dyAvg2 + dyAvg3)/3;
           
               if dyAvg3> 1.7*dyAvg1
                    if dyAvg3 >1.7*dyAvg2
                            dyAvgtest = (dy8+dy9+dy10+dy11)/4;

                        if dyAvg3>dyAvgtest*2
                             dymatrix=[dy1;dy2;dy3;dy4;dy5;dy6;dy7;dy8;dy9;dy10];
                             counter = 0;
                            for l = 1:10                              
                                if dy12>dymatrix(l)
                                        counter=counter+1;
                                else
                                end

                            end
                            if   counter==10
                                if dycAvg3>dycAvg1
                                    if dycAvg3>dycAvg2
                                        dycAvgtest = (dyc10+dyc9+dyc8)/(3);
                                        if dycAvg3>dycAvgtest
                                            tester=0;
                                            cc=3;
                                        break
                                        else
                                        end
                                    else
                                    end


                                else
                                end
                           % break
                            else
                            end
                 
                        else
                        end

                    else
                    end
              
               else
                  


                             maxpoint = position;
                             if tester ==0
                                if y13<=-1
                                tester =1;
                              positionZero1 = position-j;
                                else
                                end 
                             else
                             end
                            if tester ==1
                                if y13>=-1
                                tester =2;
                                  positionZero2 = position-j;
                                else
                                end 
                             else
                             end
                            
                            if tester==2
                            boundUp = n1+1;
                            boundDown = n1-1;
                            positionZero = abs(positionZero1-positionZero2);
                            if cc == 3
                            n2= min(xxx(:,i));
                            cc=cc+1;
                            else
                            end
                              
                               if (boundDown<=abs(n2)) && (abs(n2)<=boundUp)
                               else 
                               for k=1:2
                            
                                xxx(k,i) = 0;
                               end
                               tester=0;
                               cc=3;
                               break
                               end
                            
                            else 
                            end


               end



        






          if i ==1
               xx1(position-j)= torqueraw(position-j); 
                
          elseif i==2
               xx2(position-j)= torqueraw(position-j);
          elseif i==3
               xx3(position-j)= torqueraw(position-j);
          elseif i==4
               xx4(position-j)= torqueraw(position-j);
          elseif i==5
               xx5(position-j)= torqueraw(position-j);
          elseif i==6
               xx6(position-j)= torqueraw(position-j);
          elseif i==7
               xx7(position-j)= torqueraw(position-j);
          elseif i==8
               xx8(position-j)= torqueraw(position-j);
          elseif i==9
               xx9(position-j)= torqueraw(position-j);
          elseif i==10
               xx10(position-j)= torqueraw(position-j);
          elseif i==11
               xx11(position-j)= torqueraw(position-j);
          elseif i==12
               xx12(position-j)= torqueraw(position-j);
          elseif i==13
               xx13(position-j)= torqueraw(position-j);
          elseif i==14
               xx14(position-j)= torqueraw(position-j);
          elseif i==15
               xx15(position-j)= torqueraw(position-j);
          elseif i==16
               xx16(position-j)= torqueraw(position-j);
          else
              
          end
 xxx(position-j,i) = torqueraw(position-j);
                         
            end



counter=0;

             for j = 0:length(torqueraw)-position 
                    
                 if position+j+13>=length(torqueraw)
                 break
                 else
                   
                 y1 = torqueraw(position+j);
                 y2 = torqueraw(position+j+1); 
                 y3 = torqueraw(position+j+2);
                 y4 = torqueraw(position+j+3);
                 y5 = torqueraw(position+j+4);
                 y6 = torqueraw(position+j+5);
                 y7 = torqueraw(position+j+7);
                 y8 = torqueraw(position+j+8); 
                 y9 = torqueraw(position+j+9);
                 y10 = torqueraw(position+j+10);
                 y11 = torqueraw(position+j+11);
                 y12 = torqueraw(position+j+12);
                 y13 = torqueraw(position+j+13);

                 counter_bottem = counter_bottem+1;
                 end

             dy1 = abs(y1-y2);
             dy2 = abs(y2-y3);
             dy3 = abs(y3-y4);
             dy4= abs(y4-y5);
             dy5= abs(y5-y6);
             dy6= abs(y6-y7);
             dy7= abs(y7-y8);
             dy8= abs(y8-y9);
             dy9= abs(y9-y10);
             dy10= abs(y10-y11);
             dy11= abs(y11-y12);
             dy12= abs(y12-y13);
                
             dyc1= abs(dy1-dy2);
             dyc2= abs(dy2-dy3);
             dyc3= abs(dy3-dy4);
             dyc4= abs(dy4-dy5);
             dyc5= abs(dy5-dy6);
             dyc6= abs(dy6-dy7);
             dyc7= abs(dy7-dy8);
             dyc8= abs(dy8-dy9);
             dyc9= abs(dy9-dy10);
             dyc10= abs(dy10-dy11);
             dyc11= abs(dy11-dy12);
                
            dycAvg1=(dyc3+dyc4+dyc5)/(3);
            dycAvg2=(dyc6+dyc7+dyc8)/(3);
            dycAvg3=(dyc9+dyc10+dyc11)/(3);
            dycAvg4=(dycAvg1+dycAvg2+dycAvg3)/(3);
            dyAvg1= (dy1+dy2+dy3+dy4)/4;
            dyAvg2= (dy5+dy6+dy7+dy8)/4;
            dyAvg3= (dy9+dy10+dy11+dy12)/4;
            dyAvg4 = (dyAvg1 + dyAvg2 + dyAvg3)/3;






                if dyAvg3> 1.7*dyAvg1
                    if dyAvg3 >1.7*dyAvg2
                            dyAvgtest = (dy8+dy9+dy10+dy11)/4;

                        if dyAvg3>dyAvgtest*2%possibly to much 
                             dymatrix=[dy1;dy2;dy3;dy4;dy5;dy6;dy7;dy8;dy9;dy10];
                             counter = 0;
                            for l = 1:10                      
                                if dy12>dymatrix(l)
                                        counter=counter+1;
                                else
                                end

                            end
                            if   counter==10
                                if dycAvg3>dycAvg1
                                    if dycAvg3>dycAvg2
                                        dycAvgtest = (dyc10+dyc9+dyc8)/(3);
                                        if dycAvg3>dycAvgtest
                                            tester=0;
                                            cc=3;
                                        break
                                       
                                        else
                                        end
                                    else
                                    end


                                else
                                end
                         
                            else
                            end
                 
                        else
                        end

                    else
                    end
              
                else




                             maxpoint = position;
                             if tester ==0
                                if y13<=-1
                                tester =1;
                                positionZero1 = position+j;
                                else
                                end 
                             else
                             end
                            if tester ==1
                                if y13>=-1
                                tester =2;
                                positionZero2 = position+j;
                                else
                                end 
                             else
                             end
                            
                            if tester==2
                            boundUp = n1+1;
                            boundDown = n1-1;
                            positionZero = abs(positionZero2-positionZero1);
                            if cc == 3
                            n2= min(xxx(:,i));
                            cc=cc+1;
                            else
                            end
                              
                            
                               if (boundDown<=abs(n2)) && (abs(n2)<=boundUp)
                               else 
                               for  k=position+j:position+j-positionZero
                            
                                xxx(k,i) = 0;
                               end
                               tester=0;
                               cc=3;
                               break
                               end
                            
                            else 
                            end





                end

          if i ==1
               xx1(position+j)= torqueraw(position+j);  
              
          elseif i==2
               xx2(position+j)= torqueraw(position+j);
          elseif i==3
               xx3(position+j)= torqueraw(position+j);
          elseif i==4
               xx4(position+j)= torqueraw(position+j);
          elseif i==5
               xx5(position+j)= torqueraw(position+j);
          elseif i==6
               xx6(position+j)= torqueraw(position+j);
          elseif i==7
               xx7(position+j)= torqueraw(position+j);
          elseif i==8
               xx8(position+j)= torqueraw(position+j);
          elseif i==9
               xx9(position+j)= torqueraw(position+j);
          elseif i==10
               xx10(position+j)= torqueraw(position+j);
          elseif i==11
               xx11(position+j)= torqueraw(position+j);
          elseif i==12
               xx12(position+j)= torqueraw(position+j);
          elseif i==13
               xx13(position+j)= torqueraw(position+j);
          elseif i==14
               xx14(position+j)= torqueraw(position+j);
          elseif i==15
               xx15(position+j)= torqueraw(position+j);
          elseif i==16
               xx16(position+j)= torqueraw(position+j);
          else
         
          end
  xxx(position+j,i) = torqueraw(position+j);%% filling in matrix xxx with values




             end

   %%this area is new
        for m = position-counter_top:position
        
        torqueraw(m,1) = 0;
        
        end

        for m = position:position+counter_bottem
        torqueraw(m,1) = 0;
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% 
%          if i ==1     
%               
%                  xxp=xx1;
%                  torqueraw=torqueraw-xx1;              
%              
%          elseif i==2
%          
%                    xxp2=xx2;
%                  torqueraw=torqueraw-xxp2;               
%               
%            elseif i==3
%               
%              
%                    xxp3=xx3;
%                  torqueraw=torqueraw-xxp3;               
%              
% 
%              elseif i==4
%               
%              
%                    xxp4=xx4;
%                  torqueraw=torqueraw-xxp4;               
%              
%              elseif i==5
%               
%             
%                    xxp5=xx5;
%                  torqueraw=torqueraw-xxp5;               
%                
%              elseif i==6
%               
%               
%                    xxp6=xx6;
%                  torqueraw=torqueraw-xxp6;               
%              
% 
%              elseif i==7
%               
%              
%                    xxp7=xx7;
%                  torqueraw=torqueraw-xxp7;               
%              
% 
%              elseif i==8
%               
%                    xxp8=xx8;
%                  torqueraw=torqueraw-xxp8;               
%               
% 
%                elseif i==9
%               
%               
%                    xxp9=xx9;
%                  torqueraw=torqueraw-xxp9;               
%               
% 
%                elseif i==10
%               
%           
%                    xxp10=xx10;
%                  torqueraw=torqueraw-xxp10;               
%                 
%                elseif i==11
%               
%             
%                    xxp11=xx11;
%                  torqueraw=torqueraw-xxp11;               
%               
% 
%                elseif i==12
%               
%               
%                    xxp12=xx12;
%                  torqueraw=torqueraw-xxp12;               
%             
% 
%                elseif i==13
%               
%               
%                    xxp13=xx13;
%                  torqueraw=torqueraw-xxp13;               
%                
%                elseif i==14
%               
%                
%                    xxp14=xx14;
%                  torqueraw=torqueraw-xxp14;               
%                  
% 
%                elseif i==15
%                
%                    xxp15=xx15;
%                  torqueraw=torqueraw-xxp15;               
%                
%                elseif i==16
%               
%               
%                    xxp16=xx16;
%                  torqueraw=torqueraw-xxp16;               
%                 
%           else
%           end

          



           
            n1=0;
            counter_bottem=0;
            counter_top=0;
  
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%final check 

for k =1:100%%length(xxx(1,:))

matrixtop = zeros(length(xxx),1);
matrixmid = zeros(length(xxx),1);
matrixbottem = zeros(length(xxx),1);
matrixtop_up = zeros(length(xxx),1);
matrixmid_up = zeros(length(xxx),1);
matrixbottem_up = zeros(length(xxx),1);
matrixtop_down = zeros(length(xxx),1);
matrixmid_down = zeros(length(xxx),1);
matrixbottem_down = zeros(length(xxx),1);

iter_up = 1;
iter_down = 1;
zero_finder=0;

    for j = 0:length(xxx)
    maxpoint = max(xxx(:,k));
    start= find(xxx(:,k) == maxpoint);

if maxpoint==0
    maxpoint = min(xxx(:,k));
    start= find(xxx(:,k) == maxpoint);
    if n1 ==0
        break
    else 
    end
else
end


  
       if start-j <=1
          start_down =1;
          number_down = 0;
          maxpoint = max(xxx(:,k));
          start= find(xxx(:,k) == maxpoint);
          start_up = start+j;
          number_up = xxx(start_up,k);%%i changed this last
          itter_down =0;
       elseif start+j >= length(xxx)-1
           start_up=1;
           number_up=0;
           maxpoint = max(xxx(:,k));
           start= find(xxx(:,k) == maxpoint);
           start_down =start-j;
           number_down = xxx(start_down,k);
           iter_up=0;

       else
    maxpoint = max(xxx(:,k));
    start= find(xxx(:,k) == maxpoint);
    start_up = start+j;
    start_down =start-j;
    number_up = xxx(start_up,k);
    number_down = xxx(start_down,k);

       end


    
    if number_up ==0 && number_down ==0
        zero_finder = zero_finder+1;
    if zero_finder == 10
     break
    else
    end
    else
    end

   
   
            if number_up <=0
                iter_up=2;
            else 
            end

            if iter_up ==2 && number_up>=0
                iter_up =3;
            else
            end

            
            if iter_up ==1 
                matrixtop(start_up,1) = number_up;
                matrixtop_up(start_up,1) = number_up;
            elseif iter_up ==2
                matrixmid(start_up,1) = number_up;
                matrixmid_up(start_up,1) = number_up;
            elseif iter_up == 3
                matrixbottem(start_up,1) = number_up;
                matrixbottem_up(start_up,1) = number_up;
            else
            end 



             if number_down <=0
                iter_down=2;
            else 
            end

            if iter_down ==2 && number_down>=0
                iter_down =3;
            else
            end

            
            if iter_down ==1 
                matrixtop(start_down,1) = number_down;
                matrixtop_down(start_down,1) = number_down;
            elseif iter_down ==2
                matrixmid(start_down,1) = number_down;
                matrixmid_down(start_down,1) = number_down;
            elseif iter_down == 3
                matrixbottem(start_down,1) = number_down;
                matrixbottem_down(start_down,1) = number_down;
            elseif iter_down ==0
            end 

    


    end

    






    maxnumbertop = max(matrixtop);
    maxnumbertop_up = max(matrixtop_up);
    maxnumbertop_down = max(matrixtop_down);

    minnumbermid = min(matrixmid);
    minnumbermid_up = min(matrixmid_up);
    minnumbermid_down = min(matrixmid_down);

    maxnumberbottem = max(matrixbottem);
    maxnumberbottem_up = max(matrixbottem_up);
    maxnumberbottem_down = max(matrixbottem_down);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%new
constant = maxnumbertop*0.08;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%







    maxnumbertop_errorhigh = maxnumbertop+constant;
    maxnumbertop_errorlow = maxnumbertop-constant;
    maxnumbertop_up_errorhigh = maxnumbertop_up+constant;
    maxnumbertop_up_errorlow = maxnumbertop_up-constant;
    maxnumbertop_down_errorhigh = maxnumbertop_down+constant;
    maxnumbertop_down_errorlow = maxnumbertop_down-constant;

    minnumbermid_errorhigh = minnumbermid+constant;
    minnumbermid_errorlow = minnumbermid-constant;
    minnumbermid_up_errorhigh = minnumbermid_up+constant;
    minnumbermid_up_errorlow = minnumbermid_up-constant;
    minnumbermid_down_errorhigh = minnumbermid_down+constant;
    minnumbermid_down_errorlow = minnumbermid_down-constant;
    
  

    if abs(minnumbermid_down_errorhigh)<=abs(maxnumbertop) && abs(maxnumbertop)<=abs(minnumbermid_down_errorlow)
    else
        matrixmid_down = zeros(length(xxx),1);
    end

    if abs(minnumbermid_up_errorhigh)<=abs(maxnumbertop) && abs(maxnumbertop)<=abs(minnumbermid_up_errorlow)
    else
        matrixmid_up = zeros(length(xxx),1);
    end
    matrixmid=matrixmid_up+matrixmid_down;

    if maxnumbertop_errorlow<=abs(min(matrixmid)) && abs(min(matrixmid))<=maxnumbertop_errorhigh
        
       if minnumbermid_errorlow<=abs(max(matrixbottem)) && abs(max(matrixbottem))<=minnumbermid_errorhigh
        matrixsum = matrixtop+matrixmid+matrixbottem;
       else
         matrixsum = matrixtop+matrixmid;
       
       end

    else 

        matrixsum = xxx(:,k);

    end
  
xxx(:,k) = matrixsum;







 end 
%%%%%%%%%%%%%%%%%%%%%final final check 
xxx_reject = zeros(length(torqueraw),100);
zero_matrix =zeros(length(torqueraw),100);
first_lines = round(final_check_counter/10);
total_distance = 0;
for p = 1:first_lines
    
    distance = length(nonzeros(xxx(:,p)));
    total_distance = distance+total_distance;
    
end
avg_distance = total_distance/first_lines;

for i =1:final_check_counter

   distance = length(nonzeros(xxx(:,i)));
      
   if distance<avg_distance*.6
     
    xxx_reject(:,i) = xxx(:,i);
      xxx(:,i) = zero_matrix(:,i);
   else
   end


end




figure(10)
plot(SA,torque,':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

plott = zeros(length(torqueraw),100);
for i=1:100
for j = 1:length(torqueraw)
plott(j,i) = i;
end 
end

figure(5)
tiledlayout(5,5)
for i=1:25
nexttile
plot(SA,xxx_reject(:,i),'color',rand(1,3),'Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
end

figure(7)

for i=1:100

plot(SA,xxx_reject(:,i),'color',rand(1,3),'Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on
end
%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(6)
plot(SA,xtorqueraw,'color','black','Marker','.','LineStyle',':')
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on
for i=1:100
    
plot(SA,xxx(:,i),'color',rand(1,3),'Marker','.','LineStyle',':')
hold on



end






figure(1)
tiledlayout(4,4)
nexttile
plot(SA,xxx(:,1),'Color','#01796f','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')


nexttile
plot(SA,xxx(:,2),'Color','#ff4c78','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')


nexttile
plot(SA,xxx(:,3),'Color','#7E2F8E','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')


nexttile
plot(SA,xxx(:,4),'Color','#77AC30','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')


nexttile
plot(SA,xxx(:,5),'Color','#D95319','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,6),'Color','black','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')


nexttile
plot(SA,xxx(:,7),'Color','#FF9004','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,8),'Color','#EDB120','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,9),'Color','#00AB75','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,10),'Color','#AB00A5','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,11),'Color','#63B9FF','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,12),'Color','#FF8C63','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,13),'Color','#91008B','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,14),'Color','#5AD001','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,15),'Color','#D001D0','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

nexttile
plot(SA,xxx(:,16),'Color','#B985FF','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(2)
plot3(SA,xxx(:,1),plott(:,1),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on 

plot3(SA,xxx(:,2),plott(:,2),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on 

plot3(SA,xxx(:,3),plott(:,3),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on 

plot3(SA,xxx(:,4),plott(:,4),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on 

plot3(SA,xxx(:,5),plott(:,5),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on 

plot3(SA,xxx(:,6),plott(:,6),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on 

plot3(SA,xxx(:,7),plott(:,7),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on 

plot3(SA,xxx(:,8),plott(:,8),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on 

plot3(SA,xxx(:,9),plott(:,9),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on 

plot3(SA,xxx(:,10),plott(:,10),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on 

plot3(SA,xxx(:,11),plott(:,11),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on
plot3(SA,xxx(:,12),plott(:,12),'.:')
grid on 

title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on

plot3(SA,xxx(:,13),plott(:,13),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on
plot3(SA,xxx(:,14),plott(:,14),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on

plot3(SA,xxx(:,15),plott(:,15),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on

plot3(SA,xxx(:,16),plott(:,16),'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
hold on


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
figure(3)
plot(SA,torqueraw,'.:')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on 




plot(SA,xxp2,'Color','#ff4c78','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on 

plot(SA,xxp3,'Color','#7E2F8E','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on 

plot(SA,xxp4,'Color','#77AC30','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on 

plot(SA,xxp5,'Color','#D95319','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on 

plot(SA,xxp6,'Color','black','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on 

plot(SA,xxp7,'Color','#4DBEEE','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on 

plot(SA,xxp8,'Color','#EDB120','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on

plot(SA,xxp9,'Color','#00AB75','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on

plot(SA,xxp10,'Color','#AB00A5','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on

plot(SA,xxp11,'Color','#63B9FF','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')

hold on

plot(SA,xxp12,'Color','#FF8C63','Marker','.','LineStyle',':')
grid on 
title('SA-torque')
xlabel('slip angle')
ylabel('steering torque')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%