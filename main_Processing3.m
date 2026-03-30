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

        % the sum of V lines before and after should be the same as Vtotal - Vcore      
        t_vals = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
        C1_vals = expProcData.(filedataExp.Key(i)).BT.Ci/100;
        dCi_vals = expProcData.(filedataExp.Key(i)).BT.dC/100;
        
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

        dt_guess = (filedataExp.Vlinesbefore(i)+filedataExp.Vlinesafter(i))*60/filedataExp.Q(i); % time in seconds
        p_guess = [1,dt_guess];

        KL_all_out = fit_dispersion_dt_lines_error(C1_vals,dCi_vals,t_vals,u,Cj,Ci,L,KL_lines,v_lines,p_guess);

        KL = KL_all_out.KL;
        SE_KL = KL_all_out.dKL;
        dt_fit = KL_all_out.dt;
        SE_dt = KL_all_out.ddt;
        p_est = KL_all_out.p;
       
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
        Pe = u*L/KL;
        dtD = u*dt_fit/L;% respect to Vcore
        L_lines = v_lines*dt_fit;
        SE_Pe = (((-u*L*((KL)^-2))^2)*(SE_KL^2))^(1/2);
        SE_dtD = (((u/L)^2)*(SE_dt^2))^(1/2);
        SE_L_lines = ((v_lines^2)+(SE_dt))^(1/2);

        expProcData.(filedataExp.Key(i)).exp_params.KL_SI = KL;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_SI = SE_KL;
        expProcData.(filedataExp.Key(i)).exp_params.KL_cm2min = KL*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_cm2min = (SE_KL)*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.Pe = Pe;
        expProcData.(filedataExp.Key(i)).exp_params.SE_Pe = SE_Pe;
        expProcData.(filedataExp.Key(i)).exp_params.dt_SI = dt_fit;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dt_SI = SE_dt;
        expProcData.(filedataExp.Key(i)).exp_params.dt_min = dt_fit/60;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dt_min = SE_dt/60;
        expProcData.(filedataExp.Key(i)).exp_params.dtD = dtD;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dtD = SE_dtD;
        expProcData.(filedataExp.Key(i)).exp_params.L_lines = L_lines;
        expProcData.(filedataExp.Key(i)).exp_params.SE_L_lines = SE_L_lines;

        % Temperature stats
        T_mean = mean(expProcData.(filedataExp.Key(i)).BT.T_MFM);
        expProcData.(filedataExp.Key(i)).exp_params.T_mean = T_mean;
        T_std = std(expProcData.(filedataExp.Key(i)).BT.T_MFM);
        expProcData.(filedataExp.Key(i)).exp_params.T_std = T_std;

        % creating table 
        row_temp = expProcData.(filedataExp.Key(i)).exp_params; 
        fitting_results_temp = [fitting_results_temp;row_temp];

        % Build model function
        C_model = @(t) Ci + (Cj/2).*erfc((L - u.*t + v_lines.*dt_fit) ./ (2*p_est(1).*sqrt(max(t,eps))) );
        expProcData.(filedataExp.Key(i)).BT.Cimodel = 100*C_model(t_vals);
        expProcData.(filedataExp.Key(i)).BT.CimodelMax = 100.*(Ci + (Cj/2).*erfc( ...
            (L - u.*t_vals + v_lines*(dt_fit + SE_dt)) ./ (2*p_est(1).*sqrt(max(t_vals,eps))) ));
        expProcData.(filedataExp.Key(i)).BT.CimodelMin = 100*(Ci + (Cj/2).*erfc( ...
            (L - u.*t_vals + v_lines*(dt_fit - SE_dt)) ./ (2*p_est(1).*sqrt(max(t_vals,eps))) ));

    end
