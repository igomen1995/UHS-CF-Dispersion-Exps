% main_Processing.m
% Author: Ianna Gomez Mendez
%
% Objective: Find KL corrected
% 
% Functions:
% fit_dispersion, only K fitting, L, v, Ci and Cj fixed
%
% Input (use Import Data tool in Matlab):
% 1 - filedataExp
% 2 - expProcFullData.mat all
% 
% Procedure:
% 1 - Load input
% 2 - Use fitting dispersion function and find KL and dt
% 3 - Plot all v to Kl to find alpha
% 4 - Plot all in dimensionless plot to find tortuosity
% 
% Output: 
% Figures
% Fitting results with mixing correction

%% INPUT

addpath('functions/');

filenameExp = 'input/input_exp_H2-CO2-T32-P1500.xlsx';
pathImportAll = 'results/exp_H2-CO2-T32-P1500-H/';
pathExportAll = 'results/exp_H2-CO2-T32-P1500-H/';


%% IMPORT variables

filedataExp = import_inputExp(filenameExp); % import input to a local variable

load(pathImportAll+"expProcFullData.mat")

%%

for i = 1:length(filedataExp.Key)
    exp_params = expProcFullData.(filedataExp.Key(i)).exp_params;
    r_before = 0.145/100;
    r_after = 0.08/100;
    % r_before = exp_params.ID_lines_cm/(2*100);
    % r_after = exp_params.ID_lines_cm/(2*100);
    A_before = pi*(r_before^2);
    A_after = pi*(r_after^2);

    v_lines_before = exp_params.q_SI/A_before;
    v_lines_after = exp_params.q_SI/A_after;
    KL_lines_before = KL_lines_taylor_aris(v_lines_before, r_before, exp_params.D0_SI);
    KL_lines_after = KL_lines_taylor_aris(v_lines_before, r_before, exp_params.D0_SI);

    % V_lines_total_cc = exp_params.Vlinesbefore_cc + exp_params.Vlinesafter_cc;
    % L_line_before = (exp_params.Vlinesbefore_cc/V_lines_total_cc)*exp_params.L_lines_mean_SI;
    % L_line_after = (exp_params.Vlinesafter_cc/V_lines_total_cc)*exp_params.L_lines_mean_SI;

    L_line_before = exp_params.L_linesbefore_SI;
    L_line_after = exp_params.L_linesafter_SI;

    model = @(Dc,t) three_segment_model(t, Dc, ...
        exp_params.q_SI, A_before, ...
        exp_params.A_SI, exp_params.phi, A_after, ...
        L_line_before, exp_params.L_SI, ...
        L_line_after, ...
        KL_lines_before, ...
        KL_lines_after, 1);
    
    t_vals_aux = expProcFullData.(filedataExp.Key(i)).BT.SecondsElapsed;
    C1_vals_aux = expProcFullData.(filedataExp.Key(i)).BT.Ci/100;

    %resampling to have constant dt
    idx_finite = isfinite(t_vals_aux) & isfinite(C1_vals_aux);
    t_vals_aux = t_vals_aux(idx_finite);
    C1_vals_aux = C1_vals_aux(idx_finite);
    dt = median(diff(t_vals_aux));
    t_vals = (t_vals_aux(1):dt:t_vals_aux(end))';
    C1_vals = interp1(t_vals_aux, C1_vals_aux, t_vals, 'linear');

    Dc0 = 1e-9;                 % initial guess
    lb = 0;                     % lower bound
    ub = 1e-3;                  % upper bound

    Dc_fit = lsqcurvefit(model, Dc0, t_vals, C1_vals, lb, ub);

    expProcFullData.(filedataExp.Key(i)).exp_params.Dcore_fit_SI = Dc_fit;
    expProcFullData.(filedataExp.Key(i)).exp_params.Dcore_fit_cm2min = Dc_fit*(60*10^4);

    C1_eval = model(Dc_fit,t_vals);

    model2 = @(Dc,t) three_segment_model(t, Dc, ...
    exp_params.q_SI, A_before, ...
    exp_params.A_SI, exp_params.phi, A_after, ...
    L_line_before, exp_params.L_SI, ...
    0, ...
    KL_lines_before, ...
    0, 1);

    Dc_fit_ups_core = lsqcurvefit(model2, Dc0, t_vals, C1_vals, lb, ub);

    expProcFullData.(filedataExp.Key(i)).exp_params.Dcore_fit_upscore_SI = Dc_fit_ups_core;
    expProcFullData.(filedataExp.Key(i)).exp_params.Dcore_fit_upscore_cm2min = Dc_fit_ups_core*(60*10^4);

    C1_eval_upscore = model2(Dc_fit_ups_core,t_vals);

    expProcFullData.(filedataExp.Key(i)).BT_fit = table();
    expProcFullData.(filedataExp.Key(i)).BT_fit.SecondsElapsed = t_vals;
    expProcFullData.(filedataExp.Key(i)).BT_fit.Ci_corr_mean = C1_eval*100;
    expProcFullData.(filedataExp.Key(i)).BT_fit.Ci_upscore = C1_eval_upscore*100;

    C1_ob = ob_step(t_vals,exp_params.L_SI,exp_params.u_SI,Dc_fit,1);
    expProcFullData.(filedataExp.Key(i)).BT_fit.Ci_ob = C1_ob*100;

    C1_ob_linesbefore = ob_step(t_vals,L_line_before,exp_params.v_lines_SI,exp_params.KL_lines_SI,1);
    expProcFullData.(filedataExp.Key(i)).BT_fit.C1_ob_linesbefore = C1_ob_linesbefore*100;

    C1_ob_linesafter = ob_step(t_vals,L_line_after,exp_params.v_lines_SI,exp_params.KL_lines_SI,1);
    expProcFullData.(filedataExp.Key(i)).BT_fit.C1_ob_linesafter = C1_ob_linesafter*100;
