%% main_fluidProps_errorProp.m
% Author: Ianna Gomez Mendez (script assembled to extend main_DataExtract.m)
%
% PURPOSE
%   For each case, report density (rho), compressibility (Z), viscosity (mu)
%   and the Thorne-Enskog binary diffusion coefficient (D12) at:
%       x1 = 1   (pure component 1)  -> evaluated at (T1, P1)
%       x1 = 0.5 (50/50 mixture)     -> evaluated at (Tmix, Pmix)
%       x1 = 0   (pure component 2)  -> evaluated at (T2, P2)
%   together with propagated uncertainty, using the SAME finite-difference
%   propagation convention already used in main_DataExtract.m.
%
%   Because temperature (and pressure) drift during the experiment, each
%   fluid now has its OWN conditions:
%       T1_C, dT1_C, P1_psig, dP1_psig : conditions while fluid 1 is measured
%       T2_C, dT2_C, P2_psig, dP2_psig : conditions while fluid 2 is measured
%   so mu1 = mu(fluid1; T1, P1) and mu2 = mu(fluid2; T2, P2), and hence
%   M = mu2/mu1 reflects the actual conditions each fluid saw.
%
% MIXTURE (x1 = 0.5) CONDITIONS
%   The 50/50 point (and therefore D12 and Pe) is evaluated at the mean
%   conditions:
%       Tmix = (T1 + T2)/2,          Pmix = (P1 + P2)/2
%       dTmix = sqrt((dT1^2 + dT2^2)/2)   (RMS of the two stds)
%       dPmix = sqrt((dP1^2 + dP2^2)/2)
%   Set includeSpreadInMix = true below to also add the half-spread
%   |T1-T2|/2 (and |P1-P2|/2) in quadrature to dTmix (dPmix), i.e. treat the
%   fact that the mixing zone saw conditions anywhere between the two as
%   additional uncertainty.
%
% DIMENSIONLESS NUMBERS (same definitions/convention as main_DataExtract.m)
%   M    = mu2/mu1                           viscosity ratio (displaced/displacing)
%   Nrho = (rho1-rho2)/rho2                   density number
%   Ng   = K*(rho1-rho2)*g*sin(theta)/(mu2*u) gravity number
%   Pe   = u*L/D12                            Peclet number
%   fluid "1" = fl{1} (injected/displacing) at (T1,P1),
%   fluid "2" = fl{2} (displaced)           at (T2,P2),
%   D12 at the 50/50 mixture point (Tmix,Pmix).
%
% PROPAGATION METHOD
%   rho, Z, mu : central finite difference in T and P independently,
%                combined in quadrature:
%                    dvar    = sqrt( dvar_dT^2 + dvar_dP^2 )
%                    dvar_dT = (var(T+dT,P) - var(T-dT,P)) / 2
%                    dvar_dP = (var(T,P+dP) - var(T,P-dP)) / 2
%   D12        : sigma/eps uncertainty from calc_diff_thorne, plus T and P
%                perturbations (same convention), all in quadrature.
%
% DEPENDENCIES
%   initREFPROP, getFluidProps_REFPROP, getMixtureProps_REFPROP,
%   fluidNameREFPROP, calc_diff_thorne, import_params_diffusion_LJ

%% INPUT

addpath('functions/');

psig2MPa = @(psig) (psig + 14.696) * 0.00689476;

includeSpreadInMix = false;   % see header: add |T1-T2|/2, |P1-P2|/2 to mix uncertainty

