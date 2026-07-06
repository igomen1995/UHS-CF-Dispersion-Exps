function KL_model = KL_Pe_alpha_tau_model(Pe_fromD0,D0,p)

%KL_PE_ALPHA_TAU_MODEL Dispersion model including dispersivity and tortuosity.
%
%   KL_MODEL = KL_PE_ALPHA_TAU_MODEL(PE_FROMD0,D0,P) evaluates a
%   hydrodynamic dispersion correlation that accounts for both molecular
%   diffusion through a porous medium and mechanical dispersion.
%
%   INPUTS
%       Pe_fromD0
%           Peclet number calculated using the molecular diffusion
%           coefficient D0:
%
%               Pe = uL/D0
%
%       D0
%           Molecular diffusion coefficient [m^2/s]
%
%       p
%           Model parameter vector:
%
%               p(1) = C2
%               p(2) = tau
%
%           where:
%
%               C2   = mechanical-dispersion coefficient
%               tau  = tortuosity factor
%
%   OUTPUT
%       KL_model
%           Predicted longitudinal dispersion coefficient [m^2/s]
%
%   MODEL DESCRIPTION
%       The model is:
%
%           KL = D0 * (1/tau + C2*Pe)
%
%       where:
%
%           KL   = longitudinal dispersion coefficient
%           D0   = molecular diffusion coefficient
%           tau  = tortuosity factor
%           C2   = dispersion coefficient
%           Pe   = Peclet number
%
%       The first term:
%
%           D0/tau
%
%       represents the effective molecular diffusion contribution within
%       the porous medium.
%
%       The second term:
%
%           D0*C2*Pe
%
%       represents mechanical dispersion associated with advective
%       transport.
%
%   DISPERSIVITY INTERPRETATION
%       The coefficient C2 can be related to dispersivity:
%
%           alpha = C2 * Dp
%
%       where:
%
%           Dp = characteristic pore diameter
%
%       and alpha is the characteristic length scale of mechanical
%       dispersion in the porous medium.
%
%   PHYSICAL INTERPRETATION
%       At low Peclet numbers:
%
%           KL ≈ D0/tau
%
%       indicating diffusion-dominated transport.
%
%       At high Peclet numbers:
%
%           KL ≈ D0*C2*Pe
%
%       indicating mechanically dispersed transport.
%
%       This model therefore captures both diffusive and advective
%       contributions to longitudinal spreading.
%
%   APPLICATIONS
%       This function is typically used for:
%
%           - Estimation of dispersivity (alpha)
%           - Estimation of tortuosity (tau)
%           - Dispersion scaling analyses
%           - Fitting KL versus Peclet number data
%           - Porous-media transport studies
%
%   NOTES
%       - Assumes a fixed scaling exponent beta = 1.
%       - Includes both mechanical dispersion and tortuosity effects.
%       - Intended for use with:
%
%             fit_dispersion_params_alpha_tau
%
%       - Provides a more physically complete description than the
%         dispersivity-only model implemented in
%         KL_Pe_alpha_only_model.
%
%   EXAMPLE
%       p = [0.75, 2.5];
%
%       KL = KL_Pe_alpha_tau_model(Pe_D0,...
%                                  D0,...
%                                  p);
%
%   See also KL_PE_ALPHA_ONLY_MODEL,
%            FIT_DISPERSION_PARAMS_ALPHA_TAU.

% Model with beta = 1 no tortuosity
KL_model = D0 * ( 1/p(2) + p(1) .* (Pe_fromD0.^1) );

end

