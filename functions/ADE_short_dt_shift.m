function C = ADE_short_dt_shift(p,t,u,Cj,Ci,L)

    %ADE_SHORT_DT_SHIFT Simplified ADE solution with breakthrough time shift.
    %
    %   C = ADE_SHORT_DT_SHIFT(P,T,U,CJ,CI,L) computes the one-dimensional
    %   analytical solution of the Advection-Dispersion Equation (ADE) for a
    %   step-change tracer injection at a distance L using the simplified
    %   (short) ADE formulation. A time-shift correction (DT) is included to
    %   account for upstream dead volume or experimental tubing volumes that
    %   delay the observed breakthrough curve.
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
    %       This function evaluates the simplified analytical ADE solution:
    %
    %           C = Ci + (Cj/2) * erfc(arg)
    %
    %       where
    %
    %           arg = (L - u*(t-DT))
    %                 / (2*sqrt(KL*(t-DT)))
    %
    %       and
    %
    %           KL = p(1)^2.
    %
    %       The time-shift parameter DT corrects for delays caused by
    %       experimental dead volume (e.g., tubing, fittings, distribution
    %       manifolds, or other extra-core volumes) that are not explicitly
    %       represented in the transport model.
    %
    %       Unlike ADE_FULL_DT_SHIFT, this formulation neglects the second
    %       complementary error function term and exponential correction,
    %       making it suitable when the simplified ADE approximation is
    %       considered adequate.
    %
    %   NOTES
    %       - The fitted parameters are KL and DT.
    %       - Velocity (u), concentration levels (Ci, Cj), and core length (L)
    %         are fixed inputs.
    %       - Numerical safeguards are used to prevent singularities when
    %         t <= DT.
    %       - Intended for fitting tracer breakthrough curves from core-flood
    %         and dispersion experiments.
    %       - Provides a computationally simpler alternative to the full ADE
    %         analytical solution.
    %
    %   EXAMPLE
    %       p = [0.05, 30];
    %       C = ADE_short_dt_shift(p,t,u,Cj,Ci,L);
    %
    %   See also ADE_FULL_DT_SHIFT, ERFC.

    % enforce safe parameters
    dt = p(2);
    denom = 2.*(max(t - dt,eps).^(1/2)).* p(1);
    arg = (L-u.*(t - dt))./ denom;

    % short ADE function
    C = Ci + (Cj/2) * erfc(arg);
end
