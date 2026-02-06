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
% 4 - Plot individually and together
% 
% Output: 
% Database
% Figures
%
%% IMPORT

addpath('functions/');

% Introduce name of input and desired output folder name

filenameExp = 'input/input_exp_H2-CO2-T32-P1500.xlsx';
pathImportCal = 'results/cal_250725_PR/';
pathImportPR = 'results/PR-H2CO2-32C-1500psig/';
mkdir('results/H2CO2_T32_P1500_H');
pathExportAll = 'results/H2CO2_T32_P1500_H/';

%% IMPORT variables

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
load(pathImportPR + "PR_results.mat")


%rho_corr_lin function
rho_corr_lin = @(p,y) (y-p(1))/p(2);

%% Volume concentration
% do not use drho or rhosat values from input
% for i = 1:length(filedataExp.Key)
%     expProcData.(filedataExp.Key(i)).
% end
        expProcData.(filedataExp.Key(i)).MFMData.C1 = 100*(filedataExp.rho2sat(i)-expProcData.(filedataExp.Key(i)).MFMData.dens_MFM2)./(filedataExp.rho2sat(i)-filedataExp.rho1sat(i));
        drho_cal = [filedataExp.drho2(i) filedataExp.drho1(i)];
        rho_cal = [filedataExp.rho2sat(i) filedataExp.rho1sat(i)];
        aux_cal = polyfit(rho_cal,drho_cal,1);
        expProcData.(filedataExp.Key(i)).MFMCal = aux_cal;
        expProcData.(filedataExp.Key(i)).MFMData.drho = aux_cal(1)*expProcData.(filedataExp.Key(i)).MFMData.dens_MFM2 + aux_cal(2);
        dC1 = (((-100/(filedataExp.rho2sat(i)-filedataExp.rho1sat(i)))^2)*(expProcData.(filedataExp.Key(i)).MFMData.drho.^2)).^(1/2);
        expProcData.(filedataExp.Key(i)).MFMData.dC1 = dC1;
        BT = table(expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed, ...
            seconds(expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed), ...
            expProcData.(filedataExp.Key(i)).MFMData.dens_MFM2, ...
            expProcData.(filedataExp.Key(i)).MFMData.drho, ...
            expProcData.(filedataExp.Key(i)).MFMData.C1, ...
            expProcData.(filedataExp.Key(i)).MFMData.dC1, ...
            'VariableNames',{'Time','TimeElapsed','MFMdens','drho','C1','dC1'});
        expProcData.(filedataExp.Key(i)).BT = rmmissing(BT);

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

%% Plotting

%Individual plots for checking

%Pressure and flow rates

for i = 1:length(filedataExp.Key)
    f1 = figure; % all pressures
    if isempty(expProcData.(filedataExp.Key(i)).transData) == 0 && ismissing(trans_data_name) == 0
        scatter(expProcData.(filedataExp.Key(i)).transData.TimeElapsed,expProcData.(filedataExp.Key(i)).transData.PT1,10,'filled','DisplayName','PT1')
        hold on
        scatter(expProcData.(filedataExp.Key(i)).transData.TimeElapsed,expProcData.(filedataExp.Key(i)).transData.PT2,10,'filled','DisplayName','PT2')
    end
    if isempty(expProcData.(filedataExp.Key(i)).pumpsData) == 0 && ismissing(pumps_data_name) == 0
        scatter(expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed,expProcData.(filedataExp.Key(i)).pumpsData.P_P3,10,'filled','DisplayName','Pconf')
    end
    xlabel('Time elapsed [hh:mm:ss]')
    ylabel('Pressure [psig]')
    xtickformat('hh:mm:ss')
    grid("on")
    title(filedataExp.Key(i) + " pressure", 'Interpreter', 'none')
    legend();
    saveas(f1,pathExportAll + filedataExp.Key(i) + "_pplot",'png')

    f2 = figure; % all flow rates
    if isempty(expProcData.(filedataExp.Key(i)).pumpsData) == 0 && ismissing(pumps_data_name) == 0
        scatter(expProcData.(filedataExp.Key(i)).pumpsData.TimeElapsed,expProcData.(filedataExp.Key(i)).pumpsData.q_P1,10,'filled','DisplayName','q_{pump}')
        hold on
    end
    if isempty(expProcData.(filedataExp.Key(i)).MFMData) == 0
        scatter(expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed,expProcData.(filedataExp.Key(i)).MFMData.q_MFM2,10,'filled','DisplayName','q_{MFM}')
    end
    xlabel('Time elapsed [hh:mm:ss]')
    xtickformat('hh:mm:ss')
    ylabel('Flow rate [ml/min]')
    title(filedataExp.Key(i) + " flow rates", 'Interpreter', 'none')
    legend();
    grid on;
    saveas(f2,pathExportAll + filedataExp.Key(i) + "_qplot",'png')
end

%%
     
% Densities and concentrations
for i = 1:length(filedataExp.Key)
    if filedataExp.Fluid1(i) == "H2"
        pumps_data_name = filedataExp.path(i) + filedataExp.pumps_data_name(i);
        trans_data_name = filedataExp.path(i) + filedataExp.trans_data_name(i);
        MFM_data_name = filedataExp.path(i) + filedataExp.MFM_data_name(i);
        PGD1_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
        PGD2_data_name = filedataExp.path(i) + filedataExp.PGD1_data_name(i);
    
