function out = fit_dispersion_params_all(KL,Pe_fromD0,D0,Dp,p0,dKL)
% Reduced model for 3-point datasets:
%   KL = D0 * C2 * Pe^beta
% with constraints:
%   C2 > 0
%   1 <= beta <= 1.25

    % Weights = 1/variance
    w = 1./(dKL.^2);

    % Parameter transforms
    C2_fun   = @(p1) exp(p1);                        % C2 > 0
    beta_fun = @(p2) 1 + 0.25./(1 + exp(-p2));       % 1 <= beta <= 1.25

    % Reduced model
    KL_model = @(p,Pe_vals) ...
        D0 * ( C2_fun(p(1)) .* (Pe_vals.^beta_fun(p(2))) );

    % Weighted nonlinear fit
    opts = statset('nlinfit');
    [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit( ...
        Pe_fromD0, KL, KL_model, p0, opts, 'Weights', w);

    % Confidence intervals for unconstrained parameters
    ci = nlparci(p_est, R, 'jacobian', J);

    % Extract unconstrained parameters
    p1 = p_est(1);
    p2 = p_est(2);

    % Physical parameters
    C2   = C2_fun(p1);
    beta = beta_fun(p2);

    % Alpha (dispersivity)
    alpha = (C2^(1/beta)) * Dp;

    % Uncertainties in unconstrained parameters
    dp1 = (ci(1,2) - ci(1,1))/2;
    dp2 = (ci(2,2) - ci(2,1))/2;

    % Propagate to physical parameters
    dC2 = C2 * dp1;

    dbeta_dp2 = 0.25 * exp(-p2) / (1 + exp(-p2))^2;
    d_beta = dbeta_dp2 * dp2;

    % Alpha uncertainty
    dalpha_dC2   = Dp * (1/beta) * C2^(1/beta - 1);
    dalpha_dbeta = -alpha * (log(C2)/beta^2);

    d_alpha = sqrt( (dalpha_dC2*dC2)^2 + (dalpha_dbeta*d_beta)^2 );

    % Fitted curve
    KL_fit = KL_model(p_est, Pe_fromD0);

    % Prediction intervals (now valid!)
    [KL_pred, dKL_pred] = nlpredci(KL_model, Pe_fromD0, p_est, R, 'jacobian', J);

    % Weighted RMSE and R2
    RMSE = sqrt( sum(w .* (KL - KL_fit).^2) / sum(w) );

    KL_wmean = sum(w .* KL) / sum(w);
    SS_res = sum(w .* (KL - KL_fit).^2);
    SS_tot = sum(w .* (KL - KL_wmean).^2);
    R2 = 1 - SS_res/SS_tot;

    % Output
    out.C2 = C2;
    out.d_C2 = dC2;

    out.beta = beta;
    out.d_beta = d_beta;

    out.alpha_SI = alpha;
    out.d_alpha_SI = d_alpha;
    out.alpha_cm = alpha * 100;
    out.d_alpha_cm = d_alpha * 100;

    out.KL_fit = KL_fit;
    out.KL_pred = KL_pred;
    out.dKL_pred = dKL_pred;

    out.RMSE = RMSE;
    out.R2 = R2;

    out.Cfun = KL_model;
    out.R = R;
    out.J = J;
    out.CovB = CovB;
    out.MSE = MSE;
    out.ErrorModelInfo = ErrorModelInfo;

        
end