function out = fit_dispersion_params_all(KL,Pe_fromD0,D0,Dp,p0,dKL)
% Reduced model with beta = 1 exactly:
%   KL = D0 * C2 * Pe
% Only parameter: C2 > 0

% Weights = 1/variance
w = 1./(dKL.^2);

% Model with beta = 1 no tortuosity
KL_model = @(p,Pe_vals) D0 * ( p(1) .* Pe_vals );

% Model with beta = 1 tortuosity
% KL_model = @(p,Pe_vals) D0 * ( 1/p(2) + p(1) .* (Pe_vals.^1) );

% Nonlinear fit (unweighted or weighted)
opts = statset('nlinfit');
[p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(Pe_fromD0, KL, KL_model, p0, opts,'Weights', w);

% Confidence interval for p1
ci = nlparci(p_est, R, 'jacobian', J);

% Extract parameters
C2 = p_est(1);
alpha = C2 * Dp; % Alpha (dispersivity)
% tau = p_est(2); % tortuosity > 1

% Uncertainties
dC2 = (ci(1,2) - ci(1,1))/2;
d_alpha = Dp * dC2;
% dtau = (ci(2,2) - ci(2,1))/2;

% Fitted curve
KL_fit = KL_model(p_est, Pe_fromD0);

% Prediction intervals
[KL_pred, dKL_pred] = nlpredci(KL_model, Pe_fromD0, p_est, R, 'jacobian', J);

% Weighted RMSE and R2
RMSE = sqrt( sum(w .* (KL - KL_fit).^2) / sum(w) );
R2 = 1 - (sum(w .* (KL - KL_fit).^2))/(sum(w .* (KL - (sum(w .* KL) / sum(w))).^2));

% Output
out.C2 = C2;
out.d_C2 = dC2;

out.beta = 1;        % fixed
out.d_beta = 0;      % no uncertainty

% out.tau = tau;      
% out.d_tau = dtau;      

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