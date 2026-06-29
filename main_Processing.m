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

            % dt fixed weigthed fit wit dt weigthed limited C
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,dC_vals,Cmin,Cmax);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_wfit_wdt_lim = [method_results.dt_fixed_wfit_wdt_lim; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_wfit_wdt_lim = 100*KL_out.C_fit;

            % dt fixed non weigthed fit wit dt weigthed limited C

            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,ones(size(C1_vals)),Cmin,Cmax);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_nwfit_wdt_lim = [method_results.dt_fixed_nwfit_wdt_lim; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_nwfit_wdt_lim = 100*KL_out.C_fit;

            % dt fixed weigthed fit wit dt weigthed full
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,dC_vals,0,1);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_wfit_wdt_full = [method_results.dt_fixed_wfit_wdt_full; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_wfit_wdt_full = 100*KL_out.C_fit;

            % dt fixed non weigthed fit wit dt weigthed full
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

            % dt fixed weigthed fit wit dt non weigthed limited C
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,dC_vals,Cmin,Cmax);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_wfit_nwdt_lim = [method_results.dt_fixed_wfit_nwdt_lim; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_wfit_nwdt_lim = 100*KL_out.C_fit;

            % dt fixed non weigthed fit wit dt non weigthed limited C

            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,ones(size(C1_vals)),Cmin,Cmax);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_nwfit_nwdt_lim = [method_results.dt_fixed_nwfit_nwdt_lim; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_nwfit_nwdt_lim = 100*KL_out.C_fit;

            % dt fixed weigthed fit wit dt weigthed full
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,dC_vals,0,1);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);

            method_results.dt_fixed_wfit_nwdt_full = [method_results.dt_fixed_wfit_nwdt_full; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_wfit_nwdt_full = 100*KL_out.C_fit;

            % dt fixed non weigthed fit wit dt non weigthed full
            % non linear fitting using [p_est,R,J,CovB,MSE,ErrorModelInfo] = nlinfit(t_trim, C_trim, C_function, p0, opts, 'Weights', w_trim);
            KL_out = fit_dispersion_dtfixed_nlinfit(C1_vals,t_vals,u,Cj,Ci,L,dt_fixed,p_guess,ones(size(C1_vals)),0,1);

            % exp params for table
            row = buildRow_procResults(filedataExp, expProcData, KL_out, i);
    
            method_results.dt_fixed_nwfit_nwdt_full = [method_results.dt_fixed_nwfit_nwdt_full; row];

            expProcData.(filedataExp.Key(i)).BT.C_fit_dt_fixed_nwfit_wdt_full = 100*KL_out.C_fit;
        end
    end
end

%% Select the valid and best method results
method_names = fieldnames(method_results);
nExp = height(filedataExp);

valid_methods = [];
mean_R2 = [];


for m = 1:length(method_names)

    method_table = method_results.(method_names{m});

    valid = isfinite(method_table.KL_SI) & isfinite(method_table.R2) & isfinite(method_table.RMSE);

    if all(valid)
        valid_methods = [valid_methods; string(method_names{m})];
        mean_R2 = [mean_R2; mean(method_table.R2)];
    end
end

% Select best method
[~, idx_best] = max(mean_R2);
best_method = valid_methods(idx_best);

disp("Best method: " + best_method)

% Store best fit in expProcData
best_method_table = method_results.(best_method);
for i = 1:length(filedataExp.Key)

    key = filedataExp.Key(i);

    row_best = best_method_table(i,:);

    expProcData.(key).results = row_best;
    expProcData.(key).results.model = best_method;

    expProcData.(key).BT.C_fit_best = ...
        100 * best_method_table.C_fit{i};
end

%% Plotting KL results
% Fitting and experimental data all CF plot all methods

colors = parula(length(method_names));

for i = 1:length(filedataExp.Key)
    figure
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed, ...
        expProcData.(filedataExp.Key(i)).BT.Ci,10,'filled', ...
        'MarkerFaceColor','red','DisplayName','Experimental Data')
    hold on
    for j = 1:length(method_names)
        method_results_table = method_results.(method_names{j});
        plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed, ...
            method_results_table.C_fit{i}*100,'LineWidth',1.5, ...
            'Color', colors(j,:), ...
            'DisplayName',method_names{j})
    end
    % KL best
    plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed, ...
    expProcData.(filedataExp.Key(i)).BT.C_fit_best,'LineWidth',1.5, ...
    'Color', 'k', 'DisplayName',"BT model best fitting - " +  expProcData.(filedataExp.Key(i)).results.model)
    xlabel('Time elapsed [hh:mm:ss]');
    xtickformat('hh:mm:ss')
    ylabel('Molar concentration C_1 [mol %]');
    ylim([-0.1,100.1]);
    title(filedataExp.Key(i) + " fitting", 'Interpreter', 'none')
    grid on;
    legend('Location','southeast','Interpreter','none');
    saveas(gcf,pathExportAll + filedataExp.Key(i) + "_fittingAll",'png')
    savefig(gcf,pathExportAll + filedataExp.Key(i) + "_fittingAll")