% NOTE: T1/T2 and P1/P2 below are initialised to the previous single
% per-pair values so the script runs unchanged - EDIT them with the
% per-fluid measurements.
cases = struct( ...
    'label',   {'H2-CO2','H2-CO2','H2-CH4','H2-CH4','He-Xe','He-Xe','He-Xe','He-Xe', ...
                'H2-CO2','H2-CO2','H2-CH4','H2-CH4','H2-CH4','He-Xe','He-Xe','He-Xe','He-Xe', ...
                'H2-CO2','H2-CO2','H2-CH4','H2-CH4','H2-CH4','He-Xe','He-Xe','He-Xe','He-Xe'}, ...
    'fl',      {{"H2","CO2"},{"H2","CO2"},{"H2","CH4"},{"H2","CH4"},{"He","Xe"},{"He","Xe"},{"He","Xe"},{"He","Xe"}, ...
                {"H2","CO2"},{"H2","CO2"},{"H2","CH4"},{"H2","CH4"},{"H2","CH4"},{"He","Xe"},{"He","Xe"},{"He","Xe"},{"He","Xe"}, ...
                {"H2","CO2"},{"H2","CO2"},{"H2","CH4"},{"H2","CH4"},{"H2","CH4"},{"He","Xe"},{"He","Xe"},{"He","Xe"},{"He","Xe"}}, ...
    ... % ---------------- fluid 1 (displacing / injected) ----------------
    'T1_C',    {40, 40, 40, 40, 20, 20, 20, 20, ...
                36.82, 37.36, 35.46, 37.58, 37.55, 29.26, 26.83, 28.73, 26.28, ...
                36.25, 35.91, 35.73, 37.41, 37.69, 29.40, 27.02, 30.01, 27.36}, ...   % <-- EDIT [C]
    'dT1_C',   {0, 0, 0, 0, 0, 0, 0, 0, ...
                0.94, 2.23, 0.364, 0.332, 0.297, 0.395, 0.636, 1.856, 2.238, ...
                0.14, 0.32, 0.07, 0.12, 0.25, 0.04, 0.06, 0.04, 0.05}, ...    % <-- EDIT [C]
    'P1_psig', {1160, 1160, 1160, 1160, 725, 725, 900, 900, ...
                1158, 1167, 1162, 1168, 1166, 728.7, 730.6, 877.2, 884.8, ...
                1153, 1165, 1159, 1167, 1163, 722.9, 727.4, 900.1, 904.5}, ...       % <-- EDIT [psig]
    'dP1_psig',{0, 0, 0, 0, 0, 0, 0, 0, ...
                4.4, 1.6, 3.7, 0.4, 1.93, 4.3, 10.57, 57.73, 55.07, ...
                0.42, 0.27, 0.35, 0.39, 0.94, 0.11, 0.14, 0.14, 0.56}, ...             % <-- EDIT [psig]
    ... % ---------------- fluid 2 (displaced / resident) ----------------
    'T2_C',    {40, 40, 40, 40, 20, 20, 20, 20, ...
                36.82, 37.36, 35.46, 37.58, 37.55, 29.26, 26.83, 28.73, 26.28, ...
                37.70, 41.12, 35.02, 37.94, 37.25, 28.83, 25.87, 26.36, 22.74}, ...   % <-- EDIT [C]
    'dT2_C',   {0, 0, 0, 0, 0, 0, 0, 0, ...
                0.94, 2.23, 0.364, 0.332, 0.297, 0.395, 0.636, 1.856, 2.238, ...
                0.27, 0.31, 0.13, 0.17,  0.11, 0.12, 0.18, 0.70, 0.56}, ...    % <-- EDIT [C]
    'P2_psig', {1160, 1160, 1160, 1160, 725, 725, 900, 900, ...
                1158, 1167, 1162, 1168, 1166, 728.7, 730.6, 877.2, 884.8, ...
                1163, 1169, 1164, 1168, 1167, 729.4, 731.2, 907.2, 908.8}, ...       % <-- EDIT [psig]
    'dP2_psig',{0, 0, 0, 0, 0, 0, 0, 0, ...
                4.4, 1.6, 3.7, 0.4, 1.93, 4.3, 10.57, 57.73, 55.07, ...
                0.23, 0.42, 0.17, 0.22, 0.15, 0.12, 0.33, 1.58, 0.71}, ...             % <-- EDIT [psig]
    ... % ---------------- flow / core parameters ----------------
    'u_cmmin',  {0.256, 1.278, 0.256, 1.278, 0.256, 1.278, 0.256, 1.278, ...
                 0.256, 1.278, 0.256, 1.278, 0.256, 0.256, 1.278, 0.256, 1.278, ...
                 0.256, 1.278, 0.256, 1.278, 0.256, 0.256, 1.278, 0.256, 1.278}, ... % interstitial velocity [cm/min]
    'du_cmmin', {0, 0, 0, 0, 0, 0, 0, 0, ...
                 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
                 0, 0, 0, 0, 0, 0, 0, 0, 0}, ...
    'K_mD',     {202, 202, 202, 202, 202, 202, 202, 202, ...
                 202, 202, 202, 202, 202, 202, 202, 202, 202, ...
                 202, 202, 202, 202, 202, 202, 202, 202, 202}, ...
    'dK_mD',    {0, 0, 0, 0, 0, 0, 0, 0, ...
                 0, 0, 0, 0, 0, 0, 0, 0, 0, ...
                 0, 0, 0, 0, 0, 0, 0, 0, 0}, ...
    'theta_deg',{90, 90, 90, 90, 90, 90, 90, 90, ...
                 90, 90, 90, 90, 90, 90, 90, 90, 90, ...
                 90, 90, 90, 90, 90, 90, 90, 90, 90}, ...
    'L_in',     {6, 6, 6, 6, 6, 6, 6, 6, ...
                 6, 6, 6, 6, 6, 6, 6, 6, 6, ...
                 6, 6, 6, 6, 6, 6, 6, 6, 6} );

