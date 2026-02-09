% main_DataExtract.m
% version: v13_Feb2026
% Author: Ianna Gomez Mendez
% 
%
% Objective: Extract data collected during core flooding experiments
% using 3 Quizix pumps, 1 mass flow meter Bronkhorst, 2 transducers Omega
% and 2 portable gas detectors Cosmos (DOD Technologies)
% 
% Input (use Import Data tool in Matlab):
% 1 - Pumps file (.dat)
% 2 - Transducer file (.csv)
% 3 - Mass Flow Meters (.csv)
% 4 - Gas detectors - could be more than one file (.csv)
% 5 - Fitting parameters calibration curve 
% 6 - rho vs xi PR model points
% 
% Procedure:
% 1 - Import files
% 2 - Estimate xi array
% 3 - Export in Results one Excel for each experiment with all data in each
% spreadsheet
% 4 - Plot in one figure all vars (5 panels): vars included:PT1, PT2 P
% Conf, q pump, T MFM, densitites corrected, Xi estimated, C1 from PGDs
% 
% Output: 
% Database
% Figures
%
%% IMPORT input

addpath('functions/');

% Introduce name of input and desired output folder name

filenameExp = 'input/input_exp_H2-CO2-T32-P1500.xlsx';
pathImportCal = 'results/cal_250725_PR/';
pathImportPR = 'results/PR_H2-CO2-T32-P1500/';
mkdir('results/exp_H2-CO2-T32-P1500-H');
pathExportAll = 'results/exp_H2-CO2-T32-P1500-H/';

%% IMPORT data

% Do not change unless input excel format changed

opts = spreadsheetImportOptions("NumVariables", 29);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Key", "Date", "Type","Fluid1", "Fluid2", ...
    "T", "P", "Q", "Run", "D", "L", "phi", "K", "Vcore", ...
    "setupVersion", "Vlinesbefore", "Vlinesafter", "Vtotal", "Comments", "st", "et", "dt", ...
    "path", "pumps_data_name", "trans_data_name", "MFM_data_name", "PGD1_data_name", "PGD2_data_name","GMT_PGD"];
opts.VariableTypes = ["string", "string","string", "string", "string", ...
    "double", "double", "double", "double", "double", "double", "double", "double", "double", ...
    "string", "double", "double", "double","string", "datetime", "datetime", "double", ...
    "string", "string", "string", "string", "string", "string", "string"];
filedataExp = readtable(filenameExp,opts);

filedataExp.st = datetime(filedataExp.st,'Format','MM/dd/uuuu HH:mm:ss');
filedataExp.et = datetime(filedataExp.et,'Format','MM/dd/uuuu HH:mm:ss');

