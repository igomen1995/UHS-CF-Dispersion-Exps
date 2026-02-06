% main_Cal.m
% version: v9_Feb2026
% Author: Ianna Gomez Mendez
%
%
% Objective: 
% Extract data for density calibration of Corilis MFM
% collected during bypass experiments at fix temperature 
% and variable  pressure and fluids
% using 3 Quizix pumps, 2 mass flow meters Bronkhorst, 2 transducers Omega
% and 2 portable gas detectors Cosmos (DOD Technologies)
% 
% Input:
% 1. Exp file:
% - Pumps file (.dat)
% - Transducer file (.csv)
% - Mass Flow Meters (.csv)
% - Gas detectors - could be more than one file (.csv)
% 2. Cal reference file
% 
% Procedure:
% 1 - Take input file 
% 2 - Import files (and prepare time data)
% 3 - Create one file with all raw data and save
% 4 - Inspect data in plot density and temperature vs time
% Come back to input cal exp file to input/correct input st and et (start and end time) of each
% P, T, fluid fixed, also input P and T, and change key
% 5 - Calculate error of density for a given period of time with Temperature and pressure stable
% 6 - Plot density inst vs NIST data
% 
% Output: 
% - Excel (and csv) file with all variables with same time and time elapsed
% - Figures
%
%% INPUT

addpath('functions/');

%Exp data
filenameExp = 'input/input_cal_exp.xlsx';
opts = spreadsheetImportOptions("NumVariables", 16);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Key", "Date", "Fluid1", "T", "P", "Run", "st", "et", "dt", "path", "pumps_data_name", "trans_data_name", "MFM_data_name", "PGD1_data_name", "PGD2_data_name","GMT_PGD"];
opts.VariableTypes = ["string", "string","string", "double", "double", "double", "datetime", "datetime", "double", "string", "string", "string", "string", "string", "string", "string"];
filedataExp = readtable(filenameExp,opts);

filedataExp.st = datetime(filedataExp.st,'Format','MM/dd/uuuu HH:mm:ss');
filedataExp.et = datetime(filedataExp.et,'Format','MM/dd/uuuu HH:mm:ss');

% NIST data
filenameNIST = 'input/input_cal_PR.xlsx';
opts = spreadsheetImportOptions("NumVariables", 7);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid", "Temp", "P_psig", "P_psia", "P_bar", "dens", "Phase"];
opts.VariableTypes = ["string", "double","double", "double", "double", "double", "string"];
filedataNIST = readtable(filenameNIST,opts);

mkdir('results/cal_250725_PR');
pathExportAll = 'results/cal_250725_PR/';

%% Import data

for i = 1:length(filedataExp.Key)
    pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

    if ismissing(pumps_data_name) == 0
        pumps_data = import_pumps_data(pumps_data_name);
        expRawData.(filedataExp.Key(i)).pumpsData = pumps_data;
        expRawData.(filedataExp.Key(i)).pumpsData = pumps_data((pumps_data.TimeStamp>=filedataExp.st(i))&(pumps_data.TimeStamp<=filedataExp.et(i)),:);
    end

    if ismissing(trans_data_name) == 0
        trans_data = import_trans_data(trans_data_name);
        expRawData.(filedataExp.Key(i)).transData = trans_data;
        expRawData.(filedataExp.Key(i)).transData = trans_data((trans_data.TimeStamp_PT1>=filedataExp.st(i))&(trans_data.TimeStamp_PT1<=filedataExp.et(i)),:);
    end

    if ismissing(MFM_data_name) == 0
        MFM_data = import_MFM_data(MFM_data_name);
        expRawData.(filedataExp.Key(i)).MFMData = MFM_data;
        expRawData.(filedataExp.Key(i)).MFMData = MFM_data((MFM_data.TimeStamp>=filedataExp.st(i))&(MFM_data.TimeStamp<=filedataExp.et(i)),:);
    end

    if ismissing(PGD1_data_name) == 0
        PGD1_data = import_PGD1_data(PGD1_data_name);
        expRawData.(filedataExp.Key(i)).PGD1Data = PGD1_data;
        expRawData.(filedataExp.Key(i)).PGD1Data = PGD1_data((PGD1_data.TimeStamp>=filedataExp.st(i))&(PGD1_data.TimeStamp<=filedataExp.et(i)),:);
    end

    if ismissing(PGD2_data_name) == 0
        PGD2_data = import_PGD2_data(PGD2_data_name);
        expRawData.(filedataExp.Key(i)).PGD2Data = PGD2_data;
        expRawData.(filedataExp.Key(i)).PGD2Data = PGD2_data((PGD2_data.TimeStamp>=filedataExp.st(i))&(PGD2_data.TimeStamp<=filedataExp.et(i)),:);
    end

