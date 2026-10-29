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
% All-authors database (figures 3-4):
%
%       input_KL_allAuthors.xlsx
%
%           1_CF_CT_main     main CF/CT experiments (vertical UHS + He-Xe)
%           2_extra_own      extra own experiments (horizontal H2-CO2, He-CO2)
%           3_other_authors  literature data
%
%       one row per data point, with alpha, tau and their uncertainties.
%       Empty cells of the own rows are filled from
%           results/dimlessKL/KL_dimless_all.xlsx   (main_dimlessTranspNo: KL, D0, M, Ng)
%           results/**/expProcFullData.mat           (main_Processing: alpha, tau)
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
% FIGURES 3-4 (all authors, input_KL_allAuthors.xlsx):
% -------------------------------------------------------------------------
%
%       KL/D0 vs Pe = ux*alpha/D0,  marker = author,  colour = M   (figure 3)
%       KL/D0 vs Pe = ux*alpha/D0,  marker = author,  colour = Ng  (figure 4)
%
% where:
%
%       M  = mu2/mu1                              (REFPROP)
%       Ng = K*(rho1-rho2)*g*sin(theta)/(mu2*ux)  (REFPROP)
%       D0 = Thorne-Enskog D12 at the 50/50 mixture (LJ parameters of
%            inputDiffConfig.xlsx, as main_fluidProps_errorProp)
%
%       fluid 1 = displacing (injected), fluid 2 = displaced (resident)
%
% Error bars: KL/D0 from dKL and dD0, Pe from d_alpha and dD0.
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
%
% All authors (figures 3-4):
%
%       allAuthors_KLD0_vs_Pe_colorM.png/.fig
%
%       allAuthors_KLD0_vs_Pe_colorNg.png/.fig
%
%       KL_allAuthors_used.xlsx      (every value used, incl. D0 source)
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
% Figures 3-4:
%
%       initREFPROP, getFluidProps_REFPROP,
%       import_params_diffusion_LJ, calc_diff_thorne
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
%
%   Figures 3-4 use main_dimlessTranspNo output for the own experiments:
%   run main_fluidProps_errorProp and main_dimlessTranspNo before this script.

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

%% All authors: KL/D0 vs Pe (alpha), colour = M (figure 3) and colour = Ng (figure 4)
% Data from input_KL_allAuthors.xlsx, one row per data point (sheets 1-3, see header).
% Empty cells of the OWN rows (sheets 1-2) are filled from:
%   KL_dimless_all.xlsx (main_dimlessTranspNo): KL, dKL, D0 (Thorne), M, Ng, u
%   expProcFullData.mat (main_Processing):      alpha, alpha_tau, tau (+ uncertainties)
% Other authors: mu and rho from REFPROP, D0 = Thorne-Enskog D12 at the 50/50 mixture;
% the reported D0 is kept for comparison. Ng only where K and theta are given.
% Marker = author, colour = M or Ng.

thisRepo       = pwd;                                          % run from the repo root
pathExport     = pathExportAll;
closeAfterSave = false;

allAuthorsFile = fullfile(thisRepo, 'input', 'input_KL_allAuthors.xlsx');
aaSheets       = ["1_CF_CT_main", "2_extra_own", "3_other_authors"];
aaOwnFile      = fullfile(thisRepo, 'results', 'dimlessKL', 'KL_dimless_all.xlsx');  % main_dimlessTranspNo
aaOwnSource    = "MFM";           % KL source used for the own rows
aaOwnGroup     = "theory";        % conditions for own rows: "theory" | "measAvg" | "measBegEnd"
aaMFMRoot      = fullfile(thisRepo, 'results');                % where main_Processing writes expProcFullData.mat
aaFitData      = "wEOS";          % "wEOS" (concentration) or "woEOS" (rhoNorm), as in main_dimlessTranspNo
aaAlphaSource  = "group";         % own rows with empty alpha: "group" (per-case fit) | "pooled"
aaPeAlpha      = "alpha";         % "alpha": Pe = u*alpha/D0 | "alphaTau": Pe = u*alpha_tau/D0
aaD0Mode       = "thorne";        % "thorne": Thorne-Enskog D12 for every row | "sheet": D0_cm2min column where filled
aaDiffConfig   = fullfile(thisRepo, 'inputDiffConfig.xlsx');   % LJ parameters (as main_fluidProps_errorProp)
aaNgColour     = "signedlog";     % "signedlog" (sign*log10(1+|Ng|)) | "linear"
aaMarkers      = {'o','s','^','d','v','p','h','<','>'};