end

% only best
for i = 1:length(filedataExp.Key)
    figure
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed, ...
        expProcData.(filedataExp.Key(i)).BT.Ci,10,'filled', ...
        'MarkerFaceColor','red','DisplayName','Experimental Data')
    hold on
    % KL best
    plot(expProcData.(filedataExp.Key(i)).BT.TimeElapsed, ...
    expProcData.(filedataExp.Key(i)).BT.C_fit_best,'LineWidth',1.5, ...
    'Color', 'k', 'DisplayName',"BT model best fitting - " +  expProcData.(filedataExp.Key(i)).results.model)
    xlabel('Time elapsed [hh:mm:ss]');
    xtickformat('hh:mm:ss')
    ylabel('Molar concentration C_1 [mol %]');
    ylim([-0.1,100.1]);
    title(filedataExp.Key(i) + " fitting", 'Interpreter', 'none')
    grid on;
    legend('Location','southeast','Interpreter','none');
    saveas(gcf,pathExportAll + filedataExp.Key(i) + "_fitting",'png')
    savefig(gcf,pathExportAll + filedataExp.Key(i) + "_fitting")
end


%% Fitting and experimental data all CF plot dimensionless

% Dimensionless only best
for i = 1:length(filedataExp.Key)
    figure
    scatter(expProcData.(filedataExp.Key(i)).BT.tD, ...
        expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled', ...
        'MarkerFaceColor','red','DisplayName','Experimental Data')
    hold on
    % KL best
    plot(expProcData.(filedataExp.Key(i)).BT.tD, ...
    expProcData.(filedataExp.Key(i)).BT.C_fit_best/100,'LineWidth',1.5, ...
    'Color', 'k', 'DisplayName',"BT model best fitting - " +  expProcData.(filedataExp.Key(i)).results.model)
    xlabel('Dimensionless Time [-]');
    % xlim([0,2]);
    ylabel('C_{D}[-]');
    ylim([-0.001,1.001]);
    title(filedataExp.Key(i) + " dimensionless fitting", 'Interpreter', 'none')
    grid on;
    legend('Location','southeast');
    saveas(gcf,pathExportAll + filedataExp.Key(i) + "_dimless_fitting",'png')
    savefig(gcf,pathExportAll + filedataExp.Key(i) + "_dimless_fitting")
end


% Fitting and experimental data all CF plot dimensionless total

% Dimensionless only best
for i = 1:length(filedataExp.Key)
    figure
    scatter(expProcData.(filedataExp.Key(i)).BT.tDtotal, ...
        expProcData.(filedataExp.Key(i)).BT.CDi,10,'filled', ...
        'MarkerFaceColor','red','DisplayName','Experimental Data')
    hold on
    % KL best
    plot(expProcData.(filedataExp.Key(i)).BT.tDtotal, ...
    expProcData.(filedataExp.Key(i)).BT.C_fit_best/100,'LineWidth',1.5, ...
    'Color', 'k', 'DisplayName',"BT model best fitting - " +  expProcData.(filedataExp.Key(i)).results.model)
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

colors = orderedcolors("glow");
colorsdark = orderedcolors("earth"); 

% empty objects
h1 = gobjects(length(filedataExp.Key),1);
h2 = gobjects(length(filedataExp.Key),1);
h_titles = gobjects(length(filedataExp.Key),1);

Fluid1_unique = unique(filedataExp.Fluid1);
Fluid2_unique = unique(filedataExp.Fluid2);
T_unique = unique(filedataExp.T);
P_unique = unique(filedataExp.P);

