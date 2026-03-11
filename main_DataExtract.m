% main_DataExtract.m
% Author: Ianna Gomez Mendez
%
% Objective: Extract data collected during core flooding experiments
% using 3 Quizix pumps, 1 mass flow meter Bronkhorst, 2 transducers Omega
% and 2 portable gas detectors Cosmos (DOD Technologies)
% The only mandatory data is pumps and MFM data
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
% 3 - Estimate xi error
% 4 - Export in Results one Excel for each experiment with all data in each
% spreadsheet
% 5 - Plot in one figure all vars (5 panels): vars included:PT1, PT2 P
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

% PR parameters
% INTRODUCE THE INPUT HERE
% file containing pure components NIST data: Tc, Pc and acentric factor w
filenamePure = 'input/input_PR_pure.xlsx';
% file containing mixture compoents A12 B12 factor to estimate BIP
filenameBIP = 'input/input_PR_BIP.xlsx';

% cal curve results input import
pathImportCal = 'results/cal_250725_PR/';

mkdir('results/exp_H2-CO2-T32-P1500-H');
pathExportAll = 'results/exp_H2-CO2-T32-P1500-H/';

%% IMPORT data

filedataExp = import_inputExp(filenameExp); % import input to a local variable

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
    
    % pumps in local variables
    workingPump = filedataExp.workingPump(i);
    cushionPump = filedataExp.cushionPump(i);
    confPump = filedataExp.confiningPump(i);
    
    
    if ismissing(pumps_data_name) == 0
        pumps_data = import_pumps_data(pumps_data_name, workingPump, confPump, cushionPump); % import pumps data to local variable
        % Trim data to st and et
        expProcData.(filedataExp.Key(i)).pumpsData = pumps_data ...
            ((pumps_data.TimeStamp>=filedataExp.st(i))& ...
            (pumps_data.TimeStamp<=filedataExp.et(i)),:); % import pumps data from st (start time) to et (end time) to struct.Key
        % Calculate time elapsed
        expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed = expProcData.(filedataExp.Key(i)).pumpsData.TimeStamp - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed.Format = 'hh:mm:ss.SSS';
        % Calculate vol injected
        expProcData.(filedataExp.Key(i)).pumpsData.VolInjected = expProcData.(filedataExp.Key(i)).pumpsData.V_P1 - expProcData.(filedataExp.Key(i)).pumpsData.V_P1(1);
    end

    if ismissing(MFM_data_name) == 0
        MFM_data = import_MFM_data(MFM_data_name); % import MFM2 data to local variable
        % Trim data to st and et
        expProcData.(filedataExp.Key(i)).MFMData = MFM_data ...
            ((MFM_data.TimeStamp>=filedataExp.st(i))& ...
            (MFM_data.TimeStamp<=filedataExp.et(i)),:); % import MFM2 data from st (start time) to et (end time) to struct.Key
        % Calculate time elapsed
        expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed = expProcData.(filedataExp.Key(i)).MFMData.TimeStamp - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed.Format = 'hh:mm:ss.SSS';
    end

    if ismissing(trans_data_name) == 0
        trans_data = import_trans_data(trans_data_name); % import p transducer data to local variable
         % Trim data to st and et
        expProcData.(filedataExp.Key(i)).transData = trans_data ...
            ((trans_data.TimeStamp_PT1>=filedataExp.st(i))& ...
            (trans_data.TimeStamp_PT1<=filedataExp.et(i)),:); % import p trans data from st (start time) to et (end time) to struct.Key
        % Calculate time elapsed
        expProcData.(filedataExp.Key(i)).transData.TimeElapsed = expProcData.(filedataExp.Key(i)).transData.TimeStamp_PT1 - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).transData.TimeElapsed.Format = 'hh:mm:ss.SSS';
    end

    if ismissing(PGD1_data_name) == 0
        PGD1_data = import_PGD1_data(PGD1_data_name); % import PGD1 data to local variable
        % Change time if other GMT
        if filedataExp.GMT_PGD{i} == "GMT9"
            PGD1_data.TimeStamp = PGD1_data.TimeStamp - hours(13); %ONLY if PGD in Japan time GMT+9    
        end
        % Trim data to st and et
        expProcData.(filedataExp.Key(i)).PGD1Data = PGD1_data ...
            ((PGD1_data.TimeStamp>=filedataExp.st(i))& ...
            (PGD1_data.TimeStamp<=filedataExp.et(i)),:); % import PGD1 data from st (start time) to et (end time) to struct.Key
        % Calculate time elapsed
        expProcData.(filedataExp.Key(i)).PGD1Data.TimeElapsed = expProcData.(filedataExp.Key(i)).PGD1Data.TimeStamp - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).PGD1Data.TimeElapsed.Format = 'hh:mm:ss.SSS';
        % C1 in vol concentration % and mol concentration % (atmospheric conditions)
        expProcData.(filedataExp.Key(i)).PGD1Data.C1 = expProcData.(filedataExp.Key(i)).PGD1Data.H2GasConcentration;
    end

    if ismissing(PGD2_data_name) == 0
        PGD2_data = import_PGD2_data(PGD2_data_name); % import PGD1 data to local variable
        % Change time if other GMT
        if filedataExp.GMT_PGD{i} == "GMT9"
            PGD2_data.TimeStamp = PGD2_data.TimeStamp - hours(13); %ONLY if PGD in Japan time GMT+9    
        end
        % Trim data to st and et
        expProcData.(filedataExp.Key(i)).PGD2Data = PGD2_data ...
            ((PGD2_data.TimeStamp>=filedataExp.st(i))& ...
            (PGD2_data.TimeStamp<=filedataExp.et(i)),:); % import PGD2 data from st (start time) to et (end time) to struct.Key
        % Calculate time elapsed
        expProcData.(filedataExp.Key(i)).PGD2Data.TimeElapsed = expProcData.(filedataExp.Key(i)).PGD2Data.TimeStamp - filedataExp.st(i);
        expProcData.(filedataExp.Key(i)).PGD2Data.TimeElapsed.Format = 'hh:mm:ss.SSS';
        % C2 in vol concentration and mol concentration (atmospheric conditions)
        expProcData.(filedataExp.Key(i)).PGD2Data.C2 = expProcData.(filedataExp.Key(i)).PGD2Data.CO2GasConcentration;
        % Because binary mixture: C1 in vol concentration % and mol concentration % (atmospheric conditions)
        expProcData.(filedataExp.Key(i)).PGD2Data.C1 = 100 - expProcData.(filedataExp.Key(i)).PGD2Data.C2;
    end

    A = pi*((filedataExp.D(i)*0.0254)/2)^2; %m2
    L = filedataExp.L(i)*0.0254; % m
    q = filedataExp.Q(i)*(10^(-6))/60; %m3/s
    v = q./A; % Darcy velocity m/s
    u = v./filedataExp.phi(i); % Interstitial velocity

    exp_params = table(filedataExp.Key(i), filedataExp.Date(i), filedataExp.Type(i), filedataExp.Fluid1(i), ...
        filedataExp.Fluid2(i), filedataExp.T(i), filedataExp.P(i), filedataExp.Q(i), filedataExp.Run(i), ...
        filedataExp.D(i), filedataExp.L(i), filedataExp.phi(i), filedataExp.K(i), filedataExp.Vcore(i), ...
        filedataExp.setupVersion(i), filedataExp.Vlinesbefore(i), filedataExp.Vlinesafter(i), ... 
        filedataExp.Vtotal(i), A,L,q,v,u, 'VariableNames', {'Key', 'Date', 'Type','Fluid1', 'Fluid2', ...
        'T_C', 'P_C', 'Q_mlmin', 'Run', 'D_in', 'L_in', 'phi', 'K_mD', 'Vcore_cc', ...
        'setupVersion', 'Vlinesbefore_cc', 'Vlinesafter_cc', 'Vtotal_cc','A_SI','L_SI','q_SI','v_SI','u_SI'});
    expProcData.(filedataExp.Key(i)).exp_params = exp_params;

