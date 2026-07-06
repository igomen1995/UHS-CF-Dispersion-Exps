function [ai,bi] = calc_ai_bi(temp, pressc, tempc, acentric)

%CALC_AI_BI Calculate Peng-Robinson pure-component EOS parameters.
%
%   [AI, BI] = CALC_AI_BI(TEMP, PRESSC, TEMPC, ACENTRIC) calculates the
%   temperature-dependent attraction parameter (AI) and covolume
%   parameter (BI) for one or more pure components using the
%   Peng-Robinson equation of state (PR EOS).
%
%   INPUTS
%       temp      : System temperature [K]
%
%       pressc    : Critical pressure(s) [Pa]
%
%       tempc     : Critical temperature(s) [K]
%
%       acentric  : Acentric factor(s) [-]
%
%   OUTPUTS
%       ai        : Pure-component attraction parameter(s) [Pa·m^6/mol^2]
%
%       bi        : Pure-component covolume parameter(s) [m^3/mol]
%
%   MODEL DESCRIPTION
%       The Peng-Robinson equation of state defines:
%
%           a(T) = a(Tc)*alpha(T)
%
%       where:
%
%           a(Tc) = 0.45724 * R^2 * Tc^2 / Pc
%
%           b     = 0.07780 * R * Tc / Pc
%
%       and the temperature correction factor is:
%
%           alpha = [1 + m*(1-sqrt(Tr))]^2
%
%       with:
%
%           Tr = T/Tc
%
%           m = 0.37464
%               + 1.54226*w
%               - 0.26992*w^2
%
%       where w is the acentric factor.
%
%   NOTES
%       - Implements the standard Peng-Robinson EOS formulation.
%       - Supports scalar or vector inputs for multicomponent systems.
%       - The calculated AI and BI values can be combined using mixing
%         rules to obtain mixture parameters.
%       - Intended for phase-equilibrium and thermodynamic calculations.
%
%   EXAMPLE
%       T = 298.15;
%       Pc = [7.38e6; 4.60e6];
%       Tc = [304.13; 190.56];
%       omega = [0.225; 0.011];
%
%       [ai,bi] = calc_ai_bi(T,Pc,Tc,omega);
%

omegaa = 0.45724;
omegab = 0.0778;
R = 8.314; %Jmol-1K-1

% Calculate m
m=0.37464+1.54226*acentric-0.26992*acentric.^2;

% Calculate reduced temperature
tempr = temp./tempc;

% Calculate alpha.
alpha = (1+m.*(1-sqrt(tempr))).^2;

% Calculate ai and bi
ai_tempc = omegaa*(R^2)*(tempc.^2)./(pressc);
ai = ai_tempc.*alpha;
bi = omegab*R*tempc./pressc;

end