end
%% Save data

aux_idx = find(ismissing(filedataExp.P))';

for i = aux_idx
    pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

    if ismissing(pumps_data_name) == 0
        writetable(expRawData.(filedataExp.Key(i)).pumpsData,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'pumps_data');
    end
    if ismissing(trans_data_name) == 0
        writetable(expRawData.(filedataExp.Key(i)).transData,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'trans_data');
    end
    if ismissing(MFM_data_name) == 0
        writetable(expRawData.(filedataExp.Key(i)).MFMData,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'MFM_data');
    end
    if ismissing(PGD1_data_name) == 0
        writetable(expRawData.(filedataExp.Key(i)).PGD1Data,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'PGD1_data');
    end
    if ismissing(PGD2_data_name) == 0
        writetable(expRawData.(filedataExp.Key(i)).PGD2Data,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'PGD2_data');
    end
    save(pathExportAll + "expRawData.mat",'expRawData')
end

%% Plotting for analysis

% Pressure and flow rates together
for i = 1:length(fields(expRawData))
    f1 = figure; % concentrations and densities
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P1,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    hold on
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P2,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    xlabel('Time MM/dd/uuuu HH:mm');
    ylabel('Pressure (psig)');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Flow rate (ml/min)');
    title(filedataExp.Key(i) + " pressure & flow rates", 'Interpreter', 'none')
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.q_P1,10,'filled','MarkerFaceColor',[0.8500, 0.3250, 0.0980])
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.q_P2,10,'filled','MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    %scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.q_MFM2,10,'filled','MarkerFaceColor','r')
    legend('P_{pump1}','P_{pump2}','q_{pump1}','q_{pump2}','q_{MFM2}', 'Location','southeast');
    grid on;
    saveas(f1,pathExportAll + filedataExp.Key(i) + "_P_Qs",'png')
end

%% Plotting for analysis

%Densities and temperatures
for i = 1:length(fields(expRawData))
    f2 = figure;
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.dens_MFM2,10,'filled','MarkerFaceColor','r')
    xlabel('Time MM/dd/uuuu HH:mm');
    ylabel('Density (kg/m^{3})');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Temperature (°C)');
    title(filedataExp.Key(i) + "density & temperatures", 'Interpreter', 'none')
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.T_MFM2,10,'filled', 'MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    legend('density_{MFM2}','T_{MFM2}', 'Location','southeast');
    grid on;
    saveas(f2,pathExportAll + filedataExp.Key(i) + "_dens_temp",'png')
end

%% Plotting for analysis

% Densities & Pressures
for i = 1:length(fields(expRawData))
    f3 = figure;
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.dens_MFM2,10,'filled','MarkerFaceColor','r')
    hold on
    xlabel('Time MM/dd/uuuu HH:mm');
    ylabel('Density (kg/m^{3})');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Pressure (psig)');
    title(filedataExp.Key(i) + "density & temperatures", 'Interpreter', 'none')
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P1,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P2,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    legend('density_{MFM2}','P_{pump1}','P_{pump2}', 'Location','southeast');
    grid on;
    saveas(f3,pathExportAll + filedataExp.Key(i) + "_dens_press",'png')
end