end

load(pathImportCal + "fittingRhoResultsAll.mat")
load(pathImportCal + "nlfittingRhoResultsAll.mat")
load(pathImportCal + "nlQfittingRhoResultsAll.mat")

%% Extract breakthrough curve data

%rho_corr_lin function
rho_corr_lin = @(p,y) (y-p(1))/p(2);

% rho_corr_nl function second part
rho_corr_nlin = @(p,rho_MFM) (rho_MFM-p(1)+(p(3)-p(2))*p(4))/p(3);

for i = 1:length(filedataExp.Key)
    % Extrat measured density vs time
    BTaux = table(expProcData.(filedataExp.Key(i)).MFMData.TimeStamp, ...
        expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed, ...
        seconds(expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed), ...
        expProcData.(filedataExp.Key(i)).MFMData.dens_MFM2, ...
        expProcData.(filedataExp.Key(i)).MFMData.T_MFM2, ...
        expProcData.(filedataExp.Key(i)).MFMData.q_MFM2, ...
        'VariableNames',{'TimeStamp','TimeElapsed', 'SecondsElapsed', 'rho_MFM','T_MFM','q_MFM'});
    expProcData.(filedataExp.Key(i)).BT = BTaux;
    % fitting parameters for rho corrected
    % auxLinFit = fittingRhoResultsAll(fittingRhoResultsAll.Q == "QAll",:);
    auxnLinFit = nlfittingRhoResultsAll(nlfittingRhoResultsAll.Q == "QAll",:);
    rho_MFM_0 = rho_corr_lin([auxnLinFit.p1,auxnLinFit.p2],auxnLinFit.p4);
    rho_MFM = expProcData.(filedataExp.Key(i)).BT.rho_MFM;
    % lower slope
    expProcData.(filedataExp.Key(i)).BT.rho_corr = rho_corr_lin([auxnLinFit.p1,auxnLinFit.p2],rho_MFM);
    expProcData.(filedataExp.Key(i)).BT.rho_corrMin = rho_corr_lin([auxnLinFit.p1,auxnLinFit.p2],rho_MFM-auxnLinFit.RMSE);
    expProcData.(filedataExp.Key(i)).BT.rho_corrMax = rho_corr_lin([auxnLinFit.p1,auxnLinFit.p2],rho_MFM+auxnLinFit.RMSE);
    % higher slope
    expProcData.(filedataExp.Key(i)).BT.rho_corr(rho_MFM>rho_MFM_0) = ...
        rho_corr_nlin([auxnLinFit.p1,auxnLinFit.p2,auxnLinFit.p3,auxnLinFit.p4], ...
        rho_MFM(rho_MFM>rho_MFM_0));
    expProcData.(filedataExp.Key(i)).BT.rho_corrMin(rho_MFM>rho_MFM_0) = ...
        rho_corr_nlin([auxnLinFit.p1,auxnLinFit.p2,auxnLinFit.p3,auxnLinFit.p4], ...
        rho_MFM(rho_MFM>rho_MFM_0)-auxnLinFit.RMSE);
    expProcData.(filedataExp.Key(i)).BT.rho_corrMax(rho_MFM>rho_MFM_0) = ...
        rho_corr_nlin([auxnLinFit.p1,auxnLinFit.p2,auxnLinFit.p3,auxnLinFit.p4], ...
        rho_MFM(rho_MFM>rho_MFM_0)+auxnLinFit.RMSE);
