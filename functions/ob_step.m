function C = ob_step(t, L, v, D, C0)

%OB_STEP Evaluate the Ogata-Banks step-input solution.
%
%   C = OB_STEP(T,L,V,D,C0) computes the one-dimensional analytical
%   advection-dispersion equation (ADE) solution for a step-change tracer
%   injection at a distance L using the classical Ogata-Banks solution.
%
%   The function returns the concentration breakthrough curve resulting
%   from a constant concentration boundary condition applied at the inlet.
%
%   INPUTS
%       t
%           Time vector [s]
%
%       L
%           Transport distance or core length [m]
%
%       v
%           Average interstitial velocity [m/s]
%
%       D
%           Longitudinal dispersion coefficient [m^2/s]
%
%       C0
%           Step-input concentration amplitude
%
%   OUTPUT
%       C
%           Predicted concentration breakthrough curve
%
%   MODEL DESCRIPTION
%       The Ogata-Banks solution for a step input is:
%
%           C(t) = (C0/2) *
%                  erfc((L-vt)/(2*sqrt(Dt)))
%
%       where:
%
%           C0 = injected concentration
%           L  = transport distance
%           v  = average velocity
%           D  = longitudinal dispersion coefficient
%
%       The solution describes the concentration response produced by a
%       semi-infinite step injection under one-dimensional advection and
%       dispersion.
%
%   IMPLEMENTATION
%       Concentrations are only evaluated for:
%
%           t > 0
%
%       while:
%
%           C = 0
%
%       for t <= 0.
%
%       The reflected-boundary correction term from the full
%       Ogata-Banks solution:
%
%           exp(vL/D)*erfc((L+vt)/(2*sqrt(Dt)))
%
%       is currently omitted.
%
%   PHYSICAL INTERPRETATION
%       The breakthrough curve represents the cumulative tracer arrival
%       at distance L, accounting for:
%
%           - Advective transport
%           - Longitudinal dispersion
%
%       and serves as the step-response function of the transport system.
%
%   APPLICATIONS
%       This function is commonly used for:
%
%           - Breakthrough-curve prediction
%           - Dispersion-coefficient estimation
%           - Residence-time distribution analysis
%           - Generation of impulse responses through differentiation
%           - Convolution-based transport modeling
%
%   NOTES
%       - Implements the simplified Ogata-Banks formulation.
%       - Uses only the primary complementary-error-function term.
%       - Assumes one-dimensional transport in a homogeneous medium.
%       - Intended for tracer and dispersion experiments in porous media.
%
%   EXAMPLE
%       t = linspace(0,5000,1000);
%
%       C = ob_step(t,...
%                   0.3,...
%                   1e-4,...
%                   1e-7,...
%                   1);
%
%       plot(t,C)
%       xlabel('Time (s)')
%       ylabel('Normalized Concentration')
%
%   See also IMPULSE_FROM_STEP, ERFC.

    % Ogata–Banks step solution at x = L
    C = zeros(size(t));
    idx = t > 0;
    tt  = t(idx);

    term1 = erfc((L - v*tt) ./ (2*sqrt(D*tt)));
    % term2 = exp(v*L/D) .* erfc((L + v*tt) ./ (2*sqrt(D*tt)));

    C(idx) = C0 * 0.5 .* (term1);
end
