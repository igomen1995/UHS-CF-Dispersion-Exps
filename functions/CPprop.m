function [val,errMsg] = CPprop(prop,T,P,fluid)

% CPPROP Retrieve a thermophysical property from CoolProp.
%
% DESCRIPTION
%   Queries the CoolProp property database through MATLAB's Python
%   interface and returns the requested fluid property at a specified
%   temperature and pressure.
%
%   If CoolProp cannot calculate the property (e.g., unsupported fluid,
%   unavailable transport model, invalid state point, etc.), the function
%   returns NaN and stores the Python/CoolProp error message in errMsg.
%
% INPUTS
%   prop   - CoolProp property string.
%            Common examples:
%               'D'           Density [kg/m^3]
%               'VISCOSITY'   Dynamic viscosity [Pa·s]
%               'Z'           Compressibility factor [-]
%               'CPMASS'      Specific heat capacity [J/(kg·K)]
%               'HMASS'       Specific enthalpy [J/kg]
%               'M'           Molar mass [kg/mol]
%
%   T      - Temperature [K]
%
%   P      - Pressure [Pa]
%
%   fluid  - Fluid name recognized by CoolProp.
%            Examples:
%               'Helium'
%               'Hydrogen'
%               'CO2'
%               'Methane'
%               'Water'
%               'Xenon'
%
% OUTPUTS
%   val    - Requested property value.
%            Returns NaN if CoolProp fails to evaluate the property.
%
%   errMsg - Error message returned by MATLAB/Python/CoolProp.
%            Empty string ('') if the calculation was successful.
%
% EXAMPLES
%   % Helium viscosity at 20°C and 725 psig (~5.1 MPa)
%   [muHe,err] = CPprop('VISCOSITY',293.15,5.1e6,'Helium');
%
%   % CO2 density at 20°C and 900 psig (~6.3 MPa)
%   [rhoCO2,err] = CPprop('D',293.15,6.3e6,'CO2');
%
%   % Check for unavailable property models
%   [muXe,err] = CPprop('VISCOSITY',293.15,5e6,'Xenon');
%   if isnan(muXe)
%       fprintf('CoolProp error:\n%s\n',err);
%   end
%
% NOTES
%   - Requires a supported CPython installation configured with pyenv().
%   - Requires CoolProp installed in the active Python environment.
%   - Useful for calculating fluid properties needed for:
%         * Peclet number (Pe)
%         * Gravity number (Ng)
%         * Viscosity ratio (M)
%         * Density ratio
%         * Real-gas transport analyses
%
% SEE ALSO
%   pyenv, pyrun
%
    errMsg = '';

    try

        val = pyrun( ...
            sprintf([ ...
            'from CoolProp.CoolProp import PropsSI\n' ...
            'result = float(PropsSI("%s","T",%g,"P",%g,"%s"))'], ...
            prop,T,P,fluid), ...
            "result");

        val = double(val);

    catch ME

        val = NaN;
        errMsg = ME.message;

    end

end