end

%% Extract breakthrough curve data

%rho_corr_lin function
rho_corr_lin = @(p,y) (y(:,1)-(y(:,2).^(p(3))).*p(1))./p(2);

% rho_corr_nl function second part
rho_corr_nlin = @(p,y) (y(:,1)-(y(:,2).^(p(5))).*p(1)+(p(3)-p(2)).*p(4))./p(3);

for i = 1:length(filedataExp.Key)
    Q = filedataExp.Q(i);
    % Extrat measured density vs time
    BTaux = table(expProcData.(filedataExp.Key(i)).MFMData.TimeStamp, ...
        expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed, ...
        seconds(expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed), ...
        expProcData.(filedataExp.Key(i)).MFMData.dens_MFM2, ...
        expProcData.(filedataExp.Key(i)).MFMData.T_MFM2, ...
        expProcData.(filedataExp.Key(i)).MFMData.q_MFM2, ...
        'VariableNames',{'TimeStamp','TimeElapsed', 'SecondsElapsed', 'rho_MFM','T_MFM','q_MFM'});
    expProcData.(filedataExp.Key(i)).BT = BTaux;
    % fitting parameters for rho corrected
    % auxLinFit = fittingRhoResultsAll(fittingRhoResultsAll.Q == "QAll",:);
    auxnLinQFit = nlQfittingRhoResultsAll(nlQfittingRhoResultsAll.Q == "QAll",:);
    rho_MFM_0 = rho_corr_lin([auxnLinQFit.p1,auxnLinQFit.p2,auxnLinQFit.p5],[auxnLinQFit.p4,Q]);
    rho_MFM = expProcData.(filedataExp.Key(i)).BT.rho_MFM;
    % lower slope
    expProcData.(filedataExp.Key(i)).BT.rho_corr = rho_corr_lin([auxnLinQFit.p1,auxnLinQFit.p2,auxnLinQFit.p5],[rho_MFM,repmat(Q,length(rho_MFM),1)]);
    expProcData.(filedataExp.Key(i)).BT.rho_corrMin = rho_corr_lin([auxnLinQFit.p1,auxnLinQFit.p2,auxnLinQFit.p5],[rho_MFM-auxnLinQFit.RMSE,repmat(Q,length(rho_MFM),1)]);
    expProcData.(filedataExp.Key(i)).BT.rho_corrMax = rho_corr_lin([auxnLinQFit.p1,auxnLinQFit.p2,auxnLinQFit.p5],[rho_MFM+auxnLinQFit.RMSE,repmat(Q,length(rho_MFM),1)]);
    % higher slope
    expProcData.(filedataExp.Key(i)).BT.rho_corr(rho_MFM>rho_MFM_0) = ...
        rho_corr_nlin([auxnLinQFit.p1,auxnLinQFit.p2,auxnLinQFit.p3,auxnLinQFit.p4,auxnLinQFit.p5], ...
        [rho_MFM(rho_MFM>rho_MFM_0),repmat(Q,length(rho_MFM(rho_MFM>rho_MFM_0)),1)]);
    expProcData.(filedataExp.Key(i)).BT.rho_corrMin(rho_MFM>rho_MFM_0) = ...
        rho_corr_nlin([auxnLinQFit.p1,auxnLinQFit.p2,auxnLinQFit.p3,auxnLinQFit.p4,auxnLinQFit.p5], ...
        [rho_MFM(rho_MFM>rho_MFM_0)-auxnLinQFit.RMSE,repmat(Q,length(rho_MFM(rho_MFM>rho_MFM_0)),1)]);
    expProcData.(filedataExp.Key(i)).BT.rho_corrMax(rho_MFM>rho_MFM_0) = ...
        rho_corr_nlin([auxnLinQFit.p1,auxnLinQFit.p2,auxnLinQFit.p3,auxnLinQFit.p4,auxnLinQFit.p5], ...
        [rho_MFM(rho_MFM>rho_MFM_0)+auxnLinQFit.RMSE, repmat(Q,length(rho_MFM(rho_MFM>rho_MFM_0)),1)]);
