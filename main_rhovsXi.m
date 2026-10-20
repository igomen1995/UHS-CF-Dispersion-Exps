%% main_4curves_rhoVsX.m
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
%   (main_PR.m / the PR-EOS branch was only an illustrative earlier example
%   for H2-CO2/H2-CH4 — not used here. All 4 curves now come from the same
%   REFPROP calculation path, so the comparison is consistent across pairs:
%   H2-CO2 and H2-CH4 use REFPROP's fitted Kunz-Wagner GERG-2008 departure
%   function [KW7]; He-Xe uses REFPROP's default/unfitted combining rule
%   (no departure function exists for He-Xe, confirmed from HMX.BNC), which
%   is the methodological point you want to carry into the paper's Methods
%   section regardless.)
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
% DEPENDENCIES (same functions already used by main_DataExtract.m)
%   initREFPROP, getMixtureProps_REFPROP
%
% NOTE
%   This script was written without access to your MATLAB session, so it has
%   not been executed here. Fluid-name strings for REFPROP ('H2','CO2','CH4',
%   'HELIUM','XENON') assume the same conventions as main_DataExtract.m
%   (it calls getMixtureProps_REFPROP with upper(filedataExp.Fluid1(i))/
%   Fluid2(i) strings) — adjust the strings below if your REFPROP fluid
%   library names them differently.

%% INPUT

addpath('functions/');

x1 = 0:0.005:1;   % composition grid, shared by all 4 curves

% ---- case definitions -----------------------------------------------
% psig, T in C. psig -> MPa: (psig + 14.696) * 0.00689476
psig2MPa = @(psig) (psig + 14.696) * 0.00689476;

% NOTE: fluid strings here are the SHORT codes ("H2","He","Xe","CO2","CH4"),
% same convention as filedataExp.Fluid1/Fluid2 in main_DataExtract.m.
% fluidNameREFPROP() does the short-code -> REFPROP-library-name translation
% (H2->HYDROGEN, He->HELIUM, Xe->XENON, ...) INSIDE getFluidProps_REFPROP /
% getMixtureProps_REFPROP, so callers must NOT pass "HELIUM"/"XENON" directly
% -- and filedataDiff.Fluid (LJ table) is matched against these same short
% codes with no translation at all.
cases = struct( ...
    'label',  {'H2-CO2', 'H2-CH4', 'He-Xe', 'He-Xe'}, ...
    'fl',     {{"H2","CO2"}, {"H2","CH4"}, {"He","Xe"}, {"He","Xe"}}, ...
    'method', {'REFPROP', 'REFPROP', 'REFPROP', 'REFPROP'}, ...
    'P_psig', {1160, 1160, 725, 900}, ...
    'T_C',    {40, 40, 20, 20} );

mkdir('results/combined_rhoNorm_4curves');
pathExportAll = 'results/combined_rhoNorm_4curves/';

%% Pre-load shared inputs

% REFPROP session (used for all 4 cases)
RP = initREFPROP();

%% Compute rho(x1) for each case

results = struct();

