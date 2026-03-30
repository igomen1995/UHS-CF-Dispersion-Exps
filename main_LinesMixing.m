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
% Fitting results with mixing correction

%% INPUT

addpath('functions/');

filenameExp = 'input/input_exp_H2-CO2-T32-P1500.xlsx';
pathImportAll = 'results/exp_H2-CO2-T32-P1500-H/';
pathExportAll = 'results/exp_H2-CO2-T32-P1500-H/';


%% IMPORT variables

filedataExp = import_inputExp(filenameExp); % import input to a local variable

load(pathImportAll+"expProcData.mat")

%% adding lines data to exp_params

rlines_cm = 0.146;
Llinesbefore_cm = 340;
Llinesafter_cm = 120;
Deff = 0.411; % cm2/min

for i = 1:length(filedataExp.Key)
    expProcData.(filedataExp.Key(i)).exp_params.rlines_cm = rlines_cm;
    expProcData.(filedataExp.Key(i)).exp_params.Deff_cm2min = Deff;
    expProcData.(filedataExp.Key(i)).exp_params.Llinesbefore_cm = Llinesbefore_cm;
    expProcData.(filedataExp.Key(i)).exp_params.Llinesafter_cm = Llinesafter_cm;
    expProcData.(filedataExp.Key(i)).exp_params.Alinesbefore_cm = pi*rlines_cm^2;
    expProcData.(filedataExp.Key(i)).exp_params.Alinesafter_cm = pi*rlines_cm^2;
    expProcData.(filedataExp.Key(i)).exp_params.Dlinesbefore_cm = ...
    taylor_aris(expProcData.(filedataExp.Key(i)).exp_params.Q_mlmin, ...
    expProcData.(filedataExp.Key(i)).exp_params.Alinesbefore_cm, ...
    expProcData.(filedataExp.Key(i)).exp_params.rlines_cm, ...
    expProcData.(filedataExp.Key(i)).exp_params.Deff_cm2min);
    expProcData.(filedataExp.Key(i)).exp_params.Dlinesafter_cm = ...
    taylor_aris(expProcData.(filedataExp.Key(i)).exp_params.Q_mlmin, ...
    expProcData.(filedataExp.Key(i)).exp_params.Alinesafter_cm, ...
    expProcData.(filedataExp.Key(i)).exp_params.rlines_cm, ...
    expProcData.(filedataExp.Key(i)).exp_params.Deff_cm2min);
end

%%

for i = 1:length(filedataExp.Key)
    exp_params = expProcData.(filedataExp.Key(i)).exp_params;
    model = @(Dc,t) three_segment_model(t, Dc, ...
        exp_params.Q_mlmin/(60*10^6), exp_params.Alinesbefore_cm*(10^-4), ...
        exp_params.A_SI, exp_params.phi, exp_params.Alinesafter_cm*(10^-4), ...
        exp_params.Llinesbefore_cm*(10^-2), exp_params.L_SI, ...
        exp_params.Llinesafter_cm*(10^-2), ...
        expProcData.(filedataExp.Key(i)).exp_params.Dlinesbefore_cm/(60*10^4), ...
        expProcData.(filedataExp.Key(i)).exp_params.Dlinesafter_cm/(60*10^4), 1);
    
    t_vals_aux = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
    C1_vals_aux = expProcData.(filedataExp.Key(i)).BT.Ci_corr_mean/100;

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

    expProcData.(filedataExp.Key(i)).exp_params.Dcore_fit_SI = Dc_fit;
    expProcData.(filedataExp.Key(i)).exp_params.Dcore_fit_cm2min = Dc_fit*(60*10^4);

    C1_eval = model(Dc_fit,t_vals);

    expProcData.(filedataExp.Key(i)).BT_fit = table();
    expProcData.(filedataExp.Key(i)).BT_fit.SecondsElapsed = t_vals;
    expProcData.(filedataExp.Key(i)).BT_fit.Ci_corr_mean = C1_eval*100;

    C1_ob = ob_step(t_vals,exp_params.L_SI,exp_params.u_SI,Dc_fit,1);
    expProcData.(filedataExp.Key(i)).BT_fit.Ci_ob = C1_ob*100;
end

%%

for i = 1:length(filedataExp.Key)
        figure
        scatter(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed,expProcData.(filedataExp.Key(i)).BT.Ci_corr_mean,10,'filled','MarkerFaceColor','red')
        hold on
        scatter(expProcData.(filedataExp.Key(i)).BT_fit.SecondsElapsed,expProcData.(filedataExp.Key(i)).BT_fit.Ci_corr_mean,10,'filled','MarkerFaceColor','k')
        scatter(expProcData.(filedataExp.Key(i)).BT_fit.SecondsElapsed,expProcData.(filedataExp.Key(i)).BT_fit.Ci_ob,10,'filled','MarkerFaceColor','green')
        grid on;
end
