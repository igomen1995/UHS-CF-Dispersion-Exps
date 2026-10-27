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
%   Pe   = u*L/D12                            Peclet number (core length)
%   Pep  = u*d_pore/D12                       pore Peclet number (pore diameter,
%                                             Gray Berea d_pore = 70 um, see INPUT)
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

% pore Peclet number Pe_p = u*d_pore/D12
dpore_um  = 70;    % mean pore diameter of Gray Berea sandstone [um]
ddpore_um = 0;     % uncertainty of d_pore [um] (0 = not propagated)

% ======================================================================
% CASE TABLE -- one row per case
%   {label, fluids, group, key, ...
%    T1_C, dT1_C, P1_psig, dP1_psig, ...    fluid 1 (displacing) -- start of injection
%    T2_C, dT2_C, P2_psig, dP2_psig, ...    fluid 2 (displaced)  -- end / resident
%    u_cmmin, theta_deg, K_mD, L_in}
%   group: "theory" (nominal), "measAvg" (run average, T1=T2), "measBegEnd" (init/final)
%   rows with any NaN in the conditions are skipped (fill them when available)
%   key: experiment name (UHS keys are placeholders -- rename to your MFM keys if needed)
% ======================================================================
caseTable = { ...
% ---------------- UHS + He-Xe, theory (nominal) ---------------- rows 1-8
'H2-CO2', {"H2","CO2"}, "theory", "UHS_H2_CO2_Q1_R1",          40,0,1160,0,      40,0,1160,0,      0.256, 90, 202, 6;
'H2-CO2', {"H2","CO2"}, "theory", "UHS_H2_CO2_Q5_R1",          40,0,1160,0,      40,0,1160,0,      1.278, 90, 202, 6;
'H2-CH4', {"H2","CH4"}, "theory", "UHS_H2_CH4_Q1_R1",          40,0,1160,0,      40,0,1160,0,      0.256, 90, 202, 6;
'H2-CH4', {"H2","CH4"}, "theory", "UHS_H2_CH4_Q5_R1",          40,0,1160,0,      40,0,1160,0,      1.278, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "theory", "CF_He_Xe_T20_P725_V_Q1_R1", 20,0,725,0,       20,0,725,0,       0.256, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "theory", "CF_He_Xe_T20_P725_V_Q5_R1", 20,0,725,0,       20,0,725,0,       1.278, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "theory", "CF_He_Xe_T20_P900_V_Q1_R1", 20,0,900,0,       20,0,900,0,       0.256, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "theory", "CF_He_Xe_T20_P900_V_Q5_R1", 20,0,900,0,       20,0,900,0,       1.278, 90, 202, 6;
% ---------------- UHS + He-Xe, measured run average ---------------- rows 9-17
'H2-CO2', {"H2","CO2"}, "measAvg", "UHS_H2_CO2_Q1_R1",          36.82,0.94,1158,4.4,     36.82,0.94,1158,4.4,     0.256, 90, 202, 6;
'H2-CO2', {"H2","CO2"}, "measAvg", "UHS_H2_CO2_Q5_R1",          37.36,2.23,1167,1.6,     37.36,2.23,1167,1.6,     1.278, 90, 202, 6;
'H2-CH4', {"H2","CH4"}, "measAvg", "UHS_H2_CH4_Q1_R1",          35.46,0.364,1162,3.7,    35.46,0.364,1162,3.7,    0.256, 90, 202, 6;
'H2-CH4', {"H2","CH4"}, "measAvg", "UHS_H2_CH4_Q5_R1",          37.58,0.332,1168,0.4,    37.58,0.332,1168,0.4,    1.278, 90, 202, 6;
'H2-CH4', {"H2","CH4"}, "measAvg", "UHS_H2_CH4_Q1_R2",          37.55,0.297,1166,1.93,   37.55,0.297,1166,1.93,   0.256, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "measAvg", "CF_He_Xe_T20_P725_V_Q1_R1", 29.26,0.395,728.7,4.3,  29.26,0.395,728.7,4.3,  0.256, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "measAvg", "CF_He_Xe_T20_P725_V_Q5_R1", 26.83,0.636,730.6,10.57, 26.83,0.636,730.6,10.57, 1.278, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "measAvg", "CF_He_Xe_T20_P900_V_Q1_R1", 28.73,1.856,877.2,57.73, 28.73,1.856,877.2,57.73, 0.256, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "measAvg", "CF_He_Xe_T20_P900_V_Q5_R1", 26.28,2.238,884.8,55.07, 26.28,2.238,884.8,55.07, 1.278, 90, 202, 6;
% ---------------- UHS + He-Xe, measured init/final ---------------- rows 18-26
'H2-CO2', {"H2","CO2"}, "measBegEnd", "UHS_H2_CO2_Q1_R1",          36.25,0.14,1153,0.42,   37.70,0.27,1163,0.23,   0.256, 90, 202, 6;
'H2-CO2', {"H2","CO2"}, "measBegEnd", "UHS_H2_CO2_Q5_R1",          35.91,0.32,1165,0.27,   41.12,0.31,1169,0.42,   1.278, 90, 202, 6;
'H2-CH4', {"H2","CH4"}, "measBegEnd", "UHS_H2_CH4_Q1_R1",          35.73,0.07,1159,0.35,   35.02,0.13,1164,0.17,   0.256, 90, 202, 6;
'H2-CH4', {"H2","CH4"}, "measBegEnd", "UHS_H2_CH4_Q5_R1",          37.41,0.12,1167,0.39,   37.94,0.17,1168,0.22,   1.278, 90, 202, 6;
'H2-CH4', {"H2","CH4"}, "measBegEnd", "UHS_H2_CH4_Q1_R2",          37.69,0.25,1163,0.94,   37.25,0.11,1167,0.15,   0.256, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "measBegEnd", "CF_He_Xe_T20_P725_V_Q1_R1", 29.40,0.04,722.9,0.11,  28.83,0.12,729.4,0.12,  0.256, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "measBegEnd", "CF_He_Xe_T20_P725_V_Q5_R1", 27.02,0.06,727.4,0.14,  25.87,0.18,731.2,0.33,  1.278, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "measBegEnd", "CF_He_Xe_T20_P900_V_Q1_R1", 30.01,0.04,900.1,0.14,  26.36,0.70,907.2,1.58,  0.256, 90, 202, 6;
'He-Xe',  {"He","Xe"},  "measBegEnd", "CF_He_Xe_T20_P900_V_Q5_R1", 27.36,0.05,904.5,0.56,  22.74,0.56,908.8,0.71,  1.278, 90, 202, 6;
% ---------------- extra (horizontal, Ng = 0), theory ---------------- rows 27-34
'H2-CO2', {"H2","CO2"}, "theory", "CF_H2_CO2_T32_P1500_H_Q1_R1",   32,0,1500,0,  32,0,1500,0,  0.25564, 0, 202, 6;
'H2-CO2', {"H2","CO2"}, "theory", "CF_H2_CO2_T32_P1500_H_Q2_R1",   32,0,1500,0,  32,0,1500,0,  0.51128, 0, 202, 6;
'H2-CO2', {"H2","CO2"}, "theory", "CF_H2_CO2_T32_P1500_H_Q5_R1",   32,0,1500,0,  32,0,1500,0,  1.2782,  0, 202, 6;
'He-CO2', {"He","CO2"}, "theory", "CF_He_CO2_T40_P1500_H_Q05_R1",  40,0,1500,0,  40,0,1500,0,  0.12782, 0, 202, 6;
'He-CO2', {"He","CO2"}, "theory", "CF_He_CO2_T40_P1500_H_Q1_R1",   40,0,1500,0,  40,0,1500,0,  0.25564, 0, 202, 6;
'He-CO2', {"He","CO2"}, "theory", "CF_He_CO2_T40_P1500_H_Q2_R1",   40,0,1500,0,  40,0,1500,0,  0.51128, 0, 202, 6;
'He-CO2', {"He","CO2"}, "theory", "CF_He_CO2_T40_P1500_H_Q5_R1",   40,0,1500,0,  40,0,1500,0,  1.2782,  0, 202, 6;
'He-CO2', {"He","CO2"}, "theory", "CF_He_CO2_T40_P1500_H_Q10_R1",  40,0,1500,0,  40,0,1500,0,  2.5564,  0, 202, 6;
% ---------------- extra (horizontal, Ng = 0), measured run average ---------------- rows 35-43
'H2-CO2', {"H2","CO2"}, "measAvg", "CF_H2_CO2_T32_P1500_H_Q1_R1",   32.11,0.69,1510,2.6,     32.11,0.69,1510,2.6,     0.25564, 0, 202, 6;
'H2-CO2', {"H2","CO2"}, "measAvg", "CF_H2_CO2_T32_P1500_H_Q2_R1",   31.71,0.26,1513,1.2,     31.71,0.26,1513,1.2,     0.51128, 0, 202, 6;
'H2-CO2', {"H2","CO2"}, "measAvg", "CF_H2_CO2_T32_P1500_H_Q5_R1",   32.02,0.61,1514,0.7,     32.02,0.61,1514,0.7,     1.2782,  0, 202, 6;
'He-CO2', {"He","CO2"}, "measAvg", "CF_He_CO2_T40_P1500_H_Q05_R1",  40.45,0.66,1522.4,1.64,  40.45,0.66,1522.4,1.64,  0.12782, 0, 202, 6;
'He-CO2', {"He","CO2"}, "measAvg", "CF_He_CO2_T40_P1500_H_Q1_R1",   37.88,0.37,1527,0.79,    37.88,0.37,1527,0.79,    0.25564, 0, 202, 6;
'He-CO2', {"He","CO2"}, "measAvg", "CF_He_CO2_T40_P1500_H_Q1_R2",   38.14,0.72,1517,1.52,    38.14,0.72,1517,1.52,    0.25564, 0, 202, 6;
'He-CO2', {"He","CO2"}, "measAvg", "CF_He_CO2_T40_P1500_H_Q2_R1",   38.61,0.92,1543,5.84,    38.61,0.92,1543,5.84,    0.51128, 0, 202, 6;
'He-CO2', {"He","CO2"}, "measAvg", "CF_He_CO2_T40_P1500_H_Q5_R1",   38.89,0.51,1516,1.13,    38.89,0.51,1516,1.13,    1.2782,  0, 202, 6;
'He-CO2', {"He","CO2"}, "measAvg", "CF_He_CO2_T40_P1500_H_Q10_R1",  37.93,0.28,1521,2.62,    37.93,0.28,1521,2.62,    2.5564,  0, 202, 6;
% ---------------- extra (horizontal, Ng = 0), measured init/final
% ---------------- rows 44-52
'H2-CO2', {"H2","CO2"}, "measBegEnd", "CF_H2_CO2_T32_P1500_H_Q1_R1",   32.69,0.12,1508,0.49,  31.1,0.12,1515,0.36,  0.25564, 0, 202, 6;
'H2-CO2', {"H2","CO2"}, "measBegEnd", "CF_H2_CO2_T32_P1500_H_Q2_R1",   31.55,0.13,1510,0.6,  31.83,0.3,1513,0.24,  0.51128, 0, 202, 6;
'H2-CO2', {"H2","CO2"}, "measBegEnd", "CF_H2_CO2_T32_P1500_H_Q5_R1",   31.57,0.22,1513,0.39,  32.89,0.28,1514,0.29,  1.2782,  0, 202, 6;
'He-CO2', {"He","CO2"}, "measBegEnd", "CF_He_CO2_T40_P1500_H_Q05_R1",  41.39,0.11,1524,0.32,  40.04,0.42,1522,1.51,  0.12782, 0, 202, 6;
'He-CO2', {"He","CO2"}, "measBegEnd", "CF_He_CO2_T40_P1500_H_Q1_R1",   38.36,0.05,1526,0.12,  37.78,0.15,1526,0.52,  0.25564, 0, 202, 6;
'He-CO2', {"He","CO2"}, "measBegEnd", "CF_He_CO2_T40_P1500_H_Q1_R2",   39.89,0.05,1520,0.75,  38.38,0.1,1517,0.76,  0.25564, 0, 202, 6;
'He-CO2', {"He","CO2"}, "measBegEnd", "CF_He_CO2_T40_P1500_H_Q2_R1",   39.29,0.12,1547,2.65,  37.06,0.09,1533,0.61,  0.51128, 0, 202, 6;
'He-CO2', {"He","CO2"}, "measBegEnd", "CF_He_CO2_T40_P1500_H_Q5_R1",   38.22,0.17,1516,0.75,  38.08,0.08,1515,0.44,  1.2782,  0, 202, 6;
'He-CO2', {"He","CO2"}, "measBegEnd", "CF_He_CO2_T40_P1500_H_Q10_R1",  38.01,0.1,1518,0.51,  37.37,0.07,1524,0.59,  2.5564,  0, 202, 6};

