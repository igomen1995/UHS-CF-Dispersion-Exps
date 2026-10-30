%% main_dimlessTranspNo.m
% Relates the measured dispersion coefficient KL (scaled by the molecular
% diffusion coefficient D0) to the dimensionless numbers of each case:
%       KL/D0  vs  Pe, Pe_p, M, Ng, Nrho, Pe_alpha      (one figure per x-axis)
% Pe = uL/D0 (core length), Pe_p = u d_pore/D0 (pore diameter, Gray Berea d_pore = 70 um),
% Pe_alpha = u alpha/D0 (dispersivity alpha from the main_Processing alpha_results_<fitData>.xlsx
% of the chosen data set, see SETTINGS: alphaFile; peMain = Pe used in the maps, colour plot,
% PCA and radar)
% for the UHS cases (H2-CO2, H2-CH4, MFM) and the XCT analog cases (He-Xe,
% MFM analog + CT), and for any other experiment added later.
%
% Runs from the root of UHS-CF-Dispersion-Exps2.
%   MFM KL : every expProcFullData.mat written by main_Processing.m in this
%            repo is found automatically (results/**). The experiment key is
%            either given explicitly or matched from the case (fluids, P, u).
%   CT KL  : <Key>_postproc.mat from main_CTpostproc.m, found under the
%            sibling repo UHS-CT-Dispersion-Exps-Analog.
%
% Inputs
%   props_summary_pure_and_mix_errProp.mat   from main_fluidProps_errorProp.m
%       cases, dimlessRows (M, Nrho, Ng, Pe +/- uncertainty), summaryRows (D0)
%
% MFM breakthrough-curve moments (tmean, sigma, sigma/tmean, skewness, excess
% kurtosis) from expProcFullData.(key).(wEOS|woEOS).BT, used in the moment plots,
% as an extra PCA variable ("+ skewness" data sets) and as supplementary arrows.
%
% KL sources per experiment
%   MFM     expProcFullData.(key).(wEOS|woEOS).results.KL_cm2min (+ totUncertKL_cm2min)
%   CT BTC  resultsAll.(ds).(variant).KL_BTC_CT_byZD.zD0p8.best
%   CT W    resultsAll.(ds).(variant).KL_front_CT.width_C20_80_int0
%   CT BTC  resultsAll.(ds).(variant).KL_BTC_CT_byZD.zD0p5.best        (BTC at mid-core)
%   CT mid  resultsAll.(ds).(variant).KL_midProfile.methods.contour    (profile with the front
%           centre at mid-core, KL = w^2/(4 tau), tau from the contour arrival)
%   -> the last two are compared directly in KLmid_vs_BTC05_<group> (with MFM as reference)
%   manual  KL +/- dKL typed in (experiments without a .mat file)
%
% Rows of `cases` (same order as caseTable in main_fluidProps_errorProp.m;
% the group of every row is read from cases(c).group):
%    1- 8  theory      original (vertical) runs, nominal conditions
%    9-17  measAvg     original runs, average measured conditions
%   18-26  measBegEnd  original runs, per-fluid conditions (beginning / end)
%   27-34  theory      horizontal runs (H2-CO2 32C, He-CO2 40C, 1500 psig), nominal
%   35-43  measAvg     horizontal runs, average measured conditions
%   44-52  measBegEnd  horizontal runs, per-fluid conditions (beginning / end)
%
% Plots use the original (vertical) experiments only; the horizontal runs
% enter only the driver analysis / PCA ("all experiments" set, without Ng).
%
% Colours: He-Xe 725 green, He-Xe 900 blue, H2-CH4 yellow, H2-CO2 purple,
%          lighter = lower Q, darker = higher Q.
% Markers: MFM o, CT BTC zD 0.8 square, CT width triangle, manual diamond,
%          CT BTC zD 0.5 down-triangle, CT mid-profile pentagram.
%
% Outputs (pathExport)
%   MFM_index.xlsx                        all MFM experiments found in this repo
%   KL_dimless_all.xlsx                   one row per (case, KL source)
%   KLD0_vs_<Pe|Pep|M|Ng|Nrho|Pea>_<group>.png/.fig
 
%% SETTINGS
 
dimlessFile = 'results/combined_rhoNorm_4curves/props_summary_pure_and_mix_errProp.mat';
pathExport  = 'results/dimlessKL/';
if ~isfolder(pathExport), mkdir(pathExport); end
 
thisRepo = fileparts(mfilename('fullpath'));
if isempty(thisRepo), thisRepo = pwd; end
mfmSearchRoot = fullfile(thisRepo, 'results');      % where main_Processing.m writes
ctRoot = fullfile(thisRepo, '..', 'UHS-CT-Dispersion-Exps-Analog');
if ~isfolder(ctRoot)
    error('CT repo not found at %s -- clone UHS-CT-Dispersion-Exps-Analog next to this repo.', ctRoot);
end
 
mfmFitData   = "wEOS";               % "wEOS" (concentration) or "woEOS" (rhoNorm)
ctDataSource = "conc";               % "conc" pairs with wEOS, "rhoNorm" with woEOS
ctVariant    = "full";               % "full" or "xtrim"
ctBTCtag     = "zD0p8";              % BTC fit level used for CT KL
ctWidthTag   = "width_C20_80_int0";  % front-width method used for CT KL
ctWidthStat  = "fit";                % "fit" (regression +/- SE) or "mean" (pointwise mean +/- std)
ctBTCtagMid  = "zD0p5";              % second BTC level: mid-core, pairs with the mid-profile KL
ctMidMethod  = "contour";            % mid-profile method: "contour" | "lines" | "sigma"
ctMidStat    = "best";               % "best" (closest frame +/- SE) or "mean" (mean +/- std over the frames)
 
% tolerances for matching an MFM experiment to a case ("auto" keys)
tolP = 0.05;    % relative, on nominal pressure
tolU = 0.15;    % relative, on interstitial velocity

% pore Peclet number Pe_p = u*d_pore/D0 -- normally read from main_fluidProps_errorProp
% (dimlessRows.Pep); these values are used only for an older .mat without it
dpore_um  = 70;    % mean pore diameter of Gray Berea sandstone [um]
ddpore_um = 0;     % uncertainty of d_pore [um] (0 = not propagated)

% moments of the MFM breakthrough curve (step injection, E(t) = dC/dt)
%   tmeanBTC  first moment (mean arrival)            [tD]
%   sigmaBTC  sqrt of the second central moment       [tD]
%   cvBTC     sigma / tmean                           [-]
%   skewBTC   third standardized moment (skewness)    [-]   (0 = symmetric, >0 = long late tail)
%   kurtBTC   excess kurtosis                         [-]
momTimeVar = "tD";     % column of expProcFullData.(key).(fitData).BT used as time
momSmooth  = 5;        % points, moving median on C before cummax (noise in E = dC/dt)
momCendMin = 0.95;     % warn if the curve ends below this C (tail missing -> skew biased)

% dispersivity-based Peclet number Pe_alpha = u*alpha/D0, alpha read from the alpha table
% written by main_Processing for the selected (most suitable) experiments:
%   alphaMode "pooled" (default): sheet pooled_all, row best_per_key = one alpha for the rock,
%       used for EVERY experiment
%   alphaMode "case": sheet best_method, the experiment's own case (matched by MFM key in
%       column Keys, then by fluids, T, P, L, angle); no value -> pooled (alphaUsePooled)
%   in both: alpha_tau_cm +/- totUncertAlpha_tau_cm with tau +/- totUncertTau (alpha + tau fit),
%       if no tau fit -> alpha_cm +/- totUncertAlpha_cm (alpha-only fit)
alphaFile         = fullfile('results', 'exp_verticalStable_CFCT_REFPROP', 'alpha_results_wEOS.xlsx');
alphaMode         = "pooled";   % "pooled" (pooled_all, best_per_key) | "case" (best_method per case)
alphaPreferTau    = true;       % true: alpha_tau (+ tau) when fitted | false: always alpha_cm
alphaUsePooled    = true;       % alphaMode "case": case without alpha -> pooled value
peMain        = "Pea";     % Pe used in the KL/D0-vs-Pe colour plot, maps, PCA and radar:
                           % "Pea" = u*alpha/D0 | "Pe" = u*L/D0

analysisGroups = ["theory","measAvg","measBegEnd"];   % conditions used by EVERY plot and analysis below:
                                         % "theory" (nominal) | "measAvg" (run average) | "measBegEnd"
groupsToPlot   = analysisGroups;
closeAfterSave = false;
 
%% Colours
 
blueL   = [0.318 0.654 0.976];  blueD   = [0.090 0.306 0.525];
greenL  = [0.435 0.753 0.251];  greenD  = [0.059 0.361 0.102];
yellowL = [1.000 0.850 0.350];  yellowD = [0.800 0.600 0.000];
purpleL = [0.760 0.620 0.920];  purpleD = [0.400 0.150 0.600];
 
%% Experiments
% label    short name used in the legend (together with the keys)
% idx      rows of `cases` [theory measAvg measBegEnd]
% mfmKey   "auto" = match fluids/P/u of cases(idx(1)) in the MFM index,
%          an explicit key, or "" = no MFM value
% mfmRun   which match to take when "auto" finds several (sorted by key: R1, R2, ...)
% ctKey    CT experiment key ("" = none)
% KL/dKL   manual value (NaN = none)
 
exps = struct( ...
    'label',  {"H2-CO2 Q1", "H2-CO2 Q5", "H2-CH4 Q1", "H2-CH4 Q5", "H2-CH4 Q1 R2", ...
               "He-Xe 725 Q1", "He-Xe 725 Q5", "He-Xe 900 Q1", "He-Xe 900 Q5"}, ...
    'idx',    {[1 9 18], [2 10 19], [3 11 20], [4 12 21], [13 22], ...
               [5 14 23], [6 15 24], [7 16 25], [8 17 26]}, ...
    'color',  {purpleL, purpleD, yellowL, yellowD, yellowL, ...
               greenL, greenD, blueL, blueD}, ...
    'mfmKey', {"auto","auto","auto","auto","auto","auto","auto","auto","auto"}, ...
    'mfmRun', {1, 1, 1, 1, 2, 1, 1, 1, 1}, ...
    'ctKey',  {"", "", "", "", "", ...
               "CF_He_Xe_T20_P725_V_Q1_R1", "CF_He_Xe_T20_P725_V_Q5_R1", ...
               "CF_He_Xe_T20_P900_V_Q1_R1", "CF_He_Xe_T20_P900_V_Q5_R1"}, ...
    'KL',     {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, ...
    'dKL',    {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, ...
    'main',   {true, true, true, true, true, true, true, true, true});

shade   = @(cL,cD,n) cL + (cD - cL).*linspace(0,1,n)';
orangeH = shade([1.00 0.78 0.55], [0.80 0.35 0.00], 3);     % H2-CO2 32C 1500 H: Q1, Q2, Q5
redHe   = shade([0.98 0.72 0.72], [0.50 0.00 0.05], 5);     % He-CO2 40C 1500 H: Q05 ... Q10

% horizontal runs: idx = [theory measAvg measBegEnd] rows of `cases`
newExps = { ...
 "H2-CO2 H Q1",    [27 35 44], orangeH(1,:), "CF_H2_CO2_T32_P1500_H_Q1_R1"; ...
 "H2-CO2 H Q2",    [28 36 45], orangeH(2,:), "CF_H2_CO2_T32_P1500_H_Q2_R1"; ...
 "H2-CO2 H Q5",    [29 37 46], orangeH(3,:), "CF_H2_CO2_T32_P1500_H_Q5_R1"; ...
 "He-CO2 H Q05",   [30 38 47], redHe(1,:),   "CF_He_CO2_T40_P1500_H_Q05_R1"; ...
 "He-CO2 H Q1",    [31 39 48], redHe(2,:),   "CF_He_CO2_T40_P1500_H_Q1_R1"; ...
 "He-CO2 H Q1 R2", [31 40 49], redHe(2,:),   "CF_He_CO2_T40_P1500_H_Q1_R2"; ...
 "He-CO2 H Q2",    [32 41 50], redHe(3,:),   "CF_He_CO2_T40_P1500_H_Q2_R1"; ...
 "He-CO2 H Q5",    [33 42 51], redHe(4,:),   "CF_He_CO2_T40_P1500_H_Q5_R1"; ...
 "He-CO2 H Q10",   [34 43 52], redHe(5,:),   "CF_He_CO2_T40_P1500_H_Q10_R1"};
for k = 1:size(newExps,1)
    exps(end+1) = struct('label',newExps{k,1}, 'idx',newExps{k,2}, 'color',newExps{k,3}, ...
        'mfmKey',newExps{k,4}, 'mfmRun',1, 'ctKey',"", 'KL',NaN, 'dKL',NaN, 'main',false); %#ok<SAGROW>
end

% other experiments later: add a row to caseTable in main_fluidProps_errorProp.m,
% then append here with its row numbers, e.g.
% exps(end+1) = struct('label',"New exp",'idx',[53 54 55],'color',[0.85 0.33 0.10], ...
%     'mfmKey',"CF_...",'mfmRun',1,'ctKey',"",'KL',NaN,'dKL',NaN,'main',false);

%% Display names (legends and point labels of every plot)
% {label prefix, name}: the experiment label "<prefix> Q1..." becomes "<name> loPe",
% "<prefix> Q5..." becomes "<name> hiPe", and a run tag is kept ("... (R2)").
% M = viscosity ratio: hiM for H2-CO2 / He-Xe 900, loM for H2-CH4 / He-Xe 725.
% Labels without a match (e.g. the horizontal runs) keep their original label.
expNames = {"H2-CO2",    "UHS hiM";   "He-Xe 900", "XCT hiM"; ...
            "H2-CH4",    "UHS loM";   "He-Xe 725", "XCT loM"};
qPeTag   = {"Q1", "loPe";  "Q5", "hiPe"};     % flow-rate tag -> Peclet tag
legendShowKeys = false;                        % true: append the MFM / CT keys in the legends
for e = 1:numel(exps)
    exps(e).name = displayName(exps(e).label, expNames, qPeTag);
end

srcNames = ["MFM", "CT BTC zD=" + strrep(extractAfter(ctBTCtag,"zD"),"p","."), ...
            "CT width " + regexprep(ctWidthTag, '^width_C(\d+)_(\d+).*$', '$1-$2'), "manual", ...
            "CT BTC zD=" + strrep(extractAfter(ctBTCtagMid,"zD"),"p","."), ...
            "CT mid-profile " + ctMidMethod];
srcMk    = ["o", "s", "^", "d", "v", "p"];
 
%% Load dimensionless numbers and D0
 
S = load(dimlessFile, 'cases', 'dimlessRows', 'summaryRows');
cases = S.cases;  dimless = S.dimlessRows;
nCase = numel(cases);
 
mixRows = S.summaryRows(S.summaryRows.x1 == 0.5, :);
if height(mixRows) ~= nCase
    error('Expected one mixture row per case (%d), found %d', nCase, height(mixRows));
end
D0  = mixRows.D12_cm2min;
dD0 = mixRows.dD12_cm2min;
 
% group of every row, as stored by main_fluidProps_errorProp.m
if isfield(cases, 'group')
    groupOfCase = string({cases.group});
else                                       % older .mat without the group field
    groupOfCase = [repmat("theory",1,8), repmat("measAvg",1,9), repmat("measBegEnd",1,9)];
    groupOfCase(end+1:nCase) = "theory";
    groupOfCase = groupOfCase(1:nCase);
    warning('cases has no group field -- re-run main_fluidProps_errorProp.m');
end
if isfield(cases, 'key'), keyOfCase = string({cases.key}); else, keyOfCase = strings(1,nCase); end

% check: rows of every experiment exist, one per group, and the key matches (when set)
for e = 1:numel(exps)
    ix = exps(e).idx(:)';
    if any(ix > nCase)
        warning('%s: rows %s beyond the %d cases -- re-run main_fluidProps_errorProp.m', ...
            exps(e).label, mat2str(ix(ix > nCase)), nCase);
        continue
    end
    if numel(unique(groupOfCase(ix))) < numel(ix)
        warning('%s: rows %s repeat a group (%s)', exps(e).label, mat2str(ix), strjoin(groupOfCase(ix), ', '));
    end
    k = keyOfCase(ix(groupOfCase(ix) ~= "theory"));   % theory rows may be shared (Q1 R1/R2)
    k = k(k ~= "");
    if exps(e).mfmKey ~= "auto" && exps(e).mfmKey ~= "" && any(k ~= exps(e).mfmKey)
        warning('%s: rows %s carry key(s) %s, expected %s', exps(e).label, mat2str(ix), ...
            strjoin(unique(k), ', '), exps(e).mfmKey);
    end
end
 
%% MFM index: every experiment processed by main_Processing.m in this repo
 
cache = containers.Map('KeyType','char','ValueType','any');
mfmIdx = buildMFMIndex(mfmSearchRoot, mfmFitData, cache);
if isempty(mfmIdx)
    warning('No expProcFullData.mat found under %s -- MFM values skipped', mfmSearchRoot);
else
    fprintf('\nMFM experiments found (%s):\n', mfmFitData);
    disp(mfmIdx(:, {'key','Fluid1','Fluid2','P_psig','u_cmmin','hasFitData','KL_cm2min','file'}))
    writetable(mfmIdx, fullfile(pathExport, 'MFM_index.xlsx'));
end
 
% resolve the MFM key of every experiment
exps(1).mfmKeyUsed = "";  exps(1).mfmFileUsed = "";
for e = 1:numel(exps)
    [exps(e).mfmKeyUsed, exps(e).mfmFileUsed, note] = resolveMFM(mfmIdx, exps(e), cases, tolP, tolU);
    if exps(e).mfmKey ~= "" && exps(e).mfmKeyUsed == ""
        warning('%s: no MFM experiment (%s)', exps(e).label, note);
    end
end
disp(table(string({exps.label})', [exps.mfmKey]', [exps.mfmKeyUsed]', [exps.ctKey]', ...
    'VariableNames', {'experiment','mfmKeyRequested','mfmKeyUsed','ctKey'}))
 
%% Alpha table (main_Processing, selected experiments)

alphaTab = readAlphaTable(alphaFile);
if alphaMode == "case" && ~isempty(alphaTab.group)
    fprintf('Alpha table %s:\n', alphaFile);
    disp(alphaTab.group(:, intersect({'GroupID','n_points','alpha_cm','totUncertAlpha_cm', ...
        'alpha_tau_cm','totUncertAlpha_tau_cm','tau','totUncertTau'}, ...
        alphaTab.group.Properties.VariableNames, 'stable')))
end
if ~isempty(alphaTab.pooled)
    fprintf('Pooled (best_per_key): alpha = %.4f cm, alpha_tau = %.4f cm, tau = %.2f\n', ...
        alphaTab.pooled.alpha_cm, alphaTab.pooled.alpha_tau_cm, alphaTab.pooled.tau);
end

%% Collect KL for every experiment and source
 
rows = cell(0,1);
 
for e = 1:numel(exps)
    ex = exps(e);
    KLlist = struct('src',{},'KL',{},'dKL',{},'key',{});
    mom = momNaN();                               % BTC moments (MFM curve only)
    alEx = alphaForExp(alphaTab, ex, cases, alphaMode, alphaPreferTau, alphaUsePooled);   % alpha [cm]
    if ~isfinite(alEx.a), warning('%s: no alpha in %s -- Pe_alpha = NaN', ex.label, alphaFile); end

    if ex.mfmKeyUsed ~= ""
        [KL, dKL, note] = getMFM(ex.mfmFileUsed, ex.mfmKeyUsed, mfmFitData, cache);
        KLlist = addKL(KLlist, srcNames(1), KL, dKL, ex.mfmKeyUsed, note, ex.label);
        [mom, noteM] = getMFMMoments(ex.mfmFileUsed, ex.mfmKeyUsed, mfmFitData, cache, momTimeVar, momSmooth);
        if noteM ~= "", warning('%s, MFM moments: %s', ex.label, noteM); end
        if isfinite(mom.Cend) && mom.Cend < momCendMin
            warning('%s: MFM BTC ends at C = %.2f -- sigma and skewness are biased (truncated tail)', ...
                ex.label, mom.Cend);
        end
    end
    if ex.ctKey ~= ""
        ctFile = findPostproc(ctRoot, ex.ctKey);
        [KL, dKL, note] = getCT(ctFile, ctDataSource, ctVariant, "BTC_" + ctBTCtag, "fit", cache);
        KLlist = addKL(KLlist, srcNames(2), KL, dKL, ex.ctKey, note, ex.label);
        [KL, dKL, note] = getCT(ctFile, ctDataSource, ctVariant, ctWidthTag, ctWidthStat, cache);
        KLlist = addKL(KLlist, srcNames(3), KL, dKL, ex.ctKey, note, ex.label);
        [KL, dKL, note] = getCT(ctFile, ctDataSource, ctVariant, "BTC_" + ctBTCtagMid, "fit", cache);
        KLlist = addKL(KLlist, srcNames(5), KL, dKL, ex.ctKey, note, ex.label);
        [KL, dKL, note] = getCT(ctFile, ctDataSource, ctVariant, "MID_" + ctMidMethod, ctMidStat, cache);
        KLlist = addKL(KLlist, srcNames(6), KL, dKL, ex.ctKey, note, ex.label);
    end
    if isfinite(ex.KL)
        KLlist = addKL(KLlist, srcNames(4), ex.KL, ex.dKL, "manual", "", ex.label);
    end
 
    for k = 1:numel(KLlist)
        q = KLlist(k);
        for c = ex.idx(:)'
            if c > nCase, warning('%s: caseIdx %d out of range', ex.label, c); continue, end
            d = dimless(c,:);
            L_cm  = d.L_in*2.54;
            KLD0  = q.KL/D0(c);
            dKLD0 = KLD0*sqrt((q.dKL/q.KL)^2 + (dD0(c)/D0(c))^2);
            PeKL  = d.u_cmmin*L_cm/q.KL;
            if ismember('Pep', dimless.Properties.VariableNames)  % from main_fluidProps_errorProp
                Pep = d.Pep;  dPep = d.dPep;
            else                                                  % older .mat: compute here
                Pep  = d.u_cmmin*(dpore_um*1e-4)/D0(c);           % u*d_pore/D0, d_pore in cm
                relU = 0;  if d.u_cmmin > 0, relU = d.du_cmmin/d.u_cmmin; end
                dPep = Pep*sqrt(relU^2 + (dD0(c)/D0(c))^2 + (ddpore_um/dpore_um)^2);
            end
            if q.src == srcNames(1), mq = mom; else, mq = momNaN(); end   % moments: MFM rows only
            % Pe_alpha = u*alpha/D0 (alpha in cm, u in cm/min, D0 in cm2/min)
            Pea  = d.u_cmmin*alEx.a/D0(c);
            relU = 0;  if d.u_cmmin > 0, relU = d.du_cmmin/d.u_cmmin; end
            relA = 0;  if isfinite(alEx.da) && alEx.a > 0, relA = alEx.da/alEx.a; end
            dPea = Pea*sqrt(relU^2 + relA^2 + (dD0(c)/D0(c))^2);
            rows{end+1,1} = table(c, groupOfCase(c), ex.label, string(d.Pair), ...
                d.Pmix_psig, d.Tmix_C, d.u_cmmin, q.src, q.key, ...
                q.KL, q.dKL, D0(c), dD0(c), KLD0, dKLD0, ...
                d.Pe, d.dPe, Pep, dPep, alEx.a, alEx.da, alEx.src, alEx.tau, alEx.dtau, Pea, dPea, ...
                d.M, d.dM, d.Ng, d.dNg, d.Nrho, d.dNrho, PeKL, PeKL*q.dKL/q.KL, ...
                mq.tmean, mq.sigma, mq.cv, mq.skew, mq.kurt, mq.Cend, ...
                'VariableNames', {'caseIdx','group','experiment','pair', ...
                'Pmix_psig','Tmix_C','u_cmmin','source','sourceKey', ...
                'KL_cm2min','dKL_cm2min','D0_cm2min','dD0_cm2min','KLD0','dKLD0', ...
                'Pe','dPe','Pep','dPep','alpha_cm','d_alpha_cm','alphaSrc','tau','d_tau','Pea','dPea', ...
                'M','dM','Ng','dNg','Nrho','dNrho','PeKL','dPeKL', ...
                'tmeanBTC','sigmaBTC','cvBTC','skewBTC','kurtBTC','CendBTC'}); %#ok<SAGROW>
        end
    end
end
 
if isempty(rows), error('No valid KL entries -- check the MFM index and keys in `exps`'); end
T = vertcat(rows{:});

% skewness expected from the ADE itself (inverse-Gaussian residence time, Pe_KL = uL/KL):
% skew_ADE = 3*sqrt(2/Pe_KL). The excess skew_BTC - skew_ADE is the part of the tail
% that the fitted KL does not explain (non-Fickian / late-time tailing).
T.skewADE    = 3*sqrt(2./T.PeKL);
T.skewExcess = T.skewBTC - T.skewADE;
disp(T(:, {'caseIdx','group','experiment','source','sourceKey','KL_cm2min','KLD0','Pe', ...
    'alpha_cm','alphaSrc','tau','Pea','M','Ng','sigmaBTC','skewBTC'}))
writetable(T, fullfile(pathExport, 'KL_dimless_all.xlsx'));
% all experiments are kept for the PCA; every plot below uses the main (vertical) ones only
Tall = T;
T    = T(ismember(T.experiment, [exps([exps.main]).label]), :);
 
%% Plots: one figure per (group, x-axis)
 
% {x column, dx column, x label, log x, file tag}
xPanels = {'Pe',   'dPe',   'Pe = uL/D_0 [-]',                     true,  'Pe'; ...
           'Pep',  'dPep',  'Pe_p = u d_{pore}/D_0 [-]',           true,  'Pep'; ...
           'M',    'dM',    'M = \mu_2/\mu_1 [-]',                 false, 'M'; ...
           'Ng',   'dNg',   'N_g [-]',                             false, 'Ng'; ...
           'Nrho', 'dNrho', 'N_\rho = (\rho_1-\rho_2)/\rho_2 [-]', false, 'Nrho'; ...
           'Pea',  'dPea',  'Pe_\alpha = u\alpha/D_0 [-]',          true,  'Pea'};

% Pe used in the maps, the KL/D0-vs-Pe colour plot, moments, PCA and radar (setting peMain)
iPeMain  = find(strcmp(xPanels(:,1), peMain), 1);
peLblMain = xPanels{iPeMain,3};
if peMain == "Pea", peTag = "log_{10}Pe_\alpha"; peShort = 'Pe_\alpha'; else, peTag = "log_{10}Pe"; peShort = 'Pe'; end
 
groupTitle = struct('theory',"nominal conditions (scaling analysis)", ...
                    'measAvg',"average measured conditions", ...
                    'measBegEnd',"per-fluid measured conditions (beginning / end)", ...
                    'other',"other experiments");
 
for g = groupsToPlot
    Tg = T(T.group == g & isfinite(T.KLD0) & T.KLD0 > 0, :);
    if isempty(Tg), warning('No KL entries for group %s', g); continue, end
 
    for p = 1:size(xPanels,1)
        fig = figure('Position',[80 80 1300 700]);
        ax = axes(fig);  hold(ax,'on')
 
        for e = 1:numel(exps)
            for s = 1:numel(srcNames)
                sel = Tg.experiment == exps(e).label & Tg.source == srcNames(s);
                if ~any(sel), continue, end
                x  = Tg.(xPanels{p,1})(sel);   dx = Tg.(xPanels{p,2})(sel);
                y  = Tg.KLD0(sel);             dy = Tg.dKLD0(sel);
                dx(~isfinite(dx)) = 0;         dy(~isfinite(dy)) = 0;
                dyLow = min(dy, 0.99*y);
                dxLow = dx;  if xPanels{p,4}, dxLow = min(dx, 0.99*x); end
 
                errorbar(ax, x, y, dyLow, dy, dxLow, dx, srcMk(s), ...
                    'Color',exps(e).color, 'MarkerFaceColor',exps(e).color, ...
                    'MarkerEdgeColor',0.5*exps(e).color, 'MarkerSize',9, ...
                    'LineStyle','none', 'CapSize',4, 'HandleVisibility','off')
            end
        end
 
        % legend: experiments (colour + keys) and KL sources (marker)
        for e = 1:numel(exps)
            if ~any(Tg.experiment == exps(e).label), continue, end
            plot(ax, NaN, NaN, 's', 'MarkerSize',10, 'MarkerFaceColor',exps(e).color, ...
                'MarkerEdgeColor','none', 'DisplayName', legendKeys(exps(e), legendShowKeys))
        end
        for s = 1:numel(srcNames)
            if ~any(Tg.source == srcNames(s)), continue, end
            plot(ax, NaN, NaN, srcMk(s), 'MarkerSize',9, 'Color',[0.3 0.3 0.3], ...
                'MarkerFaceColor',[0.6 0.6 0.6], 'LineStyle','none', 'DisplayName', srcNames(s))
        end
 
        yline(ax, 1, ':k', 'HandleVisibility','off')            % KL = D0
        set(ax, 'YScale','log', 'FontSize',12)
        if xPanels{p,4}, set(ax, 'XScale','log'), end
        xlabel(ax, xPanels{p,3}, 'FontSize',13)
        ylabel(ax, 'K_L / D_0 [-]', 'FontSize',13)
        grid(ax,'on')
        legend(ax, 'Location','eastoutside', 'Interpreter','none', 'FontSize',8)
        title(ax, sprintf('K_L/D_0 vs %s -- %s', xPanels{p,5}, groupTitle.(g)), 'Interpreter','none')
 
        fname = "KLD0_vs_" + xPanels{p,5} + "_" + g;
        saveas(fig, fullfile(pathExport, fname), 'png');
        saveas(fig, fullfile(pathExport, fname), 'fig');
        if closeAfterSave, close(fig); end
    end
end

%% Plots: XCT by method (one panel each) vs UHS MFM (in every panel)

xctMethods = srcNames([1 3 2 5 6]);      % MFM, CT width, CT BTC 0.8, CT BTC 0.5, CT mid-profile
xctExps    = startsWith([exps.label], "He-Xe");
uhsExps    = startsWith([exps.label], ["H2-CO2","H2-CH4"]);
uhsSource  = srcNames(1);                % UHS cases only have MFM

for g = groupsToPlot
    Tg = T(T.group == g & isfinite(T.KLD0) & T.KLD0 > 0, :);
    if isempty(Tg), warning('No KL entries for group %s', g); continue, end

    for p = 1:size(xPanels,1)
        fig = figure('Position',[60 80 380*numel(xctMethods)+200 600]);
        tl  = tiledlayout(fig, 1, numel(xctMethods), 'TileSpacing','compact');
        axs = gobjects(1, numel(xctMethods));

        for s = 1:numel(xctMethods)
            ax = nexttile(tl);  hold(ax,'on');  axs(s) = ax;
            mkXCT = srcMk(find(srcNames == xctMethods(s), 1));
            mkUHS = srcMk(find(srcNames == uhsSource, 1));

            % UHS reference (MFM) in every panel, then XCT with this panel's method
            plotSet(ax, Tg, exps(uhsExps), uhsSource,      mkUHS, xPanels(p,:));
            plotSet(ax, Tg, exps(xctExps), xctMethods(s),  mkXCT, xPanels(p,:));

            yline(ax, 1, ':k', 'HandleVisibility','off')
            set(ax, 'YScale','log', 'FontSize',11)
            if xPanels{p,4}, set(ax, 'XScale','log'), end
            xlabel(ax, xPanels{p,3}, 'FontSize',12)
            if s == 1, ylabel(ax, 'K_L / D_0 [-]', 'FontSize',12), end
            title(ax, "XCT: " + xctMethods(s) + "  |  UHS: " + uhsSource, ...
                'Interpreter','none', 'FontSize',11)
            grid(ax,'on')
        end

        linkaxes(axs, 'xy')                       % same scales -> panels directly comparable

        % shared legend: experiments (colour + keys) and markers
        axL = axs(1);  hLeg = gobjects(0);
        for e = find(uhsExps | xctExps)
            if ~any(Tg.experiment == exps(e).label), continue, end
            hLeg(end+1) = plot(axL, NaN, NaN, 's', 'MarkerSize',10, ...
                'MarkerFaceColor',exps(e).color, 'MarkerEdgeColor','none', ...
                'DisplayName', legendKeys(exps(e), legendShowKeys)); %#ok<SAGROW>
        end
        for s = 1:numel(srcNames)
            if ~ismember(srcNames(s), [xctMethods uhsSource]), continue, end
            hLeg(end+1) = plot(axL, NaN, NaN, srcMk(s), 'MarkerSize',9, 'LineStyle','none', ...
                'Color',[0.3 0.3 0.3], 'MarkerFaceColor',[0.6 0.6 0.6], ...
                'DisplayName', srcNames(s)); %#ok<SAGROW>
        end
        lgd = legend(axL, hLeg, 'Interpreter','none', 'FontSize',8, 'NumColumns',2);
        lgd.Layout.Tile = 'south';

        title(tl, sprintf('K_L/D_0 vs %s: XCT (He-Xe) by method vs UHS (MFM) -- %s', ...
            xPanels{p,5}, groupTitle.(g)), 'Interpreter','none')

        fname = "XCTvsUHS_KLD0_vs_" + xPanels{p,5} + "_byMethod_" + g;
        saveas(fig, fullfile(pathExport, fname), 'png');
        saveas(fig, fullfile(pathExport, fname), 'fig');
        if closeAfterSave, close(fig); end
    end
end

%% Plots: CT KL at mid-core -- mid-profile vs BTC zD 0.5, and every CT KL vs MFM
% one value per experiment (KL does not depend on the case row), from the first row found
% (a) mid-profile KL vs BTC KL at zD = 0.5: same location, same first-term ADE -> expect 1:1
% (b) every CT KL vs the MFM KL of the same experiment, marker = source

ctCmp = srcNames([2 3 5 6]);           % CT BTC 0.8, CT width, CT BTC 0.5, CT mid-profile
for g = groupsToPlot
    Tg = T(T.group == g & isfinite(T.KL_cm2min) & T.KL_cm2min > 0, :);
    if isempty(Tg), continue, end
    expG = exps(ismember([exps.label], unique(Tg.experiment)));
    klOf = @(lbl, src) firstKL(Tg, lbl, src);

    fig = figure('Position',[80 80 1350 580]);
    tl  = tiledlayout(fig, 1, 2, 'TileSpacing','compact');

    % (a) mid-profile vs BTC zD 0.5
    ax = nexttile(tl);  hold(ax,'on');  allV = [];
    for e = 1:numel(expG)
        [xb, dxb] = klOf(expG(e).label, srcNames(5));
        [ym, dym] = klOf(expG(e).label, srcNames(6));
        if ~(isfinite(xb) && isfinite(ym)), continue, end
        errorbar(ax, xb, ym, min(dym,0.99*ym), dym, min(dxb,0.99*xb), dxb, 'p', ...
            'Color',expG(e).color, 'MarkerFaceColor',expG(e).color, 'MarkerEdgeColor',0.5*expG(e).color, ...
            'MarkerSize',13, 'LineStyle','none', 'CapSize',4, 'DisplayName', legendKeys(expG(e), legendShowKeys))
        text(ax, xb, ym, sprintf('  %.2f', ym/xb), 'FontSize',8, 'VerticalAlignment','bottom')
        allV = [allV xb ym];  %#ok<AGROW>
    end
    addOneToOne(ax, allV)
    set(ax, 'XScale','log', 'YScale','log', 'FontSize',11);  grid(ax,'on');  axis(ax,'square')
    xlabel(ax, "K_L, " + srcNames(5) + " [cm^2/min]", 'Interpreter','tex')
    ylabel(ax, "K_L, " + srcNames(6) + " [cm^2/min]", 'Interpreter','tex')
    title(ax, 'mid-core: front profile vs BTC (label = ratio)', 'FontSize',11)
    legend(ax, 'Location','northwest', 'Interpreter','none', 'FontSize',8)

    % (b) all CT KL vs MFM
    ax = nexttile(tl);  hold(ax,'on');  allV = [];
    for e = 1:numel(expG)
        [xm, dxm] = klOf(expG(e).label, srcNames(1));
        if ~isfinite(xm), continue, end
        for s = 1:numel(ctCmp)
            [yc, dyc] = klOf(expG(e).label, ctCmp(s));
            if ~isfinite(yc), continue, end
            mk = srcMk(srcNames == ctCmp(s));
            errorbar(ax, xm, yc, min(dyc,0.99*yc), dyc, min(dxm,0.99*xm), dxm, mk, ...
                'Color',expG(e).color, 'MarkerFaceColor',expG(e).color, 'MarkerEdgeColor',0.5*expG(e).color, ...
                'MarkerSize',10, 'LineStyle','none', 'CapSize',3, 'HandleVisibility','off')
            allV = [allV xm yc];  %#ok<AGROW>
        end
    end
    addOneToOne(ax, allV)
    for s = 1:numel(ctCmp)
        plot(ax, NaN, NaN, srcMk(srcNames == ctCmp(s)), 'MarkerSize',9, 'LineStyle','none', ...
            'Color',[0.3 0.3 0.3], 'MarkerFaceColor',[0.6 0.6 0.6], 'DisplayName', ctCmp(s))
    end
    set(ax, 'XScale','log', 'YScale','log', 'FontSize',11);  grid(ax,'on');  axis(ax,'square')
    xlabel(ax, 'K_L, MFM [cm^2/min]');  ylabel(ax, 'K_L, CT [cm^2/min]')
    title(ax, 'CT methods vs MFM (colour = experiment)', 'FontSize',11)
    legend(ax, 'Location','northwest', 'Interpreter','none', 'FontSize',8)

    title(tl, sprintf('CT K_L at mid-core vs BTC and MFM (%s, %s) -- %s', ctDataSource, ctVariant, ...
        groupTitle.(g)), 'Interpreter','none')
    fname = "KLmid_vs_BTC05_" + g;
    saveas(fig, fullfile(pathExport, fname), 'png');
    saveas(fig, fullfile(pathExport, fname), 'fig');
    if closeAfterSave, close(fig); end
end

%% Maps: M vs Pe and M vs Ng, marker colour = KL (one column per method)

mapColorVar = 'KL_cm2min';      % 'KL_cm2min' or 'KLD0'
mapColorLbl = struct('KL_cm2min','K_L [cm^2/min]', 'KLD0','K_L/D_0 [-]');
mapLogColor = true;             % log colour scale
mapMethods  = srcNames([1 3 2 5 6]);              % MFM, CT width, CT BTC 0.8, CT BTC 0.5, CT mid-profile
mapRows     = {char(peMain), peLblMain, true; ...
               'Ng', 'N_g [-]',         false};   % {y column, y label, log y}
labelPoints = true;             % write the experiment label next to each marker

cAll = T.(mapColorVar)(isfinite(T.(mapColorVar)) & T.(mapColorVar) > 0);
cLim = [min(cAll) max(cAll)];
if mapLogColor, cLim = log10(cLim); end
cmap = parula(256);

for g = groupsToPlot
    Tg = T(T.group == g & isfinite(T.(mapColorVar)) & T.(mapColorVar) > 0, :);
    if isempty(Tg), continue, end
    meth = mapMethods(ismember(mapMethods, unique(Tg.source)));

    fig = figure('Position',[50 50 520*numel(meth)+150 950]);
    tl  = tiledlayout(fig, size(mapRows,1), numel(meth), 'TileSpacing','compact');

    for r = 1:size(mapRows,1)
        for s = 1:numel(meth)
            ax = nexttile(tl);  hold(ax,'on')

            % this column's method + UHS MFM as reference (UHS has no CT)
            isUHS = startsWith(Tg.experiment, ["H2-CO2","H2-CH4"]);
            Ts = Tg(Tg.source == meth(s) | (isUHS & Tg.source == srcNames(1)), :);
            Ts = unique(Ts, 'rows', 'stable');            % MFM column would list UHS twice

            yv = Ts.(mapRows{r,1});
            errorbar(ax, Ts.M, yv, Ts.("d" + mapRows{r,1}), Ts.("d" + mapRows{r,1}), ...
                Ts.dM, Ts.dM, 'LineStyle','none', 'Color',[0.75 0.75 0.75], 'CapSize',3, ...
                'HandleVisibility','off')

            cVal = Ts.(mapColorVar);
            if mapLogColor, cVal = log10(cVal); end
            for sIdx = 1:numel(srcNames)                  % marker per source
                sel = Ts.source == srcNames(sIdx);
                if ~any(sel), continue, end
                scatter(ax, Ts.M(sel), yv(sel), 110, cVal(sel), srcMk(sIdx), 'filled', ...
                    'MarkerEdgeColor','k', 'LineWidth',0.6)
            end

            if labelPoints
                text(ax, Ts.M, yv, "  " + namesOf(Ts.experiment, exps) + " (" + Ts.source + ")", ...
                    'FontSize',7, 'Interpreter','none', 'VerticalAlignment','middle')
            end

            colormap(ax, cmap);  clim(ax, cLim)
            if mapRows{r,3}, set(ax, 'YScale','log'), end
            set(ax, 'FontSize',11);  grid(ax,'on')
            xlabel(ax, 'M = \mu_2/\mu_1 [-]', 'FontSize',12)
            if s == 1, ylabel(ax, mapRows{r,2}, 'FontSize',12), end
            if r == 1, title(ax, "XCT: " + meth(s) + "  |  UHS: " + srcNames(1), ...
                    'Interpreter','none', 'FontSize',11), 
            end
        end
    end

    cb = colorbar(ax);  cb.Layout.Tile = 'east';
    if mapLogColor
        tk = floor(cLim(1)):0.25:ceil(cLim(2));
        cb.Ticks = tk;  cb.TickLabels = compose('%.3g', 10.^tk);
    end
    cb.Label.String = mapColorLbl.(mapColorVar);

    title(tl, sprintf('M vs Pe and M vs N_g, colour = %s -- %s', ...
        mapColorLbl.(mapColorVar), groupTitle.(g)), 'Interpreter','tex')

    fname = "map_M_Pe_Ng_" + mapColorVar + "_" + g;
    saveas(fig, fullfile(pathExport, fname), 'png');
    saveas(fig, fullfile(pathExport, fname), 'fig');
    if closeAfterSave, close(fig); end
end

%% KL/D0 vs Pe, marker colour = M

pmSources  = srcNames(1);          % MFM; add srcNames(2:3) to include the XCT CT values
pmGroups   = analysisGroups;           % nominal and average measured conditions
pmUseAll   = false;                % true: include the horizontal runs (squares, Ng = 0)
pmLogM     = true;                 % log colour scale for M
pmLabels   = true;                 % experiment label next to each marker

if pmUseAll, Tpm = Tall; else, Tpm = T; end
for g = pmGroups
    Tg = Tpm(Tpm.group == g & ismember(Tpm.source, pmSources) & isfinite(Tpm.KLD0) & Tpm.KLD0 > 0, :);
    if isempty(Tg), warning('No entries for group %s', g); continue, end

    cM = Tg.M;  if pmLogM, cM = log10(cM); end
    isH = Tg.Ng == 0;                                     % horizontal runs (Ng = 0)

    fig = figure('Position',[80 80 1150 750]);
    ax = axes(fig);  hold(ax,'on')

    % uncertainty bars (grey, behind)
    xPm = Tg.(peMain);  dxPm = Tg.("d" + peMain);  dxPm(~isfinite(dxPm)) = 0;
    dyLow = min(Tg.dKLD0, 0.99*Tg.KLD0);  dxLow = min(dxPm, 0.99*xPm);
    errorbar(ax, xPm, Tg.KLD0, dyLow, Tg.dKLD0, dxLow, dxPm, 'LineStyle','none', ...
        'Color',[0.75 0.75 0.75], 'CapSize',3, 'HandleVisibility','off')

    % markers: circle = vertical (Ng ~= 0), square = horizontal (Ng = 0); edge style per source
    srcEdge = struct();  srcEdge.(matlab.lang.makeValidName(srcNames(1))) = 'k';
    for s = 1:numel(pmSources)
        selS = Tg.source == pmSources(s);
        lw = 0.8;  if s > 1, lw = 2; end                  % CT sources: thick edge
        if any(selS & ~isH)
            scatter(ax, xPm(selS & ~isH), Tg.KLD0(selS & ~isH), 120, cM(selS & ~isH), 'o', ...
                'filled', 'MarkerEdgeColor','k', 'LineWidth',lw, ...
                'DisplayName', pmSources(s) + ", vertical (N_g \neq 0)")
        end
        if any(selS & isH)
            scatter(ax, xPm(selS & isH), Tg.KLD0(selS & isH), 140, cM(selS & isH), 's', ...
                'filled', 'MarkerEdgeColor','k', 'LineWidth',lw, ...
                'DisplayName', pmSources(s) + ", horizontal (N_g = 0)")
        end
    end

    if pmLabels
        text(ax, xPm, Tg.KLD0, "  " + Tg.experiment, 'FontSize',7, 'Interpreter','none')
    end

    yline(ax, 1, ':k', 'K_L = D_0', 'HandleVisibility','off', 'LabelHorizontalAlignment','left')
    set(ax, 'XScale','log', 'YScale','log', 'FontSize',12);  grid(ax,'on')
    xlabel(ax, peLblMain, 'FontSize',13)
    ylabel(ax, 'K_L / D_0 [-]', 'FontSize',13)

    colormap(ax, turbo)
    cb = colorbar(ax);
    if pmLogM
        tk = linspace(min(cM), max(cM), 6);
        cb.Ticks = tk;  cb.TickLabels = compose('%.2f', 10.^tk);
    end
    cb.Label.String = 'M = \mu_2/\mu_1 [-]';

    legend(ax, 'Location','northwest', 'FontSize',9)
    title(ax, sprintf('K_L/D_0 vs %s, colour = M -- %s', peShort, groupTitle.(g)), 'Interpreter','tex')

    fname = "KLD0_vs_" + peMain + "_colorM_" + g + ternStr(pmUseAll, "_allExp", "");
    saveas(fig, fullfile(pathExport, fname), 'png');
    saveas(fig, fullfile(pathExport, fname), 'fig');
    if closeAfterSave, close(fig); end
end

%% MFM BTC moments (sigma, skewness) vs the dimensionless numbers, and KL/D0 vs moments
% main (vertical) experiments, MFM rows only; moments are a property of the curve,
% so they are the same in every group -- only the x values (conditions) change

momRows = {'sigmaBTC',   '\sigma (BTC) [t_D]', false; ...
           'skewBTC',    'skewness (BTC) [-]',  false; ...
           'skewExcess', 'skew_{BTC} - skew_{ADE} [-]', false; ...
           'kurtBTC',    'excess kurtosis (BTC) [-]', false};     % {column, label, log y}
momCols = xPanels(unique([iPeMain 1 2 3 4], 'stable'), :);    % Pe used (peMain), Pe, Pe_p, M, Ng

for g = groupsToPlot
    Tg = T(T.group == g & T.source == srcNames(1) & isfinite(T.skewBTC), :);
    if isempty(Tg), warning('No MFM moments for group %s', g); continue, end

    % (1) moments vs dimensionless numbers
    fig = figure('Position',[40 60 1700 950]);
    tl  = tiledlayout(fig, size(momRows,1), size(momCols,1), 'TileSpacing','compact');
    for r = 1:size(momRows,1)
        for p = 1:size(momCols,1)
            ax = nexttile(tl);  hold(ax,'on')
            for e = 1:numel(exps)
                sel = Tg.experiment == exps(e).label;
                if ~any(sel), continue, end
                scatter(ax, Tg.(momCols{p,1})(sel), Tg.(momRows{r,1})(sel), 80, exps(e).color, 'o', ...
                    'filled', 'MarkerEdgeColor', 0.5*exps(e).color, 'DisplayName', exps(e).label)
            end
            if momRows{r,1} ~= "sigmaBTC", yline(ax, 0, ':k', 'HandleVisibility','off'); end
            if momCols{p,4}, set(ax, 'XScale','log'), end
            if momRows{r,3}, set(ax, 'YScale','log'), end
            set(ax, 'FontSize',10);  grid(ax,'on')
            if r == size(momRows,1), xlabel(ax, momCols{p,3}, 'FontSize',11), end
            if p == 1, ylabel(ax, momRows{r,2}, 'FontSize',11), end
        end
    end
    lgd = legend(nexttile(tl,1), 'Interpreter','none', 'FontSize',8, 'NumColumns',5);
    lgd.Layout.Tile = 'south';
    title(tl, sprintf('MFM breakthrough-curve moments vs dimensionless numbers -- %s', groupTitle.(g)), ...
        'Interpreter','tex')
    fname = "BTCmoments_vs_dimless_" + g;
    saveas(fig, fullfile(pathExport, fname), 'png');  saveas(fig, fullfile(pathExport, fname), 'fig');
    if closeAfterSave, close(fig); end
end

% (2) KL/D0 vs sigma and vs skewness, one figure per analysis group
for gM = analysisGroups
Tm = T(T.group == gM & T.source == srcNames(1) & isfinite(T.skewBTC) & T.KLD0 > 0, :);
if ~isempty(Tm)
    fig = figure('Position',[60 80 1300 520]);
    tl  = tiledlayout(fig, 1, 3, 'TileSpacing','compact');
    mv  = {'sigmaBTC','\sigma (BTC) [t_D]'; 'skewBTC','skewness (BTC) [-]'; ...
           'skewExcess','skew_{BTC} - skew_{ADE} [-]'};
    for p = 1:size(mv,1)
        ax = nexttile(tl);  hold(ax,'on')
        for e = 1:numel(exps)
            sel = Tm.experiment == exps(e).label;
            if ~any(sel), continue, end
            scatter(ax, Tm.(mv{p,1})(sel), Tm.KLD0(sel), 90, exps(e).color, 'o', 'filled', ...
                'MarkerEdgeColor', 0.5*exps(e).color, 'DisplayName', exps(e).label)
        end
        rs = corr(Tm.(mv{p,1}), log10(Tm.KLD0), 'Type','Spearman', 'Rows','complete');
        if mv{p,1} == "skewExcess", xline(ax, 0, ':k', 'ADE', 'HandleVisibility','off'); end
        set(ax, 'YScale','log', 'FontSize',11);  grid(ax,'on')
        xlabel(ax, mv{p,2}, 'FontSize',12);  if p == 1, ylabel(ax, 'K_L / D_0 [-]', 'FontSize',12), end
        title(ax, sprintf('Spearman r = %.2f', rs), 'FontSize',11)
    end
    lgd = legend(nexttile(tl,1), 'Interpreter','none', 'FontSize',8, 'NumColumns',5);
    lgd.Layout.Tile = 'south';
    title(tl, sprintf('K_L/D_0 (MFM) vs breakthrough-curve moments -- %s', groupTitle.(gM)), 'Interpreter','tex')
    fname = "KLD0_vs_BTCmoments_" + gM;
    saveas(fig, fullfile(pathExport, fname), 'png');  saveas(fig, fullfile(pathExport, fname), 'fig');
    if closeAfterSave, close(fig); end
end
end

%% Which dimensionless number controls KL? correlation, partial correlation, regression, PCA
% Works on log10(KL/D0) vs log10(Pe) (Pe = peMain: u*alpha/D0 or u*L/D0), log10(M), log10(|Ng|).
% Note: with Pe = u*alpha/D0 and alpha fitted from the same KL, KL/D0 ~ Pe_alpha by
% construction, so Pe_alpha is expected to dominate the correlations.
% One analysis per (group, data set); each experiment counted once per data set.

anaGroups = analysisGroups;                              % nominal and average measured conditions

% data sets: main vertical runs with Ng; all runs without Ng (Ng = 0 for horizontal runs);
% the same two again with the skewness of the MFM BTC added as a variable
anaSets = struct( ...
    'name',      {"MFM, main (vertical)", "MFM, all experiments", ...
                  "MFM, main (vertical) + skewness", "MFM, all experiments + skewness"}, ...
    'source',    {srcNames(1), srcNames(1), srcNames(1), srcNames(1)}, ...
    'expFilt',   {"", "", "", ""}, ...
    'useAll',    {false, true, false, true}, ...
    'predNames', {[peTag,"log_{10}M","log_{10}|N_g|"], [peTag,"log_{10}M"], ...
                  [peTag,"log_{10}M","log_{10}|N_g|","skew"], [peTag,"log_{10}M","skew"]}, ...
    'predFun',   {@(Ts) [log10(Ts.(peMain)), log10(Ts.M), log10(abs(Ts.Ng))], ...
                  @(Ts) [log10(Ts.(peMain)), log10(Ts.M)], ...
                  @(Ts) [log10(Ts.(peMain)), log10(Ts.M), log10(abs(Ts.Ng)), Ts.skewBTC], ...
                  @(Ts) [log10(Ts.(peMain)), log10(Ts.M), Ts.skewBTC]});

% supplementary variables projected on the PCA biplot (not used to build the PCs):
% {column, label, colour}
pcaSupp = {'skewBTC',    'skew',             [0.95 0.55 0.10]; ...
           'skewExcess', 'skew - skew_{ADE}', [0.10 0.60 0.30]; ...
           'cvBTC',      '\sigma/t_{mean}',  [0.45 0.20 0.70]};

minN = 5;                                                % fewer points -> analysis skipped

anaSummary = table();

for g = anaGroups
    for a = 1:numel(anaSets)
        sa = anaSets(a);
        predNames = sa.predNames;   predFun = sa.predFun;
        if sa.useAll, Tsrc = Tall; else, Tsrc = T; end
        Ts = Tsrc(Tsrc.group == g & Tsrc.source == sa.source & isfinite(Tsrc.KLD0) & Tsrc.KLD0 > 0, :);
        if sa.expFilt ~= "", Ts = Ts(startsWith(Ts.experiment, sa.expFilt), :); end
        [~, iu] = unique(Ts.experiment, 'stable');   Ts = Ts(iu,:);     % one row per experiment
        n = height(Ts);
        if n < minN
            warning('%s / %s: only %d experiments (< %d), analysis skipped', g, sa.name, n, minN);
            continue
        end

        y = log10(Ts.KLD0);
        X = predFun(Ts);
        ok = all(isfinite([y X]), 2);   y = y(ok);  X = X(ok,:);  Ts = Ts(ok,:);  n = numel(y);
        nP = size(X,2);

        % ---- 1) correlations of each number with KL/D0
        rP  = corr(X, y, 'Type','Pearson');
        rS  = corr(X, y, 'Type','Spearman');
        rPart = nan(nP,1);  pPart = nan(nP,1);
        if n - nP - 1 >= 2                               % enough dof for partial correlation
            for k = 1:nP
                others = setdiff(1:nP, k);
                [rPart(k), pPart(k)] = partialcorr(X(:,k), y, X(:,others));
            end
        end

        % ---- 2) single-predictor R2 and standardized multiple regression
        R2single = rP.^2;
        Z  = zscore(X);   zy = zscore(y);
        mdl = fitlm(Z, zy, 'VarNames', [cellstr(matlab.lang.makeValidName(predNames)) {'logKLD0'}]);
        beta = mdl.Coefficients.Estimate(2:end);
        ci   = coefCI(mdl);   ciB = ci(2:end,:);
        Rx   = corrcoef(X);   VIF = diag(inv(Rx));       % variance inflation factor (collinearity)

        anaSummary = [anaSummary; table(repmat(g,nP,1), repmat(sa.name,nP,1), repmat(n,nP,1), ...
            predNames', rP, rS, rPart, pPart, R2single, beta, ciB(:,1), ciB(:,2), VIF, ...
            repmat(mdl.Rsquared.Adjusted,nP,1), ...
            'VariableNames', {'group','dataSet','n','predictor','r_Pearson','r_Spearman', ...
            'r_partial','p_partial','R2_single','beta_std','beta_CI_lo','beta_CI_hi','VIF','R2adj_full'})]; %#ok<AGROW>

        % ---- 3) PCA of the predictors, KL as supplementary variable
        [coeff, score, ~, ~, expl] = pca(Z);
        rKLpc = corr(score(:,1:2), y);                   % where KL points in PC1-PC2

        % ---- figure: correlation matrix | correlations with KL | std. coefficients | PCA biplot
        fig = figure('Position',[40 60 1700 900]);
        tl  = tiledlayout(fig, 2, 2, 'TileSpacing','compact');

        % (a) Spearman correlation matrix, KL included
        ax = nexttile(tl);
        allNames = ["log_{10}K_L/D_0", predNames];
        C = corr([y X], 'Type','Spearman');
        imagesc(ax, C);  colormap(ax, redblue(256));  clim(ax, [-1 1]);  colorbar(ax)
        set(ax, 'XTick',1:numel(allNames), 'XTickLabel',allNames, ...
                'YTick',1:numel(allNames), 'YTickLabel',allNames, 'FontSize',10)
        axis(ax,'square')
        for i1 = 1:size(C,1)
            for i2 = 1:size(C,2)
                text(ax, i2, i1, sprintf('%.2f', C(i1,i2)), 'HorizontalAlignment','center', ...
                    'FontSize',9, 'Color', ternColor(abs(C(i1,i2)) > 0.6))
            end
        end
        title(ax, 'Spearman correlation matrix', 'FontSize',11)

        % (b) correlation of each number with KL/D0
        ax = nexttile(tl);
        bar(ax, categorical(predNames, predNames), [rP rS rPart]);
        yline(ax, 0, 'k');  ylim(ax, [-1 1]);  grid(ax,'on')
        legend(ax, {'Pearson','Spearman','partial (others fixed)'}, 'Location','best', 'FontSize',9)
        ylabel(ax, 'correlation with log_{10}K_L/D_0')
        title(ax, 'Correlation with K_L/D_0', 'FontSize',11)

        % (c) standardized regression coefficients with 95% CI, VIF on top
        ax = nexttile(tl);  hold(ax,'on')
        xb = 1:nP;
        bar(ax, xb, beta, 'FaceColor',[0.3 0.5 0.8]);
        errorbar(ax, xb, beta, beta - ciB(:,1), ciB(:,2) - beta, 'k.', 'LineWidth',1)
        for k = 1:nP
            text(ax, xb(k), max(ciB(k,2), beta(k)) + 0.05, sprintf('VIF %.1f', VIF(k)), ...
                'HorizontalAlignment','center', 'FontSize',8)
        end
        set(ax, 'XTick',xb, 'XTickLabel',predNames);  yline(ax, 0, 'k');  grid(ax,'on')
        ylabel(ax, '\beta (standardized)')
        title(ax, sprintf('log_{10}K_L/D_0 = \\Sigma \\beta_i z_i   (R^2_{adj} = %.2f, n = %d)', ...
            mdl.Rsquared.Adjusted, n), 'FontSize',11)

        % (d) PCA biplot, points coloured by KL/D0, KL drawn as supplementary arrow
        ax = nexttile(tl);  hold(ax,'on')
        sc = max(abs(score(:,1:2)), [], 'all');
        scatter(ax, score(:,1), score(:,2), 90, y, 'filled', 'MarkerEdgeColor','k')
        colormap(ax, parula);  cb = colorbar(ax);  cb.Label.String = 'log_{10}K_L/D_0';
        text(ax, score(:,1), score(:,2), "  " + namesOf(Ts.experiment, exps), 'FontSize',7, 'Interpreter','none')
        for k = 1:nP
            quiver(ax, 0, 0, coeff(k,1)*sc, coeff(k,2)*sc, 0, 'Color',[0.2 0.2 0.2], ...
                'LineWidth',1.2, 'MaxHeadSize',0.4)
            text(ax, coeff(k,1)*sc*1.1, coeff(k,2)*sc*1.1, predNames(k), 'FontSize',10)
        end
        quiver(ax, 0, 0, rKLpc(1)*sc, rKLpc(2)*sc, 0, 'Color',[0.85 0.1 0.1], ...
            'LineWidth',2, 'MaxHeadSize',0.4)
        text(ax, rKLpc(1)*sc*1.1, rKLpc(2)*sc*1.1, 'K_L/D_0', 'Color',[0.85 0.1 0.1], 'FontWeight','bold')

        % supplementary BTC-moment arrows (dashed), skipped if the variable is a predictor
        for sv = 1:size(pcaSupp,1)
            if any(strcmp(pcaSupp{sv,2}, predNames)), continue, end
            v = Ts.(pcaSupp{sv,1});
            if ~all(isfinite(v)) || std(v) == 0, continue, end
            rV = corr(score(:,1:2), v);
            quiver(ax, 0, 0, rV(1)*sc, rV(2)*sc, 0, 'Color',pcaSupp{sv,3}, 'LineStyle','--', ...
                'LineWidth',1.8, 'MaxHeadSize',0.4)
            text(ax, rV(1)*sc*1.1, rV(2)*sc*1.1, pcaSupp{sv,2} + " (supp.)", ...
                'Color',pcaSupp{sv,3}, 'FontWeight','bold', 'FontSize',9)
        end
        xlabel(ax, sprintf('PC1 (%.0f%%)', expl(1)));  ylabel(ax, sprintf('PC2 (%.0f%%)', expl(2)))
        axis(ax,'equal');  grid(ax,'on')
        title(ax, 'PCA of the dimensionless numbers (arrows = loadings)', 'FontSize',11)

        title(tl, sprintf('What controls K_L/D_0? -- %s, %s', sa.name, groupTitle.(g)), 'Interpreter','tex')
        fname = "drivers_KLD0_" + matlab.lang.makeValidName(sa.name) + "_" + g;
        saveas(fig, fullfile(pathExport, fname), 'png');
        saveas(fig, fullfile(pathExport, fname), 'fig');
        if closeAfterSave, close(fig); end
    end
end

disp(anaSummary)
writetable(anaSummary, fullfile(pathExport, 'drivers_KLD0_summary.xlsx'));

%% Rose diagrams: importance of each dimensionless number for KL/D0

roseMetrics = {'r_Spearman', '|r| Spearman (raw)'; ...
               'r_partial',  '|r| partial (others fixed)'; ...
               'beta_std',   '|\beta| standardized'};
posCol = [0.85 0.33 0.10];      % KL/D0 increases with the number
negCol = [0.00 0.45 0.74];      % KL/D0 decreases with the number

for g = unique(anaSummary.group)'
    for ds = unique(anaSummary.dataSet(anaSummary.group == g), 'stable')'
        A  = anaSummary(anaSummary.group == g & anaSummary.dataSet == ds, :);
        nP = height(A);
        w  = 2*pi/nP;                                    % one sector per number
        centers = (0:nP-1)*w;

        fig = figure('Position',[60 80 1500 560]);
        tl  = tiledlayout(fig, 1, size(roseMetrics,1), 'TileSpacing','compact');

        for m = 1:size(roseMetrics,1)
            vals = A.(roseMetrics{m,1});
            rMax = max(1, max(abs(vals), [], 'omitnan'));    % correlations on 0-1, beta may exceed 1

            pax = polaraxes(tl);  pax.Layout.Tile = m;  hold(pax,'on')
            for k = 1:nP
                if ~isfinite(vals(k)), continue, end
                col = posCol;  if vals(k) < 0, col = negCol; end
                polarhistogram(pax, 'BinEdges', centers(k) + [-0.45 0.45]*w, ...
                    'BinCounts', abs(vals(k)), 'FaceColor', col, 'FaceAlpha', 0.85, ...
                    'EdgeColor', 'k')
            end
            pax.ThetaTick      = rad2deg(centers);
            pax.ThetaTickLabel = A.predictor;
            pax.RLim           = [0 rMax];
            pax.FontSize       = 10;
            title(pax, roseMetrics{m,2}, 'FontSize',11)
        end

        % sign legend
        axL = axes(fig, 'Position',[0 0 1 1], 'Visible','off');  hold(axL,'on')
        patch(axL, NaN, NaN, posCol, 'DisplayName','K_L/D_0 increases with the number')
        patch(axL, NaN, NaN, negCol, 'DisplayName','K_L/D_0 decreases with the number')
        lgd = legend(axL, 'Location','south', 'Orientation','horizontal', 'FontSize',10);

        n = A.n(1);
        title(tl, sprintf('Importance of each number for K_L/D_0 -- %s, %s (n = %d)', ...
            ds, groupTitle.(g), n), 'Interpreter','tex')

        fname = "rose_drivers_" + matlab.lang.makeValidName(ds) + "_" + g;
        saveas(fig, fullfile(pathExport, fname), 'png');
        saveas(fig, fullfile(pathExport, fname), 'fig');
        if closeAfterSave, close(fig); end
    end
end

%% Radar chart: dimensionless numbers and KL/D0 (MFM), all experiments
% spokes: Pe (peMain), M, N_g (signed, linear: negative -> positive), K_L/D_0 (MFM),
%         skewness of the MFM BTC
% one polygon per experiment in the experiment colour (lighter = lower Q, darker = higher Q);
% vertices: circle = UHS (H2-CO2, H2-CH4), square = XCT analog (He-Xe)
% colours: high M (H2-CO2, He-Xe 900) blue, low M (H2-CH4, He-Xe 725) green
% legend : display names (section "Display names")

radarLog     = struct('Pe',true, 'Pea',true, 'Pep',true, 'M',false, 'Ng',false, 'Nrho',false, ...
                      'KLD0',true, 'skewBTC',false);
rMin         = 0.15;                    % radius of the axis minimum (keeps polygons off the centre)
radarFillA   = 0.10;                    % fill transparency
radarColOver = struct('H2_CO2', {{blueL, blueD}}, ...     % radar only: {Q1 light, Q5 dark}
                      'H2_CH4', {{greenL, greenD}});

for radarGroup = analysisGroups
    Tr = T(T.group == radarGroup & T.source == srcNames(1) & isfinite(T.KLD0) & T.KLD0 > 0, :);

    % spokes: {column, label}
    axDef = {char(peMain), peShort;  'M','M';  'Ng','N_g';  'KLD0','K_L/D_0 (MFM)';  'skewBTC','skew (MFM BTC)'};
    nA = size(axDef,1);
    th = pi/2 - (0:nA-1)*2*pi/nA;           % first axis at the top, clockwise

    expSel = find(ismember([exps.label], Tr.experiment));
    V = nan(numel(expSel), nA);
    for ie = 1:numel(expSel)
        rr = Tr(Tr.experiment == exps(expSel(ie)).label, :);
        for a = 1:nA, V(ie,a) = rr.(axDef{a,1})(1); end
    end

    % min-max normalisation per spoke (log where set; N_g linear so its sign is kept)
    R = nan(size(V));  lo = nan(1,nA);  hi = nan(1,nA);  r0 = nan(1,nA);
    for a = 1:nA
        v = V(:,a);  isLog = radarLog.(axDef{a,1});
        if isLog, v(v <= 0) = NaN; v = log10(v); end
        lo(a) = min(v, [], 'omitnan');  hi(a) = max(v, [], 'omitnan');
        if hi(a) > lo(a)
            R(:,a) = rMin + (1-rMin)*(v - lo(a))/(hi(a) - lo(a));
            if ~isLog && lo(a) < 0 && hi(a) > 0             % where zero sits on this spoke
                r0(a) = rMin + (1-rMin)*(0 - lo(a))/(hi(a) - lo(a));
            end
        else
            R(:,a) = 0.5*(1+rMin);
        end
        if isLog, lo(a) = 10^lo(a); hi(a) = 10^hi(a); end
    end

    fig = figure('Position',[80 60 1000 900]);
    ax = axes(fig);  hold(ax,'on');  axis(ax,'equal','off')

    % grid: rings and spokes, with min / max printed at each spoke, zero mark on N_g
    for ring = linspace(rMin, 1, 4)
        plot(ax, ring*cos([th th(1)]), ring*sin([th th(1)]), '-', 'Color',[0.85 0.85 0.85], ...
            'HandleVisibility','off')
    end
    for a = 1:nA
        plot(ax, [0 cos(th(a))], [0 sin(th(a))], '-', 'Color',[0.6 0.6 0.6], 'HandleVisibility','off')
        text(ax, 1.17*cos(th(a)), 1.17*sin(th(a)), axDef{a,2}, 'FontSize',13, ...
            'FontWeight','bold', 'HorizontalAlignment','center')
        text(ax, 1.04*cos(th(a)), 1.04*sin(th(a)) - 0.05, sprintf('%.3g', hi(a)), ...
            'FontSize',8, 'Color',[0.4 0.4 0.4], 'HorizontalAlignment','center')
        text(ax, rMin*cos(th(a)), rMin*sin(th(a)) - 0.05, sprintf('%.3g', lo(a)), ...
            'FontSize',8, 'Color',[0.4 0.4 0.4], 'HorizontalAlignment','center')
        if isfinite(r0(a))
            nrm = [-sin(th(a)) cos(th(a))]*0.03;          % short tick across the spoke at 0
            p0  = r0(a)*[cos(th(a)) sin(th(a))];
            plot(ax, p0(1) + [-1 1]*nrm(1), p0(2) + [-1 1]*nrm(2), 'k-', 'LineWidth',1.5, ...
                'HandleVisibility','off')
            text(ax, p0(1) + 2*nrm(1), p0(2) + 2*nrm(2), '0', 'FontSize',8, 'HorizontalAlignment','center')
        end
    end

    % one polygon per experiment: experiment colour, marker = UHS (circle) / XCT (square)
    for ie = 1:numel(expSel)
        ex  = exps(expSel(ie));
        col = radarColour(ex, radarColOver);
        isUHS = startsWith(ex.label, ["H2-CO2","H2-CH4"]);
        mk = 's';  if isUHS, mk = 'o'; end
        okA = isfinite(R(ie,:));
        if nnz(okA) < 3, continue, end
        x = R(ie,okA).*cos(th(okA));  y = R(ie,okA).*sin(th(okA));
        patch(ax, x, y, col, 'FaceAlpha',radarFillA, 'EdgeColor',col, ...
            'LineWidth',2.2, 'HandleVisibility','off')
        plot(ax, x, y, mk, 'MarkerFaceColor',col, 'MarkerEdgeColor',col, 'MarkerSize',9, ...
            'LineStyle','none', 'HandleVisibility','off')
        plot(ax, NaN, NaN, ['-' mk], 'Color',col, 'MarkerFaceColor',col, 'MarkerEdgeColor',col, ...
            'LineWidth',2.2, 'MarkerSize',9, 'DisplayName', ex.name)
    end

    xlim(ax, [-1.35 1.35]);  ylim(ax, [-1.3 1.3])
    legend(ax, 'Location','southoutside', 'Interpreter','none', 'FontSize',9, 'NumColumns',2)
    title(ax, {sprintf('Dimensionless numbers and K_L/D_0 (MFM) per experiment -- %s', ...
        groupTitle.(radarGroup)), 'circle = UHS, square = XCT (MFM K_L); blue = high M, green = low M; lighter = Q1 (loPe), darker = Q5 (hiPe)'}, ...
        'Interpreter','tex', 'FontSize',12)

    fname = "radar_dimless_KLD0_MFM_" + radarGroup;
    saveas(fig, fullfile(pathExport, fname), 'png');
    saveas(fig, fullfile(pathExport, fname), 'fig');
    if closeAfterSave, close(fig); end
end
 
%% Local functions
 
function list = addKL(list, src, KL, dKL, key, note, label)
if ~(isfinite(KL) && KL > 0)
    warning('%s, %s (%s): %s -- skipped', label, src, key, note);
    return
end
if ~isfinite(dKL), dKL = 0; end
list(end+1) = struct('src',src,'KL',KL,'dKL',dKL,'key',string(key));
end
 
function txt = legendKeys(ex, showKeys)
% legend text: display name (see "Display names"), optionally followed by the keys
txt = ex.name;
if nargin < 2 || ~showKeys, return, end
keys = [ex.mfmKeyUsed, ex.ctKey];
keys = keys(keys ~= "");
if isfinite(ex.KL), keys(end+1) = "manual"; end
if ~isempty(keys), txt = ex.name + ": " + strjoin(keys, " / "); end
end

function txt = displayName(lbl, names, peTag)
% "H2-CO2 Q5" -> "UHS hiM hiPe", "H2-CH4 Q1 R2" -> "UHS loM loPe (R2)"; no match -> label
txt = string(lbl);
for k = 1:size(names,1)
    if ~startsWith(txt, names{k,1} + " Q"), continue, end
    rest = extractAfter(txt, strlength(names{k,1}));
    txt  = names{k,2};
    for q = 1:size(peTag,1)
        if ~isempty(regexp(char(rest), "\<" + peTag{q,1} + "\>", 'once')), txt = txt + " " + peTag{q,2}; break, end
    end
    run = string(regexp(char(rest), 'R\d+', 'match', 'once'));
    if strlength(run) > 0, txt = txt + " (" + run + ")"; end
    return
end
end

function n = namesOf(labels, exps)
% display names for a list of experiment labels (unmatched labels unchanged)
n = string(labels);
for k = 1:numel(n)
    j = find([exps.label] == n(k), 1);
    if ~isempty(j), n(k) = exps(j).name; end
end
end
 
function S = loadCached(file, cache)
k = char(file);
if ~isKey(cache, k)
    if ~isfile(k), S = []; return, end
    cache(k) = load(k);
end
S = cache(k);
end
 
function idx = buildMFMIndex(root, fitData, cache)
% one row per experiment key in every expProcFullData.mat under root
idx = table();
files = dir(fullfile(root, '**', 'expProcFullData.mat'));
for f = files'
    fp = string(fullfile(f.folder, f.name));
    S  = loadCached(fp, cache);
    if isempty(S) || ~isfield(S, 'expProcFullData'), continue, end
    keys = setdiff(fieldnames(S.expProcFullData), {'fitSummary'});
    for k = keys'
        e = S.expProcFullData.(k{1});
        if ~isstruct(e) || ~isfield(e, 'exp_params'), continue, end
        ep = e.exp_params;
        has = isfield(e, fitData);
        KL = NaN;  dKL = NaN;
        if has, [KL, dKL] = mfmKL(e.(fitData).results); end
        idx = [idx; table(string(k{1}), fp, f.datenum, ...
            paramStr(ep, {'Fluid1'}), paramStr(ep, {'Fluid2'}), ...
            paramNum(ep, {'P','P_psig','Pavg_avg'}), paramNum(ep, {'u_SI'})*6000, ...
            has, KL, dKL, ...
            'VariableNames', {'key','file','datenum','Fluid1','Fluid2', ...
            'P_psig','u_cmmin','hasFitData','KL_cm2min','dKL_cm2min'})]; %#ok<AGROW>
    end
end
end
 
function [key, file, note] = resolveMFM(idx, ex, cases, tolP, tolU)
key = "";  file = "";  note = "";
if ex.mfmKey == "", return, end
if isempty(idx), note = "MFM index empty"; return, end
 
if ex.mfmKey ~= "auto"
    rows = idx(idx.key == ex.mfmKey & idx.hasFitData, :);
    if isempty(rows), note = "key " + ex.mfmKey + " not found"; return, end
else
    c  = cases(ex.idx(1));
    fl = string(c.fl);
    sel = strcmpi(idx.Fluid1, fl(1)) & strcmpi(idx.Fluid2, fl(2)) & idx.hasFitData & ...
          abs(idx.P_psig  - c.P1_psig)  <= tolP*c.P1_psig & ...
          abs(idx.u_cmmin - c.u_cmmin)  <= tolU*c.u_cmmin;
    rows = idx(sel, :);
    if isempty(rows)
        note = sprintf('no match for %s-%s, P=%g psig, u=%g cm/min', fl(1), fl(2), c.P1_psig, c.u_cmmin);
        return
    end
    uk = unique(rows.key);                         % sorted: ..._R1, ..._R2
    if ex.mfmRun > numel(uk)
        note = sprintf('only %d matching key(s), run %d requested', numel(uk), ex.mfmRun);
        return
    end
    rows = rows(rows.key == uk(ex.mfmRun), :);
end
[~, newest] = max(rows.datenum);                   % same key in several files -> newest
key  = rows.key(newest);
file = rows.file(newest);
end
 
function [KL, dKL, note] = getMFM(file, key, fitData, cache)
KL = NaN;  dKL = NaN;  note = "";
S = loadCached(file, cache);
if isempty(S), note = "file not found: " + string(file); return, end
if ~isfield(S.expProcFullData, key), note = "key not in file"; return, end
e = S.expProcFullData.(key);
if ~isfield(e, fitData), note = fitData + " not processed"; return, end
[KL, dKL] = mfmKL(e.(fitData).results);
end
 
function m = momNaN()
m = struct('tmean',NaN, 'sigma',NaN, 'cv',NaN, 'skew',NaN, 'kurt',NaN, 'Cend',NaN);
end

function [m, note] = getMFMMoments(file, key, fitData, cache, tVar, nSmooth)
% moments of the MFM breakthrough curve stored in expProcFullData.(key).(fitData).BT
m = momNaN();  note = "";
S = loadCached(file, cache);
if isempty(S), note = "file not found"; return, end
if ~isfield(S.expProcFullData, key), note = "key not in file"; return, end
e = S.expProcFullData.(key);
if ~isfield(e, fitData) || ~isfield(e.(fitData), 'BT'), note = fitData + ".BT not stored"; return, end
BT = e.(fitData).BT;
n  = fieldOrVarNames(BT);
if ~ismember(char(tVar), n) || ~ismember('Ci', n)
    note = "BT has no " + tVar + " or Ci column";  return
end
t = double(BT.(char(tVar)));  C = double(BT.Ci)/100;       % Ci stored in %
m = btcMoments(t(:), C(:), nSmooth);
end

function m = btcMoments(t, C, nSmooth)
% moments of E = dC/dt for a step-injection BTC, from the increments of a
% cleaned (sorted, 0..1, monotonic) curve: weights w = dC at mid-interval times
m = momNaN();
ok = isfinite(t) & isfinite(C);
t = t(ok);  C = C(ok);
if numel(t) < 5, return, end
[t, o] = sort(t);  C = C(o);
[t, iu] = unique(t);  C = C(iu);
C = min(max(C, 0), 1);
C = cummax(movmedian(C, nSmooth));
C(C < 0.02) = 0;  C(C > 0.98) = 1;   % snap plateaus (same as getBTCMetrics)
w  = diff(C);   tm = 0.5*(t(1:end-1) + t(2:end));
W  = sum(w);
if W <= 0, return, end
mu  = sum(tm.*w)/W;
v   = sum((tm - mu).^2.*w)/W;   s = sqrt(v);
if s <= 0, return, end
m.tmean = mu;
m.sigma = s;
m.cv    = s/mu;
m.skew  = sum((tm - mu).^3.*w)/W / s^3;
m.kurt  = sum((tm - mu).^4.*w)/W / s^4 - 3;
m.Cend  = C(end);
end

function A = readAlphaTable(file)
% best_method sheet (one row per case) and the best_per_key row of pooled_all
A = struct('group', table(), 'pooled', table());
if ~isfile(file)
    warning('Alpha file not found: %s -- Pe_alpha = NaN', file);  return
end
[~, sh] = xlsfinfo(file);
if any(strcmp(sh, 'best_method'))
    A.group = readtable(file, 'Sheet','best_method', 'TextType','string');
end
if any(strcmp(sh, 'pooled_all'))
    P = readtable(file, 'Sheet','pooled_all', 'TextType','string');
    A.pooled = P(P.method == "best_per_key", :);
    if height(A.pooled) > 1, A.pooled = A.pooled(1,:); end
end
end

function al = alphaForExp(A, ex, cases, mode, preferTau, usePooled)
% alpha [cm] (+ uncertainty) and tau of one experiment from the alpha table:
% mode "pooled": pooled_all best_per_key row for every experiment;
% mode "case": case row (matched by MFM key, else by fluids/T/P/L/angle), no value -> pooled.
% In both: alpha_tau + tau when available, else alpha_cm.
al = struct('a',NaN, 'da',NaN, 'tau',NaN, 'dtau',NaN, 'src',"");
if mode == "pooled"
    if ~isempty(A.pooled)
        al = pickAlpha(A.pooled, preferTau);
        if isfinite(al.a), al.src = "pooled (" + al.src + ")"; end
    end
    return
end
G = A.group;
r = [];
if ~isempty(G) && ismember('Keys', G.Properties.VariableNames) && ex.mfmKeyUsed ~= ""
    for k = 1:height(G)
        if any(strtrim(split(string(G.Keys(k)), ";")) == ex.mfmKeyUsed), r = k; break, end
    end
end
if isempty(r) && ~isempty(G) && ~isempty(ex.idx)
    c   = cases(ex.idx(1));  fl = string(c.fl);
    gid = fl(1) + "_" + fl(2) + "_T" + string(c.T1_C) + "_P" + string(c.P1_psig) + ...
          "_L" + string(c.L_in) + "_THETA" + string(c.theta_deg);
    r = find(G.GroupID == gid, 1);
end
if ~isempty(r)
    al = pickAlpha(G(r,:), preferTau);
    if isfinite(al.a), al.src = "case " + string(G.GroupID(r)) + " (" + al.src + ")"; return, end
end
if usePooled && ~isempty(A.pooled)
    al = pickAlpha(A.pooled, preferTau);
    if isfinite(al.a), al.src = "pooled (" + al.src + ")"; end
end
end

function al = pickAlpha(row, preferTau)
% alpha_tau + tau (total uncertainties) when available and wanted, else alpha_cm
al = struct('a',NaN, 'da',NaN, 'tau',NaN, 'dtau',NaN, 'src',"");
v  = @(n) colVal(row, n);
if preferTau && isfinite(v('alpha_tau_cm')) && v('alpha_tau_cm') > 0 && isfinite(v('tau'))
    al.a   = v('alpha_tau_cm');  al.da   = firstFinite(v('totUncertAlpha_tau_cm'), v('d_alpha_tau_cm'));
    al.tau = v('tau');           al.dtau = firstFinite(v('totUncertTau'), v('d_tau'));
    al.src = "alpha_tau";
elseif isfinite(v('alpha_cm')) && v('alpha_cm') > 0
    al.a   = v('alpha_cm');      al.da   = firstFinite(v('totUncertAlpha_cm'), v('d_alpha_cm'));
    al.src = "alpha";
end
end

function x = colVal(row, name)
x = NaN;
if ismember(name, row.Properties.VariableNames)
    x = row.(name)(1);
    if iscell(x), x = x{1}; end
    if isstring(x) || ischar(x), x = str2double(x); end
    x = double(x);
end
end

function x = firstFinite(varargin)
x = NaN;
for k = 1:nargin
    if isfinite(varargin{k}), x = varargin{k}; return, end
end
end

function [KL, dKL] = mfmKL(r)
n = fieldOrVarNames(r);
KL = r.KL_cm2min(1);  dKL = NaN;
if ismember('totUncertKL_cm2min', n),  dKL = r.totUncertKL_cm2min(1);
elseif ismember('dKL_cm2min', n),      dKL = r.dKL_cm2min(1);
end
end
 
function f = findPostproc(ctRoot, key)
% <key>_postproc.mat anywhere under the CT repo (each experiment has its own exportPath)
hits = dir(fullfile(ctRoot, '**', key + "_postproc.mat"));
if isempty(hits)
    f = fullfile(ctRoot, key + "_postproc.mat");     % non-existent -> getCT warns, entry skipped
    return
end
if numel(hits) > 1
    [~, newest] = max([hits.datenum]);
    warning('%s: %d postproc files found, using the newest (%s)', key, numel(hits), hits(newest).folder);
    hits = hits(newest);
end
f = fullfile(hits.folder, hits.name);
end
 
function [KL, dKL, note] = getCT(file, dataSource, variant, method, stat, cache)
KL = NaN;  dKL = NaN;  note = "";
S = loadCached(file, cache);
if isempty(S), note = "postproc file not found under the CT repo"; return, end
rs = S.expCTDataSave.resultsAll;
if ~isfield(rs, dataSource) || ~isfield(rs.(dataSource), variant)
    note = "no postproc results for " + dataSource + "/" + variant; return
end
rv = rs.(dataSource).(variant);
 
if startsWith(method, "BTC_")
    tag = extractAfter(method, "BTC_");
    if ~isfield(rv.KL_BTC_CT_byZD, tag), note = tag + " not fitted"; return, end
    e = rv.KL_BTC_CT_byZD.(tag);
    if ~e.complete || ~isfield(e.best,'KL_cm2min'), note = tag + " incomplete BTC"; return, end
    KL = e.best.KL_cm2min;
    if isfield(e.best,'dKL_cm2min'), dKL = e.best.dKL_cm2min; end
elseif startsWith(method, "MID_")
    m = extractAfter(method, "MID_");
    if ~isfield(rv, 'KL_midProfile') || ~isfield(rv.KL_midProfile, 'methods') || ...
            ~isfield(rv.KL_midProfile.methods, m)
        note = "KL_midProfile." + m + " not computed (re-run main_CTpostproc)"; return
    end
    r = rv.KL_midProfile.methods.(m);
    if stat == "mean"
        KL = r.KL_cm2min_mean;  dKL = r.KL_cm2min_std;
    else
        KL = r.KL_cm2min_best;  dKL = r.dKL_cm2min_best;
    end
else
    if ~isfield(rv.KL_front_CT, method), note = method + " not in KL_front_CT"; return, end
    f = rv.KL_front_CT.(method);
    if stat == "mean" && isfield(f,'KL_cm2min_mean')
        KL = f.KL_cm2min_mean;  dKL = f.KL_cm2min_std;
    else
        KL = f.KL_cm2min_best;  dKL = f.KL_cm2min_se;
    end
end
end
 
function v = paramStr(ep, names)
v = "";
n = fieldOrVarNames(ep);
for k = 1:numel(names)
    if ismember(names{k}, n)
        x = ep.(names{k});
        if iscell(x), x = x{1}; end
        v = string(x(1));  return
    end
end
end
 
function v = paramNum(ep, names)
v = NaN;
n = fieldOrVarNames(ep);
for k = 1:numel(names)
    if ismember(names{k}, n)
        x = ep.(names{k});
        if iscell(x), x = x{1}; end
        v = double(x(1));  return
    end
end
end
 
function n = fieldOrVarNames(r)
if istable(r), n = r.Properties.VariableNames; else, n = fieldnames(r); end
end

function plotSet(ax, Tg, exSet, source, mk, xp)
% one source for a set of experiments, coloured per experiment, with x/y error bars
for e = 1:numel(exSet)
    sel = Tg.experiment == exSet(e).label & Tg.source == source;
    if ~any(sel), continue, end
    x  = Tg.(xp{1})(sel);   dx = Tg.(xp{2})(sel);
    y  = Tg.KLD0(sel);      dy = Tg.dKLD0(sel);
    dx(~isfinite(dx)) = 0;  dy(~isfinite(dy)) = 0;
    dyLow = min(dy, 0.99*y);
    dxLow = dx;  if xp{4}, dxLow = min(dx, 0.99*x); end
    errorbar(ax, x, y, dyLow, dy, dxLow, dx, mk, ...
        'Color',exSet(e).color, 'MarkerFaceColor',exSet(e).color, ...
        'MarkerEdgeColor',0.5*exSet(e).color, 'MarkerSize',9, ...
        'LineStyle','none', 'CapSize',4, 'HandleVisibility','off')
end
end

function c = redblue(n)
% diverging blue-white-red colormap
h = floor(n/2);
c = [[linspace(0.15,1,h)' linspace(0.3,1,h)' ones(h,1)]; ...
     [ones(n-h,1) linspace(1,0.3,n-h)' linspace(1,0.15,n-h)']];
end

function c = ternColor(dark)
if dark, c = [1 1 1]; else, c = [0 0 0]; end
end

function s = ternStr(cond, a, b)
if cond, s = a; else, s = b; end
end

function [KL, dKL] = firstKL(Tg, lbl, src)
% KL +/- dKL of one experiment and source (first matching row), NaN if none
KL = NaN;  dKL = NaN;
k = find(Tg.experiment == lbl & Tg.source == src, 1);
if isempty(k), return, end
KL = Tg.KL_cm2min(k);  dKL = Tg.dKL_cm2min(k);
if ~isfinite(dKL), dKL = 0; end
end

function addOneToOne(ax, v)
% 1:1 line and +/-25 % band over the range of the plotted values
v = v(isfinite(v) & v > 0);
if isempty(v), return, end
lim = [min(v)/1.5, max(v)*1.5];
plot(ax, lim, lim, 'k-', 'HandleVisibility','off')
plot(ax, lim, 1.25*lim, 'k:', 'HandleVisibility','off')
plot(ax, lim, lim/1.25, 'k:', 'HandleVisibility','off')
xlim(ax, lim);  ylim(ax, lim)
end

function col = radarColour(ex, over)
% experiment colour for the radar; pairs listed in `over` get {light, dark} by Q
col = ex.color;
key = matlab.lang.makeValidName(regexprep(ex.label, '\s.*$', ''));   % "H2-CO2 Q5" -> H2_CO2
if ~isfield(over, key) || ~startsWith(ex.label, regexprep(ex.label, '\s.*$', '') + " Q"), return, end
c = over.(key);
if contains(ex.label, "Q1"), col = c{1}; else, col = c{2}; end
end