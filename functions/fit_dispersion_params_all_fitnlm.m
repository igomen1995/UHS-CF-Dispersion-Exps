function out = fit_dispersion_params_all_fitnlm(KL,Pe_fromD0,D0,Dp,p0,dKL)

%FIT_DISPERSION_PARAMS_ALL_FITNLM Fit a dispersion scaling correlation.
%
%   OUT = FIT_DISPERSION_PARAMS_ALL_FITNLM(KL,PE_FROMD0,D0,DP,P0,dKL)
%   fits an empirical dispersion correlation relating the longitudinal
%   dispersion coefficient (KL) to the molecular-diffusion-based Peclet
%   number (Pe).
%
%   The fitted model assumes:
%
%       KL = D0 * C2 * Pe
%
%   where:
%
%       KL   : Longitudinal dispersion coefficient
%       D0   : Molecular diffusion coefficient
%       Pe   : Peclet number
%       C2   : Fitted proportionality coefficient
%
%   The model corresponds to a fixed scaling exponent:
%
%       beta = 1
%
%   and estimates only the parameter C2.
%
%   INPUTS
%       KL          : Measured or fitted longitudinal dispersion
%                     coefficients [m^2/s]
%
%       Pe_fromD0   : Peclet numbers calculated using D0 [-]
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
%       out         : Structure containing fitted parameters,
%                     uncertainties, model predictions, and fit statistics.
%
%   OUTPUT FIELDS
%       out.C2              Fitted correlation coefficient
%
%       out.d_C2            Standard error of C2
%
%       out.beta            Fixed exponent (= 1)
%
%       out.d_beta          Exponent uncertainty (= 0)
%
%       out.alpha_SI        Estimated dispersivity [m]
%
%       out.d_alpha_SI      Uncertainty in dispersivity [m]
%
%       out.alpha_cm        Estimated dispersivity [cm]
%
%       out.d_alpha_cm      Uncertainty in dispersivity [cm]
%
%       out.KL_fit          Best-fit model values
%
%       out.KL_pred         Predicted KL values
%
%       out.dKL_pred        Prediction interval half-widths
%
%       out.RMSE            Root mean square error
%
%       out.R2              Coefficient of determination
%
%       out.mdl             NonLinearModel object
%
%       out.modelfun        Model function handle
%
%   MODEL DESCRIPTION
%       The fitted relationship is:
%
%           KL = D0 * C2 * Pe
%
%       which can be rewritten as:
%
%           KL = alpha * u
%
%       where:
%
%           alpha = C2 * Dp
%
%       is the effective dispersivity of the porous medium.
%
%   FITTING PROCEDURE
%       Parameters are estimated using MATLAB's FITNLM routine with
%       inverse-variance weighting:
%
%           w = 1/dKL^2
%
%       giving greater influence to observations having lower
%       uncertainty.
%
%   UNCERTAINTY ANALYSIS
%       The uncertainty in dispersivity is propagated from the fitted
%       uncertainty in C2:
%
%           alpha = C2 * Dp
%
%           d(alpha) = Dp * d(C2)
%
%   NOTES
%       - Assumes beta = 1 and does not fit the exponent.
%       - Uses weighted nonlinear regression.
%       - Intended for analysis of dispersion scaling and estimation of
%         porous-medium dispersivity.
%       - Returns prediction intervals and goodness-of-fit statistics.
%
%   EXAMPLE
%       out = fit_dispersion_params_all_fitnlm(KL,...
%                                              Pe_D0,...
%                                              D0,...
%                                              Dp,...
%                                              1,...
%                                              dKL);
%
%       fprintf('C2 = %.3f ± %.3f\n',out.C2,out.d_C2)
%       fprintf('alpha = %.2f ± %.2f cm\n',...
%               out.alpha_cm,out.d_alpha_cm)
%
%   See also FITNLM, PREDICT.

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
