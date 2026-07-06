function [Zall, Zvap, rhomix] = calc_Z(P, T, amix, bmix, x1, M)
    
%CALC_Z Calculate compressibility factor and density using PR EOS.
%
%   [ZALL, ZVAP, RHOMIX] = CALC_Z(P,T,AMIX,BMIX,X1,M) solves the
%   Peng-Robinson equation of state (PR EOS) for the compressibility
%   factor, Z, and calculates the corresponding mixture density.
%
%   INPUTS
%       P      : Pressure [Pa]
%
%       T      : Temperature [K]
%
%       amix   : Mixture attraction parameter obtained from mixing rules
%                [Pa·m^6/mol^2]
%
%       bmix   : Mixture covolume parameter obtained from mixing rules
%                [m^3/mol]
%
%       x1     : Mole fraction of component 1. For binary mixtures,
%                x2 = 1 - x1.
%
%       M      : Molar mass vector [kg/mol]
%
%                  M = [M1; M2]
%
%                For pure-component calculations, M may be scalar.
%
%   OUTPUTS
%       Zall   : All real compressibility-factor roots
%
%       Zvap   : Largest real root of the PR EOS cubic equation,
%                corresponding to the vapor phase
%
%       rhomix : Mixture density calculated using Zvap [kg/m^3]
%
%   MODEL DESCRIPTION
%       The Peng-Robinson EOS is expressed in terms of the
%       compressibility factor:
%
%           Z^3
%           - (1-B)Z^2
%           + (A - 3B^2 - 2B)Z
%           - (AB - B^2 - B^3)
%           = 0
%
%       where:
%
%           A = amix*P/(R^2*T^2)
%
%           B = bmix*P/(R*T)
%
%       The cubic equation is solved and all real roots are returned.
%
%   ROOT SELECTION
%       Depending on pressure and temperature conditions, the PR EOS may
%       return one or three real roots.
%
%       - Smallest root  : liquid-like root
%       - Largest root   : vapor-like root
%       - Intermediate   : metastable root
%
%       This function selects the largest real root as the vapor-phase
%       compressibility factor (Zvap).
%
%   DENSITY CALCULATION
%       The mixture density is computed from:
%
%           rhomix = P*Mmix/(Zvap*R*T)
%
%       where:
%
%           Mmix = x'*M
%
%       is the mixture molecular weight.
%
%   NOTES
%       - Implements the Peng-Robinson EOS cubic formulation.
%       - Supports both pure-component and binary-mixture calculations.
%       - Returns all physically meaningful real roots.
%       - Uses the vapor root for density estimation.
%       - Intended for thermodynamic and transport-property calculations.
%
%   EXAMPLE
%       [aij,amix,bmix] = calc_abmix(x1,ai,bi,kij);
%
%       [Zall,Zvap,rho] = calc_Z(P,...
%                                T,...
%                                amix,...
%                                bmix,...
%                                x1,...
%                                M);
%
%   See also ROOTS, CALC_ABMIX, CALC_AI_BI.


R = 8.314; %Jmol-1K-1
if length(M) > 1
    xi = [x1;(1-x1)];
else
    xi = x1;
end

% Calculate A and B
A = amix*P/((R^2)*(T^2));
B = bmix*P/(R*T);

% Calculate the coefficients of cubic equation.
m3 = 1;
m2 = -(1-B);
m1 = A-3*(B^2)-2*B ;
m0 = -(A*B-(B^2)-(B^3));

% Solve the cubic equation.
Zroots = roots([m3 m2 m1 m0]);

% Choose the real roots.
Z = [];
for i = 1:3
    if imag( Zroots(i) ) == 0
        Zreal = real(Zroots(i));
        Z = cat(1, Z, Zreal);
    end
end

Zall = sort(Z);
Zvap = max(Z);

% calculate rho mixture
Mmix = xi'*M;
rhomix = P*Mmix/(Zvap*R*T);

end
