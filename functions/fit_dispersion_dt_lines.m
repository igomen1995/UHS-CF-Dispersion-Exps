function [KL,dt_fit, u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion_dt_lines(C,t,u,Cj,Ci,L,vlines,KLlines,p)

%FIT_DISPERSION_DT_LINES Fit dispersion coefficient and line delay.
%
%   [KL,DT_FIT,U_FIT,CJ_FIT,CI_FIT,C_FIT] =
%   FIT_DISPERSION_DT_LINES(C,T,U,CJ,CI,L,VLINES,KLLINES,P)
%   estimates the longitudinal dispersion coefficient (KL) and an
%   equivalent line-delay parameter (dt) by fitting an analytical
%   advection-dispersion equation (ADE) breakthrough-curve model to
%   concentration measurements using nonlinear least squares.
%
%   INPUTS
%       C        : Measured concentration vector
%
%       t        : Time vector [s]
%
%       u        : Average interstitial velocity [m/s]
%
%       Cj       : Injected concentration step amplitude
%
%       Ci       : Initial/background concentration
%
%       L        : Core length or transport distance [m]
%
%       vlines   : Average velocity within upstream tubing/line volume
%                  [m/s]
%
%       KLlines  : Dispersion coefficient of line volume [m^2/s]
%                  (currently not used in the active model formulation)
%
%       p        : Initial parameter guess
%
%                  p(1) = sqrt(KL)
%                  p(2) = dt
%
%   OUTPUTS
%       KL       : Fitted longitudinal dispersion coefficient [m^2/s]
%
%       dt_fit   : Fitted delay parameter [s]
%
%       u_fit    : Velocity used in the fit [m/s]
%
%       Cj_fit   : Boundary concentration used in the fit
%
%       Ci_fit   : Initial concentration used in the fit
%
%       C_fit    : MATLAB NonLinearModel object returned by FITNLM
%
%   MODEL DESCRIPTION
%       The fitted concentration profile is:
%
%           C(t) = Ci + (Cj/2) * erfc(arg)
%
%       where
%
%                        L - u*t + vlines*dt
%           arg = --------------------------------
%                  2*sqrt(KL)*sqrt(t)
%
%       and
%
%           KL = p(1)^2
%           dt = p(2)
%
%       The quantity vlines*dt represents an equivalent transport length
%       associated with tubing, fittings, manifolds, or other upstream
%       dead-volume effects that shift the observed breakthrough curve.
%
%   FITTING PROCEDURE
%       Parameters are estimated using MATLAB's FITNLM nonlinear
%       regression routine. The fitted parameters are:
%
%           p(1) -> sqrt(KL)
%           p(2) -> dt
%
%       The transformation KL = p(1)^2 ensures positive fitted dispersion
%       coefficients.
%
%   NOTES
%       - Only KL and dt are fitted.
%       - Velocity (u), concentrations (Ci and Cj), and transport length
%         (L) remain fixed during optimization.
%       - Numerical safeguards are used near t = 0 through MAX(t,eps).
%       - Intended for tracer breakthrough-curve analysis in core-flood
%         and dispersion experiments.
%       - Returns the full nonlinear model object, allowing parameter
%         confidence intervals and goodness-of-fit statistics to be
%         computed later.
%
%   EXAMPLE
%       p0 = [sqrt(1e-7), 50];
%
%       [KL,dt,~,~,~,mdl] = ...
%           fit_dispersion_dt_lines(C,...
%                                   t,...
%                                   u,...
%                                   Cj,...
%                                   Ci,...
%                                   L,...
%                                   vlines,...
%                                   KLlines,...
%                                   p0);
%
%   See also FITNLM, ERFC.

C_function = @(p,t) Ci + (Cj/2) .* erfc(( L - u.*t + vlines.*p(2) ) ./( 2 * p(1) .* sqrt(max(t,eps)) ) );

C_fit = fitnlm(t,C,C_function,p);
p(1) = C_fit.Coefficients.Estimate(1);
p(2) = C_fit.Coefficients.Estimate(2);

KL = p(1)^2;
dt_fit = p(2);
u_fit = u;
Cj_fit = Cj;
Ci_fit = Ci;
        
end