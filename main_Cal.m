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
% 1. Exp file:
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
% Come back to input cal exp file to input/correct input st and et (start and end time) of each
% P, T, fluid fixed, also input P and T, and change key
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

% % Reference data
% filenameRef = 'input/input_cal_PR.xlsx';

mkdir('results/cal_250725_PR'); % Create directory for output
pathExportAll = 'results/cal_250725_PR/'; % Path for OUTPUT

%% Import data

addpath('functions/');
filedataExp = import_inputCal(filenameExp); % import input to a local variable
% filedataRef = import_inputRef(filenameRef);

for i = 1:length(filedataExp.Key)
    pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

    if ismissing(pumps_data_name) == 0 % if pumps data exist (name is stated in input file)
        pumps_data = import_pumps_data(pumps_data_name); % import pumps data to local variable
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
        expRawData.(filedataExp.Key(i)).PGD1Data = PGD1_data ...
            ((PGD1_data.TimeStamp>=filedataExp.st(i))& ...
            (PGD1_data.TimeStamp<=filedataExp.et(i)),:); % import PGD1 data from st (start time) to et (end time) to struct.Key
    end

    if ismissing(PGD2_data_name) == 0 % if PGD2 exist (name is stated in input file)
        PGD2_data = import_PGD2_data(PGD2_data_name); % import PGD1 data to local variable
        expRawData.(filedataExp.Key(i)).PGD2Data = PGD2_data ...
            ((PGD2_data.TimeStamp>=filedataExp.st(i))& ...
            (PGD2_data.TimeStamp<=filedataExp.et(i)),:); % import PGD2 data from st (start time) to et (end time) to struct.Key
    end

end
%% Save raw data

aux_idx = find(cellfun(@length,filedataExp.P_psig)>1)';

mat_name = pathExportAll + "expRawData";
delete(mat_name + '.mat');

for i = aux_idx

    xlsx_name = pathExportAll + filedataExp.Key(i) +'_Raw';
    delete(xlsx_name + '.xlsx');
    
    % pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);    
    % MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

    writetable(expRawData.(filedataExp.Key(i)).pumpsData,xlsx_name + '.xlsx', 'Sheet', 'pumps_data');
    writetable(expRawData.(filedataExp.Key(i)).MFMData,xlsx_name + '.xlsx', 'Sheet', 'MFM_data');
    
    if ismissing(trans_data_name) == 0
        writetable(expRawData.(filedataExp.Key(i)).transData,xlsx_name +'.xlsx', 'Sheet', 'trans_data');
    end

    if ismissing(PGD1_data_name) == 0
        writetable(expRawData.(filedataExp.Key(i)).PGD1Data,xlsx_name + '.xlsx', 'Sheet', 'PGD1_data');
    end
    
    if ismissing(PGD2_data_name) == 0
        writetable(expRawData.(filedataExp.Key(i)).PGD2Data,xlsx_name + '.xlsx', 'Sheet', 'PGD2_data');
    end
   
end

save(mat_name + '.mat','expRawData')

%% Trim data & save

% In a same cal exp run, there are variable P and Q and a "fixed"
% approaximate Temperature, though this temperature can vary within a range
% according to Q

aux_idx = find(cellfun(@length,filedataExp.P_psig)>1)';

P_unique = unique(vertcat(filedataExp.P_psig{aux_idx}));
Q_unique = unique(vertcat(filedataExp.Q_mlmin{aux_idx}));
P_unique_field = "P"+ string(P_unique);
Q_unique_field = "Q"+ string(Q_unique);

clear calProcData;
clear expTrimData;
calResults = table();
calResultsQAll = table();
calData = table();

expTrimData_name = pathExportAll + "expTrimData";
delete(expTrimData_name + '.mat');

