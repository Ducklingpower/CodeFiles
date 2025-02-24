function [H,wn] = calculateFRF(M,K,w,dampingType,zetaType,alpha,beta)

[phi, lambda] = eig(K,M);
wn =real(sqrt(diag(lambda)));

if contains(dampingType,"S")
    alpha = 0;
    beta = 0;
    zeta  = zetaType;
elseif contains(dampingType, "P")
    zeta = alpha*M + beta*K;
else 
    alpah = 0;
    beta = 0;
    zeta = zeros(1,length(wn));

end

% finding frf

for ll = 1:length(w)
    for kk = 1:length(wn)
        switch dampingType
            case "N"
                %Diagoal term of frf accel - no damping
                diags(kk,kk) = -w(ll)^2 / (wn(kk)^2 - w(ll)^2);
            case "S"
                % structural damping
                diags(kk,kk) = -w(ll)^2 / (wn(kk)^2 - w(ll)^2 + 1i*zeta(kk) * wn(kk)^2);
            case "P"
                % proportional damping
                 diags(kk,kk) = -w(ll)^2 / (wn(kk)^2 - w(ll)^2 + 2i*zeta(kk) * wn(kk)*w(ll));
        end
    end

    H(:,:,ll) = phi * diags * phi';

end



