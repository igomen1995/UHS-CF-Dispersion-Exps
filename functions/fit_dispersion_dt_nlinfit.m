function out = fit_dispersion_dt_nlinfit(C,t,u,Cj,Ci,L,p0,dC)

%FIT_DISPERSION_DT_NLINFIT Fit ADE breakthrough curve using weighted NLINFIT.
%
%   OUT = FIT_DISPERSION_DT_NLINFIT(C,T,U,CJ,CI,L,P0,DC) estimates the
%   longitudinal dispersion coefficient (KL) and breakthrough time shift
%   (dt) by fitting the analytical Advection-Dispersion Equation (ADE)
%   solution to experimental breakthrough-curve data using weighted
%   nonlinear least squares.
%
%   In addition to the fitted parameters, the function computes parameter
%   confidence intervals, prediction intervals, uncertainty estimates,
%   goodness-of-fit metrics, and regression diagnostics.
%
%   INPUTS
%       C      : Measured concentration data
%
%       t      : Time vector [s]
%
%       u      : Average interstitial velocity [m/s]
%
%       Cj     : Injected concentration step amplitude
%
%       Ci     : Initial/background concentration
%
%       L      : Core length or transport distance [m]
%
%       p0     : Initial parameter guess
%
%                p0(1) = sqrt(KL)
%                p0(2) = dt
%
%       dC     : Measurement uncertainty associated with each
%                concentration observation
%
%   OUTPUT
%       out    : Structure containing fitted parameters, uncertainties,
%                model predictions, and regression statistics.
%
%   OUTPUT FIELDS
%       out.KL              Fitted longitudinal dispersion coefficient
%                           [m^2/s]
%
%       out.dKL             Uncertainty in KL [m^2/s]
%
%       out.dt              Fitted breakthrough time shift [s]
%
%       out.ddt             Uncertainty in dt [s]
%
%       out.C_fit           Best-fit modeled breakthrough curve
%
%       out.C_pred          Predicted concentrations
%
%       out.dC_pred         95% prediction interval half-widths
%
%       out.RMSE            Weighted root mean square error
%
%       out.R2              Weighted coefficient of determination
%
%       out.Cfun            Model function handle
%
%       out.R               Residual vector
%
%       out.J               Jacobian matrix
%
%       out.CovB            Parameter covariance matrix
%
%       out.MSE             Mean squared error
%
%       out.ErrorModelInfo  Information returned by NLINFIT
%
%   MODEL DESCRIPTION
%       The fitted model is the simplified ADE solution implemented in:
%
%           ADE_short_dt_shift()
%
%       where:
%
%           KL = p(1)^2
%
%           dt = p(2)
%
%       The parameterization KL = p(1)^2 guarantees physically meaningful
%       positive dispersion coefficients during optimization.
%
%   WEIGHTED REGRESSION
%       Measurements are weighted according to their variance:
%
%           w = 1 / dC^2
%
%       giving larger influence to observations with smaller uncertainty.
%
%   PARAMETER UNCERTAINTY
%       Parameter confidence intervals are estimated from the regression
%       Jacobian and residuals using NLPARCI.
%
%       Since:
%
%           KL = p1^2
%
%       the uncertainty in KL is obtained by first-order error
%       propagation:
%
%           dKL = 2*p1*dp1
%
%   PREDICTION INTERVALS
%       Prediction intervals are calculated using NLPREDCI and include:
%
%           - Parameter uncertainty
%           - Residual variance
%
%       providing an estimate of the expected uncertainty in future
%       observations.
%
%   GOODNESS OF FIT
%       The function reports:
%
%           RMSE = Weighted root mean square error
%
%           R²   = Weighted coefficient of determination
%
%       allowing quantitative comparison among fitted experiments.
%
%   NOTES
%       - Uses weighted nonlinear least-squares fitting through NLINFIT.
%       - Includes numerical safeguards against non-physical parameter
%         estimates and failed model evaluations.
%       - Returns NaN-valued outputs if the fit does not converge.
%       - Intended for tracer breakthrough-curve analysis and estimation
%         of longitudinal dispersion coefficients in core-flood
%         experiments.
%
%   EXAMPLE
%       p0 = [sqrt(1e-7), 100];
%
%       out = fit_dispersion_dt_nlinfit(C,...
%                                       t,...
%                                       u,...
%                                       Cj,...
%                                       Ci,...
%                                       L,...
%                                       p0,...
%                                       dC);
%
%       fprintf('KL = %.3e ± %.3e m^2/s\n',out.KL,out.dKL)
%       fprintf('dt = %.1f ± %.1f s\n',out.dt,out.ddt)
%
%   See also NLINFIT, NLPARCI, NLPREDCI,
%            ADE_SHORT_DT_SHIFT.


out = struct('KL', NaN, 'dKL', NaN, 'dt', NaN, 'ddt', NaN, 'C_fit', NaN(size(C)), ...
    'C_pred', NaN(size(C)), 'dC_pred', NaN(size(C)), 'RMSE', NaN, 'R2', NaN, ...
    'Cfun', [], 'R', [], 'J', [], 'CovB', [], 'MSE', NaN, 'ErrorModelInfo', []);

w = 1./(dC.^2); % weights = 1/variance

C_trim = C;
t_trim = t;
w_trim = w;

% C_trim = C((C>0.1)&(C <0.90));
% t_trim = t((C>0.1)&(C <0.90));
% w_trim = w((C>0.1)&(C <0.90));
        
% Cj, Ci, u not fitting, fitting p where Kl = p(1)^2 and dt = p(2)
% Corrects BT curve due to extra volume before core

C_function = @(p,tvals) ADE_short_dt_shift(p,tvals,u,Cj,Ci,L);

% Weighted nonlinear fit
opts = statset('nlinfit');

try
    [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
catch ME
    % Only exit if truly fatal
    if contains(ME.message,'Inf') || contains(ME.message,'NaN')
        return
    else
        rethrow(ME)
    end
end

if any(~isfinite(p_est))
    return
end

% Confidence intervals for parameters 95%
ci = nlparci(p_est, R, 'jacobian', J);

% Extract parameters
p1 = p_est(1);      % sqrt(KL)
KL     = p_est(1)^2;
dt = p_est(2);

% Uncertainties
d_p1 = (ci(1,2) - ci(1,1))/2;
dKL = 2*p1*d_p1; % propagated from p1
d_dt = (ci(2,2) - ci(2,1))/2;

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
out.dt = dt;
out.ddt = d_dt;

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