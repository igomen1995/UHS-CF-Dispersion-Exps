function [PR_input,PR_results] = densZ_PR(fl,x1,P_MPa,T_C)

addpath('functions/');

% ------------------------------------------------------------------------

% INTRODUCE THE INPUT HERE
% file containing pure components NIST data: Tc, Pc and acentric factor w
filenamePure = 'input_PR_pure.xlsx';
% file containing mixture compoents A12 B12 factor to estimate BIP
filenameBIP = 'input_PR_BIP.xlsx';

% % Variables of interest for this mixture
% fl = {"H2", "CO2"}; % fluids in the mixture
% x1 = 0:0.001:1; %string molar fraction component 1
% P_MPa = 10.4; % MPa
% T_C = 32; % C

% ------------------------------------------------------------------------

% import pure components NIST data: Tc, Pc and acentric factor w
filedataPure = import_inputPR_params_pure(filenamePure);
% import mixture components A12 and B12 factor to estimate BIP (kij)
filedataBIP = import_inputPR_params_BIP(filenameBIP);

P = P_MPa*(10^6); % Pa
T = T_C +273.15; %K
Pc = zeros(length(fl),1);
Tc = zeros(length(fl),1);
w = zeros(length(fl),1);
M = zeros(length(fl),1);
for i = 1:length(fl)
    Pc(i) = filedataPure.Pc(filedataPure.Fluid == fl{i})*(10^6); % NIST is in MPa, converted to Pa
    Tc(i) = filedataPure.Tc(filedataPure.Fluid == fl{i});
    w(i) = filedataPure.AcentricFactor(filedataPure.Fluid == fl{i});
    M(i) = filedataPure.M(filedataPure.Fluid == fl{i});
end

if length(fl) > 1
    % binary mixture BIP fitting params
    A12 = filedataBIP.A12(filedataBIP.Fluid1 == fl{1} & filedataBIP.Fluid2  == fl{2});
    B12 = filedataBIP.B12(filedataBIP.Fluid1 == fl{1} & filedataBIP.Fluid2  == fl{2});
end

% Pure components
% calculate ai, bi to estimate BIP
[ai,bi] = calc_ai_bi(T, Pc, Tc, w);

if length(fl) > 1
    %Mixture
    % calculate BIP based on fitting parameters and T
    % converting ai and bi to Mpa multiplying by 10^6
    
    kij = calc_BIP(T, A12, B12, ai, bi);
    
    kijmatrix = zeros(length(fl));
    kijmatrix(1,2) = kij;
    kijmatrix(2,1) = kij;

    aij = {};
    amix = [];
    bmix = [];
    Zall = {};
    Z = [];
    rho = [];

    for i = 1:length(x1)
        [aij{i}, amix(i), bmix(i)] = calc_abmix(x1(i), ai, bi, kijmatrix);
        [Zall{i},Z(i),rho(i)] = calc_Z(P, T, amix(i), bmix(i),x1(i),M);
    end
    PR_input = table(fl(1),fl(2), P_MPa, T_C,'VariableNames',{'fluid1', 'fluid2' 'P_MPa', 'T_C'});
else
    [Zall,Z,rho] = calc_Z(P, T, ai, bi, x1, M);
    PR_input = table(fl(1),NaN, P_MPa, T_C,'VariableNames',{'fluid1', 'fluid2' 'P_MPa', 'T_C'});
end

PR_results = table(x1',Z',rho','VariableNames',{'x1','Z','rho'});



