function out = fit_dispersion_dtfixed_nlinfit(C,t,u,Cj,Ci,L,dt_fixed,p0,dC,Cmin,Cmax)
%fit_dispersion solves KL (SI) given concentration and time array, interstitial velocity, 
% boundary conditions in x = 0 (Cj), initial concentration, length of the
% core, initial guess parameters
% p includes intital guess for Kl = p(1)^2 and a fixed dt = p(2);

w = 1./(dC.^2); % weights = 1/variance

C_vals = C((C>=Cmin)&(C<=Cmax));
t_vals = t((C>=Cmin)&(C<=Cmax));
w_vals = w((C>=Cmin)&(C<=Cmax));
        
% Cj, Ci, u not fitting, fitting p where Kl = p(1)^2
% Corrects BT curve due to extra volume before core

C_function = @(p,tvals)(Ci + (Cj/2)*erfc((L-u.*(tvals-dt_fixed))./(2*(max((tvals-dt_fixed),eps).^(1/2)).*p(1)))); % dt numerator and denominator
% C_function = @(p,t)(Ci + (Cj/2)*erfc((L-u.*(t-dt))./(2*(t.^(1/2)).*p(1)))); % dt only numerator

% full function
% C_function = @(p,t) Ci + (Cj/2) .* (erfc( (L - u.*(t - p(2))) ./ (2 * p(1) .* sqrt(max(t - p(2), eps))) ) + ...
%     exp( u*L / (p(1)^2) ) .*erfc( (L + u.*(t - p(2))) ./ (2 * p(1) .* sqrt(max(t - p(2), eps))) ));

% Weighted nonlinear fit
opts = statset('nlinfit');
[p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_vals, C_vals, C_function, p0, opts, 'Weights', w_vals);

% Confidence intervals for parameters 95%
ci = nlparci(p_est, R, 'jacobian', J);

% Extract parameters
p1 = p_est(1);      % sqrt(KL)
KL = p_est(1)^2;

% Uncertainties
d_p1 = (ci(1,2) - ci(1,1))/2;
dKL = 2*p1*d_p1; % propagated from p1

% Fitted curve
C_fit = C_function(p_est, t);

% Prediction intervals
[C_pred, dC_pred] = nlpredci(C_function, t, p_est, R, 'jacobian', J);

% Weighted RMSE and R2
RMSE = sqrt( sum(w .* (C - C_fit).^2) / sum(w) );
R2 = 1 - (sum(w .* (C - C_fit).^2))/(sum(w .* (C - (sum(w .* C) / sum(w))).^2));

% Output
out.KL = KL;
out.dKL = dKL;
out.dt = dt_fixed;
out.ddt = 0;

out.C_fit = C_fit; % Best fit model prediction using estimated parameters
out.C_pred = C_pred; % 95% prediction interval, which includes paramters uncertainty and residual variance
out.dC_pred = dC_pred;

out.RMSE = RMSE;
out.R2 = R2;

out.Cfun = C_function;
out.R = R;
out.J = J;
out.CovB = CovB;
out.MSE = MSE;
out.ErrorModelInfo = ErrorModelInfo;
        
        
end