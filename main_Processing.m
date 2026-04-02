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

% No need to correct BT curve due to extra volume before core, the
% fit_dispersion_dt corrects for that extra t
load(pathImportAll+"expProcData.mat")

fitting_results_temp = table();
for i = 1:length(filedataExp.Key)
    if filedataExp.Type(i) == "CF"
        
        % data vasl for fitting
        t_vals = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
        C1_vals = expProcData.(filedataExp.Key(i)).BT.Ci/100;
        dC_vals = expProcData.(filedataExp.Key(i)).BT.dC/100;
        
        % experiment params (fixed for fitting)
        Ci = filedataExp.C1init(i)/100;
        Cj = filedataExp.C1j(i)/100;
        q = expProcData.(filedataExp.Key(i)).exp_params.Q_mlmin;
        u = expProcData.(filedataExp.Key(i)).exp_params.u_SI;
        L = expProcData.(filedataExp.Key(i)).exp_params.L_SI;
        D0 = expProcData.(filedataExp.Key(i)).exp_params.D12_cm2min/(60*10^4);
        dD0 = expProcData.(filedataExp.Key(i)).exp_params.dD12_cm2min/(60*10^4);
        Pe_D0 = u*L/D0;
        dPe_D0 = (((-u*L/(D0^2))^2)*(dD0^2))^(1/2);
        v_lines = expProcData.(filedataExp.Key(i)).exp_params.v_lines_SI;
        KL_lines = expProcData.(filedataExp.Key(i)).exp_params.KL_lines_SI;
        
        % dt shift guess = Vlines total / Q 
        dt_guess = (filedataExp.Vlinesbefore(i)+filedataExp.Vlinesafter(i))*60/filedataExp.Q(i); % time in seconds
        p_guess = [1,dt_guess];

        KL_out = fit_dispersion_dt_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,p_guess,dC_vals);%ones(size(C1_vals)))

        % exp params for table
        expProcData.(filedataExp.Key(i)).exp_params.u_cmmin = u*60*(10^2);
        expProcData.(filedataExp.Key(i)).exp_params.L_cm = L*100;
        expProcData.(filedataExp.Key(i)).exp_params.D0_SI = D0;
        expProcData.(filedataExp.Key(i)).exp_params.D0_cm2min = D0*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.dD0_SI = dD0;
        expProcData.(filedataExp.Key(i)).exp_params.dD0_cm2min = dD0*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.Pe_D0 = Pe_D0;
        expProcData.(filedataExp.Key(i)).exp_params.dPe_D0 = dPe_D0;

        % Fitting parameters mean
        KL_fit = KL_out.KL;
        dKL_fit = KL_out.dKL;
        dt_fit = KL_out.dt;
        d_dt_fit = KL_out.ddt;
        C_fit = KL_out.C_fit; % Best fit model prediction using estimated parameters
        C_pred = KL_out.C_pred; % 95% prediction interval, which includes paramters uncertainty and residual variance
        dC_pred = KL_out.dC_pred;
        RMSE = KL_out.RMSE;
        R2 = KL_out.R2;
        C_function = KL_out.Cfun;
        R = KL_out.R;
        J = KL_out.J;
        CovB = KL_out.CovB;
        MSE = KL_out.MSE;
        ErrorModelInfo = KL_out.ErrorModelInfo;

        Pe = u*L/KL_fit;
        dtD = u*dt_fit/L;% respect to Vcore
        L_lines = v_lines*dt_fit;
        V_lines_cc = q*dt_fit/60;
        dPe = (((-u*L*((KL_fit)^-2))^2)*(dKL_fit^2))^(1/2);
        d_dtD = (((u/L)^2)*(d_dt_fit^2))^(1/2);
        dL_lines = ((v_lines^2)*(d_dt_fit^2))^(1/2);
        dV_lines_cc = q*d_dt_fit/60;

        expProcData.(filedataExp.Key(i)).exp_params.C_fun = {C_function};
        expProcData.(filedataExp.Key(i)).exp_params.RMSE = RMSE;
        expProcData.(filedataExp.Key(i)).exp_params.R2 = R2;
        expProcData.(filedataExp.Key(i)).exp_params.KL_SI = KL_fit;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_SI = dKL_fit;
        expProcData.(filedataExp.Key(i)).exp_params.KL_cm2min = KL_fit*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_cm2min = (dKL_fit)*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.Pe = Pe;
        expProcData.(filedataExp.Key(i)).exp_params.SE_Pe = dPe;
        expProcData.(filedataExp.Key(i)).exp_params.dt_SI = dt_fit;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dt_SI = d_dt_fit;
        expProcData.(filedataExp.Key(i)).exp_params.dt_min = dt_fit/60;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dt_min = d_dt_fit/60;
        expProcData.(filedataExp.Key(i)).exp_params.dtD = dtD;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dtD = d_dtD;
        expProcData.(filedataExp.Key(i)).exp_params.L_lines_SI = L_lines;
        expProcData.(filedataExp.Key(i)).exp_params.SE_L_lines_SI = dL_lines;
        expProcData.(filedataExp.Key(i)).exp_params.L_lines_cm = L_lines*100;
        expProcData.(filedataExp.Key(i)).exp_params.SE_L_lines_cm = dL_lines*100;
        expProcData.(filedataExp.Key(i)).exp_params.V_lines_SI = V_lines_cc*(10^-6);
        expProcData.(filedataExp.Key(i)).exp_params.SE_V_lines_SI = dV_lines_cc*(10^-6);
        expProcData.(filedataExp.Key(i)).exp_params.V_lines_cc = V_lines_cc;
        expProcData.(filedataExp.Key(i)).exp_params.SE_V_lines_cc = dV_lines_cc;

        % Temperature stats
        T_mean = mean(expProcData.(filedataExp.Key(i)).BT.T_MFM);
        expProcData.(filedataExp.Key(i)).exp_params.T_mean = T_mean;
        T_std = std(expProcData.(filedataExp.Key(i)).BT.T_MFM);
        expProcData.(filedataExp.Key(i)).exp_params.T_std = T_std;

        % creating table
        row_temp = expProcData.(filedataExp.Key(i)).exp_params;  
        fitting_results_temp = [fitting_results_temp;row_temp];

        % Predicted C BT
        expProcData.(filedataExp.Key(i)).BT.C_fit_dt_free = 100*C_fit;
        expProcData.(filedataExp.Key(i)).BT.C_pred_dt_free = 100*C_pred;
        % dimensionless values 
        % Cd = (C - Ciinit) / (Cj - Cinit)
        expProcData.(filedataExp.Key(i)).BT.CD_fit_dt_fixed = ...
            (expProcData.(filedataExp.Key(i)).BT.C_fit_dt_free - filedataExp.C1init(i))/(filedataExp.C1j(i)-filedataExp.C1init(i));
    end