for i = 1:length(filedataExp.Key)
    pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

    if ismissing(pumps_data_name) == 0
        pumps_data = import_pumps_data(pumps_data_name);
    end

    if ismissing(trans_data_name) == 0
        trans_data = import_trans_data(trans_data_name);
    end

    if ismissing(MFM_data_name) == 0
        MFM_data = import_MFM_data(MFM_data_name);
    end

    if ismissing(PGD1_data_name) == 0
        PGD1_data = import_PGD1_data(PGD1_data_name);
        if filedataExp.GMT_PGD{i} == "GMT9"
        PGD1_data.TimeStamp = PGD1_data.TimeStamp - hours(13); %ONLY if PGD in Japan time GMT+9    
        end
    end

    if ismissing(PGD2_data_name) == 0
        PGD2_data = import_PGD2_data(PGD2_data_name);
        if filedataExp.GMT_PGD{i} == "GMT9"
        PGD2_data.TimeStamp = PGD2_data.TimeStamp - hours(13); %ONLY if PGD in Japan time GMT+9    
        end
    end

    % Trim data to st and et, and calculate time elapsed and vol injected
    expProcData.(filedataExp.Key(i)).pumpsData = pumps_data((pumps_data.TimeStamp>=filedataExp.st(i))&(pumps_data.TimeStamp<=filedataExp.et(i)),:);
    if isempty(expProcData.(filedataExp.Key(i)).pumpsData) == 0
        expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed = expProcData.(filedataExp.Key(i)).pumpsData.TimeStamp - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed.Format = 'hh:mm:ss.SSS';
        expProcData.(filedataExp.Key(i)).pumpsData.VolInjected = expProcData.(filedataExp.Key(i)).pumpsData.V_P1 - expProcData.(filedataExp.Key(i)).pumpsData.V_P1(1);
    end

    expProcData.(filedataExp.Key(i)).transData = trans_data((trans_data.TimeStamp_PT1>=filedataExp.st(i))&(trans_data.TimeStamp_PT1<=filedataExp.et(i)),:);
    if isempty(expProcData.(filedataExp.Key(i)).transData) == 0
        expProcData.(filedataExp.Key(i)).transData.TimeElapsed = expProcData.(filedataExp.Key(i)).transData.TimeStamp_PT1 - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).transData.TimeElapsed.Format = 'hh:mm:ss.SSS';
    end
       
    expProcData.(filedataExp.Key(i)).MFMData = MFM_data((MFM_data.TimeStamp>=filedataExp.st(i))&(MFM_data.TimeStamp<=filedataExp.et(i)),:);
    if isempty(expProcData.(filedataExp.Key(i)).MFMData) == 0
        expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed = expProcData.(filedataExp.Key(i)).MFMData.TimeStamp - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed.Format = 'hh:mm:ss.SSS';
    end

    expProcData.(filedataExp.Key(i)).PGD1Data = PGD1_data((PGD1_data.TimeStamp>=filedataExp.st(i))&(PGD1_data.TimeStamp<=filedataExp.et(i)),:);
    if isempty(expProcData.(filedataExp.Key(i)).PGD1Data) == 0
        expProcData.(filedataExp.Key(i)).PGD1Data.TimeElapsed = expProcData.(filedataExp.Key(i)).PGD1Data.TimeStamp - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).PGD1Data.TimeElapsed.Format = 'hh:mm:ss.SSS';
        expProcData.(filedataExp.Key(i)).PGD1Data.C1 = expProcData.(filedataExp.Key(i)).PGD1Data.H2GasConcentration;
    end

    expProcData.(filedataExp.Key(i)).PGD2Data = PGD2_data((PGD2_data.TimeStamp>=filedataExp.st(i))&(PGD2_data.TimeStamp<=filedataExp.et(i)),:);
    if isempty(expProcData.(filedataExp.Key(i)).PGD1Data) == 0
        expProcData.(filedataExp.Key(i)).PGD2Data.TimeElapsed = expProcData.(filedataExp.Key(i)).PGD2Data.TimeStamp - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).PGD2Data.TimeElapsed.Format = 'hh:mm:ss.SSS';
        expProcData.(filedataExp.Key(i)).PGD2Data.C2 = expProcData.(filedataExp.Key(i)).PGD2Data.CO2GasConcentration;
        expProcData.(filedataExp.Key(i)).PGD2Data.C1 = 100 - expProcData.(filedataExp.Key(i)).PGD2Data.C2;
    end

    A = pi*((filedataExp.D(i)*0.0254)/2)^2; %m2
    L = filedataExp.L(i)*0.0254; % m
    q = filedataExp.Q(i)*(10^(-6))/60; %m3/s
    v = q./A; % Darcy velocity m/s
    u = v./filedataExp.phi(i); % Interstitil velocity

    exp_setup_params = table(A,L,q,v,u,'VariableNames',{'A_SI','L_SI','q_SI','v_SI','u_SI'});
    expProcData.(filedataExp.Key(i)).exp_setup_params = exp_setup_params;

end

load(pathImportCal + "calProcData.mat")
load(pathImportCal + "calResults.mat")
load(pathImportPR + "PR_results.mat")

%% Extract breakthrough curve data

%rho_corr_lin function
rho_corr_lin = @(p,y) (y-p(1))/p(2);

for i = 1:length(filedataExp.Key)
    % Extrat measured density vs time & remove missing
    BTaux = table(expProcData.(filedataExp.Key(i)).MFMData.TimeStamp, ...
        expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed, ...
        seconds(expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed), ...
        expProcData.(filedataExp.Key(i)).MFMData.dens_MFM2, ...
        expProcData.(filedataExp.Key(i)).MFMData.T_MFM2, ...
        expProcData.(filedataExp.Key(i)).MFMData.q_MFM2, ...
        'VariableNames',{'TimeStamp','TimeElapsed', 'SecondsElapsed', 'rho_MFM','T_MFM','q_MFM'});
    expProcData.(filedataExp.Key(i)).BT = rmmissing(BTaux);
    % fitting parameters for rho corrected
    auxLinFit = calProcData.fittingRhoResultsAll(calProcData.fittingRhoResultsAll.model == "HP_lin",:);
    expProcData.(filedataExp.Key(i)).BT.rho_corr_mean = rho_corr_lin([auxLinFit.p1,auxLinFit.p2],expProcData.(filedataExp.Key(i)).BT.rho_MFM);
    expProcData.(filedataExp.Key(i)).BT.rho_corr_min = rho_corr_lin([auxLinFit.p1,auxLinFit.p2],expProcData.(filedataExp.Key(i)).BT.rho_MFM-auxLinFit.RMSE);
    expProcData.(filedataExp.Key(i)).BT.rho_corr_max = rho_corr_lin([auxLinFit.p1,auxLinFit.p2],expProcData.(filedataExp.Key(i)).BT.rho_MFM+auxLinFit.RMSE);
    % look up for correspondent Xi in PR EOS table
    expProcData.(filedataExp.Key(i)).BT.Ci_corr_mean = 100*interp1(PR_results.rho_mix, PR_results.x1, expProcData.(filedataExp.Key(i)).BT.rho_corr_mean, 'linear');
end

%% Propagation of error in Xi


%% Save data

