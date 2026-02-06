% main_rhovsC-PR.m
% version: v1_Feb2026
% Author: Ianna Gomez Mendez
%
% Objective: 
% Estimate rho of the mixture, given an array of x1 using PR EOS
% 
% Input:
% - state fluid 1, fluid 2, P, T, and x1 array
% - input NIST data pure components
% - input kij A12 and B12 fitting params for binary interaction parameters
% 
% Procedure:
% 1 - state fluid 1, fluid 2, P, T, and x1 array, perform the following for
% each x1
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

addpath('Functions/');

% import pure components NIST data: Tc, Pc and acentric factor w
filenamePure = 'Input/ThermoNIST-pureData.xlsx';
opts = spreadsheetImportOptions("NumVariables", 5);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid", "M", "Tc", "Pc", "AcentricFactor"];
opts.VariableTypes = ["string", "double", "double", "double", "double"];
filedataPure = readtable(filenamePure,opts);

% import mixture components A12 and B12 factor to estimate BIP (kij)
filenameBIP = 'Input/Thermo-binaryInteractionParamsHighPressure.xlsx';
opts = spreadsheetImportOptions("NumVariables", 4);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid1", "Fluid2", "A12", "B12"];
opts.VariableTypes = ["string", "string", "double","double"];
filedataBIP = readtable(filenameBIP,opts);

% Variables of interest for this mixture
fl = {"H2","CO2"}; % fluids in the mixture
x1 = 0:0.01:1; %string molar fraction component 1
P_MPa = 10.4; % MPa, 1500psig
P = P_MPa*(10^6); % Pa
T_C = 28; % C
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
% binary mixture BIP fitting params
A12 = filedataBIP.A12(filedataBIP.Fluid1 == fl{1} & filedataBIP.Fluid2  == fl{2});
B12 = filedataBIP.B12(filedataBIP.Fluid1 == fl{1} & filedataBIP.Fluid2  == fl{2});

mkdir('Results/PR-H2CO2-28C-1500psig');
pathExportAll = 'Results/PR-H2CO2-28C-1500psig/';

%% PR - EOS 

% Pure components

% calculate ai, bi to estimate BIP
[ai,bi] = calc_ai_bi(T, Pc, Tc, w);

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
Zmix = [];
rho_mix = [];

for i = 1:length(x1)
    [aij{i}, amix(i), bmix(i)] = calc_abmix(x1(i), ai, bi, kijmatrix);
    [Zall{i},Zmix(i),rho_mix(i)] = calc_Z(P, T, amix(i), bmix(i),x1(i),M);
end

PR_results = [];
PR_results = table(x1',Zmix',rho_mix','VariableNames',{'x1','Zmix','rho_mix'});
writetable(PR_results,pathExportAll + "PR_results.xlsx");
save(pathExportAll + "PR_results.mat",'PR_results')

%% Plot

figure
scatter(x1,rho_mix,20,"filled")
xlabel('x_1 [-]');
ylabel('Density PR-EOS [kg/m^{3}]');
title_aux = sprintf('\\rho_{mix} vs x_{H2} @ %.1f MPa, %.1f °C', P_MPa, T_C);
title(title_aux)
grid on
saveas(gcf,pathExportAll + "rhomix-vs-x1",'png')

figure
scatter(x1,Zmix,20,"filled")
xlabel('x_1 [-]');
ylabel('Z_{mix} [-]');
title_aux = sprintf('Z_{mix} vs x_{H2} @ %.1f MPa, %.1f °C', P_MPa, T_C);
title(title_aux)
grid on
saveas(gcf,pathExportAll + "Zmix-vs-x1",'png')