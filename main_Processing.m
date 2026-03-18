% main_Processing.m
% Author: Ianna Gomez Mendez
%
% Objective: Find KL and other fitting params like dt, alpha and tortuosity
% 
% Functions:
% fit_dispersion, only K fitting, L, v, Ci and Cj fixed
%
% Input (use Import Data tool in Matlab):
% 1 - filedataExp
% 2 - expProcData.dat all
% 
% Procedure:
% 1 - Load input
% 2 - Use fitting dispersion function and find KL and dt
% 3 - Plot all v to Kl to find alpha
% 4 - Plot all in dimensionless plot to find tortuosity
% 
% Output: 
% Figures
% Fitting results

%% INPUT

addpath('functions/');

filenameExp = 'input/input_exp_H2-CO2-T32-P1500.xlsx';
pathImportAll = 'results/exp_H2-CO2-T32-P1500-H/';
pathExportAll = 'results/exp_H2-CO2-T32-P1500-H/';


%% IMPORT variables

filedataExp = import_inputExp(filenameExp); % import input to a local variable

load(pathImportAll+"expProcData.mat")

%% Fitting dispersion to find KL and dt & save in table
% short equation CF

Cj = 1;
Ci = 0;
% CDj = 1;
% CDi = 0;

% No need to correct BT curve due to extra volume before core, the
% fit_dispersion_dt corrects for that extra t

% name to save matrices and spreadsheets
table_name = pathExportAll + "fittingResults";  % Name used for saving TrimData comes from input pathExportAll

% delete previous saved files
delete(table_name + '.mat');
delete(table_name + '.xlsx');
% 
% C_function = @(p,t)(Ci + (Cj/2)*erfc(((L-u.*(t-p(2))).*((t).^(1/2)))./(2*t.*p(1))));
% CD_function = @(pD,tD)(CDi + (CDj/2)*erfc(((1-(tD-pD(2))).*((t).^(1/2)))./(2*t.*p(1))));