for i = 1:length(filedataExp.Key)
    delete(pathExportAll + filedataExp.Key(i) + '.xlsx')

    writetable(expProcData.(filedataExp.Key(i)).pumpsData,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'pumps_data');
    writetable(expProcData.(filedataExp.Key(i)).transData,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'trans_data');
    writetable(expProcData.(filedataExp.Key(i)).MFMData,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'MFM_data');
    writetable(expProcData.(filedataExp.Key(i)).PGD1Data,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'PGD1_data');
    writetable(expProcData.(filedataExp.Key(i)).PGD2Data,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'PGD2_data');
    writetable(expProcData.(filedataExp.Key(i)).BT,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'BT_curve');
    save(pathExportAll + "expProcData.mat",'expProcData')
end

%% Plots for analysis

% Subplot all in 4 panels
for i = 1:length(filedataExp.Key)
    figure('Position', [100, 100, 600, 900]); % [left, bottom, width, height];
    subplot(5,1,1);
    if isempty(expProcData.(filedataExp.Key(i)).transData) == 0 && ismissing(trans_data_name) == 0
        scatter(expProcData.(filedataExp.Key(i)).transData.TimeElapsed,expProcData.(filedataExp.Key(i)).transData.PT1,10,'filled','DisplayName','PT1')
        hold on
        scatter(expProcData.(filedataExp.Key(i)).transData.TimeElapsed,expProcData.(filedataExp.Key(i)).transData.PT2,10,'filled','DisplayName','PT2')
    end
    % xlabel('Time elapsed [hh:mm:ss]')
    ylabel('Pressure [psig]')
    xtickformat('hh:mm:ss')
    ylim([1450,1550])
    grid("on")
    title(filedataExp.Key(i) + " pore pressure", 'Interpreter', 'none')
    legend('Location','southeast');

    subplot(5,1,2);
    if isempty(expProcData.(filedataExp.Key(i)).pumpsData) == 0 && ismissing(pumps_data_name) == 0
        scatter(expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed,expProcData.(filedataExp.Key(i)).pumpsData.P_P3,10,'filled','DisplayName','Pconf')
    end
    % xlabel('Time elapsed [hh:mm:ss]')
    ylabel('Pressure [psig]')
    xtickformat('hh:mm:ss')
    ylim([1900,2400])
    grid("on")
    title(filedataExp.Key(i) + " confining pressure", 'Interpreter', 'none')
    legend('Location','southeast');

    subplot(5,1,3);
    if isempty(expProcData.(filedataExp.Key(i)).pumpsData) == 0 && ismissing(pumps_data_name) == 0
        scatter(expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed,expProcData.(filedataExp.Key(i)).pumpsData.q_P1,10,'filled','DisplayName','q_{pump}')
        hold on
    end
    if isempty(expProcData.(filedataExp.Key(i)).MFMData) == 0
        scatter(expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed,expProcData.(filedataExp.Key(i)).MFMData.q_MFM2,10,'filled','DisplayName','q_{MFM}')
    end
    xlabel('Time elapsed [hh:mm:ss]')
    xtickformat('hh:mm:ss')
    ylim([-1,15])
    ylabel('Flow rate [ml/min]')
    grid on;
    title(filedataExp.Key(i) + " flow rates", 'Interpreter', 'none')
    legend('Location','southeast');

    subplot(5,1,4);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.rho_corr_mean,10,'filled','MarkerFaceColor','r')
    hold on
    xlabel('Time elapsed [hh:mm:ss]')
    xtickformat('hh:mm:ss')
    ylabel('Corrected Density [kg/m^{3}]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Temperature [°C]');
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.T_MFM,10,'filled', 'MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    legend('density_{MFM}','T_{MFM}', 'Location','southeast');
    title(filedataExp.Key(i) + " density and temperature", 'Interpreter', 'none')
    grid on;

    subplot(5,1,5);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('PGD molar concentration [mol %]');
    if isempty(expProcData.(filedataExp.Key(i)).PGD2Data) == 0 && ismissing(PGD2_data_name) == 0
        scatter(expProcData.(filedataExp.Key(i)).PGD2Data.TimeElapsed,expProcData.(filedataExp.Key(i)).PGD2Data.C1,10,'filled', 'MarkerFaceColor',[0.0000 0.4470 0.7410], 'DisplayName','C1_{PGD2}')
        hold on
    end
    if isempty(expProcData.(filedataExp.Key(i)).PGD1Data) == 0 && ismissing(PGD1_data_name) == 0
        scatter(expProcData.(filedataExp.Key(i)).PGD1Data.TimeElapsed,expProcData.(filedataExp.Key(i)).PGD1Data.C1,10,'filled','MarkerFaceColor', [0.9290 0.6940 0.1250], 'DisplayName','C1_{PGD1}')
        hold on
    end
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.Ci_corr_mean,10,'filled','MarkerFaceColor','r','DisplayName','C1_{MFM}')
    hold on
    xlabel('Time elapsed [hh:mm:ss]')
    xtickformat('hh:mm:ss')
    ylabel('MFM molar concentration [mol %]');
    legend('Location','southeast');
    title(filedataExp.Key(i) + " molar concentrations", 'Interpreter', 'none')
    grid on;

    saveas(gcf,pathExportAll + filedataExp.Key(i) + "_BT_All_Vars",'png')
end
