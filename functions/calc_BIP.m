function kij = calc_BIP(temp, A12, B12, ai, bi)


%CALC_BIP Calculate binary interaction parameter (kij).
%
%   KIJ = CALC_BIP(TEMP,A12,B12,AI,BI) computes the binary interaction
%   parameter (BIP), kij, using the temperature-dependent correlation
%   proposed by Jaubert and Mutelet (2004) for cubic equations of state.
%
%   INPUTS
%       temp : System temperature [K]
%
%       A12  : Jaubert-Mutelet binary interaction parameter A12 [-]
%
%       B12  : Jaubert-Mutelet binary interaction parameter B12 [-]
%
%       ai   : Pure-component attraction parameters obtained from the
%              equation of state:
%
%                  ai = [a1; a2]
%
%       bi   : Pure-component covolume parameters:
%
%                  bi = [b1; b2]
%
%   OUTPUT
%       kij  : Binary interaction parameter [-]
%
%   MODEL DESCRIPTION
%       The Jaubert-Mutelet correlation defines:
%
%           delta_i = sqrt(ai)/bi
%
%       and computes the binary interaction parameter as:
%
%           kij =
%
%           [ A12*(298.15/T)^((B12/A12)-1)
%             - (delta1-delta2)^2 ]
%
%           ---------------------------------
%                  2*delta1*delta2
%
%       where delta1 and delta2 correspond to the two mixture components.
%
%   NOTES
%       - The correlation assumes a binary mixture.
%       - A12 and B12 are fitted interaction parameters obtained from
%         experimental phase-equilibrium data.
%       - ai and bi are internally scaled to MPa-based units because the
%         published Jaubert-Mutelet parameters were derived using MPa.
%       - The resulting kij can be used together with classical mixing
%         rules when calculating mixture EOS parameters.
%
%   EXAMPLE
%       [ai,bi] = calc_ai_bi(T,Pc,Tc,omega);
%
%       kij = calc_BIP(T,...
%                      A12,...
%                      B12,...
%                      ai,...
%                      bi);
%
%   See also CALC_AI_BI, CALC_ABMIX.

delta = sqrt(ai*(10^6))./(bi*(10^6));
kij = (A12*((298.15/temp)^((B12/A12)-1))-(delta(1)-delta(2))^2)/(2*delta(1)*delta(2));

end