if ~isfile(allAuthorsFile)
    warning('All-authors file not found (%s) -- figures 3-4 skipped', allAuthorsFile);
else
    numCols = ["T_C","P_MPa","P_psig","L_cm","porosity","K_mD","theta_deg","u_cmmin", ...
               "KL_cm2min","dKL_cm2min","D0_cm2min","dD0_cm2min", ...
               "alpha_cm","d_alpha_cm","alpha_tau_cm","d_alpha_tau_cm","tau","d_tau", ...
               "mu1_Pas","mu2_Pas","rho1_kgm3","rho2_kgm3","include"];
    txtCols = ["Author","Ref","Dataset","Experiment","Rock","Fluid1","Fluid2","notes"];

    A = table();
    for s = 1:numel(aaSheets)
        opts = detectImportOptions(allAuthorsFile, 'Sheet', aaSheets(s), 'VariableNamingRule','preserve');
        vn   = string(opts.VariableNames);
        miss = setdiff([txtCols numCols], vn);
        if ~isempty(miss), error('Sheet %s: missing columns %s', aaSheets(s), strjoin(miss, ', ')); end
        opts = setvartype(opts, cellstr(numCols), 'double');
        opts = setvartype(opts, cellstr(txtCols), 'string');
        opts.SelectedVariableNames = cellstr([txtCols numCols]);    % calc_ preview columns ignored
        Ts = readtable(allAuthorsFile, opts);
        Ts = Ts(~ismissing(Ts.Author) & Ts.Author ~= "", :);
        Ts.sheet = repmat(s, height(Ts), 1);
        A = [A; Ts]; %#ok<AGROW>
    end
    A.include(~isfinite(A.include)) = 1;
    A = A(A.include ~= 0, :);
    nA = height(A);
    Mown = NaN(nA,1);  Ngown = NaN(nA,1);
    A.D0_reported_cm2min = A.D0_cm2min;          % value typed in the sheet (kept for comparison)
    A.D0_source = repmat("sheet", nA, 1);
    A.D0_source(~isfinite(A.D0_cm2min)) = "";

    % ---- own rows: fill empty cells from main_dimlessTranspNo and main_Processing
    Town = table();
    if isfile(aaOwnFile)
        Town = readtable(aaOwnFile, 'TextType','string');
        Town = Town(Town.source == aaOwnSource & Town.group == aaOwnGroup, :);
    else
        warning('All authors: %s not found -- run main_dimlessTranspNo first; own rows use the sheet values only', aaOwnFile);
    end
    mfmFiles = mfmFileIndex(aaMFMRoot);          % MFM key -> newest expProcFullData.mat

    for r = find(A.sheet <= 2)'
        lab = A.Experiment(r);
        key = "";
        tr  = table();
        if ~isempty(Town), tr = Town(Town.experiment == lab, :); end
        if isempty(tr)
            warning('All authors: %s not in %s (group %s) -- only the sheet values are used', lab, aaOwnFile, aaOwnGroup);
        else
            tr = tr(1,:);
            if ~isfinite(A.KL_cm2min(r)), A.KL_cm2min(r) = tr.KL_cm2min;  A.dKL_cm2min(r) = tr.dKL_cm2min; end
            if aaD0Mode == "thorne" || ~isfinite(A.D0_cm2min(r))  % own rows: Thorne D12 of the props file
                A.D0_cm2min(r) = tr.D0_cm2min;  A.dD0_cm2min(r) = tr.dD0_cm2min;
                A.D0_source(r) = "thorne (props file)";
            end
            if ~isfinite(A.u_cmmin(r)), A.u_cmmin(r) = tr.u_cmmin; end
            Mown(r) = tr.M;  Ngown(r) = tr.Ng;
            key = tr.sourceKey;
        end
        if (ismissing(key) || key == "") && startsWith(A.Dataset(r), "CF_"), key = A.Dataset(r); end
        if ~ismissing(key) && key ~= "" && isKey(mfmFiles, char(key))
            al = getMFMAlpha(mfmFiles(char(key)), key, aaFitData, aaAlphaSource);
            for f = ["alpha_cm","d_alpha_cm","alpha_tau_cm","d_alpha_tau_cm","tau","d_tau"]
                if ~isfinite(A.(f)(r)), A.(f)(r) = al.(f); end
            end
        end
    end

    % ---- D0 = Thorne-Enskog D12 at the 50/50 mixture (other authors, and own rows still without D0)
    needD = A.D0_source ~= "thorne (props file)";
    if aaD0Mode == "sheet", needD = needD & ~isfinite(A.D0_cm2min); end
    if any(needD)
        try
            if isfolder(fullfile(thisRepo,'functions')), addpath(fullfile(thisRepo,'functions')); end
            dCfg  = readtable(aaDiffConfig);
            iTh   = strcmp(dCfg.Model, "Thorne");
            if ~any(iTh), error('Thorne model not found in %s', aaDiffConfig); end
            LJ    = import_params_diffusion_LJ(dCfg.inputDiffModel{iTh});
            dCache = containers.Map('KeyType','char','ValueType','any');
            for r = find(needD)'
                P_MPa = A.P_MPa(r);
                if ~isfinite(P_MPa), P_MPa = (A.P_psig(r) + 14.696)*0.00689476; end
                P_psig_r = P_MPa/0.00689476 - 14.696;            % calc_diff_thorne takes psig
                f1 = char(A.Fluid1(r));  f2 = char(A.Fluid2(r));
                ck = sprintf('%s_%s_%.3f_%.3f', f1, f2, A.T_C(r), P_psig_r);
                if ~isKey(dCache, ck)
                    lj1 = LJ(strcmp(LJ.Fluid, f1), :);  lj2 = LJ(strcmp(LJ.Fluid, f2), :);
                    if height(lj1) ~= 1 || height(lj2) ~= 1
                        warning('All authors: no LJ parameters for %s/%s -- D0 from the sheet', f1, f2);
                        dCache(ck) = [NaN NaN];
                    else
                        [Dv, dDv] = calc_diff_thorne(f1, f2, [0.5 0.5], A.T_C(r), P_psig_r, ...
                            lj1.sigma, lj2.sigma, lj1.eps, lj2.eps, ...
                            lj1.dsigma, lj2.dsigma, lj1.deps, lj2.deps);
                        dCache(ck) = [Dv dDv];
                    end
                end
                v = dCache(ck);
                if isfinite(v(1))
                    A.D0_cm2min(r) = v(1);  A.dD0_cm2min(r) = v(2);  A.D0_source(r) = "thorne";
                end
            end
        catch ME
            warning('All authors: Thorne D0 failed (%s) -- D0 from the sheet where given', ME.message);
        end
    end
    if any(A.D0_source == "thorne")
        Tcmp = unique(A(A.D0_source == "thorne" & isfinite(A.D0_reported_cm2min), ...
            {'Dataset','Fluid1','Fluid2','T_C','P_MPa','D0_reported_cm2min','D0_cm2min'}), 'rows');
        if ~isempty(Tcmp)
            Tcmp.ratio_Thorne_reported = Tcmp.D0_cm2min ./ Tcmp.D0_reported_cm2min;
            disp('All authors: Thorne D0 vs reported D0'); disp(Tcmp)
        end
    end

    % ---- viscosity / density from REFPROP where empty (and no M/Ng from the props file)
    needP = (~isfinite(A.mu1_Pas) | ~isfinite(A.mu2_Pas) | ~isfinite(A.rho1_kgm3) | ~isfinite(A.rho2_kgm3)) ...
            & ~isfinite(Mown);
    if any(needP)
        try
            if isfolder(fullfile(thisRepo,'functions')), addpath(fullfile(thisRepo,'functions')); end
            RPaa = initREFPROP();
            propC = containers.Map('KeyType','char','ValueType','any');
            for r = find(needP)'
                P_MPa = A.P_MPa(r);
                if ~isfinite(P_MPa), P_MPa = (A.P_psig(r) + 14.696)*0.00689476; end
                T_K = A.T_C(r) + 273.15;  P_kPa = P_MPa*1000;
                if ~isfinite(T_K) || ~isfinite(P_kPa), continue, end
                for fl = 1:2
                    fn = A.(sprintf('Fluid%d', fl))(r);
                    ck = sprintf('%s_%.3f_%.3f', fn, T_K, P_kPa);
                    if ~isKey(propC, ck)
                        pr = getFluidProps_REFPROP(RPaa, char(fn), T_K, P_kPa);
                        propC(ck) = [pr.mu, pr.rho];
                    end
                    v = propC(ck);
                    if ~isfinite(A.(sprintf('mu%d_Pas', fl))(r)),   A.(sprintf('mu%d_Pas', fl))(r)   = v(1); end
                    if ~isfinite(A.(sprintf('rho%d_kgm3', fl))(r)), A.(sprintf('rho%d_kgm3', fl))(r) = v(2); end
                end
            end
        catch ME
            warning('All authors: REFPROP not available (%s) -- rows without mu/rho have no M or Ng', ME.message);
        end
    end

    % ---- dimensionless numbers
    A.M  = A.mu2_Pas ./ A.mu1_Pas;
    A.Ng = A.K_mD*9.869e-16 .* (A.rho1_kgm3 - A.rho2_kgm3) * 9.81 .* sind(A.theta_deg) ...
           ./ (A.mu2_Pas .* A.u_cmmin/6000);
    A.M(~isfinite(A.M))   = Mown(~isfinite(A.M));               % own rows: props file values
    A.Ng(~isfinite(A.Ng)) = Ngown(~isfinite(A.Ng));
    if aaPeAlpha == "alphaTau"
        aUse = A.alpha_tau_cm;  daUse = A.d_alpha_tau_cm;  peLbl = 'Pe = u \alpha_\tau / D_0';
    else
        aUse = A.alpha_cm;      daUse = A.d_alpha_cm;      peLbl = 'Pe = u \alpha / D_0';
    end
    relD0 = A.dD0_cm2min ./ A.D0_cm2min;     relD0(~isfinite(relD0)) = 0;
    relKL = A.dKL_cm2min ./ A.KL_cm2min;     relKL(~isfinite(relKL)) = 0;
    relA  = daUse ./ aUse;                   relA(~isfinite(relA))   = 0;
    A.Pe    = A.u_cmmin .* aUse ./ A.D0_cm2min;
    A.dPe   = A.Pe .* sqrt(relA.^2 + relD0.^2);
    A.KLD0  = A.KL_cm2min ./ A.D0_cm2min;
    A.dKLD0 = A.KLD0 .* sqrt(relKL.^2 + relD0.^2);

    ok = isfinite(A.Pe) & A.Pe > 0 & isfinite(A.KLD0) & A.KLD0 > 0;
    if any(~ok)
        warning('All authors: %d rows without KL, D0 or alpha are not plotted (%s)', nnz(~ok), ...
            strjoin(unique(A.Experiment(~ok)), ', '));
    end
    A = A(ok, :);
    writetable(A, fullfile(pathExport, 'KL_allAuthors_used.xlsx'));

    if ~isempty(A)
        plotAllAuthors(A, A.M,  'M = \mu_2/\mu_1 [-]', "log", aaMarkers, peLbl, ...
            'K_L/D_0 vs Pe, all authors -- colour = M', "allAuthors_KLD0_vs_Pe_colorM", pathExport, closeAfterSave);
        plotAllAuthors(A, A.Ng, 'N_g [-]', aaNgColour, aaMarkers, peLbl, ...
            'K_L/D_0 vs Pe, all authors -- colour = N_g', "allAuthors_KLD0_vs_Pe_colorNg", pathExport, closeAfterSave);
    end