for c = 1:numel(cases)

    fl      = cases(c).fl;
    P_MPa   = psig2MPa(cases(c).P_psig);
    T_C     = cases(c).T_C;
    T_K     = T_C + 273.15;

    % all 4 cases: REFPROP (getMixtureProps_REFPROP), same call as
    % main_DataExtract.m's eosMethod == "REFPROP" branch
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
%% Summary table: rho, Z, mu, D12 at pure1 (x1=1), 50/50 mix (x1=0.5), pure2 (x1=0)
%
% DIFFUSION (D12, Thorne-Enskog): calc_diff_thorne needs Lennard-Jones
% sigma/eps per pure fluid. These are loaded from your own diffusion-input
% file, the same way main_DataExtract.m does it when diffMethod == "Thorne":
%   diffConfig  = readtable('inputDiffConfig.xlsx');
%   idxDiff     = strcmp(diffConfig.Model,"Thorne");
%   filenameDiff= diffConfig.inputDiffModel{idxDiff};
%   filedataDiff= import_params_diffusion_LJ(filenameDiff);
% filedataDiff is expected to have one row per fluid with columns
% Fluid, sigma, eps, dsigma, deps (same fields calc_diff_thorne consumes
% in main_DataExtract.m's own Thorne branch).

diffConfig  = readtable('inputDiffConfig.xlsx');
idxDiffLJ   = strcmp(diffConfig.Model, "Thorne");
if ~any(idxDiffLJ)
    error('Thorne model not found in inputDiffConfig.xlsx');
end
filenameDiffLJ = diffConfig.inputDiffModel{idxDiffLJ};
filedataDiff   = import_params_diffusion_LJ(filenameDiffLJ);

% mixture viscosity is not returned by getMixtureProps_REFPROP, so call
% REFPROPdll directly for VIS the same way getFluidProps_REFPROP does,
% but with a 2-component composition vector
getMixtureVisc_REFPROP = @(RP,fl1,fl2,z,T,P) local_mix_vis(RP,fl1,fl2,z,T,P);

summaryRows = table();
for c = 1:numel(cases)

    fl    = cases(c).fl;
    P_MPa = psig2MPa(cases(c).P_psig);
    P_kPa = P_MPa*1000;
    T_C   = cases(c).T_C;
    T_K   = T_C + 273.15;

    % --- pure component 1 (x1 = 1) ---
    pure1 = getFluidProps_REFPROP(RP, char(fl{1}), T_K, P_kPa);

    % --- pure component 2 (x1 = 0) ---
    pure2 = getFluidProps_REFPROP(RP, char(fl{2}), T_K, P_kPa);

    % --- 50/50 mixture (x1 = 0.5) ---
    mix = getMixtureProps_REFPROP(RP, {char(fl{1}), char(fl{2})}, [0.5 0.5], T_K, P_kPa);
    mix.mu = getMixtureVisc_REFPROP(RP, char(fl{1}), char(fl{2}), [0.5 0.5], T_K, P_kPa);

    % --- diffusion coefficient at x1 = 0.5 (Thorne-Enskog) ---
    lj1 = filedataDiff(strcmp(filedataDiff.Fluid, char(fl{1})), :);
    lj2 = filedataDiff(strcmp(filedataDiff.Fluid, char(fl{2})), :);
    if height(lj1) ~= 1 || height(lj2) ~= 1
        error(['LJ parameter lookup for %s/%s returned %d/%d rows ' ...
            '(expected exactly 1 each). Check that filedataDiff.Fluid ' ...
            'values match "%s"/"%s" exactly.'], ...
            fl{1}, fl{2}, height(lj1), height(lj2), fl{1}, fl{2});
    end
    [D12TE_cm2min, dD12TE_cm2min] = calc_diff_thorne( ...
        char(fl{1}), char(fl{2}), [0.5 0.5], T_C, cases(c).P_psig, ...
        lj1.sigma, lj2.sigma, lj1.eps, lj2.eps, ...
        lj1.dsigma, lj2.dsigma, lj1.deps, lj2.deps);

    % --- assemble rows ---
    summaryRows = [summaryRows; table( ...
        {cases(c).label}, cases(c).P_psig, P_MPa, T_C, {'pure1 (x1=1)'}, 1.0, ...
        pure1.rho, pure1.Z, pure1.mu, NaN, ...
        'VariableNames', {'Pair','P_psig','P_MPa','T_C','Point','x1','rho','Z','mu_Pas','D12_cm2min'})]; %#ok<AGROW>

    summaryRows = [summaryRows; table( ...
        {cases(c).label}, cases(c).P_psig, P_MPa, T_C, {'mix (x1=0.5)'}, 0.5, ...
        mix.rho, mix.Z, mix.mu, D12TE_cm2min, ...
        'VariableNames', {'Pair','P_psig','P_MPa','T_C','Point','x1','rho','Z','mu_Pas','D12_cm2min'})]; %#ok<AGROW>

    summaryRows = [summaryRows; table( ...
        {cases(c).label}, cases(c).P_psig, P_MPa, T_C, {'pure2 (x1=0)'}, 0.0, ...
        pure2.rho, pure2.Z, pure2.mu, NaN, ...
        'VariableNames', {'Pair','P_psig','P_MPa','T_C','Point','x1','rho','Z','mu_Pas','D12_cm2min'})]; %#ok<AGROW>
end

disp(summaryRows)
writetable(summaryRows, pathExportAll + "props_summary_pure_and_mix.xlsx");
save(pathExportAll + "props_summary_pure_and_mix.mat", 'summaryRows', 'filedataDiff');

%% local helper: mixture viscosity via REFPROPdll (mirrors getFluidProps_REFPROP's VIS call)
function mu = local_mix_vis(RP, fluid1, fluid2, z, T, P)
fluid1 = char(fluidNameREFPROP(fluid1));
fluid2 = char(fluidNameREFPROP(fluid2));
fluidString = strjoin({fluid1, fluid2}, '*');
zREF = zeros(1,20);
zREF(1:length(z)) = z;
zREF = py.list(num2cell(zREF));
out = RP.REFPROPdll( ...
    fluidString, ...
    'TP', ...
    'VIS', ...
    int32(0), int32(0), int32(0), ...
    T, P, zREF);
mu_microPas = double(out.Output(1));
mu = mu_microPas*1e-6; % Pa*s
end