for j = 1:length(Fluid1_unique)
    for jj = 1:length(Fluid2_unique)
        for k = 1:length(T_unique)
            for l = 1:length(P_unique)

                figure
                h = [];
                h1 = [];
                h2 = [];
                h_titles = [];
        
                count = 0;
        
                for i = 1:length(filedataExp.Key)
        
                    if filedataExp.Fluid1(i) == Fluid1_unique(j) && filedataExp.Fluid2(i) == Fluid2_unique(jj) ...
                            && filedataExp.T(k) == T_unique(j) && filedataExp.P(l) == P_unique(j)
        
                        count = count + 1;
        
                        t = expProcData.(filedataExp.Key(i)).BT.TimeElapsed;
                        t_sec = expProcData.(filedataExp.Key(i)).BT.SecondsElapsed;
                        C1 = expProcData.(filedataExp.Key(i)).BT.Ci;
                        C1min = expProcData.(filedataExp.Key(i)).BT.CiMin;
                        C1max = expProcData.(filedataExp.Key(i)).BT.CiMax;
                        C_fit = expProcData.(filedataExp.Key(i)).BT.C_fit_best;
                        % plot vals with function dt fixed weighted
                        cond = (C_fit>=16)&(C_fit<=84);
                        t_sec_cond = t(cond);
                        t_sec_cond.Format = 'hh:mm:ss';
                        C_fit_cond = C_fit(cond);
                        % Uncomment below line to show error bar
                        % errorbar(t, C1, C1-C1min, C1max - C1, 'LineStyle', 'none', ...
                        %     'Color', [0.88 0.88 0.88],'HandleVisibility','Off')
                        hold on
                        h1(count) = scatter(t,C1,5,'filled','MarkerFaceColor',colors(count,:), ...
                            'DisplayName',"C_{MFM} \pm \DeltaC_{MFM}");
                        h2(count) = plot(t_sec_cond, C_fit_cond, ...
                            'LineWidth',3,'Color', colorsdark(count,:),'DisplayName',"C_{fit}"); 
                        h_titles(count) = plot(NaN,NaN,'w', 'LineStyle','none', 'DisplayName', "\bf Q = " + filedataExp.Q(i) + " ml/min");
                        xlabel('Time elapsed [hh:mm:ss]','FontSize',14);
                        xtickformat('hh:mm:ss')
                        ylabel('C_{H_2} [mol %]','FontSize',14);
                        ylim([-0.1,100.1]);
                        ax = gca; % Get current axes
                        ax.FontSize = 12;
                        % title("Breakthrough curves fitting", 'Interpreter', 'none')
                        grid on;
                        % h = [h; h1];
                        h = [h;h_titles(count);h1(count);h2(count)];
                        
                        save_name = "CF_"+filedataExp.Fluid1(i)+"_"+filedataExp.Fluid2(i)+"_T"+filedataExp.T(i)+"_P"+filedataExp.P(i);
                        % add vertical or horizontal to tile (fix input excel (add orientation variable) for that)
                    end
                end
                lgd = legend(h, 'NumColumns', 1, ...
                    'Location', 'southeast', 'FontSize', 10);
                lgd.ItemTokenSize = [15 8];   % tighter symbols
                
                drawnow  % REQUIRED for correct positions
                
                lgd_pos = lgd.Position;  % [x y width height]
                nQ = count;
                nRows = 3 * nQ;
                rowH = lgd_pos(4) / nRows;   % approximate row height
                
                
                for i = 1:nQ
                    % Row indices (from top of legend)
                    row_Q    = (i-1)*3 + 1;
                    row_Data = row_Q + 1;
                
                    % Y positions (legend is bottom-based)
                    y1 = lgd_pos(2) + lgd_pos(4) - (row_Q-0.12)*rowH;
                
                    % X positions (small indentation inside legend box)
                    x1 = lgd_pos(1);
                    x2 = lgd_pos(1) + lgd_pos(3);
                
                    % Draw line
                    annotation('line', [x1 x2], [y1 y1], ...
                        'Color','k', 'LineWidth',0.8);
                end
                
                for i = 1:nQ-1
                
                    % Y positions (legend is bottom-based)
                    y1 = lgd_pos(2) + lgd_pos(4) - 3*i*rowH;
                
                    % X positions (small indentation inside legend box)
                    x1 = lgd_pos(1);
                    x2 = lgd_pos(1) + lgd_pos(3);
                
                    % Draw line
                    annotation('line', [x1 x2], [y1 y1], ...
                        'Color','k', 'LineWidth',0.8);
                end
                
                title(save_name,'Interpreter','none')
                saveas(gcf,pathExportAll + save_name + "_BTfitting",'png')
                savefig(gcf,pathExportAll + save_name + "_BTfitting")

            end
        end
    end
end


%% Fitting and experimental data all CF plot
% dimensionless
colors = orderedcolors("glow");
colorsdark = orderedcolors("earth"); 

% empty objects
h1 = gobjects(length(filedataExp.Key),1);
h2 = gobjects(length(filedataExp.Key),1);
h_titles = gobjects(length(filedataExp.Key),1);

Fluid1_unique = unique(filedataExp.Fluid1);
Fluid2_unique = unique(filedataExp.Fluid2);
T_unique = unique(filedataExp.T);
P_unique = unique(filedataExp.P);