%         % concentrations and densities PGDs1
%         f3 = figure; % concentrations and densities
%         yyaxis left
%         ax = gca;
%         ax.YColor = [0 0 0];
%         if isempty(expProcData.(filedataExp.Key(i)).MFMData) == 0 && ismissing(MFM_data_name) == 0
%             scatter(expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed,expProcData.(filedataExp.Key(i)).MFMData.dens_MFM2,10,'filled','MarkerFaceColor','r')
%         end
%         xlabel('Time elapsed [hh:mm:ss]');
%         xtickformat('hh:mm:ss')
%         ylabel('Density (kg/m^{3}');
%         yyaxis right
%         ax = gca;
%         ax.YColor = [0 0 0];
%         set(gca,'ylim',[0,100])
%         title(filedataExp.Key(i) + " density & concentrations PGDS", 'Interpreter', 'none')
%         legend("MFM", 'Location','southeast');
%         if isempty(expProcData.(filedataExp.Key(i)).PGD2Data) == 0 && ismissing(PGD2_data_name) == 0
%             hold on 
%             yyaxis right
%             plot(expProcData.(filedataExp.Key(i)).PGD2Data.TimeElapsed,expProcData.(filedataExp.Key(i)).PGD2Data.CO2GasConcentration,'DisplayName','PGD2','LineWidth',1.5, 'Color',[0.9290 0.6940 0.1250],'LineStyle','--')
%         end
%         if isempty(expProcData.(filedataExp.Key(i)).PGD1Data) == 0 && ismissing(PGD1_data_name) == 0
%             hold on 
%             yyaxis right
%             plot(expProcData.(filedataExp.Key(i)).PGD1Data.TimeElapsed,expProcData.(filedataExp.Key(i)).PGD1Data.H2GasConcentration,'DisplayName','PGD1','LineWidth',1.5, 'Color',[0.9290 0.6940 0.1250],'LineStyle',':')
%         end
%         grid on;
%         saveas(f3,pathExportAll + filedataExp.Key(i) + "_dens_conc_PGDS",'png')
%     
        % Densities and concentrations C1
        f4 = figure('Position', [100, 100, 700, 550]);
        tiledlayout(2,2, 'TileSpacing', 'tight', 'Padding','tight');
        title (filedataExp.Key(i), 'Interpreter', 'none','FontSize', 16)
        yyaxis left
        ax = gca;
        ax.YColor = [0 0 0];
        if isempty(expProcData.(filedataExp.Key(i)).MFMData) == 0 && ismissing(MFM_data_name) == 0
            t = expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed;
            C = expProcData.(filedataExp.Key(i)).MFMData.C1;
            dC = expProcData.(filedataExp.Key(i)).MFMData.dC1;
            %fill([t fliplr(t)], [C+dC fliplr(C-dC)], [1 0 0], 'EdgeColor', 'none', 'FaceAlpha', 1);  % Light blue shade
            h1 = errorbar(t,C,dC,'Color',[1, 0.8, 0.8],'DisplayName','MFM error');
            set(h1, 'LineStyle', 'none'); 
            hold on
            h2=scatter(t,C,1,'filled','MarkerFaceColor','r','DisplayName','MFM');
        end
        xlabel('Time elapsed [hh:mm:ss]','FontSize', 14);
        xtickformat('hh:mm:ss')
        ylabel('C_{1}[%]','FontSize', 14);
        ylim_array = [-2,102];
        ylim(ylim_array);
        ax.FontSize = 14;
        yyaxis right
        ax = gca;
        ax.FontSize = 14;
        ax.YColor = [0 0 0];
        rho_C_rel_m = (filedataExp.rho2sat(i) - filedataExp.rho1sat(i))/100;
        rho_C_rel_n = filedataExp.rho1sat(i);
        set(gca,'ylim',[ylim_array(1)*rho_C_rel_m + rho_C_rel_n, ylim_array(2)*rho_C_rel_m + rho_C_rel_n])
        set(gca, 'YDir', 'reverse')
        ylabel('MFM Density [kg/m^{3}]','FontSize',14);
        if isempty(expProcData.(filedataExp.Key(i)).PGD2Data) == 0 && ismissing(PGD2_data_name) == 0
            hold on 
            yyaxis left
            h3 = plot(expProcData.(filedataExp.Key(i)).PGD2Data.TimeElapsed,expProcData.(filedataExp.Key(i)).PGD2Data.C1,'DisplayName','PGD2','LineWidth',1.5, 'Color',[0.9290 0.6940 0.1250],'LineStyle','--');
        end
        if isempty(expProcData.(filedataExp.Key(i)).PGD1Data) == 0 && ismissing(PGD1_data_name) == 0
            hold on 
            yyaxis left
            h4 = plot(expProcData.(filedataExp.Key(i)).PGD1Data.TimeElapsed,expProcData.(filedataExp.Key(i)).PGD1Data.C1,'DisplayName','PGD1','LineWidth',1.5, 'Color',[0.9290 0.6940 0.1250],'LineStyle',':');
        end
        legend([h2,h1,h4,h3],'Location','southeast');
        grid on;
        saveas(f4,pathExportAll + filedataExp.Key(i) + "_dens_conc",'png')
    end
end