end
fitting_results = table();
for i = 1:length(filedataExp.Key)
    if filedataExp.Type(i) == "CF"

        % the sum of V lines before and after should be the same as Vtotal - Vcore      
        t_vals = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
        C1_vals = expProcData.(filedataExp.Key(i)).BT.Ci/100;
        dCi_vals = expProcData.(filedataExp.Key(i)).BT.dC/100;

        Ci = filedataExp.C1init(i)/100;
        Cj = filedataExp.C1j(i)/100;
        q = expProcData.(filedataExp.Key(i)).exp_params.Q_mlmin;
        u = expProcData.(filedataExp.Key(i)).exp_params.u_SI;
        L = expProcData.(filedataExp.Key(i)).exp_params.L_SI;
        v_lines = expProcData.(filedataExp.Key(i)).exp_params.v_lines_SI;
        L_guess = (fitting_results_temp.L_lines')*(fitting_results_temp.SE_L_lines/sum(fitting_results_temp.SE_L_lines)); % dtD fixed is a weigthed average
        % L_guess = fitting_results_temp.L_lines(fitting_results_temp.SE_L_lines==min(fitting_results_temp.SE_L_lines)); % dtD fixed is a weigthed average
        dt_guess = L_guess/v_lines; %  dt estimate according to velocity of each experiment
        p_guess = sqrt(expProcData.(filedataExp.Key(i)).exp_params.KL_SI);

        dt_fixed = dt_guess;
        ddt_all = expProcData.(filedataExp.Key(i)).exp_params.SE_dt_SI;

        KL_all_dtfixed_out = fit_dispersion_dtfixed_lines_error(C1_vals,dCi_vals,t_vals,u,Cj,Ci,L,v_lines,dt_guess,p_guess);
        KL_all_dtfixed_out_plus  = fit_dispersion_dtfixed_lines_error(C1_vals,dCi_vals,t_vals,u,Cj,Ci,L,v_lines,dt_fixed + ddt_all,p_guess);
        KL_all_dtfixed_out_minus = fit_dispersion_dtfixed_lines_error(C1_vals,dCi_vals,t_vals,u,Cj,Ci,L,v_lines,dt_fixed - ddt_all,p_guess);

        KL = KL_all_dtfixed_out.KL;
        SE_KL = KL_all_dtfixed_out.dKL;
        dt_fit = KL_all_dtfixed_out.dt;
        SE_dt = expProcData.(filedataExp.Key(i)).exp_params.SE_dt_SI;
        p_est = KL_all_dtfixed_out.p;

        dKL_ddt = (KL_all_dtfixed_out_plus.KL - KL_all_dtfixed_out_minus.KL) / (2*ddt_all);
        dKL_dtprop = abs(dKL_ddt) * ddt_all;

        dKL_fixed_total = sqrt(SE_KL^2 + dKL_dtprop^2);

        % Fitting parameters mean
        Pe = u*L/KL;
        dtD = u*dt_fit/L;% respect to Vcore
        L_lines = v_lines*dt_fit;
        SE_Pe = (((-u*L*((KL)^-2))^2)*(SE_KL^2))^(1/2);
        SE_dtD = (((u/L)^2)*(SE_dt^2))^(1/2);
        SE_L_lines = ((v_lines^2)+(SE_dt))^(1/2);
        
        expProcData.(filedataExp.Key(i)).exp_params.KL_dtfixed_SI = KL;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_dtfixed_SI = SE_KL;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_total_SI = dKL_fixed_total;
        expProcData.(filedataExp.Key(i)).exp_params.KL_dtfixed_cm2min = KL*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_dtfixed_cm2min = (SE_KL)*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.SE_KL_total_cm2min = dKL_fixed_total*60*10^4;
        expProcData.(filedataExp.Key(i)).exp_params.Pe_dtfixed = Pe;
        expProcData.(filedataExp.Key(i)).exp_params.SE_Pe_dtfixed = SE_Pe;
        expProcData.(filedataExp.Key(i)).exp_params.dt_dtfixed_SI = dt_fit;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dt_dtfixed_SI = SE_dt; 
        expProcData.(filedataExp.Key(i)).exp_params.dt_dtfixed_min = dt_fit/60;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dt_dtfixed_min = SE_dt/60; 
        expProcData.(filedataExp.Key(i)).exp_params.dtD_dtfixed = dtD;
        expProcData.(filedataExp.Key(i)).exp_params.SE_dtD_dtfixed = SE_dtD;
        expProcData.(filedataExp.Key(i)).exp_params.L_dtfixed_lines = L_lines;
        expProcData.(filedataExp.Key(i)).exp_params.SE_L_dtfixed_lines = SE_L_lines;

        % creating table
        row_temp = expProcData.(filedataExp.Key(i)).exp_params; 
        fitting_results = [fitting_results;row_temp];

        % Predicted C BT
        % Build model function
        C_model_fixed = @(t) Ci + (Cj/2).*erfc((L - u.*t + v_lines.*dt_fixed) ./ (2*p_est(1).*sqrt(max(t,eps))) );

        expProcData.(filedataExp.Key(i)).BT.Cimodel_fixed = 100*C_model_fixed(t_vals);
        expProcData.(filedataExp.Key(i)).BT.Cimodel_fixedMax = 100.*(Ci + (Cj/2).*erfc( ...
            (L - u.*t_vals + v_lines*(dt_fit + SE_dt)) ./ (2*p_est(1).*sqrt(max(t_vals,eps))) ));
        expProcData.(filedataExp.Key(i)).BT.Cimodel_fixedMin = 100.*(Ci + (Cj/2).*erfc( ...
            (L - u.*t_vals + v_lines*(dt_fit - SE_dt)) ./ (2*p_est(1).*sqrt(max(t_vals,eps))) ));

        % dimensionless values 
        % Cd = (C - Ciinit) / (Cj - Cinit)
        expProcData.(filedataExp.Key(i)).BT.CDimodel_fixed = ...
            (expProcData.(filedataExp.Key(i)).BT.Cimodel_fixed - Ci*100)/(Cj*100-Ci*100);

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

D0   = unique(fitting_results.D0_SI);
dD0  = unique(fitting_results.dD0_SI);

KL   = fitting_results.KL_dtfixed_SI;              % [L^2/T]
dKL  = fitting_results.SE_KL_dtfixed_SI/(60*1e4);  % same units as KL

KL_D0      = KL./D0;
dKL_D0     = sqrt( (dKL./D0).^2 + (KL.*dD0./D0.^2).^2 );   % error propagation
Pe_D0      = fitting_results.Pe_D0;                        % vL/D0

KL_D0_vs_Pe_model = @(p,Pe) ...
    (1./(1 + p(1).^2)) + ...                 % tau = 1 + q^2
    ( p(2).*Pe ).^( 1 + 0.25./(1 + exp(-p(3))) );   % beta in [1, 1.25]

p0 = [1, 1, 0];   % [tau, (alpha/L)^beta, beta]

opts = statset('nlinfit');
[p_est,res,J,CovB,mse] = nlinfit(Pe_D0, KL_D0, KL_D0_vs_Pe_model, p0, opts, ...
                                 'Weights', 1./dKL_D0);
dp = sqrt(diag(CovB));   % 1-sigma on parameters

q_tau     = p_est(1);
dq_tau    = sqrt(CovB(1,1));

tau   = 1 + q_tau^2;
dtau  = 2*q_tau * dq_tau;   % derivative of tau wrt q

q_beta = p_est(3);
dq_beta = sqrt(CovB(3,3));

beta = 1 + 0.25./(1 + exp(-q_beta));
dbeta_dq = 0.25 * exp(-q_beta) ./ (1 + exp(-q_beta)).^2;
dbeta = abs(dbeta_dq) * dq_beta;

Lchar = unique(fitting_results.L_SI);   % your Dp_SI

p2    = p_est(2);
dp2   = dp(2);

alpha = Lchar * p2^(1/beta);

dalpha_dp2   = Lchar * (1/beta) * p2^(1/beta - 1);
dalpha_dbeta = Lchar * p2^(1/beta) * ( -log(p2) / beta^2 );

dalpha = sqrt( (dalpha_dp2*dp2)^2 + (dalpha_dbeta*dbeta)^2 );

u_array = fitting_results.u_SI;

Pe_alpha_array = u_array .* alpha ./ D0;
dPe_alpha_array = sqrt( (u_array./D0).^2 .* dalpha.^2 + ...
                        (u_array.*alpha./D0.^2).^2 .* dD0.^2 );

KL_vs_D0_array  = KL_D0;
dKL_vs_D0_array = dKL_D0;

% Store arrays in fitting_results
fitting_results.Pe_alpha   = Pe_alpha_array;
fitting_results.dPe_alpha  = dPe_alpha_array;
fitting_results.KL_vs_D0   = KL_vs_D0_array;
fitting_results.dKL_vs_D0  = dKL_vs_D0_array;

% Store per-experiment values in expProcData
for i = 1:length(filedataExp.Key)

    key = filedataExp.Key(i);

    expProcData.(key).exp_params.Pe_alpha   = Pe_alpha_array(i);
    expProcData.(key).exp_params.dPe_alpha  = dPe_alpha_array(i);

    expProcData.(key).exp_params.KL_vs_D0   = KL_vs_D0_array(i);
    expProcData.(key).exp_params.dKL_vs_D0  = dKL_vs_D0_array(i);

end


%% Table results

%% Table results

% creating table all in cm2 and min, and mol %
% Pe alone is Pe in respect to KL and not D0
fitting_results_simple = fitting_results(:, {'Key', 'C1init_pcmol', ...
    'C1j_pcmol', 'Q_mlmin', 'u_cmmin', ...
    'KL_dtfixed_cm2min','SE_KL_dtfixed_cm2min',  'KL_vs_D0', 'dKL_vs_D0', 'Pe_dtfixed', 'SE_Pe_dtfixed', ...
    'dt_dtfixed_min', 'SE_dt_min', 'SE_dtD', ...
    'Pe_D0', 'dPe_D0', 'Pe_alpha', 'dPe_alpha', 'T_mean', 'T_std'});

fitting_params_simple = table("Berea", unique(fitting_results.Fluid1), unique(fitting_results.Fluid2),...
    unique(fitting_results.T_C),unique(fitting_results.P_psig), (unique(fitting_results.P_psig)+14.7)*0.00689476,...
    unique(fitting_results.D12_cm2min), unique(fitting_results.dD12_cm2min), ...
    unique(fitting_results.D_in)*2.54, unique(fitting_results.L_cm), ...
    unique(fitting_results.phi),unique(fitting_results.K_mD), ...
    alphaPe1*100, dalphaPe1*100, tortosityPe1, dtortosityPe1, betaPe1, ...
    'VariableNames',{'Sample', 'Fluid1','Fluid2', ...
    'T_C','P_psig','P_MPa', ...
    'D0_cm2min', 'dD0_cm2min', ...
    'D_cm', 'L_cm', ...
    'phi',  'K_mD', ...
    'alpha_cm', 'sd_alpha_cm', 'tortuosity', 'sd_tortuosity','beta'});

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
save(pathExportAll + "expProcFullData.mat",'expProcData')

% save fitting table
writetable(fitting_results_simple,table_name1 + ".xlsx");
writetable(fitting_params_simple,table_name2 + ".xlsx");
save(table_name1 + ".mat",'fitting_results_simple')
save(table_name2 + ".mat",'fitting_params_simple')

%% Fitting and experimental data all CF plot
% dt not shifted

for i = 1:length(filedataExp.Key)
    key = filedataExp.Key(i);

    % Time vector
    t_vals = expProcData.(key).BT.SecondsElapsed;

    % Extract pred values
    C_pred_free   = expProcData.(filedataExp.Key(i)).BT.Cimodel;
    C_pred_freeMax = expProcData.(filedataExp.Key(i)).BT.CimodelMax;
    C_pred_freeMin = expProcData.(filedataExp.Key(i)).BT.CimodelMin;

    C_pred_fixed  = expProcData.(filedataExp.Key(i)).BT.Cimodel_fixed;
    C_pred_fixedMax = expProcData.(filedataExp.Key(i)).BT.Cimodel_fixedMax;
    C_pred_fixedMin = expProcData.(filedataExp.Key(i)).BT.Cimodel_fixedMin;

    % Plot
    figure
    % errorbar(t_vals, C_pred_free, C_pred_free-C_pred_freeMin, C_pred_freeMax - C_pred_free, 'LineStyle', 'none', 'Color', [0.88 0.88 0.88],'HandleVisibility','off')
    % hold on 
    % errorbar(t_vals, C_pred_fixed, C_pred_fixed-C_pred_fixedMin, C_pred_fixedMax - C_pred_fixed, 'LineStyle', 'none', 'Color', [0.88 0.88 0.88],'HandleVisibility','off')
    scatter(expProcData.(key).BT.SecondsElapsed, ...
            expProcData.(key).BT.Ci, ...
            10, 'filled', 'MarkerFaceColor', 'red')
    hold on
    plot(expProcData.(key).BT.SecondsElapsed, C_pred_fixed, ...
         'LineWidth', 1.5, 'Color', 'k')

    plot(expProcData.(key).BT.SecondsElapsed, C_pred_free, ...
         'LineWidth', 1.5, 'Color', [0.5 0.5 0.5])

    xlabel('Time elapsed [hh:mm:ss]')
    % xtickformat('hh:mm:ss')
    ylabel('Molar concentration C_1 [mol %]')
    ylim([-0.1, 100.1])
    title(key + " fitting", 'Interpreter', 'none')
    grid on

    legend(["Experimental data", ...
            "BT model (dt fixed)", ...
            "BT model (dt free)"], ...
            'Location', 'southeast')

    saveas(gcf, pathExportAll + key + "_fitting", 'png')
    savefig(gcf, pathExportAll + key + "_fitting")

end

%% Plot Kl_vs_vel

% From your constrained fit:
% q_tau = p_est(1);
% p2    = p_est(2);
% beta  = beta;       % constrained [1, 1.25]
% tau   = tau;
% alpha = alpha;
% dalpha, dtau, dbeta already computed

% Model KL/D0
KL_D0_model = @(Pe) (1./(1 + q_tau.^2)) + (p2 .* Pe).^beta;

% Convert KL/D0 → KL in cm^2/min
KL_model_cm2min = @(Pe) KL_D0_model(Pe) * D0 * (60*1e4);

% Plot KL vs velocity (u_x)

colors = orderedcolors("glow");

Dp_SI = unique(fitting_results.L_SI);     % core length [m]
D0    = unique(fitting_results.D0_SI);    % free diffusion [m^2/s]

u_array_cmmin = fitting_results.u_cmmin;  % cm/min
KL_array      = fitting_results.KL_dtfixed_cm2min;
dKL_array     = fitting_results.SE_KL_dtfixed_cm2min;

% Generate model curve
Pe_grid = linspace(0, max(fitting_results.Pe_D0), 200);
u_grid_cmmin = (Pe_grid * D0 / Dp_SI) * (60*1e2);   % convert Pe → velocity

figure
plot(u_grid_cmmin, KL_model_cm2min(Pe_grid), 'k', 'LineWidth', 1.5, ...
    'DisplayName','K_L = D_0/\tau + (\alpha v/D_0)^\beta');
hold on

% Plot data with error bars
for i = 1:length(u_array_cmmin)
    errorbar(u_array_cmmin(i), KL_array(i), dKL_array(i), dKL_array(i), ...
        'Color','k','HandleVisibility','off')
    scatter(u_array_cmmin(i), KL_array(i), 50, colors(i,:), 'filled', ...
        'DisplayName',"Q = " + filedataExp.Q(i) + " ml/min")
end

xlabel('Interstitial velocity u_x [cm/min]')
ylabel('Longitudinal dispersion K_L [cm^2/min]')
ylim([0, max(KL_array)*1.3])
grid on
legend('Location','southeast')

% Annotations
annot1 = sprintf('\\alpha = %.2f \\pm %.2f cm', alpha*100, dalpha*100);
annot2 = sprintf('\\tau = %.2f \\pm %.2f', tau, dtau);
annot3 = sprintf('\\beta = %.2f \\pm %.2f', beta, dbeta);

annotation('textbox',[0.25 0.18 0.8 0.06],'String',annot1,...
    'Interpreter','tex','FontSize',9,'EdgeColor','none');
annotation('textbox',[0.25 0.13 0.8 0.06],'String',annot2,...
    'Interpreter','tex','FontSize',9,'EdgeColor','none');
annotation('textbox',[0.25 0.08 0.8 0.06],'String',annot3,...
    'Interpreter','tex','FontSize',9,'EdgeColor','none');

saveas(gcf, pathExportAll + "KLvsVel-alpha_all", 'png')
savefig(gcf, pathExportAll + "KLvsVel-alpha_all")

% Plot KL/D0 vs Pe

Pe_array      = fitting_results.Pe_D0;
dPe_array     = fitting_results.dPe_D0;
KL_D0_array   = fitting_results.KL_vs_D0;
dKL_D0_array  = fitting_results.dKL_vs_D0;

Pe_grid = logspace(log10(min(Pe_array)/2), log10(max(Pe_array)*2), 200);

figure
plot(Pe_grid, KL_D0_model(Pe_grid), 'k', 'LineWidth', 1.5, ...
    'DisplayName','K_L/D_0 = 1/\tau + (\alpha Pe)^\beta');
hold on

for i = 1:length(Pe_array)
    errorbar(Pe_array(i), KL_D0_array(i), ...
        dKL_D0_array(i), dKL_D0_array(i), ...
        dPe_array(i), dPe_array(i), ...
        'Color','k','HandleVisibility','off')
    scatter(Pe_array(i), KL_D0_array(i), 50, colors(i,:), 'filled', ...
        'DisplayName',"Q = " + filedataExp.Q(i) + " ml/min")
end

set(gca,'XScale','log','YScale','log')
xlabel('Pe = u_x L / D_0')
ylabel('K_L / D_0')
grid on
legend('Location','northwest')

saveas(gcf, pathExportAll + "KLD0vsPe_all", 'png')
savefig(gcf, pathExportAll + "KLD0vsPe_all")