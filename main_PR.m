% main_PR.m
% version: v1_Feb2026
% Author: Ianna Gomez Mendez
%
% Objective: 
% Estimate rho of the mixture or pure elements, given an array of x1 using PR EOS
% 
% Input:
% - state fluids, P, T and x1init x1final, dx in an excel file
% - input NIST data pure components
% - input kij A12 and B12 fitting params for binary interaction parameters
% 
% Procedure:
% 1 - import fluids @P, T and x to study
% 2 - import NIST data pure components and kij fitting params
% 3 - calculate ai and bi pure parameters with function, provide results in
% an array
% 4 - calculate a and b mixture, provide results in an array, including kij, aij matrices and a and b
% 5 - calculate A, B, m3, m2, m2, m0 to fit PR Cubic equation
% 6 - Estimate Zvapor, assume is Z mixture for H2 mixtures
% 7 - Estimate rho mixture for xi, store until forming an array of rho_mix
% vs xi
% 
% Output: 
% - array of rho_mix and xi in excel
% - plot rho_mix vs xi
%
%% INPUT

addpath('functions/');

% ------------------------------------------------------------------------

% INTRODUCE THE INPUT HERE
% file containing pure components NIST data: Tc, Pc and acentric factor w
filenamePure = 'input/input_PR_pure.xlsx';
% file containing mixture compoents A12 B12 factor to estimate BIP
filenameBIP = 'input/input_PR_BIP.xlsx';

% Variables of interest for this mixture
fl = {"H2", "CO2"}; % fluids in the mixture
x1 = 0:0.001:1; %string molar fraction component 1
P_MPa = 10.4; % MPa
T_C = 32; % C

% Output
mkdir('results/PR_H2-CO2-T32-P1500');
pathExportAll = 'results/PR_H2-CO2-T32-P1500/';
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

PR_input = table(fl{1}',fl{2}, P_MPa', T_C','VariableNames',{'fluid1', 'fluid2' 'P_MPa', 'T_C'});
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