%% Plotting for analysis
% Subplot all in 4 panels
aux_idx = find(ismissing(filedataExp.P))';
for i = aux_idx
    f4 = figure('Position', [100, 100, 600, 900]); % [left, bottom, width, height];
    subplot(4,1,1);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P1,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    hold on
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P2,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    %xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Pressure [psig]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Flow rate [ml/min]');
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.q_P1,10,'filled','MarkerFaceColor',[0.8500, 0.3250, 0.0980])
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.q_P2,10,'filled','MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.q_MFM2,5,'filled','MarkerFaceColor',[0.4940 0.1840 0.5560])
    legend('P_{pump1}','P_{pump2}','q_{pump1}','q_{pump2}','q_{MFM2}', 'Location','southwest');
    title(filedataExp.Key(i) + " pressure & flow rates", 'Interpreter', 'none')
    grid on;

    subplot(4,1,2);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.dens_MFM2,10,'filled','MarkerFaceColor','r')
    hold on
    %xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Density [kg/m^{3}]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Temperature [°C]');
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.T_MFM2,10,'filled', 'MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    legend('density_{MFM2}','T_{MFM2}', 'Location','southwest');
    title(filedataExp.Key(i) + "density & temperatures", 'Interpreter', 'none')
    grid on;

    subplot(4,1,3);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.dens_MFM2,10,'filled','MarkerFaceColor','r')
    hold on
    %xlabel('Time MM/dd/uuuu HH:mm');
    ylabel('Density [kg/m^{3}]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Pressure [psig]');
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P1,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P2,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    legend('density_{MFM2}','P_{pump1}','P_{pump2}', 'Location','southwest');
    title(filedataExp.Key(i) + " pressure & pressures", 'Interpreter', 'none')
    grid on;

    subplot(4,1,4);
    scatter(expRawData.(filedataExp.Key(i)).PGD1Data.TimeStamp,expRawData.(filedataExp.Key(i)).PGD1Data.H2GasConcentration,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    hold on
    scatter(expRawData.(filedataExp.Key(i)).PGD2Data.TimeStamp,expRawData.(filedataExp.Key(i)).PGD2Data.CO2GasConcentration,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Concentration [%vol]');
    legend('Conc H2 %vol PGD1','Conc CO2 %vol PGD2', 'Location','southwest');
    title(filedataExp.Key(i) + "Concentration PGDs", 'Interpreter', 'none')
    grid on;
    
    saveas(f4,pathExportAll + filedataExp.Key(i) + "_All_PGDs",'png')
end

%% Plotting for analysis
% Subplot all in 3 panels
aux_idx = find(ismissing(filedataExp.P))';
for i = aux_idx
    f5 = figure('Position', [100, 100, 600, 900]); % [left, bottom, width, height];
    subplot(3,1,1);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P1,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    hold on
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P2,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    %xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Pressure (psig)');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Flow rate [ml/min]');
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.q_P1,10,'filled','MarkerFaceColor',[0.8500, 0.3250, 0.0980])
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.q_P2,10,'filled','MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.q_MFM2,5,'filled','MarkerFaceColor',[0.4940 0.1840 0.5560])
    legend('P_{pump1}','P_{pump2}','q_{pump1}','q_{pump2}','q_{MFM2}', 'Location','southwest');
    title(filedataExp.Key(i) + " pressure & flow rates", 'Interpreter', 'none')
    grid on;
    
    subplot(3,1,2);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.dens_MFM2,10,'filled','MarkerFaceColor','r')
    %xlabel('Time (MM/dd/uuuu HH:mm)');
    ylabel('Density [kg/m^{3}]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Temperature [°C]');
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.T_MFM2,10,'filled', 'MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    legend('density_{MFM2}','T_{MFM2}', 'Location','southwest');
    title(filedataExp.Key(i) + "density & temperatures", 'Interpreter', 'none')
    grid on;

    subplot(3,1,3);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.dens_MFM2,10,'filled','MarkerFaceColor','r')
    hold on
    xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Density [kg/m^{3}]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Pressure [psig]');
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P1,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_P2,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    legend('density_{MFM2}','P_{pump1}','P_{pump2}', 'Location','southwest');
    title(filedataExp.Key(i) + "density & pressures", 'Interpreter', 'none')
    grid on;
    
    saveas(f5,pathExportAll + filedataExp.Key(i) + "_All",'png')
end

% After this, manually select st and et to put in input cal file per
% pressure tested per fluid tested (all Qs)

%% Processing data

% P, T and density arrays for a fixed time and fluid

fluids = unique(filedataExp.Fluid1);
P_unique = unique(filedataExp.P);
P_unique = P_unique(~isnan(P_unique));
P_unique_field = "P"+ string(P_unique);
T_unique = unique(filedataExp.T);
T_unique = T_unique(~isnan(T_unique));

aux_idx = find(ismissing(filedataExp.P) == 0)';