for j = 1:length(Fluid1_unique)
    for jj = 1:length(Fluid2_unique)
        for k = 1:length(T_unique)
            for l = 1:length(P_unique)

                figure
                h = [];
                h1 = [];
                h2 = [];
                h_titles = [];
        
                count = 0;
        
                for i = 1:length(filedataExp.Key)
        
                    if filedataExp.Fluid1(i) == Fluid1_unique(j) && filedataExp.Fluid2(i) == Fluid2_unique(jj) ...
                            && filedataExp.T(k) == T_unique(j) && filedataExp.P(l) == P_unique(j)
        
                        count = count + 1;

                        tD = expProcData.(filedataExp.Key(i)).BT.tD;
                        CD1 = expProcData.(filedataExp.Key(i)).BT.CDi;
                        CD1min = expProcData.(filedataExp.Key(i)).BT.CDiMin;
                        CD1max = expProcData.(filedataExp.Key(i)).BT.CDiMax;
        
                        CD_fit = expProcData.(filedataExp.Key(i)).BT.C_fit_best/100;
                        % plot vals with function dt fixed weighted
                        cond = (CD_fit>=0.16)&(CD_fit<=0.84);
                        tD_cond = tD(cond);
                        CD_fit_cond = CD_fit(cond);
                        hold on
                        h1(count) = scatter(tD,CD1,5,'filled','MarkerFaceColor',colors(count,:), ...
                            'DisplayName',"C_{MFM}");
                        h2(count) = plot(tD_cond, CD_fit_cond, ...
                            'LineWidth',3,'Color', colorsdark(count,:),'DisplayName',"C_{fit}"); 
                        h_titles(count) = plot(NaN,NaN,'w', 'LineStyle','none', 'DisplayName', "\bf Q = " + filedataExp.Q(i) + " ml/min");
                        xlabel('Dimensionless Time [-]');
                        ylabel('C_{D}[-]');
                        ylim([-0.001,1.001]);
                        ax = gca; % Get current axes
                        ax.FontSize = 12;
                        % title("Breakthrough curves fitting", 'Interpreter', 'none')
                        grid on;
                        % h = [h; h1];
                        h = [h;h_titles(count);h1(count);h2(count)];
                        
                        save_name = "CF_"+filedataExp.Fluid1(i)+"_"+filedataExp.Fluid2(i)+"_T"+filedataExp.T(i)+"_P"+filedataExp.P(i);
                        % add vertical or horizontal to tile (fix input excel (add orientation variable) for that)
                    end
                end
                lgd = legend(h, 'NumColumns', 1, ...
                    'Location', 'southeast', 'FontSize', 10);
                lgd.ItemTokenSize = [15 8];   % tighter symbols
                
                drawnow  % REQUIRED for correct positions
                
                lgd_pos = lgd.Position;  % [x y width height]
                nQ = count;
                nRows = 3 * nQ;
                rowH = lgd_pos(4) / nRows;   % approximate row height
                
                
                for i = 1:nQ
                    % Row indices (from top of legend)
                    row_Q    = (i-1)*3 + 1;
                    row_Data = row_Q + 1;
                
                    % Y positions (legend is bottom-based)
                    y1 = lgd_pos(2) + lgd_pos(4) - (row_Q-0.12)*rowH;
                
                    % X positions (small indentation inside legend box)
                    x1 = lgd_pos(1);
                    x2 = lgd_pos(1) + lgd_pos(3);
                
                    % Draw line
                    annotation('line', [x1 x2], [y1 y1], ...
                        'Color','k', 'LineWidth',0.8);
                end
                
                for i = 1:nQ-1
                
                    % Y positions (legend is bottom-based)
                    y1 = lgd_pos(2) + lgd_pos(4) - 3*i*rowH;
                
                    % X positions (small indentation inside legend box)
                    x1 = lgd_pos(1);
                    x2 = lgd_pos(1) + lgd_pos(3);
                
                    % Draw line
                    annotation('line', [x1 x2], [y1 y1], ...
                        'Color','k', 'LineWidth',0.8);
                end
                
                title(save_name,'Interpreter','none')
                saveas(gcf,pathExportAll + save_name + "_BTfitting_dimless",'png')
                savefig(gcf,pathExportAll + save_name + "_BTfitting_dimless")

            end
        end
    end
end

%% Fitting and experimental data all CF plot
% dimensionless total
colors = orderedcolors("glow");
colorsdark = orderedcolors("earth"); 

% empty objects
h1 = gobjects(length(filedataExp.Key),1);
h2 = gobjects(length(filedataExp.Key),1);
h_titles = gobjects(length(filedataExp.Key),1);

Fluid1_unique = unique(filedataExp.Fluid1);
Fluid2_unique = unique(filedataExp.Fluid2);
T_unique = unique(filedataExp.T);
P_unique = unique(filedataExp.P);

