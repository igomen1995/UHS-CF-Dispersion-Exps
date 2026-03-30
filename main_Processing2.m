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

        KL_all_dtfixed_out = fit_dispersion_dtfixed_lines_error(C1_vals,dCi_vals,t_vals,u,Cj,Ci,L,KL_lines,v_lines,dt_guess,p_guess);
        KL_all_dtfixed_out_plus  = fit_dispersion_dtfixed_lines_error(C1_vals,dCi_vals,t_vals,u,Cj,Ci,L,KL_lines,v_lines,dt_fixed + ddt_all,p_guess);
        KL_all_dtfixed_out_minus = fit_dispersion_dtfixed_lines_error(C1_vals,dCi_vals,t_vals,u,Cj,Ci,L,KL_lines,v_lines,dt_fixed - ddt_all,p_guess);

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

% Pe with Dp = L; Pe = u*L/D0
% KL = D0 *(1/tao + C2((Pe)^beta))
% KL = D0 *(1/tao + ((C2^(1/beta))*(Pe))^beta)
% alpha_L = (C2^(1/beta)*L

% all params in SI
Dp_SI = unique(fitting_results.L_SI);
u_array = fitting_results.u_SI;
Pe_D0_array = fitting_results.Pe_D0; % Pe in respect to D0
dPe_D0_array = fitting_results.dPe_D0;
% Pe_array = fitting_results.Pe; % Pe in respect to KL
% dPe_array = fitting_results.sd_Pe_avg;
Pe_array = fitting_results.Pe_dtfixed; % Pe in respect to KL
dPe_array = fitting_results.SE_Pe_dtfixed;
D0 = unique(fitting_results.D0_SI);
dD0 = unique(fitting_results.dD0_SI);
% KL_array = fitting_results.KL_SI; % KL and D0 must have same units
% dKL_array = fitting_results.SE_KL_SI/(60*10^4);
KL_array = fitting_results.KL_dtfixed_SI; % KL and D0 must have same units
dKL_array = fitting_results.SE_KL_dtfixed_SI/(60*10^4);

% fitting data
u = u_array;
Pe = Pe_D0_array;
KL = KL_array;
dKL = dKL_array;

% KL/D0 vs Pe fitting, Pe = UL/D0
KL_D0_vs_Pe_function = @(p1,Pe)D0 *((1/p1(1)) + ((p1(2)^(1/p1(3)))*Pe).^p1(3));
p1 = [1,1,1];
% KL_D0_vs_Pe_function = @(p1,Pe)D0 *((1/p1(1)) + p1(2)*Pe);
% p1 = [1,1];
% KL_D0_vs_Pe_function = @(p1,Pe)D0 *(p1(2)*Pe);
% p1 = [1,1];
% fitting not uncertainties
KL_D0_vs_Pe_fit = fitnlm(Pe,KL_array,KL_D0_vs_Pe_function,p1);

tortosityPe1 = KL_D0_vs_Pe_fit.Coefficients.Estimate(1);
% betaPe1 = KL_D0_vs_Pe_fit.Coefficients.Estimate(3);
betaPe1 = 1;
alphaPe1 = (KL_D0_vs_Pe_fit.Coefficients.Estimate(2)^(betaPe1))*Dp_SI; % SI
dtortosityPe1 = KL_D0_vs_Pe_fit.Coefficients.SE(1);
% dbetaPe1 = KL_D0_vs_Pe_fit.Coefficients.SE(3);
dbetaPe1 = 0;
dalphaPe1 = ((Dp_SI^2)*(KL_D0_vs_Pe_fit.Coefficients.SE(2)^2))^(1/2); % SI

% % fitting with uncertainties
% resKL_D0_vs_Pe_function = @(p,Pe) (KL - KL_D0_vs_Pe_function(p,Pe)) ./ dKL;
% p1 = [1,1];
% [p1_fit,~,~,~,~,~,J] = lsqcurvefit(resKL_D0_vs_Pe_function, p1, Pe, zeros(size(KL)));
% resKL_D0_vs_Pe = resKL_D0_vs_Pe_function(p1_fit,Pe);
% p1_fit_uncert = nlparci(p1_fit, resKL_D0_vs_Pe, 'jacobian', J);
% 
% tortosityPe2 = p1_fit(1);
% % betaPe2 = p1_fit(3);
% betaPe2 = 1;
% alphaPe2 = (p1_fit(2)^(betaPe1))*Dp_SI; % SI
% dtortosityPe2 = (p1_fit_uncert(1,2)-p1_fit_uncert(1,1))/(2*1.96);
% % dbetaPe2 = (p1_fit_uncert(3,2)-p1_fit_uncert(3,1))/(2*1.96);
% dbetaPe2 = 0;
% dalphaPe2 = ((Dp_SI^2)*(((p1_fit_uncert(1,2)-p1_fit_uncert(1,1))/(2*1.96))^2))^(1/2); % SI

% alpha lin fitting Kl with v not needed since we can use the one that also
% depends on tortuosity

% % alpha lin fitting
% KL_D0_vs_u_function = @(p2,u)(p2(1)*u);
% resKL_D0_vs_u_function = @(p,u) max((KL - KL_D0_vs_u_function(p,u)) ./ dKL);
% p2 = 1;
% % fitting not uncertainties
% KL_D0_vs_u_fit = fitnlm(u_array,KL_array,KL_D0_vs_u,p2);
% % fitting with uncertainties
% [p2_fit,~,~,~,~,~,J] = lsqcurvefit(resKL_D0_vs_u_function, p2, u, 0);
% resKL_D0_vs_u = resKL_D0_vs_u_function(p2_fit,u);
% p2_fit_uncert = nlparci(p2_fit, resKL_D0_vs_u, 'jacobian', J);
% 
% alphau1_SI = KL_D0_vs_u_fit.Coefficients.Estimate(1);
% alphau1_cm = KL_D0_vs_u_fit.Coefficients.Estimate(1)*100; %cm
% dalphau1_SI = KL_D0_vs_u_fit.Coefficients.SE(1); % error
% dalphau1_cm = KL_D0_vs_u_fit.Coefficients.SE(1)*100; %cm
% 
% alphau2_SI = p2_fit;
% alphau2_cm = p2_fit*100; %cm

% Peclet with Dp = alpha instead of L
Pe_alpha_array = u_array*alphaPe1/D0;
dPe_alpha_array = (((u_array/D0).^2)*(dalphaPe1^2)+((-u_array*alphaPe1/(D0^2)).^2)*(dD0^2)).^(1/2);
% Peclet/D0
KL_vs_D0_array = KL_array/D0;
dKL_vs_D0_array = (((1/D0).^2)*(dKL_array.^2)+((-KL_array/(D0^2)).^2)*(dD0^2)).^(1/2);

% add KL/D0 uncertainty as well

% Add Pe_alpha in exp_params and fitting results
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

%% Table results

% creating table all in cm2 and min, and mol %
% Pe alone is Pe in respect to KL and not D0
fitting_results_simple = fitting_results(:, {'Key', 'C1init_pcmol', ...
    'C1j_pcmol', 'Q_mlmin', 'u_cmmin', 'SE_KL_dtfixed_cm2min', 'KL_vs_D0', 'dKL_vs_D0', 'Pe_dtfixed', 'SE_Pe_dtfixed', ...
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
    cond = (expProcData.(filedataExp.Key(i)).BT.Cimodel_fixed>=10)&(expProcData.(filedataExp.Key(i)).BT.Cimodel_fixed<=90);
    % errorbar(t(cond), expProcData.(filedataExp.Key(i)).BT.Cimodel(cond), ...
    %    expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.RMSE*100*ones(size(t(cond))), ...
    %    'LineStyle', 'none', ...
    %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
    
    errorbar(t, C1, C1-C1min, C1max - C1, 'LineStyle', 'none', ...
        'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
    hold on
    h1 = scatter(t,C1,5,'filled','MarkerFaceColor',colors(i,:), ...
        'DisplayName',"Q"+filedataExp.Q(i)+": C_{MFM} \pm \DeltaC_{MFM}");
    h2 = plot(t(cond), expProcData.(filedataExp.Key(i)).BT.Cimodel_fixed(cond), ...
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
    cond = (expProcData.(filedataExp.Key(i)).BT.Cimodel_fixed>=10)&(expProcData.(filedataExp.Key(i)).BT.Cimodel_fixed<=90);
    % errorbar(tD(cond), expProcData.(filedataExp.Key(i)).BT.CDimodel(cond), ...
    %    expProcData.(filedataExp.Key(i)).exp_params.C_fit_dtfixed.RMSE*ones(size(tD(cond))), ...
    %    'LineStyle', 'none', ...
    %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
    % hold on
    % errorbar(tD, CD1, CD1-CD1min, CD1max - CD1, 'LineStyle', 'none', ...
    %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
    h1 = scatter(tD,CD1,5,'filled','MarkerFaceColor',colors(i,:), ...
        'DisplayName',"Q"+filedataExp.Q(i)+": C_{D}");
    hold on
    h2 = plot(tD(cond), expProcData.(filedataExp.Key(i)).BT.CDimodel_fixed(cond), ...
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
        'DisplayName',"Q"+filedataExp.Q(i)+": C_{D}");
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
u_array_cm2min = fitting_results.u_cmmin;
KL_array = fitting_results.KL_dtfixed_cm2min; % KL and D0 must have same units
dKLneg_array = fitting_results.SE_KL_dtfixed_cm2min;
dKLpos_array = fitting_results.SE_KL_dtfixed_cm2min;
alpha_L = alphaPe1*100;
dalpha_L = dalphaPe1*100;
tortuosity = tortosityPe1;
dtortuosity = dtortosityPe1;

figure % dispersivity
x = 0:1:ceil(max(Pe_D0_array));
plot((x*D0/Dp_SI)*(60*10^2),KL_D0_vs_Pe_fit.feval(x)*(60*10^4), ...
    'DisplayName','K_L = D_0/\tau + \alpha_Lu_x','Color','k'); % Kl_vs_u fitting
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
annotation('textbox', [0.265, 0.13, 0.8, 0.06], 'String', annotText2, ...
    'Interpreter', 'tex', 'FontSize', 9, 'EdgeColor', 'none','FaceAlpha',0.1);
legend('Location','southeast');
saveas(gcf,pathExportAll + "KLvsVel-alpha_all",'png')
savefig(gcf,pathExportAll + "KLvsVel-alpha_all")

%% Plot Kl/Dl vs Pe

% % all params in SI
% Pe_array = Pe_alpha_array; % Pe in respect to D0
% dPe_array = fitting_results.dPe_alpha;
% KL_vs_D0_array = fitting_results.KL_vs_D0;
% dKL_vs_D0_array = fitting_results.dKL_vs_D0;
% D0 = unique(fitting_results.D0_SI);
% dD0 = unique(fitting_results.dD0_SI);
% KL_array = fitting_results.KL_SI; % KL and D0 must have same units
% dKL_array = fitting_results.SE_KL_SI/(60*10^4);

figure
plot(0:0.1:max(Pe_D0_array),KL_D0_vs_Pe_fit.feval(0:0.1:max(Pe_D0_array))/D0, ...
    'DisplayName','K_L/D_0 = 1/\tau + \alpha_Lu_x/D_0','Color','k'); % Kl_vs_u fitting
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