% additional experiments, nominal conditions -- horizontal core (theta = 0) -> Ng = 0
% {label, fluids, T_C, P_psig, u_cmmin, theta_deg, K_mD, L_in}   <-- check K and L for these cores
extraCases = { ...
    'H2-CO2', {"H2","CO2"}, 32, 1500, 0.25564, 0, 202, 6; ...   % row 27  Q1
    'H2-CO2', {"H2","CO2"}, 32, 1500, 0.51128, 0, 202, 6; ...   % row 28  Q2
    'H2-CO2', {"H2","CO2"}, 32, 1500, 1.2782,  0, 202, 6; ...   % row 29  Q5
    'He-CO2', {"He","CO2"}, 40, 1500, 0.12782, 0, 202, 6; ...   % row 30  Q05
    'He-CO2', {"He","CO2"}, 40, 1500, 0.25564, 0, 202, 6; ...   % row 31  Q1 (R1 and R2)
    'He-CO2', {"He","CO2"}, 40, 1500, 0.51128, 0, 202, 6; ...   % row 32  Q2
    'He-CO2', {"He","CO2"}, 40, 1500, 1.2782,  0, 202, 6; ...   % row 33  Q5
    'He-CO2', {"He","CO2"}, 40, 1500, 2.5564,  0, 202, 6};      % row 34  Q10
for k = 1:size(extraCases,1)
    ec = extraCases(k,:);
    cases(end+1) = struct('label',ec{1}, 'fl',{ec{2}}, ...
        'T1_C',ec{3}, 'dT1_C',0, 'P1_psig',ec{4}, 'dP1_psig',0, ...
        'T2_C',ec{3}, 'dT2_C',0, 'P2_psig',ec{4}, 'dP2_psig',0, ...
        'u_cmmin',ec{5}, 'du_cmmin',0, 'K_mD',ec{7}, 'dK_mD',0, ...
        'theta_deg',ec{6}, 'L_in',ec{8}); %#ok<SAGROW>
end

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
dimlessRows = table();