mean_vals = table();
std_vals = table();
fluid_NIST_row_vals = table();
cal_results = table();

for i = aux_idx(1):aux_idx(end)
    for j = 1:length(fluids)
        for k = 1:length(P_unique)
            for l = 1:length(T_unique)
                if fluids(j) == filedataExp.Fluid1(i)
                    if P_unique(k) == filedataExp.P(i)
                        if T_unique(l) == filedataExp.T(i)
                            P_P1_aux = expRawData.(filedataExp.Key(i)).pumpsData.P_P1((expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp<=filedataExp.et(i)),:);
                            P_P2_aux = expRawData.(filedataExp.Key(i)).pumpsData.P_P2((expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp<=filedataExp.et(i)),:);
                            calProcData.(fluids(j)).(P_unique_field(k)).P_array = P_P1_aux + P_P2_aux;
                            Q_P1_aux = expRawData.(filedataExp.Key(i)).pumpsData.q_P1((expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp<=filedataExp.et(i)),:);
                            Q_P2_aux = expRawData.(filedataExp.Key(i)).pumpsData.q_P2((expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp<=filedataExp.et(i)),:);
                            calProcData.(fluids(j)).(P_unique_field(k)).Q_array = Q_P1_aux + Q_P2_aux;
                            calProcData.(fluids(j)).(P_unique_field(k)).dens_array = expRawData.(filedataExp.Key(i)).MFMData.dens_MFM2((expRawData.(filedataExp.Key(i)).MFMData.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp<=filedataExp.et(i)),:);
                            calProcData.(fluids(j)).(P_unique_field(k)).T_array = expRawData.(filedataExp.Key(i)).MFMData.T_MFM2((expRawData.(filedataExp.Key(i)).MFMData.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp<=filedataExp.et(i)),:);
                            calProcData.(fluids(j)).(P_unique_field(k)).PGD1_array = expRawData.(filedataExp.Key(i)).PGD1Data.H2GasConcentration((expRawData.(filedataExp.Key(i)).PGD1Data.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).PGD1Data.TimeStamp<=filedataExp.et(i)),:);
                            calProcData.(fluids(j)).(P_unique_field(k)).PGD2_array = expRawData.(filedataExp.Key(i)).PGD2Data.CO2GasConcentration((expRawData.(filedataExp.Key(i)).PGD2Data.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).PGD2Data.TimeStamp<=filedataExp.et(i)),:);
                            % mean
                            P_mean = mean(calProcData.(fluids(j)).(P_unique_field(k)).P_array,'omitnan');
                            Q_mean = mean(calProcData.(fluids(j)).(P_unique_field(k)).Q_array,'omitnan');
                            dens_mean = mean(calProcData.(fluids(j)).(P_unique_field(k)).dens_array,'omitnan');
                            T_mean = mean(calProcData.(fluids(j)).(P_unique_field(k)).T_array,'omitnan');
                            PGD1_mean = mean(calProcData.(fluids(j)).(P_unique_field(k)).PGD1_array,'omitnan');
                            PGD2_mean = mean(calProcData.(fluids(j)).(P_unique_field(k)).PGD2_array,'omitnan');
                            mean_temp = table(P_mean,Q_mean,dens_mean,T_mean,PGD1_mean, PGD2_mean,'VariableNames',{'P_psig_mean','Q_mean','dens_mean','T_mean','C1_PGD1_mean','C2_PGD2_mean'});
                            calProcData.(fluids(j)).(P_unique_field(k)).mean = mean_temp;
                            mean_vals = [mean_vals;mean_temp];
                            % std
                            P_std = std(calProcData.(fluids(j)).(P_unique_field(k)).P_array,'omitnan');
                            Q_std = std(calProcData.(fluids(j)).(P_unique_field(k)).Q_array,'omitnan');
                            dens_std = std(calProcData.(fluids(j)).(P_unique_field(k)).dens_array,'omitnan');
                            T_std = std(calProcData.(fluids(j)).(P_unique_field(k)).T_array,'omitnan');
                            PGD1_std = std(calProcData.(fluids(j)).(P_unique_field(k)).PGD1_array,'omitnan');
                            PGD2_std = std(calProcData.(fluids(j)).(P_unique_field(k)).PGD2_array,'omitnan');
                            std_temp = table(P_std,Q_std,dens_std,T_std,PGD1_std, PGD2_std,'VariableNames',{'P_psig_std','Q_std','dens_std','T_std','C1_PGD1_std','C2_PGD2_std'});
                            calProcData.(fluids(j)).(P_unique_field(k)).std = std_temp;
                            std_vals = [std_vals;std_temp];
                        end
                    end
                end
            end
        end
    end