end


%% Local functions

function plotAllAuthors(A, cv, cLabel, cMode, mk, peLbl, ttl, fname, pathExport, closeAfterSave)
% KL/D0 vs Pe, marker = author, colour = cv (M or Ng); rows with NaN colour drawn open grey
fig = figure('Position',[80 80 1150 760]);
ax  = axes(fig);  hold(ax,'on')

c = cv;
switch cMode
    case "log",       c(c <= 0) = NaN;  c = log10(c);
    case "signedlog", c = sign(c).*log10(1 + abs(c));
end
okC = isfinite(c);

dy = A.dKLD0;  dy(~isfinite(dy)) = 0;  dyLow = min(dy, 0.99*A.KLD0);
dx = A.dPe;    dx(~isfinite(dx)) = 0;  dxLow = min(dx, 0.99*A.Pe);
errorbar(ax, A.Pe, A.KLD0, dyLow, dy, dxLow, dx, 'LineStyle','none', 'Color',[0.75 0.75 0.75], ...
    'CapSize',2, 'HandleVisibility','off')

auth = unique(A.Author, 'stable');
for k = 1:numel(auth)
    s   = A.Author == auth(k);
    m   = mk{mod(k-1, numel(mk)) + 1};
    own = any(A.sheet(s) <= 2);
    lw  = 0.6;  sz = 60;
    if own, lw = 1.4; sz = 95; end
    if any(s & okC)
        scatter(ax, A.Pe(s & okC), A.KLD0(s & okC), sz, c(s & okC), m, 'filled', ...
            'MarkerEdgeColor','k', 'LineWidth',lw, 'DisplayName', auth(k))
    end
    if any(s & ~okC)
        scatter(ax, A.Pe(s & ~okC), A.KLD0(s & ~okC), sz, [0.55 0.55 0.55], m, 'LineWidth',lw, ...
            'DisplayName', auth(k) + " (" + strtok(string(cLabel)) + " n/a)")
    end
