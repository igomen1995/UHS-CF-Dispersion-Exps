function Cout = three_segment_model(t, Dcore, ...
                                    Q, Aup, Acore, phi, Adown, ...
                                    Lup, Lc, Ldown, ...
                                    Dup, Ddown, C0)

%THREE_SEGMENT_MODEL Simulate transport through upstream, core, and downstream sections.
%
%   COUT = THREE_SEGMENT_MODEL(T,DCORE,...
%                              Q,AUP,ACORE,PHI,ADOWN,...
%                              LUP,LC,LDOWN,...
%                              DUP,DDOWN,C0)
%   computes the outlet breakthrough curve of a flow system represented
%   as three transport segments connected in series:
%
%       1. Upstream tubing/manifold section
%       2. Porous core section
%       3. Downstream tubing/manifold section
%
%   Advection-dispersion transport in each segment is represented using
%   analytical Ogata-Banks solutions. The overall response is obtained
%   through convolution of the corresponding impulse-response functions.
%
%   INPUTS
%       t
%           Time vector [s]
%
%       Dcore
%           Longitudinal dispersion coefficient in the core [m^2/s]
%
%       Q
%           Volumetric flow rate [m^3/s]
%
%       Aup
%           Cross-sectional area of the upstream section [m^2]
%
%       Acore
%           Core cross-sectional area [m^2]
%
%       phi
%           Core porosity [-]
%
%       Adown
%           Cross-sectional area of the downstream section [m^2]
%
%       Lup
%           Upstream transport length [m]
%
%       Lc
%           Core length [m]
%
%       Ldown
%           Downstream transport length [m]
%
%       Dup
%           Dispersion coefficient in the upstream section [m^2/s]
%
%       Ddown
%           Dispersion coefficient in the downstream section [m^2/s]
%
%       C0
%           Step-input concentration
%
%   OUTPUT
%       Cout
%           Predicted outlet concentration breakthrough curve
%
%   MODEL DESCRIPTION
%       The system is represented as:
%
%           Upstream ---> Core ---> Downstream
%
%       with transport occurring sequentially through each section.
%
%       Superficial/interstitial velocities are calculated from:
%
%           v_up   = Q / Aup
%
%           v_core = Q / (Acore*phi)
%
%           v_down = Q / Adown
%
%       where the porosity correction is applied only to the porous core.
%
%   SOLUTION APPROACH
%       Step 1:
%           Compute the upstream step response:
%
%               Cup = ob_step(...)
%
%       Step 2:
%           Compute the core impulse response:
%
%               Gcore = impulse_from_step(...)
%
%       Step 3:
%           Propagate the tracer through the core using convolution:
%
%               Ccore = Cup * Gcore
%
%       Step 4:
%           Compute the downstream impulse response:
%
%               Gdown = impulse_from_step(...)
%
%       Step 5:
%           Propagate the signal through the downstream section:
%
%               Cout = Ccore * Gdown
%
%       where "*" denotes convolution.
%
%   PHYSICAL INTERPRETATION
%       The upstream and downstream regions account for transport in
%       tubing, fittings, manifolds, and other extra-core volumes,
%       while the core section represents transport within the porous
%       medium.
%
%       This model therefore captures:
%
%           - Dead-volume effects
%           - Tubing dispersion
%           - Core dispersion
%           - Residence-time broadening
%
%       within a unified framework.
%
%   NUMERICAL IMPLEMENTATION
%       Convolutions are evaluated numerically using:
%
%           conv(...)
%
%       and scaled by:
%
%           dt = t(2) - t(1)
%
%       to approximate the continuous convolution integral.
%
%   ASSUMPTIONS
%       - One-dimensional transport.
%       - Constant flow rate.
%       - Constant transport properties.
%       - Uniform cross-sectional areas within each segment.
%       - Ogata-Banks transport behavior in all regions.
%       - Uniformly spaced time vector.
%
%   APPLICATIONS
%       - Core-flood breakthrough-curve modeling
%       - Dead-volume analysis
%       - Tubing-dispersion evaluation
%       - Residence-time-distribution studies
%       - Experimental system response simulations
%
%   EXAMPLE
%       Cout = three_segment_model(t,...
%                                  Dcore,...
%                                  Q,...
%                                  Aup,...
%                                  Acore,...
%                                  phi,...
%                                  Adown,...
%                                  Lup,...
%                                  Lc,...
%                                  Ldown,...
%                                  Dup,...
%                                  Ddown,...
%                                  1);
%
%       plot(t,Cout)
%       xlabel('Time (s)')
%       ylabel('Outlet Concentration')
%
%   See also OB_STEP, IMPULSE_FROM_STEP, CONV.

    dt = t(2) - t(1);

    % Velocities
    v_up   = Q / Aup;
    v_core = Q / (Acore * phi);
    v_down = Q / Adown;

    % --- 1) Upstream system step response ---
    Cup = ob_step(t, Lup, v_up, Dup, C0);

    % --- 2) Core impulse response ---
    Gcore = impulse_from_step(t, Lc, v_core, Dcore);

    % Convolution: upstream → core
    Ccore_in = conv(Cup, Gcore) * dt;
    Ccore_in = Ccore_in(1:numel(t));

    % --- 3) Downstream impulse response ---
    Gdown = impulse_from_step(t, Ldown, v_down, Ddown);

    % Convolution: core outlet → downstream
    Cfull = conv(Ccore_in, Gdown) * dt;
    Cout = Cfull(1:numel(t));
end

