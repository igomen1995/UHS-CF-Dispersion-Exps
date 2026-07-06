function out = fit_dispersion_params_alpha_tau(KL,Pe_fromD0,D0,Dp,p0,dKL)

%FIT_DISPERSION_PARAMS_ALPHA_TAU Fit dispersivity and tortuosity parameters.
%
%   OUT = FIT_DISPERSION_PARAMS_ALPHA_TAU(KL,PE_FROMD0,D0,DP,P0,dKL)
%   fits an empirical longitudinal-dispersion correlation that accounts
%   for both mechanical dispersion and molecular diffusion effects in
%   porous media.
%
%   The model assumes:
%
%       KL = D0 * (1/tau + C2*Pe)
%
%   where:
%
%       KL   : Longitudinal dispersion coefficient
%       D0   : Molecular diffusion coefficient
%       Pe   : Peclet number
%       C2   : Mechanical-dispersion coefficient
%       tau  : Tortuosity factor
%
%   The scaling exponent is fixed:
%
%       beta = 1
%
%   and the fitted parameters are:
%
%       p(1) = C2
%       p(2) = tau
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
%       p0          : Initial parameter guess
%
%                     p0(1) = C2
%                     p0(2) = tau
%
%       dKL         : Uncertainty associated with KL [m^2/s]
%
%   OUTPUT
%       out         : Structure containing fitted parameters,
%                     uncertainties, model predictions, goodness-of-fit
%                     statistics, and regression diagnostics.
%
%   MODEL DESCRIPTION
%       The fitted correlation is implemented through:
%
%           KL_Pe_alpha_tau_model()
%
%       and assumes:
%
%           KL = D0 * (1/tau + C2*Pe)
%
%       where:
%
%           1/tau
%
%       represents the contribution of molecular diffusion through the
%       porous medium and:
%
%           C2*Pe
%
%       represents mechanical dispersion.
%
%       The corresponding dispersivity is:
%
%           alpha = C2 * Dp
%
%   FITTING PROCEDURE
%       Parameters are estimated using MATLAB's NLINFIT routine with
%       inverse-variance weighting:
%
%           w = 1/dKL^2
%
%       giving greater influence to measurements with lower uncertainty.
%
%   UNCERTAINTY ANALYSIS
%       Parameter confidence intervals are estimated using NLPARCI.
%
%       The uncertainty in dispersivity is propagated from C2:
%
%           alpha = C2 * Dp
%
%           d(alpha) = Dp * d(C2)
%
%       The uncertainty in tortuosity is obtained directly from the
%       fitted confidence interval:
%
%           d(tau)
%
%   OUTPUT FIELDS
%       out.C2              Mechanical-dispersion coefficient
%
%       out.d_C2            Uncertainty in C2
%
%       out.beta            Fixed exponent (= 1)
%
%       out.d_beta          Exponent uncertainty (= 0)
%
%       out.tau             Fitted tortuosity factor
%
%       out.d_tau           Uncertainty in tortuosity
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
%       out.R               Regression residuals
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
%       The fitted parameter alpha characterizes the magnitude of
%       mechanical dispersion, while tau characterizes the influence of
%       pore-scale tortuosity on molecular diffusion.
%
%       Together, these parameters describe both advective and diffusive
%       contributions to longitudinal dispersion in porous media.
%
%   NOTES
%       - Uses weighted nonlinear least-squares regression.
%       - Assumes a fixed scaling exponent beta = 1.
%       - Simultaneously estimates dispersivity and tortuosity.
%       - Returns prediction intervals and parameter uncertainties.
%       - Intended for analysis of hydrodynamic dispersion in core-flood
%         and porous-media transport experiments.
%
%   EXAMPLE
%       p0 = [1, 2];
%
%       out = fit_dispersion_params_alpha_tau(KL,...
%                                             Pe_D0,...
%                                             D0,...
%                                             Dp,...
%                                             p0,...
%                                             dKL);
%
%       fprintf('alpha = %.2f ± %.2f cm\n',...
%               out.alpha_cm,out.d_alpha_cm)
%
%       fprintf('tau = %.2f ± %.2f\n',...
%               out.tau,out.d_tau)
%
%   See also NLINFIT, NLPARCI, NLPREDCI,
%            KL_Pe_alpha_tau_model.

% Weights = 1/variance
w = 1./(dKL.^2);

% % Model with beta = 1 tortuosity

KL_model = @(p,Pe_vals) KL_Pe_alpha_tau_model(Pe_vals,D0,p);

% Nonlinear fit (unweighted or weighted)
opts = statset('nlinfit');
[p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(Pe_fromD0, KL, KL_model, p0, opts,'Weights', w);

% Confidence interval for p1
ci = nlparci(p_est, R, 'jacobian', J);

% Extract parameters
C2 = p_est(1);
alpha = C2 * Dp; % Alpha (dispersivity)
tau = p_est(2); % tortuosity > 1

% Uncertainties
dC2 = (ci(1,2) - ci(1,1))/2;
d_alpha = Dp * dC2;
dtau = (ci(2,2) - ci(2,1))/2;

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

out.tau = tau;      
out.d_tau = dtau;      

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