fitting_results = table();
for i = 1:length(filedataExp.Key)
    if filedataExp.Type(i) == "CF"

        dt_guess = (filedataExp.Vlinesbefore(i)+filedataExp.Vlinesafter(i))*60/filedataExp.Q(i); % time in seconds
        % the sum of V lines before and after should be the same as Vtotal - Vcore      
        t_vals = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed(expProcData.(filedataExp.Key(i)).BT.Ci<90);
        C1_vals = expProcData.(filedataExp.Key(i)).BT.Ci(expProcData.(filedataExp.Key(i)).BT.Ci<90)/100;
        C1_max_vals = expProcData.(filedataExp.Key(i)).BT.CiMax(expProcData.(filedataExp.Key(i)).BT.Ci<90)/100;
        C1_min_vals = expProcData.(filedataExp.Key(i)).BT.CiMin(expProcData.(filedataExp.Key(i)).BT.Ci<90)/100;
        
        u = expProcData.(filedataExp.Key(i)).exp_params.u_SI;
        L = expProcData.(filedataExp.Key(i)).exp_params.L_SI;
        p_guess = [1,dt_guess];

        % tD = expProcData.(filedataExp.Key(l)).BT.SecondsElapsed*filedataExp.Q(l)/(60*filedataExp.Vtotal(l));
        %                             CD = expProcData.(filedataExp.Key(l)).BT.Ci/100;
        %                             CDmin = expProcData.(filedataExp.Key(l)).BT.CiMin/100;
        %                             CDmax = expProcData.(filedataExp.Key(l)).BT.CiMax/100;

        [KL,dt_fit, u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion_dt(C1_vals,t_vals,u,Cj,Ci,L,p_guess);
        [KL_max,dt_fit_max, u_fit_max, Cj_fit_max, Ci_fit_max, C_fit_max] = fit_dispersion_dt(C1_max_vals,t_vals,u,Cj,Ci,L,p_guess); %max Ci
        [KL_min,dt_fit_min, u_fit_min, Cj_fit_min, Ci_fit_min, C_fit_min] = fit_dispersion_dt(C1_min_vals,t_vals,u,Cj,Ci,L,p_guess); %min Ci

        expProcData.(filedataExp.Key(i)).exp_params.u_fit_SI = u_fit;
        expProcData.(filedataExp.Key(i)).exp_params.u_fit_cmmin = u_fit*60*10^2;
        expProcData.(filedataExp.Key(i)).exp_params.Cj_fit = Cj_fit;
        expProcData.(filedataExp.Key(i)).exp_params.Ci_fit = Ci_fit;       
        % Fitting parameters mean
        expProcData.(filedataExp.Key(i)).exp_params.C_fit = C_fit;
        expProcData.(filedataExp.Key(i)).exp_params.KL_SI = KL;
        expProcData.(filedataExp.Key(i)).exp_params.KL_cm2min = KL*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.dt_SI = dt_fit;
        expProcData.(filedataExp.Key(i)).exp_params.dt_min = dt_fit/60;
        expProcData.(filedataExp.Key(i)).exp_params.dtD_SI = dt_fit;
        expProcData.(filedataExp.Key(i)).exp_params.dtD_min = dt_fit/60;

        % Fitting parameters max
        expProcData.(filedataExp.Key(i)).exp_params.C_fit_max = C_fit_max;
        expProcData.(filedataExp.Key(i)).exp_params.KL_max_SI = KL_max;
        expProcData.(filedataExp.Key(i)).exp_params.KL_max_cm2min = KL_max*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.dt_max_SI = dt_fit_max;
        expProcData.(filedataExp.Key(i)).exp_params.dt_max_min = dt_fit_max/60;
        % Fitting parameters min
        expProcData.(filedataExp.Key(i)).exp_params.C_fit_min = C_fit_min;
        expProcData.(filedataExp.Key(i)).exp_params.KL_min_SI = KL_min;
        expProcData.(filedataExp.Key(i)).exp_params.KL_min_cm2min = KL_min*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.dt_min_SI = dt_fit_min;
        expProcData.(filedataExp.Key(i)).exp_params.dt_min_min = dt_fit_min/60;

        % Corrected BT with time shift
        expProcData.(filedataExp.Key(i)).BT.SecondsElapsed_corr = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed - dt_fit;
        expProcData.(filedataExp.Key(i)).BT_corr = expProcData.(filedataExp.Key(i)).BT(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed_corr>=0,:);
        SecondsElapsedNew_aux = seconds(expProcData.(filedataExp.Key(i)).BT_corr.SecondsElapsed_corr);
        SecondsElapsedNew_aux.Format = 'hh:mm:ss.SSS';
        expProcData.(filedataExp.Key(i)).BT_corr.TimeElapsedNew = SecondsElapsedNew_aux;

        % Table with fitting results
        % mean
        RMSE = expProcData.(filedataExp.Key(i)).exp_params.C_fit.RMSE;
        R2 = expProcData.(filedataExp.Key(i)).exp_params.C_fit.Rsquared.Adjusted;
        p1 = expProcData.(filedataExp.Key(i)).exp_params.C_fit.Coefficients.Estimate(1);
        SE_p1 = expProcData.(filedataExp.Key(i)).exp_params.C_fit.Coefficients.SE(1);
        SE_KL = (((2*p1)^2)*(SE_p1^2))^(1/2);
        SE_dt = expProcData.(filedataExp.Key(i)).exp_params.C_fit.Coefficients.SE(2);
        % max
        RMSE_max = expProcData.(filedataExp.Key(i)).exp_params.C_fit_max.RMSE;
        R2_max = expProcData.(filedataExp.Key(i)).exp_params.C_fit_max.Rsquared.Adjusted;
        p1_max = expProcData.(filedataExp.Key(i)).exp_params.C_fit_max.Coefficients.Estimate(1);
        SE_p1_max = expProcData.(filedataExp.Key(i)).exp_params.C_fit_max.Coefficients.SE(1);
        SE_KL_max = (((2*p1_max)^2)*(SE_p1_max^2))^(1/2);
        SE_dt_max = expProcData.(filedataExp.Key(i)).exp_params.C_fit_max.Coefficients.SE(2);
        %min
        RMSE_min = expProcData.(filedataExp.Key(i)).exp_params.C_fit_min.RMSE;
        R2_min = expProcData.(filedataExp.Key(i)).exp_params.C_fit_min.Rsquared.Adjusted;
        p1_min = expProcData.(filedataExp.Key(i)).exp_params.C_fit_min.Coefficients.Estimate(1);
        SE_p1_min = expProcData.(filedataExp.Key(i)).exp_params.C_fit_min.Coefficients.SE(1);
        SE_KL_min = (((2*p1_max)^2)*(SE_p1_max^2))^(1/2);
        SE_dt_min = expProcData.(filedataExp.Key(i)).exp_params.C_fit_min.Coefficients.SE(2);
        % Temperature stats
        T_mean = mean(expProcData.(filedataExp.Key(i)).BT.T_MFM);
        T_std = std(expProcData.(filedataExp.Key(i)).BT.T_MFM);

        % creating table
        row_temp = table(filedataExp.Key(i),u,u*60*10^2, L,L*100, ...
            u_fit, u_fit*60*10^2, Cj_fit,Ci_fit, RMSE,R2,T_mean,T_std, ...
            KL, SE_KL, KL*60*10^4,(SE_KL)*60*10^4, ...
            abs(KL-KL_max)*60*10^4, abs(KL-KL_min)*60*10^4, ...
            mean([abs(KL-KL_max),abs(KL-KL_min)])*60*10^4, 100*mean([abs(KL-KL_max),abs(KL-KL_min)])/KL,...
            dt_fit, SE_dt, dt_fit/60, SE_dt/60,...
            Cj_fit_max, KL_max, SE_KL_max, KL_max*60*10^4,(SE_KL_max)*60*10^4, ...
            dt_fit_max, SE_dt_max, dt_fit_max/60, SE_dt_max/60,...
            Cj_fit_min, KL_min, SE_KL_min, KL_min*60*10^4,(SE_KL_min)*60*10^4, ...
            dt_fit_min, SE_dt_min, dt_fit_min/60, SE_dt_min/60,...
            'VariableNames',{'Key','u_SI','u_cmmin', 'L_SI', 'L_cm', ...
            'u_fit_SI','u_fit_cmmin', 'Cj_fit','Ci_fit','RMSE','R2','T_mean','T_std',...
            'KL_SI', 'SE_KL_SI', 'KL_cm2min','SE_KL_cm2min', ...
            'sd_KL_max_cm2min', 'sd_KL_min_cm2min', ...
            'sd_KL_avg_cm2min', 'error_pc_KL_avg_cm2min'...
            'dt_SI', 'SE_dt_SI', 'dt_min', 'SE_dt_min',...
            'Cj_fit_max','KL_max_SI', 'SE_KL_max_SI', 'KL_max_cm2min','SE_KL_max_cm2min', ...
            'dt_max_SI', 'SE_dt_max_SI', 'dt_max_min', 'SE_dt_max_min', ...
            'Cj_fit_min','KL_min_SI', 'SE_KL_min_SI', 'KL_min_cm2min','SE_KL_min_cm2min', ...
            'dt_min_SI', 'SE_dt_min_SI', 'dt_min_min', 'SE_dt_min_min'});
        fitting_results = [fitting_results;row_temp];
    end
end
writetable(fitting_results,table_name + ".xlsx");
save(table_name + ".mat",'fitting_results')

%% Fitting and experimental data all CF plot

for i = 1:length(filedataExp.Key)
        figure
        scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.Ci,10,'filled','MarkerFaceColor','red')
        hold on
        plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
        xlabel('Time elapsed [hh:mm:ss]');
        xtickformat('hh:mm:ss')
        ylabel('Molar concentration C_1 [mol %]');
        title(filedataExp.Key(i) + " fitting", 'Interpreter', 'none')
        grid on;
        legend(["Experimental data", "BT model fitting"],'Location','southeast');
        saveas(gcf,pathImportAll + filedataExp.Key(i) + "_fitting",'png')
        savefig(gcf,pathImportAll + filedataExp.Key(i) + "_fitting")
