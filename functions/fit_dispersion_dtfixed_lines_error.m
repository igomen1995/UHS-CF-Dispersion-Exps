function out = fit_dispersion_dtfixed_lines_error(C,dCi, t,u,Cj,Ci,L,KLlines,vlines,dt_fixed,p0)

    % p0 now contains only p(1) = sqrt(KL)
    C_model = @(p,t) Ci + (Cj/2).*erfc( ...
        (L - u.*t + vlines.*dt_fixed) ./ (2*p(1).*sqrt(max(t,eps))) );

    % % Model KL lines
    % C_model = @(p,t) Ci + (Cj/2).*erfc( ...
    %     (L - u.*t + vlines.*dt_fixed) ./ (2*(p(1).*sqrt(max(t,eps)))-sqrt(max(KLlines.*dt_fixed,eps))) );

    opts = statset('nlinfit');
    [p_est,res,J,CovB,mse] = nlinfit(t, C, C_model, p0, opts, ...
                                     'Weights', 1./dCi);

    KL = p_est(1)^2;
    dKL = 2*p_est(1) * sqrt(CovB(1,1));

    out.KL = KL;
    out.dKL = dKL;
    out.dt = dt_fixed;
    out.ddt = 0;   % fixed parameter → no uncertainty
    out.p = p_est;
    out.CovB = CovB;
    out.res = res;
    out.J = J;
end
