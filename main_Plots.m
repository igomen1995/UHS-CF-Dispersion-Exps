%% main_Plots.m
% Author: Ianna Gomez Mendez
%
% PURPOSE
%   Generate breakthrough-curve comparison figures for core-flood and
%   dispersion experiments processed using MAIN_DATAEXTRACT.
%
%   Experiments are grouped by fluid system, temperature and pressure.
%   Within each group, curves are labelled by flow rate and run number.
%
%       - Molar-composition breakthrough curves      (Ci  vs time)
%       - Dimensionless breakthrough curves          (CDi vs tD)
%       - Experimental uncertainty bounds            (error bars)
%       - All experiments together, both forms
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
%
%   inputExpConfig.xlsx      configuration
%   inputExp.xlsx            experimental metadata
%   expProcData.mat          processed data from main_DataExtract.m
%
% -------------------------------------------------------------------------
% GENERATED FIGURES
% -------------------------------------------------------------------------
%
%   Per case (same Fluid1, Fluid2, T, P; all Q and runs):
%
%       CF_<Fluid1>_<Fluid2>_T<T>_P<P>_Qall.png       Ci  vs TimeElapsed
%       CF_<Fluid1>_<Fluid2>_T<T>_P<P>_Qall_nd.png    CDi vs tD
%
%   All experiments together:
%
%       all_fluids_T_P_Q.png                          Ci  vs TimeElapsed
%       all_fluids_T_P_Q_nd.png                       CDi vs tD
%
% -------------------------------------------------------------------------
% NOTES
% -------------------------------------------------------------------------
%
%   - Only combinations of Fluid1/Fluid2/T/P that exist in the input are
%     plotted (no empty figures).
%
%   - Run number comes from a 'Run' column in inputExp.xlsx if present;
%     otherwise repeats of the same Q within a case are numbered 1, 2, ...
%
%   - Duplicate experiment keys in inputExp.xlsx are removed with a
%     warning (same Key = same data in expProcData).
%
%   - Error bars are the composition uncertainty propagated from the
%     density calibration (Ci +/- dCi, CDi +/- dCDi).

%% IMPORT

addpath('functions/');

inputFileConfigName = 'inputExpConfig.xlsx';
inputFileConfig     = readtable(inputFileConfigName);

filenameExp   = inputFileConfig.inputFileName{:};
pathImportAll = inputFileConfig.exportPath{:};   % path for INPUT and OUTPUT
mkdir(pathImportAll);

%% IMPORT variables

filedataExp = import_inputExp(filenameExp);
load(pathImportAll + "expProcData.mat")

% remove duplicated experiment keys (same Key = same data in expProcData)
[~, iu] = unique(string(filedataExp.Key), 'stable');
if numel(iu) < height(filedataExp)
    dupKeys = unique(string(filedataExp.Key(setdiff(1:height(filedataExp), iu))));
    warning("inputExp:duplicateKeys", "Duplicate keys removed: %s", strjoin(dupKeys, ", "))
    filedataExp = filedataExp(iu,:);
end

% keep only keys that exist in expProcData
hasData = arrayfun(@(k) isfield(expProcData, char(k)), string(filedataExp.Key));
if ~all(hasData)
    warning("inputExp:missingData", "No processed data for: %s", ...
        strjoin(string(filedataExp.Key(~hasData)), ", "))
    filedataExp = filedataExp(hasData,:);
end
nExp = height(filedataExp);

%% Plot settings

colors = orderedcolors("glow");  nC = size(colors,1);
hasRun = ismember('Run', filedataExp.Properties.VariableNames);

% one case per existing combination of fluids, T and P
caseID = string(filedataExp.Fluid1) + "_" + string(filedataExp.Fluid2) + ...
         "_T" + string(filedataExp.T) + "_P" + string(filedataExp.P);
cases  = unique(caseID, 'stable');

% plot variants: {x var, y var, ymin var, ymax var, x label, y label, ylim, xlim, file suffix}
variants = { ...
    'TimeElapsed', 'Ci',  'CiMin',  'CiMax', ...
        'Time elapsed [hh:mm:ss]', 'C_1 [mol %]', [0 100], [],    "_Qall"; ...
    'tD',          'CDi', 'CDiMin', 'CDiMax', ...
        'Dimensionless time t_D [-]', 'C_D [-]',  [0 1],   [0 2], "_Qall_nd"};

%% Per case: same Fluid1, Fluid2, T, P - all Q and runs

for v = 1:size(variants,1)
    [xVar, yVar, yMinVar, yMaxVar, xLab, yLab, yLim, xLim, suffix] = variants{v,:};

    for c = 1:numel(cases)

        % experiments of this case, sorted by Q (stable -> runs keep input order)
        idxCase = find(caseID == cases(c));
        [~, ord] = sort(filedataExp.Q(idxCase));
        idxCase  = idxCase(ord);

        figure
        hold on
        Q_seen = [];

        for q = 1:numel(idxCase)
            i   = idxCase(q);
            key = filedataExp.Key(i);
            BT  = expProcData.(key).BT;

            x    = BT.(xVar);
            y    = BT.(yVar);
            yMin = BT.(yMinVar);
            yMax = BT.(yMaxVar);

            % run number: Run column if present, else repeat count of same Q
            if hasRun
                runN = filedataExp.Run(i);
            else
                Q_seen(end+1) = filedataExp.Q(i); %#ok<AGROW>
                runN = sum(Q_seen == filedataExp.Q(i));
            end

            errorbar(x, y, y - yMin, yMax - y, 'LineStyle','none', ...
                'Color', [0.8 0.8 0.8], 'HandleVisibility','off')
            scatter(x, y, 5, 'filled', 'MarkerFaceColor', colors(mod(q-1,nC)+1,:), ...
                'DisplayName', "Q = " + filedataExp.Q(i) + " ml/min, run " + runN + ...
                ": C_{MFM} \pm \DeltaC_{MFM}");
        end

        xlabel(xLab)
        ylabel(yLab)
        if isduration(x), xtickformat('hh:mm:ss'), end
        ylim(yLim)
        if ~isempty(xLim), xlim(xLim), end
        grid on
        legend('Location','southeast')

        save_name = "CF_" + cases(c) + suffix;
        title(save_name, 'Interpreter','none')
        saveas(gcf, pathImportAll + save_name, 'png')
    end
end

%% All experiments together

cAll = parula(max(nExp,1));
allNames = ["all_fluids_T_P_Q", "all_fluids_T_P_Q_nd"];

for v = 1:size(variants,1)
    [xVar, yVar, ~, ~, xLab, yLab, yLim, xLim] = variants{v,1:8};

    figure
    hold on
    for i = 1:nExp
        key = filedataExp.Key(i);
        BT  = expProcData.(key).BT;
        scatter(BT.(xVar), BT.(yVar), 10, cAll(i,:), 'filled', 'DisplayName', key)
    end

    xlabel(xLab)
    ylabel(yLab)
    if isduration(BT.(xVar)), xtickformat('hh:mm:ss'), end
    ylim(yLim)
    if ~isempty(xLim), xlim(xLim), end
    grid on
    legend('Location','southeast','Interpreter','none')

    title(allNames(v), 'Interpreter','none')
    saveas(gcf, pathImportAll + allNames(v), 'png')
end