%% main_Cal.m

% Author: Ianna Gomez Mendez
%
% PURPOSE
%   Process density-calibration experiments used to calibrate the
%   Bronkhorst Coriolis Mass Flow Meter (MFM) density measurement.
%
%   Experimental data are collected during bypass-flow calibration tests
%   performed at controlled pressure, temperature, and flow-rate
%   conditions using pure calibration gases.
%
%   The script imports raw acquisition files, identifies stable operating
%   intervals, computes reference thermodynamic properties using
%   NIST REFPROP, and generates calibration correlations relating
%   measured MFM density to reference fluid density.
%
%   Calibration fluids currently include:
%
%       - Hydrogen (H2)
%       - Helium (He)
%       - Carbon dioxide (CO2)
%
% -------------------------------------------------------------------------
% INPUT FILES
% -------------------------------------------------------------------------
%
% Configuration:
%
%       inputCalConfig.xlsx
%
% Calibration metadata:
%
%       inputCal.xlsx
%
% Legacy EOS files (optional):
%
%       Pure-component parameter file
%       Binary interaction parameter (BIP) file
%
%       NOTE:
%       These files were originally used for Peng-Robinson calculations.
%       Current density calibration uses REFPROP and does not require
%       Peng-Robinson predictions.
%
% Experimental acquisition files:
%
%       Pumps (.dat)
%       Pressure transducers (.csv)
%       Mass flow meters (.csv)
%       Portable gas detectors PGD1 / PGD2 (.csv)
%
% -------------------------------------------------------------------------
% THERMODYNAMIC MODEL
% -------------------------------------------------------------------------
%
%   Thermodynamic properties are obtained from:
%
%       NIST REFPROP
%
%   Properties calculated include:
%
%       Density
%       Compressibility factor
%       Dynamic viscosity
%       Molecular weight
%
%   During calibration, REFPROP density values are used as the reference
%   density against which MFM measurements are calibrated.
%
%   REFPROP input units:
%
%       Temperature : K
%       Pressure    : kPa
%
%   REFPROP output units stored in MATLAB:
%
%       Density     : kg/m^3
%       Viscosity   : Pa·s
%       MW          : kg/mol
%       Z           : -
%
% -------------------------------------------------------------------------
% WORKFLOW
% -------------------------------------------------------------------------
%
%   1. Read calibration configuration and metadata.
%
%   2. Initialize REFPROP.
%
%   3. Import raw experimental datasets:
%
%          - Pumps
%          - Pressure transducers
%          - MFM
%          - PGD sensors
%
%   4. Synchronize timestamps and trim data using user-defined start
%      and end times.
%
%   5. Save raw datasets to:
%
%          - MAT files
%          - Excel workbooks
%
%   6. Identify stable operating intervals corresponding to specified
%      pressure and flow-rate conditions.
%
%   7. Calculate statistics for each operating condition:
%
%          - Mean pressure
%          - Mean flow rate
%          - Mean temperature
%          - Mean density
%          - Standard deviations
%
%   8. Compute REFPROP reference properties:
%
%          rho_REF(T,P)
%          Z_REF(T,P)
%
%   9. Interpolate reference density and compressibility factor to the
%      instantaneous MFM temperature.
%
%  10. Assemble processed calibration datasets:
%
%          calProcData
%          calResults
%          calResultsQAll
%          calData
%
%  11. Fit calibration correlations using:
%
%          - Linear regression
%          - Piecewise nonlinear regression
%
%  12. Estimate calibration uncertainty.
%
%  13. Save processed datasets and calibration parameters.
%
%  14. Generate publication-quality calibration figures.
%
% -------------------------------------------------------------------------
% CALIBRATION MODELS
% -------------------------------------------------------------------------
%
% Linear calibration:
%
%       rho_MFM = p1 + p2*rho_REF
%
%
% Piecewise nonlinear calibration:
%
%       rho_MFM =
%
%           p1
%         + p2*rho_REF
%         + p3*max(0,rho_REF-p4)
%
%
% where:
%
%       rho_REF = REFPROP reference density
%
%       rho_MFM = measured MFM density
%
%       p4      = transition density
%
% The nonlinear model allows separate low-density and high-density
% sensitivities while preserving continuity at rho_REF = p4.
%
% -------------------------------------------------------------------------
% GENERATED DATASETS
% -------------------------------------------------------------------------
%
% Raw datasets:
%
%       expRawData
%
% Trimmed datasets:
%
%       expTrimData
%
% Processed calibration datasets:
%
%       calProcData
%       calResults
%       calResultsQAll
%       calData
%
% Reference-property tables:
%
%       PTXrho_REF
%
% Calibration models:
%
%       cal_curve_params
%       nl_cal_curve_params
%
% Linear fitting results:
%
%       fittingRhoResultsAll
%
% Nonlinear fitting results:
%
%       nlfittingRhoResultsAll
%
% -------------------------------------------------------------------------
% OUTPUT FILES
% -------------------------------------------------------------------------
%
% MAT files:
%
%       expRawData.mat
%       expTrimData.mat
%       calProcData.mat
%       calResults.mat
%       calResultsQAll.mat
%       calData.mat
%
% Excel files:
%
%       calResults.xlsx
%       calResultsQAll.xlsx
%       calData.xlsx
%
% Calibration parameters:
%
%       cal_curve_params.mat
%       nl_cal_curve_params.mat
%
% Figures:
%
%       *_All_vars_Raw.png
%       *_All_vars_Trim.png
%       Cal-all-HP400+-l.png
%       Cal-all-HP400+-nl.png
%       Cal-curve-lin-zoom-in.png
%       Cal-curve-nonlin-zoom-in.png
%
% -------------------------------------------------------------------------
% DEPENDENCIES
% -------------------------------------------------------------------------
%
% Import functions:
%
%       import_inputCal
%       import_inputPR_params_pure
%       import_inputPR_params_BIP
%       import_pumps_data
%       import_trans_data
%       import_MFM_data
%       import_PGD1_data
%       import_PGD2_data
%
% Property functions:
%
%       initREFPROP
%       getFluidProps_REFPROP
%
% Optional backup property package:
%
%       initCoolProp
%       getFluidProps_CProp
%
% Processing functions:
%
%       trim_time_P_Q
%
% -------------------------------------------------------------------------
% NOTES
% -------------------------------------------------------------------------
%
%   - REFPROP is used as the reference source for density and
%     compressibility-factor calculations.
%
%   - Calibration fits are currently generated using data above
%     approximately 400 psig.
%
%   - The calibration correlation is intended to correct MFM density
%     readings during high-pressure gas transport experiments.
%
%   - Generated calibration parameters are subsequently used in
%     breakthrough and CT-processing workflows.