for j = 1:length(Fluid1_unique)
    for jj = 1:length(Fluid2_unique)
        for k = 1:length(T_unique)
            for l = 1:length(P_unique)

                figure
                h = [];
                h1 = [];
                h2 = [];
                h_titles = [];
        
                count = 0;
        
                for i = 1:length(filedataExp.Key)
        
                    if filedataExp.Fluid1(i) == Fluid1_unique(j) && filedataExp.Fluid2(i) == Fluid2_unique(jj) ...
                            && filedataExp.T(k) == T_unique(j) && filedataExp.P(l) == P_unique(j)
        
                        count = count + 1;

                        tDtotal = expProcData.(filedataExp.Key(i)).BT.tDtotal;
                        CD1 = expProcData.(filedataExp.Key(i)).BT.CDi;
                        CD1min = expProcData.(filedataExp.Key(i)).BT.CDiMin;
                        CD1max = expProcData.(filedataExp.Key(i)).BT.CDiMax;
        
                        CD_fit = expProcData.(filedataExp.Key(i)).BT.C_fit_best/100;
                        % plot vals with function dt fixed weighted
                        cond = (CD_fit>=0.16)&(CD_fit<=0.84);
                        tDtotal_cond = tDtotal(cond);
                        CD_fit_cond = CD_fit(cond);
                        hold on
                        h1(count) = scatter(tDtotal,CD1,5,'filled','MarkerFaceColor',colors(count,:), ...
                            'DisplayName',"C_{MFM}");
                        h2(count) = plot(tDtotal_cond, CD_fit_cond, ...
                            'LineWidth',3,'Color', colorsdark(count,:),'DisplayName',"C_{fit}"); 
                        h_titles(count) = plot(NaN,NaN,'w', 'LineStyle','none', 'DisplayName', "\bf Q = " + filedataExp.Q(i) + " ml/min");
                        xlabel('Dimensionless Time (total)[-]');
                        ylabel('C_{D}[-]');
                        ylim([-0.001,1.001]);
                        ax = gca; % Get current axes
                        ax.FontSize = 12;
                        % title("Breakthrough curves fitting", 'Interpreter', 'none')
                        grid on;
                        % h = [h; h1];
                        h = [h;h_titles(count);h1(count);h2(count)];
                        
                        save_name = "CF_"+filedataExp.Fluid1(i)+"_"+filedataExp.Fluid2(i)+"_T"+filedataExp.T(i)+"_P"+filedataExp.P(i);
                        % add vertical or horizontal to tile (fix input excel (add orientation variable) for that)
                    end
                end
                lgd = legend(h, 'NumColumns', 1, ...
                    'Location', 'southeast', 'FontSize', 10);
                lgd.ItemTokenSize = [15 8];   % tighter symbols
                
                drawnow  % REQUIRED for correct positions
                
                lgd_pos = lgd.Position;  % [x y width height]
                nQ = count;
                nRows = 3 * nQ;
                rowH = lgd_pos(4) / nRows;   % approximate row height
                
                
                for i = 1:nQ
                    % Row indices (from top of legend)
                    row_Q    = (i-1)*3 + 1;
                    row_Data = row_Q + 1;
                
                    % Y positions (legend is bottom-based)
                    y1 = lgd_pos(2) + lgd_pos(4) - (row_Q-0.12)*rowH;
                
                    % X positions (small indentation inside legend box)
                    x1 = lgd_pos(1);
                    x2 = lgd_pos(1) + lgd_pos(3);
                
                    % Draw line
                    annotation('line', [x1 x2], [y1 y1], ...
                        'Color','k', 'LineWidth',0.8);
                end
                
                for i = 1:nQ-1
                
                    % Y positions (legend is bottom-based)
                    y1 = lgd_pos(2) + lgd_pos(4) - 3*i*rowH;
                
                    % X positions (small indentation inside legend box)
                    x1 = lgd_pos(1);
                    x2 = lgd_pos(1) + lgd_pos(3);
                
                    % Draw line
                    annotation('line', [x1 x2], [y1 y1], ...
                        'Color','k', 'LineWidth',0.8);
                end
                
                title(save_name,'Interpreter','none')
                saveas(gcf,pathExportAll + save_name + "_BTfitting_dimlessTotal",'png')
                savefig(gcf,pathExportAll + save_name + "_BTfitting_dimlessTotal")

            end
        end
    end
end

%% alpha estimation with best method only 

min_points_alpha = 2;
min_points_alpha_tau = 3;

Fluid1_unique = unique(filedataExp.Fluid1);
Fluid2_unique = unique(filedataExp.Fluid2);
T_unique      = unique(filedataExp.T);
P_unique      = unique(filedataExp.P);

alpha_results = struct();
count_row = 0;

% Initial guesses
p_guess_alpha     = 1;
p_guess_alpha_tau = [1,1];

