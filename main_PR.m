%% main_PR.m
% Version: v1_Feb2026
% Author: Ianna Gomez Mendez
%
% PURPOSE
%   Calculate fluid density and compressibility factor using the
%   Peng-Robinson Equation of State (PR-EOS).
%
%   The script generates density-composition relationships for pure
%   components or binary mixtures over a specified composition range
%   at fixed pressure and temperature.
%
%   The generated density database can subsequently be used for:
%
%       - Coriolis density calibration
%       - Composition estimation
%       - Breakthrough-curve data processing
%       - Transport-model analysis
%
% -------------------------------------------------------------------------
% OBJECTIVE
% -------------------------------------------------------------------------
%
%   Estimate:
%
%       rho = f(P,T,x)
%
%   and
%
%       Z = f(P,T,x)
%
%   using the Peng-Robinson Equation of State.
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
%
% Configuration:
%
%       inputPRConfig.xlsx
%
% Pure-component properties:
%
%       input_PR_pure.xlsx
%
%       containing:
%
%           Critical temperature (Tc)
%           Critical pressure (Pc)
%           Acentric factor (omega)
%           Molecular weight (M)
%
% Binary-mixture properties:
%
%       input_PR_BIP.xlsx
%
%       containing:
%
%           A12
%           B12
%
%       parameters used to estimate:
%
%           kij(T)
%
% -------------------------------------------------------------------------
% USER-DEFINED PARAMETERS
% -------------------------------------------------------------------------
%
% Fluid system:
%
%       Fluid1
%       Fluid2
%
% Composition range:
%
%       xi
%       xf
%       dx
%
% Pressure:
%
%       P_MPa
%
% Temperature:
%
%       T_C
%
% -------------------------------------------------------------------------
% THERMODYNAMIC MODEL
% -------------------------------------------------------------------------
%
%   Peng-Robinson Equation of State:
%
%                   RT
%       P = ---------------- - a(T)
%           (V-b)      ...
%
%   where:
%
%       a(T)     attractive term
%       b        covolume term
%
% -------------------------------------------------------------------------
% PURE-COMPONENT PARAMETERS
% -------------------------------------------------------------------------
%
%   For each component:
%
%       ai
%       bi
%
%   are calculated from:
%
%       Tc
%       Pc
%       omega
%
%   using standard PR-EOS correlations.
%
% -------------------------------------------------------------------------
% BINARY INTERACTION PARAMETERS
% -------------------------------------------------------------------------
%
%   For binary systems:
%
%       kij
%
%   is calculated using:
%
%       A12
%       B12
%
%   through:
%
%       kij = f(T)
%
% -------------------------------------------------------------------------
% MIXTURE PROPERTIES
% -------------------------------------------------------------------------
%
%   For each composition x1:
%
%       aij
%       amix
%       bmix
%
%   are calculated using conventional PR mixing rules.
%
% -------------------------------------------------------------------------
% EOS SOLUTION PROCEDURE
% -------------------------------------------------------------------------
%
%   For each composition:
%
%       1. Calculate ai and bi
%
%       2. Calculate kij
%
%       3. Construct:
%
%              aij matrix
%
%       4. Calculate:
%
%              amix
%              bmix
%
%       5. Generate PR cubic equation
%
%       6. Calculate compressibility roots:
%
%              Z1
%              Z2
%              Z3
%
%       7. Select the vapor-phase root
%
%              Zvapor
%
%       8. Calculate:
%
%              Density
%
% -------------------------------------------------------------------------
% CALCULATED VARIABLES
% -------------------------------------------------------------------------
%
%   For each x1:
%
%       x1
%
%       Z
%
%       rho
%
% -------------------------------------------------------------------------
% OUTPUT TABLES
% -------------------------------------------------------------------------
%
% PR_input:
%
%       Fluid1
%       Fluid2
%       P_MPa
%       T_C
%
% -------------------------------------------------------------------------
%
% PR_results:
%
%       x1
%       Z
%       rho
%
% -------------------------------------------------------------------------
% GENERATED FIGURES
% -------------------------------------------------------------------------
%
% Density-composition relationship:
%
%       rho(x1)
%
%       rho-vs-x1.png
%
% -------------------------------------------------------------------------
%
% Compressibility relationship:
%
%       Z(x1)
%
%       Z-vs-x1.png
%
% -------------------------------------------------------------------------
% OUTPUT FILES
% -------------------------------------------------------------------------
%
% Excel:
%
%       PR_results.xlsx
%
% MATLAB:
%
%       PR_results.mat
%
% Figures:
%
%       rho-vs-x1.png
%
%       Z-vs-x1.png
%
% -------------------------------------------------------------------------
% DEPENDENCIES
% -------------------------------------------------------------------------
%
% Import functions:
%
%       import_inputPR_params_pure
%       import_inputPR_params_BIP
%
% EOS functions:
%
%       calc_ai_bi
%       calc_BIP
%       calc_abmix
%       calc_Z
%
% -------------------------------------------------------------------------
% APPLICATIONS
% -------------------------------------------------------------------------
%
%   Typical uses include:
%
%       - Generating rho-versus-composition lookup tables
%
%       - Supporting composition estimation from Coriolis density
%         measurements
%
%       - Producing reference datasets for calibration workflows
%
%       - Validating EOS performance against experimental data
%
%       - Studying pressure and temperature effects on mixture density
%
% -------------------------------------------------------------------------
% ASSUMPTIONS
% -------------------------------------------------------------------------
%
%   - Peng-Robinson EOS adequately represents the investigated fluids.
%
%   - Binary-mixture behavior can be represented using the selected
%     binary interaction parameter correlation.
%
%   - The vapor root of the PR cubic equation is assumed to represent
%     the physical phase of interest.
%
%   - Units are:
%
%         Pressure      MPa (input)
%         Temperature   °C (input)
%         Density       kg/m³ (output)
%
% -------------------------------------------------------------------------
% NOTES
% -------------------------------------------------------------------------
%
%   This script is the thermodynamic backbone of the workflow:
%
%       main_PR
%           ↓
%       main_Cal
%           ↓
%       main_Validation
%           ↓
%       main_DataExtract
%           ↓
%       main_Processing
%
%   The density-composition surfaces generated through Peng-Robinson EOS
%   are ultimately used to convert corrected MFM density measurements
%   into molar compositions during breakthrough-curve analysis.
%
%% INPUT

