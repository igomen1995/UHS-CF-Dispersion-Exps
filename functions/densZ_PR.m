function [PR_input,PR_results] = densZ_PR(fl,x1,P_MPa,T_C,filedataPure,filedataBIP)

%DENSZ_PR Calculate density and compressibility factor using PR EOS.
%
%   [PR_INPUT, PR_RESULTS] = DENSZ_PR(FL,X1,P_MPA,T_C,...
%                                     FILEDATAPURE,FILEDATABIP)
%   calculates the compressibility factor (Z) and density (rho) of a pure
%   fluid or binary mixture using the Peng-Robinson equation of state
%   (PR EOS).
%
%   The function retrieves pure-component critical properties and
%   acentric factors, computes EOS parameters, evaluates binary
%   interaction parameters (BIPs) when applicable, and solves the
%   Peng-Robinson EOS over the specified composition range.
%
%   INPUTS
%       fl            : Cell array containing fluid names.
%
%                       Pure fluid:
%                           {"CO2"}
%
%                       Binary mixture:
%                           {"H2","CO2"}
%
%       x1            : Mole fraction(s) of component 1.
%
%       P_MPa         : Pressure [MPa]
%
%       T_C           : Temperature [°C]
%
%       filedataPure  : Table containing pure-component properties:
%                           - Fluid
%                           - Pc
%                           - Tc
%                           - AcentricFactor
%                           - M
%
%       filedataBIP   : Table containing fitted binary interaction
%                       parameters:
%                           - Fluid1
%                           - Fluid2
%                           - A12
%                           - B12
%
%   OUTPUTS
%       PR_input      : Summary table containing:
%                           - Fluid names
%                           - Pressure
%                           - Temperature
%
%       PR_results    : Results table containing:
%                           - x1    : Mole fraction component 1
%                           - Z     : Vapor-phase compressibility factor
%                           - rho   : Mixture density [kg/m^3]
%
%   WORKFLOW
%       1. Read pure-component critical properties.
%       2. Compute pure-component Peng-Robinson parameters:
%
%              ai, bi
%
%       3. For binary mixtures:
%
%          a) Compute temperature-dependent binary interaction
%             parameter (kij).
%
%          b) Apply classical mixing rules.
%
%          c) Calculate mixture parameters:
%
%                 amix, bmix
%
%          d) Solve the Peng-Robinson cubic EOS.
%
%       4. Extract the vapor-phase root (Z).
%
%       5. Compute mixture density:
%
%              rho = P*Mmix/(ZRT)
%
%   NOTES
%       - Supports both pure fluids and binary mixtures.
%       - Binary interaction parameters are calculated using the
%         Jaubert-Mutelet correlation.
%       - Density calculations are based on the vapor-phase EOS root.
%       - Intended for thermodynamic, transport-property, and dispersion
%         analyses involving H2, CO2, N2, CH4, and related mixtures.
%
%   EXAMPLE
%       fl = {"H2","CO2"};
%       x1 = 0:0.01:1;
%
%       [PR_input,PR_results] = densZ_PR(fl,...
%                                        x1,...
%                                        10.4,...
%                                        32,...
%                                        filedataPure,...
%                                        filedataBIP);
%
%       plot(PR_results.x1,PR_results.rho)
%       xlabel('H_2 Mole Fraction')
%       ylabel('Density (kg/m^3)')
%
%   See also CALC_AI_BI, CALC_BIP, CALC_ABMIX, CALC_Z.

addpath('functions/');

% % Variables of interest for this mixture
% fl = {"H2", "CO2"}; % fluids in the mixture
% x1 = 0:0.001:1; %string molar fraction component 1
% P_MPa = 10.4; % MPa
% T_C = 32; % C

P = P_MPa*(10^6); % Pa
T = T_C +273.15; %K
Pc = zeros(length(fl),1);
Tc = zeros(length(fl),1);
w = zeros(length(fl),1);
M = zeros(length(fl),1);
for i = 1:length(fl)
    Pc(i) = filedataPure.Pc(filedataPure.Fluid == fl{i})*(10^6); % NIST is in MPa, converted to Pa
    Tc(i) = filedataPure.Tc(filedataPure.Fluid == fl{i});
    w(i) = filedataPure.AcentricFactor(filedataPure.Fluid == fl{i});
    M(i) = filedataPure.M(filedataPure.Fluid == fl{i});
end

if length(fl) > 1
    % binary mixture BIP fitting params
    A12 = filedataBIP.A12(filedataBIP.Fluid1 == fl{1} & filedataBIP.Fluid2  == fl{2});
    B12 = filedataBIP.B12(filedataBIP.Fluid1 == fl{1} & filedataBIP.Fluid2  == fl{2});
end

% Pure components
% calculate ai, bi to estimate BIP
[ai,bi] = calc_ai_bi(T, Pc, Tc, w);

if length(fl) > 1
    %Mixture
    % calculate BIP based on fitting parameters and T
    % converting ai and bi to Mpa multiplying by 10^6
    
    kij = calc_BIP(T, A12, B12, ai, bi);
    
    kijmatrix = zeros(length(fl));
    kijmatrix(1,2) = kij;
    kijmatrix(2,1) = kij;

    aij = {};
    amix = [];
    bmix = [];
    Zall = {};
    Z = [];
    rho = [];

    for i = 1:length(x1)
        [aij{i}, amix(i), bmix(i)] = calc_abmix(x1(i), ai, bi, kijmatrix);
        [Zall{i},Z(i),rho(i)] = calc_Z(P, T, amix(i), bmix(i),x1(i),M);
    end
    PR_input = table(fl(1),fl(2), P_MPa, T_C,'VariableNames',{'fluid1', 'fluid2' 'P_MPa', 'T_C'});
else
    [Zall,Z,rho] = calc_Z(P, T, ai, bi, x1, M);
    PR_input = table(fl(1),NaN, P_MPa, T_C,'VariableNames',{'fluid1', 'fluid2' 'P_MPa', 'T_C'});
end

PR_results = table(x1',Z',rho','VariableNames',{'x1','Z','rho'});