end


for i = 1:height(filedataNIST)
    for j = 1:length(fluids)
        for k = 1:length(P_unique)
            for l = 1:length(T_unique)
                if fluids(j) == filedataNIST.Fluid(i)
                    if P_unique(k) == filedataNIST.P_psig(i)
                        if T_unique(l) == filedataNIST.Temp(i)
                            fluid_NIST_row_temp = filedataNIST(i,:);
                            fluid_NIST_row_vals = [fluid_NIST_row_vals;fluid_NIST_row_temp];
                        end
                    end
                end
            end
        end
    end
end

cal_results = [fluid_NIST_row_vals,mean_vals,std_vals];
writetable(cal_results,pathExportAll + "calResults.xlsx");
save(pathExportAll + "cal_results.mat",'cal_results')

for j = 1:length(fluids)
    cal_vals.(fluids(j)) = cal_results(cal_results.Fluid == fluids(j),:);
end

%% Calibration curve
aux_idx = find(ismissing(filedataExp.P) == 0)';

for i = aux_idx
    for j = 1:length(fluids)
        if fluids(j) == filedataExp.Fluid1(i)
            dens_cal_vals = table();
            for k = 1:length(P_unique)
                dens_cal_NIST = repmat(cal_vals.(fluids(j)).dens(k),length(calProcData.(fluids(j)).(P_unique_field(k)).dens_array),1);
                P_cal_ref = repmat(cal_vals.(fluids(j)).P_psig(k),length(calProcData.(fluids(j)).(P_unique_field(k)).dens_array),1);
                fluid_cal_ref = repmat(cal_vals.(fluids(j)).Fluid(k),length(calProcData.(fluids(j)).(P_unique_field(k)).dens_array),1);
                dens_cal_MFM = calProcData.(fluids(j)).(P_unique_field(k)).dens_array;
                T_cal_MFM = calProcData.(fluids(j)).(P_unique_field(k)).T_array;
                % take out Nan values
                dens_cal_NIST_clean = dens_cal_NIST(~isnan(dens_cal_MFM));
                P_cal_ref_clean = P_cal_ref(~isnan(dens_cal_MFM));
                fluid_cal_ref_clean = fluid_cal_ref(~isnan(dens_cal_MFM));
                dens_cal_MFM_clean = dens_cal_MFM(~isnan(dens_cal_MFM));
                T_cal_MFM_clean = T_cal_MFM(~isnan(dens_cal_MFM));
                dens_cal_vals_temp = table(dens_cal_NIST_clean,dens_cal_MFM_clean,T_cal_MFM_clean, P_cal_ref_clean,fluid_cal_ref_clean,'VariableNames',{'dens_cal_NIST','dens_cal_MFM','T_cal_MFM','P_cal_ref','Fluid_cal_ref'});
                dens_cal_vals = [dens_cal_vals;dens_cal_vals_temp];
            end
            calProcData.(fluids(j)).dens_cal_all = dens_cal_vals;
        end
    end
end

%% Rho Cal curve

dens_cal_vals_all = table();
for i = 1:length(fluids)
    dens_cal_vals_all = [dens_cal_vals_all;calProcData.(fluids(i)).dens_cal_all];
end

calProcData.dens_cal_vals_all = dens_cal_vals_all;

%functions
lin_function = @(p,x)p(1)+p(2)*x;
pow_function = @(p,x)p(1)+p(2)*(x.^2);
exp_function = @(p,x)p(1)*exp(p(2)*x);
p_init = [0,0];

% choose best model
rho_cal_fit_lin = fitnlm(dens_cal_vals_all(:,1:2),lin_function,p_init); 
rho_cal_fit_pow = fitnlm(dens_cal_vals_all(:,1:2),pow_function,p_init);
rho_cal_fit_exp = fitnlm(dens_cal_vals_all(:,1:2),exp_function,p_init);