% ---- build the cases struct (complete rows only) ----
cases = struct('label',{}, 'fl',{}, 'group',{}, 'key',{}, ...
    'T1_C',{}, 'dT1_C',{}, 'P1_psig',{}, 'dP1_psig',{}, ...
    'T2_C',{}, 'dT2_C',{}, 'P2_psig',{}, 'dP2_psig',{}, ...
    'u_cmmin',{}, 'du_cmmin',{}, 'K_mD',{}, 'dK_mD',{}, 'theta_deg',{}, 'L_in',{});
for k = 1:size(caseTable,1)
    r = caseTable(k,:);
    cond = [r{5:12}];
    if any(isnan(cond))
        fprintf('caseTable row %d (%s, %s): conditions not filled yet, skipped\n', k, r{4}, r{3});
        continue
    end
    cases(end+1) = struct('label',r{1}, 'fl',{r{2}}, 'group',string(r{3}), 'key',string(r{4}), ...
        'T1_C',r{5}, 'dT1_C',r{6}, 'P1_psig',r{7}, 'dP1_psig',r{8}, ...
        'T2_C',r{9}, 'dT2_C',r{10}, 'P2_psig',r{11}, 'dP2_psig',r{12}, ...
        'u_cmmin',r{13}, 'du_cmmin',0, 'K_mD',r{15}, 'dK_mD',0, ...
        'theta_deg',r{14}, 'L_in',r{16}); %#ok<SAGROW>
