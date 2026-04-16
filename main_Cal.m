% main_Cal.m
% Author: Ianna Gomez Mendez
%
% Objective: 
% Extract data for density calibration of Corilis MFM
% collected during bypass experiments at fix temperature 
% and variable  pressure and fluids
% using 3 Quizix pumps, 2 mass flow meters Bronkhorst, 2 transducers Omega
% and 2 portable gas detectors Cosmos (DOD Technologies)
% 
% Input:
% 1. Experiment file:
% - Pumps file (.dat) (mandatory)
% - Transducer file (.csv)
% - Mass Flow Meters (.csv) (mandatory)
% - Gas detectors - could be more than one file (.csv)
% 2. Cal reference file
% 
% Procedure:
% 1 - Take input file 
% 2 - Import files (and prepare time data)
% 3 - Create one file with all raw data and save
% 4 - Inspect data in plot density and temperature vs time
% 5 - Calculate error of density for a given period of time with Temperature and pressure stable
% 6 - Plot density inst vs Ref data
% 
% Output: 
% - Excel (and csv) file with all variables with same time and time elapsed
% - Figures
%
%% INPUT
% INTRODUCE HERE INPUT AND OUTPUT PATH

%Cal Experimental data
filenameExp = 'input/input_cal_exp.xlsx';

% PR parameters
% INTRODUCE THE INPUT HERE
% file containing pure components NIST data: Tc, Pc and acentric factor w
filenamePure = 'input/input_PR_pure.xlsx';
% file containing mixture compoents A12 B12 factor to estimate BIP
filenameBIP = 'input/input_PR_BIP.xlsx';

mkdir('results/cal_250725_PR'); % Create directory for output
pathExportAll = 'results/cal_250725_PR/'; % Path for OUTPUT


%% Import data

addpath('functions/');

filedataExp = import_inputCal(filenameExp); % import input to a local variable

% import pure components NIST data: Tc, Pc and acentric factor w
filedataPure = import_inputPR_params_pure(filenamePure);
% import mixture components A12 and B12 factor to estimate BIP (kij)
filedataBIP = import_inputPR_params_BIP(filenameBIP);

for i = 1:length(filedataExp.Key)

    pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);
    
    workingPump = filedataExp.workingPump(i);
    confPump = 0;
    cushionPump = 0;

    if ismissing(pumps_data_name) == 0 % if pumps data exist (name is stated in input file)
        pumps_data = import_pumps_data(pumps_data_name, workingPump, confPump, cushionPump); % import pumps data to local variable
        expRawData.(filedataExp.Key(i)).pumpsData = pumps_data ...
            ((pumps_data.TimeStamp>=filedataExp.st(i))& ...
            (pumps_data.TimeStamp<=filedataExp.et(i)),:); % import pumps data from st (start time) to et (end time) to struct.Key
    end

    if ismissing(trans_data_name) == 0 % if p transducer data exist (name is stated in input file)
        trans_data = import_trans_data(trans_data_name); % import p transducer data to local variable
        expRawData.(filedataExp.Key(i)).transData = trans_data ...
            ((trans_data.TimeStamp_PT1>=filedataExp.st(i))& ...
            (trans_data.TimeStamp_PT1<=filedataExp.et(i)),:); % import p trans data from st (start time) to et (end time) to struct.Key
    end

    if ismissing(MFM_data_name) == 0 % if MFM exist (name is stated in input file)
        MFM_data = import_MFM_data(MFM_data_name); % import MFM2 data to local variable
        expRawData.(filedataExp.Key(i)).MFMData = MFM_data ...
            ((MFM_data.TimeStamp>=filedataExp.st(i))& ...
            (MFM_data.TimeStamp<=filedataExp.et(i)),:); % import MFM2 data from st (start time) to et (end time) to struct.Key
    end

    if ismissing(PGD1_data_name) == 0 % if PGD1 exist (name is stated in input file)
        PGD1_data = import_PGD1_data(PGD1_data_name); % import PGD1 data to local variable
        if filedataExp.GMT_PGD{i} == "GMT9"
            PGD1_data.TimeStamp = PGD1_data.TimeStamp - hours(13); %ONLY if PGD in Japan time GMT+9    
        end
        expRawData.(filedataExp.Key(i)).PGD1Data = PGD1_data ...
            ((PGD1_data.TimeStamp>=filedataExp.st(i))& ...
            (PGD1_data.TimeStamp<=filedataExp.et(i)),:); % import PGD1 data from st (start time) to et (end time) to struct.Key
    end

    if ismissing(PGD2_data_name) == 0 % if PGD2 exist (name is stated in input file)
        PGD2_data = import_PGD2_data(PGD2_data_name); % import PGD1 data to local variable
        if filedataExp.GMT_PGD{i} == "GMT9"
            PGD2_data.TimeStamp = PGD2_data.TimeStamp - hours(13); %ONLY if PGD in Japan time GMT+9    
        end
        expRawData.(filedataExp.Key(i)).PGD2Data = PGD2_data ...
            ((PGD2_data.TimeStamp>=filedataExp.st(i))& ...
            (PGD2_data.TimeStamp<=filedataExp.et(i)),:); % import PGD2 data from st (start time) to et (end time) to struct.Key
    end

end
%% Save raw data

mat_name = pathExportAll + "expRawData"; % Name used for saving RawData comes from input pathExportAll
delete(mat_name + '.mat'); % Delete previously saved .mat file
save(mat_name + '.mat','expRawData') % Save .mat file

% Save each key in xlsx file
for i = 1:length(filedataExp.Key)

    xlsx_name = pathExportAll + filedataExp.Key(i) +'_Raw'; % Name for each Key for saving RawData comes from input pathExportAll
    delete(xlsx_name + '.xlsx'); % Delete old xlsx before creating it and saving it again
    
    % pumps_data_name & MFM_data_name are MANDATORY to run calibration;
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

    writetable(expRawData.(filedataExp.Key(i)).pumpsData,xlsx_name + '.xlsx', 'Sheet', 'pumps_data'); % save sheet with pumps data
    writetable(expRawData.(filedataExp.Key(i)).MFMData,xlsx_name + '.xlsx', 'Sheet', 'MFM_data'); % save sheet with MFM data
    
    if ismissing(trans_data_name) == 0 % if P trans exists
        writetable(expRawData.(filedataExp.Key(i)).transData,xlsx_name +'.xlsx', 'Sheet', 'trans_data'); % save sheet with P trans data
    end

    if ismissing(PGD1_data_name) == 0 % if PGD1 exists
        writetable(expRawData.(filedataExp.Key(i)).PGD1Data,xlsx_name + '.xlsx', 'Sheet', 'PGD1_data'); % save sheet with PGD1 data
    end
    
    if ismissing(PGD2_data_name) == 0 % if PGD2 exists
        writetable(expRawData.(filedataExp.Key(i)).PGD2Data,xlsx_name + '.xlsx', 'Sheet', 'PGD2_data'); % save sheet with PGD2 data
    end
   
end

%% Trim and ref data

% Clear previous data
clear calProcData;
clear expTrimData;

% Start calResults as an empty table
calResults = table();
calResultsQAll = table();

