%% main_PlotsIntegration.m
% Author: Ianna Gomez Mendez
%
% PURPOSE
%   Integrate and compare longitudinal dispersion measurements obtained
%   in the present study with previously published literature data.
%
%   The workflow generates transport-scaling plots commonly used in
%   porous-media transport studies and evaluates whether dispersion
%   behavior observed in the current experiments is consistent with
%   previously reported trends.
%
% -------------------------------------------------------------------------
% OBJECTIVE
% -------------------------------------------------------------------------
%
%   Compare:
%
%       Longitudinal dispersion coefficient
%
%           KL
%
%   and
%
%       Dimensionless dispersion
%
%           KL / D0
%
%   as functions of:
%
%       Interstitial velocity
%
%           ux
%
%   and
%
%       Peclet number
%
%           Pe
%
%   across multiple experimental studies.
%
% -------------------------------------------------------------------------
% INPUT
% -------------------------------------------------------------------------
%
% Literature database:
%
%       input_expsAll_results.xlsx
%
% The workbook contains one worksheet for each experimental study
% or dataset.
%
% -------------------------------------------------------------------------
% DATA IMPORT
% -------------------------------------------------------------------------
%
% For each worksheet:
%
%       Experimental transport results
%
%       Experimental conditions
%
% are imported using:
%
%       import_inputExpsResults
%
%       import_inputExpsParams
%
% -------------------------------------------------------------------------
% EXPERIMENTAL PARAMETERS
% -------------------------------------------------------------------------
%
% For each dataset:
%
%       Reference
%       Fluid system
%       Sample
%       Temperature
%       Pressure
%       Porosity
%       Dispersivity
%       Molecular diffusivity
%
% are stored.
%
% -------------------------------------------------------------------------
% VISUALIZATION STRATEGY
% -------------------------------------------------------------------------
%
% Symbols represent:
%
%       Sample type
%
% Colors represent:
%
%       Reference + Fluid system
%
% Transparency represents:
%
%       Pressure level
%
% allowing multiple studies to be compared within a single figure.
%
% -------------------------------------------------------------------------
% FIGURE 1:
% -------------------------------------------------------------------------
%
%       KL vs ux
%
% where:
%
%       KL   = longitudinal dispersion coefficient
%
%       ux   = interstitial velocity
%
% Units:
%
%       KL  [cm²/min]
%       ux  [cm/min]
%
% Purpose:
%
%       Evaluate dispersivity-controlled transport behavior.
%
%       Identify velocity-dependent dispersion trends.
%
%       Compare measured transport coefficients between studies.
%
% -------------------------------------------------------------------------
% FIGURE 2:
% -------------------------------------------------------------------------
%
%       KL/D0 vs Pe
%
% where:
%
%       D0 = molecular diffusion coefficient
%
%       Pe = ux*alpha/D0
%
% Purpose:
%
%       Collapse transport data onto a dimensionless framework.
%
%       Compare experiments conducted with different:
%
%           fluids
%           pressures
%           temperatures
%           porous media
%
% -------------------------------------------------------------------------
% DIMENSIONLESS ANALYSIS
% -------------------------------------------------------------------------
%
% The Peclet number is defined as:
%
%       Pe = ux alpha / D0
%
% and represents the ratio of:
%
%       advective transport
%
% to
%
%       diffusive transport
%
% -------------------------------------------------------------------------
%
% The dimensionless dispersion coefficient:
%
%       KL / D0
%
% quantifies enhancement of transport relative to molecular diffusion.
%
% -------------------------------------------------------------------------
% COLOR CODING
% -------------------------------------------------------------------------
%
% Color groups:
%
%       Ref + Fluid2
%
% Example:
%
%       H2–CO2
%       H2–N2
%       H2–CH4
%
% from different publications.
%
% -------------------------------------------------------------------------
% SYMBOL CODING
% -------------------------------------------------------------------------
%
% Marker shape identifies:
%
%       Rock sample
%
% Examples:
%
%       Bentheimer
%       Berea
%       Carbonate
%       Sandpack
%
% -------------------------------------------------------------------------
% TRANSPARENCY CODING
% -------------------------------------------------------------------------
%
% Marker transparency is scaled using:
%
%       Pressure
%
% allowing visual identification of pressure effects while preserving
% color grouping.
%
% -------------------------------------------------------------------------
% OUTPUT FIGURES
% -------------------------------------------------------------------------
%
% KL versus velocity:
%
%       KLvsVel-alpha_allLit.png
%
%       KLvsVel-alpha_allLit.fig
%
% -------------------------------------------------------------------------
%
% Dimensionless transport:
%
%       KLD0vsPe_allLit.png
%
%       KLD0vsPe_allLit.fig
%
% -------------------------------------------------------------------------
% SCIENTIFIC APPLICATIONS
% -------------------------------------------------------------------------
%
% Typical uses:
%
%       - Benchmarking new transport measurements
%
%       - Comparing dispersivities across porous media
%
%       - Evaluating pressure effects
%
%       - Evaluating fluid-composition effects
%
%       - Testing transport-scaling relationships
%
%       - Preparing publication-quality comparison figures
%
% -------------------------------------------------------------------------
% DEPENDENCIES
% -------------------------------------------------------------------------
%
% Import functions:
%
%       import_inputExpsResults
%
%       import_inputExpsParams
%
% -------------------------------------------------------------------------
% OUTPUT
% -------------------------------------------------------------------------
%
% Figures only
%
% No fitting or parameter estimation is performed.
%
% The script is intended exclusively for:
%
%       visualization
%       comparison
%       benchmarking
%
% of transport parameters obtained from multiple studies.
%
% -------------------------------------------------------------------------
% NOTES
% -------------------------------------------------------------------------
%
%   This script represents the final integration stage of the workflow:
%
%       main_PR
%           ↓
%       main_Cal
%           ↓
%       main_Validation
%           ↓
%       main_DataExtract
%           ↓
%       main_Processing
%           ↓
%       main_ProcessingMixingCorrection
%           ↓
%       main_PlotsIntegration
%
%   allowing direct comparison between internally generated transport
%   parameters and literature-reported datasets.

%% IMPORT

addpath('functions/');

% Introduce name of input and desired output folder name

filenameExp = 'input/input_expsAll_results.xlsx';
mkdir('results/expsLiteratureIntegration');
pathExportAll = 'results/expsLiteratureIntegration/';

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
ylabel('Longitudinal Dispersion Coefficient (K_L) [cm^2/min]');
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



