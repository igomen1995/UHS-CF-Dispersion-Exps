%% Calculate BIP based on fitting params
% The Definition of Variables.
% temp    : temperature K
% A12: fitting param BIP based on Jaubert and mutulet 2004
% B12: fitting param BIP based on Jaubert and mutulet 2004
% ai:attraction oarameter pure comp
% bi: covolume pure comp 
% Result is a kij matrix - BIP

function kij = calc_BIP(temp, A12, B12, ai, bi)

% multiply ai and bi by 10^6 to have it in MPa, A12 and B12 params are
% based on MPa ai and bi

delta = sqrt(ai*(10^6))./(bi*(10^6));
kij = (A12*((298.15/temp)^((B12/A12)-1))-(delta(1)-delta(2))^2)/(2*delta(1)*delta(2));

end