end

xr = logspace(floor(log10(min(A.Pe))) - 0.2, ceil(log10(max(A.Pe))) + 0.2, 200);
plot(ax, xr, xr,     'k--', 'LineWidth',1, 'DisplayName','K_L/D_0 = Pe')
plot(ax, xr, 1 + xr, 'k:',  'LineWidth',1, 'DisplayName','K_L/D_0 = 1 + Pe  (\tau = 1)')

set(ax, 'XScale','log', 'YScale','log', 'FontSize',12);  grid(ax,'on')
xlabel(ax, peLbl, 'FontSize',13);  ylabel(ax, 'K_L / D_0 [-]', 'FontSize',13)

cb = colorbar(ax);
if any(okC)
    switch cMode
        case "log"
            colormap(ax, turbo);
            lo = min(c(okC));  hi = max(c(okC));  if hi <= lo, hi = lo + 0.1; end
            clim(ax, [lo hi]);
            tk = linspace(lo, hi, 6);  cb.Ticks = tk;  cb.TickLabels = compose('%.3g', 10.^tk);
        case "signedlog"
            colormap(ax, redblue(256));
            mx = max(abs(c(okC)));  if mx == 0, mx = 1; end
            clim(ax, [-mx mx]);
            tk = linspace(-mx, mx, 7);  cb.Ticks = tk;
            cb.TickLabels = compose('%.3g', sign(tk).*(10.^abs(tk) - 1));
        otherwise
            colormap(ax, redblue(256));
            mx = max(abs(c(okC)));  if mx == 0, mx = 1; end
            clim(ax, [-mx mx]);
    end
