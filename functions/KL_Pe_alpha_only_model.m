function KL_model = KL_Pe_alpha_only_model(Pe_fromD0,D0,p)

%KL_PE_ALPHA_ONLY_MODEL Dispersion scaling model with dispersivity only.
%
%   KL_MODEL = KL_PE_ALPHA_ONLY_MODEL(PE_FROMD0,D0,P) evaluates a
%   simplified hydrodynamic dispersion correlation relating the
%   longitudinal dispersion coefficient (KL) to the molecular-diffusion-
%   based Peclet number (Pe).
%
%   The model assumes a linear dependence between dispersion and Peclet
%   number and neglects tortuosity effects.
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
%           Model parameter:
%
%               p = C2
%
%           where C2 is the proportionality coefficient relating
%           longitudinal dispersion to Peclet number.
%
%   OUTPUT
%       KL_model
%           Predicted longitudinal dispersion coefficient [m^2/s]
%
%   MODEL DESCRIPTION
%       The model is:
%
%           KL = D0 * C2 * Pe
%
%       where:
%
%           KL   = longitudinal dispersion coefficient
%           D0   = molecular diffusion coefficient
%           C2   = fitted coefficient
%           Pe   = Peclet number
%
%       This corresponds to a dispersivity-only model with:
%
%           beta = 1
%
%       and no tortuosity correction.
%
%   DISPERSIVITY INTERPRETATION
%       The fitted parameter can be related to dispersivity:
%
%           alpha = C2 * Dp
%
%       where:
%
%           Dp = characteristic pore diameter
%
%       and alpha represents the characteristic length scale associated
%       with mechanical dispersion.
%
%   APPLICATIONS
%       This model is typically used for:
%
%           - Dispersion scaling analyses
%           - Estimation of dispersivity
%           - Regression of KL vs Pe relationships
%           - Comparison with more complex transport models
%
%   NOTES
%       - Assumes a linear dependence of KL on Pe.
%       - Assumes a fixed exponent beta = 1.
%       - Does not account for tortuosity effects.
%       - Intended for use with:
%
%             fit_dispersion_params_alpha
%             fit_dispersion_params_all
%
%   EXAMPLE
%       C2 = 0.75;
%
%       KL = KL_Pe_alpha_only_model(Pe_D0,...
%                                   D0,...
%                                   C2);
%
%   See also FIT_DISPERSION_PARAMS_ALPHA,
%            FIT_DISPERSION_PARAMS_ALL.

% Model with beta = 1 no tortuosity
KL_model = D0 * ( p .* Pe_fromD0 );

end

