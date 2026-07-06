function G = impulse_from_step(t, L, v, D)

%IMPULSE_FROM_STEP Compute impulse response from an Ogata-Banks step response.
%
%   G = IMPULSE_FROM_STEP(T,L,V,D) computes the impulse response function
%   associated with one-dimensional advection-dispersion transport by
%   differentiating a unit-step Ogata-Banks breakthrough curve.
%
%   The impulse response represents the residence-time distribution (RTD)
%   of the system and describes the concentration response to an
%   instantaneous tracer injection.
%
%   INPUTS
%       t    : Time vector [s]
%
%       L    : Transport distance or core length [m]
%
%       v    : Average interstitial velocity [m/s]
%
%       D    : Longitudinal dispersion coefficient [m^2/s]
%
%   OUTPUT
%       G    : Impulse response function evaluated at times t
%
%   MODEL DESCRIPTION
%       The impulse response is obtained as the time derivative of the
%       corresponding unit-step breakthrough curve:
%
%           G(t) = dC(t)/dt
%
%       where:
%
%           C(t) = ob_step(t,L,v,D,1)
%
%       is the Ogata-Banks solution for a unit step input.
%
%   NUMERICAL IMPLEMENTATION
%       The derivative is approximated using finite differences:
%
%           G ~= diff(Cstep)/dt
%
%       where:
%
%           dt = t(2) - t(1)
%
%       and Cstep is the unit-step response.
%
%       Negative values introduced by numerical differentiation are
%       removed:
%
%           G(G < 0) = 0
%
%       to suppress small numerical oscillations and preserve a
%       physically meaningful impulse response.
%
%   PHYSICAL INTERPRETATION
%       The resulting function can be interpreted as:
%
%           - Residence-time distribution (RTD)
%           - Tracer arrival-time distribution
%           - Green's function for ADE transport
%
%       and can be used for convolution-based transport modeling and
%       breakthrough-curve reconstruction.
%
%   NOTES
%       - Assumes a uniformly spaced time vector.
%       - Requires the function OB_STEP.
%       - Numerical differentiation may introduce small negative values,
%         which are removed automatically.
%       - Intended for tracer transport, dispersion, and RTD analyses.
%
%   EXAMPLE
%       t = linspace(0,5000,1000);
%
%       G = impulse_from_step(t,...
%                             0.3,...
%                             1e-4,...
%                             1e-7);
%
%       plot(t,G)
%       xlabel('Time (s)')
%       ylabel('Impulse Response')
%
%   See also OB_STEP, DIFF.
    % Impulse response = derivative of step response
    Cstep = ob_step(t, L, v, D, 1);   % unit step
    dt = t(2) - t(1);

    G = [Cstep(1); diff(Cstep)] / dt;
    G(G < 0) = 0;   % clean numerical noise
end