end
cb.Label.String = cLabel;

legend(ax, 'Location','northwest', 'FontSize',9, 'Interpreter','tex')
title(ax, ttl, 'Interpreter','tex')
saveas(fig, fullfile(pathExport, fname), 'png');
saveas(fig, fullfile(pathExport, fname), 'fig');
if closeAfterSave, close(fig); end
end

function v = firstField(r, n, names)
% first finite value among the given field/column names (NaN if none)
v = NaN;
for k = 1:numel(names)
    if ismember(names{k}, n)
        x = r.(names{k});
        if iscell(x), x = x{1}; end
        if ~isempty(x) && isfinite(x(1)), v = double(x(1)); return, end
    end
end
end
 

function al = getMFMAlpha(file, key, fitData, mode)
% alpha (alpha-only fit), alpha_tau, tau and their uncertainties for an MFM experiment
% from main_Processing: mode "group" = per-case fit stored in results,
% "pooled" = pooled fit (best_per_key row). Uncertainty = total (fit + method spread)
% when available, otherwise the fit error.
persistent fileCache
if isempty(fileCache), fileCache = containers.Map('KeyType','char','ValueType','any'); end
al = struct('alpha_cm',NaN, 'd_alpha_cm',NaN, 'alpha_tau_cm',NaN, 'd_alpha_tau_cm',NaN, ...
            'tau',NaN, 'd_tau',NaN);