for c = 1:numel(cases)

    fl = cases(c).fl;

    % ---- per-fluid conditions ----
    T1_C = cases(c).T1_C;  dT1_C = cases(c).dT1_C;
    P1_psig = cases(c).P1_psig;  dP1_psig = cases(c).dP1_psig;
    T2_C = cases(c).T2_C;  dT2_C = cases(c).dT2_C;
    P2_psig = cases(c).P2_psig;  dP2_psig = cases(c).dP2_psig;

    % ---- mixture (50/50) conditions ----
    Tmix_C     = (T1_C + T2_C)/2;
    Pmix_psig  = (P1_psig + P2_psig)/2;
    dTmix_C    = sqrt((dT1_C^2 + dT2_C^2)/2);
    dPmix_psig = sqrt((dP1_psig^2 + dP2_psig^2)/2);
    if includeSpreadInMix
        dTmix_C    = sqrt(dTmix_C^2    + ((T1_C - T2_C)/2)^2);
        dPmix_psig = sqrt(dPmix_psig^2 + ((P1_psig - P2_psig)/2)^2);
    end

    % LJ params for D12
    lj1 = filedataDiff(strcmp(filedataDiff.Fluid, char(fl{1})), :);
    lj2 = filedataDiff(strcmp(filedataDiff.Fluid, char(fl{2})), :);
    if height(lj1) ~= 1 || height(lj2) ~= 1
        error(['LJ parameter lookup for %s/%s returned %d/%d rows ' ...
            '(expected exactly 1 each). Check that filedataDiff.Fluid ' ...
            'values match "%s"/"%s" exactly.'], ...
            fl{1}, fl{2}, height(lj1), height(lj2), fl{1}, fl{2});
    end

    % ---- the 3 composition points, each with its own conditions ----
    points = struct( ...
        'label',   {'pure1 (x1=1)', 'mix (x1=0.5)', 'pure2 (x1=0)'}, ...
        'x1',      {1.0,      0.5,        0.0}, ...
        'T_C',     {T1_C,     Tmix_C,     T2_C}, ...
        'dT_C',    {dT1_C,    dTmix_C,    dT2_C}, ...
        'P_psig',  {P1_psig,  Pmix_psig,  P2_psig}, ...
        'dP_psig', {dP1_psig, dPmix_psig, dP2_psig});

    rho1 = NaN; drho1 = NaN; mu1 = NaN; dmu1 = NaN;   % pure1 at (T1,P1)
    rho2 = NaN; drho2 = NaN; mu2 = NaN; dmu2 = NaN;   % pure2 at (T2,P2)
    D12mix = NaN; dD12mix = NaN;                      % mix at (Tmix,Pmix)

    for p = 1:numel(points)
        x1pt    = points(p).x1;
        z       = [x1pt, 1-x1pt];
        T_C     = points(p).T_C;
        dT_C    = points(p).dT_C;
        P_psig  = points(p).P_psig;
        dP_psig = points(p).dP_psig;

        % ---- rho, Z, mu with T/P finite-difference propagation ----
        [rho0, drho, Z0, dZ, mu0, dmu] = ...
            local_props_errprop(RP, fl, z, T_C, dT_C, P_psig, dP_psig);

        % ---- D12 only at the mixture point ----
        D12 = NaN; dD12 = NaN;
        if x1pt == 0.5
            [D12, dD12_sigmaeps] = local_D12(fl, T_C,        P_psig,           lj1, lj2);
            D12_Tmin             = local_D12(fl, T_C - dT_C, P_psig,           lj1, lj2);
            D12_Tmax             = local_D12(fl, T_C + dT_C, P_psig,           lj1, lj2);
            D12_Pmin             = local_D12(fl, T_C,        P_psig - dP_psig, lj1, lj2);
            D12_Pmax             = local_D12(fl, T_C,        P_psig + dP_psig, lj1, lj2);

            dD12_dT = (D12_Tmax - D12_Tmin)/2;
            dD12_dP = (D12_Pmax - D12_Pmin)/2;
            dD12    = sqrt(dD12_sigmaeps^2 + dD12_dT^2 + dD12_dP^2);

            D12mix = D12; dD12mix = dD12;
        end

        if x1pt == 1.0
            rho1 = rho0; drho1 = drho; mu1 = mu0; dmu1 = dmu;
        elseif x1pt == 0.0
            rho2 = rho0; drho2 = drho; mu2 = mu0; dmu2 = dmu;
        end

        summaryRows = [summaryRows; table( ...
            {cases(c).label}, {points(p).label}, x1pt, ...
            T_C, dT_C, P_psig, dP_psig, psig2MPa(P_psig), ...
            rho0, drho, Z0, dZ, mu0, dmu, D12, dD12, ...
            'VariableNames', {'Pair','Point','x1', ...
            'T_C','dT_C','P_psig','dP_psig','P_MPa', ...
            'rho','drho','Z','dZ','mu_Pas','dmu_Pas', ...
            'D12_cm2min','dD12_cm2min'})]; %#ok<AGROW>
    end

    %% ---- Dimensionless numbers for this case (M, Nrho, Ng, Pe) ----

    u_SI  = cases(c).u_cmmin/(60*100);     % cm/min -> m/s
    du_SI = cases(c).du_cmmin/(60*100);
    K_SI  = cases(c).K_mD*9.869e-16;       % mD -> m^2
    dK_SI = cases(c).dK_mD*9.869e-16;
    theta = deg2rad(cases(c).theta_deg);
    L_SI  = cases(c).L_in*0.0254;          % in -> m
    D12_SI  = D12mix/(60*1e4);             % cm^2/min -> m^2/s
    dD12_SI = dD12mix/(60*1e4);

    % viscosity ratio M = mu2(T2,P2)/mu1(T1,P1)
    M  = mu2/mu1;
    dM = sqrt( ((-mu2*dmu1)/(mu1^2))^2 + (dmu2/mu1)^2 );

    % density number Nrho = (rho1-rho2)/rho2
    Nrho  = (rho1-rho2)/rho2;
    dNrho = sqrt( (drho1/rho2)^2 + ((-rho1*drho2)/(rho2^2))^2 );

    % gravity number Ng = K*(rho1-rho2)*g*sin(theta)/(mu2*u)
    Ng  = K_SI*(rho1-rho2)*9.8*sin(theta)/(mu2*u_SI);
    dNg = abs(Ng)*sqrt( (drho1/(rho1-rho2))^2 + (drho2/(rho1-rho2))^2 ...
                      + (dmu2/mu2)^2 + (du_SI/u_SI)^2 + (dK_SI/K_SI)^2 );

    % Peclet number Pe = u*L/D12 (D12 at the 50/50 mixture point)
    Pe  = u_SI*L_SI/D12_SI;
    dPe = Pe*sqrt( (du_SI/u_SI)^2 + (dD12_SI/D12_SI)^2 );

    dimlessRows = [dimlessRows; table( ...
        {cases(c).label}, ...
        T1_C, dT1_C, P1_psig, dP1_psig, ...
        T2_C, dT2_C, P2_psig, dP2_psig, ...
        Tmix_C, dTmix_C, Pmix_psig, dPmix_psig, ...
        cases(c).u_cmmin, cases(c).du_cmmin, cases(c).K_mD, cases(c).dK_mD, ...
        cases(c).theta_deg, cases(c).L_in, ...
        mu1, dmu1, mu2, dmu2, ...
        M, dM, Nrho, dNrho, Ng, dNg, Pe, dPe, ...
        'VariableNames', {'Pair', ...
        'T1_C','dT1_C','P1_psig','dP1_psig', ...
        'T2_C','dT2_C','P2_psig','dP2_psig', ...
        'Tmix_C','dTmix_C','Pmix_psig','dPmix_psig', ...
        'u_cmmin','du_cmmin','K_mD','dK_mD','theta_deg','L_in', ...
        'mu1_Pas','dmu1_Pas','mu2_Pas','dmu2_Pas', ...
        'M','dM','Nrho','dNrho','Ng','dNg','Pe','dPe'})]; %#ok<AGROW>
