function C = ADE_full_dt_shift(p,t,u,Cj,Ci,L)
    
    %ADE_FULL_DT_SHIFT Full analytical ADE solution with breakthrough time shift.
    %
    %   C = ADE_FULL_DT_SHIFT(P,T,U,CJ,CI,L) computes the one-dimensional
    %   analytical solution of the Advection-Dispersion Equation (ADE) for a
    %   step-change tracer injection at a distance L. The model includes a
    %   time-shift correction (DT) to account for upstream dead volume or
    %   experimental tubing volumes that delay the measured breakthrough curve.
    %
    %   INPUTS
    %       p(1) : Dispersion parameter, where KL = p(1)^2
    %       p(2) : Time-shift correction, DT [s]
    %       t    : Time vector [s]
    %       u    : Average linear velocity [L/T]
    %       Cj   : Concentration step amplitude
    %       Ci   : Initial/background concentration
    %       L    : Core length or transport distance [L]
    %
    %   OUTPUT
    %       C    : Predicted concentration breakthrough curve
    %
    %   MODEL DESCRIPTION
    %       This function evaluates the full analytical ADE solution:
    %
    %           C = Ci + (Cj/2) * [ erfc(arg1)
    %                             + exp(u*L/KL)*erfc(arg2) ]
    %
    %       where
    %
    %           arg1 = (L - u*(t-DT)) / (2*sqrt(KL*(t-DT)))
    %           arg2 = (L + u*(t-DT)) / (2*sqrt(KL*(t-DT)))
    %
    %       and KL = p(1)^2.
    %
    %       The time-shift parameter DT corrects for delays caused by
    %       experimental dead volume (e.g., tubing, fittings, distribution
    %       manifolds, or other extra-core volumes) that are not explicitly
    %       represented in the transport model.
    %
    %   NOTES
    %       - The fitted parameters are KL and DT.
    %       - Velocity (u), concentration levels (Ci, Cj), and core length (L)
    %         are fixed inputs.
    %       - Numerical safeguards are used to prevent singularities when
    %         t <= DT.
    %       - Intended for fitting tracer breakthrough curves from core-flood
    %         and dispersion experiments.
    %
    %   EXAMPLE
    %       p = [0.05, 30];
    %       C = ADE_full_dt_shift(p,t,u,Cj,Ci,L);
    %
    %   See also ERFC.

    % enforce safe parameters
    dt = p(2);
    denom = 2.*(max(t - dt,eps).^(1/2)).* p(1);

    % Arg two erfc terms
    arg1 = (L - u.*(t - dt)) ./ denom;
    arg2 = (L + u.*(t - dt)) ./ denom;

    % exp term
    % KL = p1^2 → u*L/KL = u*L/p1^2
    exp_term = exp(u*L/(p(1)^2)); 

    % full ADE function
    C = Ci + (Cj/2) .* (erfc(arg1) + exp_term .* erfc(arg2));
end