% high pressure cal only
% choose best model
dens_cal_vals_HP = dens_cal_vals_all(dens_cal_vals_all.P_cal_ref==1500,:);
rho_cal_HP_fit_lin = fitnlm(dens_cal_vals_HP(:,1:2),lin_function,p_init); 
rho_cal_HP_fit_pow = fitnlm(dens_cal_vals_HP(:,1:2),pow_function,p_init);
rho_cal_HP_fit_exp = fitnlm(dens_cal_vals_HP(:,1:2),exp_function,p_init);

% save fit model params
fittingRhoResultsAll = table('Size',[0 4],'VariableTypes',{'string','double','double','double'},'VariableNames',{'model','p1','p2','RMSE'});
calProcData.rho_cal_fit_lin = rho_cal_fit_lin;
fittingRhoResultsAll(1,:) = {"all_lin",rho_cal_fit_lin.Coefficients.Estimate(1),rho_cal_fit_lin.Coefficients.Estimate(2),rho_cal_fit_lin.RMSE};
calProcData.rho_cal_fit_pow = rho_cal_fit_pow;
fittingRhoResultsAll(2,:) = {"all_pow",rho_cal_fit_pow.Coefficients.Estimate(1),rho_cal_fit_pow.Coefficients.Estimate(2),rho_cal_fit_pow.RMSE};
calProcData.rho_cal_fit_exp = rho_cal_fit_exp;
fittingRhoResultsAll(3,:) = {"all_exp",rho_cal_fit_exp.Coefficients.Estimate(1),rho_cal_fit_exp.Coefficients.Estimate(2),rho_cal_fit_exp.RMSE};
calProcData.rho_cal_HP_fit_lin = rho_cal_HP_fit_lin;
fittingRhoResultsAll(4,:) = {"HP_lin",rho_cal_HP_fit_lin.Coefficients.Estimate(1),rho_cal_HP_fit_lin.Coefficients.Estimate(2),rho_cal_HP_fit_lin.RMSE};
calProcData.rho_cal_HP_fit_pow = rho_cal_HP_fit_pow;
fittingRhoResultsAll(5,:) = {"HP_pow",rho_cal_HP_fit_pow.Coefficients.Estimate(1),rho_cal_HP_fit_pow.Coefficients.Estimate(2),rho_cal_HP_fit_pow.RMSE};
calProcData.rho_cal_HP_fit_exp = rho_cal_HP_fit_exp;
fittingRhoResultsAll(6,:) = {"HP_exp",rho_cal_HP_fit_exp.Coefficients.Estimate(1),rho_cal_HP_fit_exp.Coefficients.Estimate(2),rho_cal_HP_fit_exp.RMSE};

writetable(fittingRhoResultsAll,pathExportAll + "fittingRhoResultsAll.xlsx");
save(pathExportAll + "calProcData.mat",'calProcData')

%rho_corr_lin function
rho_corr_lin = @(p,y) (y-p(1))/p(2);

%% Density cal plot all densitites (all fluids, temperatures and pressures)
figure
set(gcf, 'Position', [100, 100, 700, 550])
scatter(dens_cal_vals_all.dens_cal_NIST,dens_cal_vals_all.dens_cal_MFM,20,dens_cal_vals_all.T_cal_MFM,'filled')
hold on
plot(0:1:800,feval(rho_cal_fit_lin,0:1:800),"Color",'k')
xlabel('\rho_{ref} [kg/m^{3}]');
ylabel('\rho_{MFM} [kg/m^{3}]');
xlim([0 800]);
ylim([0 800]);
xticks(0:100:800)
yticks(0:100:800)
c=colorbar;
c.Title.String = 'Temperature [°C]';
c.Title.Rotation = 90;
c.Title.Units = 'normalized';
c.Title.Position = [3.55, 0.5, 0];
c.Title.FontSize = 14;
cTicks = c.Ticks;
cTicks = cTicks(mod(cTicks,1) == 0);
c.Ticks = cTicks;
grid on
title("Calibration curve - all cal fluids P and T")
saveas(gcf,pathExportAll + "Cal-all",'png')