for i = 1:length(filedataExp.Key)
        
    % names for rest of data types; pumps_data_name & MFM_data name are mandatory
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);
    
    % take pumps and MFM data to local variable in a struct
    pumps_data = expRawData.(filedataExp.Key(i)).pumpsData;
    MFM_data = expRawData.(filedataExp.Key(i)).MFMData;
    
    % Cal experiment references
    P_unique = unique(vertcat(filedataExp.P_psig{i}));
    P_unique_MPa = (P_unique + 14.7)*0.00689476; % P in MPa for PR model
    Q_unique = unique(vertcat(filedataExp.Q_mlmin{i}));

    % P and Q name arrays for struct and plots
    P_unique_field = "P"+ string(P_unique);
    Q_unique_field = "Q"+ string(Q_unique);

    fluid_cal = filedataExp.Fluid1(i); % fluid cal reference
    T_cal = filedataExp.T_C(i); % fluid T cal reference
    T_unique_field = "T" + string(T_cal);

    pumps_data_trim = [];
    MFM_data_trim = [];
    trans_data_trim = [];
    PGD1_data_trim = [];
    PGD2_data_trim = [];

    if ismissing(trans_data_name) == 0
        trans_data = expRawData.(filedataExp.Key(i)).transData; % take trans data to local variable in a struct
    end

    if ismissing(PGD1_data_name) == 0
        PGD1_data = expRawData.(filedataExp.Key(i)).PGD1Data; % take PGD1 data to local variable in a struct
    end

    if ismissing(PGD2_data_name) == 0
        PGD2_data = expRawData.(filedataExp.Key(i)).PGD2Data; % take PGD2 data to local variable in a struct
    end

    for j = 1:length(P_unique) % trimming according to P
        
        % empty data array for each P, that will gather all Qs
        pumps_data_trim_QAll = []; 
        MFM_data_trim_QAll = [];
        trans_data_trim_QAll = [];
        PGD1_data_trim_QAll = [];
        PGD2_data_trim_QAll = [];
        calResults_QAll = table();
        calData_QAll = table ();

        for k = 1:length(Q_unique) % trimming according to Q

            P_tol = 0.05; %relative IMPORTANT parameter to change, changes sensitivity of analysis
            Q_tol = 0.01; %absolute IMPORTANT parameter to change, changes sensitivity of analysis
            
            % Store in local variable st and et to trim according to P and Q
            [TimeStamp_st,TimeStamp_et] = trim_time_P_Q(pumps_data.P_Pworking,P_unique(j),P_tol,pumps_data.TimeStamp,pumps_data.Q_Pworking,Q_unique(k),Q_tol);
            
            pumps_data_aux = [];
            MFM_data_aux = [];
            trans_data_aux = [];
            PGD1_data_aux = [];
            PGD2_data_aux = [];

            if ~isempty(TimeStamp_st) % only runs if trimmed part length is different than zero

                for l = 1:length(TimeStamp_st) % different subparts with same P, Q, T and fluid 
                % if length(TimeStamp_st) = 0, then this for won't start, but not error raised
                    
                    % pumps and MFM are mandatory for calibration
                    % pumps data
                    % Trim according to time st and et
                    pumps_data_trim_aux = pumps_data((pumps_data.TimeStamp>=TimeStamp_st(l))&(pumps_data.TimeStamp<=TimeStamp_et(l)),:);
                    % Add specific subpart to full pumps_data_aux for that P and Q
                    pumps_data_aux = [pumps_data_aux; pumps_data_trim_aux];  % all P and all Q
    
                    % MFM data
                    % Trim according to time st and et
                    MFM_data_trim_aux = MFM_data((MFM_data.TimeStamp>=TimeStamp_st(l))&(MFM_data.TimeStamp<=TimeStamp_et(l)),:);
                    % Add specific subpart to full MFM_data_aux for that P and Q
                    MFM_data_aux = [MFM_data_aux; MFM_data_trim_aux];  % all P and all Q
                    
                    % trans data
                    if ismissing(trans_data_name) == 0 % if trans data exists
                        % Trim according to time st and et
                        trans_data_trim_aux = trans_data((PGD1_data.TimeStamp>=TimeStamp_st(l))&(PGD1_data.TimeStamp<=TimeStamp_et(l)),:);
                        % Add specific subpart to full MFM_data_aux for that P and Q
                        trans_data_aux = [trans_data_aux; trans_data_trim_aux]; % all P and all Q
                    end
    
                    % PGD1 data
                    if ismissing(PGD1_data_name) == 0 % if PGD1 data exists                   
                        PGD1_data_trim_aux = PGD1_data((PGD1_data.TimeStamp>=TimeStamp_st(l))&(PGD1_data.TimeStamp<=TimeStamp_et(l)),:);
                        PGD1_data_aux = [PGD1_data_aux; PGD1_data_trim_aux]; % all P and all Q
                    end
    
                    % PGD2 data
                    if ismissing(PGD2_data_name) == 0 % if PGD2 data exists                    
                        PGD2_data_trim_aux = PGD2_data((PGD2_data.TimeStamp>=TimeStamp_st(l))&(PGD2_data.TimeStamp<=TimeStamp_et(l)),:);
                        PGD2_data_aux = [PGD2_data_aux; PGD2_data_trim_aux]; % all P and all Q
                    end  
    
                end
    
                % xxx_data_trim_QAll is feeded with xxx_data_aux for each fluid, T, P and Q, it is rezeroed every k 
                pumps_data_trim_QAll = [pumps_data_trim_QAll; pumps_data_aux]; % Unique P and all Q
                MFM_data_trim_QAll = [MFM_data_trim_QAll; MFM_data_aux]; % Unique P and all Q
                            
                % calProcData struct is created
                calProcData.(fluid_cal).(T_unique_field). ...
                    (P_unique_field(j)).(Q_unique_field(k)).pumpsData = pumps_data_aux; %pumps data is added. Structure is calProcData.fluid.T.P.Q.pumpsData
                calProcData.(fluid_cal).(T_unique_field). ...
                    (P_unique_field(j)).(Q_unique_field(k)).MFMData = MFM_data_aux; %MFM data is added. Structure is calProcData.fluid.T.P.Q.pumpsData   
    
                % MFM main data arrays for cal data for cal curve, freq and Q MFMF could be added too
                dens_MFM = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.dens_MFM2;
                T_MFM = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.T_MFM2;
                Q_MFM = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.q_MFM2;
    
                % statistics for same P, Q, T and fluid
                    % mean for a specific P and Q
                        % pumps data
                P_mean = mean(pumps_data_aux.P_Pworking);
                Q_mean = mean(pumps_data_aux.Q_Pworking);
                        % MFM data
                T_mean = mean(MFM_data_aux.T_MFM2);
                Q_MFM_mean = mean(MFM_data_aux.q_MFM2);
                dens_mean = mean(MFM_data_aux.dens_MFM2);
                freq_MFM_mean = mean(MFM_data_aux.freq_MFM2);
                    % std for a specific P and Q
                        % pumps data
                P_std = std(pumps_data_aux.P_Pworking);
                Q_std = std(pumps_data_aux.Q_Pworking); 
                        % MFM data      
                T_std = std(MFM_data_aux.T_MFM2);
                Q_MFM_std = std(MFM_data_aux.q_MFM2);
                dens_std = std(MFM_data_aux.dens_MFM2);
                freq_MFM_std = std(MFM_data_aux.freq_MFM2);

                % Reference density from Peng Robinson model  
                    % at T mean values
                [PR_input_T_mean,PR_results_T_mean] = densZ_PR(fluid_cal,1,P_unique_MPa(j),T_mean,filedataPure,filedataBIP);
                [PR_input_T_max,PR_results_T_max] = densZ_PR(fluid_cal,1,P_unique_MPa(j),T_mean+T_std, filedataPure,filedataBIP); % at Tmax
                [PR_input_T_min,PR_results_T_min] = densZ_PR(fluid_cal,1,P_unique_MPa(j),T_mean-T_std, filedataPure,filedataBIP); % at Tmin
                    % Compressibility factor from Peng Robinson T_mean
                Z_PR_T_mean = PR_results_T_mean.Z;
                Z_PR_T_max = PR_results_T_max.Z;
                Z_PR_T_min = PR_results_T_min.Z;
                Z_PR_T_mean_std = abs(Z_PR_T_max-Z_PR_T_min); % error of Z depending on T
                    % density from Peng Robinson at T_mean
                dens_PR_T_mean = PR_results_T_mean.rho;
                dens_PR_T_max = PR_results_T_max.rho;
                dens_PR_T_min = PR_results_T_min.rho;
                dens_PR_T_mean_std = abs(dens_PR_T_max-dens_PR_T_min); % error of dens depending on T
              
                % cal results gathers mean and std
                calResults_temp = table(fluid_cal,T_cal,P_unique(j), Q_unique(k), ...
                    T_mean,T_std, P_mean,P_std, Q_mean,Q_std, Q_MFM_mean,Q_MFM_std, ...
                    dens_mean,dens_std,freq_MFM_mean,freq_MFM_std, ...
                    {TimeStamp_st},{TimeStamp_et}, ...
                    Z_PR_T_mean , Z_PR_T_mean_std, dens_PR_T_mean , dens_PR_T_mean_std, ...
                    'VariableNames',{'Fluid_cal','T_cal_C','P_cal_psig', 'Q_cal_mlmin', ...
                    'T_mean','T_std','P_psig_mean','P_psig_std','Q_mean','Q_std', 'Q_MFM_mean', 'Q_MFM_std', ...
                    'dens_mean','dens_std','freq_MFM_mean','freq_MFM_std', ...
                    'st','et','Z_PR_T_mean','Z_PR_T_mean_std','dens_PR_T_mean','dens_PR_T_mean_std'});
    
                % cal data gathers all punctual data and its mean and cal experiment ref value
                calData_temp = table(repmat(fluid_cal,length(dens_MFM),1), ...
                    repmat(T_cal,length(dens_MFM),1), repmat(P_unique(j),length(dens_MFM),1), ...
                    repmat(Q_unique(k),length(dens_MFM),1), ...
                    Q_MFM,T_MFM, repmat(T_mean,length(dens_MFM),1), repmat(T_std,length(dens_MFM),1), ...
                    dens_MFM, repmat(dens_mean,length(dens_MFM),1), repmat(dens_std,length(dens_MFM),1), ...
                    repmat(Z_PR_T_mean,length(dens_MFM),1), repmat(Z_PR_T_mean_std,length(dens_MFM),1), ...
                    repmat(dens_PR_T_mean,length(dens_MFM),1), repmat(dens_PR_T_mean_std,length(dens_MFM),1), ...
                    'VariableNames',{'Fluid_cal','T_cal_C', 'P_cal_psig', 'Q_cal_mlmin', ...
                    'Q_MFM','T_MFM','T_mean','T_std','dens_MFM','dens_mean','dens_std', ...
                    'Z_PR_T_mean','Z_PR_T_mean_std','dens_PR_T_mean','dens_PR_T_mean_std'});
                
                % calProcData struct collects calResults_temp and calData_temp
                calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).calResults = calResults_temp;
                calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).calData = calData_temp;
    
                % trans data
                if ismissing(trans_data_name) == 0 % if trans data exists
                        % trans_data_trim_QAll from trans_data_aux
                    trans_data_trim_QAll = [trans_data_trim_QAll; trans_data_aux]; % Unique P and all Q
                        % xxx_data_trim is feeded with xxx_data_aux for each fluid, T, P and Q, gathers all
                    trans_data_trim = [trans_data_trim; trans_data_aux];
                        % calProcData struct takes trans_data
                    calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).transData = trans_data_aux;
                        % statistics for same P, Q, T and fluid
                            % mean
                    PT1_mean = mean(trans_data_aux.PT1);
                    PT2_mean = mean(trans_data_aux.PT2);
                            % std
                    PT1_std = std(trans_data_aux.PT1);
                    PT2_std = std(trans_data_aux.PT2);               
                        % variables added to calResults_temp table from trans_data
                    calResults_temp.PT1_mean = PT1_mean;
                    calResults_temp.PT1_std = PT1_std;
                    calResults_temp.PT2_mean = PT2_mean;
                    calResults_temp.PT2_std = PT2_std;                       
                end
    
                % PGD1 data
                if ismissing(PGD1_data_name) == 0 % if PGD1 data exists
                        % PGD1_data_trim_QAll from PGD1_data_aux
                    PGD1_data_trim_QAll = [PGD1_data_trim_QAll; PGD1_data_aux]; % Unique P and all Q
                        % xxx_data_trim is feeded with xxx_data_aux for each fluid, T, P and Q, gathers all
                    PGD1_data_trim = [PGD1_data_trim; PGD1_data_aux];
                        % calProcData struct takes PGD1_data
                    calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).PGD1Data = PGD1_data_aux;
                        % statistics for same P, Q, T and fluid
                            % mean
                    PGD1_mean = mean(PGD1_data_aux.H2GasConcentration);
                            % std
                    PGD1_std = std(PGD1_data_aux.H2GasConcentration);                
                        % variAbles added to calResults_temp table from PGD1_data
                    calResults_temp.PGD1_mean = PGD1_mean;
                    calResults_temp.PGD1_std = PGD1_std;
                end
    
                % PGD2 data 
                if ismissing(PGD2_data_name) == 0 % if PGD2 data exists
                        % PGD1_data_trim_QAll from PGD1_data_aux            
                    PGD2_data_trim_QAll = [PGD2_data_trim_QAll; PGD2_data_aux]; % Unique P and all Q
                        % xxx_data_trim is feeded with xxx_data_aux for each fluid, T, P and Q, gathers all
                    PGD2_data_trim = [PGD2_data_trim; PGD2_data_aux];
                        % calProcData struct takes PGD2_data
                    calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).PGD2Data = PGD2_data_aux;
                        % statistics for same P, Q, T and fluid
                            % mean                
                    PGD2_mean = mean(PGD2_data_aux.CO2GasConcentration);
                            % STD
                    PGD2_std = std(PGD2_data_aux.CO2GasConcentration);
                        % variAbles added to calResults_temp table from PGD2_data
                    calResults_temp.PGD2_mean = PGD2_mean;
                    calResults_temp.PGD2_std = PGD2_std;                
                end
    
                % cal Results and data for each fluid, T, P and Q, it is rezeroed every k 
                calResults_QAll = [calResults_QAll;calResults_temp];
                calData_QAll = [calData_QAll;calData_temp];

            end

        end

        % statistics for same P, Q, T and fluid
        % mean for a specific P and QAll
            % pumps data
        P_mean = mean(pumps_data_trim_QAll.P_Pworking);
        Q_mean = mean(pumps_data_trim_QAll.Q_Pworking);
            % MFM data
        T_mean = mean(MFM_data_trim_QAll.T_MFM2);
        Q_MFM_mean = mean(MFM_data_trim_QAll.q_MFM2);
        dens_mean = mean(MFM_data_trim_QAll.dens_MFM2);
        freq_MFM_mean = mean(MFM_data_trim_QAll.freq_MFM2);
        % std for a specific P and Q
            % pumps data
        P_std = std(pumps_data_trim_QAll.P_Pworking);
        Q_std = std(pumps_data_trim_QAll.Q_Pworking); 
            % MFM data      
        T_std = std(MFM_data_trim_QAll.T_MFM2);
        Q_MFM_std = std(MFM_data_trim_QAll.q_MFM2);
        dens_std = std(MFM_data_trim_QAll.dens_MFM2);
        freq_MFM_std = std(MFM_data_trim_QAll.freq_MFM2);
                       
        % xxx_data_trim is feeded with xxx_data_aux for each fluid, T, P and Q, gathers all
        pumps_data_trim = [pumps_data_trim; pumps_data_trim_QAll];
        MFM_data_trim = [MFM_data_trim; MFM_data_trim_QAll];

        % calProcData struct incorporates QAll
        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.pumpsData = pumps_data_trim_QAll;
        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.MFMData = MFM_data_trim_QAll;

        if ismissing(trans_data_name) == 0 % if trans data exists
            calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.transData = trans_data_trim_QAll;
        end

        if ismissing(PGD1_data_name) == 0 % if PGD1 data exists
            calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.PGD1Data = PGD1_data_trim_QAll;
        end

        if ismissing(PGD2_data_name) == 0 % if PGD2 data exists
            calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.PGD2Data = PGD2_data_trim_QAll;
        end

        % cal results gathers mean and std QAll
        calResultsQAll_temp = table(fluid_cal,T_cal,P_unique(j), "QAll", ...
            T_mean,T_std, P_mean,P_std, Q_mean,Q_std, Q_MFM_mean,Q_MFM_std, ...
            dens_mean,dens_std,freq_MFM_mean,freq_MFM_std, ...
            {TimeStamp_st},{TimeStamp_et}, ...
            'VariableNames',{'Fluid_cal','T_cal_C','P_cal_psig', 'Q_cal_mlmin', ...
            'T_mean','T_std','P_psig_mean','P_psig_std','Q_mean','Q_std', 'Q_MFM_mean', 'Q_MFM_std', ...
            'dens_mean','dens_std','freq_MFM_mean','freq_MFM_std', ...
            'st','et'});
        
        % cal proc data gets calResults and Data for each fluid, T and P, QAll
        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.calResults = calResults_QAll;
        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.calData = calData_QAll;

        % cal Results and data for each fluid, T, P and Q
        calResults = [calResults;calResults_QAll];
        calResultsQAll = [calResultsQAll;calResultsQAll_temp];
        
    end

    % Trim data per key
    expTrimData.(filedataExp.Key(i)).pumpsData = pumps_data_trim;
    expTrimData.(filedataExp.Key(i)).MFMData = MFM_data_trim;
    expTrimData.(filedataExp.Key(i)).transData = trans_data_trim;
    expTrimData.(filedataExp.Key(i)).PGD1Data = PGD1_data_trim;
    expTrimData.(filedataExp.Key(i)).PGD2Data = PGD2_data_trim;

