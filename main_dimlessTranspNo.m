%% main_dimlessTranspNo.m
% Relates the measured dispersion coefficient KL (scaled by the molecular
% diffusion coefficient D0) to the dimensionless numbers of each case:
%       KL/D0  vs  Pe, M, Ng, Nrho      (one figure per x-axis)
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
% KL sources per experiment
%   MFM     expProcFullData.(key).(wEOS|woEOS).results.KL_cm2min (+ totUncertKL_cm2min)
%   CT BTC  resultsAll.(ds).(variant).KL_BTC_CT_byZD.zD0p8.best
%   CT W    resultsAll.(ds).(variant).KL_front_CT.width_C20_80_int0
%   manual  KL +/- dKL typed in (experiments without a .mat file)
%
% Rows of `cases` (same order as main_fluidProps_errorProp.m):
%    1- 8  theory      nominal conditions (scaling analysis)
%    9-17  measAvg     average measured conditions
%   18-26  measBegEnd  per-fluid conditions (beginning / end of the run)
%
% Colours: He-Xe 725 blue, He-Xe 900 green, H2-CH4 yellow, H2-CO2 purple,
%          lighter = lower Q, darker = higher Q.
% Markers: MFM o, CT BTC square, CT width triangle, manual diamond.
%
% Outputs (pathExport)
%   MFM_index.xlsx                        all MFM experiments found in this repo
%   KL_dimless_all.xlsx                   one row per (case, KL source)
%   KLD0_vs_<Pe|M|Ng|Nrho>_<group>.png/.fig
 
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
 
% tolerances for matching an MFM experiment to a case ("auto" keys)
tolP = 0.05;    % relative, on nominal pressure
tolU = 0.15;    % relative, on interstitial velocity
 
groupsToPlot   = ["theory","measAvg","measBegEnd"];
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
               blueL, blueD, greenL, greenD}, ...
    'mfmKey', {"auto","auto","auto","auto","auto","auto","auto","auto","auto"}, ...
    'mfmRun', {1, 1, 1, 1, 2, 1, 1, 1, 1}, ...
    'ctKey',  {"", "", "", "", "", ...
               "CF_He_Xe_T20_P725_V_Q1_R1", "CF_He_Xe_T20_P725_V_Q5_R1", ...
               "CF_He_Xe_T20_P900_V_Q1_R1", "CF_He_Xe_T20_P900_V_Q5_R1"}, ...
    'KL',     {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN}, ...
    'dKL',    {NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN});
 
% other experiments later, e.g. (row 27 added in main_fluidProps_errorProp.m):
% exps(end+1) = struct('label',"He-CO2 1500 Q05",'idx',27,'color',[0.85 0.33 0.10], ...
%     'mfmKey',"CF_He_CO2_T40_P1500_H_Q05_R1",'mfmRun',1,'ctKey',"",'KL',NaN,'dKL',NaN);
 
srcNames = ["MFM", "CT BTC zD=" + strrep(extractAfter(ctBTCtag,"zD"),"p","."), ...
            "CT width " + regexprep(ctWidthTag, '^width_C(\d+)_(\d+).*$', '$1-$2'), "manual"];
srcMk    = ["o", "s", "^", "d"];
 
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
 
groupOfCase = [repmat("theory",1,8), repmat("measAvg",1,9), repmat("measBegEnd",1,9)];
groupOfCase(end+1:nCase) = "other";
groupOfCase = groupOfCase(1:nCase);
 
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
 
%% Collect KL for every experiment and source
 
rows = cell(0,1);
 
