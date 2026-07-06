function out = fit_dispersion_dtfixed_lines_error(C,dCi, t,u,Cj,Ci,L,KLlines,vlines,dt_fixed,p0)

%FIT_DISPERSION_DTFIXED_LINES_ERROR Fit KL with fixed line-delay correction.
%
%   OUT = FIT_DISPERSION_DTFIXED_LINES_ERROR(C,dCi,T,U,CJ,CI,L,...
%                                            KLLINES,VLINES,...
%                                            DT_FIXED,P0)
%   estimates the longitudinal dispersion coefficient (KL) by fitting an
%   analytical ADE breakthrough-curve model while keeping the line-delay
%   parameter (dt) fixed to a prescribed value.
%
%   This function is useful when an independent estimate of the upstream
%   dead volume or tubing delay is available and only the dispersion
%   coefficient remains unknown.
%
%   INPUTS
%       C         : Measured concentration data
%
%       dCi       : Concentration uncertainty associated with each
%                   measurement
%
%       t         : Time vector [s]
%
%       u         : Average interstitial velocity [m/s]
%
%       Cj        : Concentration step amplitude
%
%       Ci        : Initial/background concentration
%
%       L         : Core length or transport distance [m]
%
%       KLlines   : Dispersion coefficient associated with tubing or
%                   line volume [m^2/s]
%                   (currently not used in the active model)
%
%       vlines    : Average velocity in tubing/line volume [m/s]
%
%       dt_fixed  : Fixed breakthrough-delay parameter [s]
%
%       p0        : Initial parameter guess
%
%                   p0(1) = sqrt(KL)
%
%   OUTPUT
%       out       : Structure containing fitted parameters and regression
%                   diagnostics.
%
%       out.KL    : Fitted longitudinal dispersion coefficient [m^2/s]
%
%       out.dKL   : Uncertainty in KL [m^2/s]
%
%       out.dt    : Fixed delay parameter [s]
%
%       out.ddt   : Delay uncertainty (= 0 because dt is fixed)
%
%       out.p     : Fitted parameter vector
%
%       out.CovB  : Parameter covariance matrix
%
%       out.res   : Residual vector
%
%       out.J     : Regression Jacobian
%
%   MODEL DESCRIPTION
%       The fitted breakthrough-curve model is:
%
%           C(t) = Ci + (Cj/2)*erfc(arg)
%
%       where
%
%                    L - u*t + vlines*dt_fixed
%           arg = --------------------------------
%                  2*sqrt(KL)*sqrt(t)
%
%       and
%
%           KL = p(1)^2
%
%       The term vlines*dt_fixed represents a known transport distance
%       associated with upstream tubing, fittings, manifolds, or other
%       extra-core volumes.
%
%   FITTING PROCEDURE
%       Parameters are estimated using MATLAB's NLINFIT routine with
%       weighted nonlinear least squares.
%
%       Measurement weights are defined as:
%
%           w = 1./dCi
%
%       so observations with lower uncertainty receive greater weight
%       during optimization.
%
%   UNCERTAINTY ESTIMATION
%       The fitted parameter is:
%
%           KL = p1^2
%
%       with uncertainty propagated from the covariance matrix:
%
%           dKL = 2*p1*dp1
%
%       where dp1 is the standard error of p1.
%
%       Since dt is prescribed and not optimized:
%
%           ddt = 0
%
%   NOTES
%       - Only KL is fitted.
%       - dt remains fixed throughout the regression.
%       - KL is constrained to positive values through the
%         transformation KL = p(1)^2.
%       - Intended for sensitivity studies and situations where the
%         line-volume delay has been independently characterized.
%
%   EXAMPLE
%       dt_fixed = 120;      % s
%       p0 = sqrt(1e-7);
%
%       out = fit_dispersion_dtfixed_lines_error(C,...
%                                                dCi,...
%                                                t,...
%                                                u,...
%                                                Cj,...
%                                                Ci,...
%                                                L,...
%                                                KLlines,...
%                                                vlines,...
%                                                dt_fixed,...
%                                                p0);
%
%   See also NLINFIT, FIT_DISPERSION_DT_LINES_ERROR.
    % p0 now contains only p(1) = sqrt(KL)
    C_model = @(p,t) Ci + (Cj/2).*erfc( ...
        (L - u.*t + vlines.*dt_fixed) ./ (2*p(1).*sqrt(max(t,eps))) );

    % % Model KL lines
    % C_model = @(p,t) Ci + (Cj/2).*erfc( ...
    %     (L - u.*t + vlines.*dt_fixed) ./ (2*(p(1).*sqrt(max(t,eps)))-sqrt(max(KLlines.*dt_fixed,eps))) );

    opts = statset('nlinfit');
    [p_est,res,J,CovB,mse] = nlinfit(t, C, C_model, p0, opts, ...
                                     'Weights', 1./dCi);

    KL = p_est(1)^2;
    dKL = 2*p_est(1) * sqrt(CovB(1,1));

    out.KL = KL;
    out.dKL = dKL;
    out.dt = dt_fixed;
    out.ddt = 0;   % fixed parameter → no uncertainty
    out.p = p_est;
    out.CovB = CovB;
    out.res = res;
    out.J = J;
end
