function [KL,dt_fit, u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion_dt2(C,t,u,Cj,Ci,L,p)

%FIT_DISPERSION_DT2 Fit Ogata-Banks breakthrough curve with time delay.
%
%   [KL,DT_FIT,U_FIT,CJ_FIT,CI_FIT,C_FIT] =
%   FIT_DISPERSION_DT2(C,T,U,CJ,CI,L,P)
%   estimates the longitudinal dispersion coefficient (KL) and a
%   breakthrough time-delay parameter (dt) by fitting an Ogata-Banks
%   analytical solution to measured tracer breakthrough-curve data.
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
%       dt_fit  : Fitted breakthrough time delay [s]
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
%       The model evaluates a time-shifted Ogata-Banks solution:
%
%           ts = t - dt
%
%       For ts > 0:
%
%           C(ts) = Ci +
%                   (Cj/2) *
%                   erfc( (L-u*ts)
%                        /(2*sqrt(KL*ts)) )
%
%       where:
%
%           KL = p(1)^2
%
%           dt = p(2)
%
%       For t <= dt:
%
%           C = Ci
%
%       This formulation assumes that breakthrough cannot occur before
%       the delayed arrival time.
%
%   FITTING PROCEDURE
%       Parameters are estimated using FITNLM.
%
%       The function performs five consecutive fitting iterations,
%       updating the initial guess after each regression:
%
%           p(1) <- fitted sqrt(KL)
%           p(2) <- fitted dt
%
%       to improve convergence when the initial guess is far from the
%       optimal solution.
%
%   NOTES
%       - KL is constrained to positive values through:
%
%             KL = p(1)^2
%
%       - The current implementation uses only the primary
%         Ogata-Banks error-function term.
%       - The second reflected-boundary term is intentionally disabled.
%       - Concentration remains equal to Ci before breakthrough
%         (t <= dt).
%       - Intended for fitting tracer breakthrough curves in
%         core-flood and dispersion experiments.
%
%   EXAMPLE
%       p0 = [sqrt(1e-7), 100];
%
%       [KL,dt,~,~,~,mdl] = ...
%           fit_dispersion_dt2(C,...
%                              t,...
%                              u,...
%                              Cj,...
%                              Ci,...
%                              L,...
%                              p0);
%
%   See also FITNLM, ERFC.


    C_function = @(p,t) OBsolution(p,t,Ci,Cj,L,u);

    for i = 1:5

        C_fit = fitnlm(t,C,C_function,p);
    
        p(1) = C_fit.Coefficients.Estimate(1);
        p(2) = C_fit.Coefficients.Estimate(2);
    
        KL     = p(1)^2;
        dt_fit = p(2);
        u_fit  = u;
        Cj_fit = Cj;
        Ci_fit = Ci;
    end
end


function C = OBsolution(p,t,Ci,Cj,L,u)
    KL_sqrt = p(1);      % sqrt(KL)
    dt      = p(2);      % time delay

    ts = t - dt;         % shifted time
    C  = Ci * ones(size(t));

    mask = ts > 0;
    ts_pos = ts(mask);

    % --- Ogata–Banks term 1 ---
    arg1 = (L - u.*ts_pos) ./ (2 * KL_sqrt .* sqrt(ts_pos));

    % --- Ogata–Banks term 2 ---
    arg2 = 0;%(L + u.*ts_pos) ./ (2 * KL_sqrt .* sqrt(ts_pos));
    exp_term = 0;%exp(u*L/(KL_sqrt^2));

    % Full OB step solution
    C(mask) = Ci + (Cj/2) .* ( erfc(arg1) + exp_term .* erfc(arg2) );
end
