% main_Cal.m
% Author: Ianna Gomez Mendez
%
% Objective: 
% Validate methodology to estimate Xi from rho measured and T_MFM
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
% 4 - Estimate rho corrected
% 5 - Estimate Xi
% 6 - Plot density inst vs Ref data
% 
% Output: 
% - Excel (and csv) file with all variables with same time and time elapsed
% - Figures
%
%% INPUT
% INTRODUCE HERE INPUT AND OUTPUT PATH

%Cal Experimental data
filenameExp = 'input/input_val_H2CO2_260303.xlsx';

% PR parameters
% INTRODUCE THE INPUT HERE
% file containing pure components NIST data: Tc, Pc and acentric factor w
filenamePure = 'input/input_PR_pure.xlsx';
% file containing mixture compoents A12 B12 factor to estimate BIP
filenameBIP = 'input/input_PR_BIP.xlsx';

% cal curve results input import
pathImportCal = 'results/cal_250725_PR/';

mkdir('results/val_PR_H2CO2_260303'); % Create directory for output
pathExportAll = 'results/val_PR_H2CO2_260303/'; % Path for OUTPUT


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

%% Trim data

% Clear previous data
clear expTrimData;
clear expProcData;

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
                            
                % trans data
                if ismissing(trans_data_name) == 0 % if trans data exists
                        % trans_data_trim_QAll from trans_data_aux
                    trans_data_trim_QAll = [trans_data_trim_QAll; trans_data_aux]; % Unique P and all Q
                        % xxx_data_trim is feeded with xxx_data_aux for each fluid, T, P and Q, gathers all
                    trans_data_trim = [trans_data_trim; trans_data_aux];                     
                end
    
                % PGD1 data
                if ismissing(PGD1_data_name) == 0 % if PGD1 data exists
                        % PGD1_data_trim_QAll from PGD1_data_aux
                    PGD1_data_trim_QAll = [PGD1_data_trim_QAll; PGD1_data_aux]; % Unique P and all Q
                        % xxx_data_trim is feeded with xxx_data_aux for each fluid, T, P and Q, gathers all
                    PGD1_data_trim = [PGD1_data_trim; PGD1_data_aux];
                end
    
                % PGD2 data 
                if ismissing(PGD2_data_name) == 0 % if PGD2 data exists
                        % PGD1_data_trim_QAll from PGD1_data_aux            
                    PGD2_data_trim_QAll = [PGD2_data_trim_QAll; PGD2_data_aux]; % Unique P and all Q
                        % xxx_data_trim is feeded with xxx_data_aux for each fluid, T, P and Q, gathers all
                    PGD2_data_trim = [PGD2_data_trim; PGD2_data_aux];               
                end
    
            end

        end

        % xxx_data_trim is feeded with xxx_data_aux for each fluid, T, P and Q, gathers all
        pumps_data_trim = [pumps_data_trim; pumps_data_trim_QAll];
        MFM_data_trim = [MFM_data_trim; MFM_data_trim_QAll];

        % Trim data per key
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).pumpsData = pumps_data_trim_QAll;
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).MFMData = MFM_data_trim_QAll;
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).transData = trans_data_trim_QAll;
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).PGD1Data = PGD1_data_trim_QAll;
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).PGD2Data = PGD2_data_trim_QAll;
        
    end

    % Trim data per key
    expTrimData.(filedataExp.Key(i)).pumpsData = pumps_data_trim;
    expTrimData.(filedataExp.Key(i)).MFMData = MFM_data_trim;
    expTrimData.(filedataExp.Key(i)).transData = trans_data_trim;
    expTrimData.(filedataExp.Key(i)).PGD1Data = PGD1_data_trim;
    expTrimData.(filedataExp.Key(i)).PGD2Data = PGD2_data_trim;

end

load(pathImportCal + "fittingRhoResultsAll.mat")
load(pathImportCal + "nlfittingRhoResultsAll.mat")

%% Extract breakthrough curve data

%rho_corr_lin function
rho_corr_lin = @(p,rho_MFM) (rho_MFM-p(1))/p(2);

% rho_corr_nl function second part
rho_corr_nlin = @(p,rho_MFM) (rho_MFM-p(1)+(p(3)-p(2))*p(4))/p(3);

% P of interest array % P in all arrays to validate should be the same
P_unique = unique(vertcat(filedataExp.P_psig{:}));
P_unique_MPa = (P_unique + 14.7)*0.00689476; % P in MPa for PR model

% P and Q name arrays for struct and plots
P_unique_field = "P"+ string(P_unique);

