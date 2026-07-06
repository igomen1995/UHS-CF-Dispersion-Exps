function [KL,u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion(C,t,u,Cj,Ci,L,p)

%FIT_DISPERSION Fit the classical ADE breakthrough-curve solution.
%
%   [KL,U_FIT,CJ_FIT,CI_FIT,C_FIT] =
%   FIT_DISPERSION(C,T,U,CJ,CI,L,P)
%   estimates the longitudinal dispersion coefficient (KL) by fitting the
%   analytical one-dimensional Advection-Dispersion Equation (ADE)
%   solution to experimental breakthrough-curve data.
%
%   The function assumes constant flow velocity and fixed concentration
%   boundary conditions while optimizing a single transport parameter:
%
%       KL = p^2
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
%       p      : Initial guess for sqrt(KL)
%
%   OUTPUTS
%       KL      : Fitted longitudinal dispersion coefficient [m^2/s]
%
%       u_fit   : Velocity used in fitting [m/s]
%
%       Cj_fit  : Boundary concentration used in fitting
%
%       Ci_fit  : Initial concentration used in fitting
%
%       C_fit   : MATLAB NonLinearModel object returned by FITNLM
%
%   MODEL DESCRIPTION
%       The fitted breakthrough curve is:
%
%           C(t) =
%               Ci
%               + (Cj/2)
%               * erfc( (L-u*t)
%                      /(2*sqrt(KL*t)) )
%
%       where:
%
%           KL = p^2
%
%       This corresponds to the simplified Ogata-Banks analytical
%       solution for one-dimensional advection-dispersion transport in a
%       porous medium.
%
%   FITTING PROCEDURE
%       The parameter:
%
%           p = sqrt(KL)
%
%       is estimated using MATLAB's FITNLM nonlinear regression routine.
%
%       The fitting process is repeated iteratively, updating the initial
%       parameter estimate after each regression cycle.
%
%       This iterative refinement can improve convergence when the initial
%       guess is far from the optimal solution.
%
%   NOTES
%       - Only KL is fitted.
%       - Velocity (u), concentration levels (Ci and Cj), and transport
%         distance (L) remain fixed.
%       - KL is constrained to positive values through:
%
%             KL = p^2
%
%       - This implementation does not include a breakthrough time-shift
%         correction (dt).
%       - This implementation does not estimate uncertainty, confidence
%         intervals, or prediction intervals.
%       - For experiments affected by tubing or dead-volume delays,
%         consider using FIT_DISPERSION_DT or
%         FIT_DISPERSION_DT_NLINFIT.
%
%   EXAMPLE
%       p0 = sqrt(1e-7);
%
%       [KL,u_fit,Cj_fit,Ci_fit,mdl] = ...
%           fit_dispersion(C,...
%                          t,...
%                          u,...
%                          Cj,...
%                          Ci,...
%                          L,...
%                          p0);
%
%       fprintf('KL = %.3e m^2/s\n',KL)
%
%   See also FITNLM, FIT_DISPERSION_DT,
%            FIT_DISPERSION_DT_NLINFIT.

    for i = 1:10
        
        % Cj, Ci, u not fitting, fitting p where Kl = p^2
        C_function = @(p,t)(Ci + (Cj/2)*erfc(((L-u.*t).*((t).^(1/2)))./(2*t.*p(1))));
        %C_function = @(p,t)(Cj/2)*erfc(((L-u.*t).*((t).^(1/2)))./(2*t.*p(1)))+(Cj/2)*exp(u*L/(p(1)^2)).*erfc(((L+u.*t).*((t).^(1/2)))./(2*t.*p(1)));
        C_fit = fitnlm(t,C,C_function,p);
        p = C_fit.Coefficients.Estimate;
        
        % % Cj, p, u not fitting, fitting Ci
        % C_function1 = @(Ci,t)(Ci + (Cj(1)/2)*erfc(((L-u.*t).*((t).^(1/2)))./(2*t.*p)));
        % C_fit = fitnlm(t,C,C_function1,Ci);
        % Ci = C_fit.Coefficients.Estimate;
    
        % % u, p, Ci not fitting, fitting Cj
        % C_function3 = @(Cj,t)(Ci + (Cj(1)/2)*erfc(((L-u.*t).*((t).^(1/2)))./(2*t.*p)));
        % C_fit = fitnlm(t,C,C_function3,Cj);
        % Cj = C_fit.Coefficients.Estimate;

        % % Cj, p, Ci not fitting, fitting u
        % C_function2 = @(u,t)(Ci + (Cj/2)*erfc(((L-u(1).*t).*((t).^(1/2)))./(2*t.*p)));
        % C_fit = fitnlm(t,C,C_function2,u);
        % u = C_fit.Coefficients.Estimate;
           
        % Cj, Ci, u not fitting, fitting p where Kl = p^2
        C_fit = fitnlm(t,C,C_function,p);
        p = C_fit.Coefficients.Estimate;
     
        KL = p^2;
        u_fit = u;
        Cj_fit = Cj;
        Ci_fit = Ci;
        
    end
end