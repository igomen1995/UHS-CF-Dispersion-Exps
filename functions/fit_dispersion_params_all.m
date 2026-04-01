function out = fit_dispersion_params_all(KL,Pe_fromD0,D0,Dp,p0,dKL)
% fit_dispersion_params_all solves alpha, beta and tortuosity with constrains and weights (inverse of variaance of Kl)
%
%
% Pe with Dp = L; Pe = u*L/D0
% KL = D0 *(1/tao + C2((Pe)^beta))
% KL = D0 *(1/tao + ((C2^(1/beta))*(Pe))^beta)
% alpha_L = (C2^(1/beta)*L

w = 1./(dKL.^2); % weights = 1/variance

KL_D0_vs_Pe_function_full = @(p,Pe_vals)D0 *((1/p(1)) + ((p(2)^(1/p(3)))*Pe_vals).^p(3));

% Weighted nonlinear fit
opts = statset('nlinfit');
[p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(Pe_fromD0, KL, KL_D0_vs_Pe_function_full, p0, opts, 'Weights', w);

% Confidence intervals for parameters 95%
ci = nlparci(p_est, R, 'jacobian', J);

% Extract parameters
tau = p_est(1); 
beta = p_est(3); 
C2 = p_est(2);
alpha = (C2^(beta))*Dp; % SI

% Uncertainties
d_tau = (ci(1,2) - ci(1,1))/2;
d_beta = (ci(3,2) - ci(3,1))/2;
d_C2 = (ci(2,2) - ci(2,1))/2; %dC2 C2 consant to solve alpha
d_alpha_dC2 = Dp*(1/beta)*C2^(1/beta -1);
d_alpha_dbeta = -alpha*log(C2)/(beta^2);
d_alpha = sqrt( (d_alpha_dC2 * d_C2)^2 + (d_alpha_dbeta * d_beta)^2 );

% Fitted curve
KL_fit = KL_D0_vs_Pe_function_full(p_est, Pe_fromD0);
 
% Prediction intervals
[KL_pred, dKL_pred] = nlpredci(KL_D0_vs_Pe_function_full, Pe_fromD0, p_est, R, 'jacobian', J);

% Weighted RMSE and R2
RMSE = sqrt( sum(w .* (KL - KL_fit).^2) / sum(w) );
R2 = 1 - (sum(w .* (KL - KL_fit).^2))/(sum(w .* (KL - (sum(w .* KL) / sum(w))).^2));

% Output
out.tau = tau;
out.d_tau = d_tau;
out.beta = beta;
out.d_beta = d_beta;
out.alpha_SI = alpha;
out.d_alpha_SI = d_alpha;
out.alpha_cm = alpha*100;
out.d_alpha_cm = d_alpha*100;

out.KL_fit = KL_fit; % Best fit model prediction using estimated parameters
out.KL_pred = KL_pred; % 95% prediction interval, which includes paramters uncertainty and residual variance
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