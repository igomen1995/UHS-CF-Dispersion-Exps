function [D12, dD12] = calc_diff_marrero(T_C,P_psig, A, B, C, D, E, group, dev_pc)

%CALC_DIFF_MARRERO Estimate binary gas diffusivity using Marrero correlation.
%
%   [D12, dD12] = CALC_DIFF_MARRERO(T_C,P_psig,A,B,C,D,E,GROUP,DEV_PC)
%   calculates the binary molecular diffusion coefficient for a gas pair
%   using a Marrero-type empirical correlation. The function returns the
%   predicted diffusivity and an uncertainty estimate based on a specified
%   percent deviation.
%
%   INPUTS
%       T_C      : Temperature [°C]
%
%       P_psig   : Pressure [psig]
%
%       A,B,C,D,E
%                : Correlation coefficients for the selected gas pair.
%
%       group    : Correlation group identifier:
%                    1 = Correlations requiring the full expression
%                        (e.g., H2-N2)
%                    otherwise = Simplified correlation form
%
%       dev_pc   : Expected model deviation [%]
%
%   OUTPUTS
%       D12      : Binary diffusion coefficient [cm^2/min]
%
%       dD12     : Estimated uncertainty of D12 [cm^2/min]
%
%   MODEL DESCRIPTION
%       The correlation is evaluated using temperature in Kelvin and
%       pressure in atmospheres. Diffusivity is first calculated in
%       cm^2/s and then converted to cm^2/min.
%
%       Group 1:
%
%           D12 = exp[ ln(A·10^-5)
%                      + B·ln(T)
%                      - ln((ln(C·10^8/T))^2)
%                      - D/T
%                      - E/T^2 ] / P
%
%       Other groups:
%
%           D12 = exp[ ln(A·10^-5)
%                      + B·ln(T)
%                      - D/T ] / P
%
%   UNIT CONVERSIONS
%       Temperature:
%
%           T[K] = T_C + 273.15
%
%       Pressure:
%
%           P[atm] = (P_psig + 14.7)/14.6959
%
%       Diffusivity:
%
%           cm^2/s -> cm^2/min
%
%   UNCERTAINTY ESTIMATION
%       The diffusivity uncertainty is estimated from the specified
%       percentage deviation:
%
%           dD12 = (dev_pc/100) * D12
%
%   NOTES
%       - The correlation coefficients are gas-pair specific.
%       - Pressure dependence is inversely proportional to pressure.
%       - The returned diffusivity is reported in cm^2/min for consistency
%         with laboratory-scale transport calculations.
%       - Intended for estimating molecular diffusion coefficients used in
%         transport, dispersion, and core-flood analyses.
%
%   EXAMPLE
%       [D12,dD12] = calc_diff_marrero(25,...
%                                      500,...
%                                      A,B,C,D,E,...
%                                      1,...
%                                      5);

T = T_C + 273.15; % K
P = (P_psig + 14.7)/14.6959; % atm

if group == 1 % H2 N2
    D12 = (exp(log(A*(10^-5)) + B*log(T) - log((log(C*(10^8)/T))^2) - D/T - E/(T^2)))/P;
else
    D12 = (exp(log(A*(10^-5)) + B*log(T) - D/T))/P;
end

D12 = D12*60; % cm2min

dD12 = dev_pc*D12/100; % cm2min

end
