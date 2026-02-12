% main_Processing.m
% version: v06_Feb2025
% Author: Ianna Gomez Mendez
%
% Objective: Find KL and other fitting params
% 
% Functions:
% fit_dispersion, Cj and Ci fitted
%
% Input (use Import Data tool in Matlab):
% 1 - filedataExp
% 2 - expProcData.dat all
% 
% Procedure:
% 1 - Load input
% 2 - Use fitting dispersion according to goal
% 
% Output: 
% Figures
% Ditting results

%% INPUT

addpath('functions/');

filenameExp = 'input/input_exp_H2-CO2-T32-P1500.xlsx';
pathImportAll = 'results/exp_H2-CO2-T32-P1500-H/';
pathExportAll = 'results/exp_H2-CO2-T32-P1500-H/';


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

load(pathImportAll+"expProcData.mat")


%% Fittingt short equation CF

Cj_guess = 1;
Ci_guess = 0;
p_guess = 1; % Kl = p^2 in fitting function fit_dispersion

for i = 1:length(filedataExp.Key)
    if filedataExp.Type(i) == "CF"
        C1_vals = expProcData.(filedataExp.Key(i)).BT.Ci_corr_mean;
        t_vals = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
        u_vals = expProcData.(filedataExp.Key(i)).exp_setup_params.u_SI;
        L_vals = expProcData.(filedataExp.Key(i)).exp_setup_params.L_SI;
        [KL,u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion(C1_vals/100,...
        t_vals, u_vals, Cj_guess,Ci_guess,L_vals,p_guess);
        expProcData.(filedataExp.Key(i)).exp_setup_params.KL1 = KL;
        expProcData.(filedataExp.Key(i)).exp_setup_params.u_fit = u_fit;
        expProcData.(filedataExp.Key(i)).exp_setup_params.Cj_fit = Cj_fit;
        expProcData.(filedataExp.Key(i)).exp_setup_params.Ci_fit = Ci_fit;
        expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit = C_fit;
    end
end

%% Fittingt short equation BP
D_lines_SI = 0.00240; %m2 %average 1/4in and 1/8in diameter tubing
A_lines_SI = pi*((D_lines_SI/2)^2);
L_lines_SI = 0.850; %m

for i = 1:length(filedataExp.Key)
    if filedataExp.Type(i) == "BP"
        C1_vals = expProcData.(filedataExp.Key(i)).BT.Ci_corr_mean;
        t_vals = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
        q_vals = expProcData.(filedataExp.Key(i)).exp_setup_params.q_SI;
        u_vals = expProcData.(filedataExp.Key(i)).exp_setup_params.u_SI;
        L_vals = expProcData.(filedataExp.Key(i)).exp_setup_params.L_SI;
        [KL,u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion(C1_vals/100,...
        t_vals, q_vals/A_lines_SI,Cj_guess,Ci_guess,L_lines_SI,p_guees);
        expProcData.(filedataExp.Key(i)).exp_setup_params.KL1 = KL;
        expProcData.(filedataExp.Key(i)).exp_setup_params.u_fit = u_fit;
        expProcData.(filedataExp.Key(i)).exp_setup_params.Cj_fit = Cj_fit;
        expProcData.(filedataExp.Key(i)).exp_setup_params.Ci_fit = Ci_fit;
        expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit = C_fit;
    end
end

%% Table with fitting results

fitting_results_v = table();
for i = 1:length(filedataExp.Key)
    if filedataExp.Type(i) == "CF"
        % fitting parameters results
        u_SI = expProcData.(filedataExp.Key(i)).exp_setup_params.u_SI;
        u_lines_SI = expProcData.(filedataExp.Key(i)).exp_setup_params.q_SI/A_lines_SI;
        u_fit_SI = expProcData.(filedataExp.Key(i)).exp_setup_params.u_fit;
        KL_SI = expProcData.(filedataExp.Key(i)).exp_setup_params.KL1;
        L_SI = expProcData.(filedataExp.Key(i)).exp_setup_params.L_SI;
        Cj_fit_SI = expProcData.(filedataExp.Key(i)).exp_setup_params.Cj_fit;
        Ci_fit_SI = expProcData.(filedataExp.Key(i)).exp_setup_params.Ci_fit;
        RMSE = expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit.RMSE;
        R2 = expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit.Rsquared.Adjusted;
        p = expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit.Coefficients.Estimate;
        SE_p = expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit.Coefficients.SE;
        SE_KL = (((2*p)^2)*(SE_p^2))^(1/2);
        T_mean = mean(expProcData.(filedataExp.Key(i)).BT.T_MFM);
        T_std = std(expProcData.(filedataExp.Key(i)).BT.T_MFM);
        % creating table
        row_temp = table(filedataExp.Key(i),u_SI,u_SI*60*100,u_lines_SI, ...
            u_lines_SI*60*100,u_fit_SI, u_fit_SI*60*100, ...
            KL_SI,KL_SI* 60 * 10^4, p, SE_p, SE_KL, (SE_KL)* 60 * 10^4, ...
            L_SI,L_SI*100,Cj_fit_SI,Ci_fit_SI, RMSE,R2,T_mean,T_std, ...
            'VariableNames',{'Key','u_SI','u_cmmin','ulines_SI','ulines_cmmin', ...
            'u_fit_SI','u_fit_cmmin','KL_SI','KL_cm2min', 'p','SE_p', 'SE_KL_SI','SE_KL_cm2min', ...
            'L_SI', 'L_cm','Cj_fit','Ci_fit','RMSE','R2','T_mean','T_std'});
        fitting_results_v = [fitting_results_v;row_temp];
    end
end
writetable(fitting_results_v,pathExportAll + "fittingResults_v.xlsx");
save(pathExportAll + "fitting_results_v.mat",'fitting_results_v')

%% Fitting and experimental data all CF plot

for i = 1:length(filedataExp.Key)
        figure
        scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.Ci_corr_mean,10,'filled','MarkerFaceColor','red')
        hold on
        plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
        xlabel('Time elapsed [hh:mm:ss]');
        xtickformat('hh:mm:ss')
        ylabel('Molar concentration C_1 [mol %]');
        title(filedataExp.Key(i) + " fitting", 'Interpreter', 'none')
        grid on;
        legend(["Experimental data", "BT model fitting"],'Location','southeast');
        saveas(gcf,pathImportAll + filedataExp.Key(i) + "_fitting",'png')
        savefig(gcf,pathImportAll + filedataExp.Key(i) + "_fitting")
end

%%
f1=figure;
for i = 1:length(filedataExp.Key)
    % if filedataExp.Fluid1(i) == "He"
    %     if filedataExp.T(i) == 40
    %         if filedataExp.Type(i) == "CF"
                plot(expProcData.(filedataExp.Key(i)).BT.Time,expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit1.feval(expProcData.(filedataExp.Key(i)).BT.TimeElapsed),'LineWidth',1.5,"DisplayName",filedataExp.Key(i))
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
                plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed*expProcData.(filedataExp.Key(i)).exp_setup_params.u_fit/expProcData.(filedataExp.Key(i)).exp_setup_params.L_SI,expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit1.feval(expProcData.(filedataExp.Key(i)).BT.TimeElapsed),'LineWidth',1.5,"DisplayName",filedataExp.Key(i))
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
            C1_fit_vals = expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit1.feval(t_elapsed_vals);
            % C1_fit_range = C1_fit_vals(C1_fit_vals < 1.1);
            % t_vals_range = t_vals(C1_fit_vals<1.1);
            h2 = scatter(t_vals,C1_vals,2,'filled','DisplayName',"Q = " + filedataExp.Q(i) +" ml/min",'MarkerFaceColor',colors(j,:),'HandleVisibility', 'off');
            h3 = plot(t_vals(C1_fit_vals<0.60),100*C1_fit_vals(C1_fit_vals<0.60),'HandleVisibility', 'off', 'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','-');
            h5 = plot(t_vals(C1_fit_vals>0.98),100*C1_fit_vals(C1_fit_vals>0.98),'DisplayName',"BT Fit - Q "+ filedataExp.Q(i) +" ml/min", 'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','-');
            h4 = plot(t_vals(C1_fit_vals>0.6 & C1_fit_vals<0.98),100*C1_fit_vals(C1_fit_vals>0.6 & C1_fit_vals<0.98),'DisplayName',"Extension BT Fit - Q "+ filedataExp.Q(i) +" ml/min", 'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','--');
            % h3 = plot(t_vals_range,100*C1_fit_range,'DisplayName',"BT Fit - Q "+ filedataExp.Q(i) +" ml/min",'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','-');
            % R2 = expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit1.Rsquared.Ordinary;
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
            tD = t_elapsed_vals*expProcData.(filedataExp.Key(i)).exp_setup_params.u_fit/expProcData.(filedataExp.Key(i)).exp_setup_params.L_SI;
            C1_fit_vals = expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit1.feval(t_elapsed_vals);
            C1_fit_range = C1_fit_vals(C1_fit_vals >0 & C1_fit_vals < 1);
            t_vals_range = t_vals(C1_fit_vals>0 & C1_fit_vals<1);
            h1 = errorbar(tD,C,dC,'Color',colors_error(j,:),'DisplayName',"MFM - Q " + filedataExp.Q(i) +" ml/min",'MarkerSize',10,'Marker','o','MarkerFaceColor',colors(j,:),'MarkerSize',5);
            set(h1, 'LineStyle', 'none'); 
            hold on
            h2 = scatter(tD,C1_vals,2,'filled','DisplayName',"Q = " + filedataExp.Q(i) +" ml/min",'MarkerFaceColor',colors(j,:),'HandleVisibility', 'off');
            h3 = plot(tD,100*C1_fit_vals,'DisplayName',"BT Fit - Q "+ filedataExp.Q(i) +" ml/min",'LineWidth',2,'Color', colors_fit(j,:),'LineStyle','-');
            % R2 = expProcData.(filedataExp.Key(i)).exp_setup_params.C_fit1.Rsquared.Ordinary;
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


