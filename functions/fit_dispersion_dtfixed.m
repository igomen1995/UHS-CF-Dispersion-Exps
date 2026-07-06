function [KL,dt_fit, u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion_dtfixed(C,t,u,Cj,Ci,L,dt,p)

%FIT_DISPERSION_DTFIXED Fit an ADE breakthrough curve with fixed time delay.
%
%   [KL,DT_FIT,U_FIT,CJ_FIT,CI_FIT,C_FIT] =
%   FIT_DISPERSION_DTFIXED(C,T,U,CJ,CI,L,DT,P)
%   estimates the longitudinal dispersion coefficient (KL) from
%   experimental breakthrough-curve data while keeping the breakthrough
%   time-delay parameter (dt) fixed.
%
%   This function is useful when the delay associated with upstream dead
%   volume, tubing, fittings, or experimental infrastructure has been
%   independently estimated and should not be included as a fitting
%   parameter.
%
%   INPUTS
%       C      : Measured concentration vector
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
%       dt     : Fixed breakthrough time shift [s]
%
%       p      : Initial parameter guess
%
%                p(1) = sqrt(KL)
%
%   OUTPUTS
%       KL      : Fitted longitudinal dispersion coefficient [m^2/s]
%
%       dt_fit  : Fixed delay parameter returned for completeness [s]
%
%       u_fit   : Velocity used in the fit [m/s]
%
%       Cj_fit  : Boundary concentration used in the fit
%
%       Ci_fit  : Initial concentration used in the fit
%
%       C_fit   : MATLAB NonLinearModel object returned by FITNLM
%
%   MODEL DESCRIPTION
%       The fitted concentration profile is:
%
%           C(t) =
%               Ci
%               + (Cj/2)
%               * erfc( (L-u(t-dt))
%                      /(2*sqrt(KL*(t-dt))) )
%
%       where:
%
%           KL = p(1)^2
%
%       and dt is prescribed and remains fixed during optimization.
%
%       The time-shift correction accounts for tracer travel through
%       upstream dead volumes that are not explicitly represented in the
%       advection-dispersion model.
%
%   FITTING PROCEDURE
%       The parameter:
%
%           p(1) = sqrt(KL)
%
%       is estimated using MATLAB's FITNLM nonlinear regression routine.
%
%       The transformation:
%
%           KL = p(1)^2
%
%       guarantees positive fitted dispersion coefficients.
%
%   NOTES
%       - Only KL is fitted.
%       - dt remains fixed throughout the regression.
%       - Velocity (u), concentration levels (Ci and Cj), and transport
%         distance (L) are treated as known inputs.
%       - Uses MAX(t-dt,eps) to avoid numerical singularities near
%         breakthrough.
%       - Implements the simplified ADE analytical solution containing a
%         single complementary error function term.
%       - For uncertainty estimates and confidence intervals, use
%         FIT_DISPERSION_DTFIXED_NLINFIT.
%
%   EXAMPLE
%       dt = 120;          % s
%       p0 = sqrt(1e-7);
%
%       [KL,dt_fit,~,~,~,mdl] = ...
%           fit_dispersion_dtfixed(C,...
%                                  t,...
%                                  u,...
%                                  Cj,...
%                                  Ci,...
%                                  L,...
%                                  dt,...
%                                  p0);
%
%   See also FITNLM, FIT_DISPERSION_DTFIXED_NLINFIT,
%            ADE_SHORT_DT_SHIFT.

C_function = @(p,t)(Ci + (Cj/2)*erfc((L-u.*(t-dt))./(2*(max((t-dt),eps).^(1/2)).*p(1)))); % dt numerator and denominator

C_fit = fitnlm(t,C,C_function,p);
p(1) = C_fit.Coefficients.Estimate(1);

KL = p(1)^2;
dt_fit = dt;
u_fit = u;
Cj_fit = Cj;
Ci_fit = Ci;
        
end