end

%% Fitting and experimental data all CF plot all

for i = 1:length(filedataExp.Key)
        figure
        scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.Ci_corr_mean,10,'filled','MarkerFaceColor','red')
        hold on
        %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
        xlabel('Time elapsed [hh:mm:ss]');
        xtickformat('hh:mm:ss')
        ylabel('Molar concentration C_1 [mol %]');
        title(filedataExp.Key(i) + " fitting", 'Interpreter', 'none')
        grid on;
        legend(["Experimental data", "BT model fitting"],'Location','southeast');
        scatter(expProcData.(filedataExp.Key(i)).BT_corr.TimeElapsed,expProcData.(filedataExp.Key(i)).BT_corr.Ci_corr_mean,10,'filled','MarkerFaceColor','blue')
        hold on
        %plot(expProcData.(filedataExp.Key(i)).BT_corr.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT_corr.SecondsElapsed),'LineWidth',1.5,'Color', 'green')
        xlabel('Time elapsed [hh:mm:ss]');
        xtickformat('hh:mm:ss')
        ylabel('Molar concentration C_1 [mol %]');
        title(filedataExp.Key(i) + " fitting tshift", 'Interpreter', 'none')
        grid on;
        legend(["Experimental data", "BT model fitting"],'Location','southeast');
        saveas(gcf,pathImportAll + filedataExp.Key(i) + "_fitting_tshift",'png')
        savefig(gcf,pathImportAll + filedataExp.Key(i) + "_fitting_tshift")