% save figs, add colours, add mean val and symbol per substance tested
%% All fluids, only high pressure - cal curves
figure
scatter(dens_cal_vals_HP.dens_cal_NIST,dens_cal_vals_HP.dens_cal_MFM,20,dens_cal_vals_HP.T_cal_MFM,'filled')
hold on
plot(0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
xlabel('\rho_{ref} [kg/m^{3}]');
ylabel('\rho_{MFM} [kg/m^{3}]');
xlim([0 800]);
ylim([0 800]);
xticks(0:100:800)
yticks(0:100:800)
c=colorbar;
c.Title.String = 'Temperature [°C]';
c.Title.Rotation = 90;
c.Title.Units = 'normalized';
c.Title.Position = [3.55, 0.5, 0];
c.Title.FontSize = 14;
cTicks = c.Ticks;
cTicks = cTicks(mod(cTicks,1) == 0);
c.Ticks = cTicks;
grid on
title("Calibration curve - all cal fluids and T at HP")
saveas(gcf,pathExportAll + "Cal-all_HP",'png')

%% All fluids, only high pressure, cal curves, zoom in

% three different fluids H2, He, CO2 for paper! High pressure = 1500 psig,
% Tref = 32C

figure;
set(gcf, 'Position', [100, 100, 700, 550])
ax1 = axes;
scatter(dens_cal_vals_HP.dens_cal_NIST,dens_cal_vals_HP.dens_cal_MFM,15,dens_cal_vals_HP.T_cal_MFM,'filled')
hold on
plot(0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
x1 = xlabel('\rho_{ref} [kg/m^{3}]', 'FontSize', 14);
ylabel('\rho_{MFM} [kg/m^{3}]', 'FontSize', 14);
xlim([0 800]);
ylim([0 800]);
xticks(0:100:800)
yticks(0:100:800)
numTicks = 6;
ax1.FontSize = 14;
c=colorbar;
c.Title.String = 'Temperature [°C]';
c.Title.Rotation = 90;
c.Title.Units = 'normalized';
c.Title.Position = [3.55, 0.5, 0];
c.Title.FontSize = 14;
cTicks = c.Ticks;
cTicks = cTicks(mod(cTicks,1) == 0);
c.Ticks = cTicks;
grid on
legend({'Measured density','Calibration curve'},'Location','southeast')
% cal curve formula annotation
coeffs = calProcData.rho_cal_HP_fit_lin.Coefficients.Estimate;
annotText = sprintf('\\rho_{MFM} = %.1f \\cdot \\rho_{NIST} + %.1f', coeffs(2), coeffs(1));
annotation('textbox', [0.2, 0.12, 0.3, 0.1], 'String', annotText, ...
    'Interpreter', 'tex', 'FontSize', 11, 'EdgeColor', 'none');
% H2
insetAx = axes('Position', [0.19 0.70 0.1 0.15]);  % [x y width height]
box(insetAx, 'on');  % Add border to inset
scatter(insetAx,dens_cal_vals_HP.dens_cal_NIST,dens_cal_vals_HP.dens_cal_MFM,15,dens_cal_vals_HP.T_cal_MFM,'filled')
hold on
plot(insetAx,0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
grid on
xlim([4,12])
ylim([17,27])
title('H_2 (32°C, 10.4 MPa)')
% He
insetAx = axes('Position', [0.36 0.70 0.1 0.15]);  % [x y width height]
box(insetAx, 'on');  % Add border to inset
scatter(insetAx,dens_cal_vals_HP.dens_cal_NIST,dens_cal_vals_HP.dens_cal_MFM,15,dens_cal_vals_HP.T_cal_MFM,'filled')
hold on
plot(insetAx,0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
xlim([11,19])
ylim([24,34])
title('He_  (32°C, 10.4 MPa)')
grid on
% CO2
insetAx = axes('Position', [0.19 0.47 0.1 0.15]);  % [x y width height]
box(insetAx, 'on');  % Add border to inset
scatter(insetAx,dens_cal_vals_HP.dens_cal_NIST,dens_cal_vals_HP.dens_cal_MFM,15,dens_cal_vals_HP.T_cal_MFM,'filled')
hold on
plot(insetAx,0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
xlim([696,720])
ylim([748,777])
title('CO_2 (32°C, 10.4 MPa)')
grid on
saveas(gcf,pathExportAll + "Cal-curve-zoom-in",'png')
