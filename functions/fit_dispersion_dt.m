function [KL,dt_fit, u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion_dt(C,t,u,Cj,Ci,L,p)

%FIT_DISPERSION_DT Fit a time-shifted ADE breakthrough curve.
%
%   [KL,DT_FIT,U_FIT,CJ_FIT,CI_FIT,C_FIT] =
%   FIT_DISPERSION_DT(C,T,U,CJ,CI,L,P)
%   estimates the longitudinal dispersion coefficient (KL) and a
%   breakthrough time-shift parameter (dt) by fitting the analytical
%   solution of the one-dimensional Advection-Dispersion Equation (ADE)
%   to experimental breakthrough-curve data.
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
%       p      : Initial parameter guess
%
%                p(1) = sqrt(KL)
%                p(2) = dt
%
%   OUTPUTS
%       KL      : Fitted longitudinal dispersion coefficient [m^2/s]
%
%       dt_fit  : Fitted breakthrough time shift [s]
%
%       u_fit   : Velocity used during fitting [m/s]
%
%       Cj_fit  : Boundary concentration used during fitting
%
%       Ci_fit  : Initial concentration used during fitting
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
%           dt = p(2)
%
%       The parameter dt represents an effective delay caused by tubing,
%       dead volume, fittings, or other experimental components located
%       upstream of the core.
%
%   FITTING PROCEDURE
%       Parameters are estimated using MATLAB's FITNLM nonlinear
%       regression routine.
%
%       The transformation:
%
%           KL = p(1)^2
%
%       guarantees positive dispersion coefficients during optimization.
%
%   NOTES
%       - Only KL and dt are fitted.
%       - Velocity (u), concentration levels (Ci and Cj), and transport
%         distance (L) remain fixed.
%       - Uses MAX(t-dt,eps) to avoid singularities near breakthrough.
%       - Implements the simplified ADE analytical solution containing a
%         single complementary error function term.
%       - No uncertainty estimates or confidence intervals are returned.
%         For uncertainty quantification, use
%         FIT_DISPERSION_DT_NLINFIT.
%
%   EXAMPLE
%       p0 = [sqrt(1e-7), 100];
%
%       [KL,dt,~,~,~,mdl] = ...
%           fit_dispersion_dt(C,...
%                             t,...
%                             u,...
%                             Cj,...
%                             Ci,...
%                             L,...
%                             p0);
%
%   See also FITNLM, FIT_DISPERSION_DT_NLINFIT,
%            ADE_SHORT_DT_SHIFT.

C_function = @(p,t)(Ci + (Cj/2)*erfc((L-u.*(t-p(2)))./(2*(max((t-p(2)),eps).^(1/2)).*p(1)))); % dt numerator and denominator

C_fit = fitnlm(t,C,C_function,p);
p(1) = C_fit.Coefficients.Estimate(1);
p(2) = C_fit.Coefficients.Estimate(2);

KL = p(1)^2;
dt_fit = p(2);
u_fit = u;
Cj_fit = Cj;
Ci_fit = Ci;
        
end