function out = fit_dispersion_params_alpha(KL,Pe_fromD0,D0,Dp,p0,dKL)

%FIT_DISPERSION_PARAMS_ALPHA Fit a dispersivity-based dispersion correlation.
%
%   OUT = FIT_DISPERSION_PARAMS_ALPHA(KL,PE_FROMD0,D0,DP,P0,dKL)
%   estimates the dispersivity parameter of a hydrodynamic dispersion
%   correlation by fitting longitudinal dispersion coefficients (KL)
%   as a function of Peclet number (Pe).
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
%       C2   : Proportionality coefficient
%
%   The scaling exponent is fixed:
%
%       beta = 1
%
%   and only the dispersivity-related parameter C2 is estimated.
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
%       p0          : Initial guess for parameter C2
%
%       dKL         : Uncertainty associated with KL [m^2/s]
%
%   OUTPUT
%       out         : Structure containing fitted parameters,
%                     uncertainties, model predictions, and regression
%                     statistics.
%
%   MODEL DESCRIPTION
%       The fitted correlation is implemented through:
%
%           KL_Pe_alpha_only_model()
%
%       and takes the form:
%
%           KL = D0 * C2 * Pe
%
%       The dispersivity is computed as:
%
%           alpha = C2 * Dp
%
%       where alpha represents the characteristic length scale
%       associated with mechanical dispersion within the porous medium.
%
%   FITTING PROCEDURE
%       Parameters are estimated using MATLAB's NLINFIT routine with
%       inverse-variance weighting:
%
%           w = 1/dKL^2
%
%       giving greater weight to observations with smaller uncertainty.
%
%   UNCERTAINTY ANALYSIS
%       Confidence intervals for C2 are calculated using NLPARCI.
%
%       The uncertainty in dispersivity is propagated as:
%
%           alpha = C2 * Dp
%
%           d(alpha) = Dp * d(C2)
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
%   INTERPRETATION
%       The fitted dispersivity alpha quantifies the contribution of
%       mechanical dispersion to longitudinal spreading within the porous
%       medium. Larger values of alpha indicate stronger velocity-driven
%       mixing and spreading.
%
%   NOTES
%       - Uses weighted nonlinear least-squares regression.
%       - Assumes a fixed scaling exponent (beta = 1).
%       - No tortuosity term is included in this model.
%       - Returns parameter uncertainties and prediction intervals.
%       - Intended for analysis of dispersion scaling relationships in
%         porous-media transport and core-flood experiments.
%
%   EXAMPLE
%       out = fit_dispersion_params_alpha(KL,...
%                                         Pe_D0,...
%                                         D0,...
%                                         Dp,...
%                                         1,...
%                                         dKL);
%
%       fprintf('alpha = %.2f ± %.2f cm\n',...
%               out.alpha_cm,out.d_alpha_cm)
%
%   See also NLINFIT, NLPARCI, NLPREDCI,
%            KL_Pe_ALPHA_ONLY_MODEL.

% Weights = 1/variance
w = 1./(dKL.^2);

% Model with beta = 1 no tortuosity
KL_model = @(p,Pe_vals) KL_Pe_alpha_only_model(Pe_vals,D0,p);

% Nonlinear fit (unweighted or weighted)
opts = statset('nlinfit');
[p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(Pe_fromD0, KL, KL_model, p0, opts,'Weights', w);

% Confidence interval for p1
ci = nlparci(p_est, R, 'jacobian', J);

% Extract parameters
C2 = p_est(1);
alpha = C2 * Dp; % Alpha (dispersivity)

% Uncertainties
dC2 = (ci(1,2) - ci(1,1))/2;
d_alpha = Dp * dC2;

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