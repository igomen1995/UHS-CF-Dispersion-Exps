%% Calculate BIP based on fitting params
% The Definition of Variables.
% temp    : temperature K
% A12: fitting param BIP based on Jaubert and mutulet 2004
% B12: fitting param BIP based on Jaubert and mutulet 2004
% ai:attraction oarameter pure comp
% bi: covolume pure comp 
% Result is a kij matrix - BIP

function [D12, dD12] = calc_diff_marrero(T_C,P_psig, A, B, C, D, E, group, dev_pc)

% Marrero model works with T in K and P in atm and gives results of D in cm2/s
% group can be 1, 2, 4, 4

T = T_C + 273.15; % K
P = (P_psig + 14.7)/14.6959; % atm

if group == 1 % H2 N2
    D12 = (exp(log(A*(10^-5)) + B*log(T) - log((log(C*(10^8)/T))^2) - D/T - E/(T^2)))/P;
else
    D12 = (exp(log(A*(10^-5)) + B*log(T) - D/T))/P;
end

D12 = D12*60; % cm2min

dD12 = dev_pc*D12/100; % cm2min

end
