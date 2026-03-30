function out = fit_dispersion_dt_lines_error(C,dCi,t,u,Cj,Ci,L,KLlines,vlines,p0)

    % % Model
    % C_model = @(p,t) Ci + (Cj/2).*erfc( ...
    %     (L - u.*t + vlines.*p(2)) ./ (2*p(1).*sqrt(max(t,eps))) );

    % Model KL lines
    C_model = @(p,t) Ci + (Cj/2).*erfc( ...
        (L - u.*t + vlines.*p(2)) ./ (2*(p(1).*sqrt(max(t,eps)))-sqrt(max(KLlines.*p(2),eps))) );

    %C_function = @(p,t)(Ci + (Cj/2)*erfc((L-u.*(t-p(2)))./(2*(max((t-p(2)),eps).^(1/2)).*p(1)))); % dt numerator and denominator


   % Weighted fit
    opts = statset('nlinfit');
    [p_est,res,J,CovB,mse] = nlinfit(t, C, C_model, p0, opts, ...
                                     'Weights', 1./dCi);

    % Extract parameters
    KL = p_est(1)^2;
    dt = p_est(2);

    % Uncertainty propagation
    % Covariance of p_est is CovB
    dKL = 2*p_est(1) * sqrt(CovB(1,1));   % via derivative d(KL)/dp1 = 2*p1
    ddt = sqrt(CovB(2,2));

    % Package output
    out.KL = KL;
    out.dKL = dKL;
    out.dt = dt;
    out.ddt = ddt;
    out.p = p_est;
    out.CovB = CovB;
    out.res = res;
    out.J = J;

end
