%% main_fluidProps_errorProp.m
% Author: Ianna Gomez Mendez (script assembled to extend main_DataExtract.m)
%
% PURPOSE
%   For each of the 4 cases (H2-CO2, H2-CH4, He-Xe@725psig, He-Xe@900psig),
%   report density (rho), compressibility (Z), viscosity (mu) and the
%   Thorne-Enskog binary diffusion coefficient (D12) at:
%       x1 = 1   (pure component 1)
%       x1 = 0.5 (50/50 mixture)
%       x1 = 0   (pure component 2)
%   together with propagated uncertainty, using the SAME finite-difference
%   propagation convention already used in main_DataExtract.m
%   (e.g. dmu1 = sqrt(dmu1_dT^2 + dmu1_dP^2), with
%   dmu1_dT = (mu(Tmax)-mu(Tmin))/2 ).
%
% UNCERTAINTY INPUTS (fill these in before running)
%   dT_C      : std of temperature [C] for each case
%   dP_psig   : std of pressure [psig] for each case
%   (sigma/eps uncertainties for D12 come from your own LJ input file via
%    import_params_diffusion_LJ, same as calc_diff_thorne's own usage in
%    main_DataExtract.m's Thorne branch - no extra input needed for those.)
%
% PROPAGATION METHOD
%   rho, Z, mu  : central finite difference in T and P independently,
%                 combined in quadrature:
%                     dvar = sqrt( dvar_dT^2 + dvar_dP^2 )
%                     dvar_dT = (var(T+dT,P) - var(T-dT,P)) / 2
%                     dvar_dP = (var(T,P+dP) - var(T,P-dP)) / 2
%   D12 (Thorne-Enskog):
%                 calc_diff_thorne already propagates sigma/eps uncertainty
%                 internally and returns dD12_sigmaeps. This script ALSO
%                 perturbs T and P (same finite-difference convention as
%                 above) to get dD12_dT, dD12_dP, and combines everything
%                 in quadrature:
%                     dD12_total = sqrt( dD12_sigmaeps^2 ...
%                                        + (dD12_dT*dT)^2 + (dD12_dP*dP)^2 )
%
% DEPENDENCIES
%   initREFPROP, getFluidProps_REFPROP, getMixtureProps_REFPROP,
%   fluidNameREFPROP, calc_diff_thorne, import_params_diffusion_LJ

%% INPUT

addpath('functions/');

psig2MPa = @(psig) (psig + 14.696) * 0.00689476;

% NOTE: fluid strings are SHORT codes ("H2","He","Xe","CO2","CH4"), same
% convention as filedataExp.Fluid1/Fluid2 in main_DataExtract.m -
% fluidNameREFPROP() translates them to REFPROP library names internally,
% and filedataDiff.Fluid (LJ table) is matched against these same short
% codes with no translation.
cases = struct( ...
    'label',   {'H2-CO2', 'H2-CH4', 'He-Xe', 'He-Xe'}, ...
    'fl',      {{"H2","CO2"}, {"H2","CH4"}, {"He","Xe"}, {"He","Xe"}}, ...
    'P_psig',  {1160, 1160, 725, 900}, ...
    'T_C',     {40, 40, 20, 20}, ...
    'dT_C',    {0.5, 0.5, 0.3, 0.3}, ...   % <-- EDIT: your T std per case [C]
    'dP_psig', {5,   5,   3,   3} );       % <-- EDIT: your P std per case [psig]

mkdir('results/combined_rhoNorm_4curves');
pathExportAll = 'results/combined_rhoNorm_4curves/';

%% Load LJ diffusion parameters (same path as main_DataExtract.m, diffMethod == "Thorne")

diffConfig  = readtable('inputDiffConfig.xlsx');
idxDiffLJ   = strcmp(diffConfig.Model, "Thorne");
if ~any(idxDiffLJ)
    error('Thorne model not found in inputDiffConfig.xlsx');
end
filenameDiffLJ = diffConfig.inputDiffModel{idxDiffLJ};
filedataDiff   = import_params_diffusion_LJ(filenameDiffLJ);

%% Init REFPROP

RP = initREFPROP();

%% Compute nominal + perturbed properties, propagate uncertainty

summaryRows = table();

for c = 1:numel(cases)

    fl      = cases(c).fl;
    P_psig  = cases(c).P_psig;
    T_C     = cases(c).T_C;
    dT_C    = cases(c).dT_C;
    dP_psig = cases(c).dP_psig;

    P_MPa    = psig2MPa(P_psig);
    P_MPa_Tp = psig2MPa(P_psig);   % P unperturbed when perturbing T
    P_kPa    = P_MPa*1000;

    T_K     = T_C + 273.15;
    T_K_min = (T_C - dT_C) + 273.15;
    T_K_max = (T_C + dT_C) + 273.15;

    P_MPa_min = psig2MPa(P_psig - dP_psig);
    P_MPa_max = psig2MPa(P_psig + dP_psig);
    P_kPa_min = P_MPa_min*1000;
    P_kPa_max = P_MPa_max*1000;

    % LJ params for D12
    lj1 = filedataDiff(strcmp(filedataDiff.Fluid, char(fl{1})), :);
    lj2 = filedataDiff(strcmp(filedataDiff.Fluid, char(fl{2})), :);
    if height(lj1) ~= 1 || height(lj2) ~= 1
        error(['LJ parameter lookup for %s/%s returned %d/%d rows ' ...
            '(expected exactly 1 each). Check that filedataDiff.Fluid ' ...
            'values match "%s"/"%s" exactly.'], ...
            fl{1}, fl{2}, height(lj1), height(lj2), fl{1}, fl{2});
    end

    % ---- the 3 composition points to report ----
    points = struct('label', {'pure1 (x1=1)','mix (x1=0.5)','pure2 (x1=0)'}, ...
                     'x1',    {1.0,            0.5,           0.0});

    for p = 1:numel(points)
        x1pt = points(p).x1;
        z    = [x1pt, 1-x1pt];

        % ---- nominal properties ----
        [rho0, Z0, mu0] = local_props_at(RP, fl, z, T_K, P_kPa);

        % ---- T-perturbed properties (P fixed) ----
        [rho_Tmin, Z_Tmin, mu_Tmin] = local_props_at(RP, fl, z, T_K_min, P_kPa);
        [rho_Tmax, Z_Tmax, mu_Tmax] = local_props_at(RP, fl, z, T_K_max, P_kPa);

        % ---- P-perturbed properties (T fixed) ----
        [rho_Pmin, Z_Pmin, mu_Pmin] = local_props_at(RP, fl, z, T_K, P_kPa_min);
        [rho_Pmax, Z_Pmax, mu_Pmax] = local_props_at(RP, fl, z, T_K, P_kPa_max);

        % ---- finite-difference partials ----
        drho_dT = (rho_Tmax - rho_Tmin)/2;  drho_dP = (rho_Pmax - rho_Pmin)/2;
        dZ_dT   = (Z_Tmax   - Z_Tmin)/2;    dZ_dP   = (Z_Pmax   - Z_Pmin)/2;
        dmu_dT  = (mu_Tmax  - mu_Tmin)/2;   dmu_dP  = (mu_Pmax  - mu_Pmin)/2;

        % ---- propagated uncertainty (quadrature, same convention as main_DataExtract.m) ----
        drho = sqrt(drho_dT^2 + drho_dP^2);
        dZ   = sqrt(dZ_dT^2   + dZ_dP^2);
        dmu  = sqrt(dmu_dT^2  + dmu_dP^2);

        % ---- D12 only defined/meaningful at the mixture point ----
        D12 = NaN; dD12 = NaN;
        if x1pt == 0.5
            [D12, dD12_sigmaeps] = calc_diff_thorne( ...
                char(fl{1}), char(fl{2}), [0.5 0.5], T_C, P_psig, ...
                lj1.sigma, lj2.sigma, lj1.eps, lj2.eps, ...
                lj1.dsigma, lj2.dsigma, lj1.deps, lj2.deps);

            [D12_Tmin, ~] = calc_diff_thorne(char(fl{1}), char(fl{2}), [0.5 0.5], ...
                T_C - dT_C, P_psig, lj1.sigma, lj2.sigma, lj1.eps, lj2.eps, ...
                lj1.dsigma, lj2.dsigma, lj1.deps, lj2.deps);
            [D12_Tmax, ~] = calc_diff_thorne(char(fl{1}), char(fl{2}), [0.5 0.5], ...
                T_C + dT_C, P_psig, lj1.sigma, lj2.sigma, lj1.eps, lj2.eps, ...
                lj1.dsigma, lj2.dsigma, lj1.deps, lj2.deps);
            [D12_Pmin, ~] = calc_diff_thorne(char(fl{1}), char(fl{2}), [0.5 0.5], ...
                T_C, P_psig - dP_psig, lj1.sigma, lj2.sigma, lj1.eps, lj2.eps, ...
                lj1.dsigma, lj2.dsigma, lj1.deps, lj2.deps);
            [D12_Pmax, ~] = calc_diff_thorne(char(fl{1}), char(fl{2}), [0.5 0.5], ...
                T_C, P_psig + dP_psig, lj1.sigma, lj2.sigma, lj1.eps, lj2.eps, ...
                lj1.dsigma, lj2.dsigma, lj1.deps, lj2.deps);

            dD12_dT = (D12_Tmax - D12_Tmin)/2;
            dD12_dP = (D12_Pmax - D12_Pmin)/2;

            dD12 = sqrt(dD12_sigmaeps^2 + dD12_dT^2 + dD12_dP^2);
        end

        summaryRows = [summaryRows; table( ...
            {cases(c).label}, P_psig, P_MPa, T_C, dT_C, dP_psig, ...
            {points(p).label}, x1pt, ...
            rho0, drho, Z0, dZ, mu0, dmu, D12, dD12, ...
            'VariableNames', {'Pair','P_psig','P_MPa','T_C','dT_C','dP_psig', ...
            'Point','x1','rho','drho','Z','dZ','mu_Pas','dmu_Pas', ...
            'D12_cm2min','dD12_cm2min'})]; %#ok<AGROW>
    end
end

disp(summaryRows)
writetable(summaryRows, pathExportAll + "props_summary_pure_and_mix_errProp.xlsx");
save(pathExportAll + "props_summary_pure_and_mix_errProp.mat", 'summaryRows', 'filedataDiff', 'cases');

%% local helpers

function [rho, Z, mu] = local_props_at(RP, fl, z, T_K, P_kPa)
% rho, Z, mu for a pure fluid (z=[1 0] or [0 1]) or a 2-component mixture,
% at given T [K] and P [kPa].
if z(1) == 1
    props = getFluidProps_REFPROP(RP, char(fl{1}), T_K, P_kPa);
    rho = props.rho; Z = props.Z; mu = props.mu;
elseif z(2) == 1
    props = getFluidProps_REFPROP(RP, char(fl{2}), T_K, P_kPa);
    rho = props.rho; Z = props.Z; mu = props.mu;
else
    mixProps = getMixtureProps_REFPROP(RP, {char(fl{1}), char(fl{2})}, z, T_K, P_kPa);
    rho = mixProps.rho; Z = mixProps.Z;
    mu = local_mix_vis(RP, char(fl{1}), char(fl{2}), z, T_K, P_kPa);
end
end

function mu = local_mix_vis(RP, fluid1, fluid2, z, T, P)
% mixture viscosity via REFPROPdll, same call pattern as getFluidProps_REFPROP's
% VIS call, but for a 2-component composition vector (not returned by
% getMixtureProps_REFPROP, which only gives rho/Z/MW).
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