end

%%
f1=figure;
for i = 1:length(filedataExp.Key)
    % if filedataExp.Fluid1(i) == "He"
    %     if filedataExp.T(i) == 40
    %         if filedataExp.Type(i) == "CF"
                plot(expProcData.(filedataExp.Key(i)).BT.Time,expProcData.(filedataExp.Key(i)).exp_params.C_fit1.feval(expProcData.(filedataExp.Key(i)).BT.TimeElapsed),'LineWidth',1.5,"DisplayName",filedataExp.Key(i))
                xlabel('Time elapsed [hh:mm:ss]');
                xtickformat('hh:mm:ss')
                ylabel('Concentration C_1');
                title(" all fitting", 'Interpreter', 'none')
                grid on;
                legend('Location','southeast', 'Interpreter','none');
                hold on
    %         end
    %     end
    % end
end
saveas(gcf,pathExportAll + "all_fitting",'png')
savefig(gcf,pathExportAll + "all_fitting")

%%

f2=figure;
for i = 1:length(filedataExp.Key)
    if filedataExp.Fluid1(i) == "H2"
    %     if filedataExp.T(i) == 40
    %         if filedataExp.Type(i) == "CF"
                plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed*expProcData.(filedataExp.Key(i)).exp_params.u_fit/expProcData.(filedataExp.Key(i)).exp_params.L_SI,expProcData.(filedataExp.Key(i)).exp_params.C_fit1.feval(expProcData.(filedataExp.Key(i)).BT.TimeElapsed),'LineWidth',1.5,"DisplayName",filedataExp.Key(i))
                xlabel('Dimensionless time');
                ylabel('Concentration C_1');
                title(" all fitting", 'Interpreter', 'none')
                grid on;
                legend('Location','southeast', 'Interpreter','none');
                hold on
    %         end
    %     end
    end
end
saveas(gcf,pathExportAll + "all_fitting dimensionless",'png')
savefig(gcf,pathExportAll + "all_fitting dimensionless")

