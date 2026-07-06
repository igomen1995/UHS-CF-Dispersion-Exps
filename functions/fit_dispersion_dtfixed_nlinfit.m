function out = fit_dispersion_dtfixed_nlinfit(C,t,u,Cj,Ci,L,dt_fixed,p0,dC,Cmin,Cmax)

%FIT_DISPERSION_DTFIXED_NLINFIT Fit KL with fixed delay using weighted NLINFIT.
%
%   OUT = FIT_DISPERSION_DTFIXED_NLINFIT(C,T,U,CJ,CI,L,...
%                                        DT_FIXED,P0,DC,...
%                                        CMIN,CMAX)
%   estimates the longitudinal dispersion coefficient (KL) by fitting a
%   time-shifted analytical Advection-Dispersion Equation (ADE) solution
%   to breakthrough-curve data using weighted nonlinear least squares.
%
%   Unlike FIT_DISPERSION_DT_NLINFIT, the breakthrough delay parameter
%   (dt) is held fixed during optimization and only the dispersion
%   coefficient is estimated.
%
%   The function additionally computes parameter uncertainties,
%   prediction intervals, goodness-of-fit metrics, and regression
%   diagnostics.
%
%   INPUTS
%       C         : Measured concentration data
%
%       t         : Time vector [s]
%
%       u         : Average interstitial velocity [m/s]
%
%       Cj        : Injected concentration step amplitude
%
%       Ci        : Initial/background concentration
%
%       L         : Core length or transport distance [m]
%
%       dt_fixed  : Fixed breakthrough delay parameter [s]
%
%       p0        : Initial parameter guess
%
%                   p0 = sqrt(KL)
%
%       dC        : Measurement uncertainty associated with each
%                   concentration observation
%
%       Cmin      : Lower concentration bound used for fitting
%
%       Cmax      : Upper concentration bound used for fitting
%
%   OUTPUT


out = struct('KL', NaN, 'dKL', NaN, 'dt', NaN, 'ddt', NaN, 'C_fit', NaN(size(C)), ...
    'C_pred', NaN(size(C)), 'dC_pred', NaN(size(C)), 'RMSE', NaN, 'R2', NaN, ...
    'Cfun', [], 'R', [], 'J', [], 'CovB', [], 'MSE', NaN, 'ErrorModelInfo', []);

w = 1./(dC.^2); % weights = 1/variance

C_vals = C((C>=Cmin)&(C<=Cmax));
t_vals = t((C>=Cmin)&(C<=Cmax));
w_vals = w((C>=Cmin)&(C<=Cmax));
        
% Cj, Ci, u not fitting, fitting p where Kl = p(1)^2
% Corrects BT curve due to extra volume before core

p = [dt_fixed; p0];

C_function = @(p,tvals) ADE_short_dt_shift(p,tvals,u,Cj,Ci,L);

% Weighted nonlinear fit
opts = statset('nlinfit');

try
    [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_vals, C_vals, C_function, p, opts, 'Weights', w_vals);
catch ME
    % Only exit if truly fatal
    if contains(ME.message,'Inf') || contains(ME.message,'NaN')
        return
    else
        rethrow(ME)
    end
end

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