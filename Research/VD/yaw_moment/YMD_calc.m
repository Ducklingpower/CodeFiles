function outputStruct = YMDfunc(sim_parameters, vehicleParams)
%% func params

% sim parameters ----------------------------------------------------------
delta_angle_deg = -sim_parameters.deltaMax:sim_parameters.deltaResolution:sim_parameters.deltaMax; % sweep delta angles
deltas = deg2rad(delta_angle_deg);

beta_angle_deg = -sim_parameters.betaMax:sim_parameters.betaResolution:sim_parameters.betaMax; % sweep beta angles
betas = deg2rad(beta_angle_deg);

g = sim_parameters.gravity;
Vx = sim_parameters.Vx;
Air_Density = sim_parameters.airDensity;

% Vehicle params to varibles ----------------------------------------------

wheelbase = vehicleParams.wheelbase;        % wheelbase             (m)
w_dist_f = vehicleParams.w_dist_f;          % mass dsitribution     (%/100)
t_f = vehicleParams.t_f;                    % front track width     (m)
t_r = vehicleParams.t_r;                    % rear track width      (m)
wheelRate_f = vehicleParams.wheelRate_f;    % Front wheel Rate      (N/m)
wheelRate_r = vehicleParams.wheelRate_r;    % rear wheel rate       (N/m)
ARB_f = vehicleParams.ARB_f;                % Front ARB stiffness   (rad/m)
cg_z = vehicleParams.cg_z;                  % cg height             (m)
rc_f = vehicleParams.rc_f;                  % roll center front     (m)
rc_r = vehicleParams.rc_r;                  % roll center rear      (m)
toe_f = deg2rad(vehicleParams.toe_f);       % toe front (- = out)   (rad)
toe_r = deg2rad(vehicleParams.toe_r);       % toe front (- = out)   (rad)
m = vehicleParams.m;                        % vehicle mass          (kg)
mech_trail_f = vehicleParams.mech_trail_f;  % mech trail front      (m)
mech_trail_r = vehicleParams.mech_trail_r;  % mech trail rear       (m)
frontalArea = vehicleParams.frontalArea;    % frontal area          (m^2)
Cd = vehicleParams.Cd;                      % drag coef             (-)
Cl = vehicleParams.Cl;                      % lift coef             (-)
aeroBalance = vehicleParams.aeroBalance;    % frontal aero load     (-)


% Calcuated Parameters ----------------------------------------------------

w = m*g;                                                      %Vehcile weight (N)
cg2rollAxis = cg_z -((1-w_dist_f)*(rc_r-rc_f) + rc_f);
l_a = (1 - w_dist_f) * wheelbase;                             % cg to front axle      (m)
l_b = wheelbase - l_a;                                        % cg to rear axle       (m)
k_phi_f = ((wheelRate_f *(t_f^2))/2) + (ARB_f); % roll stiffness front (Nm/rad)
k_phi_r = ((wheelRate_r *(t_r^2))/2) + (0); % roll stiffness rear (Nm/rad)
weightTransferGradient_f = (w/t_f) * ((cg2rollAxis * k_phi_f)/(k_phi_f + k_phi_r) + (l_b * rc_f/wheelbase));
weightTransferGradient_r = (w/t_r) * ((cg2rollAxis * k_phi_r)/(k_phi_f + k_phi_r) + (l_a * rc_r/wheelbase));
aeroLoad_F = Cl * Air_Density * ((Vx^2)/2) * frontalArea * aeroBalance;
aeroLoad_R = Cl * Air_Density * ((Vx^2)/2) * frontalArea * (1 - aeroBalance);


%% ackermann steering sweep

ackerman_sweep = xlsread("ackerman_sweep.xlsx");


%% variable initialization

progress = 0;
totalIts = length(deltas) * length(betas);
it_prog = 1/totalIts;
itNum = 0;

loopbar = waitbar(progress, 'starting');

maxLat = 0;

maxLat_pos = [0, 1000]; % [lat accel, yaw moment]
maxLat_neg = [0, -1000];
compareVal_pos = 0;
compareVal_neg = 0;
slope = 2500;
MzCap = -1100;


output_Ay(length(deltas), length(betas)) = 0;  % Only allocates last element
output_N(length(deltas), length(betas)) = 0;
iterations(length(deltas)*length(betas), 1) = 0;




%% main func loop 