%% Paper Fitting and experimental data all CF together
colors = [[0.0000, 0.4470, 0.7410];[0.9290, 0.6940, 0.1250];[0.4660, 0.6740, 0.1880]];
colors_fit = [[0.03, 0.1, 0.410];[0.7290, 0.4940, 0];[0, 0.3740, 0.0880]];
colors_error = [[0.7000, 0.8470, 1];[1, 1, 0.7250];[0.67, 1, 0.72]];
figure
handles = []; %here it goes h1, h2...
labels = []; 
j = 1;
for i = 1:length(filedataExp.Key)
    if filedataExp.Fluid1(i) == "H2"
        % if filedataExp.Type(i) == "BP"
            t = expProcData.(filedataExp.Key(i)).MFMData.TimeElapsed;
            C = expProcData.(filedataExp.Key(i)).MFMData.C1;
            dC = expProcData.(filedataExp.Key(i)).MFMData.dC1;
            h1 = errorbar(t,C,dC,'Color',colors_error(j,:),'DisplayName',"MFM - Q " + filedataExp.Q(i) +" ml/min",'MarkerSize',10,'Marker','o','MarkerFaceColor',colors(j,:),'MarkerSize',5);
            set(h1, 'LineStyle', 'none'); 
            hold on
            C1_vals = expProcData.(filedataExp.Key(i)).BT.C1;
            t_vals = expProcData.(filedataExp.Key(i)).BT.Time;
            t_elapsed_vals = expProcData.(filedataExp.Key(i)).BT.TimeElapsed;
            C1_fit_vals = expProcData.(filedataExp.Key(i)).exp_params.C_fit1.feval(t_elapsed_vals);
            % C1_fit_range = C1_fit_vals(C1_fit_vals < 1.1);
            % t_vals_range = t_vals(C1_fit_vals<1.1);
            h2 = scatter(t_vals,C1_vals,2,'filled','DisplayName',"Q = " + filedataExp.Q(i) +" ml/min",'MarkerFaceColor',colors(j,:),'HandleVisibility', 'off');
            h3 = plot(t_vals(C1_fit_vals<0.60),100*C1_fit_vals(C1_fit_vals<0.60),'HandleVisibility', 'off', 'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','-');
            h5 = plot(t_vals(C1_fit_vals>0.98),100*C1_fit_vals(C1_fit_vals>0.98),'DisplayName',"BT Fit - Q "+ filedataExp.Q(i) +" ml/min", 'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','-');
            h4 = plot(t_vals(C1_fit_vals>0.6 & C1_fit_vals<0.98),100*C1_fit_vals(C1_fit_vals>0.6 & C1_fit_vals<0.98),'DisplayName',"Extension BT Fit - Q "+ filedataExp.Q(i) +" ml/min", 'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','--');
            % h3 = plot(t_vals_range,100*C1_fit_range,'DisplayName',"BT Fit - Q "+ filedataExp.Q(i) +" ml/min",'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','-');
            % R2 = expProcData.(filedataExp.Key(i)).exp_params.C_fit1.Rsquared.Ordinary;
            % annotText = sprintf('R^2 = %.2f', R2);
            % annotation('textbox', [0.15*(4-j), 0.86 - 0.02*(4-j), 0.12, 0.06], 'String', annotText, ...
            % 'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','BackgroundColor',colors_fit(j,:),'FaceAlpha',0.1);
            % 
            xlabel('Time elapsed [hh:mm:ss]');
            xtickformat('hh:mm:ss')
            ylabel('Concentration C_1 [%]');
            grid on;
            ylim([-2,102]);
            title("Breakthrough curves fitting", 'Interpreter', 'none')
            % legend('Location','southeast');
            Qheader = plot(nan,nan,'w');
            handles = [handles,Qheader, h1, h5, h4];
            labels  = [labels, "Q = " + filedataExp.Q(i) + " ml/min", "MFM Data", "BT Fit", "BT Fit Ext."];            
            % lgd = legend([h2,h5,h4], {'MFM Data','BT Fit','Extension BT Fit'},'Location','southeast');
            % title(lgd, "Q = " + filedataExp.Q(i) +" ml/min");
            j = j +1;
        % end
    end
end
lgd = legend(handles, labels, 'Location','southeast');
lgd.NumColumns = 3;
lgd.ItemTokenSize = [18,10];
saveas(gcf,pathImportAll + "BTfitting",'png')
savefig(gcf,pathImportAll + "BTfitting")