end

%%

for i = 1:length(filedataExp.Key)
        figure
        scatter(expProcFullData.(filedataExp.Key(i)).BT.SecondsElapsed,expProcFullData.(filedataExp.Key(i)).BT.Ci,10,'filled','MarkerFaceColor','red','DisplayName','Experimental Data')
        hold on
        % plot(expProcFullData.(filedataExp.Key(i)).BT_fit.SecondsElapsed,expProcFullData.(filedataExp.Key(i)).BT_fit.Ci_ob,'LineWidth',1.0,'Color','green','DisplayName','Ogatta Banks no t shift')
        plot(expProcFullData.(filedataExp.Key(i)).BT_fit.SecondsElapsed,expProcFullData.(filedataExp.Key(i)).BT_fit.C1_ob_linesbefore,'LineWidth',1.0,'Color',[0.5 0.5 0.5],'DisplayName','Ogatta Banks lines before')
        plot(expProcFullData.(filedataExp.Key(i)).BT_fit.SecondsElapsed,expProcFullData.(filedataExp.Key(i)).BT_fit.Ci_upscore,'LineWidth',1.0,'Color','k','DisplayName','Two steps conv')
        % plot(expProcFullData.(filedataExp.Key(i)).BT_fit.SecondsElapsed,expProcFullData.(filedataExp.Key(i)).BT_fit.C1_ob_linesafter,'LineWidth',1.0,'Color',[0.5 0.5 0.5],'DisplayName','Ogatta Banks lines after alone')
        plot(expProcFullData.(filedataExp.Key(i)).BT_fit.SecondsElapsed,expProcFullData.(filedataExp.Key(i)).BT_fit.Ci_corr_mean,'LineWidth',2.0,'Color','k','DisplayName','Three steps conv')
        plot(expProcFullData.(filedataExp.Key(i)).BT.SecondsElapsed,expProcFullData.(filedataExp.Key(i)).BT.C_fit_dt_fixed, 'LineWidth',1.0,'Color','blue','DisplayName','C model w t shift')
        % plot(expProcFullData.(filedataExp.Key(i)).BT.SecondsElapsed,expProcFullData.(filedataExp.Key(i)).BT.C_mean_fit_dt_fixed,'LineStyle','--', 'LineWidth',1.0,'Color','blue','DisplayName','C model mean t shift')
        plot(expProcFullData.(filedataExp.Key(i)).BT.SecondsElapsed,expProcFullData.(filedataExp.Key(i)).BT.C_nw_fit_dt_fixed,'LineStyle','--', 'LineWidth',1.0,'Color','k','DisplayName','C model nw t shift')
        xlabel('Seconds elapsed [seconds]');
        ylabel('Molar concentration C_1 [mol %]');
        ylim([-0.1,100.1]);
        grid on;
        legend('Location','southeast');
        saveas(gcf,pathExportAll + "C_mixing_lines_effect",'png')
        savefig(gcf,pathExportAll + "C_mixing_lines_effect")
end
hold off
