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

inputFileConfigName = 'inputExpConfig.xlsx';

inputFileConfig = readtable(inputFileConfigName);

filenameExp = inputFileConfig.inputFileName{:};

pathImportAll = inputFileConfig.exportPath{:}; % Path for INPUT
pathExportAll = pathImportAll;
mkdir(pathImportAll); % Create directory for output

%% IMPORT variables

filedataExp = import_inputExp(filenameExp); % import input to a local variable

load(pathImportAll+"expProcData.mat")

%% Fitting dispersion to find KL and dt short equation ADE
% dt free

% No need to correct BT curve due to extra volume before core, the
% fit_dispersion_dt corrects for that extra t

method_results = struct();

methods = {'dt_free_wfit', 'dt_free_nwfit', ...
    'dt_fixed_wfit_wdt_lim','dt_fixed_wfit_nwdt_lim', ...
    'dt_fixed_nwfit_wdt_lim', 'dt_fixed_nwfit_nwdt_lim', ...
    'dt_fixed_wfit_wdt_full','dt_fixed_wfit_nwdt_full', ...
    'dt_fixed_nwfit_wdt_full', 'dt_fixed_nwfit_nwdt_full'};

for m = 1:length(methods)
    method_results.(methods{m}) = table();
end

for i = 1:length(filedataExp.Key)
    if filedataExp.Type(i) == "CF"

        % data
        t_vals = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
        C1_vals = expProcData.(filedataExp.Key(i)).BT.Ci/100;
        dC_vals = expProcData.(filedataExp.Key(i)).BT.dC/100;

        % experiment params (fixed for fitting)
        Ci = filedataExp.C1init(i)/100;
        Cj = filedataExp.C1j(i)/100;
        u = expProcData.(filedataExp.Key(i)).exp_params.u_SI;
        L = expProcData.(filedataExp.Key(i)).exp_params.L_SI;

        % dt shift guess = Vlines total / Q 
        dt_guess = (filedataExp.Vlinesbefore(i)+filedataExp.Vlinesafter(i))*60/filedataExp.Q(i); % time in seconds
        p_guess = [1,dt_guess];

        % dt_free_w dt free weigthed
        % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
        KL_out = fit_dispersion_dt_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,p_guess,dC_vals); % weigthed with errors

        % exp params for table
        row = buildRow_procResults(filedataExp, expProcData, KL_out, i);

        method_results.dt_free_wfit = [method_results.dt_free_wfit; row];

        expProcData.(filedataExp.Key(i)).BT.C_fit_dt_free = 100*KL_out.C_fit;

        % dt_free_nw dt free non weigthed
        % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
        KL_out = fit_dispersion_dt_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,p_guess,ones(size(C1_vals))); %non weighted (error is 1, hence w = 1./(dC.^2) = 1)

        % exp params for table
        row = buildRow_procResults(filedataExp, expProcData, KL_out, i);

        method_results.dt_free_nwfit = [method_results.dt_free_nwfit; row];

        expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_free = 100*KL_out.C_fit;

    end
end

%% Fitting dispersion to find KL short equation ADE
% dt fixed

