function out = fit_dispersion_params_all_fitnlm(KL,Pe_fromD0,D0,Dp,p0,dKL)

% Model with beta = 1:
% KL = D0 * C2 * Pe
% Parameter: C2 > 0

% Weights = 1/variance
w = 1./(dKL.^2);

% Table for fitnlm
tbl = table(Pe_fromD0, KL, 'VariableNames', {'Pe','KL'});

% Model function for fitnlm (C2 = exp(b1))
modelfun = @(b,Pe) D0 * b(1) .* Pe;

% Fit (unweighted)
mdl = fitnlm(tbl, modelfun, p0,'Weights',w);

% Extract parameter
C2 = mdl.Coefficients.Estimate(1);

% Alpha
alpha = C2 * Dp;

% Uncertainty in C2
dC2 = mdl.Coefficients.SE(1);

% Uncertainty in alpha
d_alpha = Dp * dC2;

% Fitted curve
KL_fit = modelfun(mdl.Coefficients.Estimate, Pe_fromD0);

% Prediction intervals
[KL_pred, dKL_pred] = predict(mdl, tbl);

% Output
out.C2 = C2;
out.d_C2 = dC2;

out.beta = 1;
out.d_beta = 0;

out.alpha_SI = alpha;
out.d_alpha_SI = d_alpha;
out.alpha_cm = alpha * 100;
out.d_alpha_cm = d_alpha * 100;

out.KL_fit = KL_fit;
out.KL_pred = KL_pred;
out.dKL_pred = dKL_pred;

out.RMSE = mdl.RMSE;
out.R2 = mdl.Rsquared.Ordinary;

out.mdl = mdl;
out.modelfun = modelfun;

end
