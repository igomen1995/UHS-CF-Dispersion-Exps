function out = fit_dispersion_params_all(KL,Pe_fromD0,D0,Dp,p0,dKL)
% fit_dispersion_params_all
%   Solves alpha, beta and tortuosity with constraints and weights
%   Constraints:
%       tau >= 1
%       1 <= beta <= 1.25
%       C2 > 0
%
%   Model:
%       KL = D0 * ( 1/tau + ( (C2^(1/beta))*Pe )^beta )
%       alpha_L = (C2^(1/beta))*Dp

    % Weights = 1/variance
    w = 1./(dKL.^2);

    % Parameter transforms (unconstrained p -> physical params)
    tau_fun  = @(p1) 1 + exp(p1);                         % tau >= 1
    C2_fun   = @(p2) exp(p2);                             % C2 > 0
    beta_fun = @(p3) 1 + 0.25./(1 + exp(-p3));            % 1 <= beta <= 1.25

    % Full model in terms of unconstrained p
    KL_D0_vs_Pe_function_full = @(p,Pe_vals) ...
        D0 * ( ...
            1./tau_fun(p(1)) + ...
            ( (C2_fun(p(2)).^(1./beta_fun(p(3))) .* Pe_vals) ).^beta_fun(p(3)) ...
        );

    % Weighted nonlinear fit
    opts = statset('nlinfit');
    [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit( ...
        Pe_fromD0, KL, KL_D0_vs_Pe_function_full, p0, opts, 'Weights', w);

    % Confidence intervals for unconstrained parameters (95%)
    ci = nlparci(p_est, R, 'jacobian', J);

    p1 = p_est(1);
    p2 = p_est(2);
    p3 = p_est(3);

    % Physical parameters
    tau  = tau_fun(p1);
    C2   = C2_fun(p2);
    beta = beta_fun(p3);

    % Alpha (dispersivity)
    alpha = (C2^(1/beta)) * Dp;   % SI

    % Uncertainties in unconstrained parameters (half-width of CI)
    dp1 = (ci(1,2) - ci(1,1))/2;
    dp2 = (ci(2,2) - ci(2,1))/2;
    dp3 = (ci(3,2) - ci(3,1))/2;

    % Propagate to physical parameters
    % tau = 1 + exp(p1)
    d_tau = exp(p1) * dp1;

    % C2 = exp(p2)
    d_C2 = C2 * dp2;

    % beta = 1 + 0.25/(1+exp(-p3))
    dbeta_dp3 = 0.25 * exp(-p3) / (1 + exp(-p3))^2;
    d_beta = dbeta_dp3 * dp3;

    % Alpha uncertainty: alpha = Dp * C2^(1/beta)
    dalpha_dC2   = Dp * (1/beta) * C2^(1/beta - 1);
    dalpha_dbeta = -alpha * (log(C2) / beta^2);

    d_alpha = sqrt( (dalpha_dC2 * d_C2)^2 + (dalpha_dbeta * d_beta)^2 );

    % Fitted curve
    KL_fit = KL_D0_vs_Pe_function_full(p_est, Pe_fromD0);

    % Prediction intervals
    [KL_pred, dKL_pred] = nlpredci( ...
        KL_D0_vs_Pe_function_full, Pe_fromD0, p_est, R, 'jacobian', J);

    % Weighted RMSE and R2
    RMSE = sqrt( sum(w .* (KL - KL_fit).^2) / sum(w) );

    KL_wmean = sum(w .* KL) / sum(w);
    SS_res = sum(w .* (KL - KL_fit).^2);
    SS_tot = sum(w .* (KL - KL_wmean).^2);
    R2 = 1 - SS_res/SS_tot;

    % Output
    out.tau = tau;
    out.d_tau = d_tau;

    out.beta = beta;
    out.d_beta = d_beta;

    out.alpha_SI = alpha;
    out.d_alpha_SI = d_alpha;
    out.alpha_cm = alpha * 100;
    out.d_alpha_cm = d_alpha * 100;

    out.C2 = C2;
    out.d_C2 = d_C2;

    out.KL_fit = KL_fit;
    out.KL_pred = KL_pred;
    out.dKL_pred = dKL_pred;

    out.RMSE = RMSE;
    out.R2 = R2;

    out.Cfun = KL_D0_vs_Pe_function_full;
    out.R = R;
    out.J = J;
    out.CovB = CovB;
    out.MSE = MSE;
    out.ErrorModelInfo = ErrorModelInfo;
        
end