for i = 1:length(filedataExp.Key)
    for j = 1: length(P_unique)
        % Extract measured density vs time
        BTaux = table(expProcData.(filedataExp.Key(i)).(P_unique_field(j)).MFMData.TimeStamp, ...
            expProcData.(filedataExp.Key(i)).(P_unique_field(j)).MFMData.dens_MFM2, ...
            expProcData.(filedataExp.Key(i)).(P_unique_field(j)).MFMData.T_MFM2, ...
            expProcData.(filedataExp.Key(i)).(P_unique_field(j)).MFMData.q_MFM2, ...
            repmat(filedataExp.x1(i), ...
            length(expProcData.(filedataExp.Key(i)).(P_unique_field(j)).MFMData.dens_MFM2),1), ...
            'VariableNames',{'TimeStamp', 'rho_MFM','T_MFM','q_MFM','Ci_ref'});
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT = BTaux;
        % fitting parameters for rho corrected
        % auxLinFit = fittingRhoResultsAll(fittingRhoResultsAll.Q == "QAll",:);
        auxnLinFit = nlfittingRhoResultsAll(nlfittingRhoResultsAll.Q == "QAll",:);
        rho_MFM_0 = rho_corr_lin([auxnLinFit.p1,auxnLinFit.p2],auxnLinFit.p4);
        rho_MFM = expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_MFM;
        % lower slope
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_corr = rho_corr_lin([auxnLinFit.p1,auxnLinFit.p2],rho_MFM);
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_corrMin = rho_corr_lin([auxnLinFit.p1,auxnLinFit.p2],rho_MFM-auxnLinFit.RMSE);
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_corrMax = rho_corr_lin([auxnLinFit.p1,auxnLinFit.p2],rho_MFM+auxnLinFit.RMSE);
        % higher slope
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_corr(rho_MFM>rho_MFM_0) = ...
        rho_corr_nlin([auxnLinFit.p1,auxnLinFit.p2,auxnLinFit.p3,auxnLinFit.p4], ...
        rho_MFM(rho_MFM>rho_MFM_0));
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_corrMin(rho_MFM>rho_MFM_0) = ...
        rho_corr_nlin([auxnLinFit.p1,auxnLinFit.p2,auxnLinFit.p3,auxnLinFit.p4], ...
        rho_MFM(rho_MFM>rho_MFM_0)-auxnLinFit.RMSE);
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_corrMax(rho_MFM>rho_MFM_0) = ...
        rho_corr_nlin([auxnLinFit.p1,auxnLinFit.p2,auxnLinFit.p3,auxnLinFit.p4], ...
        rho_MFM(rho_MFM>rho_MFM_0)+auxnLinFit.RMSE);
    end
end

%% Add molar concentration to breakthrough data and error

% P of interest array
P_unique = unique(vertcat(filedataExp.P_psig{:}));

% P and Q name arrays for struct and plots
P_unique_field = "P"+ string(P_unique);

x1 = 0:0.01:1; % array for binary mixture
for i = 1:length(filedataExp.Key)
    for j = 1: length(P_unique)
        fluidPair = [filedataExp.Fluid1(i),filedataExp.Fluid2(i)];
        Tmin = floor(min(expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.T_MFM)*10)/10;
        Tmax = ceil(max(expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.T_MFM)*10)/10;
        T_PR_aux = Tmin:0.1:Tmax;
        P_psig = P_unique(j);
        P_MPa = (P_psig + 14.7)*0.00689476;
        PTXrho_PR_ref = table();
        for m = 1:length(T_PR_aux)
            [PR_input_T_PR_aux,PR_results_T_PR_aux] = densZ_PR(fluidPair,x1,P_MPa,T_PR_aux(m),filedataPure,filedataBIP);
            % Compressibility factor from Peng Robinson at T_MFM and T_mean
            Z_PR_T_PR_aux = PR_results_T_PR_aux.Z;
            % density from Peng Robinson at T_MFM and T_mean
            dens_PR_T_PR_aux = PR_results_T_PR_aux.rho;        
            % PTXrho_PR_ref table aux
            PTXrho_PR_ref_aux = table(repmat(join(fluidPair),length(x1),1), ...
                repmat(P_psig,length(x1),1), repmat(T_PR_aux(m),length(x1),1), x1', ...
                Z_PR_T_PR_aux, dens_PR_T_PR_aux, 'VariableNames',{'fluidPair', ...
                'P_cal_psig','T_PR', 'x_PR','Z_PR_T_PR', 'rho_PR_T_PR'});
            PTXrho_PR_ref = [PTXrho_PR_ref;PTXrho_PR_ref_aux];
        end   
        scatInterp = scatteredInterpolant(PTXrho_PR_ref.T_PR, ...
            PTXrho_PR_ref.rho_PR_T_PR, PTXrho_PR_ref.x_PR, 'linear', 'linear');
        % at rho corr value
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.Ci = ...
            100*scatInterp(expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.T_MFM, ...
            expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_corr);
        % at rho min value
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.CiMax = ...
            100*scatInterp(expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.T_MFM, ...
            expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_corrMin);
        % at rho max value
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.CiMin = ...
            100*scatInterp(expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.T_MFM, ...
            expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.rho_corrMax);
        % absolute error % 
        expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.dC = ...
            abs(expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.CiMax ...
            -expProcData.(filedataExp.Key(i)).(P_unique_field(j)).BT.CiMin);
    end
end

%% Save trimmed and processed data

% name to save matrices and spreadsheets
expTrimData_name = pathExportAll + "expTrimData";  % Name used for saving TrimData comes from input pathExportAll
expProcData_name = pathExportAll + "expProcData";

% delete previous saved files
delete(expTrimData_name + '.mat');
delete(expProcData_name + '.mat');

for i = 1:length(filedataExp.Key)

    xlsx_name = pathExportAll + filedataExp.Key(i) + '_Trim';
    delete(xlsx_name + '.xlsx');

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
save(expProcData_name + '.mat','expProcData')


%% All val fluids, only high pressure - cal curves
% take only High Pressure Data

figure
set(gcf, 'Position', [100, 100, 700, 550])
for i = 1: length(filedataExp.Key)
    scatter(100*expProcData.(filedataExp.Key(i)).P1500.BT.Ci_ref, ...
        expProcData.(filedataExp.Key(i)).P1500.BT.Ci,20,expProcData.(filedataExp.Key(i)).P1500.BT.T_MFM,'filled')
hold on
end
plot(0:1:100,0:1:100,"Color",'k') % fitting responds to high pressure only
xlabel('C_{H2} _{ref} [mol %]');
ylabel('C_{H2} _{MFM} [mol %]');
xlim([0 100]);
ylim([0 100]);
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
title("Validation curve - H2CO2 (~32 °C, 10.4 MPa)")
saveas(gcf,pathExportAll + "Val-P1500",'png')

%% Plot calibration curve with these two points included