end
%% Add molar concentration to breakthrough data and error

x1 = 0:0.01:1; % array for binary mixture
for i = 1:length(filedataExp.Key)
    fluidPair = [filedataExp.Fluid1(i),filedataExp.Fluid2(i)];
    Tmin = floor(min(expProcData.(filedataExp.Key(i)).BT.T_MFM)*10)/10;
    Tmax = ceil(max(expProcData.(filedataExp.Key(i)).BT.T_MFM)*10)/10;
    T_PR_aux = Tmin:0.1:Tmax;
    P_psig = filedataExp.P(i);
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
    expProcData.(filedataExp.Key(i)).BT.Ci = ...
        100*scatInterp(expProcData.(filedataExp.Key(i)).BT.T_MFM, ...
        expProcData.(filedataExp.Key(i)).BT.rho_corr);
    % at rho min value
    expProcData.(filedataExp.Key(i)).BT.CiMax = ...
        100*scatInterp(expProcData.(filedataExp.Key(i)).BT.T_MFM, ...
        expProcData.(filedataExp.Key(i)).BT.rho_corrMin);
    % at rho max value
    expProcData.(filedataExp.Key(i)).BT.CiMin = ...
        100*scatInterp(expProcData.(filedataExp.Key(i)).BT.T_MFM, ...
        expProcData.(filedataExp.Key(i)).BT.rho_corrMax);
    % absolute error % 
    expProcData.(filedataExp.Key(i)).BT.dC = ...
        abs(expProcData.(filedataExp.Key(i)).BT.CiMax ...
        -expProcData.(filedataExp.Key(i)).BT.CiMin);
end

%% Save data

for i = 1:length(filedataExp.Key)
    delete(pathExportAll + filedataExp.Key(i) + '.xlsx')

    writetable(expProcData.(filedataExp.Key(i)).pumpsData,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'pumps_data');
    writetable(expProcData.(filedataExp.Key(i)).transData,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'trans_data');
    writetable(expProcData.(filedataExp.Key(i)).MFMData,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'MFM_data');
    writetable(expProcData.(filedataExp.Key(i)).PGD1Data,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'PGD1_data');
    writetable(expProcData.(filedataExp.Key(i)).PGD2Data,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'PGD2_data');
    writetable(expProcData.(filedataExp.Key(i)).exp_params,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'exp_params');
    writetable(expProcData.(filedataExp.Key(i)).BT,pathExportAll + filedataExp.Key(i) + '.xlsx', 'Sheet', 'BT_curve');
    save(pathExportAll + "expProcData.mat",'expProcData')