for e = 1:numel(exps)
    ex = exps(e);
    KLlist = struct('src',{},'KL',{},'dKL',{},'key',{});
 
    if ex.mfmKeyUsed ~= ""
        [KL, dKL, note] = getMFM(ex.mfmFileUsed, ex.mfmKeyUsed, mfmFitData, cache);
        KLlist = addKL(KLlist, srcNames(1), KL, dKL, ex.mfmKeyUsed, note, ex.label);
    end
    if ex.ctKey ~= ""
        ctFile = findPostproc(ctRoot, ex.ctKey);
        [KL, dKL, note] = getCT(ctFile, ctDataSource, ctVariant, "BTC_" + ctBTCtag, "fit", cache);
        KLlist = addKL(KLlist, srcNames(2), KL, dKL, ex.ctKey, note, ex.label);
        [KL, dKL, note] = getCT(ctFile, ctDataSource, ctVariant, ctWidthTag, ctWidthStat, cache);
        KLlist = addKL(KLlist, srcNames(3), KL, dKL, ex.ctKey, note, ex.label);
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
            rows{end+1,1} = table(c, groupOfCase(c), ex.label, string(d.Pair), ...
                d.Pmix_psig, d.Tmix_C, d.u_cmmin, q.src, q.key, ...
                q.KL, q.dKL, D0(c), dD0(c), KLD0, dKLD0, ...
                d.Pe, d.dPe, d.M, d.dM, d.Ng, d.dNg, d.Nrho, d.dNrho, PeKL, PeKL*q.dKL/q.KL, ...
                'VariableNames', {'caseIdx','group','experiment','pair', ...
                'Pmix_psig','Tmix_C','u_cmmin','source','sourceKey', ...
                'KL_cm2min','dKL_cm2min','D0_cm2min','dD0_cm2min','KLD0','dKLD0', ...
                'Pe','dPe','M','dM','Ng','dNg','Nrho','dNrho','PeKL','dPeKL'}); %#ok<SAGROW>
        end
    end
end
 
if isempty(rows), error('No valid KL entries -- check the MFM index and keys in `exps`'); end
T = vertcat(rows{:});
disp(T(:, {'caseIdx','group','experiment','source','sourceKey','KL_cm2min','KLD0','Pe','M','Ng'}))
writetable(T, fullfile(pathExport, 'KL_dimless_all.xlsx'));
 
%% Plots: one figure per (group, x-axis)
 
% {x column, dx column, x label, log x, file tag}
xPanels = {'Pe',   'dPe',   'Pe = uL/D_0 [-]',                     true,  'Pe'; ...
           'M',    'dM',    'M = \mu_2/\mu_1 [-]',                 false, 'M'; ...
           'Ng',   'dNg',   'N_g [-]',                             false, 'Ng'; ...
           'Nrho', 'dNrho', 'N_\rho = (\rho_1-\rho_2)/\rho_2 [-]', false, 'Nrho'};
 
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
                'MarkerEdgeColor','none', 'DisplayName', legendKeys(exps(e)))
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

xctMethods = srcNames([1 3 2]);          % MFM, CT width, CT BTC
xctExps    = startsWith([exps.label], "He-Xe");
uhsExps    = startsWith([exps.label], ["H2-CO2","H2-CH4"]);
uhsSource  = srcNames(1);                % UHS cases only have MFM

for g = groupsToPlot
    Tg = T(T.group == g & isfinite(T.KLD0) & T.KLD0 > 0, :);
    if isempty(Tg), warning('No KL entries for group %s', g); continue, end

    for p = 1:size(xPanels,1)
        fig = figure('Position',[60 80 1600 600]);
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
                'DisplayName', legendKeys(exps(e))); %#ok<SAGROW>
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
 
%% Local functions
 
function list = addKL(list, src, KL, dKL, key, note, label)
if ~(isfinite(KL) && KL > 0)
    warning('%s, %s (%s): %s -- skipped', label, src, key, note);
    return
end
if ~isfinite(dKL), dKL = 0; end
list(end+1) = struct('src',src,'KL',KL,'dKL',dKL,'key',string(key));
end
 
function txt = legendKeys(ex)
keys = [ex.mfmKeyUsed, ex.ctKey];
keys = keys(keys ~= "");
if isfinite(ex.KL), keys(end+1) = "manual"; end
if isempty(keys), txt = ex.label; else, txt = ex.label + ": " + strjoin(keys, " / "); end
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