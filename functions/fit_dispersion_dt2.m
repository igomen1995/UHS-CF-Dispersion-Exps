function [KL,dt_fit, u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion_dt2(C,t,u,Cj,Ci,L,p)
% p(1) = sqrt(KL)
% p(2) = dt

    C_function = @(p,t) OBsolution(p,t,Ci,Cj,L,u);

    for i = 1:5

        C_fit = fitnlm(t,C,C_function,p);
    
        p(1) = C_fit.Coefficients.Estimate(1);
        p(2) = C_fit.Coefficients.Estimate(2);
    
        KL     = p(1)^2;
        dt_fit = p(2);
        u_fit  = u;
        Cj_fit = Cj;
        Ci_fit = Ci;
    end
end


function C = OBsolution(p,t,Ci,Cj,L,u)
    KL_sqrt = p(1);      % sqrt(KL)
    dt      = p(2);      % time delay

    ts = t - dt;         % shifted time
    C  = Ci * ones(size(t));

    mask = ts > 0;
    ts_pos = ts(mask);

    % --- Ogata–Banks term 1 ---
    arg1 = (L - u.*ts_pos) ./ (2 * KL_sqrt .* sqrt(ts_pos));

    % --- Ogata–Banks term 2 ---
    arg2 = 0;%(L + u.*ts_pos) ./ (2 * KL_sqrt .* sqrt(ts_pos));
    exp_term = 0;%exp(u*L/(KL_sqrt^2));

    % Full OB step solution
    C(mask) = Ci + (Cj/2) .* ( erfc(arg1) + exp_term .* erfc(arg2) );
end
