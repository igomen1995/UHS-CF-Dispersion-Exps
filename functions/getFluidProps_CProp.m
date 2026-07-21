function props = getFluidProps_CProp(fluid,T,P)

% GETFLUIDPROPS Retrieve common thermophysical properties from CoolProp.
%
% DESCRIPTION
%   Returns a structure containing selected thermophysical properties
%   of a specified fluid at the supplied temperature and pressure using
%   the CoolProp database through the CPprop() function.
%
% INPUTS
%   fluid   - Fluid name recognized by CoolProp.
%             Examples:
%                 'Helium'
%                 'Hydrogen'
%                 'CO2'
%                 'Methane'
%                 'Water'
%                 'Xenon'
%
%   T       - Temperature [K]
%
%   P       - Pressure [Pa]
%
% OUTPUT
%   props   - Structure containing:
%
%       props.rho
%           Fluid density [kg/m^3]
%
%       props.mu
%           Dynamic viscosity [Pa·s]
%
%       props.Z
%           Compressibility factor [-]
%
%       props.MW
%           Molecular weight [kg/mol]
%
% EXAMPLES
%   % Helium properties at 20°C and 725 psig (~5.1 MPa)
%   He = getFluidProps('Helium',293.15,5.1e6);
%
%   % Access individual properties
%   rhoHe = He.rho;
%   muHe  = He.mu;
%   ZHe   = He.Z;
%
%   % Compute viscosity ratio
%   H2  = getFluidProps('Hydrogen',293.15,6e6);
%   CO2 = getFluidProps('CO2',293.15,6e6);
%
%   viscosityRatio = CO2.mu/H2.mu;
%
% NOTES
%   - Requires CoolProp installed in the Python environment configured
%     through MATLAB's pyenv().
%   - Uses CPprop() to query CoolProp properties.
%   - Intended for transport-scaling calculations including:
%         * Viscosity ratio (M)
%         * Gravity number (Ng)
%         * Peclet number (Pe)
%         * Density ratio
%         * Real-gas property evaluation
%
% SEE ALSO
%   CPprop, pyenv
%

[props.rho,props.rhoErr] = CPprop('D',T,P,fluid);
[props.mu,props.muErr]  = CPprop('VISCOSITY',T,P,fluid);
[props.Z,props.ZErr]   = CPprop('Z',T,P,fluid);
[props.MW,props.MWErr]  = CPprop('M',T,P,fluid);

end
