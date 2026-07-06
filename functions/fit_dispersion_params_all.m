function out = fit_dispersion_params_all(KL,Pe_fromD0,D0,Dp,p0,dKL)

%FIT_DISPERSION_PARAMS_ALL Fit a dispersion scaling correlation using NLINFIT.
%
%   OUT = FIT_DISPERSION_PARAMS_ALL(KL,PE_FROMD0,D0,DP,P0,dKL)
%   fits an empirical relationship between the longitudinal dispersion
%   coefficient (KL) and the molecular-diffusion-based Peclet number (Pe)
%   using weighted nonlinear least squares.
%
%   The model assumes:
%
%       KL = D0 * C2 * Pe
%
%   where:
%
%       KL   : Longitudinal dispersion coefficient
%       D0   : Molecular diffusion coefficient
%       Pe   : Peclet number
%       C2   : Empirical proportionality coefficient
%
%   The scaling exponent is fixed:
%
%       beta = 1
%
%   and only C2 is estimated.
%
%   INPUTS
%       KL          : Measured or fitted longitudinal dispersion
%                     coefficients [m^2/s]
%
%       Pe_fromD0   : Peclet numbers calculated using the molecular
%                     diffusion coefficient D0 [-]
%
%       D0          : Molecular diffusion coefficient [m^2/s]
%
%       Dp          : Characteristic pore diameter [m]
%
%       p0          : Initial guess for C2
%
%       dKL         : Uncertainty associated with KL [m^2/s]
%
%   OUTPUT
%       out         : Structure containing fitted parameters, uncertainty
%                     estimates, fitted values, prediction intervals,
%                     goodness-of-fit statistics, and regression
%                     diagnostics.
%
%   MODEL DESCRIPTION
%       The fitted correlation is:
%
%           KL = D0 * C2 * Pe
%
%       with:
%
%           beta = 1
%
%       The fitted parameter C2 can be related to dispersivity:
%
%           alpha = C2 * Dp
%
%       where alpha is the characteristic dispersivity length scale of
%       the porous medium.
%
%   FITTING PROCEDURE
%       Parameters are estimated using MATLAB's NLINFIT routine with
%       inverse-variance weighting:
%
%           w = 1 / dKL^2
%
%       resulting in greater influence from measurements with lower
%       uncertainty.
%
%   UNCERTAINTY ANALYSIS
%       Confidence intervals for C2 are computed using NLPARCI.
%
%       The uncertainty in dispersivity is propagated as:
%
%           alpha = C2 * Dp
%
%           d(alpha) = Dp * d(C2)
%
%   GOODNESS OF FIT
%       The function reports:
%
%           RMSE = Weighted root mean square error
%
%           R²   = Weighted coefficient of determination
%
%       allowing quantitative comparison of alternative dispersion
%       correlations or datasets.
%
%   OUTPUT FIELDS
%       out.C2              Fitted proportionality coefficient
%
%       out.d_C2            Uncertainty in C2
%
%       out.beta            Fixed exponent (= 1)
%
%       out.d_beta          Exponent uncertainty (= 0)
%
%       out.alpha_SI        Dispersivity [m]
%
%       out.d_alpha_SI      Dispersivity uncertainty [m]
%
%       out.alpha_cm        Dispersivity [cm]
%
%       out.d_alpha_cm      Dispersivity uncertainty [cm]
%
%       out.KL_fit          Best-fit model values
%
%       out.KL_pred         Predicted KL values
%
%       out.dKL_pred        95% prediction interval half-widths
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
%       out.ErrorModelInfo  Diagnostic information returned by NLINFIT
%
%   NOTES
%       - Uses weighted nonlinear regression with weights equal to the
%         inverse variance of KL measurements.
%       - Assumes a fixed scaling exponent (beta = 1).
%       - Returns both confidence-based parameter uncertainties and
%         prediction intervals.
%       - Intended for estimating dispersivity and evaluating dispersion
%         scaling relationships in porous-media transport experiments.
%
%   EXAMPLE
%       out = fit_dispersion_params_all(KL,...
%                                       Pe_D0,...
%                                       D0,...
%                                       Dp,...
%                                       1,...
%                                       dKL);
%
%       fprintf('C2 = %.3f ± %.3f\n',out.C2,out.d_C2)
%       fprintf('alpha = %.2f ± %.2f cm\n',...
%               out.alpha_cm,out.d_alpha_cm)
%
%   See also NLINFIT, NLPARCI, NLPREDCI.

% Weights = 1/variance
w = 1./(dKL.^2);

% Model with beta = 1 no tortuosity
KL_model = @(p,Pe_vals) D0 * ( p(1) .* Pe_vals );

% % Model with beta = 1 tortuosity
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