end

%% Peng Robinson for T_MFM and cal data all

% Run for all Q after calData is finished
fluid_unique = fieldnames(calProcData);
calData = table();
calResultsQAll_PR = table();

for i = 1:length(fields(calProcData)) % for each fluid
    T_unique_field = fieldnames(calProcData.(fluid_unique{i}));
    for ii = 1:length(T_unique_field) % for each cal temperature average  
        P_unique_field = fieldnames(calProcData.(fluid_unique{i}).(T_unique_field{ii}));
        for j = 1:length(P_unique_field) % for each P
            x1 = filedataExp.x1(filedataExp.Fluid1 == string(fluid_unique{i}));
            Tmin = floor(min(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.T_MFM)*10)/10;
            Tmax = ceil(max(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.T_MFM)*10)/10;
            T_PR_aux = Tmin:0.1:Tmax;
            P_psig = str2double(P_unique_field{j}(2:end));
            P_MPa = (P_psig + 14.7)*0.00689476;
            Z_PR_T_PR = [];
            dens_PR_T_PR = [];
            for m = 1:length(T_PR_aux)
                [PR_input_T_PR_aux,PR_results_T_PR_aux] = densZ_PR(string(fluid_unique{i}),x1,P_MPa,T_PR_aux(m),filedataPure,filedataBIP);
                % Compressibility factor from Peng Robinson at T_MFM and T_mean
                Z_PR_T_PR_aux = PR_results_T_PR_aux.Z;
                % density from Peng Robinson at T_MFM and T_mean
                dens_PR_T_PR_aux = PR_results_T_PR_aux.rho;        
                % Z and rho arrays for each fluid, P, Q and T
                Z_PR_T_PR = [Z_PR_T_PR;Z_PR_T_PR_aux];
                dens_PR_T_PR = [dens_PR_T_PR;dens_PR_T_PR_aux];
            end
            PTXrho_PR_ref = table(repmat(fluid_unique{i},length(T_PR_aux),1), ...
                repmat(P_psig,length(T_PR_aux),1), T_PR_aux', repmat(x1,length(T_PR_aux),1), ...
                Z_PR_T_PR, dens_PR_T_PR, 'VariableNames',{'Fluid_cal', ...
                'P_cal_psig','T_PR', 'x_PR','Z_PR_T_PR', 'dens_PR_T_PR'});
            calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.PTXrho_PR_ref = PTXrho_PR_ref;
                        calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.dens_PR_T_MFM = ...
                interp1(PTXrho_PR_ref.T_PR, PTXrho_PR_ref.dens_PR_T_PR, ...
                calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.T_MFM, 'linear');
            calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.Z_PR_T_MFM = ...
                interp1(PTXrho_PR_ref.T_PR, PTXrho_PR_ref.Z_PR_T_PR, ...
                calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.T_MFM, 'linear');

            % create table with PR_Results QAll
            Z_PR_T_MFM_mean = mean(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.Z_PR_T_MFM);
            Z_PR_T_MFM_std = std(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.Z_PR_T_MFM);
            dens_PR_T_MFM_mean = mean(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.dens_PR_T_MFM);
            dens_PR_T_MFM_std = std(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.dens_PR_T_MFM);

            calResultsQAll_PR_temp = table(string(fluid_unique{i}),str2double(T_unique_field{ii}(2:end)),str2double(P_unique_field{j}(2:end)), "QAll", ...
                Z_PR_T_MFM_mean,Z_PR_T_MFM_std, dens_PR_T_MFM_mean,dens_PR_T_MFM_std, ...
                'VariableNames',{'Fluid_cal','T_cal_C','P_cal_psig', 'Q_cal_mlmin', ...
                'Z_PR_T_mean','Z_PR_T_mean_std','dens_PR_T_mean','dens_PR_T_mean_std'});

            % create calData with all data for cal curve
            calResultsQAll_PR = [calResultsQAll_PR;calResultsQAll_PR_temp];
            calData = [calData;calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData];
        end
    end