end

%% Plots for analysis

% Subplot all in 5 panels
for i = 1:length(filedataExp.Key)
    
    pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD2_data_name(i);

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
        scatter(expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed,expProcData.(filedataExp.Key(i)).pumpsData.P_Pconf,10,'filled','DisplayName','Pconf')
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
        scatter(expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed,expProcData.(filedataExp.Key(i)).pumpsData.Q_Pworking,10,'filled','DisplayName','q_{pump}')
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
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.rho_corr,10,'filled','MarkerFaceColor','r')
    hold on
    xlabel('Time elapsed [hh:mm:ss]')
    xtickformat('hh:mm:ss')
    ylabel('\rho_{corr} [kg/m^{3}]');
    yyaxis right
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('Temperature [°C]');
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.T_MFM,10,'filled', 'MarkerFaceColor',[0.9290, 0.6940, 0.1250])
    legend('\rho_{corr}','T_{MFM}', 'Location','southeast');
    title(filedataExp.Key(i) + " density and temperature", 'Interpreter', 'none')
    grid on;

    subplot(5,1,5);
    yyaxis left
    ax = gca;
    ax.YColor = [0 0 0];
    ylabel('C1_{PGDs} [mol %]');
    ylim([0,100])
    hold on
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
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.Ci,10,'filled','MarkerFaceColor','r','DisplayName','C1_{MFM}')
    hold on
    xlabel('Time elapsed [hh:mm:ss]')
    xtickformat('hh:mm:ss')
    ylabel('C1_{MFM} [mol %]');
    ylim([0,100])
    legend('Location','southeast');
    title(filedataExp.Key(i) + " molar concentrations", 'Interpreter', 'none')
    grid on;

    saveas(gcf,pathExportAll + filedataExp.Key(i) + "_BT_All_Vars",'png')
end

%% Plot concentration molar all together
for i = 1:length(filedataExp.Key)
    pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);
    trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
    MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
    PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    PGD2_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    % Densities and concentrations PGD
    figure('Position', [100, 100, 700, 550]);
    tiledlayout(2,2, 'TileSpacing', 'tight', 'Padding','tight');
    if isempty(expProcData.(filedataExp.Key(i)).MFMData) == 0 && ismissing(MFM_data_name) == 0
        t = expProcData.(filedataExp.Key(i)).BT.TimeElapsed;
        C1 = expProcData.(filedataExp.Key(i)).BT.Ci;
        C1min = expProcData.(filedataExp.Key(i)).BT.CiMin;
        C1max = expProcData.(filedataExp.Key(i)).BT.CiMax;
        errorbar(t, C1, C1-C1min, C1max - C1, 'LineStyle', 'none', 'Color', [1 0.7 0.8])
        hold on 
        h3 = scatter(t,C1,5,'filled','MarkerFaceColor','r','DisplayName','C_{MFM} \pm \DeltaC_{MFM}');
    end
    if isempty(expProcData.(filedataExp.Key(i)).PGD2Data) == 0 && ismissing(PGD2_data_name) == 0
        h1 = scatter(expProcData.(filedataExp.Key(i)).PGD2Data.TimeElapsed,expProcData.(filedataExp.Key(i)).PGD2Data.C1,5,'filled','MarkerFaceColor',[0.7 0.7 0.7],'DisplayName','C_{PGD2}');
        hold on 
    end
    if isempty(expProcData.(filedataExp.Key(i)).PGD1Data) == 0 && ismissing(PGD1_data_name) == 0
        h2 = scatter(expProcData.(filedataExp.Key(i)).PGD1Data.TimeElapsed,expProcData.(filedataExp.Key(i)).PGD1Data.C1,5,'filled','MarkerFaceColor',[0.9290 0.6940 0.1250],'DisplayName','C_{PGD1}');
        hold on 
    end
    xlabel('Time elapsed [hh:mm:ss]','FontSize', 14);
    xtickformat('hh:mm:ss')
    ylabel('C_{H_2} [mol %]','FontSize', 14);
    ylim([0,100]);
    legend([h3,h2,h1], 'Location','southeast');
    title (filedataExp.Key(i), 'Interpreter', 'none','FontSize', 16)
    grid on;
    saveas(gcf,pathExportAll + filedataExp.Key(i) + "_dens_conc_Qeffect",'png')
end
