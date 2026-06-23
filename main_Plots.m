% main_Plots.m
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

inputFileConfigName = 'inputExpConfig.xlsx';

inputFileConfig = readtable(inputFileConfigName);

filenameExp = inputFileConfig.inputFileName{:};

pathImportAll = inputFileConfig.exportPath{:}; % Path for OUTPUT
mkdir(pathImportAll); % Create directory for output

%% IMPORT variables

filedataExp = import_inputExp(filenameExp); % import input to a local variable

load(pathImportAll+"expProcData.mat")

%% Figure all

% Plot same fluid 1, same conditions

Fluid1_unique = unique(filedataExp.Fluid1);
Fluid2_unique = unique(filedataExp.Fluid2);
T_unique = unique(filedataExp.T);
P_unique = unique(filedataExp.P);
Q_unique = unique(filedataExp.Q);

colors = orderedcolors("glow");

% same Fluid 1, T and P, all Qs
for i = 1:length(Fluid1_unique)
    for ii = 1:length(Fluid2_unique)
        for j = 1:length(T_unique)
            for k = 1:length(P_unique)
                figure;
                for l = 1:length(filedataExp.Key)
                    if filedataExp.Fluid1(l) == Fluid1_unique(i)
                        if filedataExp.Fluid2(l) == Fluid2_unique(ii)
                            if filedataExp.T(l) == T_unique(j)
                                if filedataExp.P(l) == P_unique(k)
                                    for m = 1:length(Q_unique)
                                        if filedataExp.Q(l) == Q_unique(m)
                                            t = expProcData.(filedataExp.Key(l)).BT.TimeElapsed;
                                            C1 = expProcData.(filedataExp.Key(l)).BT.Ci;
                                            C1min = expProcData.(filedataExp.Key(l)).BT.CiMin;
                                            C1max = expProcData.(filedataExp.Key(l)).BT.CiMax;
                                            errorbar(t, C1, C1-C1min, C1max - C1, 'LineStyle', 'none', 'Color', [0.8 0.8 0.8],'HandleVisibility','Off')
                                            hold on 
                                            scatter(t,C1,5,'filled','MarkerFaceColor',colors(m,:),'DisplayName',"Q"+filedataExp.Q(l)+": C_{MFM} \pm \DeltaC_{MFM}");
                                            % scatter(expProcData.(filedataExp.Key(l)).BT.TimeElapsed,expProcData.(filedataExp.Key(l)).BT.Ci,10,'filled',"DisplayName"," q = " +filedataExp.Q(l)+" ml/min")
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
                                    saveas(gcf,pathImportAll + "CF_" + Fluid1_unique(i) + Fluid2_unique(ii) + "_T" + T_unique(j) + "_P" + P_unique(k) +"_Qall",'png')
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

%% Figure all dimensionless

% Plot same fluid 1, same conditions

Fluid1_unique = unique(filedataExp.Fluid1);
Fluid2_unique = unique(filedataExp.Fluid2);
T_unique = unique(filedataExp.T);
P_unique = unique(filedataExp.P);
Q_unique = unique(filedataExp.Q);

colors = orderedcolors("glow");

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
                                    tD = expProcData.(filedataExp.Key(l)).BT.tD;
                                    CD = expProcData.(filedataExp.Key(l)).BT.CDi;
                                    CDmin = expProcData.(filedataExp.Key(l)).BT.CDiMin;
                                    CDmax = expProcData.(filedataExp.Key(l)).BT.CDiMax;
                                    errorbar(tD, CD, CD-CDmin, CDmax - CD, 'LineStyle', 'none', 'Color', [0.8 0.8 0.8],'HandleVisibility','Off')
                                    hold on 
                                    scatter(tD,CD,5,'filled','MarkerFaceColor',colors(m,:),'DisplayName',"Q"+filedataExp.Q(l)+": C_{MFM} \pm \DeltaC_{MFM}");
                                    % scatter(expProcData.(filedataExp.Key(l)).BT.TimeElapsed,expProcData.(filedataExp.Key(l)).BT.Ci,10,'filled',"DisplayName"," q = " +filedataExp.Q(l)+" ml/min")
                                    xlabel('Dimensionless Time [-]');
                                    xlim([0,2]);
                                    ylabel('C_{D}[-]');
                                    ylim([0,1]);
                                    title(filedataExp.Key(l) + " concentrations - dimensionless", 'Interpreter', 'none')
                                    grid on;
                                    legend('Location','southeast');
                                end
                                hold on;
                            end
                            hold off
                            saveas(gcf,pathImportAll + "CF_" + Fluid1_unique(i) + "_T" + T_unique(j) + "_P" + P_unique(k) +"_Qall_nd",'png')
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
    scatter(expProcData.(filedataExp.Key(i)).BT.TimeElapsed,expProcData.(filedataExp.Key(i)).BT.Ci,10,c(i,:),'filled',"DisplayName",filedataExp.Key(i))
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

%%

% different Fluid 1, same T and P and Q
figure
c = parula(length(filedataExp.Key));
for i = 1:length(filedataExp.Key)
    scatter(expProcData.(filedataExp.Key(i)).BT.tD,expProcData.(filedataExp.Key(i)).BT.CDi,10,c(i,:),'filled',"DisplayName",filedataExp.Key(i))
    xlabel('Dimensionless Time [-]');
    xlim([0,2]);
    ylabel('C_{D}[-]');
    ylim([0,1]);
    title(filedataExp.Key(l) + " concentrations dimensionless", 'Interpreter', 'none')
    grid on;
    legend('Location','southeast', 'Interpreter','none');
    hold on
end
saveas(gcf,pathImportAll + "all_fluids_T_P_Q_nd",'png')