%% INPUT

% INTRODUCE HERE INPUT AND OUTPUT PATH

inputFileConfigName = 'inputCalConfig.xlsx';

inputFileConfig = readtable(inputFileConfigName);

%Cal Experimental data
filenameExp = inputFileConfig.inputFileName{:};

% PR parameters
% INTRODUCE THE INPUT HERE
% file containing pure components NIST data: Tc, Pc and acentric factor w
filenamePure = inputFileConfig.inputPureParams{:};
% file containing mixture compoents A12 B12 factor to estimate BIP
filenameBIP = inputFileConfig.inputMixParams{:};

pathExportAll = inputFileConfig.exportPath{:}; % Path for OUTPUT
mkdir(pathExportAll); % Create directory for output


%% Import input

addpath('functions/');

filedataExp = import_inputCal(filenameExp); % import input to a local variable

% import pure components NIST data: Tc, Pc and acentric factor w
filedataPure = import_inputPR_params_pure(filenamePure);
% import mixture components A12 and B12 factor to estimate BIP (kij)
filedataBIP = import_inputPR_params_BIP(filenameBIP);

%% Initialize Python for CProP or REFPROP

% % Initialize CProp
% initCoolProp()

% Initialize REFPROP
RP = initREFPROP();

%% Import data

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
                rho_MFM = calProcData.(fluid_cal).(T_unique_field).(P_unique_field(j)).(Q_unique_field(k)).MFMData.dens_MFM2;
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
                rho_mean = mean(MFM_data_aux.dens_MFM2);
                freq_MFM_mean = mean(MFM_data_aux.freq_MFM2);
                    % std for a specific P and Q
                        % pumps data
                P_std = std(pumps_data_aux.P_Pworking);
                Q_std = std(pumps_data_aux.Q_Pworking); 
                        % MFM data      
                T_std = std(MFM_data_aux.T_MFM2);
                Q_MFM_std = std(MFM_data_aux.q_MFM2);
                rho_std = std(MFM_data_aux.dens_MFM2);
                freq_MFM_std = std(MFM_data_aux.freq_MFM2);

                % % Reference density from Peng Robinson model  
                %     % at T mean values
                % [PR_input_T_mean,PR_results_T_mean] = densZ_PR(fluid_cal,1,P_unique_MPa(j),T_mean,filedataPure,filedataBIP);
                % [PR_input_T_max,PR_results_T_max] = densZ_PR(fluid_cal,1,P_unique_MPa(j),T_mean+T_std, filedataPure,filedataBIP); % at Tmax
                % [PR_input_T_min,PR_results_T_min] = densZ_PR(fluid_cal,1,P_unique_MPa(j),T_mean-T_std, filedataPure,filedataBIP); % at Tmin
                %     % Compressibility factor from Peng Robinson T_mean
                % Z_REF_T_mean = PR_results_T_mean.Z;
                % Z_REF_T_max = PR_results_T_max.Z;
                % Z_REF_T_min = PR_results_T_min.Z;
                % Z_REF_T_mean_std = abs(Z_REF_T_max-Z_REF_T_min); % error of Z depending on T
                %     % density from Peng Robinson at T_mean
                % rho_REF_T_mean = PR_results_T_mean.rho;
                % rho_REF_T_max = PR_results_T_max.rho;
                % rho_REF_T_min = PR_results_T_min.rho;
                % rho_REF_T_mean_std = abs(rho_REF_T_max-rho_REF_T_min); % error of rho depending on T

                % Reference density from REFPROP 
                    % at T mean values
                fluidProp_REF_T_mean = getFluidProps_REFPROP(RP,upper(fluid_cal),T_mean+273.15,P_unique_MPa(j)*1000);
                fluidProp_REF_T_max = getFluidProps_REFPROP(RP,upper(fluid_cal),T_mean+T_std+273.15,P_unique_MPa(j)*1000);
                fluidProp_REF_T_min = getFluidProps_REFPROP(RP,upper(fluid_cal),T_mean-T_std+273.15,P_unique_MPa(j)*1000);
                    % Compressibility factor from Peng Robinson T_mean
                Z_REF_T_mean = fluidProp_REF_T_mean.Z;
                Z_REF_T_max = fluidProp_REF_T_max.Z;
                Z_REF_T_min = fluidProp_REF_T_min.Z;
                Z_REF_T_mean_std = abs(Z_REF_T_max-Z_REF_T_min); % error of Z depending on T
                    % density from Peng Robinson at T_mean
                rho_REF_T_mean = fluidProp_REF_T_mean.rho;
                rho_REF_T_max = fluidProp_REF_T_max.rho;
                rho_REF_T_min = fluidProp_REF_T_min.rho;
                rho_REF_T_mean_std = abs(rho_REF_T_max-rho_REF_T_min); % error of rho depending on T
              
                % cal results gathers mean and std
                calResults_temp = table(fluid_cal,T_cal,P_unique(j), Q_unique(k), ...
                    T_mean,T_std, P_mean,P_std, Q_mean,Q_std, Q_MFM_mean,Q_MFM_std, ...
                    rho_mean,rho_std,freq_MFM_mean,freq_MFM_std, ...
                    {TimeStamp_st},{TimeStamp_et}, ...
                    Z_REF_T_mean , Z_REF_T_mean_std, rho_REF_T_mean , rho_REF_T_mean_std, ...
                    'VariableNames',{'Fluid_cal','T_cal_C','P_cal_psig', 'Q_cal_mlmin', ...
                    'T_mean','T_std','P_psig_mean','P_psig_std','Q_mean','Q_std', 'Q_MFM_mean', 'Q_MFM_std', ...
                    'rho_mean','rho_std','freq_MFM_mean','freq_MFM_std', ...
                    'st','et','Z_REF_T_mean','Z_REF_T_mean_std','rho_REF_T_mean','rho_REF_T_mean_std'});
    
                % cal data gathers all punctual data and its mean and cal experiment ref value
                calData_temp = table(repmat(fluid_cal,length(rho_MFM),1), ...
                    repmat(T_cal,length(rho_MFM),1), repmat(P_unique(j),length(rho_MFM),1), ...
                    repmat(Q_unique(k),length(rho_MFM),1), ...
                    Q_MFM,T_MFM, repmat(T_mean,length(rho_MFM),1), repmat(T_std,length(rho_MFM),1), ...
                    rho_MFM, repmat(rho_mean,length(rho_MFM),1), repmat(rho_std,length(rho_MFM),1), ...
                    repmat(Z_REF_T_mean,length(rho_MFM),1), repmat(Z_REF_T_mean_std,length(rho_MFM),1), ...
                    repmat(rho_REF_T_mean,length(rho_MFM),1), repmat(rho_REF_T_mean_std,length(rho_MFM),1), ...
                    'VariableNames',{'Fluid_cal','T_cal_C', 'P_cal_psig', 'Q_cal_mlmin', ...
                    'Q_MFM','T_MFM','T_mean','T_std','rho_MFM','rho_mean','rho_std', ...
                    'Z_REF_T_mean','Z_REF_T_mean_std','rho_REF_T_mean','rho_REF_T_mean_std'});
                
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
        rho_mean = mean(MFM_data_trim_QAll.dens_MFM2);
        freq_MFM_mean = mean(MFM_data_trim_QAll.freq_MFM2);
        % std for a specific P and Q
            % pumps data
        P_std = std(pumps_data_trim_QAll.P_Pworking);
        Q_std = std(pumps_data_trim_QAll.Q_Pworking); 
            % MFM data      
        T_std = std(MFM_data_trim_QAll.T_MFM2);
        Q_MFM_std = std(MFM_data_trim_QAll.q_MFM2);
        rho_std = std(MFM_data_trim_QAll.dens_MFM2);
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
            rho_mean,rho_std,freq_MFM_mean,freq_MFM_std, ...
            {TimeStamp_st},{TimeStamp_et}, ...
            'VariableNames',{'Fluid_cal','T_cal_C','P_cal_psig', 'Q_cal_mlmin', ...
            'T_mean','T_std','P_psig_mean','P_psig_std','Q_mean','Q_std', 'Q_MFM_mean', 'Q_MFM_std', ...
            'rho_mean','rho_std','freq_MFM_mean','freq_MFM_std', ...
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

%% Thermodynamic model for T_MFM and cal data all

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
            T_REF_aux = Tmin:0.1:Tmax;
            P_psig = str2double(P_unique_field{j}(2:end));
            P_MPa = (P_psig + 14.7)*0.00689476;
            Z_REF_T_REF = [];
            rho_REF_T_REF = [];
            for m = 1:length(T_REF_aux)
                % % Using Peng Robinson EoS
                % [PR_input_T_REF_aux,PR_results_T_REF_aux] = densZ_PR(string(fluid_unique{i}),x1,P_MPa,T_REF_aux(m),filedataPure,filedataBIP);
                % % Compressibility factor from Peng Robinson at T_MFM and T_mean
                % Z_REF_T_REF_aux = PR_results_T_REF_aux.Z;
                % % density from Peng Robinson at T_MFM and T_mean
                % rho_REF_T_REF_aux = PR_results_T_REF_aux.rho;        

                % Using REFPROP
                fluidProp_REFPROP = getFluidProps_REFPROP( ...
                    RP,upper(fluid_unique{i}), ...
                    T_REF_aux(m)+273.15,P_MPa*1000);
                Z_REF_T_REF_aux = fluidProp_REFPROP.Z;
                rho_REF_T_REF_aux = fluidProp_REFPROP.rho;

                % Z and rho arrays for each fluid, P, Q and T
                Z_REF_T_REF = [Z_REF_T_REF;Z_REF_T_REF_aux];
                rho_REF_T_REF = [rho_REF_T_REF;rho_REF_T_REF_aux];
            end

            PTXrho_REF = table(repmat(fluid_unique{i},length(T_REF_aux),1), ...
                repmat(P_psig,length(T_REF_aux),1), T_REF_aux', repmat(x1,length(T_REF_aux),1), ...
                Z_REF_T_REF, rho_REF_T_REF, 'VariableNames',{'Fluid_cal', ...
                'P_cal_psig','T_REF', 'x_PR','Z_REF_T_REF', 'rho_REF_T_REF'});
            calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.PTXrho_REF = PTXrho_REF;
                        calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.rho_REF_T_MFM = ...
                interp1(PTXrho_REF.T_REF, PTXrho_REF.rho_REF_T_REF, ...
                calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.T_MFM, 'linear');
            calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.Z_REF_T_MFM = ...
                interp1(PTXrho_REF.T_REF, PTXrho_REF.Z_REF_T_REF, ...
                calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.T_MFM, 'linear');

            % create table with PR_Results QAll
            Z_REF_T_MFM_mean = mean(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.Z_REF_T_MFM);
            Z_REF_T_MFM_std = std(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.Z_REF_T_MFM);
            rho_REF_T_MFM_mean = mean(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.rho_REF_T_MFM);
            rho_REF_T_MFM_std = std(calProcData.(fluid_unique{i}).(T_unique_field{ii}).(P_unique_field{j}).QAll.calData.rho_REF_T_MFM);

            calResultsQAll_PR_temp = table(string(fluid_unique{i}),str2double(T_unique_field{ii}(2:end)),str2double(P_unique_field{j}(2:end)), "QAll", ...
                Z_REF_T_MFM_mean,Z_REF_T_MFM_std, rho_REF_T_MFM_mean,rho_REF_T_MFM_std, ...
                'VariableNames',{'Fluid_cal','T_cal_C','P_cal_psig', 'Q_cal_mlmin', ...
                'Z_REF_T_mean','Z_REF_T_mean_std','rho_REF_T_mean','rho_REF_T_mean_std'});

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

% Linear fitting Q all considering punctual rho at T_MFM and high pressures

Q_unique = unique(vertcat(filedataExp.Q_mlmin{:}));
Q_unique_field = "Q"+ string(Q_unique);
cal_curve_params = {};
cal_curve_params_Qeach = {};
fittingRhoResultsAll = table('Size',[0 5],'VariableTypes', ...
    {'string','double','double','double','double'},'VariableNames',{'Q','p1','p2','RMSE','drho_corr'});
% fitting for each Q
% take only High Pressure Data
calData_aux = calData(calData.P_cal_psig > 400,:);
for k = 1:length(Q_unique)
    cal_curve_params_Qeach_aux = fitlm ...
        (calData_aux.rho_REF_T_MFM(calData_aux.Q_cal_mlmin == Q_unique(k)), ...
        calData_aux.rho_MFM(calData_aux.Q_cal_mlmin == Q_unique(k)));
    % Add Fitting Qeach to table fittingRhoResultsAll
    cal_curve_params_Qeach{end+1} = cal_curve_params_Qeach_aux;
    fittingRhoResultsAll(k,:) = {Q_unique_field{k}, ...
        cal_curve_params_Qeach_aux.Coefficients.Estimate(1), ...
        cal_curve_params_Qeach_aux.Coefficients.Estimate(2), ...
        cal_curve_params_Qeach_aux.RMSE, ...
        cal_curve_params_Qeach_aux.RMSE/cal_curve_params_Qeach_aux.Coefficients.Estimate(2)};
end
% Fitting for all Qs
cal_curve_params_Qall = fitlm(calData_aux.rho_REF_T_MFM,calData_aux.rho_MFM);
% Add Fitting QAll to table fittingRhoResultsAll
cal_curve_params = {cal_curve_params_Qeach;cal_curve_params_Qall};
fittingRhoResultsAll(length(Q_unique)+1,:) = {"QAll", ...
        cal_curve_params_Qall.Coefficients.Estimate(1), ...
        cal_curve_params_Qall.Coefficients.Estimate(2), ...
        cal_curve_params_Qall.RMSE, ...
        cal_curve_params_Qall.RMSE/cal_curve_params_Qall.Coefficients.Estimate(2)};

% save fittingRhoResultsAll
writetable(fittingRhoResultsAll,pathExportAll + "fittingRhoResultsAll.xlsx");
save(pathExportAll + "cal_curve_params.mat",'cal_curve_params');
save(pathExportAll + "fittingRhoResultsAll.mat",'fittingRhoResultsAll')

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
        (calData_aux.rho_REF_T_MFM(calData_aux.Q_cal_mlmin == Q_unique(k)), ...
        calData_aux.rho_MFM(calData_aux.Q_cal_mlmin == Q_unique(k)),rho_MFM,pinit);
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
        ((1/(cal_curve_params_Qeach_aux.Coefficients.Estimate(2)))*(cal_curve_params_Qeach_aux.RMSE^2))^(1/2), ...
        ((1/(cal_curve_params_Qeach_aux.Coefficients.Estimate(2)+cal_curve_params_Qeach_aux.Coefficients.Estimate(3)))*(cal_curve_params_Qeach_aux.RMSE^2))^(1/2)};