end

disp(summaryRows)
writetable(summaryRows, pathExportAll + "props_summary_pure_and_mix_errProp.xlsx");

disp(dimlessRows)
writetable(dimlessRows, pathExportAll + "dimless_numbers_errProp.xlsx");

save(pathExportAll + "props_summary_pure_and_mix_errProp.mat", ...
    'summaryRows', 'dimlessRows', 'filedataDiff', 'cases', 'includeSpreadInMix');

%% local helpers

function P_kPa = local_psig2kPa(P_psig)
P_kPa = (P_psig + 14.696) * 6.89476;
end

function [rho0, drho, Z0, dZ, mu0, dmu] = local_props_errprop(RP, fl, z, T_C, dT_C, P_psig, dP_psig)
% Nominal rho, Z, mu at (T_C, P_psig) and their uncertainties from central
% finite differences in T and P (+/- one std), combined in quadrature.
T_K     = T_C + 273.15;
T_K_min = T_C - dT_C + 273.15;
T_K_max = T_C + dT_C + 273.15;
P_kPa     = local_psig2kPa(P_psig);
P_kPa_min = local_psig2kPa(P_psig - dP_psig);
P_kPa_max = local_psig2kPa(P_psig + dP_psig);

[rho0,     Z0,     mu0    ] = local_props_at(RP, fl, z, T_K,     P_kPa);
[rho_Tmin, Z_Tmin, mu_Tmin] = local_props_at(RP, fl, z, T_K_min, P_kPa);
[rho_Tmax, Z_Tmax, mu_Tmax] = local_props_at(RP, fl, z, T_K_max, P_kPa);
[rho_Pmin, Z_Pmin, mu_Pmin] = local_props_at(RP, fl, z, T_K,     P_kPa_min);
[rho_Pmax, Z_Pmax, mu_Pmax] = local_props_at(RP, fl, z, T_K,     P_kPa_max);

drho = sqrt(((rho_Tmax - rho_Tmin)/2)^2 + ((rho_Pmax - rho_Pmin)/2)^2);
dZ   = sqrt(((Z_Tmax   - Z_Tmin  )/2)^2 + ((Z_Pmax   - Z_Pmin  )/2)^2);
dmu  = sqrt(((mu_Tmax  - mu_Tmin )/2)^2 + ((mu_Pmax  - mu_Pmin )/2)^2);
end

function [D12, dD12_sigmaeps] = local_D12(fl, T_C, P_psig, lj1, lj2)
% Thorne-Enskog D12 for a 50/50 mixture at (T_C, P_psig).
[D12, dD12_sigmaeps] = calc_diff_thorne( ...
    char(fl{1}), char(fl{2}), [0.5 0.5], T_C, P_psig, ...
    lj1.sigma, lj2.sigma, lj1.eps, lj2.eps, ...
    lj1.dsigma, lj2.dsigma, lj1.deps, lj2.deps);
end

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
% mixture viscosity via REFPROPdll (2-component composition vector).
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