end

% row map (to use in main_dimlessTranspNo)
fprintf('\nCase rows:\n');
for c = 1:numel(cases)
    fprintf('  %2d  %-7s  %-10s  %s\n', c, cases(c).label, cases(c).group, cases(c).key);
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

    % pore Peclet number Pe_p = u*d_pore/D12 (same D12)
    dpore_SI = dpore_um*1e-6;              % um -> m
    Pep  = u_SI*dpore_SI/D12_SI;
    dPep = Pep*sqrt( (du_SI/u_SI)^2 + (dD12_SI/D12_SI)^2 + (ddpore_um/dpore_um)^2 );

    dimlessRows = [dimlessRows; table( ...
        {cases(c).label}, c, cases(c).group, cases(c).key, ...
        T1_C, dT1_C, P1_psig, dP1_psig, ...
        T2_C, dT2_C, P2_psig, dP2_psig, ...
        Tmix_C, dTmix_C, Pmix_psig, dPmix_psig, ...
        cases(c).u_cmmin, cases(c).du_cmmin, cases(c).K_mD, cases(c).dK_mD, ...
        cases(c).theta_deg, cases(c).L_in, ...
        mu1, dmu1, mu2, dmu2, ...
        M, dM, Nrho, dNrho, Ng, dNg, Pe, dPe, Pep, dPep, dpore_um, ...
        'VariableNames', {'Pair','caseRow','group','key', ...
        'T1_C','dT1_C','P1_psig','dP1_psig', ...
        'T2_C','dT2_C','P2_psig','dP2_psig', ...
        'Tmix_C','dTmix_C','Pmix_psig','dPmix_psig', ...
        'u_cmmin','du_cmmin','K_mD','dK_mD','theta_deg','L_in', ...
        'mu1_Pas','dmu1_Pas','mu2_Pas','dmu2_Pas', ...
        'M','dM','Nrho','dNrho','Ng','dNg','Pe','dPe','Pep','dPep','dpore_um'})]; %#ok<AGROW>
end

disp(summaryRows)
writetable(summaryRows, pathExportAll + "props_summary_pure_and_mix_errProp.xlsx");

disp(dimlessRows)
writetable(dimlessRows, pathExportAll + "dimless_numbers_errProp.xlsx");

save(pathExportAll + "props_summary_pure_and_mix_errProp.mat", ...
    'summaryRows', 'dimlessRows', 'filedataDiff', 'cases', 'includeSpreadInMix', ...
    'dpore_um', 'ddpore_um');

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