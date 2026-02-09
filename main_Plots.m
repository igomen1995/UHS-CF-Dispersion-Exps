% main_Plots.m
% version: v02_Feb2026
% Author: Ianna Gomez Mendez
%
% Objective: Plot BT curves together
% having same or different fluids, temperatures and pressure
% 
% Input (use Import Data tool in Matlab):
% 1 - filedataExp
% 2 - expProcData.dat all
% 
% Procedure:
% 1 - Load input
% 2 - Plot according to goal
% 
% Output: 
% Figures
%
%% IMPORT

addpath('functions/');

% Introduce name of input and desired output folder name

filenameExp = 'input/input_exp_H2-CO2-T32-P1500.xlsx';
mkdir('results/exp_H2-CO2-T32-P1500-H');
pathImportAll = 'results/exp_H2-CO2-T32-P1500-H/';

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

%% Figure all

% Plot same fluid 1, same conditions

Fluid1_unique = unique(filedataExp.Fluid1);
Fluid2_unique = unique(filedataExp.Fluid2);
T_unique = unique(filedataExp.T);
P_unique = unique(filedataExp.P);
Q_unique = unique(filedataExp.Q);

% same Fluid 1, T and P, all Qs
for i = 1:length(Fluid1_unique)
    for j = 1:length(T_unique)
        for k = 1:length(P_unique)
            figure;
            for l = 1:length(filedataExp.Key)
                if filedataExp.Fluid1(l) == Fluid1_unique(i)
                    if filedataExp.T(l) == T_unique(j)
                        if filedataExp.P(l) == P_unique(k)
                            for m = 1:length(Q_unique)
                                if filedataExp.Q(l) == Q_unique(m)
                                    scatter(expProcData.(filedataExp.Key(l)).BT.TimeElapsed,expProcData.(filedataExp.Key(l)).BT.Ci_corr_mean,10,'filled',"DisplayName"," q = " +filedataExp.Q(l)+" ml/min")
                                    xlabel('Time elapsed [hh:mm:ss]');
                                    xtickformat('hh:mm:ss')
                                    ylabel('C_{1}[mol %]');
                                    ylim([0,100]);
                                    title(filedataExp.Key(l) + " concentrations", 'Interpreter', 'none')
                                    grid on;
                                    legend('Location','southeast');
                                end
                                hold on;
                            end
                            hold off
                            saveas(gcf,pathImportAll + "CF_" + Fluid1_unique(i) + "_T" + T_unique(j) + "_P" + P_unique(k) +"_Qall",'png')
                            savefig(gcf,pathImportAll + "CF_" + Fluid1_unique(i) + "_T" + T_unique(j) + "_P" + P_unique(k) +"_Qall")
                        end
                    end
                end
            end
        end
    end
end

%%

% different Fluid 1, same T and P and Q
figure
c = parula(length(filedataExp.Key));
for i = 1:length(filedataExp.Key)
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.Ci_corr_mean,10,c(i,:),'filled',"DisplayName",filedataExp.Key(i))
    xlabel('Time elapsed [hh:mm:ss]');
    xtickformat('hh:mm:ss')
    ylabel('C_{1}[mol %]');
    ylim([0,100]);
    title(filedataExp.Key(l) + " concentrations", 'Interpreter', 'none')
    grid on;
    legend('Location','southeast', 'Interpreter','none');
    hold on
end
saveas(gcf,pathImportAll + "all_fluids_T_P_Q",'png')
savefig(gcf,pathImportAll + "all_fluids_T_P_Q")