for i = 1:length(filedataExp.Key)
    if filedataExp.Type(i) == "CF"

        % data
        t_vals = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
        C1_vals = expProcData.(filedataExp.Key(i)).BT.Ci/100;
        dC_vals = expProcData.(filedataExp.Key(i)).BT.dC/100;

        Cmin = 0.16;
        Cmax = 0.84;

        % experiment params (fixed for fitting)
        Ci = filedataExp.C1init(i)/100;
        Cj = filedataExp.C1j(i)/100;
        u = expProcData.(filedataExp.Key(i)).exp_params.u_SI;
        L = expProcData.(filedataExp.Key(i)).exp_params.L_SI;

        % run dt fixed fitting only if dt guess from weigthed or non weigthed dt free are valid

        % dtfixed from dt free weigthed
        valid_dtD_fixed_w = isfinite(method_results.dt_free_wfit.dtD) & ...
            isfinite(method_results.dt_free_wfit.d_dtD);

        if any(valid_dtD_fixed_w)
            % dtD guess fixed is a weigthed average of previous dtD
            dtD_guess = (method_results.dt_free_wfit.dtD(valid_dtD_fixed_w)')*(method_results.dt_free_wfit.d_dtD(valid_dtD_fixed_w)/sum(method_results.dt_free_wfit.d_dtD(valid_dtD_fixed_w))); % dtD fixed is a weigthed average
            d_dt_dtfixed_SI = (method_results.dt_free_wfit.d_dt_SI(valid_dtD_fixed_w)')*(method_results.dt_free_wfit.d_dtD(valid_dtD_fixed_w)/sum(method_results.dt_free_wfit.d_dtD(valid_dtD_fixed_w)));
            dt_fixed = dtD_guess*L/u; %  dt estimate according to velocity of each experiment
            p_guess = sqrt(method_results.dt_free_wfit.KL_SI);

            %% dt fixed weigthed fit wit dt weigthed limited C
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,dC_vals,Cmin,Cmax);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_wfit_wdt_lim = [method_results.dt_fixed_wfit_wdt_lim; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_wfit_wdt_lim = 100*KL_out.C_fit;

            %% dt fixed non weigthed fit wit dt weigthed limited C

            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,ones(size(C1_vals)),Cmin,Cmax);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_nwfit_wdt_lim = [method_results.dt_fixed_nwfit_wdt_lim; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_nwfit_wdt_lim = 100*KL_out.C_fit;

            %% dt fixed weigthed fit wit dt weigthed full
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,dC_vals,0,1);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_wfit_wdt_full = [method_results.dt_fixed_wfit_wdt_full; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_wfit_wdt_full = 100*KL_out.C_fit;

            %% dt fixed non weigthed fit wit dt weigthed full
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,ones(size(C1_vals)),0,1);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_nwfit_wdt_full = [method_results.dt_fixed_nwfit_wdt_full; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_nwfit_wdt_full = 100*KL_out.C_fit;
        end

        % Non weigthed for dtfixed
        valid_dtD_fixed_nw = isfinite(method_results.dt_free_nwfit.dtD) & ...
            isfinite(method_results.dt_free_nwfit.d_dtD);
        
        if any(valid_dtD_fixed_nw)
            % dtD guess nw fixed is a weigthed average of previous dtD non weigthed
            dtD_guess = (method_results.dt_free_nwfit.dtD(valid_dtD_fixed_nw)')*(method_results.dt_free_nwfit.d_dtD(valid_dtD_fixed_nw)/sum(method_results.dt_free_nwfit.d_dtD(valid_dtD_fixed_nw))); % dtD fixed is a weigthed average
            d_dt_dtfixed_SI = (method_results.dt_free_nwfit.d_dt_SI(valid_dtD_fixed_nw)')*(method_results.dt_free_nwfit.d_dtD/sum(method_results.dt_free_nwfit.d_dtD(valid_dtD_fixed_nw)));
            dt_fixed = dtD_guess*L/u; %  dt estimate according to velocity of each experiment
            p_guess = sqrt(method_results.dt_free_nwfit.KL_SI);

            %% dt fixed weigthed fit wit dt non weigthed limited C
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,dC_vals,Cmin,Cmax);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_wfit_nwdt_lim = [method_results.dt_fixed_wfit_nwdt_lim; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_wfit_nwdt_lim = 100*KL_out.C_fit;

            %% dt fixed non weigthed fit wit dt non weigthed limited C

            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,ones(size(C1_vals)),Cmin,Cmax);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_nwfit_nwdt_lim = [method_results.dt_fixed_nwfit_nwdt_lim; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_nwfit_nwdt_lim = 100*KL_out.C_fit;

            %% dt fixed weigthed fit wit dt weigthed full
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,dC_vals,0,1);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);

            method_results.dt_fixed_wfit_nwdt_full = [method_results.dt_fixed_wfit_nwdt_full; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_wfit_nwdt_full = 100*KL_out.C_fit;

            %% dt fixed non weigthed fit wit dt non weigthed full
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,ones(size(C1_vals)),0,1);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_nwfit_nwdt_full = [method_results.dt_fixed_nwfit_nwdt_full; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_nwfit_wdt_full = 100*KL_out.C_fit;
        end
    end
end

% %% Select best method (less R2 average) to estimate alpha and tortuosity
% 
% 
% 
% % Minimum requirements for fitting
% min_points_alphaFitting = 3; 
% 
% % Estimate alpha - tortuosity for same fluid, same T, and P (same D0), same length
% 
% % all params in SI
% Dp_SI = unique(fitting_results.L_SI); % Dp characteristic length in Peclet number
% D0 = unique(fitting_results.D0_SI);
% dD0 = unique(fitting_results.dD0_SI);
% 
% u_array = fitting_results.u_SI;
% Pe_D0_array = fitting_results.Pe_D0; % Pe in respect to D0
% dPe_D0_array = fitting_results.dPe_D0;
% 
% % KL_array = fitting_results.KL_SI; % KL and D0 must have same units
% % dKL_array = fitting_results.SE_KL_SI;
% KL_array = fitting_results.KL_dtfixed_SI; % KL and D0 must have same units
% dKL_array = fitting_results.SE_KL_total_dtfixed_SI;
% KL_nw_array = fitting_results.KL_dtfixed_nw_SI; % KL and D0 must have same units
% dKL_nw_array = fitting_results.SE_KL_total_dtfixed_nw_SI;
% % KL_mean_array = fitting_results.KL_mean_SI; % KL and D0 must have same units
% % dKL_mean_array = fitting_results.SE_KL_mean_SI;
% 
% for i = 1:length(Dp_SI)
%     for j = 1:length(D0)
% 
%         for l = 1:length(filedataExp.Key)
% 
%         end
%     end
% end
% 
% 
% 
% 
% 
% 
% 
% 
% 
% % Fitting
% % p_guess = 1;
% p_guess = [1,1]; % with tau
% 
% % KL weigthed
% % weighted
% fit_dispersion_params_all_out = fit_dispersion_params_all(KL_array,Pe_D0_array,D0,Dp_SI,p_guess,dKL_array);
% %nonweighted
% fit_dispersion_params_all_nw_out = fit_dispersion_params_all(KL_array,Pe_D0_array,D0,Dp_SI,p_guess,ones(size(KL_array)));
% 
% % Propagation of uncertainty from D0 error
% D0max = D0 + dD0;
% D0min = D0 - dD0;
% Pe_D0max_array = Pe_D0_array*(D0/D0max); % Pe in respect to D0max
% Pe_D0min_array = Pe_D0_array*(D0/D0min); % Pe in respect to D0min
% 
% % Fitting KL with different Pe ranges
% fit_dispersion_params_all_Pe_D0max_out = fit_dispersion_params_all(KL_array,Pe_D0max_array,D0max,Dp_SI,p_guess,dKL_array);
% fit_dispersion_params_all_Pe_D0min_out = fit_dispersion_params_all(KL_array,Pe_D0min_array,D0min,Dp_SI,p_guess,dKL_array);
% fit_dispersion_params_all_Pe_D0max_nw_out = fit_dispersion_params_all(KL_array,Pe_D0max_array,D0max,Dp_SI,p_guess,ones(size(KL_array)));
% fit_dispersion_params_all_Pe_D0min_nw_out = fit_dispersion_params_all(KL_array,Pe_D0min_array,D0min,Dp_SI,p_guess,ones(size(KL_array)));
% 
% % Params from fitting
% beta = fit_dispersion_params_all_out.beta;
% d_beta = fit_dispersion_params_all_out.d_beta;
% 
% % % taus KL weigthed
% % % tau weigthed
% % tau_w = fit_dispersion_params_all_out.tau;
% % d_tau_w = fit_dispersion_params_all_out.d_tau;
% % % tau non weigthed
% % tau_nw = fit_dispersion_params_all_nw_out.tau;
% % d_tau_nw = fit_dispersion_params_all_nw_out.d_tau;
% % % tau weigthed D0 effect
% % tau_D0max_w = fit_dispersion_params_all_Pe_D0max_out.tau;
% % tau_D0min_w = fit_dispersion_params_all_Pe_D0min_out.tau;
% % d_tau_D0uncert_w = abs(tau_D0max_w - tau_D0min_w)/2;
% % % tau non weigthed D0 effect
% % tau_D0max_nw = fit_dispersion_params_all_Pe_D0max_nw_out.tau;
% % tau_D0min_nw = fit_dispersion_params_all_Pe_D0min_nw_out.tau;
% % d_tau_D0uncert_nw = abs(tau_D0max_nw - tau_D0min_nw)/2;
% 
% % alphas KL weigthed
% % alpha weigthed
% alpha_w_SI = fit_dispersion_params_all_out.alpha_SI;
% d_alpha_w_SI = fit_dispersion_params_all_out.d_alpha_SI;
% alpha_w_cm = fit_dispersion_params_all_out.alpha_cm;
% d_alpha_w_cm = fit_dispersion_params_all_out.d_alpha_cm;
% % alpha non weigthed
% alpha_nw_SI = fit_dispersion_params_all_nw_out.alpha_SI;
% d_alpha_nw_SI = fit_dispersion_params_all_nw_out.d_alpha_SI;
% alpha_nw_cm = fit_dispersion_params_all_nw_out.alpha_cm;
% d_alpha_nw_cm = fit_dispersion_params_all_nw_out.d_alpha_cm;
% % alpha weigthed D0 effect
% alpha_D0max_w_SI = fit_dispersion_params_all_Pe_D0max_out.alpha_SI;
% alpha_D0min_w_SI = fit_dispersion_params_all_Pe_D0min_out.alpha_SI;
% d_alpha_D0uncert_w_SI = abs(alpha_D0max_w_SI - alpha_D0min_w_SI)/2;
% alpha_D0max_w_cm = fit_dispersion_params_all_Pe_D0max_out.alpha_cm;
% alpha_D0min_w_cm = fit_dispersion_params_all_Pe_D0min_out.alpha_cm;
% d_alpha_D0uncert_w_cm = abs(alpha_D0max_w_cm - alpha_D0min_w_cm)/2;
% % alpha non weigthed D0 effect
% alpha_D0max_nw_SI = fit_dispersion_params_all_Pe_D0max_nw_out.alpha_SI;
% alpha_D0min_nw_SI = fit_dispersion_params_all_Pe_D0min_nw_out.alpha_SI;
% d_alpha_D0uncert_nw_SI = abs(alpha_D0max_nw_SI - alpha_D0min_nw_SI)/2;
% alpha_D0max_nw_cm = fit_dispersion_params_all_Pe_D0max_nw_out.alpha_cm;
% alpha_D0min_nw_cm = fit_dispersion_params_all_Pe_D0min_nw_out.alpha_cm;
% d_alpha_D0uncert_nw_cm = abs(alpha_D0max_nw_cm - alpha_D0min_nw_cm)/2;
% 
% % KL non weigthed
% % weighted
% fit_dispersion_params_all_KLnw_out = fit_dispersion_params_all(KL_nw_array,Pe_D0_array,D0,Dp_SI,p_guess,dKL_nw_array);
% %nonweighted
% fit_dispersion_params_all_nw_KLnw_out = fit_dispersion_params_all(KL_nw_array,Pe_D0_array,D0,Dp_SI,p_guess,ones(size(KL_nw_array)));
% 
% % Propagation of uncertainty from D0 error
% D0max = D0 + dD0;
% D0min = D0 - dD0;
% Pe_D0max_array = Pe_D0_array*(D0/D0max); % Pe in respect to D0max
% Pe_D0min_array = Pe_D0_array*(D0/D0min); % Pe in respect to D0min
% 
% % Fitting KL with different Pe ranges
% fit_dispersion_params_all_Pe_D0max_KLnw_out = fit_dispersion_params_all(KL_nw_array,Pe_D0max_array,D0max,Dp_SI,p_guess,dKL_nw_array);
% fit_dispersion_params_all_Pe_D0min_KLnw_out = fit_dispersion_params_all(KL_nw_array,Pe_D0min_array,D0min,Dp_SI,p_guess,dKL_nw_array);
% fit_dispersion_params_all_Pe_D0max_nw_KLnw_out = fit_dispersion_params_all(KL_nw_array,Pe_D0max_array,D0max,Dp_SI,p_guess,ones(size(KL_nw_array)));
% fit_dispersion_params_all_Pe_D0min_nw_KLnw_out = fit_dispersion_params_all(KL_nw_array,Pe_D0min_array,D0min,Dp_SI,p_guess,ones(size(KL_nw_array)));
% 
% % Params from fitting
% beta_KLnw = fit_dispersion_params_all_KLnw_out.beta;
% d_beta_KLnw = fit_dispersion_params_all_KLnw_out.d_beta;
% 
% % % taus KL weigthed
% % % tau weigthed
% % tau_w_KLnw = fit_dispersion_params_all_KLnw_out.tau;
% % d_tau_w_KLnw = fit_dispersion_params_all_KLnw_out.d_tau;
% % % tau non weigthed
% % tau_nw_KLnw = fit_dispersion_params_all_nw_KLnw_out.tau;
% % d_tau_nw_KLnw = fit_dispersion_params_all_nw_KLnw_out.d_tau;
% % % tau weigthed D0 effect
% % tau_D0max_w_KLnw = fit_dispersion_params_all_Pe_D0max_KLnw_out.tau;
% % tau_D0min_w_KLnw = fit_dispersion_params_all_Pe_D0min_KLnw_out.tau;
% % d_tau_D0uncert_w_KLnw = abs(tau_D0max_w_KLnw - tau_D0min_w_KLnw)/2;
% % % tau non weigthed D0 effect
% % tau_D0max_nw_KLnw = fit_dispersion_params_all_Pe_D0max_KLnw_out.tau;
% % tau_D0min_nw_KLnw = fit_dispersion_params_all_Pe_D0min_KLnw_out.tau;
% % d_tau_D0uncert_nw_KLnw = abs(tau_D0max_nw_KLnw - tau_D0min_nw_KLnw)/2;
% 
% % alphas KL non weigthed
% % alpha weigthed
% alpha_w_KLnw_SI = fit_dispersion_params_all_KLnw_out.alpha_SI;
% d_alpha_w_KLnw_SI = fit_dispersion_params_all_KLnw_out.d_alpha_SI;
% alpha_w_KLnw_cm = fit_dispersion_params_all_KLnw_out.alpha_cm;
% d_alpha_w_KLnw_cm = fit_dispersion_params_all_KLnw_out.d_alpha_cm;
% % alpha non weigthed
% alpha_nw_KLnw_SI = fit_dispersion_params_all_nw_KLnw_out.alpha_SI;
% d_alpha_nw_KLnw_SI = fit_dispersion_params_all_nw_KLnw_out.d_alpha_SI;
% alpha_nw_KLnw_cm = fit_dispersion_params_all_nw_KLnw_out.alpha_cm;
% d_alpha_nw_KLnw_cm = fit_dispersion_params_all_nw_KLnw_out.d_alpha_cm;
% % alpha weigthed D0 effect
% alpha_D0max_w_KLnw_SI = fit_dispersion_params_all_Pe_D0max_KLnw_out.alpha_SI;
% alpha_D0min_w_KLnw_SI = fit_dispersion_params_all_Pe_D0min_KLnw_out.alpha_SI;
% d_alpha_D0uncert_w_KLnw_SI = abs(alpha_D0max_w_KLnw_SI - alpha_D0min_w_KLnw_SI)/2;
% alpha_D0max_w_KLnw_cm = fit_dispersion_params_all_Pe_D0max_KLnw_out.alpha_cm;
% alpha_D0min_w_KLnw_cm = fit_dispersion_params_all_Pe_D0min_KLnw_out.alpha_cm;
% d_alpha_D0uncert_w_KLnw_cm = abs(alpha_D0max_w_KLnw_cm - alpha_D0min_w_KLnw_cm)/2;
% % alpha non weigthed D0 effect
% alpha_D0max_nw_KLnw_SI = fit_dispersion_params_all_Pe_D0max_nw_KLnw_out.alpha_SI;
% alpha_D0min_nw_KLnw_SI = fit_dispersion_params_all_Pe_D0min_nw_KLnw_out.alpha_SI;
% d_alpha_D0uncert_nw_KLnw_SI = abs(alpha_D0max_nw_KLnw_SI - alpha_D0min_nw_KLnw_SI)/2;
% alpha_D0max_nw_KLnw_cm = fit_dispersion_params_all_Pe_D0max_nw_KLnw_out.alpha_cm;
% alpha_D0min_nw_KLnw_cm = fit_dispersion_params_all_Pe_D0min_nw_KLnw_out.alpha_cm;
% d_alpha_D0uncert_nw_KLnw_cm = abs(alpha_D0max_nw_KLnw_cm - alpha_D0min_nw_KLnw_cm)/2;
% 
% % % KL mean
% % % weighted
% % fit_dispersion_params_all_KLmean_out = fit_dispersion_params_all(KL_mean_array,Pe_D0_array,D0,Dp_SI,p_guess,dKL_mean_array);
% % %nonweighted
% % fit_dispersion_params_all_nw_KLmean_out = fit_dispersion_params_all(KL_mean_array,Pe_D0_array,D0,Dp_SI,p_guess,ones(size(KL_mean_array)));
% % 
% % % Propagation of uncertainty from D0 error
% % D0max = D0 + dD0;
% % D0min = D0 - dD0;
% % Pe_D0max_array = Pe_D0_array*(D0/D0max); % Pe in respect to D0max
% % Pe_D0min_array = Pe_D0_array*(D0/D0min); % Pe in respect to D0min
% % 
% % % Fitting KL with different Pe ranges
% % fit_dispersion_params_all_Pe_D0max_KLmean_out = fit_dispersion_params_all(KL_mean_array,Pe_D0max_array,D0max,Dp_SI,p_guess,dKL_mean_array);
% % fit_dispersion_params_all_Pe_D0min_KLmean_out = fit_dispersion_params_all(KL_mean_array,Pe_D0min_array,D0min,Dp_SI,p_guess,dKL_mean_array);
% % fit_dispersion_params_all_Pe_D0max_nw_KLmean_out = fit_dispersion_params_all(KL_mean_array,Pe_D0max_array,D0max,Dp_SI,p_guess,ones(size(KL_mean_array)));
% % fit_dispersion_params_all_Pe_D0min_nw_KLmean_out = fit_dispersion_params_all(KL_mean_array,Pe_D0min_array,D0min,Dp_SI,p_guess,ones(size(KL_mean_array)));
% % 
% % % Params from fitting
% % beta_KLmean = fit_dispersion_params_all_KLmean_out.beta;
% % d_beta_KLmean = fit_dispersion_params_all_KLmean_out.d_beta;
% % 
% % % % taus KL weigthed
% % % % tau weigthed
% % % tau_w_KLmean = fit_dispersion_params_all_KLmean_out.tau;
% % % d_tau_w_KLmean = fit_dispersion_params_all_KLmean_out.d_tau;
% % % % tau non weigthed
% % % tau_nw_KLmean = fit_dispersion_params_all_nw_KLmean_out.tau;
% % % d_tau_nw_KLmean = fit_dispersion_params_all_nw_KLmean_out.d_tau;
% % % % tau weigthed D0 effect
% % % tau_D0max_w_KLmean = fit_dispersion_params_all_Pe_D0max_KLmean_out.tau;
% % % tau_D0min_w_KLmean = fit_dispersion_params_all_Pe_D0min_KLmean_out.tau;
% % % d_tau_D0uncert_w_KLmean = abs(tau_D0max_w_KLmean - tau_D0min_w_KLmean)/2;
% % % % tau non weigthed D0 effect
% % % tau_D0max_nw_KLmean = fit_dispersion_params_all_Pe_D0max_KLmean_out.tau;
% % % tau_D0min_nw_KLmean = fit_dispersion_params_all_Pe_D0min_KLmean_out.tau;
% % % d_tau_D0uncert_nw_KLmean = abs(tau_D0max_nw_KLmean - tau_D0min_nw_KLmean)/2;
% % 
% % % alphas KL average
% % % alpha weigthed
% % alpha_w_KLmean_SI = fit_dispersion_params_all_KLmean_out.alpha_SI;
% % d_alpha_w_KLmean_SI = fit_dispersion_params_all_KLmean_out.d_alpha_SI;
% % alpha_w_KLmean_cm = fit_dispersion_params_all_KLmean_out.alpha_cm;
% % d_alpha_w_KLmean_cm = fit_dispersion_params_all_KLmean_out.d_alpha_cm;
% % % alpha non weigthed
% % alpha_nw_KLmean_SI = fit_dispersion_params_all_nw_KLmean_out.alpha_SI;
% % d_alpha_nw_KLmean_SI = fit_dispersion_params_all_nw_KLmean_out.d_alpha_SI;
% % alpha_nw_KLmean_cm = fit_dispersion_params_all_nw_KLmean_out.alpha_cm;
% % d_alpha_nw_KLmean_cm = fit_dispersion_params_all_nw_KLmean_out.d_alpha_cm;
% % % alpha weigthed D0 effect
% % alpha_D0max_w_KLmean_SI = fit_dispersion_params_all_Pe_D0max_KLmean_out.alpha_SI;
% % alpha_D0min_w_KLmean_SI = fit_dispersion_params_all_Pe_D0min_KLmean_out.alpha_SI;
% % d_alpha_D0uncert_w_KLmean_SI = abs(alpha_D0max_w_KLmean_SI - alpha_D0min_w_KLmean_SI)/2;
% % alpha_D0max_w_KLmean_cm = fit_dispersion_params_all_Pe_D0max_KLmean_out.alpha_cm;
% % alpha_D0min_w_KLmean_cm = fit_dispersion_params_all_Pe_D0min_KLmean_out.alpha_cm;
% % d_alpha_D0uncert_w_KLmean_cm = abs(alpha_D0max_w_KLmean_cm - alpha_D0min_w_KLmean_cm)/2;
% % % alpha non weigthed D0 effect
% % alpha_D0max_nw_KLmean_SI = fit_dispersion_params_all_Pe_D0max_nw_KLmean_out.alpha_SI;
% % alpha_D0min_nw_KLmean_SI = fit_dispersion_params_all_Pe_D0min_nw_KLmean_out.alpha_SI;
% % d_alpha_D0uncert_nw_KLmean_SI = abs(alpha_D0max_nw_KLmean_SI - alpha_D0min_nw_KLmean_SI)/2;
% % alpha_D0max_nw_KLmean_cm = fit_dispersion_params_all_Pe_D0max_nw_KLmean_out.alpha_cm;
% % alpha_D0min_nw_KLmean_cm = fit_dispersion_params_all_Pe_D0min_nw_KLmean_out.alpha_cm;
% % d_alpha_D0uncert_nw_KLmean_cm = abs(alpha_D0max_nw_KLmean_cm - alpha_D0min_nw_KLmean_cm)/2;
% % 
% % % % all taus
% % % % KL weigthed
% % % taus = [tau_w,tau_nw,tau_D0max_w,tau_D0min_w,tau_D0max_nw,tau_D0min_nw];
% % % d_taus = [d_tau_w,d_tau_nw,d_tau_D0uncert_w,d_tau_D0uncert_nw];
% % % % KL non weigthed
% % % taus_KLnw = [tau_w_KLnw,tau_nw_KLnw,tau_D0max_w_KLnw,tau_D0min_w_KLnw,tau_D0max_nw_KLnw,tau_D0min_nw_KLnw];
% % % d_taus_KLnw = [d_tau_w_KLnw,d_tau_nw_KLnw,d_tau_D0uncert_w_KLnw,d_tau_D0uncert_nw_KLnw];
% % % % KL mean
% % % taus_KLmean = [tau_w_KLmean,tau_nw_KLmean,tau_D0max_w_KLmean,tau_D0min_w_KLmean,tau_D0max_nw_KLmean,tau_D0min_nw_KLmean];
% % % d_taus_KLmean = [d_tau_w_KLmean,d_tau_nw_KLmean,d_tau_D0uncert_w_KLmean,d_tau_D0uncert_nw_KLmean];
% % % 
% % % % all taus and dtaus
% % % taus_all = [taus_KLnw,taus_KLmean];
% % % d_taus_all = [d_taus_KLnw,d_taus_KLmean];
% % % tau_mean = mean(taus_all);
% % % d_tau_sens = max(abs(taus_all - tau_mean));
% % 
% % % all alphas
% % % KL weigthed
% % alphas_SI = [alpha_w_SI,alpha_nw_SI,alpha_D0max_w_SI,alpha_D0min_w_SI,alpha_D0max_nw_SI,alpha_D0min_nw_SI];
% % alphas_cm = [alpha_w_cm,alpha_nw_cm,alpha_D0max_w_cm,alpha_D0min_w_cm,alpha_D0max_nw_cm,alpha_D0min_nw_cm];
% % d_alphas_SI = [d_alpha_w_SI,d_alpha_nw_SI,d_alpha_D0uncert_w_SI,d_alpha_D0uncert_nw_SI];
% % d_alphas_cm = [d_alpha_w_cm,d_alpha_nw_cm,d_alpha_D0uncert_w_cm,d_alpha_D0uncert_nw_cm];
% % % KL non weigthed
% % alphas_KLnw_SI = [alpha_w_KLnw_SI,alpha_nw_KLnw_SI,alpha_D0max_w_KLnw_SI,alpha_D0min_w_KLnw_SI,alpha_D0max_nw_KLnw_SI,alpha_D0min_nw_KLnw_SI];
% % alphas_KLnw_cm = [alpha_w_KLnw_cm,alpha_nw_KLnw_cm,alpha_D0max_w_KLnw_cm,alpha_D0min_w_KLnw_cm,alpha_D0max_nw_KLnw_cm,alpha_D0min_nw_KLnw_cm];
% % d_alphas_KLnw_SI = [d_alpha_w_KLnw_SI,d_alpha_nw_KLnw_SI,d_alpha_D0uncert_w_KLnw_SI,d_alpha_D0uncert_nw_KLnw_SI];
% % d_alphas_KLnw_cm = [d_alpha_w_KLnw_cm,d_alpha_nw_KLnw_cm,d_alpha_D0uncert_w_KLnw_cm,d_alpha_D0uncert_nw_KLnw_cm];
% % % KL mean
% % alphas_KLmean_SI = [alpha_w_KLmean_SI,alpha_nw_KLmean_SI,alpha_D0max_w_KLmean_SI,alpha_D0min_w_KLmean_SI,alpha_D0max_nw_KLmean_SI,alpha_D0min_nw_KLmean_SI];
% % alphas_KLmean_cm = [alpha_w_KLmean_cm,alpha_nw_KLmean_cm,alpha_D0max_w_KLmean_cm,alpha_D0min_w_KLmean_cm,alpha_D0max_nw_KLmean_cm,alpha_D0min_nw_KLmean_cm];
% % d_alphas_KLmean_SI = [d_alpha_w_KLmean_SI,d_alpha_nw_KLmean_SI,d_alpha_D0uncert_w_KLmean_SI,d_alpha_D0uncert_nw_KLmean_SI];
% % d_alphas_KLmean_cm = [d_alpha_w_KLmean_cm,d_alpha_nw_KLmean_cm,d_alpha_D0uncert_w_KLmean_cm,d_alpha_D0uncert_nw_KLmean_cm];
% % 
% % % all alphas and dalphas
% % alphas_all_SI = [alphas_SI,alphas_KLnw_SI,alphas_KLmean_SI];
% % alphas_all_cm = [alphas_cm,alphas_KLnw_cm,alphas_KLmean_cm];
% % d_alphas_all_SI = [d_alphas_SI,d_alphas_KLnw_SI,d_alphas_KLmean_SI];
% % d_alphas_all_cm = [d_alphas_SI,d_alphas_KLnw_SI,d_alphas_KLmean_SI];
% % 
% % alpha_mean_SI = mean(alphas_all_SI);
% % alpha_mean_cm = mean(alphas_all_cm);
% % d_alpha_sens_SI = max(abs(alphas_all_SI - alpha_mean_SI));
% % d_alpha_sens_cm = max(abs(alphas_all_cm - alpha_mean_cm));
% % 
% % C2 in model is alpha/Dp Dp is characterstic legth L
% KL_fun = fit_dispersion_params_all_out.Cfun; 
% % KL_SI = KL_fun(alpha_mean_SI/Dp_SI,Pe_D0_array);
% % % KL_SI = KL_fun([alpha_mean_SI/Dp_SI,tau_mean],Pe_D0_array);
% % KL_alphamax_fit = KL_fun((alpha_mean_SI+d_alpha_sens_SI)/Dp_SI,Pe_D0_array);
% % KL_alphamin_fit = KL_fun((alpha_mean_SI-d_alpha_sens_SI)/Dp_SI,Pe_D0_array);
% % % KL_alphamax_fit = KL_fun([(alpha_mean_SI+d_alpha_sens_SI)/Dp_SI,tau_mean+d_tau_sens],Pe_D0_array);
% % % KL_alphamin_fit = KL_fun([(alpha_mean_SI-d_alpha_sens_SI)/Dp_SI,tau_mean-d_tau_sens],Pe_D0_array);
% % dKL_alpha_sens = abs(KL_alphamax_fit - KL_alphamin_fit)/2;
% % 
% % % RMSE = fit_dispersion_params_all_out.RMSE;
% % % R2 = fit_dispersion_params_all_out.R2;
% 
% % Peclet with Dp = alpha instead of L
% Pe_alpha_array = u_array*alpha_nw_SI/D0;
% dPe_alpha_array = (((u_array/D0).^2)*((abs(alpha_nw_SI-alpha_w_SI))^2)+((-u_array*alpha_nw_SI/(D0^2)).^2)*(dD0^2)).^(1/2);
% % KL/D0, must be same units
% KL_vs_D0_array = KL_array/D0;
% dKL_vs_D0_array = (((1/D0).^2)*(dKL_nw_array.^2)+((-KL_array/(D0^2)).^2)*(dD0^2)).^(1/2); %dKL array instead of dKL total
% % since it is the result from fitting C vs t, not plotting the results from this fitting
% 
% % Add dispersion parameters in exp_params and fitting results
% fitting_results.Pe_alpha = Pe_alpha_array;
% fitting_results.dPe_alpha = dPe_alpha_array;
% fitting_results.KL_vs_D0 = KL_vs_D0_array;
% fitting_results.dKL_vs_D0 = dKL_vs_D0_array;
% for i = 1:length(filedataExp.Key)
%     expProcData.(filedataExp.Key(i)).exp_params.Pe_alpha = Pe_alpha_array(i);
%     expProcData.(filedataExp.Key(i)).exp_params.dPe_alpha = dPe_alpha_array(i);
%     expProcData.(filedataExp.Key(i)).exp_params.KL_vs_D0 = KL_vs_D0_array(i);
%     expProcData.(filedataExp.Key(i)).exp_params.dKL_vs_D0 = dKL_vs_D0_array(i);
% end
% 
% expProcFullData = expProcData;
% 
% % save updated expProcData
% save(pathExportAll + "expProcFullData.mat",'expProcFullData')
% 
% %% Table results
% 
% % creating table all in cm2 and min, and mol %
% % Pe alone is Pe in respect to KL and not D0
% fitting_results_simple = fitting_results(:, {'Key', 'C1init_pcmol', ...
%     'C1j_pcmol', 'Q_mlmin', 'u_cmmin', 'RMSE_dtfixed', 'R2_dtfixed', ...
%     'KL_dtfixed_cm2min','SE_KL_total_dtfixed_cm2min','Pe_dtfixed', 'SE_Pe_dtfixed', ...
%     'dt_dtfixed_min', 'SE_dt_dtfixed_min', 'dtD_dtfixed', 'SE_dtD_dtfixed', ...
%     'L_dtfixed_lines_cm','SE_L_dtfixed_lines_cm','V_dtfixed_lines_cc','SE_V_dtfixed_lines_cc',...
%     'Pe_D0', 'dPe_D0', 'Pe_alpha', 'dPe_alpha', 'T_mean', 'T_std', ...
%     'RMSE_dtfixed_nw', 'R2_dtfixed_nw', ...
%     'KL_dtfixed_nw_cm2min','SE_KL_total_dtfixed_nw_cm2min','Pe_dtfixed_nw', 'SE_Pe_dtfixed_nw', ...
%     'dt_dtfixed_nw_min', 'SE_dt_dtfixed_nw_min', 'dtD_dtfixed_nw', 'SE_dtD_dtfixed_nw', ...
%     'L_lines_nw_cm','SE_L_lines_nw_cm','V_lines_nw_cc','SE_V_lines_nw_cc'});
% 
% fitting_params_simple = table("Berea", unique(fitting_results.Fluid1), unique(fitting_results.Fluid2),...
%     unique(fitting_results.T_C),unique(fitting_results.P_psig), (unique(fitting_results.P_psig)+14.7)*0.00689476,...
%     unique(fitting_results.D12_cm2min), unique(fitting_results.dD12_cm2min), ...
%     unique(fitting_results.D_in)*2.54, unique(fitting_results.L_cm), ...
%     unique(fitting_results.phi),unique(fitting_results.K_mD), ...
%     unique(fitting_results.dtD_dtfixed), max(fitting_results.L_dtfixed_lines_cm),max(fitting_results.SE_L_dtfixed_lines_cm),...
%     unique(fitting_results.Vlinesbefore_cc), max(fitting_results.V_dtfixed_lines_cc),max(fitting_results.SE_V_dtfixed_lines_cc),...
%     alpha_w_cm, d_alpha_w_cm, alpha_nw_cm, d_alpha_nw_cm, ...
%     alpha_w_KLnw_cm, d_alpha_w_KLnw_cm, alpha_nw_KLnw_cm, d_alpha_nw_KLnw_cm, beta, ...
%     'VariableNames',{'Sample', 'Fluid1','Fluid2', ...
%     'T_C','P_psig','P_MPa', ...
%     'D0_cm2min', 'dD0_cm2min', ...
%     'D_cm', 'L_cm', ...
%     'phi',  'K_mD', ...
%     'dtD_fixed','L_lines_before_dtfixed_cm','sd_L_lines_before_dtfixed_cm',...
%     'Vlinesbefore_cc','V_lines_before_dtfixed_cc','sd_V_lines_before_dtfixed_cc',...
%     'alpha_w_cm', 'sd_alpha_w_cm','alpha_nw_cm', 'sd_alpha_nw_cm', ...
%     'alpha_w_KLnw_cm', 'd_alpha_w_KLnw_cm', 'alpha_nw_KLnw_cm', 'd_alpha_nw_KLnw_cm','beta'});
% 
% fittingDispersionResults.results = fitting_results_simple;
% fittingDispersionResults.params = fitting_params_simple;
% 
% %% Save tables and matrices
% 
% % name to save matrices and spreadsheets
% table_name = pathExportAll + "fittingResults";  % Name used for saving TrimData comes from input pathExportAll
% table_name1 = pathExportAll + "fittingResultsSimple";  % Name used for saving TrimData comes from input pathExportAll
% table_name2 = pathExportAll + "fittingResultsParams";  % Name used for saving TrimData comes from input pathExportAll
% 
% % delete previous saved files
% delete(table_name + '.mat');
% delete(table_name + '.xlsx');
% delete(table_name1 + '.mat');
% delete(table_name1 + '.xlsx');
% delete(table_name2 + '.mat');
% delete(table_name2 + '.xlsx');
% 
% % save fitting_results
% writetable(fitting_results,table_name + ".xlsx");
% save(table_name + ".mat",'fitting_results')
% 
% % save updated expProcData
% save(pathExportAll + "expProcFullData.mat",'expProcFullData')
% 
% % save fitting table
% writetable(fitting_results_simple,table_name1 + ".xlsx");
% writetable(fitting_params_simple,table_name2 + ".xlsx");
% save(table_name1 + ".mat",'fitting_results_simple')
% save(table_name2 + ".mat",'fitting_params_simple')
% 
% %% Fitting and experimental data all CF plot
% % dt not shifted
% 
% for i = 1:length(filedataExp.Key)
%         figure
%         scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.Ci,10,'filled','MarkerFaceColor','red','DisplayName','Experimental Data')
%         hold on
%         % KL weigthed 
%         % plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.C_fit_dt_free,'LineWidth',1.5,'Color', [0.5 0.5 0.5],'DisplayName',"BT model fitting - dt free - KL weigthed")
%         plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed,'LineWidth',1.5,'Color', 'k', 'DisplayName',"BT model fitting - KL weighted fitting")
%         % KL non weigthed
%         % plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_free,'LineStyle','--','LineWidth',1.5,'Color', [0.5 0.5 0.5],'DisplayName',"BT model fitting - dt free - KL non weigthed")
%         plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_fixed,'LineStyle','--','LineWidth',1.5,'Color', 'k', 'DisplayName',"BT model fitting - KL non weighted fitting")
%         % KL mean
%         % plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.C_mean_fit_dt_fixed,'LineWidth',1.5,'Color', 'blue', 'DisplayName',"BT model fitting - dt fixed - KL mean")
%         xlabel('Time elapsed [hh:mm:ss]');
%         xtickformat('hh:mm:ss')
%         ylabel('Molar concentration C_1 [mol %]');
%         ylim([-0.1,100.1]);
%         title(filedataExp.Key(i) + " fitting", 'Interpreter', 'none')
%         grid on;
%         legend('Location','southeast');
%         saveas(gcf,pathExportAll + filedataExp.Key(i) + "_fitting",'png')
%         savefig(gcf,pathExportAll + filedataExp.Key(i) + "_fitting")
% end
% 
% %% Fitting and experimental data all CF plot dimensionless
% 
% for i = 1:length(filedataExp.Key)
%         figure
%         scatter(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled','MarkerFaceColor','red','DisplayName','Experimental Data')
%         hold on
%         % KL weigthed 
%         plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.C_fit_dt_free/100,'LineWidth',1.5,'Color', [0.5 0.5 0.5],'DisplayName',"BT model fitting - dt free - KL weigthed")
%         plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed/100,'LineWidth',1.5,'Color', 'k', 'DisplayName',"BT model fitting - dt fixed - KL weigthed")
%         % KL non weigthed
%         plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_free/100,'LineStyle','--','LineWidth',1.5,'Color', [0.5 0.5 0.5],'DisplayName',"BT model fitting - dt free - KL non weigthed")
%         plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_fixed/100,'LineStyle','--','LineWidth',1.5,'Color', 'k', 'DisplayName',"BT model fitting - dt fixed - KL non weigthed")
%         % % KL mean
%         % plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.C_mean_fit_dt_fixed/100,'LineWidth',1.5,'Color', 'blue', 'DisplayName',"BT model fitting - dt fixed - KL mean")
%         xlabel('Dimensionless Time [-]');
%         % xlim([0,2]);
%         ylabel('C_{D}[-]');
%         ylim([-0.001,1.001]);
%         title(filedataExp.Key(i) + " dimensionless fitting", 'Interpreter', 'none')
%         grid on;
%         legend('Location','southeast');
%         saveas(gcf,pathExportAll + filedataExp.Key(i) + "_dimless_fitting",'png')
%         savefig(gcf,pathExportAll + filedataExp.Key(i) + "_dimless_fitting")
% end
% 
% % Fitting and experimental data all CF plot dimensionless total
% 
% for i = 1:length(filedataExp.Key)
%         figure
%         scatter(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled','MarkerFaceColor','red','DisplayName','Experimental Data')
%         hold on
%         % KL weigthed 
%         plot(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).BT.C_fit_dt_free/100,'LineWidth',1.5,'Color', [0.5 0.5 0.5],'DisplayName',"BT model fitting - dt free - KL weigthed")
%         plot(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed/100,'LineWidth',1.5,'Color', 'k', 'DisplayName',"BT model fitting - dt fixed - KL weigthed")
%         % KL non weigthed
%         plot(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_free/100,'LineStyle','--','LineWidth',1.5,'Color', [0.5 0.5 0.5],'DisplayName',"BT model fitting - dt free - KL non weigthed")
%         plot(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_fixed/100,'LineStyle','--','LineWidth',1.5,'Color', 'k', 'DisplayName',"BT model fitting - dt fixed - KL non weigthed")
%         % % KL mean
%         % plot(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).BT.C_mean_fit_dt_fixed/100,'LineWidth',1.5,'Color', 'blue', 'DisplayName',"BT model fitting - dt fixed - KL mean")
%         xlabel('Dimensionless Time [-]');
%         % xlim([0,2]);
%         ylabel('C_{D}[-]');
%         ylim([-0.001,1.001]);
%         title(filedataExp.Key(i) + " dimensionless fitting", 'Interpreter', 'none')
%         grid on;
%         legend(["Experimental data", "BT model fitting"],'Location','southeast');
%         saveas(gcf,pathExportAll + filedataExp.Key(i) + "_dimlessTotal_fitting",'png')
%         savefig(gcf,pathExportAll + filedataExp.Key(i) + "_dimlessTotal_fitting")
% end
% 
% %% Fitting and experimental data all CF plot
% % dt shifted
% 
% colors = orderedcolors("glow");
% figure
% for i = 1:length(filedataExp.Key)
%         scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed, ...
%             expProcData.(filedataExp.Key(i)).BT.Ci,10,'filled', ...
%             'MarkerFaceColor',colors(i,:),'DisplayName',"Q"+filedataExp.Q(i));
%         hold on
%         scatter(expProcData.(filedataExp.Key(i)).BT_corr.TimeElapsedNew, ...
%             expProcData.(filedataExp.Key(i)).BT_corr.Ci,10,'filled', ...
%             'MarkerFaceColor',colors(length(filedataExp.Key)+i,:),'DisplayName',"Q"+filedataExp.Q(i)+"-t_{shifted}")
%         %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
%         %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', [0.5 0.5 0.5])
%         xlabel('Time elapsed [hh:mm:ss]');
%         xtickformat('hh:mm:ss')
%         ylabel('Molar concentration C_1 [mol %]');
%         ylim([-0.1,100.1]);
%         title(filedataExp.Key(i) + " fitting", 'Interpreter', 'none')
%         grid on;
%         legend('Location','southeast');
% end
% saveas(gcf,pathExportAll + "dtshift_fitting",'png')
% savefig(gcf,pathExportAll + "dtshift_fitting")
% %% Fitting and experimental data all CF plot dimensionless
% % tD shifted
% colors = orderedcolors("glow");
% figure
% for i = 1:length(filedataExp.Key)
%         scatter(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled','MarkerFaceColor',colors(i,:), 'DisplayName',"Q"+filedataExp.Q(i))
%         hold on
%         scatter(expProcData.(filedataExp.Key(i)).BT_corr.tD_corr,expProcData.(filedataExp.Key(i)).BT_corr.CDi,10,'filled','MarkerFaceColor',colors(length(filedataExp.Key)+i,:), 'DisplayName',"Q"+filedataExp.Q(i)+"-t_{shifted}")
%         %plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
%         %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', [0.5 0.5 0.5])
%         xlabel('Dimensionless Time [-]');
%         % xlim([0,2]);
%         ylabel('C_{D}[-]');
%         ylim([-0.001,1.001]);
%         title(filedataExp.Key(i) + " dimensionless fitting", 'Interpreter', 'none')
%         grid on;
%         legend('Location','southeast');
% end
% saveas(gcf,pathExportAll + "dimless_tDshift_fitting",'png')
% savefig(gcf,pathExportAll + "dimless_tDshift_fitting")
% 
% % Fitting and experimental data all CF plot dimensionless total
% % tD shifted
% colors = orderedcolors("glow");
% figure
% for i = 1:length(filedataExp.Key)
%         scatter(expProcData.(filedataExp.Key(i)).BT.tDtotal,expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled','MarkerFaceColor',colors(i,:), 'DisplayName',"Q"+filedataExp.Q(i))
%         hold on
%         scatter(expProcData.(filedataExp.Key(i)).BT_corr.tDtotal_corr,expProcData.(filedataExp.Key(i)).BT_corr.CDi,10,'filled','MarkerFaceColor',colors(length(filedataExp.Key)+i,:), 'DisplayName',"Q"+filedataExp.Q(i)+"-t_{shifted}")
%         %plot(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', 'k')
%         %plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,100*expProcData.(filedataExp.Key(i)).exp_params.C_fit.feval(expProcData.(filedataExp.Key(i)).BT.SecondsElapsed),'LineWidth',1.5,'Color', [0.5 0.5 0.5])
%         xlabel('Dimensionless Time [-]');
%         % xlim([0,2]);
%         ylabel('C_{D}[-]');
%         ylim([-0.001,1.001]);
%         title(filedataExp.Key(i) + " dimensionless fitting", 'Interpreter', 'none')
%         grid on;
%         legend('Location','southeast');
% end
% saveas(gcf,pathExportAll + "dimless_tDshiftTotal_fitting",'png')
% savefig(gcf,pathExportAll + "dimless_tDshiftTotal_fitting")
% 
% %% Fitting and experimental data all CF plot
% 
% colors = orderedcolors("glow");
% colorsdark = orderedcolors("earth"); 
% figure
% h=[];
% 
% % empty objects
% h1 = gobjects(length(filedataExp.Key),1);
% h2 = gobjects(length(filedataExp.Key),1);
% h_titles = gobjects(length(filedataExp.Key),1);
% 
% for i = 1:length(filedataExp.Key)
%     t = expProcData.(filedataExp.Key(i)).BT.TimeElapsed;
%     t_sec = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
%     C1 = expProcData.(filedataExp.Key(i)).BT.Ci;
%     C1min = expProcData.(filedataExp.Key(i)).BT.CiMin;
%     C1max = expProcData.(filedataExp.Key(i)).BT.CiMax;
%     % plot vals with function dt fixed weighted
%     cond = (expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed>=16)&(expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed<=84);
%     cond_nw = (expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_fixed>=16)&(expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_fixed<=84);
%     t_sec_cond = seconds(t(cond));
%     t_sec_trim = t_sec_cond(1):0.05:t_sec_cond(end);
%     t_trim = seconds(t_sec_trim);
%     t_trim.Format = 'hh:mm:ss';
%     dt_fixed = expProcData.(filedataExp.Key(i)).exp_params.dt_dtfixed_SI;
%     p = sqrt(expProcData.(filedataExp.Key(i)).exp_params.KL_dtfixed_SI);
%     L = expProcData.(filedataExp.Key(i)).exp_params.L_SI;
%     u = expProcData.(filedataExp.Key(i)).exp_params.u_SI;
%     C_plot_function = expProcData.(filedataExp.Key(i)).exp_params.C_fun_dtfixed{1};
%     C_plot = 100*C_plot_function(p,t_sec_trim);   
%     % errorbar(t(cond), expProcData.(filedataExp.Key(i)).BT.C_mean_fit_dt_fixed(cond), ...
%     %    expProcData.(filedataExp.Key(i)).exp_params.RMSE_mean*100*ones(size(t(cond))), ...
%     %    'LineStyle', 'none', ...
%     %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
%     % hold on
%     errorbar(t, C1, C1-C1min, C1max - C1, 'LineStyle', 'none', ...
%         'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
%     hold on
%     h1(i) = scatter(t,C1,5,'filled','MarkerFaceColor',colors(i,:), ...
%         'DisplayName',"C_{MFM} \pm \DeltaC_{MFM}");
%     % h2(i) = plot(t(cond), expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed(cond), ...
%     %     'LineWidth',3,'Color', colorsdark(i,:),'DisplayName',"C_{fit}");
%     h2(i) = plot(t_trim, C_plot, ...
%         'LineWidth',2,'Color', colorsdark(i,:),'DisplayName',"C_{fit}"); %gives same results, but evaluating the function
%     % h3 = plot(t(cond_nw), expProcData.(filedataExp.Key(i)).BT.C_nw_fit_dt_fixed(cond_nw), ...
%     %     'LineWidth',0.8,'LineStyle','--', 'Color', 'k','DisplayName',"C_{non weigthed fitting}");    
%     h_titles(i) = plot(NaN,NaN,'w', 'LineStyle','none', 'DisplayName', "\bf Q = " + filedataExp.Q(i) + " ml/min");
%     xlabel('Time elapsed [hh:mm:ss]','FontSize',14);
%     xtickformat('hh:mm:ss')
%     ylabel('C_{H_2} [mol %]','FontSize',14);
%     ylim([-0.1,100.1]);
%     ax = gca; % Get current axes
%     ax.FontSize = 12;
%     % title("Breakthrough curves fitting", 'Interpreter', 'none')
%     grid on;
%     % h = [h; h1];
%     h = [h;h_titles(i);h1(i);h2(i)];
% end
% lgd = legend(h, 'NumColumns', 1, ...
%     'Location', 'southeast', 'FontSize', 10);
% lgd.ItemTokenSize = [15 8];   % tighter symbols
% 
% drawnow  % REQUIRED for correct positions
% 
% lgd_pos = lgd.Position;  % [x y width height]
% nQ = length(filedataExp.Key);
% nRows = 3 * nQ;
% rowH = lgd_pos(4) / nRows;   % approximate row height
% 
% 
% for i = 1:nQ
%     % Row indices (from top of legend)
%     row_Q    = (i-1)*3 + 1;
%     row_Data = row_Q + 1;
% 
%     % Y positions (legend is bottom-based)
%     y1 = lgd_pos(2) + lgd_pos(4) - (row_Q-0.12)*rowH;
% 
%     % X positions (small indentation inside legend box)
%     x1 = lgd_pos(1);
%     x2 = lgd_pos(1) + lgd_pos(3);
% 
%     % Draw line
%     annotation('line', [x1 x2], [y1 y1], ...
%         'Color','k', 'LineWidth',0.8);
% end
% 
% for i = 1:nQ-1
% 
%     % Y positions (legend is bottom-based)
%     y1 = lgd_pos(2) + lgd_pos(4) - 3*i*rowH;
% 
%     % X positions (small indentation inside legend box)
%     x1 = lgd_pos(1);
%     x2 = lgd_pos(1) + lgd_pos(3);
% 
%     % Draw line
%     annotation('line', [x1 x2], [y1 y1], ...
%         'Color','k', 'LineWidth',0.8);
% end
% 
% % lgd1 = legend([h;h2], 'Location','southeast','FontSize',12);
% % title (lgd1, "C_{MFM} \pm \DeltaC_{MFM}",'FontSize',12)
% % lgd2 = legend(h2, 'Location','southeast','FontSize',12);
% saveas(gcf,pathExportAll + "BTfitting",'png')
% savefig(gcf,pathExportAll + "BTfitting")
% 
% %% Fitting and experimental data all CF plot
% % dimensionless 
% 
% colors = orderedcolors("glow");
% figure
% h=[];
% for i = 1:length(filedataExp.Key)
%     tD = expProcData.(filedataExp.Key(i)).BT.tD;
%     CD1 = expProcData.(filedataExp.Key(i)).BT.CDi;
%     CD1min = expProcData.(filedataExp.Key(i)).BT.CDiMin;
%     CD1max = expProcData.(filedataExp.Key(i)).BT.CDiMax;
%     cond = (expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed>=10)&(expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed<=90);
%     % errorbar(tD(cond), expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed(cond)/100, ...
%     %    expProcData.(filedataExp.Key(i)).exp_params.RMSE_mean*ones(size(tD(cond))), ...
%     %    'LineStyle', 'none', ...
%     %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
%     % hold on
%     % errorbar(tD, CD1, CD1-CD1min, CD1max - CD1, 'LineStyle', 'none', ...
%     %     'Color', [1 0.78 0.88],'HandleVisibility','Off')
%     h1 = scatter(tD,CD1,5,'filled','MarkerFaceColor',colors(i,:), ...
%         'DisplayName',"Q"+filedataExp.Q(i)+": C_{D}");
%     hold on
%     h2 = plot(tD(cond), expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed(cond)/100, ...
%         'LineWidth',1.0,'Color', 'k','DisplayName',"C_D_{fit} \pm \DeltaC_D_{fit}");
%     xlabel('Dimensionless Time [-]');
%     ylabel('C_{D}[-]');
%     ylim([-0.001,1.001]);
%     title("Breakthrough curves fitting - dimensionless", 'Interpreter', 'none')
%     grid on;
%     h = [h; h1];
% end
% legend([h;h2], 'Location','southeast');
% saveas(gcf,pathExportAll + "BTfitting_dimless",'png')
% savefig(gcf,pathExportAll + "BTfitting_dimless")
% 
% %% Fitting and experimental data all CF plot
% % dimensionless 
% 
% colors = orderedcolors("glow");
% figure
% h=[];
% for i = 1:length(filedataExp.Key)
%     tDtotal = expProcData.(filedataExp.Key(i)).BT.tDtotal;
%     CD1 = expProcData.(filedataExp.Key(i)).BT.CDi;
%     CD1min = expProcData.(filedataExp.Key(i)).BT.CDiMin;
%     CD1max = expProcData.(filedataExp.Key(i)).BT.CDiMax;
%     cond = (expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed>=10)&(expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed<=90);
%     % errorbar(tDtotal(cond), expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed(cond)/100, ...
%     %    expProcData.(filedataExp.Key(i)).exp_params.RMSE_mean*ones(size(tDtotal(cond))), ...
%     %    'LineStyle', 'none', ...
%     %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
%     % hold on
%     % errorbar(tDtotal, CD1, CD1-CD1min, CD1max - CD1, 'LineStyle', 'none', ...
%     %     'Color', [1 0.78 0.88],'HandleVisibility','Off')
%     h1 = scatter(tDtotal,CD1,5,'filled','MarkerFaceColor',colors(i,:), ...
%         'DisplayName',"Q"+filedataExp.Q(i));
%     hold on
%     % h2 = plot(tDtotal(cond), expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed(cond)/100, ...
%     %     'LineWidth',1.0,'Color', 'k','DisplayName',"C_D_{fit} \pm \DeltaC_D_{fit}");
%     xlabel('Dimensionless Time [-]');
%     ylabel('C_{D}[-]');
%     xlim([0,2]);
%     ylim([-0.001,1.001]);
%     title("Breakthrough curves fitting - dimensionless total", 'Interpreter', 'none')
%     grid on;
%     h = [h; h1];
% end
% % legend([h;h2], 'Location','southeast');
% legend(h, 'Location','southeast');
% saveas(gcf,pathExportAll + "BTfitting_dimlessTotal",'png')
% savefig(gcf,pathExportAll + "BTfitting_dimlessTotal")
% 
% %% Plot Kl_vs_vel
% 
% colors = orderedcolors("glow");
% 
% % all params in SI
% Dp_SI = unique(fitting_results.L_SI);
% D0 = unique(fitting_results.D0_SI);
% Pe_D0_array = fitting_results.Pe_D0; % Pe in respect to D0
% u_array_cmmin = fitting_results.u_cmmin;
% 
% % weigthed
% KL_array = fitting_results.KL_dtfixed_cm2min; % KL and D0 must have same units
% dKLneg_array = fitting_results.SE_KL_dtfixed_cm2min;
% dKLpos_array = fitting_results.SE_KL_dtfixed_cm2min;
% alpha_SI = alpha_nw_SI;
% dalpha_SI = d_alpha_nw_SI;
% alpha_L = alpha_nw_cm;
% dalpha_L = d_alpha_nw_cm;
% 
% % non weigthed
% KL_array_nw = fitting_results.KL_dtfixed_nw_cm2min; % KL and D0 must have same units
% dKLneg_array_nw = fitting_results.SE_KL_dtfixed_nw_cm2min;
% dKLpos_array_nw = fitting_results.SE_KL_dtfixed_nw_cm2min;
% alpha_SI_nw = alpha_nw_KLnw_SI;
% dalpha_SI_nw = d_alpha_nw_KLnw_SI;
% alpha_L_nw = alpha_nw_KLnw_cm;
% dalpha_L_nw = d_alpha_nw_KLnw_cm;
% 
% x = 0:1:ceil(max(Pe_D0_array));
% KL_plot = KL_fun(alpha_SI/Dp_SI,x);
% KL_plot_nw = KL_fun(alpha_SI_nw/Dp_SI,x);
% 
% figure % dispersivity
% % KL fit weighted
% plot((x*D0/Dp_SI)*(60*10^2),KL_plot*(60*10^4), ...
%     'DisplayName','K_L \approx \alpha_L fit u_x','Color','k'); % Kl_vs_u fitting
% hold on
% for i = 1:length(u_array_cmmin)
%     errorbar(u_array_cmmin(i),KL_array(i),dKLneg_array(i),dKLpos_array(i), ...
%         'Color','k','HandleVisibility','off')
%     hold on
%     scatter(u_array_cmmin(i),KL_array(i),'filled', ...
%         'DisplayName',"K_L for Q = " + filedataExp.Q(i) +" ml/min", ...
%         'Color',colors(i,:))
% end
% % KL fit non weighted
% plot((x*D0/Dp_SI)*(60*10^2),KL_plot_nw*(60*10^4), ...
%     'DisplayName','K_L nw \approx \alpha_L nw u_x','Color',[0.5 0.5 0.5]); % Kl_vs_u fitting
% hold on
% for i = 1:length(u_array_cmmin)
%     errorbar(u_array_cmmin(i),KL_array_nw(i),dKLneg_array(i),dKLpos_array(i), ...
%         'Color','k','HandleVisibility','off')
%     hold on
%     scatter(u_array_cmmin(i),KL_array_nw(i),'filled', ...
%         'Marker','^', 'DisplayName',"K_L nw for Q = " + filedataExp.Q(i) +" ml/min",...
%         'Color',colors(i,:))
% end
% xlabel('Interstitial velocity (u_x) [cm/min]');
% ylabel('Longitudinal Dispersion Coefficient (K_L) [cm^2/s]');
% ylim([0,4.5])
% grid on;
% annotText1 = sprintf('\\alpha_{L} = %.2f \\pm %.2f cm', alpha_L, dalpha_L);
% % annotText2 = sprintf('\\tau = %.2f \\pm %.2f', tau, dtau);
% annotation('textbox', [0.285, 0.18, 0.8, 0.06], 'String', annotText1, ...
%     'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','FaceAlpha',0.1);
% annotText3 = sprintf('\\alpha_{L} nw = %.2f \\pm %.2f cm', alpha_L_nw, dalpha_L_nw);
% annotation('textbox', [0.25, 0.14, 0.8, 0.06], 'String', annotText3, ...
%     'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','FaceAlpha',0.1);
% 
% % annotation('textbox', [0.265, 0.13, 0.8, 0.06], 'String', annotText2, ...
% %     'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','FaceAlpha',0.1);
% legend('Location','northwest');
% saveas(gcf,pathExportAll + "KLvsVel-alpha_all",'png')
% savefig(gcf,pathExportAll + "KLvsVel-alpha_all")
% 
% %% Plot Kl/Dl vs Pe
% 
% % all params in SI
% Pe_array = Pe_alpha_array; % Pe in respect to D0
% dPe_array = fitting_results.dPe_alpha;
% KL_vs_D0_array = fitting_results.KL_vs_D0;
% dKL_vs_D0_array = fitting_results.dKL_vs_D0;
% D0 = unique(fitting_results.D0_SI);
% dD0 = unique(fitting_results.dD0_SI);
% KL_array = fitting_results.KL_dtfixed_SI; % KL and D0 must have same units
% dKL_array = fitting_results.SE_KL_dtfixed_SI;
% 
% x = 0:1:ceil(max(Pe_array));
% KL_plot = KL_fun(alpha_SI/Dp_SI,x);
% % KL_plot = KL_fun([alpha_SI/Dp_SI,tau],x);
% 
% figure % dispersivity
% plot(x,KL_plot/D0, ...
%     'DisplayName','K_L/D_0 \approx \alpha_Lu_x/D_0','Color','k'); % Kl_vs_u fitting
% hold on
% for i = 1:length(Pe_array)
%     errorbar(Pe_array(i),KL_vs_D0_array(i), ...
%         dKL_vs_D0_array(i),dKL_vs_D0_array(i), dPe_array(i), dPe_array(i), ...
%         'Color','k','HandleVisibility','off')
%     hold on
%     scatter(Pe_array(i),KL_vs_D0_array(i),'filled', ...
%         'DisplayName',"Q = " + filedataExp.Q(i) +" ml/min", ...
%         'Color',colors(i,:))
%     hold on
% end
% xlabel('Pe = u_x\alpha/D_0')
% ylabel('K_L/D_0');
% ylim([0,10])
% set(gca, 'XScale','log','YScale','log')
% grid on;
% legend('Location','northwest');
% saveas(gcf,pathExportAll + "KLD0vsPe_all",'png')
% savefig(gcf,pathExportAll + "KLD0vsPe_all")
% 
% 
% 