for i = 1:length(Fluid1_unique)
    for j = 1:length(Fluid2_unique)
        for k = 1:length(T_unique)
            for m = 1:length(P_unique)
            
                KL = [];
                dKL = [];
                Pe_D0 = [];
                D0_group = [];
                dD0_group = [];
                Dp_group = [];
            
                for l = 1:length(filedataExp.Key)
            
                    if filedataExp.Fluid1(l) == Fluid1_unique(i) && ...
                       filedataExp.Fluid2(l) == Fluid2_unique(j) && ...
                       filedataExp.T(l) == T_unique(k) && ...
                       filedataExp.P(l) == P_unique(m)
            
                        key = filedataExp.Key(l);
                        res = expProcData.(key).results;
            
                        if isfinite(res.KL_SI)
            
                            KL = [KL; res.KL_SI];
                            dKL = [dKL; res.dKL_SI];
                            Pe_D0 = [Pe_D0; res.Pe_D0];
            
                            D0_group = [D0_group; res.D0_SI];
                            dD0_group = [dD0_group; res.dD0_SI];
                            Dp_group = [Dp_group; res.L_SI];
            
                        end
                    end
                end
            
                n_points = length(KL);
            
                % D0 unique if fluid , fluid 2, T and P are unique
                D0_val = unique(D0_group);
                Dp_val = unique(Dp_group);
            
                % store goup info
                count_row = count_row + 1;
            
                alpha_results(count_row).Fluid1 = Fluid1_unique(i);
                alpha_results(count_row).Fluid2 = Fluid2_unique(j);
                alpha_results(count_row).T = T_unique(k);
                alpha_results(count_row).P = P_unique(m);
                alpha_results(count_row).n_points = n_points;
            
                % Initialize outputs
                % alpha only fitting
                alpha_results(count_row).alpha_SI   = NaN;
                alpha_results(count_row).d_alpha_SI = NaN;
                alpha_results(count_row).alpha_cm   = NaN;
                alpha_results(count_row).d_alpha_cm = NaN;
            
                % alpha + tau fitting
                alpha_results(count_row).alpha_tau_SI   = NaN;
                alpha_results(count_row).d_alpha_tau_SI = NaN;
                alpha_results(count_row).alpha_tau_cm   = NaN;
                alpha_results(count_row).d_alpha_tau_cm = NaN;
                alpha_results(count_row).tau   = NaN;
                alpha_results(count_row).d_tau = NaN;
            
                % alpha only fitting
                if n_points >= min_points_alpha && range(Pe_D0) > 1e-4 && std(KL) > 1e-12
            
                    try
                        out_alpha = fit_dispersion_params_alpha( ...
                            KL, Pe_D0, D0_val, Dp_val, p_guess_alpha, dKL);
            
                        alpha_results(count_row).alpha_SI   = out_alpha.alpha_SI;
                        alpha_results(count_row).d_alpha_SI = out_alpha.d_alpha_SI;
                        alpha_results(count_row).alpha_cm   = out_alpha.alpha_cm;
                        alpha_results(count_row).d_alpha_cm = out_alpha.d_alpha_cm;
            
                    catch
                        % leave NaNs
                    end
            
                end
            
                % alpha + tau if possible
                if n_points >= min_points_alpha_tau && range(Pe_D0) > 1e-3 && std(KL) > 1e-12
            
                    try
                        out_tau = fit_dispersion_params_alpha_tau( ...
                            KL, Pe_D0, D0_val, Dp_val, p_guess_alpha_tau, dKL);
            
                        if isfinite(out_tau.tau) && ...
                           out_tau.tau > 0 && ...
                           out_tau.tau < 10 && ...
                           abs(out_tau.d_tau / out_tau.tau) < 1

                            alpha_results(count_row).alpha_tau_SI   = out_tau.alpha_SI;
                            alpha_results(count_row).d_alpha_tau_SI = out_tau.d_alpha_SI;
                            alpha_results(count_row).alpha_tau_cm   = out_tau.alpha_cm;
                            alpha_results(count_row).d_alpha_tau_cm = out_tau.d_alpha_cm;
            
                            alpha_results(count_row).tau   = out_tau.tau;
                            alpha_results(count_row).d_tau = out_tau.d_tau;
            
                        end
            
                    catch
                        % leave NaN
                    end
            
                end
            
            end
        end
    end
end

% convert to table

alpha_table = struct2table(alpha_results);

disp(alpha_table)

%% Save results

alpha_table_name = pathExportAll + "alpha_results";

% delete previous
if exist(alpha_table_name + ".xlsx","file")
    delete(alpha_table_name + ".xlsx")
end
if exist(alpha_table_name + ".mat","file")
    delete(alpha_table_name + ".mat")
end

% save alpha table
writetable(alpha_table, alpha_table_name + ".xlsx")
save(alpha_table_name + ".mat",'alpha_table')

% save processed data
expProcFullData = expProcData;
save(pathExportAll + "expProcFullData.mat",'expProcFullData')

fitting_results_name = pathExportAll + "fitting_results.xlsx";

% delete previous file
if exist(fitting_results_name,"file")
    delete(fitting_results_name)
end

% Sheet 1: Best results
vars_to_remove = {'C_fit'};
T = best_method_table; 
T(:, vars_to_remove) = [];
writetable(T, fitting_results_name, ...
    'Sheet','best_method')