inputFileConfigName = 'inputPRConfig.xlsx';

inputFileConfig = readtable(inputFileConfigName);

addpath('functions/');

% ------------------------------------------------------------------------

% INTRODUCE THE INPUT HERE
% file containing pure components NIST data: Tc, Pc and acentric factor w
filenamePure = inputFileConfig.inputPureParams{:};
% file containing mixture compoents A12 B12 factor to estimate BIP
filenameBIP = inputFileConfig.inputMixParams{:};

% Variables of interest for this mixture
flaux = string(inputFileConfig.inputFluids{:}); % fluids in the mixture
fl = split(flaux,',');
xi = inputFileConfig.inputXi;
xf = inputFileConfig.inputXf;
dx = inputFileConfig.inputdXi;
x1 = xi:dx:xf; %string molar fraction component 1
P_MPa = inputFileConfig.P_MPa; % MPa
T_C = inputFileConfig.T_C; % C

exportPath = inputFileConfig.exportPath{:};

% Output
pathExportAll = inputFileConfig.exportPath{:}; % Path for OUTPUT
mkdir(pathExportAll); % Create directory for output

filenameOutput = "PR_results";

% ------------------------------------------------------------------------

% import pure components NIST data: Tc, Pc and acentric factor w
filedataPure = import_inputPR_params_pure(filenamePure);

% import mixture components A12 and B12 factor to estimate BIP (kij)
filedataBIP = import_inputPR_params_BIP(filenameBIP);

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


%% PR - EOS 

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
else
    [Zall,Z,rho] = calc_Z(P, T, ai, bi, x1, M);
end

%% Save results

PR_input = table(string(fl{1}),string(fl{2}), P_MPa, T_C,'VariableNames',{'fluid1', 'fluid2', 'P_MPa', 'T_C'});
PR_results = table(x1',Z',rho','VariableNames',{'x1','Z','rho'});

delete(pathExportAll + filenameOutput + ".xlsx")

writetable(PR_input,pathExportAll + filenameOutput + ".xlsx", 'Sheet', 'PR_input');
writetable(PR_results,pathExportAll + filenameOutput + ".xlsx", 'Sheet', filenameOutput);
save(pathExportAll + filenameOutput + ".mat",filenameOutput)

%% Plot
figure
scatter(x1,rho,5,'k',"filled")
xlabel_aux = sprintf('x_{%s} [-]',fl{1});
xlabel(xlabel_aux);
ylabel_aux = sprintf('\\rho_{PR-EOS} [kg/m^{3}]');
ylabel(ylabel_aux);
if length(fl) > 1
    title_aux = sprintf('\\rho_{%s%s} vs x_{%s} @ %.1f MPa, %.1f °C', fl{1}, fl{2}, fl{1}, P_MPa, T_C);
else
    title_aux = sprintf('\\rho_{%s} vs x_{%s} @ %.1f MPa, %.1f °C', fl{1}, fl{1}, P_MPa, T_C);
end
title(title_aux)
grid on
saveas(gcf,pathExportAll + "rho-vs-x1",'png')

figure
scatter(x1,Z,5,"filled")
xlabel('x_1 [-]');
ylabel('Z [-]');
if length(fl) > 1
    title_aux = sprintf('Z_{%s%s} vs x_{%s} @ %.1f MPa, %.1f °C', fl{1}, fl{2}, fl{1}, P_MPa, T_C);
else
    title_aux = sprintf('Z_{%s} vs x_{%s} @ %.1f MPa, %.1f °C', fl{1}, fl{1}, P_MPa, T_C);
end
title(title_aux)
grid on
saveas(gcf,pathExportAll + "Z-vs-x1",'png')