for i = 1:length(deltas)
    for j = 1:length(betas)
        tic
        itNum = itNum + 1;

        % if deltas_deg(i) == -20 && betas_deg(j) == -11
        %     warning("L function, you not that guy")
        % end

        % Before the loop starts, initialize with a better guess:
        if i == 1 && j == 1
            Ay_it = 0;
        elseif j == 1
            % Using solution from previous delta at same beta
            Ay_it = output_Ay(i-1, j);
        else
            % Using solution from previous beta at same delta
            Ay_it = output_Ay(i, j-1);
        end

        if isnan(Ay_it)
            error("Ay_it is undefined " + alpha_fl + " "+ alpha_fr)
        end

        Fy_fr = 0;
        Fy_fl = 0;
        Fy_rr = 0;
        Fy_rl = 0;
        Mz_fr = 0;
        Mz_fl = 0;
        Mz_rr = 0;
        Mz_rl = 0;
        SA_sat = false;

        debug = 1;
        maxIter = 1000;
        resultsNum = zeros(maxIter);
        iterCount = 0;
        tolerance = 0.002;
        damp = 0.35;
        oscillation = 0;
        Ay_tolerance = 0;

        while iterCount <= maxIter
            iterCount = iterCount + 1;

            if isnan(Ay_it)
                error("Ay_it is undefined ")% + rad2deg(alpha_fl) + " " + rad2deg(alpha_fr))
            end

            % if deltas_deg(i) == -18 && betas_deg(j) == 1
            %     warning("fart")
            % end

            R = (Vx^2)/Ay_it; % radius of curvature, m
            r = Vx/R; % yaw rate, rad/s
            Vy = Vx * (betas(j) + (l_b/R)); % lateral velocity, m/s

            delta_r = interp1(ackerman_sweep(:, 1), ackerman_sweep(:, 3), rad2deg(deltas(i)));
            delta_l = interp1(ackerman_sweep(:, 1), ackerman_sweep(:, 2), rad2deg(deltas(i)));

            % delta_r = rad2deg(deltas(i));
            % delta_l = rad2deg(deltas(i));

            % zTorq_fr = (-(Fy_fr * mech_trail_f) + Mz_fr);
            % toeC_fr = -toe_comp_f * zTorq_fr;
            % 
            % zTorq_fl = (-(Fy_fl * mech_trail_f) + Mz_fl);
            % toeC_fl = -toe_comp_f * zTorq_fl;
            % 
            % zTorq_rr = (-(Fy_rr * mech_trail_r) + Mz_rr);
            % toeC_rr = -toe_comp_r * zTorq_rr;
            % 
            % zTorq_rl = (-(Fy_rl * mech_trail_r) + Mz_rl);
            % toeC_rl = -toe_comp_r * zTorq_rl;


            zTorq_fr = (-(Fy_fr * 0) + Mz_fr);
            toeC_fr = -0 * zTorq_fr;

            zTorq_fl = (-(Fy_fl * 0) + Mz_fl);
            toeC_fl = -0* zTorq_fl;

            zTorq_rr = (-(Fy_rr * 0) + Mz_rr);
            toeC_rr = -0* zTorq_rr;

            zTorq_rl = (-(Fy_rl * 0) + Mz_rl);
            toeC_rl = -0 * zTorq_rl;


            alpha_fr = ((Vy + (r * l_a)) / (Vx + r * (t_f/2))) - (deg2rad(delta_r) + toe_f - deg2rad(toeC_fr));
            fr_SAmod = deg2rad(delta_r) + toe_f - deg2rad(toeC_fr);
            alpha_fl = ((Vy + (r * l_a)) / (Vx - r * (t_f/2))) - (deg2rad(delta_l) - toe_f - deg2rad(toeC_fl));
            fl_SAmod = deg2rad(delta_l) - toe_f - deg2rad(toeC_fl);

            alpha_rr = ((Vy - (r * l_b)) / (Vx + r * (t_r/2))) - (toe_r - deg2rad(toeC_rr));
            rr_SAmod = toe_r - deg2rad(toeC_rr);
            alpha_rl = ((Vy - (r * l_b)) / (Vx - r * (t_r/2))) - (-toe_r - deg2rad(toeC_rl));
            rl_SAmod = -toe_r - deg2rad(toeC_rl);

            if alpha_fr > deg2rad(45) || alpha_fl > deg2rad(45) || alpha_rl > deg2rad(45) || alpha_rr > deg2rad(45)
                SA_sat = true;
            end

            weightTransfer_f = Ay_it/g * weightTransferGradient_f;
            weightTransfer_r = Ay_it/g * weightTransferGradient_r;

            Fz_fr = -(((w * w_dist_f)/2) + weightTransfer_f) + aeroLoad_F;
            Fz_fl = -(((w * w_dist_f)/2) - weightTransfer_f) + aeroLoad_F;

            Fz_rr = -(((w * (1-w_dist_f))/2) + weightTransfer_r) + aeroLoad_R;
            Fz_rl = -(((w * (1-w_dist_f))/2) - weightTransfer_r) + aeroLoad_R;

            if Fz_fr > 0
                Fz_fr = -0.001;
                Fz_fl = (-w * w_dist_f);
                warning("Front Right Unloaded")
            end

            if Fz_fl > 0
                Fz_fl = -0.001;
                Fz_fr = (-w * w_dist_f);
                warning("Front Left Unloaded")
            end

            if Fz_rr > 0
                Fz_rr = -0.001;
                Fz_rl = (-w * w_dist_f);
                warning("Rear Right Unloaded")
            end

            if Fz_rl > 0
                Fz_rl = -0.001;
                Fz_rr = (-w * w_dist_f);
                warning("Rear Left Unloaded")
            end

            %% Fy and Mz calculations

            % Fy

            
            Fy_fr = LateralTireModel(Fz_fr, rad2deg(alpha_fr));
            Fy_fl = LateralTireModel(Fz_fl, rad2deg(alpha_fl));

            Fy_rr = LateralTireModel(Fz_rr, rad2deg(alpha_rr));
            Fy_rl = LateralTireModel(Fz_rl, rad2deg(alpha_rl));


            netFy = (Fy_fr + Fy_fl + Fy_rr +Fy_rl);
            Ay_result = netFy / m;

            % Mz
            latFy_fl = Fy_fl * cos((deg2rad(delta_l) - toe_f + deg2rad(toeC_fl)));
            latFy_fr = Fy_fr * cos((deg2rad(delta_r) + toe_f + deg2rad(toeC_fr)));

            latFy_rl = Fy_rl * cos((-toe_r + deg2rad(toeC_rl)));
            latFy_rr = Fy_rr * cos((toe_r + deg2rad(toeC_rr)));

            lonFy_fl = Fy_fl * sin((deg2rad(delta_l) - toe_f + deg2rad(toeC_fl)));
            lonFy_fr = Fy_fr * sin((deg2rad(delta_r) + toe_f + deg2rad(toeC_fr)));

            lonFy_rl = Fy_rl * sin((-toe_r + deg2rad(toeC_rl)));
            lonFy_rr = Fy_rr * sin((toe_r + deg2rad(toeC_rr)));

            Fz_flb = Fz_fl;
            Fz_frb = Fz_fr;
            Fz_rlb = Fz_rl;
            Fz_rrb = Fz_rr;

            if abs(Fz_fl) > abs(MzCap)
                Fz_fl = MzCap;
            end

            if abs(Fz_fr) > abs(MzCap)
                Fz_fr = MzCap;
            end

            if abs(Fz_rl) > abs(MzCap)
                Fz_rl = MzCap;
            end

            if abs(Fz_rr) > abs(MzCap)
                Fz_rr = MzCap;
            end

            Mz_fl = AligningTireModel(Fz_fl, rad2deg(alpha_fl));
            Mz_fr = AligningTireModel(Fz_fr, rad2deg(alpha_fr));
            Mz_rl = AligningTireModel(Fz_rl, rad2deg(alpha_rl));
            Mz_rr = AligningTireModel(Fz_rr, rad2deg(alpha_rr));


            Fz_fl = Fz_flb;
            Fz_fr = Fz_frb;
            Fz_rl = Fz_rlb;
            Fz_rr = Fz_rrb;

            netMz = ((lonFy_fl * (t_f/2)) + (lonFy_rl * (t_r/2))) - ((lonFy_fr * (t_f/2)) + (lonFy_rr * (t_r/2)))...
                + ((latFy_fl + latFy_fr) * l_a - (latFy_rl + latFy_rr) * l_b)...
                + Mz_fr + Mz_fl + Mz_rr + Mz_rl;
          
            if (sign(Ay_tolerance) ~= sign(Ay_it - Ay_result)) && (iterCount > 1)
                oscillation = oscillation + 1;
            end

            Ay_tolerance = (Ay_it - Ay_result);
            iterCount;

            Ay_it;
            Ay_result;

            % if (iterCount > 900) && (abs(Ay_tolerance) < (100*tolerance))
            %     Ay_tolerance = tolerance;
            % end

            if abs(Ay_tolerance) <= tolerance || SA_sat % check if convergence is met

                output_Ay(i, j) = Ay_result; % rows: delta, col: beta
                output_N(i, j) = netMz; % rows: delta, col: beta

                iterations(itNum) = iterCount;
                %iterations(itNum) = Ay_result;
                             
                SSvals.alphaFL(i, j) = alpha_fl;
                SSvals.alphaFR(i, j) = alpha_fr;
                SSvals.alphaRL(i, j) = alpha_rl;
                SSvals.alphaRR(i, j) = alpha_rr;

                SSvals.FzFL(i, j) = Fz_fl;
                SSvals.FzFR(i, j) = Fz_fr;
                SSvals.FzRL(i, j) = Fz_rl;
                SSvals.FzRR(i, j) = Fz_rr;

                SSvals.MzFL(i, j) = Mz_fl;
                SSvals.MzFR(i, j) = Mz_fr;
                SSvals.MzRL(i, j) = Mz_rl;
                SSvals.MzRR(i, j) = Mz_rr;

                SSvals.zTorq_fl(i, j) = zTorq_fl;
                SSvals.zTorq_fr(i, j) = zTorq_fr;
                SSvals.zTorq_rl(i, j) = zTorq_rl;
                SSvals.zTorq_rr(i, j) = zTorq_rr;

                SSvals.FyFL(i, j) = Fy_fl;
                SSvals.FyFR(i, j) = Fy_fr;
                SSvals.FyRL(i, j) = Fy_rl;
                SSvals.FyRR(i, j) = Fy_rr;

                SSvals.FL_SAmod(i, j) = fl_SAmod;
                SSvals.FR_SAmod(i, j) = fr_SAmod;
                SSvals.RL_SAmod(i, j) = rl_SAmod;
                SSvals.RR_SAmod(i, j) = rr_SAmod;
                                           
                if Ay_result > maxLat
                    maxLat = Ay_result;
                    maxLatDeltaIndex = i;
                    maxLatBetaIndex = j;
                end

                progress = progress + it_prog;

                if mod(itNum, 40) == 0                   
                    prog_percent = round(((itNum/totalIts) * 100), 2);
                    waitbar(progress, loopbar, "YMD Loading... " + num2str(prog_percent) + "%")
                end

                break;
            else
                
                if iterCount == 1
                    % First iteration - use moderate damping
                    damp = 0.35;
                elseif oscillation > 100
                    % if oscillation < 350
                        % damp = ((-1.07e-4)*(oscillation - 65)) + 0.1;
                    % else
                    %     damp = 0%(oscillation - 348.741074588)^-10;
                    % end

                    % damp = 0.1;
                    %
                    % if oscillation > 300
                    %     damp = 0.025;
                    % end
                    %
                    % if oscillation > 500
                    %     damp = 0.005;
                    % end
                    damp = ((-0.0003)*(oscillation - 100)) + 0.1;
                else
                    % Adaptive damping based on convergence rate
                    error_ratio = abs(Ay_tolerance) / prev_error;
                    damp = min(0.9, max(0.1, 0.6*(1 + tanh(2*(0.5 - error_ratio)))));
                end
                prev_error = abs(Ay_tolerance);

                %damp = 0.1;

                resultsNum(debug, 1) = Ay_it;
                resultsNum(debug, 2) = Ay_result;
                resultsNum(debug, 3) = Ay_tolerance;
                resultsNum(debug, 7) = damp;
                resultsNum(debug, 8) = Fy_fl;
                resultsNum(debug, 9) = Fy_fr;
                resultsNum(debug, 10) = Fy_rl;
                resultsNum(debug, 11) = Fy_rr;
                % if iterCount == 1
                %     resultsNum(debug, 12) = 0;                    
                % else
                %     resultsNum(debug, 12) = error_ratio;
                % end
                % resultsNum(debug, 13) = prev_error;

                Ay_it = Ay_it - (damp * (Ay_it - Ay_result));

                debug = debug + 1;

                if debug == maxIter                   

                    hold on
                    grid on
                    plot(resultsNum(:, 1), 'red')
                    plot(resultsNum(:, 2), 'blue')
                    plot(resultsNum(:, 3), 'green')
                    plot(resultsNum(:, 4), 'yellow')
                    plot(resultsNum(:, 5), 'black')
                    plot(resultsNum(:, 7), 'magenta')
                    legend('Ay it', 'Ay result', "Ay tolerance", "it slope", "result slope")

                    figure
                    hold on
                    grid on
                    plot(resultsNum(:, 8), 'DisplayName', 'Fy_fl')
                    plot(resultsNum(:, 9), 'DisplayName', 'Fy_fr')
                    plot(resultsNum(:, 10), 'DisplayName', 'Fy_rl')
                    plot(resultsNum(:, 11), 'DisplayName', 'Fy_rr')
                    legend

                    figure
                    hold on
                    grid on
                    plot(resultsNum(:, 12), 'DisplayName', 'error_ratio')
                    plot(resultsNum(:, 13), 'DisplayName', 'prev_error')
                    legend

                    close(loopbar)
                    error("ERROR: Solution did not converge\n" + "delta: " + deltas_deg(i) + "\nbeta: " + betas_deg(j))
                    return
                end
            end
        end % converge loop end

        if iterCount == maxIter
            warning("Max iterations reached: No full convergence for delta=%.2f, beta=%.2f", rad2deg(deltas(i)), rad2deg(betas(j)));
        end
    end
end

close(loopbar)

end