%% Paper Fitting and experimental data all CF together dimensionless time
colors = [[0.0000, 0.4470, 0.7410];[0.9290, 0.6940, 0.1250];[0.4660, 0.6740, 0.1880]];
colors_fit = [[0.03, 0.1, 0.410];[0.7290, 0.4940, 0];[0, 0.3740, 0.0880]];
colors_error = [[0.7000, 0.8470, 1];[1, 1, 0.7250];[0.67, 1, 0.72]];
figure
j = 1;
for i = 1:length(filedataExp.Key)
    if filedataExp.Fluid1(i) == "H2"
        % if filedataExp.Type(i) == "BP"
            t = expProcData.(filedataExp.Key(i)).BT.TimeElapsed;
            C = expProcData.(filedataExp.Key(i)).BT.C1;
            dC = expProcData.(filedataExp.Key(i)).BT.dC1;
            C1_vals = expProcData.(filedataExp.Key(i)).BT.C1;
            t_vals = expProcData.(filedataExp.Key(i)).BT.Time;
            t_elapsed_vals = expProcData.(filedataExp.Key(i)).BT.TimeElapsed;
            tD = t_elapsed_vals*expProcData.(filedataExp.Key(i)).exp_params.u_fit/expProcData.(filedataExp.Key(i)).exp_params.L_SI;
            C1_fit_vals = expProcData.(filedataExp.Key(i)).exp_params.C_fit1.feval(t_elapsed_vals);
            C1_fit_range = C1_fit_vals(C1_fit_vals >0 & C1_fit_vals < 1);
            t_vals_range = t_vals(C1_fit_vals>0 & C1_fit_vals<1);
            h1 = errorbar(tD,C,dC,'Color',colors_error(j,:),'DisplayName',"MFM - Q " + filedataExp.Q(i) +" ml/min",'MarkerSize',10,'Marker','o','MarkerFaceColor',colors(j,:),'MarkerSize',5);
            set(h1, 'LineStyle', 'none'); 
            hold on
            h2 = scatter(tD,C1_vals,2,'filled','DisplayName',"Q = " + filedataExp.Q(i) +" ml/min",'MarkerFaceColor',colors(j,:),'HandleVisibility', 'off');
            h3 = plot(tD,100*C1_fit_vals,'DisplayName',"BT Fit - Q "+ filedataExp.Q(i) +" ml/min",'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','-');
            % R2 = expProcData.(filedataExp.Key(i)).exp_params.C_fit1.Rsquared.Ordinary;
            % annotText = sprintf('R^2 = %.2f', R2);
            % annotation('textbox', [0.15*(4-j), 0.86 - 0.02*(4-j), 0.12, 0.06], 'String', annotText, ...
            % 'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','BackgroundColor',colors_fit(j,:),'FaceAlpha',0.1);
            % 
            xlabel('Dimensionless time');
            ylabel('Concentration C_1 [%]');
            grid on;
            xlim([0,2]);
            ylim([-2,102]);
            title("Dimensionless breakthrough curves fitting", 'Interpreter', 'none')
            legend('Location','southeast');
            j = j +1;
        % end
    end
end
saveas(gcf,pathImportAll + "BTfitting_td",'png')
savefig(gcf,pathImportAll + "BTfitting_td")

%% Paper Kl_vs_vel
colors = [[0.0000, 0.4470, 0.7410];[0.9290, 0.6940, 0.1250];[0.4660, 0.6740, 0.1880]];

figure; % dispersivity

u_cmmin_all = [];
KL_cm2min_all = [];
j = 1;                
for i = 1:length(filedataExp.Key)
    if filedataExp.Fluid1(i) == "H2"
        u_cmmin = fitting_results.u_cmmin(j);
        KL = fitting_results.KL_cm2min(j);
        dKL = fitting_results.SE_KL_cm2min(j);
        u_cmmin_all = [u_cmmin_all, u_cmmin];
        KL_cm2min_all = [KL_cm2min_all, KL];
        scatter(u_cmmin,KL,'filled','DisplayName',"Q = " + filedataExp.Q(i) +" ml/min")
        hold on
        j = j + 1;
    end
end
xlabel('Interstitial velocity (u_x) [cm/min]');
ylabel('Longitudinal Dispersion Coefficient (K_L) [cm^2/s]');
grid on;

% Kl_vs_u fitting
KL_vs_u_function = @(p,u)(p(1)*u);
p = 1;
for j = 1:20
    KL_vs_u_fit = fitnlm(u_cmmin_all,KL_cm2min_all,KL_vs_u_function,p);
    p = KL_vs_u_fit.Coefficients.Estimate;
    err = KL_vs_u_fit.Coefficients.SE;
end

% f1 = polyfit(u_cmmin_all,KL_cm2min_all,1);
% feval = polyval(f1,u_cmmin_all);
%plot(u_cmmin_all,feval,'DisplayName','fitting');