% Sheet 2+: each method
method_names = fieldnames(method_results);

for j = 1:length(method_names)

    T = method_results.(method_names{j});

    % remove Cfit col
    T(:, vars_to_remove) = [];

    % limit sheet name
    sheet_name = method_names{j};
    if strlength(sheet_name) > 31
        sheet_name = extractBefore(sheet_name,32);
    end

    writetable(T, fitting_results_name, 'Sheet', sheet_name)

end

%% Plot Kl_vs_vel

Fluid1_unique = unique(best_method_table.Fluid1);
Fluid2_unique = unique(best_method_table.Fluid2);
T_unique      = unique(best_method_table.T_C);
P_unique      = unique(best_method_table.P_psig);

colors = orderedcolors("glow");

for i = 1:length(Fluid1_unique)
    for j = 1:length(Fluid2_unique)
        for k = 1:length(T_unique)
            for m = 1:length(P_unique)
            
                % filter rows for this group
                idx = best_method_table.Fluid1 == Fluid1_unique(i) & ...
                      best_method_table.Fluid2 == Fluid2_unique(j) & ...
                      best_method_table.T_C == T_unique(k) & ...
                      best_method_table.P_psig == P_unique(m);
            
                % extract data
                u_array_cmmin = best_method_table.u_cmmin(idx);
                KL_array      = best_method_table.KL_cm2min(idx);
                dKL_array     = best_method_table.dKL_cm2min(idx);
                Pe_D0_array   = best_method_table.Pe_D0(idx);
            
                D0 = unique(best_method_table.D0_SI(idx));
                Dp_SI = unique(best_method_table.L_SI(idx));
            
                % get alpha for this group
                idx_alpha = alpha_table.Fluid1 == Fluid1_unique(i) & ...
                            alpha_table.Fluid2 == Fluid2_unique(j) & ...
                            alpha_table.T      == T_unique(k) & ...
                            alpha_table.P      == P_unique(m);
            
                alpha_SI = alpha_table.alpha_SI(idx_alpha);
                dalpha_SI = alpha_table.d_alpha_SI(idx_alpha);
            
                alpha_cm = alpha_SI * 100;
                dalpha_cm = dalpha_SI * 100;
            
                % % model (KL = alpha * u)
                % u_model = linspace(0, max(u_array_cmmin)/(60*100), 100);
                % KL_model = alpha_SI * u_model;
                % 
                % u_model_cm = u_model * (60*100);
                % KL_model_cm = KL_model * (60*10^4);

                % model based on Pe numbers (Pe with D0 denominator)
                Pe_D0_array_plot = 0:1:ceil(max(Pe_D0_array));
                % KL_Pe_alpha_only_model(Pe_fromD0,D0,p) % alpha = p * Dp; % Alpha (dispersivity) Dp is L
                KL_array_SI_plot = KL_Pe_alpha_only_model(Pe_D0_array_plot,D0,alpha_SI/Dp_SI);
                KL_array_cm2min_plot = KL_array_SI_plot*(60*10^4);
                u_array_cmmin_plot = (Pe_D0_array_plot*D0/Dp_SI)*(60*10^2);
            
                % plot
                figure
                hold on
            
                % model line
                % plot(u_model_cm, KL_model_cm, ...
                %     'k','LineWidth',2,...
                %     'DisplayName','K_L = \alpha u_x')
                plot(u_array_cmmin_plot, KL_array_cm2min_plot, ...
                    'k','LineWidth',2,...
                    'DisplayName','K_L = \alpha u_x')
            
                % data
                for ii = 1:length(u_array_cmmin)
            
                    errorbar(u_array_cmmin(ii), KL_array(ii), ...
                        dKL_array(ii), dKL_array(ii), ...
                        'Color','k','HandleVisibility','off')
            
                    scatter(u_array_cmmin(ii), KL_array(ii), ...
                        'filled', ...
                        'Color',colors(ii,:), ...
                        'DisplayName',"Q = " + best_method_table.Q_mlmin(ii) + " ml/min")
            
                end
            
                xlabel('Interstitial velocity (u_x) [cm/min]')
                ylabel('K_L [cm^2/min]')
            
                xlim([0,1.1*max(u_array_cmmin)])
                ylim([0,1.1*max(KL_array)])
            
                grid on
            
                save_name = "CF_"+filedataExp.Fluid1(i)+"_"+filedataExp.Fluid2(j)+"_T"+filedataExp.T(k)+"_P"+filedataExp.P(m);
            
                title(save_name, 'Interpreter','none')
            
                annotation('textbox',[0.25 0.2 0.5 0.05],...
                    'String',sprintf('\\alpha = %.2f ± %.2f cm', alpha_cm, dalpha_cm),...
                    'EdgeColor','none')
            
                legend('Location','northwest')
            
                % save figure
                saveas(gcf, pathExportAll + "KLvsVel_" + save_name, 'png')
                savefig(gcf, pathExportAll + "KLvsVel_" + save_name)
            
            end
        end
    end