for i = aux_idx

    xlsx_name = pathExportAll + filedataExp.Key(i) + '_Trim';
    delete(xlsx_name + '.xlsx');
    
    fluid_cal = filedataExp.Fluid1(i);
    T_cal = filedataExp.T_C(i);
    % dT_cal = 4; % to trim array when T is meaningful automatically, it will take out values when T has not reached th right conditions
    T_unique_field = "T" + string(T_cal);
        
    % pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);    
    % MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

    pumps_data = expRawData.(filedataExp.Key(i)).pumpsData;
    MFM_data = expRawData.(filedataExp.Key(i)).MFMData;

    pumps_data_trim = [];
    MFM_data_trim = [];

    if ismissing(trans_data_name) == 0
        trans_data = expRawData.(filedataExp.Key(i)).transData;
        trans_data_trim = [];
    end

    if ismissing(PGD1_data_name) == 0
        PGD1_data = expRawData.(filedataExp.Key(i)).PGD1Data;
        PGD1_data_trim = [];
    end

    if ismissing(PGD2_data_name) == 0
        PGD2_data = expRawData.(filedataExp.Key(i)).PGD2Data;
        PGD2_data_trim = [];
    end

    for j = 1:length(P_unique)

        pumps_data_trim_Punique_QAll = [];
        MFM_data_trim_Punique_QAll = [];
        trans_data_trim_Punique_QAll = [];
        PGD1_data_trim_Punique_QAll = [];
        PGD2_data_trim_Punique_QAll = [];

        for k = 1:length(Q_unique)

            P_P1_aux = pumps_data.P_P1;
            P_P2_aux = pumps_data.P_P2;
            P_total = P_P1_aux + P_P2_aux; % if only one pumps is used while recording
            P_tol = 0.05; %relative
            Q_P1_aux = pumps_data.q_P1;
            Q_P2_aux = pumps_data.q_P2;
            Q_total = Q_P1_aux + Q_P2_aux; % if only one pumps is used while recording
            Q_tol = 0.01; %absolute

            idx_P_Q = (abs(P_total - P_unique(j))/(P_unique(j)+14.7)<P_tol)&(abs(Q_total - Q_unique(k))<Q_tol);

            if any(idx_P_Q ~= 0)

                idx_P_Q_aux1 = [0;idx_P_Q(1:end-1)];
                idx_P_Q_aux2 = [idx_P_Q(2:end);0;];
                idx_diff1 = idx_P_Q - idx_P_Q_aux1;
                idx_diff2 = idx_P_Q - idx_P_Q_aux2;

                % pumps data
                pumps_data_aux = pumps_data(idx_P_Q,:);
                pumps_data_aux.P12 = P_total(idx_P_Q);
                pumps_data_aux.Q12 = Q_total(idx_P_Q);
                P_mean = mean(pumps_data_aux.P12);
                Q_mean = mean(pumps_data_aux.Q12);
                P_std = std(pumps_data_aux.P12);
                Q_std = std(pumps_data_aux.Q12);           
                pumps_data_trim = [pumps_data_trim; pumps_data_aux]; % all P and all Q
                pumps_data_trim_Punique_QAll = [pumps_data_trim_Punique_QAll; pumps_data_aux]; % Unique P and all Q
                calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).pumpsData = pumps_data_aux;
                expTrimData.(filedataExp.Key(i)).pumpsData = pumps_data_trim;

                % find time stap to trim
                TimeStamp_aux = pumps_data.TimeStamp;
                idx_st = find(idx_diff1 == 1);
                idx_et = find(idx_diff2 == 1);
                TimeStamp_st = TimeStamp_aux(idx_st);
                TimeStamp_et = TimeStamp_aux(idx_et);

                MFM_data_aux = [];
                trans_data_aux = [];
                PGD1_data_aux = [];
                PGD2_data_aux = [];

                for l = 1:length(idx_st) % different subparts with same P, Q, T and fluid

                    % MFM data
                    MFM_data_trim_aux = MFM_data((MFM_data.TimeStamp>=TimeStamp_st(l))&(MFM_data.TimeStamp<=TimeStamp_et(l)),:);
                    % MFM_data_trim_aux = MFM_data_trim_aux((MFM_data_trim_aux.T_MFM2>=T_cal-dT_cal),:);
                    MFM_data_aux = [MFM_data_aux; MFM_data_trim_aux];  % all P and all Q
                    MFM_data_trim_Punique_QAll = [MFM_data_trim_Punique_QAll; MFM_data_aux]; % Unique P and all Q

                    % trans data
                    if ismissing(trans_data_name) == 0
                        trans_data_trim_aux = trans_data((PGD1_data.TimeStamp>=TimeStamp_st(l))&(PGD1_data.TimeStamp<=TimeStamp_et(l)),:);
                        trans_data_aux = [trans_data_aux; trans_data_trim_aux]; % all P and all Q
                        trans_data_trim_Punique_QAll = [trans_data_trim_Punique_QAll; trans_data_aux]; % Unique P and all Q
                    end

                    % PGD1 data
                    if ismissing(PGD1_data_name) == 0                    
                        PGD1_data_trim_aux = PGD1_data((PGD1_data.TimeStamp>=TimeStamp_st(l))&(PGD1_data.TimeStamp<=TimeStamp_et(l)),:);
                        PGD1_data_aux = [PGD1_data_aux; PGD1_data_trim_aux]; % all P and all Q
                        PGD1_data_trim_Punique_QAll = [PGD1_data_trim_Punique_QAll; PGD1_data_aux]; % Unique P and all Q
                    end

                    % PGD2 data
                    if ismissing(PGD2_data_name) == 0                    
                        PGD2_data_trim_aux = PGD2_data((PGD2_data.TimeStamp>=TimeStamp_st(l))&(PGD2_data.TimeStamp<=TimeStamp_et(l)),:);
                        PGD2_data_aux = [PGD2_data_aux; PGD2_data_trim_aux]; % all P and all Q
                        PGD2_data_trim_Punique_QAll = [PGD2_data_trim_Punique_QAll; PGD2_data_aux]; % Unique P and all Q
                    end  

                end
                    
                % statistics for same P, Q, T and fluid
                dens_mean = mean(MFM_data_aux.dens_MFM2);
                T_mean = mean(MFM_data_aux.T_MFM2);
                Q_MFM_mean = mean(MFM_data_aux.q_MFM2);
                freq_MFM_mean = mean(MFM_data_aux.freq_MFM2);
                dens_std = std(MFM_data_aux.dens_MFM2);
                T_std = std(MFM_data_aux.T_MFM2);
                Q_MFM_std = std(MFM_data_aux.q_MFM2);
                freq_MFM_std = std(MFM_data_aux.freq_MFM2);

                MFM_data_trim = [MFM_data_trim; MFM_data_aux];
                calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData = MFM_data_aux;
                expTrimData.(filedataExp.Key(i)).MFMData = MFM_data_trim;

                % cal results main
                calResults_temp = table(fluid_cal,T_cal,P_mean,P_std,Q_mean,Q_std, ...
                dens_mean,dens_std, T_mean,T_std,Q_MFM_mean,Q_MFM_std,freq_MFM_mean,freq_MFM_std, ...
                {TimeStamp_st},{TimeStamp_et},'VariableNames',{'Fluid','T_C','P_psig_mean','P_psig_std','Q_mean','Q_std', ...
                'dens_mean','dens_std','T_mean','T_std','Q_MFM_mean', 'Q_MFM_std', ...
                'freq_MFM_mean','freq_MFM_std','st','et'});

                dens_array = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.dens_MFM2;
                T_array = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.T_MFM2;
                % freq and Q MFMF could be added too
                calData_temp = table(repmat(fluid_cal,length(dens_array),1),dens_array, repmat(dens_mean,length(dens_array),1), ...
                    T_array, repmat(T_mean,length(dens_array),1),repmat(P_mean,length(dens_array),1), repmat(Q_mean,length(dens_array),1),...
                    'VariableNames',{'fluid_cal','dens_MFM','dens_mean','T_MFM','T_mean','Ppsig_mean','Q_mean'});
                calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).calData = calData_temp;
                calData = [calData;calData_temp];

                % trans data
                if ismissing(trans_data_name) == 0
                    PT1_mean = mean(trans_data_aux.PT1);
                    PT2_mean = mean(trans_data_aux.PT2);
                    PT1_std = std(trans_data_aux.PT1);
                    PT2_std = std(trans_data_aux.PT2);
                    trans_data_trim = [trans_data_trim; trans_data_aux];
                    calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).transData = trans_data_aux;
                    expTrimData.(filedataExp.Key(i)).transData = trans_data_trim;
                    calResults_temp.PT1_mean = PT1_mean;
                    calResults_temp.PT1_std = PT1_std;
                    calResults_temp.PT2_mean = PT2_mean;
                    calResults_temp.PT2_std = PT2_std;                       
                end

                % PGD1 data
                if ismissing(PGD1_data_name) == 0
                    PGD1_mean = mean(PGD1_data_aux.H2GasConcentration);
                    PGD1_std = std(PGD1_data_aux.H2GasConcentration);
                    PGD1_data_trim = [PGD1_data_trim; PGD1_data_aux];
                    calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).PGD1Data = PGD1_data_aux;
                    expTrimData.(filedataExp.Key(i)).PGD1Data = PGD1_data_trim;
                    calResults_temp.PGD1_mean = PGD1_mean;
                    calResults_temp.PGD1_std = PGD1_std;
                end

                % PGD2 data
                if ismissing(PGD2_data_name) == 0
                    PGD2_mean = mean(PGD2_data_aux.CO2GasConcentration);
                    PGD2_std = std(PGD2_data_aux.CO2GasConcentration);
                    PGD2_data_trim = [PGD2_data_trim; PGD2_data_aux];
                    calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).PGD2Data = PGD2_data_aux;
                    expTrimData.(filedataExp.Key(i)).PGD2Data = PGD2_data_trim;
                    calResults_temp.PGD2_mean = PGD2_mean;
                    calResults_temp.PGD2_std = PGD2_std;                
                end
                
                calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).calResults = calResults_temp;
                calResults = [calResults;calResults_temp];

            end

        end

        % block for all Q
        P_mean = mean(pumps_data_trim_Punique_QAll.P12);
        Q_mean = mean(pumps_data_trim_Punique_QAll.Q12);
        P_std = std(pumps_data_trim_Punique_QAll.P12);
        Q_std = std(pumps_data_trim_Punique_QAll.Q12);  
        dens_mean = mean(MFM_data_trim_Punique_QAll.dens_MFM2);
        T_mean = mean(MFM_data_trim_Punique_QAll.T_MFM2);
        Q_MFM_mean = mean(MFM_data_trim_Punique_QAll.q_MFM2);
        freq_MFM_mean = mean(MFM_data_trim_Punique_QAll.freq_MFM2);
        dens_std = std(MFM_data_trim_Punique_QAll.dens_MFM2);
        T_std = std(MFM_data_trim_Punique_QAll.T_MFM2);
        Q_MFM_std = std(MFM_data_trim_Punique_QAll.q_MFM2);
        freq_MFM_std = std(MFM_data_trim_Punique_QAll.freq_MFM2);

        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.pumpsData = pumps_data_trim_Punique_QAll;
        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.MFMData = MFM_data_trim_Punique_QAll;

        % cal results main Q all
        calResultsQAll_temp = table(fluid_cal,T_cal,P_mean,P_std,Q_mean,Q_std, ...
        dens_mean,dens_std, T_mean,T_std,Q_MFM_mean,Q_MFM_std,freq_MFM_mean,freq_MFM_std, ...
        NaN,NaN,'VariableNames',{'Fluid','T_C','P_psig_mean','P_psig_std','Q_mean','Q_std', ...
        'dens_mean','dens_std','T_mean','T_std','Q_MFM_mean', 'Q_MFM_std', ...
        'freq_MFM_mean','freq_MFM_std','st','et'});

        if ismissing(trans_data_name) == 0
            PT1_mean = mean(trans_data_trim_Punique_QAll.PT1);
            PT2_mean = mean(trans_data_trim_Punique_QAll.PT2);
            PT1_std = std(trans_data_trim_Punique_QAll.PT1);
            PT2_std = std(trans_data_trim_Punique_QAll.PT2);

            calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.transData = trans_data_trim_Punique_QAll;

            calResultsQAll_temp.PT1_mean = PT1_mean;
            calResultsQAll_temp.PT1_std = PT1_std;
            calResultsQAll_temp.PT2_mean = PT2_mean;
            calResultsQAll_temp.PT2_std = PT2_std; 
        end

        if ismissing(PGD1_data_name) == 0
            PGD1_mean = mean(PGD1_data_trim_Punique_QAll.H2GasConcentration);
            PGD1_std = std(PGD1_data_trim_Punique_QAll.H2GasConcentration);

            calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.PGD1Data = PGD1_data_trim_Punique_QAll;

            calResultsQAll_temp.PGD1_mean = PGD1_mean;
            calResultsQAll_temp.PGD1_std = PGD1_std;
        end

        if ismissing(PGD2_data_name) == 0
            PGD2_mean = mean(PGD2_data_trim_Punique_QAll.CO2GasConcentration);
            PGD2_std = std(PGD2_data_trim_Punique_QAll.CO2GasConcentration);

            calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.PGD2Data = PGD2_data_trim_Punique_QAll;

            calResultsQAll_temp.PGD2_mean = PGD2_mean;
            calResultsQAll_temp.PGD2_std = PGD2_std;
        end
        
        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.calResults = calResultsQAll_temp;
        calResultsQAll = [calResultsQAll;calResultsQAll_temp];
        
    end
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