plot(u_cmmin_all,KL_vs_u_fit.feval(u_cmmin_all),'DisplayName','fitting');
alpha = p(1);
annotText = sprintf('\\alpha_{L} = %.2f \\pm %.2f cm', alpha, err);
annotation('textbox', [0.25, 0.18, 0.8, 0.06], 'String', annotText, ...
'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','FaceAlpha',0.1);

legend('Location','southeast');
saveas(gcf,"KLvsVel-alpha_all",'png')

%% KL-D0 vs Pe test 1

%case H2 and CO2 at 32 C and 1500 psig
D0 = 6.85E-03; % cm2/s 
D0_cm2min = D0 * 60; %cm2/min

Pe_KL = []; 
Pe_D0 = [];
j = 1;  
for i = 1:length(filedataExp.Key)
    if filedataExp.Fluid1(i) == "H2"
        u_cmmin = fitting_results.u_cmmin(j);
        KL = fitting_results.KL_cm2min(j);
        L_cm = fitting_results.L_cm(j);
        Pe_KL = [Pe_KL,u_cmmin*L_cm/KL];
        Pe_D0 = [Pe_D0,u_cmmin*alpha/D0];
        j = j + 1;
        hold on
    end
end

figure
scatter(Pe_D0,KL_cm2min_all/D0_cm2min,'filled')

K_L_D0_vs_Pe_function = @(p_K_L,Pe_alphaD0)((p_K_L(1))+Pe_alphaD0.^p_K_L(2));
p2 = [1,1];
% Lower and upper bounds (force p(1) > 0)
lb = [-Inf, -Inf];
ub = [Inf, Inf];

for j = 1:20
    %K_L_D0_vs_Pe_fit = fitnlm(Pe_D0,KL_cm2min_all/D0_cm2min,K_L_D0_vs_Pe_function,p2);
    K_L_D0_vs_Pe_fit = lsqcurvefit(K_L_D0_vs_Pe_function, p2, Pe_D0, KL_cm2min_all/D0_cm2min, lb, ub);
    % p2 = K_L_D0_vs_Pe_fit.Coefficients.Estimate;
    % err2 = K_L_D0_vs_Pe_fit.Coefficients.SE;
end

K_L_D0_fit = K_L_D0_vs_Pe_function(K_L_D0_vs_Pe_fit,Pe_D0);

figure; % dispersivity
scatter(Pe_D0,KL_cm2min_all/D0_cm2min,'filled')
hold on
plot(Pe_D0,K_L_D0_fit,'r-')


%% KL-D0 vs Pe test 2

%case H2 and CO2 at 32 C and 1500 psig
D0 = 6.85E-03; % cm2/s 
D0_cm2min = D0 * 60; %cm2/min

Pe_KL = []; 
Pe_D0 = [];
j = 1;  
for i = 1:length(filedataExp.Key)
    if filedataExp.Fluid1(i) == "H2"
        u_cmmin = fitting_results.u_cmmin(j);
        KL = fitting_results.KL_cm2min(j);
        L_cm = fitting_results.L_cm(j);
        Pe_KL = [Pe_KL,u_cmmin*L_cm/KL];
        Pe_D0 = [Pe_D0,u_cmmin*alpha/D0];
        j = j + 1;
        hold on
    end
end

figure
scatter(Pe_D0,KL_cm2min_all/D0_cm2min,'filled')

K_L_D0_vs_Pe_function = @(p_K_L,Pe_D0)(p_K_L(1)+Pe_D0.^(1.2));
p3 = 1;

for j = 1:20
    K_L_D0_vs_Pe_fit = fitnlm(Pe_D0,KL_cm2min_all/D0_cm2min,K_L_D0_vs_Pe_function,p3);
    p3 = K_L_D0_vs_Pe_fit.Coefficients.Estimate;
    err3 = K_L_D0_vs_Pe_fit.Coefficients.SE;
end

% K_L_D0_fit = K_L_D0_vs_Pe_function(K_L_D0_vs_Pe_fit,Pe_D0);
% 
% figure; % dispersivity
% scatter(Pe_D0,KL_cm2min_all/D0_cm2min,'filled')
% hold on
% plot(Pe_D0,K_L_D0_fit,'r-')
%%


 
% fit

% tortuosity = 

% plot