end
fitting_results = table();
for i = 1:length(filedataExp.Key)
    if filedataExp.Type(i) == "CF"

        % data vasl for fitting
        t_vals = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
        C1_vals = expProcData.(filedataExp.Key(i)).BT.Ci/100;
        dC_vals = expProcData.(filedataExp.Key(i)).BT.dC/100;
        
        % experiment params (fixed for fitting)
        Ci = filedataExp.C1init(i)/100;
        Cj = filedataExp.C1j(i)/100;
        q = expProcData.(filedataExp.Key(i)).exp_params.Q_mlmin;
        u = expProcData.(filedataExp.Key(i)).exp_params.u_SI;
        L = expProcData.(filedataExp.Key(i)).exp_params.L_SI;
        D0 = expProcData.(filedataExp.Key(i)).exp_params.D12_cm2min/(60*10^4);
        dD0 = expProcData.(filedataExp.Key(i)).exp_params.dD12_cm2min/(60*10^4);
        Pe_D0 = u*L/D0;
        dPe_D0 = (((-u*L/(D0^2))^2)*(dD0^2))^(1/2);
        v_lines = expProcData.(filedataExp.Key(i)).exp_params.v_lines_SI;
        KL_lines = expProcData.(filedataExp.Key(i)).exp_params.KL_lines_SI;

        dtD_guess = (fitting_results_temp.dtD')*(fitting_results_temp.SE_dtD/sum(fitting_results_temp.SE_dtD)); % dtD fixed is a weigthed average
        d_dt_dtfixed_SI = (fitting_results_temp.SE_dt_SI')*(fitting_results_temp.SE_dtD/sum(fitting_results_temp.SE_dtD));
        dt_fixed = dtD_guess*L/u; %  dt estimate according to velocity of each experiment
        p_guess = sqrt(expProcData.(filedataExp.Key(i)).exp_params.KL_SI);

        KL_dt_fixed_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,dC_vals);%ones(size(C1_vals)));

        % Fitting parameters mean
        KL_fit = KL_dt_fixed_out.KL;
        dKL_fit = KL_dt_fixed_out.dKL;
        dt_fit = KL_dt_fixed_out.dt;
        d_dt_fit = d_dt_dtfixed_SI; %KL_dt_fixed_out.ddt;
        C_fit = KL_dt_fixed_out.C_fit; % Best fit model prediction using estimated parameters
        C_pred = KL_dt_fixed_out.C_pred; % 95% prediction interval, which includes paramters uncertainty and residual variance
        dC_pred = KL_dt_fixed_out.dC_pred;
        RMSE = KL_dt_fixed_out.RMSE;
        R2 = KL_dt_fixed_out.R2;
        C_function = KL_dt_fixed_out.Cfun;
        R = KL_dt_fixed_out.R;
        J = KL_dt_fixed_out.J;
        CovB = KL_dt_fixed_out.CovB;
        MSE = KL_dt_fixed_out.MSE;
        ErrorModelInfo = KL_dt_fixed_out.ErrorModelInfo;

        Pe = u*L/KL_fit;
        dtD = u*dt_fit/L;% respect to Vcore
        L_lines = v_lines*dt_fit;
        V_lines_cc = q*dt_fit/60;
        dPe = (((-u*L*((KL_fit)^-2))^2)*(dKL_fit^2))^(1/2);
        d_dtD = (((u/L)^2)*(d_dt_fit^2))^(1/2);
        dL_lines = ((v_lines^2)*(d_dt_fit^2))^(1/2);
        dV_lines_cc = q*d_dt_fit/60;

        expProcData.(filedataExp.Key(i)).exp_params.C_fun_dtfixed = {C_function};
        expProcData.(filedataExp.Key(i)).exp_params.RMSE_dtfixed = RMSE;
        expProcData.(filedataExp.Key(i)).exp_params.R2_dtfixed = R2;
        expProcData.(filedataExp.Key(i)).exp_params.KL_dtfixed_SI = KL_fit;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_dtfixed_SI = dKL_fit;
        expProcData.(filedataExp.Key(i)).exp_params.KL_dtfixed_cm2min = KL_fit*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_dtfixed_cm2min = (dKL_fit)*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.Pe_dtfixed = Pe;
        expProcData.(filedataExp.Key(i)).exp_params.SE_Pe_dtfixed = dPe;
        expProcData.(filedataExp.Key(i)).exp_params.dt_dtfixed_SI = dt_fit;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dt_dtfixed_SI = d_dt_fit; 
        expProcData.(filedataExp.Key(i)).exp_params.dt_dtfixed_min = dt_fit/60;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dt_dtfixed_min = d_dt_fit/60; 
        expProcData.(filedataExp.Key(i)).exp_params.dtD_dtfixed = dtD;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dtD_dtfixed = d_dtD;
        expProcData.(filedataExp.Key(i)).exp_params.L_dtfixed_lines_SI = L_lines;
        expProcData.(filedataExp.Key(i)).exp_params.SE_L_dtfixed_lines_SI = dL_lines;
        expProcData.(filedataExp.Key(i)).exp_params.L_dtfixed_lines_cm = L_lines*100;
        expProcData.(filedataExp.Key(i)).exp_params.SE_L_dtfixed_lines_cm = dL_lines*100;
        expProcData.(filedataExp.Key(i)).exp_params.V_dtfixed_lines_SI = V_lines_cc*(10^-6);
        expProcData.(filedataExp.Key(i)).exp_params.SE_V_dtfixed_lines_SI = dV_lines_cc*(10^-6);
        expProcData.(filedataExp.Key(i)).exp_params.V_dtfixed_lines_cc = V_lines_cc;
        expProcData.(filedataExp.Key(i)).exp_params.SE_V_dtfixed_lines_cc = dV_lines_cc;

        % Uncertainty propagation from dt_free error
        d_dt_free = expProcData.(filedataExp.Key(i)).exp_params.SE_dt_SI;

        KL_dt_fixed_max_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed+d_dt_free,p_guess,dC_vals);%ones(size(C1_vals)));
        KL_dt_fixed_min_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed-d_dt_free,p_guess,dC_vals);%ones(size(C1_vals)));

        KL_max_fit = KL_dt_fixed_max_out.KL;
        KL_min_fit = KL_dt_fixed_min_out.KL;
        dKL_dtfree = abs(KL_max_fit - KL_min_fit)/2; % (dKL/dt)*dt = ((KL+ -KL-)/(2dt))*dt
        dKL_total = (dKL_dtfree^2 + dKL_fit^2)^(1/2);

        expProcData.(filedataExp.Key(i)).exp_params.KL_max_dtfixed_SI = KL_max_fit;
        expProcData.(filedataExp.Key(i)).exp_params.KL_max_dtfixed_cm2min = KL_max_fit*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.KL_min_dtfixed_SI = KL_min_fit;
        expProcData.(filedataExp.Key(i)).exp_params.KL_min_dtfixed_cm2min = KL_min_fit*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_dtfree_dtfixed_SI = dKL_dtfree;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_dtfree_dtfixed_cm2min = dKL_dtfree*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_total_dtfixed_SI = dKL_total;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_total_dtfixed_cm2min = dKL_total*60*10^4;

        % creating table
        row_temp = expProcData.(filedataExp.Key(i)).exp_params;  
        fitting_results = [fitting_results;row_temp];

        % Predicted C BT
        expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed = 100*C_fit;
        expProcData.(filedataExp.Key(i)).BT.C_pred_dt_fixed = 100*C_pred;
        % dimensionless values 
        % Cd = (C - Ciinit) / (Cj - Cinit)
        expProcData.(filedataExp.Key(i)).BT.CD_fit_dt_fixed = ...
            (expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed - filedataExp.C1init(i))/(filedataExp.C1j(i)-filedataExp.C1init(i));

        % Corrected BT with time shift
        expProcData.(filedataExp.Key(i)).BT.SecondsElapsed_corr = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed - dt_fit;
        % Corrected BT with dimensionless time shift
        expProcData.(filedataExp.Key(i)).BT.tD_corr = expProcData.(filedataExp.Key(i)).BT.tD - dtD;
        expProcData.(filedataExp.Key(i)).BT.tDtotal_corr = expProcData.(filedataExp.Key(i)).BT.tDtotal - dtD;

        % BT corr
        expProcData.(filedataExp.Key(i)).BT_corr = expProcData.(filedataExp.Key(i)).BT(expProcData.(filedataExp.Key(i)).BT.tD_corr>=0,:);
        SecondsElapsedNew_aux = seconds(expProcData.(filedataExp.Key(i)).BT_corr.SecondsElapsed_corr);
        SecondsElapsedNew_aux.Format = 'hh:mm:ss.SSS';
        expProcData.(filedataExp.Key(i)).BT_corr.TimeElapsedNew = SecondsElapsedNew_aux;
    end