if ~isKey(fileCache, char(file)), fileCache(char(file)) = load(file, 'expProcFullData'); end
S = fileCache(char(file));
if ~isfield(S, 'expProcFullData'), return, end
if mode == "pooled"
    try
        r = S.expProcFullData.fitSummary.(fitData).alpha_pooled;
        r = r(r.method == "best_per_key", :);
    catch
        return
    end
else
    if ~isfield(S.expProcFullData, key), return, end
    e = S.expProcFullData.(key);
    if ~isfield(e, fitData) || ~isfield(e.(fitData), 'results'), return, end
    r = e.(fitData).results;
end
if isempty(r), return, end
n = fieldOrVarNames(r);
pick = @(names) firstField(r, n, names);
al.alpha_cm       = pick({'alpha_cm'});
al.d_alpha_cm     = pick({'totUncertAlpha_cm','d_alpha_cm'});
al.alpha_tau_cm   = pick({'alpha_tau_cm'});
al.d_alpha_tau_cm = pick({'totUncertAlpha_tau_cm','d_alpha_tau_cm'});
al.tau            = pick({'tau'});
al.d_tau          = pick({'totUncertTau','d_tau'});
end

function M = mfmFileIndex(root)
% MFM experiment key -> newest expProcFullData.mat under root that contains it
M  = containers.Map('KeyType','char','ValueType','any');
dn = containers.Map('KeyType','char','ValueType','double');
files = dir(fullfile(root, '**', 'expProcFullData.mat'));
for f = files'
    fp = fullfile(f.folder, f.name);
    try
        w = whos('-file', fp);
        if ~any(strcmp({w.name}, 'expProcFullData')), continue, end
        S = load(fp, 'expProcFullData');
    catch
        continue
    end
    for k = setdiff(fieldnames(S.expProcFullData), {'fitSummary'})'
        kk = k{1};
        if ~isKey(M, kk) || f.datenum > dn(kk)
            M(kk) = fp;  dn(kk) = f.datenum;
        end
    end
end
end

function n = fieldOrVarNames(r)
if istable(r), n = r.Properties.VariableNames; else, n = fieldnames(r); end
end

function c = redblue(n)
% diverging blue-white-red colormap
h = floor(n/2);
c = [[linspace(0.15,1,h)' linspace(0.3,1,h)' ones(h,1)]; ...
     [ones(n-h,1) linspace(1,0.3,n-h)' linspace(1,0.15,n-h)']];
end