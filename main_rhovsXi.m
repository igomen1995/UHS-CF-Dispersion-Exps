%% main_rhoVsXi.m
% Author: Ianna Gomez Mendez (script assembled to extend main_DataExtract.m)
%
% PURPOSE
%   Build one combined figure with 4 density-vs-composition curves, all
%   generated with REFPROP (getMixtureProps_REFPROP), the same REFPROP
%   branch already used in main_DataExtract.m:
%
%       1) H2-CO2  @ 1160 psig, 40 C
%       2) H2-CH4  @ 1160 psig, 40 C
%       3) He-Xe   @  725 psig, 20 C
%       4) He-Xe   @  900 psig, 20 C
%
%   x-axis  : mole fraction of the lighter/injected component (H2 or He)
%   y-axis  : density normalized between the two pure-component endpoints,
%             rhoNorm = (rho - rho(x=0)) / (rho(x=1) - rho(x=0))
%             so every curve runs 0 -> 1 regardless of which pure fluid is
%             denser, the same convention used for normalized concentration
%             (CDi) elsewhere in this project.
%
%   All 4 series are legended with the ABSOLUTE pressure in MPa
%   (psig -> psia: +14.696 psi, then x 0.00689476 to MPa) and the
%   temperature in C.
%
% DEPENDENCIES
%   initREFPROP, getMixtureProps_REFPROP, fluidNameREFPROP
%
% For pure/mix property tables with error propagation (rho, Z, mu, D12 at
% x1=0, 0.5, 1), see the companion script main_fluidProps_errorProp.m.

%% INPUT

addpath('functions/');

x1 = 0:0.005:1;   % composition grid, shared by all 4 curves

% psig, T in C. psig -> MPa: (psig + 14.696) * 0.00689476
psig2MPa = @(psig) (psig + 14.696) * 0.00689476;

% NOTE: fluid strings here are the SHORT codes ("H2","He","Xe","CO2","CH4"),
% same convention as filedataExp.Fluid1/Fluid2 in main_DataExtract.m.
% fluidNameREFPROP() does the short-code -> REFPROP-library-name translation
% (H2->HYDROGEN, He->HELIUM, Xe->XENON, ...) INSIDE getFluidProps_REFPROP /
% getMixtureProps_REFPROP, so callers must NOT pass "HELIUM"/"XENON" directly.
cases = struct( ...
    'label',  {'H2-CO2', 'H2-CH4', 'He-Xe', 'He-Xe'}, ...
    'fl',     {{"H2","CO2"}, {"H2","CH4"}, {"He","Xe"}, {"He","Xe"}}, ...
    'P_psig', {1160, 1160, 725, 900}, ...
    'T_C',    {40, 40, 20, 20} );

mkdir('results/combined_rhoNorm_4curves');
pathExportAll = 'results/combined_rhoNorm_4curves/';

%% Pre-load shared inputs

RP = initREFPROP();

%% Compute rho(x1) for each case

results = struct();

for c = 1:numel(cases)

    fl    = cases(c).fl;
    P_MPa = psig2MPa(cases(c).P_psig);
    T_C   = cases(c).T_C;
    T_K   = T_C + 273.15;
    P_kPa = P_MPa*1000;

    rho = zeros(size(x1));
    Z   = zeros(size(x1));
    for i = 1:length(x1)
        z = [x1(i), 1-x1(i)];
        Mix = getMixtureProps_REFPROP(RP, {char(fl{1}), char(fl{2})}, z, T_K, P_kPa);
        rho(i) = Mix.rho;
        Z(i)   = Mix.Z;
    end

    % normalize density between the two pure-component endpoints (x1=0, x1=1)
    rho0 = rho(1);
    rho1 = rho(end);
    rhoNorm = (rho - rho0) / (rho1 - rho0);

    results(c).label   = cases(c).label;
    results(c).fl      = fl;
    results(c).P_MPa   = P_MPa;
    results(c).P_psig  = cases(c).P_psig;
    results(c).T_C     = T_C;
    results(c).x1      = x1;
    results(c).rho     = rho;
    results(c).rhoNorm = rhoNorm;
    results(c).Z       = Z;
end

%% Save table of results

allResults = table();
for c = 1:numel(results)
    n = numel(results(c).x1);
    allResults = [allResults; table( ...
        repmat({results(c).label}, n, 1), ...
        repmat(results(c).P_psig, n, 1), ...
        repmat(results(c).P_MPa, n, 1), ...
        repmat(results(c).T_C, n, 1), ...
        results(c).x1', results(c).rho', results(c).rhoNorm', ...
        'VariableNames', {'Pair','P_psig','P_MPa','T_C','x1','rho','rhoNorm'})]; %#ok<AGROW>
end
writetable(allResults, pathExportAll + "rhoNorm_4curves.xlsx");
save(pathExportAll + "rhoNorm_4curves.mat", 'results', 'allResults');

%% Plot

figure; hold on
colours = {[0.850 0.325 0.098],[0.494 0.184 0.556],[0.466 0.674 0.188],[0 0.447 0.741]};
markers = {'o','o','o','o'};

legendStr = cell(numel(results),1);
for c = 1:numel(results)
    scatter(results(c).x1, results(c).rhoNorm, 15, colours{c}, markers{c}, 'filled');
    legendStr{c} = sprintf('%s @ %.2f MPa, %d°C', results(c).label, results(c).P_MPa, results(c).T_C);
end
hold off

xlabel('x_1 (mole fraction H_2 or He) [-]');
ylabel('\rho_{norm} [-]  (normalized between x_1=0 and x_1=1)');
title('Density vs. composition (REFPROP): H_2-CO_2, H_2-CH_4, He-Xe');
legend(legendStr, 'Location', 'southeast');
grid on
saveas(gcf, pathExportAll + "rhoNorm_vs_x1_4curves", 'png');