end

%% Estimate alpha and tortuosity

% Pe with Dp = L; Pe = u*L/D0
% KL = D0 *(1/tao + C2((Pe)^beta))
% KL = D0 *(1/tao + ((C2^(1/beta))*(Pe))^beta)
% alpha_L = (C2^(1/beta)*L

% all params in SI
Dp_SI = unique(fitting_results.L_SI); % Dp characteristic length in Peclet number
u_array = fitting_results.u_SI;
D0 = unique(fitting_results.D0_SI);
dD0 = unique(fitting_results.dD0_SI);
Pe_D0_array = fitting_results.Pe_D0; % Pe in respect to D0
dPe_D0_array = fitting_results.dPe_D0;

% KL_array = fitting_results.KL_SI; % KL and D0 must have same units
% dKL_array = fitting_results.SE_KL_SI;
KL_array = fitting_results.KL_dtfixed_SI; % KL and D0 must have same units
dKL_array = fitting_results.SE_KL_total_dtfixed_SI;

% Fitting
p_guess = 1;

% weighted
fit_dispersion_params_all_out = fit_dispersion_params_all(KL_array,Pe_D0_array,D0,Dp_SI,p_guess,dKL_array);
%nonweighted
fit_dispersion_params_all_nw_out = fit_dispersion_params_all(KL_array,Pe_D0_array,D0,Dp_SI,p_guess,ones(size(KL_array)));

% Propagation of uncertainty from D0 error
D0max = D0 + dD0;
D0min = D0 - dD0;
Pe_D0max_array = Pe_D0_array*(D0/D0max); % Pe in respect to D0max
Pe_D0min_array = Pe_D0_array*(D0/D0min); % Pe in respect to D0min

% Fitting KL with different Pe ranges
fit_dispersion_params_all_Pe_D0max_out = fit_dispersion_params_all(KL_array,Pe_D0max_array,D0max,Dp_SI,p_guess,dKL_array);
fit_dispersion_params_all_Pe_D0min_out = fit_dispersion_params_all(KL_array,Pe_D0min_array,D0min,Dp_SI,p_guess,dKL_array);
fit_dispersion_params_all_Pe_D0max_nw_out = fit_dispersion_params_all(KL_array,Pe_D0max_array,D0max,Dp_SI,p_guess,ones(size(KL_array)));
fit_dispersion_params_all_Pe_D0min_nw_out = fit_dispersion_params_all(KL_array,Pe_D0min_array,D0min,Dp_SI,p_guess,ones(size(KL_array)));

% Params from fitting
beta = fit_dispersion_params_all_out.beta;
d_beta = fit_dispersion_params_all_out.d_beta;

% alphas
% alpha weigthed
alpha_w_SI = fit_dispersion_params_all_out.alpha_SI;
d_alpha_w_SI = fit_dispersion_params_all_out.d_alpha_SI;
alpha_w_cm = fit_dispersion_params_all_out.alpha_cm;
d_alpha_w_cm = fit_dispersion_params_all_out.d_alpha_cm;
% alpha non weigthed
alpha_nw_SI = fit_dispersion_params_all_nw_out.alpha_SI;
d_alpha_nw_SI = fit_dispersion_params_all_nw_out.d_alpha_SI;
alpha_nw_cm = fit_dispersion_params_all_nw_out.alpha_cm;
d_alpha_nw_cm = fit_dispersion_params_all_nw_out.d_alpha_cm;
% alpha weigthed D0 effect
alpha_D0max_w_SI = fit_dispersion_params_all_Pe_D0max_out.alpha_SI;
alpha_D0min_w_SI = fit_dispersion_params_all_Pe_D0min_out.alpha_SI;
d_alpha_D0uncert_w_SI = abs(alpha_D0max_w_SI - alpha_D0min_w_SI)/2;
alpha_D0max_w_cm = fit_dispersion_params_all_Pe_D0max_out.alpha_cm;
alpha_D0min_w_cm = fit_dispersion_params_all_Pe_D0min_out.alpha_cm;
d_alpha_D0uncert_w_cm = abs(alpha_D0max_w_cm - alpha_D0min_w_cm)/2;
% alpha non weigthed D0 effect
alpha_D0max_nw_SI = fit_dispersion_params_all_Pe_D0max_nw_out.alpha_SI;
alpha_D0min_nw_SI = fit_dispersion_params_all_Pe_D0min_nw_out.alpha_SI;
d_alpha_D0uncert_nw_SI = abs(alpha_D0max_nw_SI - alpha_D0min_nw_SI)/2;
alpha_D0max_nw_cm = fit_dispersion_params_all_Pe_D0max_nw_out.alpha_cm;
alpha_D0min_nw_cm = fit_dispersion_params_all_Pe_D0min_nw_out.alpha_cm;
d_alpha_D0uncert_nw_cm = abs(alpha_D0max_nw_cm - alpha_D0min_nw_cm)/2;

alphas_SI = [alpha_w_SI,alpha_nw_SI,alpha_D0max_w_SI,alpha_D0min_w_SI,alpha_D0max_nw_SI,alpha_D0min_nw_SI];
alphas_cm = [alpha_w_cm,alpha_nw_cm,alpha_D0max_w_cm,alpha_D0min_w_cm,alpha_D0max_nw_cm,alpha_D0min_nw_cm];
d_alphas_SI = [d_alpha_w_SI,d_alpha_nw_SI,d_alpha_D0uncert_w_SI,d_alpha_D0uncert_nw_SI];
d_alphas_cm = [d_alpha_w_cm,d_alpha_nw_cm,d_alpha_D0uncert_w_cm,d_alpha_D0uncert_nw_cm];

alpha_mean_SI = mean(alphas_SI);
alpha_mean_cm = mean(alphas_cm);
d_alpha_sens_SI = max(abs(alphas_SI - alpha_mean_SI));
d_alpha_sens_cm = max(abs(alphas_cm - alpha_mean_cm));

% C2 in model is alpha/Dp Dp is characterstic legth L

KL_fit = fit_dispersion_params_all_out.Cfun(alpha_mean_SI/Dp_SI,Pe_D0_array);
KL_alphamax_fit = fit_dispersion_params_all_out.Cfun((alpha_mean_SI+d_alpha_sens_SI)/Dp_SI,Pe_D0_array);
KL_alphamin_fit = fit_dispersion_params_all_out.Cfun((alpha_mean_SI-d_alpha_sens_SI)/Dp_SI,Pe_D0_array);
dKL_alpha_sens = abs(KL_alphamax_fit - KL_alphamin_fit)/2;

% RMSE = fit_dispersion_params_all_out.RMSE;
% R2 = fit_dispersion_params_all_out.R2;

% Peclet with Dp = alpha instead of L
Pe_alpha_array = u_array*alpha_mean_SI/D0;
dPe_alpha_array = (((u_array/D0).^2)*(d_alpha_sens_SI^2)+((-u_array*alpha_mean_SI/(D0^2)).^2)*(dD0^2)).^(1/2);
% KL/D0, must be same units
KL_vs_D0_array = KL_array/D0;
dKL_vs_D0_array = (((1/D0).^2)*(dKL_alpha_sens.^2)+((-KL_array/(D0^2)).^2)*(dD0^2)).^(1/2); %dKL array instead of dKL total
% since it is the result from fitting C vs t, not plotting the results from this fitting

% Add dispersion parameters in exp_params and fitting results
fitting_results.Pe_alpha = Pe_alpha_array;
fitting_results.dPe_alpha = dPe_alpha_array;
fitting_results.KL_vs_D0 = KL_vs_D0_array;
fitting_results.dKL_vs_D0 = dKL_vs_D0_array;
for i = 1:length(filedataExp.Key)
    expProcData.(filedataExp.Key(i)).exp_params.Pe_alpha = Pe_alpha_array(i);
    expProcData.(filedataExp.Key(i)).exp_params.dPe_alpha = dPe_alpha_array(i);
    expProcData.(filedataExp.Key(i)).exp_params.KL_vs_D0 = KL_vs_D0_array(i);
    expProcData.(filedataExp.Key(i)).exp_params.dKL_vs_D0 = dKL_vs_D0_array(i);
end

expProcFullData = expProcData;

% save updated expProcData
save(pathExportAll + "expProcFullData.mat",'expProcFullData')

%% Table results

% creating table all in cm2 and min, and mol %
% Pe alone is Pe in respect to KL and not D0
fitting_results_simple = fitting_results(:, {'Key', 'C1init_pcmol', ...
    'C1j_pcmol', 'Q_mlmin', 'u_cmmin', 'RMSE_dtfixed', 'R2_dtfixed', ...
    'KL_dtfixed_cm2min','SE_KL_total_dtfixed_cm2min','Pe_dtfixed', 'SE_Pe_dtfixed', ...
    'dt_dtfixed_min', 'SE_dt_min', 'dtD_dtfixed', 'SE_dtD', ...
    'L_dtfixed_lines_cm','SE_L_dtfixed_lines_cm',...
    'Pe_D0', 'dPe_D0', 'Pe_alpha', 'dPe_alpha', 'T_mean', 'T_std'});

fitting_params_simple = table("Berea", unique(fitting_results.Fluid1), unique(fitting_results.Fluid2),...
    unique(fitting_results.T_C),unique(fitting_results.P_psig), (unique(fitting_results.P_psig)+14.7)*0.00689476,...
    unique(fitting_results.D12_cm2min), unique(fitting_results.dD12_cm2min), ...
    unique(fitting_results.D_in)*2.54, unique(fitting_results.L_cm), ...
    unique(fitting_results.phi),unique(fitting_results.K_mD), ...
    unique(fitting_results.dtD_dtfixed), max(fitting_results.L_dtfixed_lines_cm),max(fitting_results.SE_L_dtfixed_lines_cm),...
    unique(fitting_results.Vlinesbefore_cc), max(fitting_results.V_dtfixed_lines_cc),max(fitting_results.SE_V_dtfixed_lines_cc),...
    alpha_mean_cm, d_alpha_sens_cm, beta, ...
    'VariableNames',{'Sample', 'Fluid1','Fluid2', ...
    'T_C','P_psig','P_MPa', ...
    'D0_cm2min', 'dD0_cm2min', ...
    'D_cm', 'L_cm', ...
    'phi',  'K_mD', ...
    'dtD_fixed','L_lines_before_dtfixed_cm','sd_L_lines_before_dtfixed_cm',...
    'Vlinesbefore_cc','V_lines_before_dtfixed_cc','sd_V_lines_before_dtfixed_cc',...
    'alpha_cm', 'sd_alpha_cm','beta'});

fittingDispersionResults.results = fitting_results_simple;
fittingDispersionResults.params = fitting_params_simple;

%% Save tables and matrices

% name to save matrices and spreadsheets
table_name = pathExportAll + "fittingResults";  % Name used for saving TrimData comes from input pathExportAll
table_name1 = pathExportAll + "fittingResultsSimple";  % Name used for saving TrimData comes from input pathExportAll
table_name2 = pathExportAll + "fittingResultsParams";  % Name used for saving TrimData comes from input pathExportAll

% delete previous saved files
delete(table_name + '.mat');
delete(table_name + '.xlsx');
delete(table_name1 + '.mat');
delete(table_name1 + '.xlsx');
delete(table_name2 + '.mat');
delete(table_name2 + '.xlsx');

% save fitting_results
writetable(fitting_results,table_name + ".xlsx");
save(table_name + ".mat",'fitting_results')

% save updated expProcData
save(pathExportAll + "expProcFullData.mat",'expProcFullData')

% save fitting table
writetable(fitting_results_simple,table_name1 + ".xlsx");
writetable(fitting_params_simple,table_name2 + ".xlsx");
save(table_name1 + ".mat",'fitting_results_simple')
save(table_name2 + ".mat",'fitting_params_simple')

%% Fitting and experimental data all CF plot
% dt not shifted

for i = 1:length(filedataExp.Key)
        figure
        scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.Ci,10,'filled','MarkerFaceColor','red')
        hold on
        plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed,'LineWidth',1.5,'Color', [0.5 0.5 0.5])
        plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.C_fit_dt_free,'LineWidth',1.5,'Color', 'k')
        % 
        % plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
        % plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', [0.5 0.5 0.5])
        % xlabel('Time elapsed [hh:mm:ss]');
        xtickformat('hh:mm:ss')
        ylabel('Molar concentration C_1 [mol %]');
        ylim([-0.1,100.1]);
        title(filedataExp.Key(i) + " fitting", 'Interpreter', 'none')
        grid on;
        legend(["Experimental data", "BT model fitting - dt fixed", "BT model fitting - dt free"],'Location','southeast');
        saveas(gcf,pathExportAll + filedataExp.Key(i) + "_fitting",'png')
        savefig(gcf,pathExportAll + filedataExp.Key(i) + "_fitting")