%% Take reference from PR model
% instead of taking reference from input, estimate rho from PR and mean T
% and P (mean T and ref P, since BPR is not continupusly measured)

aux_idx = find(cellfun(@length,filedataExp.P_psig)>1)';

P_unique = unique(vertcat(filedataExp.P_psig{aux_idx}));
Q_unique = unique(vertcat(filedataExp.Q_mlmin{aux_idx}));
P_unique_field = "P"+ string(P_unique);
Q_unique_field = "Q"+ string(Q_unique);

calResults_name = pathExportAll + "calResults";
calResultsQAll_name = pathExportAll + "calResultsQAll";
calData_name = pathExportAll + "calData";
calProcData_name = pathExportAll + "calProcData";

delete(calResults_name + '.xlsx');
delete(calResults_name + '.mat');
delete(calResultsQAll_name + '.mat');
delete(calData_name + '.xlsx');
delete(calData_name + '.mat');
delete(calProcData_name + '.mat');

for i = aux_idx

    xlsx_name = pathExportAll + filedataExp.Key(i) + '_Trim';
    delete(xlsx_name + '.xlsx');

    T_cal = filedataExp.T_C(i);
    % dT_cal = 4; % to trim array when T is meaningful automatically, it will take out values when T has not reached th right conditions
    T_unique_field = "T" + string(T_cal);
        
    % pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);    
    % MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

    pumps_data = expRawData.(filedataExp.Key(i)).pumpsData;
    MFM_data = expRawData.(filedataExp.Key(i)).MFMData;

    pumps_data_trim = [];
    MFM_data_trim = [];

    if ismissing(trans_data_name) == 0
        trans_data = expRawData.(filedataExp.Key(i)).transData;
        trans_data_trim = [];
    end

    if ismissing(PGD1_data_name) == 0
        PGD1_data = expRawData.(filedataExp.Key(i)).PGD1Data;
        PGD1_data_trim = [];
    end

    if ismissing(PGD2_data_name) == 0
        PGD2_data = expRawData.(filedataExp.Key(i)).PGD2Data;
        PGD2_data_trim = [];
    end

    for j = 1:length(P_unique)

        pumps_data_trim_Punique_QAll = [];
        MFM_data_trim_Punique_QAll = [];
        trans_data_trim_Punique_QAll = [];
        PGD1_data_trim_Punique_QAll = [];
        PGD2_data_trim_Punique_QAll = [];

        for k = 1:length(Q_unique)

            P_P1_aux = pumps_data.P_P1;
            P_P2_aux = pumps_data.P_P2;
            P_total = P_P1_aux + P_P2_aux; % if only one pumps is used while recording
            P_tol = 0.05; %relative
            Q_P1_aux = pumps_data.q_P1;
            Q_P2_aux = pumps_data.q_P2;
            Q_total = Q_P1_aux + Q_P2_aux; % if only one pumps is used while recording
            Q_tol = 0.01; %absolute

            idx_P_Q = (abs(P_total - P_unique(j))/(P_unique(j)+14.7)<P_tol)&(abs(Q_total - Q_unique(k))<Q_tol);

            if any(idx_P_Q ~= 0)

                idx_P_Q_aux1 = [0;idx_P_Q(1:end-1)];
                idx_P_Q_aux2 = [idx_P_Q(2:end);0;];
                idx_diff1 = idx_P_Q - idx_P_Q_aux1;
                idx_diff2 = idx_P_Q - idx_P_Q_aux2;

                % pumps data
                pumps_data_aux = pumps_data(idx_P_Q,:);
                pumps_data_aux.P12 = P_total(idx_P_Q);
                pumps_data_aux.Q12 = Q_total(idx_P_Q);
                P_mean = mean(pumps_data_aux.P12);
                Q_mean = mean(pumps_data_aux.Q12);
                P_std = std(pumps_data_aux.P12);
                Q_std = std(pumps_data_aux.Q12);           
                pumps_data_trim = [pumps_data_trim; pumps_data_aux]; % all P and all Q
                pumps_data_trim_Punique_QAll = [pumps_data_trim_Punique_QAll; pumps_data_aux]; % Unique P and all Q
                calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).pumpsData = pumps_data_aux;
                expTrimData.(filedataExp.Key(i)).pumpsData = pumps_data_trim;

                % find time stap to trim
                TimeStamp_aux = pumps_data.TimeStamp;
                idx_st = find(idx_diff1 == 1);
                idx_et = find(idx_diff2 == 1);
                TimeStamp_st = TimeStamp_aux(idx_st);
                TimeStamp_et = TimeStamp_aux(idx_et);

                MFM_data_aux = [];
                trans_data_aux = [];
                PGD1_data_aux = [];
                PGD2_data_aux = [];

                for l = 1:length(idx_st)

                    % MFM data
                    MFM_data_trim_aux = MFM_data((MFM_data.TimeStamp>=TimeStamp_st(l))&(MFM_data.TimeStamp<=TimeStamp_et(l)),:);
                    % MFM_data_trim_aux = MFM_data_trim_aux((MFM_data_trim_aux.T_MFM2>=T_cal-dT_cal),:);
                    MFM_data_aux = [MFM_data_aux; MFM_data_trim_aux];  % all P and all Q
                    MFM_data_trim_Punique_QAll = [MFM_data_trim_Punique_QAll; MFM_data_aux]; % Unique P and all Q

                    % trans data
                    if ismissing(trans_data_name) == 0
                        trans_data_trim_aux = trans_data((PGD1_data.TimeStamp>=TimeStamp_st(l))&(PGD1_data.TimeStamp<=TimeStamp_et(l)),:);
                        trans_data_aux = [trans_data_aux; trans_data_trim_aux]; % all P and all Q
                        trans_data_trim_Punique_QAll = [trans_data_trim_Punique_QAll; trans_data_aux]; % Unique P and all Q
                    end

                    % PGD1 data
                    if ismissing(PGD1_data_name) == 0                    
                        PGD1_data_trim_aux = PGD1_data((PGD1_data.TimeStamp>=TimeStamp_st(l))&(PGD1_data.TimeStamp<=TimeStamp_et(l)),:);
                        PGD1_data_aux = [PGD1_data_aux; PGD1_data_trim_aux]; % all P and all Q
                        PGD1_data_trim_Punique_QAll = [PGD1_data_trim_Punique_QAll; PGD1_data_aux]; % Unique P and all Q
                    end

                    % PGD2 data
                    if ismissing(PGD2_data_name) == 0                    
                        PGD2_data_trim_aux = PGD2_data((PGD2_data.TimeStamp>=TimeStamp_st(l))&(PGD2_data.TimeStamp<=TimeStamp_et(l)),:);
                        PGD2_data_aux = [PGD2_data_aux; PGD2_data_trim_aux]; % all P and all Q
                        PGD2_data_trim_Punique_QAll = [PGD2_data_trim_Punique_QAll; PGD2_data_aux]; % Unique P and all Q
                    end  

                end

                    dens_mean = mean(MFM_data_aux.dens_MFM2);
                    T_mean = mean(MFM_data_aux.T_MFM2);
                    Q_MFM_mean = mean(MFM_data_aux.q_MFM2);
                    freq_MFM_mean = mean(MFM_data_aux.freq_MFM2);
                    dens_std = std(MFM_data_aux.dens_MFM2);
                    T_std = std(MFM_data_aux.T_MFM2);
                    Q_MFM_std = std(MFM_data_aux.q_MFM2);
                    freq_MFM_std = std(MFM_data_aux.freq_MFM2);

                    MFM_data_trim = [MFM_data_trim; MFM_data_aux];
                    calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData = MFM_data_aux;
                    expTrimData.(filedataExp.Key(i)).MFMData = MFM_data_trim;

                    % cal results main
                    calResults_temp = table(fluid_cal,T_cal,P_mean,P_std,Q_mean,Q_std, ...
                    dens_mean,dens_std, T_mean,T_std,Q_MFM_mean,Q_MFM_std,freq_MFM_mean,freq_MFM_std, ...
                    {TimeStamp_st},{TimeStamp_et},'VariableNames',{'Fluid','T_C','P_psig_mean','P_psig_std','Q_mean','Q_std', ...
                    'dens_mean','dens_std','T_mean','T_std','Q_MFM_mean', 'Q_MFM_std', ...
                    'freq_MFM_mean','freq_MFM_std','st','et'});

                    % trans data
                    if ismissing(trans_data_name) == 0
                        PT1_mean = mean(trans_data_aux.PT1);
                        PT2_mean = mean(trans_data_aux.PT2);
                        PT1_std = std(trans_data_aux.PT1);
                        PT2_std = std(trans_data_aux.PT2);
                        trans_data_trim = [trans_data_trim; trans_data_aux];
                        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).transData = trans_data_aux;
                        expTrimData.(filedataExp.Key(i)).transData = trans_data_trim;
                        calResults_temp.PT1_mean = PT1_mean;
                        calResults_temp.PT1_std = PT1_std;
                        calResults_temp.PT2_mean = PT2_mean;
                        calResults_temp.PT2_std = PT2_std;                       
                    end

                    % PGD1 data
                    if ismissing(PGD1_data_name) == 0
                        PGD1_mean = mean(PGD1_data_aux.H2GasConcentration);
                        PGD1_std = std(PGD1_data_aux.H2GasConcentration);
                        PGD1_data_trim = [PGD1_data_trim; PGD1_data_aux];
                        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).PGD1Data = PGD1_data_aux;
                        expTrimData.(filedataExp.Key(i)).PGD1Data = PGD1_data_trim;
                        calResults_temp.PGD1_mean = PGD1_mean;
                        calResults_temp.PGD1_std = PGD1_std;
                    end

                    % PGD2 data
                    if ismissing(PGD2_data_name) == 0
                        PGD2_mean = mean(PGD2_data_aux.CO2GasConcentration);
                        PGD2_std = std(PGD2_data_aux.CO2GasConcentration);
                        PGD2_data_trim = [PGD2_data_trim; PGD2_data_aux];
                        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).PGD2Data = PGD2_data_aux;
                        expTrimData.(filedataExp.Key(i)).PGD2Data = PGD2_data_trim;
                        calResults_temp.PGD2_mean = PGD2_mean;
                        calResults_temp.PGD2_std = PGD2_std;                
                    end

                dens_ref = filedataRef.dens((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
                Z_ref = filedataRef.Z((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
                phase_ref = filedataRef.Phase((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
                fluid_ref = filedataRef.Fluid((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
                T_ref = filedataRef.T_C((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
                Ppsig_ref = filedataRef.P_psig((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));

                calResults_temp.dens_ref = dens_ref;
                calResults_temp.Z_ref = Z_ref;
                calResults_temp.fluid_ref = phase_ref;
                calResults_temp.fluid_ref = fluid_ref;
                calResults_temp.T_ref = T_ref;
                calResults_temp.Ppsig_ref = Ppsig_ref;
    
                calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).calResults = calResults_temp;
                calResults = [calResults;calResults_temp];

                dens_array = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.dens_MFM2;
                T_array = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.T_MFM2;
                % freq and Q MFMF could be added too
                calData_temp = table(repmat(fluid_cal,length(dens_array),1),dens_array, repmat(dens_mean,length(dens_array),1), repmat(dens_ref,length(dens_array),1), ...
                    T_array, repmat(T_mean,length(dens_array),1), repmat(T_ref,length(dens_array),1),repmat(P_mean,length(dens_array),1), repmat(Ppsig_ref,length(dens_array),1), repmat(Q_mean,length(dens_array),1),...
                    'VariableNames',{'fluid_cal','dens_MFM','dens_mean', 'dens_ref','T_MFM','T_mean','T_ref','Ppsig_mean','Ppsig_ref','Q_mean'});
                calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).calData = calData_temp;
                calData = [calData;calData_temp];
            end

        end

        % block for all Q
        P_mean = mean(pumps_data_trim_Punique_QAll.P12);
        Q_mean = mean(pumps_data_trim_Punique_QAll.Q12);
        P_std = std(pumps_data_trim_Punique_QAll.P12);
        Q_std = std(pumps_data_trim_Punique_QAll.Q12);  
        dens_mean = mean(MFM_data_trim_Punique_QAll.dens_MFM2);
        T_mean = mean(MFM_data_trim_Punique_QAll.T_MFM2);
        Q_MFM_mean = mean(MFM_data_trim_Punique_QAll.q_MFM2);
        freq_MFM_mean = mean(MFM_data_trim_Punique_QAll.freq_MFM2);
        dens_std = std(MFM_data_trim_Punique_QAll.dens_MFM2);
        T_std = std(MFM_data_trim_Punique_QAll.T_MFM2);
        Q_MFM_std = std(MFM_data_trim_Punique_QAll.q_MFM2);
        freq_MFM_std = std(MFM_data_trim_Punique_QAll.freq_MFM2);

        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.pumpsData = pumps_data_trim_Punique_QAll;
        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.MFMData = MFM_data_trim_Punique_QAll;

        % cal results main Q all
        calResultsQAll_temp = table(fluid_cal,T_cal,P_mean,P_std,Q_mean,Q_std, ...
        dens_mean,dens_std, T_mean,T_std,Q_MFM_mean,Q_MFM_std,freq_MFM_mean,freq_MFM_std, ...
        NaN,NaN,'VariableNames',{'Fluid','T_C','P_psig_mean','P_psig_std','Q_mean','Q_std', ...
        'dens_mean','dens_std','T_mean','T_std','Q_MFM_mean', 'Q_MFM_std', ...
        'freq_MFM_mean','freq_MFM_std','st','et'});

        if ismissing(trans_data_name) == 0
            PT1_mean = mean(trans_data_trim_Punique_QAll.PT1);
            PT2_mean = mean(trans_data_trim_Punique_QAll.PT2);
            PT1_std = std(trans_data_trim_Punique_QAll.PT1);
            PT2_std = std(trans_data_trim_Punique_QAll.PT2);

            calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.transData = trans_data_trim_Punique_QAll;

            calResultsQAll_tempp.PT1_mean = PT1_mean;
            calResultsQAll_temp.PT1_std = PT1_std;
            calResultsQAll_temp.PT2_mean = PT2_mean;
            calResultsQAll_temp.PT2_std = PT2_std; 
        end

        if ismissing(PGD1_data_name) == 0
            PGD1_mean = mean(PGD1_data_trim_Punique_QAll.H2GasConcentration);
            PGD1_std = std(PGD1_data_trim_Punique_QAll.H2GasConcentration);

            calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.PGD1Data = PGD1_data_trim_Punique_QAll;

            calResultsQAll_temp.PGD1_mean = PGD1_mean;
            calResultsQAll_temp.PGD1_std = PGD1_std;
        end

        if ismissing(PGD2_data_name) == 0
            PGD2_mean = mean(PGD2_data_trim_Punique_QAll.CO2GasConcentration);
            PGD2_std = std(PGD2_data_trim_Punique_QAll.CO2GasConcentration);

            calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.PGD2Data = PGD2_data_trim_Punique_QAll;

            calResultsQAll_temp.PGD2_mean = PGD2_mean;
            calResultsQAll_temp.PGD2_std = PGD2_std;
        end

        dens_ref = filedataRef.dens((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
        Z_ref = filedataRef.Z((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
        phase_ref = filedataRef.Phase((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
        
        calResultsQAll_temp.dens_ref = dens_ref;
        calResultsQAll_temp.Z_ref = Z_ref;
        calResultsQAll_temp.phase_ref = phase_ref;
        
        calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.calResults = calResultsQAll_temp;
        calResultsQAll = [calResultsQAll;calResultsQAll_temp];
        
    end
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

save(calResults_name + '.mat','calResults')
save(calResultsQAll_name + '.mat','calResultsQAll')
save(calData_name + '.mat','calData')
save(calProcData_name + '.mat','calProcData')
save(expTrimData_name + '.mat','expTrimData')

% save in excel, with timestamp as string joins
calResults_xlsx = calResults;
calResults_xlsx.st = [];
calResults_xlsx.et = [];
for m = 1:height(calResults)
    calResults_xlsx.st(m) = strjoin(string(calResults.st{m}),", ");
    calResults_xlsx.et(m) = strjoin(string(calResults.et{m}),", ");
end
writetable(calResults_xlsx,calResults_name + '.xlsx','Sheet', 'calResultsQx');
writetable(calResultsQAll,calResults_name + '.xlsx','Sheet', 'calResultsQAll');

writetable(calData,calData_name + '.xlsx','Sheet', 'calDataQAll');

%% Plotting for analysis Raw Data
% Subplot all in 4 panels
aux_idx = find(cellfun(@length,filedataExp.P_psig)>1)';

for i = aux_idx
    figure('Position', [100, 100, 600, 900]); % [left, bottom, width, height];
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
    scatter(expTrimData.(filedataExp.Key(i)).pumpsData.TimeStamp,expTrimData.(filedataExp.Key(i)).pumpsData.P_P1,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    hold on
    scatter(expTrimData.(filedataExp.Key(i)).pumpsData.TimeStamp,expTrimData.(filedataExp.Key(i)).pumpsData.P_P2,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    %xlabel('Time [MM/dd/uuuu HH:mm]');
    ylabel('Pressure [psig]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Flow rate [ml/min]');
    scatter(expTrimData.(filedataExp.Key(i)).pumpsData.TimeStamp,expTrimData.(filedataExp.Key(i)).pumpsData.q_P1,10,'filled','MarkerFaceColor',[0.8500, 0.3250, 0.0980])
    scatter(expTrimData.(filedataExp.Key(i)).pumpsData.TimeStamp,expTrimData.(filedataExp.Key(i)).pumpsData.q_P2,10,'filled','MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    scatter(expTrimData.(filedataExp.Key(i)).MFMData.TimeStamp,expTrimData.(filedataExp.Key(i)).MFMData.q_MFM2,5,'filled','MarkerFaceColor',[0.4940 0.1840 0.5560])
    legend('P_{pump1}','P_{pump2}','q_{pump1}','q_{pump2}','q_{MFM2}', 'Location','southwest');
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
    legend('density_{MFM2}','T_{MFM2}', 'Location','southwest');
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
    scatter(expTrimData.(filedataExp.Key(i)).pumpsData.TimeStamp,expTrimData.(filedataExp.Key(i)).pumpsData.P_P1,10,'filled','MarkerFaceColor',[0, 0.4470, 0.7410])
    scatter(expTrimData.(filedataExp.Key(i)).pumpsData.TimeStamp,expTrimData.(filedataExp.Key(i)).pumpsData.P_P2,10,'filled','MarkerFaceColor',[0.4660, 0.6740, 0.1880])
    legend('density_{MFM2}','P_{pump1}','P_{pump2}', 'Location','southwest');
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
% 
% 
% 
% for i = aux_idx
%     for j = 1:length(fluids)
%         if fluids(j) == fluid_cal
%             dens_cal_vals = table();
%             for k = 1:length(P_unique)
%                 dens_cal_Ref = repmat(cal_vals.(fluids(j)).dens(k),length(calProcData.(fluids(j)).(P_unique_field(k)).dens_array),1);
%                 P_cal_ref = repmat(cal_vals.(fluids(j)).P_psig(k),length(calProcData.(fluids(j)).(P_unique_field(k)).dens_array),1);
%                 fluid_cal_ref = repmat(cal_vals.(fluids(j)).Fluid(k),length(calProcData.(fluids(j)).(P_unique_field(k)).dens_array),1);
%                 dens_cal_MFM = calProcData.(fluids(j)).(P_unique_field(k)).dens_array;
%                 T_cal_MFM = calProcData.(fluids(j)).(P_unique_field(k)).T_array;
%                 % take out Nan values
%                 dens_cal_Ref_clean = dens_cal_Ref(~isnan(dens_cal_MFM));
%                 P_cal_ref_clean = P_cal_ref(~isnan(dens_cal_MFM));
%                 fluid_cal_ref_clean = fluid_cal_ref(~isnan(dens_cal_MFM));
%                 dens_cal_MFM_clean = dens_cal_MFM(~isnan(dens_cal_MFM));
%                 T_cal_MFM_clean = T_cal_MFM(~isnan(dens_cal_MFM));
%                 dens_cal_vals_temp = table(dens_cal_Ref_clean,dens_cal_MFM_clean,T_cal_MFM_clean, P_cal_ref_clean,fluid_cal_ref_clean,'VariableNames',{'dens_cal_Ref','dens_cal_MFM','T_cal_MFM','P_cal_ref','Fluid_cal_ref'});
%                 dens_cal_vals = [dens_cal_vals;dens_cal_vals_temp];
%             end
%             calProcData.(fluids(j)).dens_cal_all = dens_cal_vals;
%         end
%     end
% end
% 
% %% Rho Cal curve
% 
% dens_cal_vals_all = table();
% for i = 1:length(fluids)
%     dens_cal_vals_all = [dens_cal_vals_all;calProcData.(fluids(i)).dens_cal_all];
% end
% 
% calProcData.dens_cal_vals_all = dens_cal_vals_all;
% 
% % fit linear
% % all
% rho_cal_fit_lin = fitlm(dens_cal_vals_all(:,1:2)); 
% % high pressure cal only
% dens_cal_vals_HP = dens_cal_vals_all(dens_cal_vals_all.P_cal_ref==1500,:);
% rho_cal_HP_fit_lin = fitlm(dens_cal_vals_HP(:,1:2)); 
% 
% % save fit model params
% fittingRhoResultsAll = table('Size',[0 4],'VariableTypes',{'string','double','double','double'},'VariableNames',{'model','p1','p2','RMSE'});
% calProcData.rho_cal_fit_lin = rho_cal_fit_lin;
% fittingRhoResultsAll(1,:) = {"all_lin",rho_cal_fit_lin.Coefficients.Estimate(1),rho_cal_fit_lin.Coefficients.Estimate(2),rho_cal_fit_lin.RMSE};
% calProcData.rho_cal_HP_fit_lin = rho_cal_HP_fit_lin;
% fittingRhoResultsAll(2,:) = {"HP_lin",rho_cal_HP_fit_lin.Coefficients.Estimate(1),rho_cal_HP_fit_lin.Coefficients.Estimate(2),rho_cal_HP_fit_lin.RMSE};
% 
% calProcData.fittingRhoResultsAll = fittingRhoResultsAll;
% writetable(fittingRhoResultsAll,pathExportAll + "fittingRhoResultsAll.xlsx");
% save(pathExportAll + "calProcData.mat",'calProcData')
% 
% %% Density cal plot all densitites (all fluids, temperatures and pressures)
% figure
% set(gcf, 'Position', [100, 100, 700, 550])
% scatter(dens_cal_vals_all.dens_cal_Ref,dens_cal_vals_all.dens_cal_MFM,20,dens_cal_vals_all.T_cal_MFM,'filled')
% hold on
% plot(0:1:800,feval(rho_cal_fit_lin,0:1:800),"Color",'k')
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
% grid on
% title("Calibration curve - all cal fluids P and T")
% saveas(gcf,pathExportAll + "Cal-all",'png')
% 
% % save figs, add colours, add mean val and symbol per substance tested
% %% All fluids, only high pressure - cal curves
% figure
% scatter(dens_cal_vals_HP.dens_cal_Ref,dens_cal_vals_HP.dens_cal_MFM,20,dens_cal_vals_HP.T_cal_MFM,'filled')
% hold on
% plot(0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
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
% grid on
% title("Calibration curve - all cal fluids and T at HP")
% saveas(gcf,pathExportAll + "Cal-all_HP",'png')
% 
% %% All fluids, only high pressure, cal curves, zoom in
% 
% % three different fluids H2, He, CO2 for paper! High pressure = 1500 psig,
% % Tref = 32C
% 
% figure;
% set(gcf, 'Position', [100, 100, 700, 550])
% ax1 = axes;
% scatter(dens_cal_vals_HP.dens_cal_Ref,dens_cal_vals_HP.dens_cal_MFM,15,dens_cal_vals_HP.T_cal_MFM,'filled')
% hold on
% plot(0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
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
% grid on
% legend({'Measured density','Calibration curve'},'Location','southeast')
% % cal curve formula annotation
% coeffs = calProcData.rho_cal_HP_fit_lin.Coefficients.Estimate;
% annotText = sprintf('\\rho_{MFM} = %.1f \\cdot \\rho_{Ref} + %.1f', coeffs(2), coeffs(1));
% annotation('textbox', [0.2, 0.12, 0.3, 0.1], 'String', annotText, ...
%     'Interpreter', 'tex', 'FontSize', 11, 'EdgeColor', 'none');
% % H2
% insetAx = axes('Position', [0.19 0.70 0.1 0.15]);  % [x y width height]
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,dens_cal_vals_HP.dens_cal_Ref,dens_cal_vals_HP.dens_cal_MFM,15,dens_cal_vals_HP.T_cal_MFM,'filled')
% hold on
% plot(insetAx,0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
% grid on
% xlim([4,12])
% ylim([17,27])
% title('H_2 (32°C, 10.4 MPa)')
% % He
% insetAx = axes('Position', [0.36 0.70 0.1 0.15]);  % [x y width height]
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,dens_cal_vals_HP.dens_cal_Ref,dens_cal_vals_HP.dens_cal_MFM,15,dens_cal_vals_HP.T_cal_MFM,'filled')
% hold on
% plot(insetAx,0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
% xlim([11,19])
% ylim([24,34])
% title('He_  (32°C, 10.4 MPa)')
% grid on
% % CO2
% insetAx = axes('Position', [0.19 0.47 0.1 0.15]);  % [x y width height]
% box(insetAx, 'on');  % Add border to inset
% scatter(insetAx,dens_cal_vals_HP.dens_cal_Ref,dens_cal_vals_HP.dens_cal_MFM,15,dens_cal_vals_HP.T_cal_MFM,'filled')
% hold on
% plot(insetAx,0:1:800,feval(rho_cal_HP_fit_lin,0:1:800),"Color",'k')
% xlim([696,720])
% ylim([748,777])
% title('CO_2 (32°C, 10.4 MPa)')
% grid on
% saveas(gcf,pathExportAll + "Cal-curve-zoom-in",'png')
% 
% %% correction due tue temperature or Q
% 
% % P, T and density arrays for a fixed time and fluid
% 
% fluids = unique(filedataExp.Fluid1);
% P_unique = unique(filedataExp.P_psig);
% P_unique = P_unique(~isnan(P_unique));
% P_unique_field = "P"+ string(P_unique);
% T_unique = unique(filedataExp.T);
% T_unique = T_unique(~isnan(T_unique));
% 
% aux_idx = find(ismissing(filedataExp.P_psig) == 0)';
% 
% mean_vals = table();
% std_vals = table();
% fluid_Ref_row_vals = table();
% calResults = table();
% 
% for i = aux_idx(1):aux_idx(end)
%     for j = 1:length(fluids)
%         for k = 1:length(P_unique)
%             for l = 1:length(T_unique)
%                 if fluids(j) == filedataExp.Fluid1(i)
%                     if P_unique(k) == filedataExp.P_psig(i)
%                         if T_unique(l) == filedataExp.T(i)
%                             calProcData1.(fluids(j)).(P_unique_field(k)).dens_array = expRawData.(filedataExp.Key(i)).MFMData.dens_MFM2((expRawData.(filedataExp.Key(i)).MFMData.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp<=filedataExp.et(i)),:);
%                             calProcData1.(fluids(j)).(P_unique_field(k)).T_array = expRawData.(filedataExp.Key(i)).MFMData.T_MFM2((expRawData.(filedataExp.Key(i)).MFMData.TimeStamp>=filedataExp.st(i))&(expRawData.(filedataExp.Key(i)).MFMData.TimeStamp<=filedataExp.et(i)),:);
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end
% 
% 
% for i = 1:height(filedataRef)
%     for j = 1:length(fluids)
%         for k = 1:length(P_unique)
%             for l = 1:length(T_unique)
%                 if fluids(j) == filedataRef.Fluid(i)
%                     if P_unique(k) == filedataRef.P_psig(i)
%                         if T_unique(l) == filedataRef.Temp(i)
%                             calProcData1.(fluids(j)).(P_unique_field(k)).dens_arraynorm = calProcData1.(fluids(j)).(P_unique_field(k)).dens_array/filedataRef.dens(i);
%                             calProcData1.(fluids(j)).(P_unique_field(k)).T_arraynorm = calProcData1.(fluids(j)).(P_unique_field(k)).T_array/filedataRef.Temp(i);
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end
% 
% calResults1 = [calProcData1.(fluids(j)).(P_unique_field(k)).dens_arraynorm,calProcData1.(fluids(j)).(P_unique_field(k)).T_arraynorm];
% 
% for j = 1:length(fluids)
%     cal_vals1.(fluids(j)) = calResults1(calResults1.Fluid == fluids(j),:);
% end
% 
% %%
% % Calibration curve
% figure
% for j = 1:length(fluids)
%     scatter(calProcData1.(fluids(j)).P1500.T_arraynorm,calProcData1.(fluids(j)).P1500.dens_arraynorm,'DisplayName',fluids{j})
%     hold on
%     grid on
%     legend()
%     ylabel('rho MFM / rho ref')
%     xlabel('T MFM / T ref')
% end
% 
% 
% %% Back up trim & save
% aux_idx = find(cellfun(@length,filedataExp.P_psig)>1)';
% 
% P_unique = unique(vertcat(filedataExp.P_psig{aux_idx}));
% Q_unique = unique(vertcat(filedataExp.Q_mlmin{aux_idx}));
% P_unique_field = "P"+ string(P_unique);
% Q_unique_field = "Q"+ string(Q_unique);
% 
% clear calProcData;
% clear expTrimData;
% calResults = table();
% calResultsQAll = table();
% calData = table();
% 
% calResults_name = pathExportAll + "calResults";
% calResultsQAll_name = pathExportAll + "calResultsQAll";
% calData_name = pathExportAll + "calData";
% calProcData_name = pathExportAll + "calProcData";
% expTrimData_name = pathExportAll + "expTrimData";
% 
% delete(calResults_name + '.xlsx');
% delete(calResults_name + '.mat');
% delete(calResultsQAll_name + '.mat');
% delete(calData_name + '.xlsx');
% delete(calData_name + '.mat');
% delete(calProcData_name + '.mat');
% delete(expTrimData_name + '.mat');
% 
% for i = aux_idx
% 
%     xlsx_name = pathExportAll + filedataExp.Key(i) + '_Trim';
%     delete(xlsx_name + '.xlsx');
% 
%     T_cal = filedataExp.T_C(i);
%     % dT_cal = 4; % to trim array when T is meaningful automatically, it will take out values when T has not reached th right conditions
%     T_unique_field = "T" + string(T_cal);
% 
%     pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);    
%     MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
%     trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
%     PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
%     PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);
% 
%     pumps_data = expRawData.(filedataExp.Key(i)).pumpsData;
%     MFM_data = expRawData.(filedataExp.Key(i)).MFMData;
% 
%     pumps_data_trim = [];
%     MFM_data_trim = [];
% 
%     if ismissing(trans_data_name) == 0
%         trans_data = expRawData.(filedataExp.Key(i)).transData;
%         trans_data_trim = [];
%     end
% 
%     if ismissing(PGD1_data_name) == 0
%         PGD1_data = expRawData.(filedataExp.Key(i)).PGD1Data;
%         PGD1_data_trim = [];
%     end
% 
%     if ismissing(PGD2_data_name) == 0
%         PGD2_data = expRawData.(filedataExp.Key(i)).PGD2Data;
%         PGD2_data_trim = [];
%     end
% 
%     for j = 1:length(P_unique)
% 
%         pumps_data_trim_Punique_QAll = [];
%         MFM_data_trim_Punique_QAll = [];
%         trans_data_trim_Punique_QAll = [];
%         PGD1_data_trim_Punique_QAll = [];
%         PGD2_data_trim_Punique_QAll = [];
% 
%         for k = 1:length(Q_unique)
% 
%             P_P1_aux = pumps_data.P_P1;
%             P_P2_aux = pumps_data.P_P2;
%             P_total = P_P1_aux + P_P2_aux; % if only one pumps is used while recording
%             P_tol = 0.05; %relative
%             Q_P1_aux = pumps_data.q_P1;
%             Q_P2_aux = pumps_data.q_P2;
%             Q_total = Q_P1_aux + Q_P2_aux; % if only one pumps is used while recording
%             Q_tol = 0.01; %absolute
% 
%             idx_P_Q = (abs(P_total - P_unique(j))/(P_unique(j)+14.7)<P_tol)&(abs(Q_total - Q_unique(k))<Q_tol);
% 
%             if any(idx_P_Q ~= 0)
% 
%                 idx_P_Q_aux1 = [0;idx_P_Q(1:end-1)];
%                 idx_P_Q_aux2 = [idx_P_Q(2:end);0;];
%                 idx_diff1 = idx_P_Q - idx_P_Q_aux1;
%                 idx_diff2 = idx_P_Q - idx_P_Q_aux2;
% 
%                 % pumps data
%                 pumps_data_aux = pumps_data(idx_P_Q,:);
%                 pumps_data_aux.P12 = P_total(idx_P_Q);
%                 pumps_data_aux.Q12 = Q_total(idx_P_Q);
%                 P_mean = mean(pumps_data_aux.P12);
%                 Q_mean = mean(pumps_data_aux.Q12);
%                 P_std = std(pumps_data_aux.P12);
%                 Q_std = std(pumps_data_aux.Q12);           
%                 pumps_data_trim = [pumps_data_trim; pumps_data_aux]; % all P and all Q
%                 pumps_data_trim_Punique_QAll = [pumps_data_trim_Punique_QAll; pumps_data_aux]; % Unique P and all Q
%                 calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).pumpsData = pumps_data_aux;
%                 expTrimData.(filedataExp.Key(i)).pumpsData = pumps_data_trim;
% 
%                 % find time stap to trim
%                 TimeStamp_aux = pumps_data.TimeStamp;
%                 idx_st = find(idx_diff1 == 1);
%                 idx_et = find(idx_diff2 == 1);
%                 TimeStamp_st = TimeStamp_aux(idx_st);
%                 TimeStamp_et = TimeStamp_aux(idx_et);
% 
%                 MFM_data_aux = [];
%                 trans_data_aux = [];
%                 PGD1_data_aux = [];
%                 PGD2_data_aux = [];
% 
%                 for l = 1:length(idx_st)
% 
%                     % MFM data
%                     MFM_data_trim_aux = MFM_data((MFM_data.TimeStamp>=TimeStamp_st(l))&(MFM_data.TimeStamp<=TimeStamp_et(l)),:);
%                     % MFM_data_trim_aux = MFM_data_trim_aux((MFM_data_trim_aux.T_MFM2>=T_cal-dT_cal),:);
%                     MFM_data_aux = [MFM_data_aux; MFM_data_trim_aux];  % all P and all Q
%                     MFM_data_trim_Punique_QAll = [MFM_data_trim_Punique_QAll; MFM_data_aux]; % Unique P and all Q
% 
%                     % trans data
%                     if ismissing(trans_data_name) == 0
%                         trans_data_trim_aux = trans_data((PGD1_data.TimeStamp>=TimeStamp_st(l))&(PGD1_data.TimeStamp<=TimeStamp_et(l)),:);
%                         trans_data_aux = [trans_data_aux; trans_data_trim_aux]; % all P and all Q
%                         trans_data_trim_Punique_QAll = [trans_data_trim_Punique_QAll; trans_data_aux]; % Unique P and all Q
%                     end
% 
%                     % PGD1 data
%                     if ismissing(PGD1_data_name) == 0                    
%                         PGD1_data_trim_aux = PGD1_data((PGD1_data.TimeStamp>=TimeStamp_st(l))&(PGD1_data.TimeStamp<=TimeStamp_et(l)),:);
%                         PGD1_data_aux = [PGD1_data_aux; PGD1_data_trim_aux]; % all P and all Q
%                         PGD1_data_trim_Punique_QAll = [PGD1_data_trim_Punique_QAll; PGD1_data_aux]; % Unique P and all Q
%                     end
% 
%                     % PGD2 data
%                     if ismissing(PGD2_data_name) == 0                    
%                         PGD2_data_trim_aux = PGD2_data((PGD2_data.TimeStamp>=TimeStamp_st(l))&(PGD2_data.TimeStamp<=TimeStamp_et(l)),:);
%                         PGD2_data_aux = [PGD2_data_aux; PGD2_data_trim_aux]; % all P and all Q
%                         PGD2_data_trim_Punique_QAll = [PGD2_data_trim_Punique_QAll; PGD2_data_aux]; % Unique P and all Q
%                     end  
% 
%                 end
% 
%                     dens_mean = mean(MFM_data_aux.dens_MFM2);
%                     T_mean = mean(MFM_data_aux.T_MFM2);
%                     Q_MFM_mean = mean(MFM_data_aux.q_MFM2);
%                     freq_MFM_mean = mean(MFM_data_aux.freq_MFM2);
%                     dens_std = std(MFM_data_aux.dens_MFM2);
%                     T_std = std(MFM_data_aux.T_MFM2);
%                     Q_MFM_std = std(MFM_data_aux.q_MFM2);
%                     freq_MFM_std = std(MFM_data_aux.freq_MFM2);
% 
%                     MFM_data_trim = [MFM_data_trim; MFM_data_aux];
%                     calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData = MFM_data_aux;
%                     expTrimData.(filedataExp.Key(i)).MFMData = MFM_data_trim;
% 
%                     % cal results main
%                     calResults_temp = table(fluid_cal,T_cal,P_mean,P_std,Q_mean,Q_std, ...
%                     dens_mean,dens_std, T_mean,T_std,Q_MFM_mean,Q_MFM_std,freq_MFM_mean,freq_MFM_std, ...
%                     {TimeStamp_st},{TimeStamp_et},'VariableNames',{'Fluid','T_C','P_psig_mean','P_psig_std','Q_mean','Q_std', ...
%                     'dens_mean','dens_std','T_mean','T_std','Q_MFM_mean', 'Q_MFM_std', ...
%                     'freq_MFM_mean','freq_MFM_std','st','et'});
% 
%                     % trans data
%                     if ismissing(trans_data_name) == 0
%                         PT1_mean = mean(trans_data_aux.PT1);
%                         PT2_mean = mean(trans_data_aux.PT2);
%                         PT1_std = std(trans_data_aux.PT1);
%                         PT2_std = std(trans_data_aux.PT2);
%                         trans_data_trim = [trans_data_trim; trans_data_aux];
%                         calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).transData = trans_data_aux;
%                         expTrimData.(filedataExp.Key(i)).transData = trans_data_trim;
%                         calResults_temp.PT1_mean = PT1_mean;
%                         calResults_temp.PT1_std = PT1_std;
%                         calResults_temp.PT2_mean = PT2_mean;
%                         calResults_temp.PT2_std = PT2_std;                       
%                     end
% 
%                     % PGD1 data
%                     if ismissing(PGD1_data_name) == 0
%                         PGD1_mean = mean(PGD1_data_aux.H2GasConcentration);
%                         PGD1_std = std(PGD1_data_aux.H2GasConcentration);
%                         PGD1_data_trim = [PGD1_data_trim; PGD1_data_aux];
%                         calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).PGD1Data = PGD1_data_aux;
%                         expTrimData.(filedataExp.Key(i)).PGD1Data = PGD1_data_trim;
%                         calResults_temp.PGD1_mean = PGD1_mean;
%                         calResults_temp.PGD1_std = PGD1_std;
%                     end
% 
%                     % PGD2 data
%                     if ismissing(PGD2_data_name) == 0
%                         PGD2_mean = mean(PGD2_data_aux.CO2GasConcentration);
%                         PGD2_std = std(PGD2_data_aux.CO2GasConcentration);
%                         PGD2_data_trim = [PGD2_data_trim; PGD2_data_aux];
%                         calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).PGD2Data = PGD2_data_aux;
%                         expTrimData.(filedataExp.Key(i)).PGD2Data = PGD2_data_trim;
%                         calResults_temp.PGD2_mean = PGD2_mean;
%                         calResults_temp.PGD2_std = PGD2_std;                
%                     end
% 
%                 dens_ref = filedataRef.dens((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
%                 Z_ref = filedataRef.Z((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
%                 phase_ref = filedataRef.Phase((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
%                 fluid_ref = filedataRef.Fluid((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
%                 T_ref = filedataRef.T_C((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
%                 Ppsig_ref = filedataRef.P_psig((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
% 
%                 calResults_temp.dens_ref = dens_ref;
%                 calResults_temp.Z_ref = Z_ref;
%                 calResults_temp.fluid_ref = phase_ref;
%                 calResults_temp.fluid_ref = fluid_ref;
%                 calResults_temp.T_ref = T_ref;
%                 calResults_temp.Ppsig_ref = Ppsig_ref;
% 
%                 calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).calResults = calResults_temp;
%                 calResults = [calResults;calResults_temp];
% 
%                 dens_array = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.dens_MFM2;
%                 T_array = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.T_MFM2;
%                 % freq and Q MFMF could be added too
%                 calData_temp = table(repmat(fluid_cal,length(dens_array),1),dens_array, repmat(dens_mean,length(dens_array),1), repmat(dens_ref,length(dens_array),1), ...
%                     T_array, repmat(T_mean,length(dens_array),1), repmat(T_ref,length(dens_array),1),repmat(P_mean,length(dens_array),1), repmat(Ppsig_ref,length(dens_array),1), repmat(Q_mean,length(dens_array),1),...
%                     'VariableNames',{'fluid_cal','dens_MFM','dens_mean', 'dens_ref','T_MFM','T_mean','T_ref','Ppsig_mean','Ppsig_ref','Q_mean'});
%                 calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).calData = calData_temp;
%                 calData = [calData;calData_temp];
%             end
% 
%         end
% 
%         % block for all Q
%         P_mean = mean(pumps_data_trim_Punique_QAll.P12);
%         Q_mean = mean(pumps_data_trim_Punique_QAll.Q12);
%         P_std = std(pumps_data_trim_Punique_QAll.P12);
%         Q_std = std(pumps_data_trim_Punique_QAll.Q12);  
%         dens_mean = mean(MFM_data_trim_Punique_QAll.dens_MFM2);
%         T_mean = mean(MFM_data_trim_Punique_QAll.T_MFM2);
%         Q_MFM_mean = mean(MFM_data_trim_Punique_QAll.q_MFM2);
%         freq_MFM_mean = mean(MFM_data_trim_Punique_QAll.freq_MFM2);
%         dens_std = std(MFM_data_trim_Punique_QAll.dens_MFM2);
%         T_std = std(MFM_data_trim_Punique_QAll.T_MFM2);
%         Q_MFM_std = std(MFM_data_trim_Punique_QAll.q_MFM2);
%         freq_MFM_std = std(MFM_data_trim_Punique_QAll.freq_MFM2);
% 
%         calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.pumpsData = pumps_data_trim_Punique_QAll;
%         calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.MFMData = MFM_data_trim_Punique_QAll;
% 
%         % cal results main Q all
%         calResultsQAll_temp = table(fluid_cal,T_cal,P_mean,P_std,Q_mean,Q_std, ...
%         dens_mean,dens_std, T_mean,T_std,Q_MFM_mean,Q_MFM_std,freq_MFM_mean,freq_MFM_std, ...
%         NaN,NaN,'VariableNames',{'Fluid','T_C','P_psig_mean','P_psig_std','Q_mean','Q_std', ...
%         'dens_mean','dens_std','T_mean','T_std','Q_MFM_mean', 'Q_MFM_std', ...
%         'freq_MFM_mean','freq_MFM_std','st','et'});
% 
%         if ismissing(trans_data_name) == 0
%             PT1_mean = mean(trans_data_trim_Punique_QAll.PT1);
%             PT2_mean = mean(trans_data_trim_Punique_QAll.PT2);
%             PT1_std = std(trans_data_trim_Punique_QAll.PT1);
%             PT2_std = std(trans_data_trim_Punique_QAll.PT2);
% 
%             calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.transData = trans_data_trim_Punique_QAll;
% 
%             calResultsQAll_tempp.PT1_mean = PT1_mean;
%             calResultsQAll_temp.PT1_std = PT1_std;
%             calResultsQAll_temp.PT2_mean = PT2_mean;
%             calResultsQAll_temp.PT2_std = PT2_std; 
%         end
% 
%         if ismissing(PGD1_data_name) == 0
%             PGD1_mean = mean(PGD1_data_trim_Punique_QAll.H2GasConcentration);
%             PGD1_std = std(PGD1_data_trim_Punique_QAll.H2GasConcentration);
% 
%             calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.PGD1Data = PGD1_data_trim_Punique_QAll;
% 
%             calResultsQAll_temp.PGD1_mean = PGD1_mean;
%             calResultsQAll_temp.PGD1_std = PGD1_std;
%         end
% 
%         if ismissing(PGD2_data_name) == 0
%             PGD2_mean = mean(PGD2_data_trim_Punique_QAll.CO2GasConcentration);
%             PGD2_std = std(PGD2_data_trim_Punique_QAll.CO2GasConcentration);
% 
%             calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.PGD2Data = PGD2_data_trim_Punique_QAll;
% 
%             calResultsQAll_temp.PGD2_mean = PGD2_mean;
%             calResultsQAll_temp.PGD2_std = PGD2_std;
%         end
% 
%         dens_ref = filedataRef.dens((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
%         Z_ref = filedataRef.Z((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
%         phase_ref = filedataRef.Phase((fluid_cal==filedataRef.Fluid)&(T_cal==filedataRef.T_C)&(P_unique(j)==filedataRef.P_psig));
% 
%         calResultsQAll_temp.dens_ref = dens_ref;
%         calResultsQAll_temp.Z_ref = Z_ref;
%         calResultsQAll_temp.phase_ref = phase_ref;
% 
%         calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).QAll.calResults = calResultsQAll_temp;
%         calResultsQAll = [calResultsQAll;calResultsQAll_temp];
% 
%     end
%     % save table for each key but trimmed
%     writetable(expTrimData.(filedataExp.Key(i)).pumpsData,xlsx_name  + '.xlsx', 'Sheet', 'pumps_data');
%     writetable(expTrimData.(filedataExp.Key(i)).MFMData,xlsx_name  + '.xlsx', 'Sheet', 'MFM_data');
% 
%     if ismissing(trans_data_name) == 0
%         writetable(expTrimData.(filedataExp.Key(i)).transData,xlsx_name +'.xlsx', 'Sheet', 'trans_data');
%     end
% 
%     if ismissing(PGD1_data_name) == 0
%         writetable(expTrimData.(filedataExp.Key(i)).PGD1Data,xlsx_name + '.xlsx', 'Sheet', 'PGD1_data');
%     end
% 
%     if ismissing(PGD2_data_name) == 0
%         writetable(expTrimData.(filedataExp.Key(i)).PGD2Data,xlsx_name + '.xlsx', 'Sheet', 'PGD2_data');
%     end
% 
% end
% 
% save(calResults_name + '.mat','calResults')
% save(calResultsQAll_name + '.mat','calResultsQAll')
% save(calData_name + '.mat','calData')
% save(calProcData_name + '.mat','calProcData')
% save(expTrimData_name + '.mat','expTrimData')
% 
% % save in excel, with timestamp as string joins
% calResults_xlsx = calResults;
% calResults_xlsx.st = [];
% calResults_xlsx.et = [];
% for m = 1:height(calResults)
%     calResults_xlsx.st(m) = strjoin(string(calResults.st{m}),", ");
%     calResults_xlsx.et(m) = strjoin(string(calResults.et{m}),", ");
% end
% writetable(calResults_xlsx,calResults_name + '.xlsx','Sheet', 'calResultsQx');
% writetable(calResultsQAll,calResults_name + '.xlsx','Sheet', 'calResultsQAll');
% 
% writetable(calData,calData_name + '.xlsx','Sheet', 'calDataQAll');