end
% Fitting for all Qs
nl_cal_curve_params_Qall = fitnlm(calData_aux.rho_REF_T_MFM,calData_aux.rho_MFM,rho_MFM,pinit);
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

%% Density cal plot all densitites (all fluids, temperatures and pressures)
% linear
calData_aux = calData(calData.P_cal_psig > 400,:);

figure
set(gcf, 'Position', [100, 100, 700, 550])
ax1 = axes;
rho_ref_0 = fittingRhoResultsAll.p1(fittingRhoResultsAll.Q == "QAll");
drho_MFM = fittingRhoResultsAll.RMSE(fittingRhoResultsAll.Q == "QAll");
step = 1;
errorbar(0:step:rho_ref_0,feval(cal_curve_params_Qall,0:step:rho_ref_0),drho_MFM,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
hold on
errorbar(rho_ref_0:step:800,feval(cal_curve_params_Qall,rho_ref_0:step:800),drho_MFM,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
scatter(calData_aux.rho_REF_T_MFM,calData_aux.rho_MFM,20,calData_aux.T_MFM,'filled','DisplayName','Measured density')
plot(0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k','DisplayName','Linear calibration curve') % fitting responds to high pressure only
xlabel('\rho_{ref} [kg/m^{3}]', 'FontSize', 14);
ylabel('\rho_{MFM} [kg/m^{3}]','FontSize', 14);
xlim([0 800]);
ylim([0 800]);
xticks(0:100:800)
yticks(0:100:800)
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
title("Calibration curve - HP cal fluids P and T - linear")
saveas(gcf,pathExportAll + "Cal-all-HP400+-l",'png')

%% Density cal plot all densitites (all fluids, temperatures and pressures)
% non linear
calData_aux = calData(calData.P_cal_psig > 400,:);
figure;
set(gcf, 'Position', [100, 100, 700, 550])
ax1 = axes;
rho_ref_0 = nlfittingRhoResultsAll.p4(nlfittingRhoResultsAll.Q == "QAll");
drho_MFM = nlfittingRhoResultsAll.RMSE(nlfittingRhoResultsAll.Q == "QAll");
drho_corr_low = nlfittingRhoResultsAll.drho_corr_low(nlfittingRhoResultsAll.Q == "QAll");
drho_corr_high = nlfittingRhoResultsAll.drho_corr_high(nlfittingRhoResultsAll.Q == "QAll");
step = 1;
%error bar low dens
errorbar(0:step:rho_ref_0,feval(nl_cal_curve_params_Qall,0:step:rho_ref_0),drho_MFM,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
hold on 
errorbar(rho_ref_0:step:800,feval(nl_cal_curve_params_Qall,rho_ref_0:step:800),drho_MFM,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
scatter(calData_aux.rho_REF_T_MFM,calData_aux.rho_MFM,20,calData_aux.T_MFM,'filled')
plot(0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k','LineWidth',0.8) % fitting responds to high pressure only
xlabel('\rho_{ref} [kg/m^{3}]', 'FontSize', 14);
ylabel('\rho_{MFM} [kg/m^{3}]', 'FontSize', 14);
xlim([0 800]);
ylim([0 800]);
xticks(0:100:800)
yticks(0:100:800)
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
title("Calibration curve - HP cal fluids P and T - non linear")
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

%% All fluids, highest pressures, linear zoom in

% three different fluids H2, He, CO2 for paper! High pressure = 1500 psig, Tref = 32C
calData_aux = calData(calData.P_cal_psig > 400,:);

figure;
set(gcf, 'Position', [100, 100, 700, 550])
ax1 = axes;
axPos = ax1.Position;
xlim([0 900]);
ylim([0 900]);
% references
rho_ref_0 = fittingRhoResultsAll.p1(fittingRhoResultsAll.Q == "QAll");
drho_MFM = fittingRhoResultsAll.RMSE(fittingRhoResultsAll.Q == "QAll");
rho_MFM_0 = predict(cal_curve_params_Qall,rho_ref_0);
step = 1;
xNorm = axPos(1) + (rho_ref_0-ax1.XLim(1))/diff(ax1.XLim)*axPos(3);
yNorm = axPos(2) + (rho_MFM_0-ax1.YLim(1))/diff(ax1.YLim)*axPos(4);
% plots
%error bar low dens
errorbar(0:step:rho_ref_0,feval(cal_curve_params_Qall,0:step:rho_ref_0),drho_MFM,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
hold on 
errorbar(rho_ref_0:step:800,feval(cal_curve_params_Qall,rho_ref_0:step:800),drho_MFM,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
scatter(calData_aux.rho_REF_T_MFM,calData_aux.rho_MFM,20,calData_aux.T_MFM,'filled')
hold on
plot(0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k','LineWidth',0.8) % fitting responds to high pressure only
xlabel('\rho_{ref} [kg/m^{3}]', 'FontSize', 14);
ylabel('\rho_{MFM} [kg/m^{3}]', 'FontSize', 14);
xticks(0:100:800)
yticks(0:100:800)
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
legend({'\rho_{MFM}','\rho_{MFM_{fit}} \pm \Delta\rho_{MFM_{fit}}'},'Location','southeast','FontSize', 14)
% cal curve formula annotation
coeffs = fittingRhoResultsAll(fittingRhoResultsAll.Q == 'QAll',:);
annotText = sprintf('$\\rho_{MFM}=%.2f+(%.3f)\\rho_{Ref}$',coeffs.p1, coeffs.p2);
annotation('textbox', [0.16, 0.1, 0.3, 0.1], 'String', annotText, ...
    'Interpreter', 'latex', 'FontSize', 11, 'EdgeColor', 'none');

%H2
insetAx = axes('Position', [0.18 0.65 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'H2');
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'H2');
z = calData_aux.T_MFM(calData_aux.Fluid_cal == 'H2');
scatter(insetAx,x,y,15,z,'filled')
hold on
plot(insetAx,0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'H_2 @ T_{MFM}', ...
        'P = 3.5, 6.3, 10.4 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on

% He
insetAx = axes('Position', [0.34 0.65 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'He');
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'He');
z = calData_aux.T_MFM(calData_aux.Fluid_cal == 'He');
scatter(insetAx,x,y,15,z,'filled')
hold on
plot(insetAx,0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'He @ T_{MFM}', ...
        'P = 3.5, 6.3, 10.4 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on

% CO2
insetAx = axes('Position', [0.18 0.41 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
xplot = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2');
yplot = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2');
zplot = calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2');
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 500);
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 500);
scatter(insetAx,xplot,yplot,15,zplot,'filled')
hold on
plot(insetAx,0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'CO_2 @ T_{MFM}', ...
        'P = 3.5 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on

% CO2
insetAx = axes('Position', [0.54 0.33 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
xplot = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2');
yplot = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2');
zplot = calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2');
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 900);
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 900);
scatter(insetAx,xplot,yplot,15,zplot,'filled')
hold on
plot(insetAx,0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'CO_2 @ T_{MFM}', ...
        'P = 6.3 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on

% CO2
insetAx = axes('Position', [0.68 0.33 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
xplot = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2');
yplot = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2');
zplot = calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2');
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 1500);
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 1500);
scatter(insetAx,xplot,yplot,15,zplot,'filled')
hold on
plot(insetAx,0:1:800,feval(cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'CO_2 @ T_{MFM}', ...
        'P = 10.4 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);

grid on
saveas(gcf,pathExportAll + "Cal-curve-lin-zoom-in",'png')

%% All fluids, highest pressures, non linear zoom in

% three different fluids H2, He, CO2 for paper! High pressure = 1500 psig, Tref = 32C
calData_aux = calData(calData.P_cal_psig > 400,:);

figure;
set(gcf, 'Position', [100, 100, 700, 550])
ax1 = axes;
axPos = ax1.Position;
xlim([0 900]);
ylim([0 900]);
% references
rho_ref_0 = nlfittingRhoResultsAll.p4(nlfittingRhoResultsAll.Q == "QAll");
drho_MFM = nlfittingRhoResultsAll.RMSE(nlfittingRhoResultsAll.Q == "QAll");
drho_corr_low = nlfittingRhoResultsAll.drho_corr_low(nlfittingRhoResultsAll.Q == "QAll");
drho_corr_high = nlfittingRhoResultsAll.drho_corr_high(nlfittingRhoResultsAll.Q == "QAll");
rho_MFM_0 = predict(nl_cal_curve_params_Qall,rho_ref_0);
step = 1;
xNorm = axPos(1) + (rho_ref_0-ax1.XLim(1))/diff(ax1.XLim)*axPos(3);
yNorm = axPos(2) + (rho_MFM_0-ax1.YLim(1))/diff(ax1.YLim)*axPos(4);
% plots
%error bar low dens
errorbar(0:step:rho_ref_0,feval(nl_cal_curve_params_Qall,0:step:rho_ref_0),drho_MFM,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
hold on 
errorbar(rho_ref_0:step:800,feval(nl_cal_curve_params_Qall,rho_ref_0:step:800),drho_MFM,'LineStyle', 'none', ...
    'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
scatter(calData_aux.rho_REF_T_MFM,calData_aux.rho_MFM,20,calData_aux.T_MFM,'filled')
hold on
plot(0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k','LineWidth',0.8) % fitting responds to high pressure only
plot([0,rho_ref_0],[rho_MFM_0,rho_MFM_0],'--','Color','k','LineWidth',1.0);
plot([rho_ref_0,rho_ref_0],[0,rho_MFM_0],'--','Color','k','LineWidth',1.0);
% annotations
annotText1 = sprintf('{%.1f} kg/m^{3}', rho_MFM_0);
annotText2 = sprintf('{%.1f} kg/m^{3}', rho_ref_0);
annotation('textbox', [axPos(1), yNorm+0.02, 0.2, 0.05], 'String', annotText1, ...
    'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none');
annotation('textbox', [xNorm+0.025, axPos(2) + 0.015, 0.2, 0.05], 'String', annotText2, ...
    'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','Rotation',90);
xlabel('\rho_{ref} [kg/m^{3}]', 'FontSize', 14);
ylabel('\rho_{MFM} [kg/m^{3}]', 'FontSize', 14);
xticks(0:100:800)
yticks(0:100:800)
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
legend({'\rho_{MFM}','\rho_{MFM_{fit}} \pm \Delta\rho_{MFM_{fit}}'},'Location','southeast','FontSize', 14)
% % cal curve formula annotation
% coeffs = nlfittingRhoResultsAll(nlfittingRhoResultsAll.Q == 'QAll',:);
% annotText = sprintf(['$\\rho_{MFM} = \\left\\{ \\begin{array}{ll}',...
%     '%.2f + %.3f\\rho_{Ref}, & \\rho_{Ref} \\le %.2f \\\\',...
%     '%.2f + %.3f\\rho_{Ref}, & \\rho_{Ref} > %.2f',...
%     '\\end{array} \\right.$'], coeffs.p1, coeffs.p2, coeffs.p4, coeffs.n2, coeffs.p3, coeffs.p4);
% annotation('textbox', [0.34, 0.25, 0.3, 0.1], 'String', annotText, ...
%     'Interpreter', 'latex', 'FontSize', 11, 'EdgeColor', 'none');

%H2
insetAx = axes('Position', [0.18 0.65 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'H2');
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'H2');
z = calData_aux.T_MFM(calData_aux.Fluid_cal == 'H2');
scatter(insetAx,x,y,15,z,'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'H_2 @ T_{MFM}', ...
        'P = 3.5, 6.3, 10.4 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on

% He
insetAx = axes('Position', [0.34 0.65 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'He');
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'He');
z = calData_aux.T_MFM(calData_aux.Fluid_cal == 'He');
scatter(insetAx,x,y,15,z,'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'He @ T_{MFM}', ...
        'P = 3.5, 6.3, 10.4 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on

% CO2
insetAx = axes('Position', [0.18 0.41 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
xplot = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2');
yplot = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2');
zplot = calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2');
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 500);
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 500);
scatter(insetAx,xplot,yplot,15,zplot,'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'CO_2 @ T_{MFM}', ...
        'P = 3.5 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on

annotText3 = sprintf('Insets \\rho_{ref} %s %.1f kg/m^{3}', char(8804),rho_ref_0);
annotation('textbox', [0.21, 0.81, 0.3, 0.1], 'String', annotText3, ...
    'FontSize', 9, 'FontWeight', 'bold','EdgeColor', 'none');

% CO2
insetAx = axes('Position', [0.54 0.33 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
xplot = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2');
yplot = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2');
zplot = calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2');
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 900);
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 900);
scatter(insetAx,xplot,yplot,15,zplot,'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'CO_2 @ T_{MFM}', ...
        'P = 6.3 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);
grid on

% CO2
insetAx = axes('Position', [0.68 0.33 0.1 0.15]);  % [x y width height]
limScale = (insetAx.Position(3)/insetAx.Position(4))/((range(ax1.XLim)*ax1.Position(3))/(range(ax1.YLim)*ax1.Position(4)));
box(insetAx, 'on');  % Add border to inset
xplot = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2');
yplot = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2');
zplot = calData_aux.T_MFM(calData_aux.Fluid_cal == 'CO2');
x = calData_aux.rho_REF_T_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 1500);
y = calData_aux.rho_MFM(calData_aux.Fluid_cal == 'CO2' & calData_aux.P_cal_psig == 1500);
scatter(insetAx,xplot,yplot,15,zplot,'filled')
hold on
plot(insetAx,0:1:800,feval(nl_cal_curve_params_Qall,0:1:800),"Color",'k')
xPad = 0.2*range(x);
xmin = min(x) - xPad;
xmax = max(x) + xPad;
xRange = xmax - xmin;
yCenter = mean(y);
xlim([xmin xmax])
ylim([yCenter - xRange/(2*limScale),yCenter + xRange/(2*limScale)])
title({ 'CO_2 @ T_{MFM}', ...
        'P = 10.4 MPa' }, ...
      'Interpreter','tex', 'FontSize',8);

annotText4 = sprintf('Insets \\rho_{ref} > %.1f kg/m^{3}',rho_ref_0);
annotation('textbox', [0.56, 0.49, 0.3, 0.1], 'String', annotText4, ...
    'FontSize', 9, 'FontWeight', 'bold','EdgeColor', 'none');

grid on
saveas(gcf,pathExportAll + "Cal-curve-nonlin-zoom-in",'png')
