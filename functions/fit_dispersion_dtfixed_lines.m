function [KL,dt_fit, u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion_dtfixed_lines(C,t,u,Cj,Ci,L,vlines,KLlines,dt,p)

%FIT_DISPERSION_DTFIXED_LINES Fit KL with a fixed line-volume delay.
%
%   [KL,DT_FIT,U_FIT,CJ_FIT,CI_FIT,C_FIT] =
%   FIT_DISPERSION_DTFIXED_LINES(C,T,U,CJ,CI,L,...
%                                VLINES,KLLINES,DT,P)
%   estimates the longitudinal dispersion coefficient (KL) from
%   breakthrough-curve data while keeping the delay parameter (dt) fixed.
%
%   This formulation is useful when the upstream dead volume or tubing
%   delay has been estimated independently and should not be included as
%   an adjustable fitting parameter.
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
%       vlines   : Average velocity in upstream tubing/line volume [m/s]
%
%       KLlines  : Dispersion coefficient associated with line volume
%                  [m²/s] (currently not used in the active model)
%
%       dt       : Fixed breakthrough-delay parameter [s]
%
%       p        : Initial parameter guess
%
%                  p(1) = sqrt(KL)
%
%   OUTPUTS
%       KL       : Fitted longitudinal dispersion coefficient [m²/s]
%
%       dt_fit   : Fixed delay parameter returned for completeness [s]
%
%       u_fit    : Velocity used during fitting [m/s]
%
%       Cj_fit   : Boundary concentration used during fitting
%
%       Ci_fit   : Initial concentration used during fitting
%
%       C_fit    : MATLAB NonLinearModel object returned by FITNLM
%
%   MODEL DESCRIPTION
%       The fitted concentration profile is:
%
%           C(t) = Ci + (Cj/2)*erfc(arg)
%
%       where
%
%                    L - u*t + vlines*dt
%           arg = -------------------------
%                  2*sqrt(KL)*sqrt(t)
%
%       and
%
%           KL = p(1)^2
%
%       The term:
%
%           vlines*dt
%
%       represents an equivalent transport distance associated with
%       tubing, fittings, manifolds, and other extra-core volumes.
%
%   FITTING PROCEDURE
%       Only one parameter is optimized:
%
%           p(1) = sqrt(KL)
%
%       using MATLAB's FITNLM nonlinear regression routine.
%
%       The transformation:
%
%           KL = p(1)^2
%
%       ensures physically meaningful positive dispersion coefficients.
%
%   NOTES
%       - Only KL is fitted.
%       - dt remains fixed throughout the optimization.
%       - Velocity (u), concentrations (Ci and Cj), and transport length
%         (L) are treated as known inputs.
%       - Numerical safeguards are used through MAX(t,eps).
%       - Suitable for sensitivity studies and analyses where line-volume
%         delays have already been independently characterized.
%
%   EXAMPLE
%       dt = 120;          % s
%       p0 = sqrt(1e-7);
%
%       [KL,dt_fit,~,~,~,mdl] = ...
%           fit_dispersion_dtfixed_lines(C,...
%                                        t,...
%                                        u,...
%                                        Cj,...
%                                        Ci,...
%                                        L,...
%                                        vlines,...
%                                        KLlines,...
%                                        dt,...
%                                        p0);
%
%   See also FITNLM, FIT_DISPERSION_DTFIXED_LINES_ERROR,
%            FIT_DISPERSION_DT_LINES.

C_function = @(p,t) Ci + (Cj/2) .* erfc(( L - u.*t + vlines.*dt ) ./( 2 * p(1) .* sqrt(max(t,eps)) ) );

C_fit = fitnlm(t,C,C_function,p);
p(1) = C_fit.Coefficients.Estimate(1);

KL = p(1)^2;
dt_fit = dt;
u_fit = u;
Cj_fit = Cj;
Ci_fit = Ci;
        
end