end

calResultsQAll_joint = outerjoin(calResultsQAll, calResultsQAll_PR, 'Keys',{'Fluid_cal', 'T_cal_C','P_cal_psig','Q_cal_mlmin'},'MergeKeys',true);

%% Save trimmed and processed data

% name to save matrices and spreadsheets
expTrimData_name = pathExportAll + "expTrimData";  % Name used for saving TrimData comes from input pathExportAll
calProcData_name = pathExportAll + "calProcData";
calResults_name = pathExportAll + "calResults";
calResultsQAll_name = pathExportAll + "calResultsQAll";
calData_name = pathExportAll + "calData";

% delete previous saved files
delete(expTrimData_name + '.mat');
delete(calProcData_name + '.mat');
delete(calResults_name + '.xlsx');
delete(calResults_name + '.mat');
delete(calResultsQAll_name + '.xlsx');
delete(calResultsQAll_name + '.mat');
delete(calData_name + '.xlsx');
delete(calData_name + '.mat');


for i = 1:length(filedataExp.Key)

    xlsx_name = pathExportAll + filedataExp.Key(i) + '_Trim';
    delete(xlsx_name + '.xlsx');

    % names for rest of data types; pumps_data_name & MFM_data name are mandatory
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

    % save table for each key but trimmed
    writetable(expTrimData.(filedataExp.Key(i)).pumpsData,xlsx_name  + '.xlsx', 'Sheet', 'pumps_data');
    writetable(expTrimData.(filedataExp.Key(i)).MFMData,xlsx_name  + '.xlsx', 'Sheet', 'MFM_data');

        if ismissing(trans_data_name) == 0
            writetable(expTrimData.(filedataExp.Key(i)).transData,xlsx_name +'.xlsx', 'Sheet', 'trans_data');
        end

        if ismissing(PGD1_data_name) == 0
            writetable(expTrimData.(filedataExp.Key(i)).PGD1Data,xlsx_name + '.xlsx', 'Sheet', 'PGD1_data');
        end

        if ismissing(PGD2_data_name) == 0
            writetable(expTrimData.(filedataExp.Key(i)).PGD2Data,xlsx_name + '.xlsx', 'Sheet', 'PGD2_data');
        end

end

save(expTrimData_name + '.mat','expTrimData')
save(calProcData_name + '.mat','calProcData')
save(calResults_name + '.mat','calResults')
save(calResultsQAll_name + '.mat','calResultsQAll_joint')
save(calData_name + '.mat','calData')

% save in excel, with timestamp as string joins
% calResults
calResults_xlsx = calResults;
calResults_xlsx.st = [];
calResults_xlsx.et = [];
for m = 1:height(calResults)
    calResults_xlsx.st(m) = strjoin(string(calResults.st{m}),", ");
    calResults_xlsx.et(m) = strjoin(string(calResults.et{m}),", ");
end
writetable(calResults_xlsx,calResults_name + '.xlsx','Sheet', 'calResults');
writetable(calData,calData_name + '.xlsx','Sheet', 'calData');
% calResultsQAll
calResultsQAll_xlsx = calResultsQAll_joint;
calResultsQAll_xlsx.st = [];
calResultsQAll_xlsx.et = [];
for m = 1:height(calResultsQAll_joint)
    calResultsQAll_xlsx.st(m) = strjoin(string(calResultsQAll_joint.st{m}),", ");
    calResultsQAll_xlsx.et(m) = strjoin(string(calResultsQAll_joint.et{m}),", ");
end
writetable(calResultsQAll_xlsx,calResultsQAll_name + '.xlsx','Sheet', 'calResultsQAll_joint');

%% Plotting for analysis Raw Data
% Subplot all in 4 panels

