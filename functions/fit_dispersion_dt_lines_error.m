function out = fit_dispersion_dt_lines_error(C,dCi,t,u,Cj,Ci,L,KLlines,vlines,p0)

%FIT_DISPERSION_DT_LINES_ERROR Fit ADE dispersion and line-delay parameters.
%
%   OUT = FIT_DISPERSION_DT_LINES_ERROR(C,dCi,t,u,Cj,Ci,L,...
%                                       KLlines,vlines,p0)
%   estimates the longitudinal dispersion coefficient (KL) and an
%   equivalent line-volume delay parameter (dt) by fitting a modified
%   analytical solution of the Advection-Dispersion Equation (ADE) to
%   experimental breakthrough-curve data using weighted nonlinear least
%   squares.
%
%   The fitting procedure accounts for measurement uncertainty through
%   weighted regression and provides uncertainty estimates for the fitted
%   parameters using covariance-based error propagation.
%
%   INPUTS
%       C         : Measured concentration data
%
%       dCi       : Concentration uncertainty (standard deviation or error)
%                   associated with each measurement
%
%       t         : Time vector [s]
%
%       u         : Average linear velocity [m/s]
%
%       Cj        : Concentration step amplitude
%
%       Ci        : Initial/background concentration
%
%       L         : Core length or transport distance [m]
%
%       KLlines   : Dispersion coefficient associated with the upstream
%                   line volume (currently not used in active model)
%
%       vlines    : Average velocity in tubing/line volume [m/s]
%
%       p0        : Initial parameter guess
%
%                   p0(1) = sqrt(KL)
%                   p0(2) = dt
%
%   OUTPUT
%       out       : Structure containing fitted parameters and statistics
%
%           out.KL     : Fitted longitudinal dispersion coefficient
%                        [m^2/s]
%
%           out.dKL    : Uncertainty of KL [m^2/s]
%
%           out.dt     : Fitted line-delay parameter [s]
%
%           out.ddt    : Uncertainty of dt [s]
%
%           out.p      : Fitted parameter vector
%
%           out.CovB   : Parameter covariance matrix
%
%           out.res    : Residual vector
%
%           out.J      : Regression Jacobian
%
%   MODEL DESCRIPTION
%       The fitted concentration profile is:
%
%           C(t) = Ci + (Cj/2) * erfc(arg)
%
%       where
%
%           arg =
%           (L - u*t + vlines*dt)
%           --------------------------------
%           2*sqrt(KL)*sqrt(t)
%
%       and
%
%           KL = p(1)^2
%           dt = p(2)
%
%       The term vlines*dt represents an effective transport length
%       associated with experimental tubing or dead volume upstream of
%       the core.
%
%   WEIGHTED REGRESSION
%       Parameters are estimated using MATLAB's NLINFIT function with
%       inverse-error weighting:
%
%           weight = 1./dCi
%
%       giving greater influence to measurements with lower uncertainty.
%
%   UNCERTAINTY PROPAGATION
%       Parameter uncertainties are obtained from the covariance matrix
%       returned by NLINFIT.
%
%       Since:
%
%           KL = p1^2
%
%       its uncertainty is propagated as:
%
%           dKL = 2*p1*dp1
%
%       where dp1 is the standard error of p1.
%
%   NOTES
%       - KL is constrained to positive values through the transformation
%         KL = p(1)^2.
%       - Numerical safeguards prevent singularities at t = 0.
%       - Intended for fitting tracer breakthrough curves from core-flood
%         and dispersion experiments.
%       - Returns both fitted parameters and regression diagnostics for
%         further analysis.
%
%   EXAMPLE
%       p0 = [sqrt(1e-7), 50];
%
%       out = fit_dispersion_dt_lines_error(C,...
%                                           dCi,...
%                                           t,...
%                                           u,...
%                                           Cj,...
%                                           Ci,...
%                                           L,...
%                                           KLlines,...
%                                           vlines,...
%                                           p0);
%
%   See also NLINFIT, NLPARCI, ERFC.

    % Model
    C_model = @(p,t) Ci + (Cj/2).*erfc( ...
        (L - u.*t + vlines.*p(2)) ./ (2*p(1).*sqrt(max(t,eps))) );

    % % Model KL lines
    % C_model = @(p,t) Ci + (Cj/2).*erfc( ...
    %     (L - u.*t + vlines.*p(2)) ./ (2*(p(1).*sqrt(max(t,eps)))-sqrt(max(KLlines.*p(2),eps))) );

    %C_function = @(p,t)(Ci + (Cj/2)*erfc((L-u.*(t-p(2)))./(2*(max((t-p(2)),eps).^(1/2)).*p(1)))); % dt numerator and denominator


   % Weighted fit
    opts = statset('nlinfit');
    [p_est,res,J,CovB,mse] = nlinfit(t, C, C_model, p0, opts, ...
                                     'Weights', 1./dCi);

    % Extract parameters
    KL = p_est(1)^2;
    dt = p_est(2);

    % Uncertainty propagation
    % Covariance of p_est is CovB
    dKL = 2*p_est(1) * sqrt(CovB(1,1));   % via derivative d(KL)/dp1 = 2*p1
    ddt = sqrt(CovB(2,2));

    % Package output
    out.KL = KL;
    out.dKL = dKL;
    out.dt = dt;
    out.ddt = ddt;
    out.p = p_est;
    out.CovB = CovB;
    out.res = res;
    out.J = J;

end