end

%% Plot Kl/Dl vs Pe

Fluid1_unique = unique(best_method_table.Fluid1);
Fluid2_unique = unique(best_method_table.Fluid2);
T_unique      = unique(best_method_table.T_C);
P_unique      = unique(best_method_table.P_psig);

colors = orderedcolors("glow");

for i = 1:length(Fluid1_unique)
    for j = 1:length(Fluid2_unique)
        for k = 1:length(T_unique)
            for m = 1:length(P_unique)
            
                % filter rows for this group
                idx = best_method_table.Fluid1 == Fluid1_unique(i) & ...
                      best_method_table.Fluid2 == Fluid2_unique(j) & ...
                      best_method_table.T_C == T_unique(k) & ...
                      best_method_table.P_psig == P_unique(m);
            
                % extract data
                u_array_cmmin = best_method_table.u_cmmin(idx);
                u_array_SI = best_method_table.u_SI(idx);
                KL_array      = best_method_table.KL_cm2min(idx);
                dKL_array     = best_method_table.dKL_cm2min(idx);
                Pe_D0_array   = best_method_table.Pe_D0(idx);
            
                D0 = unique(best_method_table.D0_SI(idx));
                dD0 = unique(best_method_table.dD0_SI(idx));
                Dp_SI = unique(best_method_table.L_SI(idx));

                KL_vs_D0_array = best_method_table.KL_SI(idx)/D0;
                dKL_vs_D0_array = best_method_table.dKL_SI(idx)/D0+best_method_table.KL_SI(idx)*dD0/(D0^2);
            
                % get alpha for this group
                idx_alpha = alpha_table.Fluid1 == Fluid1_unique(i) & ...
                            alpha_table.Fluid2 == Fluid2_unique(j) & ...
                            alpha_table.T      == T_unique(k) & ...
                            alpha_table.P      == P_unique(m);
            
                alpha_SI = alpha_table.alpha_SI(idx_alpha);
                dalpha_SI = alpha_table.d_alpha_SI(idx_alpha);
            
                alpha_cm = alpha_SI * 100;
                dalpha_cm = dalpha_SI * 100;

                Pe_D0_alpha = u_array_SI*alpha_SI/D0;
            
                % model based on Pe numbers (Pe with D0 denominator)
                Pe_D0_array_plot = 0.1:0.1:6;
                % KL_Pe_alpha_only_model(Pe_fromD0,D0,p) % alpha = p * Dp; % Alpha (dispersivity) Dp is L
                KL_array_SI_plot = KL_Pe_alpha_only_model(Pe_D0_array_plot,D0,1);
                KL_array_cm2min_plot = KL_array_SI_plot*(60*10^4);
                u_array_cmmin_plot = (Pe_D0_array_plot*D0/Dp_SI)*(60*10^2);
            
                % plot
                figure
                hold on
            
                plot(Pe_D0_array_plot, KL_array_SI_plot/D0, ...
                    'k','LineWidth',2,...
                    'DisplayName','K_L/D_0 \approx \alpha_Lu_x/D_0')
            
                % data
                for ii = 1:length(Pe_D0_alpha)
            
                    errorbar(Pe_D0_alpha(ii), KL_vs_D0_array(ii), ...
                        dKL_vs_D0_array(ii), dKL_vs_D0_array(ii), ...
                        'Color','k','HandleVisibility','off')
            
                    scatter(Pe_D0_alpha(ii), KL_vs_D0_array(ii), ...
                        'filled', ...
                        'Color',colors(ii,:), ...
                        'DisplayName',"Q = " + best_method_table.Q_mlmin(ii) + " ml/min")            
                end
            
                xlabel('Pe = u_x\alpha/D_0')
                ylabel('K_L/D_0');
             
                xlim([0,10])
                ylim([0,10])
                
                set(gca, 'XScale','log','YScale','log')
                grid on
            
                save_name = "CF_"+filedataExp.Fluid1(i)+"_"+filedataExp.Fluid2(j)+"_T"+filedataExp.T(k)+"_P"+filedataExp.P(m);
            
                title(save_name, 'Interpreter','none')
            
                annotation('textbox',[0.25 0.2 0.5 0.05],...
                    'String',sprintf('\\alpha = %.2f ± %.2f cm', alpha_cm, dalpha_cm),...
                    'EdgeColor','none')
            
                legend('Location','northwest')
            
                % save figure
                saveas(gcf, pathExportAll + "KLD0vsPe_all_" + save_name, 'png')
                savefig(gcf, pathExportAll + "KLD0vsPe_all_" + save_name)
            
            end
        end
    end
end