for i = 1:length(filedataExp.Key)
    figure('Position', [100, 100, 600, 900]); % [left, bottom, width, height];
    subplot(4,1,1);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_Pworking,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    %xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Pressure [psig]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Flow rate [ml/min]');
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.Q_Pworking,10,'filled','MarkerFaceColor',[0.8500, 0.3250, 0.0980])
    hold on
    scatter(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp,expRawData.(filedataExp.Key(i)).MFMData.q_MFM2,5,'filled','MarkerFaceColor',[0.4940 0.1840 0.5560])
    legend('P_{pump}','q_{pump}','q_{MFM}', 'Location','southwest');
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
    legend('density_{MFM}','T_{MFM}', 'Location','southwest');
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
    scatter(expRawData.(filedataExp.Key(i)).pumpsData.TimeStamp,expRawData.(filedataExp.Key(i)).pumpsData.P_Pworking,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    legend('density_{MFM}','P_{pump}', 'Location','southwest');
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
    
    saveas(gcf,pathExportAll + filedataExp.Key(i) + "_All_vars_Raw",'png')
end

%% Plotting for analysis trim Data
% Subplot all in 4 panels
aux_idx = find(cellfun(@length,filedataExp.P_psig)>1)';

for i = aux_idx
    figure('Position', [100, 100, 600, 900]); % [left, bottom, width, height];
    subplot(4,1,1);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expTrimData.(filedataExp.Key(i)).pumpsData.TimeStamp,expTrimData.(filedataExp.Key(i)).pumpsData.P_Pworking,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    %xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Pressure [psig]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Flow rate [ml/min]');
    scatter(expTrimData.(filedataExp.Key(i)).pumpsData.TimeStamp,expTrimData.(filedataExp.Key(i)).pumpsData.Q_Pworking,10,'filled','MarkerFaceColor',[0.8500, 0.3250, 0.0980])
    hold on
    scatter(expTrimData.(filedataExp.Key(i)).MFMData.TimeStamp,expTrimData.(filedataExp.Key(i)).MFMData.q_MFM2,5,'filled','MarkerFaceColor',[0.4940 0.1840 0.5560])
    legend('P_{pump}','q_{pump}','q_{MFM}', 'Location','southwest');
    title(filedataExp.Key(i) + " pressure & flow rates", 'Interpreter', 'none')
    grid on;

    subplot(4,1,2);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expTrimData.(filedataExp.Key(i)).MFMData.TimeStamp,expTrimData.(filedataExp.Key(i)).MFMData.dens_MFM2,10,'filled','MarkerFaceColor','r')
    hold on
    %xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Density [kg/m^{3}]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Temperature [°C]');
    scatter(expTrimData.(filedataExp.Key(i)).MFMData.TimeStamp,expTrimData.(filedataExp.Key(i)).MFMData.T_MFM2,10,'filled', 'MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    legend('density_{MFM}','T_{MFM}', 'Location','southwest');
    title(filedataExp.Key(i) + "density & temperatures", 'Interpreter', 'none')
    grid on;

    subplot(4,1,3);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    scatter(expTrimData.(filedataExp.Key(i)).MFMData.TimeStamp,expTrimData.(filedataExp.Key(i)).MFMData.dens_MFM2,10,'filled','MarkerFaceColor','r')
    hold on
    %xlabel('Time MM/dd/uuuu HH:mm');
    ylabel('Density [kg/m^{3}]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Pressure [psig]');
    scatter(expTrimData.(filedataExp.Key(i)).pumpsData.TimeStamp,expTrimData.(filedataExp.Key(i)).pumpsData.P_Pworking,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    legend('density_{MFM}','P_{pump}', 'Location','southwest');
    title(filedataExp.Key(i) + " pressure & pressures", 'Interpreter', 'none')
    grid on;

    subplot(4,1,4);
    scatter(expTrimData.(filedataExp.Key(i)).PGD1Data.TimeStamp,expTrimData.(filedataExp.Key(i)).PGD1Data.H2GasConcentration,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    hold on
    scatter(expTrimData.(filedataExp.Key(i)).PGD2Data.TimeStamp,expTrimData.(filedataExp.Key(i)).PGD2Data.CO2GasConcentration,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Concentration [%vol]');
    legend('Conc H2 %vol PGD1','Conc CO2 %vol PGD2', 'Location','southwest');
    title(filedataExp.Key(i) + "Concentration PGDs", 'Interpreter', 'none')
    grid on;
    
    saveas(gcf,pathExportAll + filedataExp.Key(i) + "_All_vars_Trim",'png')
end

%% Calibration curve

% % Linear fitting Q all considering punctual rho at T_MFM and high pressures
% 
% Q_unique = unique(vertcat(filedataExp.Q_mlmin{:}));
% Q_unique_field = "Q"+ string(Q_unique);
% cal_curve_params = {};
% cal_curve_params_Qeach = {};
% fittingRhoResultsAll = table('Size',[0 4],'VariableTypes', ...
%     {'string','double','double','double'},'VariableNames',{'Q','p1','p2','RMSE'});
% % fitting for each Q
% % take only High Pressure Data
% calData_aux = calData(calData.P_cal_psig > 1000,:);
% for k = 1:length(Q_unique)
%     cal_curve_params_Qeach_aux = fitlm ...
%         (calData_aux.dens_PR_T_MFM(calData_aux.Q_cal_mlmin == Q_unique(k)), ...
%         calData_aux.dens_MFM(calData_aux.Q_cal_mlmin == Q_unique(k)));
%     % Add Fitting Qeach to table fittingRhoResultsAll
%     cal_curve_params_Qeach{end+1} = cal_curve_params_Qeach_aux;
%     fittingRhoResultsAll(k,:) = {Q_unique_field{k}, ...
%         cal_curve_params_Qeach_aux.Coefficients.Estimate(1), ...
%         cal_curve_params_Qeach_aux.Coefficients.Estimate(2), ...
%         cal_curve_params_Qeach_aux.RMSE};
% end
% % Fitting for all Qs
% cal_curve_params_Qall = fitlm(calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM);
% % Add Fitting QAll to table fittingRhoResultsAll
% cal_curve_params = {cal_curve_params_Qeach;cal_curve_params_Qall};
% fittingRhoResultsAll(length(Q_unique)+1,:) = {"QAll", ...
%         cal_curve_params_Qall.Coefficients.Estimate(1), ...
%         cal_curve_params_Qall.Coefficients.Estimate(2), ...
%         cal_curve_params_Qall.RMSE};
% 
% % save fittingRhoResultsAll
% writetable(fittingRhoResultsAll,pathExportAll + "fittingRhoResultsAll.xlsx");
% save(pathExportAll + "cal_curve_params.mat",'cal_curve_params');
% save(pathExportAll + "fittingRhoResultsAll.mat",'fittingRhoResultsAll')

%% Calibration curve

% Non linear fitting Q all considering punctual rho at T_MFM and high pressures
rho_MFM = @(p,rho_ref)(p(1) + p(2)*rho_ref + p(3)*max(0,rho_ref-p(4))); % two linear trams
pinit = [1,1,1,10];
Q_unique = unique(vertcat(filedataExp.Q_mlmin{:}));
Q_unique_field = "Q"+ string(Q_unique);
nl_cal_curve_params_Qeach = {};
nlfittingRhoResultsAll = table('Size',[0 11],'VariableTypes', ...
    {'string','double','double','double','double','double','double','double','double','double','double'}, ...
    'VariableNames',{'Q','p1','p2','p3','p4','m','n2','RMSE','rho_MFM_0','drho_corr_low','drho_corr_high'});

% fitting for each Q
% take only High Pressure Data
calData_aux = calData(calData.P_cal_psig > 400,:);
for k = 1:length(Q_unique)
    cal_curve_params_Qeach_aux = fitnlm ...
        (calData_aux.dens_PR_T_MFM(calData_aux.Q_cal_mlmin == Q_unique(k)), ...
        calData_aux.dens_MFM(calData_aux.Q_cal_mlmin == Q_unique(k)),rho_MFM,pinit);
    % Add Fitting Qeach to table fittingRhoResultsAll
    nl_cal_curve_params_Qeach{end+1} = cal_curve_params_Qeach_aux;
    nlfittingRhoResultsAll(k,:) = {Q_unique_field{k}, ...
        cal_curve_params_Qeach_aux.Coefficients.Estimate(1), ...
        cal_curve_params_Qeach_aux.Coefficients.Estimate(2), ...
        cal_curve_params_Qeach_aux.Coefficients.Estimate(3), ...
        cal_curve_params_Qeach_aux.Coefficients.Estimate(4), ...
        cal_curve_params_Qeach_aux.Coefficients.Estimate(3) + cal_curve_params_Qeach_aux.Coefficients.Estimate(2), ...
        -1*(cal_curve_params_Qeach_aux.Coefficients.Estimate(3))* cal_curve_params_Qeach_aux.Coefficients.Estimate(4)+cal_curve_params_Qeach_aux.Coefficients.Estimate(1),...
        cal_curve_params_Qeach_aux.RMSE, ...
        cal_curve_params_Qeach_aux.feval(cal_curve_params_Qeach_aux.Coefficients.Estimate(4)), ...
        ((1/(cal_curve_params_Qeach_aux.Coefficients.Estimate(2)))*(cal_curve_params_Qeach_aux.RMSE^2))^(1/2), ((1/(cal_curve_params_Qeach_aux.Coefficients.Estimate(2)+cal_curve_params_Qeach_aux.Coefficients.Estimate(3)))*(cal_curve_params_Qeach_aux.RMSE^2))^(1/2)};
end
% Fitting for all Qs
nl_cal_curve_params_Qall = fitnlm(calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,rho_MFM,pinit);
% Add Fitting QAll to table fittingRhoResultsAll
nl_cal_curve_params = {nl_cal_curve_params_Qeach;nl_cal_curve_params_Qall};
nlfittingRhoResultsAll(length(Q_unique)+1,:) = {"QAll", ...
        nl_cal_curve_params_Qall.Coefficients.Estimate(1), ...
        nl_cal_curve_params_Qall.Coefficients.Estimate(2), ...
        nl_cal_curve_params_Qall.Coefficients.Estimate(3), ...
        nl_cal_curve_params_Qall.Coefficients.Estimate(4), ...
        nl_cal_curve_params_Qall.Coefficients.Estimate(3) + nl_cal_curve_params_Qall.Coefficients.Estimate(2), ...
        -1*(nl_cal_curve_params_Qall.Coefficients.Estimate(3))* nl_cal_curve_params_Qall.Coefficients.Estimate(4)+nl_cal_curve_params_Qall.Coefficients.Estimate(1),...
        nl_cal_curve_params_Qall.RMSE, ...
        nl_cal_curve_params_Qall.feval(nl_cal_curve_params_Qall.Coefficients.Estimate(4)), ...
        ((1/(nl_cal_curve_params_Qall.Coefficients.Estimate(2)))*(nl_cal_curve_params_Qall.RMSE^2))^(1/2), ((1/(nl_cal_curve_params_Qall.Coefficients.Estimate(2)+nl_cal_curve_params_Qall.Coefficients.Estimate(3)))*(nl_cal_curve_params_Qall.RMSE^2))^(1/2)};

% save no linear fittingRhoResultsAll
writetable(nlfittingRhoResultsAll,pathExportAll + "nlfittingRhoResultsAll.xlsx");
save(pathExportAll + "nl_cal_curve_params.mat",'nl_cal_curve_params');
save(pathExportAll + "nlfittingRhoResultsAll.mat",'nlfittingRhoResultsAll')

% %% Calibration curve
% 
% rho_ref_0 = nlfittingRhoResultsAll.p4(nlfittingRhoResultsAll.Q == "QAll");
% rho_MFM_0 = predict(nl_cal_curve_params_Qall,rho_ref_0);
% 
% % Non linear fitting Q effect considering punctual rho at T_MFM and high pressures
% rho_MFM_low_dens = @(p,data)(rho_MFM_0 + (data(:,2).^p(1)).*p(2).*(data(:,1)-rho_ref_0)); % two linear trams
% pinit = [1,1];
% Q_unique = unique(vertcat(filedataExp.Q_mlmin{:}));
% Q_unique_field = "Q"+ string(Q_unique);
% nlQfittingRhoResultsAll = table('Size',[0 9],'VariableTypes', ...
%     {'string','double','double','double','double','double','double','double','double'},'VariableNames',{'Q','p1','p2','p3','p4','p5','m','n2','RMSE'});
% % fitting for each Q
% % take only High Pressure Data
% calData_aux = calData(calData.P_cal_psig > 400,:);
% calData_aux = calData_aux(calData_aux.dens_MFM < rho_MFM_0,:);
% % Fitting for all Qs
% nl_Q_cal_curve_params_Qall = fitnlm([calData_aux.dens_PR_T_MFM,calData_aux.Q_cal_mlmin],calData_aux.dens_MFM,rho_MFM_low_dens,pinit);
% % Add Fitting QAll to table fittingRhoResultsAll
% nl_Q_cal_curve_params = nl_Q_cal_curve_params_Qall;
% 
% for k = 1:length(Q_unique)
%     % Add Fitting Qeach to table fittingRhoResultsAll
%     nlQfittingRhoResultsAll(k,:) = {Q_unique_field{k}, ...
%         rho_MFM_0 - rho_ref_0*(Q_unique(k)^nl_Q_cal_curve_params_Qall.Coefficients.Estimate(1))*nl_Q_cal_curve_params_Qall.Coefficients.Estimate(2), ...
%         (Q_unique(k)^nl_Q_cal_curve_params_Qall.Coefficients.Estimate(1))*nl_Q_cal_curve_params_Qall.Coefficients.Estimate(2), ...
%         NaN, ...
%         NaN, ...
%         NaN,...
%         NaN,...
%         NaN, ...
%         nl_Q_cal_curve_params_Qall.RMSE};
% end
% 
% nlQfittingRhoResultsAll(length(Q_unique)+1,:) = {"QAll-Lrho", ...
%         NaN,...
%         nl_Q_cal_curve_params_Qall.Coefficients.Estimate(2), ...
%         NaN,...
%         NaN,...
%         nl_Q_cal_curve_params_Qall.Coefficients.Estimate(1), ...
%         NaN,...
%         NaN,...
%         nl_Q_cal_curve_params_Qall.RMSE};
% 
% nlQfittingRhoResultsAll(length(Q_unique)+2,:) = {"QAll-Hrho", ...
%         nl_cal_curve_params_Qall.Coefficients.Estimate(1), ...
%         nl_cal_curve_params_Qall.Coefficients.Estimate(2), ...
%         nl_cal_curve_params_Qall.Coefficients.Estimate(3), ...
%         nl_cal_curve_params_Qall.Coefficients.Estimate(4), ...
%         NaN,...
%         nl_cal_curve_params_Qall.Coefficients.Estimate(3) + nl_cal_curve_params_Qall.Coefficients.Estimate(2), ...
%         -1*(nl_cal_curve_params_Qall.Coefficients.Estimate(3))* nl_cal_curve_params_Qall.Coefficients.Estimate(4)++nl_cal_curve_params_Qall.Coefficients.Estimate(1),...
%         nl_cal_curve_params_Qall.RMSE};
% 
% %save no linear fittingRhoResultsAll
% writetable(nlQfittingRhoResultsAll,pathExportAll + "nlQfittingRhoResultsAll.xlsx");
% save(pathExportAll + "nl_Q_cal_curve_params.mat",'nl_Q_cal_curve_params');
% save(pathExportAll + "nlQfittingRhoResultsAll.mat",'nlQfittingRhoResultsAll')
% 
% % % Non linear fitting Q effect considering punctual rho at T_MFM and high pressures
% % rho_MFM = @(p,data)(p(1)*data(:,2).^p(5) + p(2).*data(:,1) + p(3).*max(0,data(:,1)-p(4))); % two linear trams
% % pinit = [1,1,1,10,0];
% % Q_unique = unique(vertcat(filedataExp.Q_mlmin{:}));
% % Q_unique_field = "Q"+ string(Q_unique);
% % nlQfittingRhoResultsAll = table('Size',[0 9],'VariableTypes', ...
% %     {'string','double','double','double','double','double','double','double','double'},'VariableNames',{'Q','p1','p2','p3','p4','p5','nlCoef','n2','RMSE'});
% % % fitting for each Q
% % % take only High Pressure Data
% % calData_aux = calData(calData.P_cal_psig > 400,:);
% % % Fitting for all Qs
% % nl_Q_cal_curve_params_Qall = fitnlm([calData_aux.dens_PR_T_MFM,calData_aux.Q_cal_mlmin],calData_aux.dens_MFM,rho_MFM,pinit);
% % % Add Fitting QAll to table fittingRhoResultsAll
% % nl_Q_cal_curve_params = nl_Q_cal_curve_params_Qall;
% % nlQfittingRhoResultsAll(length(Q_unique)+1,:) = {"QAll", ...
% %         nl_Q_cal_curve_params_Qall.Coefficients.Estimate(1), ...
% %         nl_Q_cal_curve_params_Qall.Coefficients.Estimate(2), ...
% %         nl_Q_cal_curve_params_Qall.Coefficients.Estimate(3), ...
% %         nl_Q_cal_curve_params_Qall.Coefficients.Estimate(4), ...
% %         nl_Q_cal_curve_params_Qall.Coefficients.Estimate(5), ...
% %         nl_Q_cal_curve_params_Qall.Coefficients.Estimate(3) + nl_Q_cal_curve_params_Qall.Coefficients.Estimate(2), ...
% %         -1*(nl_Q_cal_curve_params_Qall.Coefficients.Estimate(3))* nl_Q_cal_curve_params_Qall.Coefficients.Estimate(4),...
% %         nl_Q_cal_curve_params_Qall.RMSE};
% % 
% % % save no linear fittingRhoResultsAll
% % writetable(nlQfittingRhoResultsAll,pathExportAll + "nlQfittingRhoResultsAll.xlsx");
% % save(pathExportAll + "nl_Q_cal_curve_params.mat",'nl_Q_cal_curve_params');
% % save(pathExportAll + "nlQfittingRhoResultsAll.mat",'nlQfittingRhoResultsAll')

%% Density cal plot all densitites (all fluids, temperatures and pressures)
% non linear
calData_aux = calData(calData.P_cal_psig > 400,:);
figure;
set(gcf, 'Position', [100, 100, 700, 550])
ax1 = axes;
rho_ref_0 = nlfittingRhoResultsAll.p4(nlfittingRhoResultsAll.Q == "QAll");
drho_corr_low = nlfittingRhoResultsAll.drho_corr_low(nlfittingRhoResultsAll.Q == "QAll");
drho_corr_high = nlfittingRhoResultsAll.drho_corr_high(nlfittingRhoResultsAll.Q == "QAll");
step = 1;
%error bar low dens
errorbar(0:step:rho_ref_0,feval(nl_cal_curve_params_Qall,0:step:rho_ref_0),drho_corr_low,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
hold on 
errorbar(rho_ref_0:step:800,feval(nl_cal_curve_params_Qall,rho_ref_0:step:800),drho_corr_high,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
scatter(calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,20,calData_aux.T_MFM,'filled')
plot(0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k','LineWidth',0.8) % fitting responds to high pressure only
x1 = xlabel('\rho_{ref} [kg/m^{3}]', 'FontSize', 14);
ylabel('\rho_{MFM} [kg/m^{3}]', 'FontSize', 14);
xlim([0 800]);
ylim([0 800]);
xticks(0:100:800)
yticks(0:100:800)
numTicks = 6;
ax1.FontSize = 14;
c=colorbar;
c.Title.String = 'T_{MFM} [°C]';
c.Title.Rotation = 90;
c.Title.Units = 'normalized';
c.Title.Position = [4, 0.5, 0];
c.Title.FontSize = 14;
cTicks = c.Ticks;
cTicks = cTicks(mod(cTicks,1) == 0);
c.Ticks = cTicks;
grid on
legend({'\rho_{MFM}','\rho_{MFM_{fit}} \pm \Delta\rho_{MFM_{fit}}'},'Location','southeast')
% cal curve formula annotation
coeffs = nlfittingRhoResultsAll(nlfittingRhoResultsAll.Q == 'QAll',:);
% annotText = sprintf(['$\\rho_{MFM_{fit}} = \\left\\{ \\begin{array}{ll}',...
%     '%.2f + %.3f\\rho_{Ref}, & \\rho_{Ref} \\le %.2f \\\\',...
%     '%.2f + %.3f\\rho_{Ref}, & \\rho_{Ref} > %.2f',...
%     '\\end{array} \\right.$'], coeffs.p1, coeffs.p2, coeffs.p4, coeffs.n2, coeffs.p3, coeffs.p4);
% annotation('textbox', [0.33, 0.27, 0.3, 0.1], 'String', annotText, ...
%     'Interpreter', 'latex', 'FontSize', 11, 'EdgeColor', 'none');
% title("Calibration curve - all cal fluids P and T - linear and non linear")
saveas(gcf,pathExportAll + "Cal-all-HP400+-nl",'png')

% %% Density cal plot all densitites (all fluids, temperatures and pressures)
% % linear
% calData_aux = calData(calData.P_cal_psig > 400,:);
% 
% figure
% set(gcf, 'Position', [100, 100, 700, 550])
% scatter(calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,20,calData_aux.T_MFM,'filled','DisplayName','Measured density')
% hold on
% plot(0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k','DisplayName','Linear calibration curve') % fitting responds to high pressure only
% xlabel('\rho_{ref} [kg/m^{3}]');
% ylabel('\rho_{MFM} [kg/m^{3}]');
% xlim([0 800]);
% ylim([0 800]);
% xticks(0:100:800)
% yticks(0:100:800)
% c=colorbar;
% c.Title.String = 'Temperature [°C]';
% c.Title.Rotation = 90;
% c.Title.Units = 'normalized';
% c.Title.Position = [3.55, 0.5, 0];
% c.Title.FontSize = 14;
% cTicks = c.Ticks;
% cTicks = cTicks(mod(cTicks,1) == 0);
% c.Ticks = cTicks;
% legend('Location','southeast');
% grid on
% title("Calibration curve - all cal fluids P and T")
% saveas(gcf,pathExportAll + "Cal-all",'png')
% 
% % %% All fluids, only high pressure - cal curves
% % % take only High Pressure Data
% % calData_aux = calData(calData.P_cal_psig > 1000,:);
% % 
% % figure
% % set(gcf, 'Position', [100, 100, 700, 550])
% % scatter(calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,20,calData_aux.T_MFM,'filled')
% % hold on
% % plot(0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k') % fitting responds to high pressure only
% % xlabel('\rho_{ref} [kg/m^{3}]');
% % ylabel('\rho_{MFM} [kg/m^{3}]');
% % xlim([0 800]);
% % ylim([0 800]);
% % xticks(0:100:800)
% % yticks(0:100:800)
% % c=colorbar;
% % c.Title.String = 'Temperature [°C]';
% % c.Title.Rotation = 90;
% % c.Title.Units = 'normalized';
% % c.Title.Position = [3.55, 0.5, 0];
% % c.Title.FontSize = 14;
% % cTicks = c.Ticks;
% % cTicks = cTicks(mod(cTicks,1) == 0);
% % c.Ticks = cTicks;
% % grid on
% % title("Calibration curve - all cal fluids and T at HP")
% % saveas(gcf,pathExportAll + "Cal-all_HP",'png')

% %% All fluids, only high pressure, cal curves, zoom in
% 
% % three different fluids H2, He, CO2 for paper! High pressure = 1500 psig, Tref = 32C
% calData_aux = calData(calData.P_cal_psig > 1000,:);
% 
% figure;
% set(gcf, 'Position', [100, 100, 700, 550])
% ax1 = axes;
% scatter(calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,20,calData_aux.T_MFM,'filled')
% hold on
% plot(0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k') % fitting responds to high pressure only
% x1 = xlabel('\rho_{ref} [kg/m^{3}]', 'FontSize', 14);
% ylabel('\rho_{MFM} [kg/m^{3}]', 'FontSize', 14);
% xlim([0 800]);
% ylim([0 800]);
% xticks(0:100:800)
% yticks(0:100:800)
% numTicks = 6;
% ax1.FontSize = 14;
% c=colorbar;
% c.Title.String = 'Temperature [°C]';
% c.Title.Rotation = 90;
% c.Title.Units = 'normalized';
% c.Title.Position = [3.55, 0.5, 0];
% c.Title.FontSize = 14;
% cTicks = c.Ticks;
% cTicks = cTicks(mod(cTicks,1) == 0);
% c.Ticks = cTicks;
% title("    Coriolis density calibration curve")
% grid on
% legend({'Measured density','Calibration curve'},'Location','southeast')
% % cal curve formula annotation
% coeffs = cal_curve_params_Qall.Coefficients.Estimate;
% annotText = sprintf('\\rho_{MFM} = %.2f \\cdot \\rho_{Ref} + %.2f', coeffs(2), coeffs(1));
% annotation('textbox', [0.2, 0.12, 0.3, 0.1], 'String', annotText, ...
%     'Interpreter', 'tex', 'FontSize', 11, 'EdgeColor', 'none');
% % H2
% insetAx = axes('Position', [0.19 0.72 0.1 0.15]);  % [x y width height]
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,15,calData_aux.T_MFM,'filled')
% hold on
% plot(insetAx,0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k')
% xlim([4,12])
% ylim([17,27])
% xlabel('\rho_{H_2} (T_{MFM}, 10.4 MPa)')
% grid on
% % He
% insetAx = axes('Position', [0.37 0.72 0.1 0.15]);  % [x y width height]
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,15,calData_aux.T_MFM,'filled')
% hold on
% plot(insetAx,0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k')
% xlim([12,20])
% ylim([24,34])
% xlabel('\rho_{He} (T_{MFM}, 10.4 MPa)')
% grid on
% % CO2
% insetAx = axes('Position', [0.19 0.47 0.1 0.15]);  % [x y width height]
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,15,calData_aux.T_MFM,'filled')
% hold on
% plot(insetAx,0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k')
% xlim([692,716])
% ylim([754,783])
% xlabel('\rho_{CO_2} (T_{MFM}, 10.4 MPa)')
% grid on
% saveas(gcf,pathExportAll + "Cal-curve-zoom-in",'png')

%% All fluids, highest pressures, non linear zoom in

% three different fluids H2, He, CO2 for paper! High pressure = 1500 psig, Tref = 32C
calData_aux = calData(calData.P_cal_psig > 400,:);

figure;
set(gcf, 'Position', [100, 100, 700, 550])
ax1 = axes;
rho_ref_0 = nlfittingRhoResultsAll.p4(nlfittingRhoResultsAll.Q == "QAll");
drho_corr_low = nlfittingRhoResultsAll.drho_corr_low(nlfittingRhoResultsAll.Q == "QAll");
drho_corr_high = nlfittingRhoResultsAll.drho_corr_high(nlfittingRhoResultsAll.Q == "QAll");
step = 1;
%error bar low dens
errorbar(0:step:rho_ref_0,feval(nl_cal_curve_params_Qall,0:step:rho_ref_0),drho_corr_low,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
hold on 
errorbar(rho_ref_0:step:800,feval(nl_cal_curve_params_Qall,rho_ref_0:step:800),drho_corr_high,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
scatter(calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,20,calData_aux.T_MFM,'filled')
plot(0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k','LineWidth',0.8) % fitting responds to high pressure only
x1 = xlabel('\rho_{ref} [kg/m^{3}]', 'FontSize', 16);
ylabel('\rho_{MFM} [kg/m^{3}]', 'FontSize', 16);
xlim([0 800]);
ylim([0 800]);
xticks(0:100:800)
yticks(0:100:800)
numTicks = 6;
ax1.FontSize = 16;
c=colorbar;
c.Title.String = 'T_{MFM} [°C]';
c.Title.Rotation = 90;
c.Title.Units = 'normalized';
c.Title.Position = [4, 0.5, 0];
c.Title.FontSize = 16;
cTicks = c.Ticks;
cTicks = cTicks(mod(cTicks,1) == 0);
c.Ticks = cTicks;
grid on
legend({'\rho_{MFM}','\rho_{MFM_{fit}} \pm \Delta\rho_{MFM_{fit}}'},'Location','southeast')
% % cal curve formula annotation
% coeffs = nlfittingRhoResultsAll(nlfittingRhoResultsAll.Q == 'QAll',:);
% annotText = sprintf(['$\\rho_{MFM} = \\left\\{ \\begin{array}{ll}',...
%     '%.2f + %.3f\\rho_{Ref}, & \\rho_{Ref} \\le %.2f \\\\',...
%     '%.2f + %.3f\\rho_{Ref}, & \\rho_{Ref} > %.2f',...
%     '\\end{array} \\right.$'], coeffs.p1, coeffs.p2, coeffs.p4, coeffs.n2, coeffs.p3, coeffs.p4);
% annotation('textbox', [0.34, 0.25, 0.3, 0.1], 'String', annotText, ...
%     'Interpreter', 'latex', 'FontSize', 11, 'EdgeColor', 'none');
% H2
insetAx = axes('Position', [0.19 0.68 0.1 0.17]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'H2'),calData_aux.dens_MFM(calData_aux.Fluid_cal == 'H2'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'H2'),'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xlim([0,10])
ylim([9.5,9.5+range(insetAx.XLim)/limScale])
title({ 'H_2 @ T_{MFM}', ...
        'P = 3.5, 6.3, 10.4 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on
% He
insetAx = axes('Position', [0.35 0.68 0.1 0.17]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'He'),calData_aux.dens_MFM(calData_aux.Fluid_cal == 'He'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'He'),'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xlim([3,19])
ylim([12.5,12.5+range(insetAx.XLim)/limScale])
title({ 'He @ T_{MFM}', ...
        'P = 3.5, 6.3, 10.4 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on
% CO2
insetAx = axes('Position', [0.19 0.42 0.1 0.17]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'CO2'),calData_aux.dens_MFM(calData_aux.Fluid_cal == 'CO2'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2'),'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xlim([75,80])
ylim([83,83+range(insetAx.XLim)/limScale])
title({ 'CO_2 @ T_{MFM}', ...
        'P = 3.5 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on
% CO2
insetAx = axes('Position', [0.54 0.42 0.1 0.17]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'CO2'),calData_aux.dens_MFM(calData_aux.Fluid_cal == 'CO2'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2'),'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xlim([184,204])
ylim([182,182+range(insetAx.XLim)/limScale])
title({ 'CO_2 @ T_{MFM}', ...
        'P = 6.3 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on
% CO2
insetAx = axes('Position', [0.68 0.42 0.1 0.17]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'CO2'),calData_aux.dens_MFM(calData_aux.Fluid_cal == 'CO2'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2'),'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xlim([692,716])
ylim([750,750+range(insetAx.XLim)/limScale])
title({ 'CO_2 @ T_{MFM}', ...
        'P = 10.4 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on
saveas(gcf,pathExportAll + "Cal-curve-nonlin-zoom-in",'png')

% %% All fluids, highest pressures, Q effect, non linear zoom in
% 
% % three different fluids H2, He, CO2 for paper! High pressure = 1500 psig, Tref = 32C
% calData_aux = calData(calData.P_cal_psig > 400,:);
% Q_unique = [1,5];
% Q_symbol_line = {'--',':'};
% 
% figure;
% set(gcf, 'Position', [100, 100, 700, 550])
% ax1 = axes;
% scatter(calData_aux.dens_PR_T_MFM,calData_aux.dens_MFM,20,calData_aux.T_MFM,'filled','DisplayName','Measured density')
% hold on
% for k = 1:length(Q_unique)
%     leg = sprintf('Cal. curve Low \\rho, Q = %.0f ml/min', Q_unique(k));
%     plot(0:1:round(rho_ref_0),feval(nl_Q_cal_curve_params_Qall,[(0:1:round(rho_ref_0))',repmat(Q_unique(k),length(0:1:round(rho_ref_0)),1)]),'DisplayName',leg,'LineStyle',Q_symbol_line{k},"Color",'k') % fitting responds to high pressure only
%     hold on
% end
% leg = sprintf('Cal. curve High \\rho');
% plot(round(rho_ref_0):1:800,feval(nl_cal_curve_params_Qall,round(rho_ref_0):1:800),"Color",'k','LineWidth',0.8,'DisplayName',leg) % fitting responds to high pressure only
% x1 = xlabel('\rho_{ref} [kg/m^{3}]', 'FontSize', 14);
% ylabel('\rho_{MFM} [kg/m^{3}]', 'FontSize', 14);
% xlim([0 800]);
% ylim([0 800]);
% xticks(0:100:800)
% yticks(0:100:800)
% ax1.FontSize = 14;
% c=colorbar;
% c.Title.String = 'Temperature [°C]';
% c.Title.Rotation = 90;
% c.Title.Units = 'normalized';
% c.Title.Position = [3.55, 0.5, 0];
% c.Title.FontSize = 14;
% cTicks = c.Ticks;
% cTicks = cTicks(mod(cTicks,1) == 0);
% c.Ticks = cTicks;
% title("    Coriolis density calibration curve")
% grid on
% legend('Location',[0.48, 0.26, 0.3, 0.1],'Interpreter', 'tex','FontSize',10)
% % cal curve formula annotation
% coeffs = nlfittingRhoResultsAll(nlfittingRhoResultsAll.Q == 'QAll',:);
% coeffs2 = nlQfittingRhoResultsAll(nlQfittingRhoResultsAll.Q == 'QAll-Lrho',:);
% annotText = sprintf(['$\\rho_{MFM} = \\left\\{ \\begin{array}{ll}',...
%     ' %.2f + %.3fQ^{%.2f}(\\rho_{Ref}-%.2f), & \\rho_{Ref} \\le %.2f \\\\',...
%     '%.2f + %.3f(\\rho_{Ref}-%.2f), & \\rho_{Ref} > %.2f',...
%     '\\end{array} \\right.$'], rho_MFM_0, coeffs2.p2, coeffs2.p5, rho_ref_0, coeffs.p4, rho_MFM_0, coeffs.m, coeffs.p4, rho_ref_0);
% annotation('textbox', [0.2, 0.12, 0.3, 0.1], 'String', annotText, ...
%     'Interpreter', 'latex', 'FontSize', 11, 'EdgeColor', 'none');
% % H2
% insetAx = axes('Position', [0.19 0.68 0.1 0.17]);  % [x y width height]
% limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'H2'), ...
%     calData_aux.dens_MFM(calData_aux.Fluid_cal == 'H2'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'H2'),'filled')
% hold on
% for k = 1:length(Q_unique)
%     plot(0:1:round(rho_ref_0),feval(nl_Q_cal_curve_params_Qall,[(0:1:round(rho_ref_0))',repmat(Q_unique(k),length(0:1:round(rho_ref_0)),1)]),'DisplayName',leg,'LineStyle',Q_symbol_line{k},"Color",'k') % fitting responds to high pressure only
%     hold on
% end
% xlim([0,10])
% ylim([9.5,9.5+range(insetAx.XLim)/limScale])
% title({ 'H_2 @ T_{MFM}', ...
%         'P = 3.5, 6.3, 10.4 MPa' }, ...
%       'Interpreter','tex', 'FontSize',7);
% grid on
% % He
% insetAx = axes('Position', [0.35 0.68 0.1 0.17]);  % [x y width height]
% limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'He'),calData_aux.dens_MFM(calData_aux.Fluid_cal == 'He'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'He'),'filled')
% hold on
% for k = 1:length(Q_unique)
%     plot(0:1:round(rho_ref_0),feval(nl_Q_cal_curve_params_Qall,[(0:1:round(rho_ref_0))',repmat(Q_unique(k),length(0:1:round(rho_ref_0)),1)]),'DisplayName',leg,'LineStyle',Q_symbol_line{k},"Color",'k') % fitting responds to high pressure only
%     hold on
% end
% xlim([3,19])
% ylim([12.5,12.5+range(insetAx.XLim)/limScale])
% title({ 'He @ T_{MFM}', ...
%         'P = 3.5, 6.3, 10.4 MPa' }, ...
%       'Interpreter','tex', 'FontSize',7);
% grid on
% % CO2
% insetAx = axes('Position', [0.19 0.42 0.1 0.17]);  % [x y width height]
% limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'CO2'),calData_aux.dens_MFM(calData_aux.Fluid_cal == 'CO2'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2'),'filled')
% hold on
% for k = 1:length(Q_unique)
%     plot(0:1:round(rho_ref_0),feval(nl_Q_cal_curve_params_Qall,[(0:1:round(rho_ref_0))',repmat(Q_unique(k),length(0:1:round(rho_ref_0)),1)]),'DisplayName',leg,'LineStyle',Q_symbol_line{k},"Color",'k') % fitting responds to high pressure only
%     hold on
% end
% xlim([75,80])
% ylim([83,83+range(insetAx.XLim)/limScale])
% title({ 'CO_2 @ T_{MFM}', ...
%         'P = 3.5 MPa' }, ...
%       'Interpreter','tex', 'FontSize',7);
% grid on
% % CO2
% insetAx = axes('Position', [0.54 0.42 0.1 0.17]);  % [x y width height]
% limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'CO2'),calData_aux.dens_MFM(calData_aux.Fluid_cal == 'CO2'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2'),'filled')
% hold on
% plot(0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
% xlim([184,204])
% ylim([182,182+range(insetAx.XLim)/limScale])
% title({ 'CO_2 @ T_{MFM}', ...
%         'P = 6.3 MPa' }, ...
%       'Interpreter','tex', 'FontSize',7);
% grid on
% % CO2
% insetAx = axes('Position', [0.68 0.42 0.1 0.17]);  % [x y width height]
% limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,calData_aux.dens_PR_T_MFM(calData_aux.Fluid_cal == 'CO2'),calData_aux.dens_MFM(calData_aux.Fluid_cal == 'CO2'),15,calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2'),'filled')
% hold on
% plot(0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
% xlim([692,716])
% ylim([750,750+range(insetAx.XLim)/limScale])
% title({ 'CO_2 @ T_{MFM}', ...
%         'P = 10.4 MPa' }, ...
%       'Interpreter','tex', 'FontSize',7);
% grid on
% saveas(gcf,pathExportAll + "Cal-Q-curve-nonlin-zoom-in",'png')
