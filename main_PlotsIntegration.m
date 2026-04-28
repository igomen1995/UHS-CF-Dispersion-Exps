% main_PlotsIntegration.m
% Author: Ianna Gomez Mendez
%
% Objective: Plot KL vs vel and KL/D0 vs Pe for all experiments in
% literature plus this one
% 
% Input (use Import Data tool in Matlab):
% 1 - expsAll_results
% 
% Procedure:
% 1 - Load input
% 2 - Plot according to goal
% 
% Output: 
% Figures
%
%% IMPORT

addpath('functions/');

% Introduce name of input and desired output folder name

filenameExp = 'input/input_expsAll_results.xlsx';
mkdir('results/expsLiteraturetIntegration');
pathExportAll = 'results/expsLiteraturetIntegration/';

%% IMPORT variables

[~, sheets] = xlsfinfo(filenameExp);

ExpsLiterature = struct();
filedataExpsParams = table('Size',[0 9], ...
          'VariableTypes', {'string','string','string','string','string', ...
          'string','string','string','string'}, ...
          'VariableNames', {'Ref','Fluid2','Sample','T_C','L_cm', ...
          'phi','alpha_cm','P_MPa','D0_cm2min'});
for i = 1:numel(sheets)
    sheetName = sheets{i};
    filedataExpsResultsAux = import_inputExpsResults(filenameExp,sheetName);
    filedataExpsParamsAux = import_inputExpsParams(filenameExp, sheetName);
    ExpsLiterature.(sheetName).filedataExpsResults = filedataExpsResultsAux;
    ExpsLiterature.(sheetName).filedataExpsParams = filedataExpsParamsAux;
    filedataExpsParams = [filedataExpsParams;filedataExpsParamsAux];
end

sample = unique(filedataExpsParams.Sample);

% colors based on Ref + Fluid2
[uniquePairs, ~, Gid] = unique( ...
    [filedataExpsParams.Ref, filedataExpsParams.Fluid2], ...
    'rows', 'stable');
numGroups = max(Gid);   % this will be 5 in your example
% colors = parula(numGroups); % if more than 7
colors = orderedcolors("gem");

% transparency based on P
P = str2double(filedataExpsParams.P_MPa);
[P_unique, ~, idxP] = unique(P, 'stable');
alpha_unique = rescale(P_unique,0, 1.0);
alphaVals = alpha_unique(idxP);

% symbols based on sample
samples = unique(filedataExpsParams.Sample, 'stable');
markerSymbols = {'o','^','s','d','v','>'};  % extendable
markerMap = containers.Map(samples, markerSymbols(1:numel(samples)));

%% Plot Kl_vs_vel

figure % dispersivity
for i = 1:height(filedataExpsParams)
    groupID = Gid(i);          % color group
    alpha_i = alphaVals(i);    % transparency
    sample_i = filedataExpsParams.Sample(i);
    marker_i = markerMap(sample_i);

    ux = ExpsLiterature.(sheets{i}).filedataExpsResults.u_cmmin;
    KL = ExpsLiterature.(sheets{i}).filedataExpsResults.KL_cm2min;

    scatter(ux, KL, 60, ...
        'Marker', marker_i, ...
        'MarkerFaceColor', colors(groupID,:), ...
        'MarkerFaceAlpha', alpha_i, ...
        'MarkerEdgeColor', colors(groupID,:), ...
        'DisplayName', "H2-" + ...
        filedataExpsParams.Fluid2(i) + "_" + filedataExpsParams.Sample(i) + ...
        "_" + filedataExpsParams.T_C(i) + " °C_" + ...
        filedataExpsParams.P_MPa(i) +" MPa");

    hold on
end
xlabel('Interstitial velocity (u_x) [cm/min]');
ylabel('Longitudinal Dispersion Coefficient (K_L) [cm^2/s]');
ylim([0,4.5])
grid on;
legend('Location','northeast','Interpreter','none');
saveas(gcf,pathExportAll + "KLvsVel-alpha_allLit",'png')
savefig(gcf,pathExportAll + "KLvsVel-alpha_allLit")

%% Plot Kl/Dl vs Pe

figure
for i = 1:height(filedataExpsParams)
    groupID = Gid(i);          % color group
    alpha_i = alphaVals(i);    % transparency
    sample_i = filedataExpsParams.Sample(i);
    marker_i = markerMap(sample_i);

    Pe = ExpsLiterature.(sheets{i}).filedataExpsResults.Pe_D0;
    KL_vs_D0 = ExpsLiterature.(sheets{i}).filedataExpsResults.KL_vs_D0;

    scatter(Pe,KL_vs_D0, 60, ...
        'Marker', marker_i, ...
        'MarkerFaceColor', colors(groupID,:), ...
        'MarkerFaceAlpha', alpha_i, ...
        'MarkerEdgeColor', colors(groupID,:), ...
        'DisplayName', "H2-" + ...
        filedataExpsParams.Fluid2(i) + "_" + filedataExpsParams.Sample(i) + ...
        "_" + filedataExpsParams.T_C(i) + " °C_" + ...
        filedataExpsParams.P_MPa(i) +" MPa");

    hold on
end
xlabel('Pe = u_x\alpha/D_0')
ylabel('K_L/D_0');
ylim([0.08,10])
set(gca, 'XScale','log','YScale','log')
grid on;
legend('Location','northwest','Interpreter','none');
saveas(gcf,pathExportAll + "KLD0vsPe_allLit",'png')
savefig(gcf,pathExportAll + "KLD0vsPe_allLit")