end

%% Fitting and experimental data all CF plot dimensionless

for i = 1:length(filedataExp.Key)
        figure
        scatter(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled','MarkerFaceColor','red')
        hold on
        plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
        %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', [0.5 0.5 0.5])
        xlabel('Dimensionless Time [-]');
        % xlim([0,2]);
        ylabel('C_{D}[-]');
        ylim([-0.001,1.001]);
        title(filedataExp.Key(i) + " dimensionless fitting", 'Interpreter', 'none')
        grid on;
        legend(["Experimental data", "BT model fitting"],'Location','southeast');
        saveas(gcf,pathExportAll + filedataExp.Key(i) + "_dimless_fitting",'png')
        savefig(gcf,pathExportAll + filedataExp.Key(i) + "_dimless_fitting")
end

% Fitting and experimental data all CF plot dimensionless total

for i = 1:length(filedataExp.Key)
        figure
        scatter(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled','MarkerFaceColor','red')
        hold on
        plot(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
        %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', [0.5 0.5 0.5])
        xlabel('Dimensionless Time [-]');
        % xlim([0,2]);
        ylabel('C_{D}[-]');
        ylim([-0.001,1.001]);
        title(filedataExp.Key(i) + " dimensionless fitting", 'Interpreter', 'none')
        grid on;
        legend(["Experimental data", "BT model fitting"],'Location','southeast');
        saveas(gcf,pathExportAll + filedataExp.Key(i) + "_dimlessTotal_fitting",'png')
        savefig(gcf,pathExportAll + filedataExp.Key(i) + "_dimlessTotal_fitting")
end

%% Fitting and experimental data all CF plot
% dt shifted

colors = orderedcolors("glow");
figure
for i = 1:length(filedataExp.Key)
        scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed, ...
            expProcData.(filedataExp.Key(i)).BT.Ci,10,'filled', ...
            'MarkerFaceColor',colors(i,:),'DisplayName',"Q"+filedataExp.Q(i));
        hold on
        scatter(expProcData.(filedataExp.Key(i)).BT_corr.TimeElapsedNew, ...
            expProcData.(filedataExp.Key(i)).BT_corr.Ci,10,'filled', ...
            'MarkerFaceColor',colors(length(filedataExp.Key)+i,:),'DisplayName',"Q"+filedataExp.Q(i)+"-t_{shifted}")
        %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
        %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', [0.5 0.5 0.5])
        xlabel('Time elapsed [hh:mm:ss]');
        xtickformat('hh:mm:ss')
        ylabel('Molar concentration C_1 [mol %]');
        ylim([-0.1,100.1]);
        title(filedataExp.Key(i) + " fitting", 'Interpreter', 'none')
        grid on;
        legend('Location','southeast');
end
saveas(gcf,pathExportAll + "dtshift_fitting",'png')
savefig(gcf,pathExportAll + "dtshift_fitting")
%% Fitting and experimental data all CF plot dimensionless
% tD shifted
colors = orderedcolors("glow");
figure
for i = 1:length(filedataExp.Key)
        scatter(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled','MarkerFaceColor',colors(i,:), 'DisplayName',"Q"+filedataExp.Q(i))
        hold on
        scatter(expProcData.(filedataExp.Key(i)).BT_corr.tD_corr,expProcData.(filedataExp.Key(i)).BT_corr.CDi,10,'filled','MarkerFaceColor',colors(length(filedataExp.Key)+i,:), 'DisplayName',"Q"+filedataExp.Q(i)+"-t_{shifted}")
        %plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
        %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', [0.5 0.5 0.5])
        xlabel('Dimensionless Time [-]');
        % xlim([0,2]);
        ylabel('C_{D}[-]');
        ylim([-0.001,1.001]);
        title(filedataExp.Key(i) + " dimensionless fitting", 'Interpreter', 'none')
        grid on;
        legend('Location','southeast');
end
saveas(gcf,pathExportAll + "dimless_tDshift_fitting",'png')
savefig(gcf,pathExportAll + "dimless_tDshift_fitting")

% Fitting and experimental data all CF plot dimensionless total
% tD shifted
colors = orderedcolors("glow");
figure
for i = 1:length(filedataExp.Key)
        scatter(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled','MarkerFaceColor',colors(i,:), 'DisplayName',"Q"+filedataExp.Q(i))
        hold on
        scatter(expProcData.(filedataExp.Key(i)).BT_corr.tDtotal_corr,expProcData.(filedataExp.Key(i)).BT_corr.CDi,10,'filled','MarkerFaceColor',colors(length(filedataExp.Key)+i,:), 'DisplayName',"Q"+filedataExp.Q(i)+"-t_{shifted}")
        %plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
        %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', [0.5 0.5 0.5])
        xlabel('Dimensionless Time [-]');
        % xlim([0,2]);
        ylabel('C_{D}[-]');
        ylim([-0.001,1.001]);
        title(filedataExp.Key(i) + " dimensionless fitting", 'Interpreter', 'none')
        grid on;
        legend('Location','southeast');
end
saveas(gcf,pathExportAll + "dimless_tDshiftTotal_fitting",'png')
savefig(gcf,pathExportAll + "dimless_tDshiftTotal_fitting")

%% Fitting and experimental data all CF plot

colors = orderedcolors("glow");
figure
h=[];
for i = 1:length(filedataExp.Key)
    t = expProcData.(filedataExp.Key(i)).BT.TimeElapsed;
    t_sec = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
    C1 = expProcData.(filedataExp.Key(i)).BT.Ci;
    C1min = expProcData.(filedataExp.Key(i)).BT.CiMin;
    C1max = expProcData.(filedataExp.Key(i)).BT.CiMax;
    cond = (expProcData.(filedataExp.Key(i)).BT.Cimodel>=10)&(expProcData.(filedataExp.Key(i)).BT.Cimodel<=90);
    % errorbar(t(cond), expProcData.(filedataExp.Key(i)).BT.Cimodel(cond), ...
    %    expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.RMSE*100*ones(size(t(cond))), ...
    %    'LineStyle', 'none', ...
    %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
    % hold on
    errorbar(t, C1, C1-C1min, C1max - C1, 'LineStyle', 'none', ...
        'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
    hold on
    h1 = scatter(t,C1,5,'filled','MarkerFaceColor',colors(i,:), ...
        'DisplayName',"Q"+filedataExp.Q(i)+": C_{MFM} \pm \DeltaC_{MFM}");
    h2 = plot(t(cond), expProcData.(filedataExp.Key(i)).BT.Cimodel(cond), ...
        'LineWidth',1.0,'Color', 'k','DisplayName',"C_{fit} \pm \DeltaC_{fit}");
    xlabel('Time elapsed [hh:mm:ss]');
    xtickformat('hh:mm:ss')
    ylabel('Molar concentration C_1 [mol %]');
    ylim([-0.1,100.1]);
    title("Breakthrough curves fitting", 'Interpreter', 'none')
    grid on;
    h = [h; h1];
end
legend([h;h2], 'Location','southeast');
saveas(gcf,pathExportAll + "BTfitting",'png')
savefig(gcf,pathExportAll + "BTfitting")

%% Fitting and experimental data all CF plot
% dimensionless 

colors = orderedcolors("glow");
figure
h=[];
for i = 1:length(filedataExp.Key)
    tD = expProcData.(filedataExp.Key(i)).BT.tD;
    CD1 = expProcData.(filedataExp.Key(i)).BT.CDi;
    CD1min = expProcData.(filedataExp.Key(i)).BT.CDiMin;
    CD1max = expProcData.(filedataExp.Key(i)).BT.CDiMax;
    cond = (expProcData.(filedataExp.Key(i)).BT.Cimodel>=10)&(expProcData.(filedataExp.Key(i)).BT.Cimodel<=90);
    % errorbar(tD(cond), expProcData.(filedataExp.Key(i)).BT.CDimodel(cond), ...
    %    expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.RMSE*ones(size(tD(cond))), ...
    %    'LineStyle', 'none', ...
    %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
    % hold on
    % errorbar(tD, CD1, CD1-CD1min, CD1max - CD1, 'LineStyle', 'none', ...
    %     'Color', [1 0.78 0.88],'HandleVisibility','Off')
    h1 = scatter(tD,CD1,5,'filled','MarkerFaceColor',colors(i,:), ...
        'DisplayName',"Q"+filedataExp.Q(i)+": C_{D}");
    hold on
    h2 = plot(tD(cond), expProcData.(filedataExp.Key(i)).BT.CDimodel(cond), ...
        'LineWidth',1.0,'Color', 'k','DisplayName',"C_D_{fit} \pm \DeltaC_D_{fit}");
    xlabel('Dimensionless Time [-]');
    ylabel('C_{D}[-]');
    ylim([-0.001,1.001]);
    title("Breakthrough curves fitting - dimensionless", 'Interpreter', 'none')
    grid on;
    h = [h; h1];
end
legend([h;h2], 'Location','southeast');
saveas(gcf,pathExportAll + "BTfitting_dimless",'png')
savefig(gcf,pathExportAll + "BTfitting_dimless")

%% Fitting and experimental data all CF plot
% dimensionless 

colors = orderedcolors("glow");
figure
h=[];
for i = 1:length(filedataExp.Key)
    tDtotal = expProcData.(filedataExp.Key(i)).BT.tDtotal;
    CD1 = expProcData.(filedataExp.Key(i)).BT.CDi;
    CD1min = expProcData.(filedataExp.Key(i)).BT.CDiMin;
    CD1max = expProcData.(filedataExp.Key(i)).BT.CDiMax;
    cond = (expProcData.(filedataExp.Key(i)).BT.Cimodel>=10)&(expProcData.(filedataExp.Key(i)).BT.Cimodel<=90);
    % errorbar(tDtotal(cond), expProcData.(filedataExp.Key(i)).BT.CDimodel(cond), ...
    %    expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.RMSE*ones(size(tDtotal(cond))), ...
    %    'LineStyle', 'none', ...
    %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
    % hold on
    % errorbar(tDtotal, CD1, CD1-CD1min, CD1max - CD1, 'LineStyle', 'none', ...
    %     'Color', [1 0.78 0.88],'HandleVisibility','Off')
    h1 = scatter(tDtotal,CD1,5,'filled','MarkerFaceColor',colors(i,:), ...
        'DisplayName',"Q"+filedataExp.Q(i));
    hold on
    % h2 = plot(tDtotal(cond), expProcData.(filedataExp.Key(i)).BT.CDimodel(cond), ...
    %     'LineWidth',1.0,'Color', 'k','DisplayName',"C_D_{fit} \pm \DeltaC_D_{fit}");
    xlabel('Dimensionless Time [-]');
    ylabel('C_{D}[-]');
    xlim([0,2]);
    ylim([-0.001,1.001]);
    title("Breakthrough curves fitting - dimensionless total", 'Interpreter', 'none')
    grid on;
    h = [h; h1];
end
% legend([h;h2], 'Location','southeast');
legend(h, 'Location','southeast');
saveas(gcf,pathExportAll + "BTfitting_dimlessTotal",'png')
savefig(gcf,pathExportAll + "BTfitting_dimlessTotal")

%% Plot Kl_vs_vel

colors = orderedcolors("glow");

% % all params in SI
% Dp_SI = unique(fitting_results.L_SI);
% D0 = unique(fitting_results.D0_SI);
% Pe_D0_array = fitting_results.Pe_D0; % Pe in respect to D0
% u_array_cm2min = fitting_results.u_fit_cmmin;
% KL_array = fitting_results.KL_cm2min; % KL and D0 must have same units
% dKLneg_array = fitting_results.sd_KL_max_cm2min + fitting_results.SE_KL_cm2min;
% dKLpos_array = fitting_results.sd_KL_min_cm2min + fitting_results.SE_KL_cm2min;
% alpha_L = alphaPe1*100;
% dalpha_L = dalphaPe1*100;
% tortuosity = tortosityPe1;
% dtortuosity = dtortosityPe1;

% all params in SI
Dp_SI = unique(fitting_results.L_SI);
D0 = unique(fitting_results.D0_SI);
Pe_D0_array = fitting_results.Pe_D0; % Pe in respect to D0
u_array_cm2min = fitting_results.u_fit_dtfixed_cmmin;
KL_array = fitting_results.KL_dtfixed_cm2min; % KL and D0 must have same units
dKLneg_array = fitting_results.sd_KL_dtfixed_max_cm2min + fitting_results.SE_KL_dtfixed_cm2min;
dKLpos_array = fitting_results.sd_KL_dtfixed_min_cm2min + fitting_results.SE_KL_dtfixed_cm2min;
alpha_L = alphaPe1*100;
dalpha_L = dalphaPe1*100;
tortuosity = tortosityPe1;
dtortuosity = dtortosityPe1;

figure % dispersivity
x = 0:1:ceil(max(Pe_D0_array));
% plot((x*D0/Dp_SI)*(60*10^2),KL_D0_vs_Pe_fit.feval(x)*(60*10^4), ...
%     'DisplayName','K_L = D_0/\tau + \alpha_Lu_x','Color','k'); % Kl_vs_u fitting
plot((x*D0/Dp_SI)*(60*10^2),KL_D0_vs_Pe_fit.feval(x)*(60*10^4), ...
    'DisplayName','K_L \approx \alpha_Lu_x','Color','k'); % Kl_vs_u fitting
hold on
for i = 1:length(u_array_cm2min)
    errorbar(u_array_cm2min(i),KL_array(i),dKLneg_array(i),dKLpos_array(i), ...
        'Color','k','HandleVisibility','off')
    hold on
    scatter(u_array_cm2min(i),KL_array(i),'filled', ...
        'DisplayName',"Q = " + filedataExp.Q(i) +" ml/min", ...
        'Color',colors(i,:))
end
xlabel('Interstitial velocity (u_x) [cm/min]');
ylabel('Longitudinal Dispersion Coefficient (K_L) [cm^2/s]');
ylim([0,4.5])
grid on;
annotText1 = sprintf('\\alpha_{L} = %.2f \\pm %.2f cm', alpha_L, dalpha_L);
annotText2 = sprintf('\\tau = %.2f \\pm %.2f', tortuosity, dtortuosity);
annotation('textbox', [0.25, 0.18, 0.8, 0.06], 'String', annotText1, ...
    'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','FaceAlpha',0.1);
% annotation('textbox', [0.265, 0.13, 0.8, 0.06], 'String', annotText2, ...
%     'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','FaceAlpha',0.1);
legend('Location','southeast');
saveas(gcf,pathExportAll + "KLvsVel-alpha_all",'png')
savefig(gcf,pathExportAll + "KLvsVel-alpha_all")

%% Plot Kl/Dl vs Pe

% all params in SI
Pe_array = Pe_alpha_array; % Pe in respect to D0
dPe_array = fitting_results.dPe_alpha;
KL_vs_D0_array = fitting_results.KL_vs_D0;
dKL_vs_D0_array = fitting_results.dKL_vs_D0;
D0 = unique(fitting_results.D0_SI);
dD0 = unique(fitting_results.dD0_SI);
KL_array = fitting_results.KL_SI; % KL and D0 must have same units
dKL_array = fitting_results.sd_KL_dtfixed_avg_cm2min/(60*10^4);

figure
% plot(0:0.1:max(Pe_D0_array),KL_D0_vs_Pe_fit.feval(0:0.1:max(Pe_D0_array))/D0, ...
%     'DisplayName','K_L/D_0 = 1/\tau + \alpha_Lu_x/D_0','Color','k'); % Kl_vs_u fitting
plot(0:0.1:max(Pe_D0_array),KL_D0_vs_Pe_fit.feval(0:0.1:max(Pe_D0_array))/D0, ...
    'DisplayName','K_L/D_0 \approx \alpha_Lu_x/D_0','Color','k'); % Kl_vs_u fitting
hold on
for i = 1:length(Pe_D0_array)
    errorbar(Pe_D0_array(i),KL_vs_D0_array(i), ...
        dKL_vs_D0_array(i),dKL_vs_D0_array(i), dPe_array(i), dPe_array(i), ...
        'Color','k','HandleVisibility','off')
    hold on
    scatter(Pe_D0_array(i),KL_vs_D0_array(i),'filled', ...
        'DisplayName',"Q = " + filedataExp.Q(i) +" ml/min", ...
        'Color',colors(i,:))
    hold on
end
xlabel('Pe = u_x\alpha/D_0')
ylabel('K_L/D_0');
ylim([0,10])
set(gca, 'XScale','log','YScale','log')
grid on;
legend('Location','northwest');
saveas(gcf,pathExportAll + "KLD0vsPe_all",'png')
savefig(gcf,pathExportAll + "KLD0vsPe_all")



