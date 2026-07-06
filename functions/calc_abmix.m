function [aij, amix, bmix] = calc_abmix(x1, ai, bi, kij)
%CALC_ABMIX Calculate mixture EOS parameters using classical mixing rules.
%
%   [AIJ, AMIX, BMIX] = CALC_ABMIX(X1, AI, BI, KIJ) computes the binary
%   interaction matrix (AIJ) and the mixture attraction and covolume
%   parameters (AMIX and BMIX) using the classical quadratic mixing rules
%   commonly employed in cubic equations of state (e.g., Peng-Robinson and
%   Soave-Redlich-Kwong).
%
%   INPUTS
%       x1   : Mole fraction of component 1 in a binary mixture.
%
%       ai   : Vector of pure-component attraction parameters:
%              AI = [a1; a2]
%
%       bi   : Vector of pure-component covolume parameters:
%              BI = [b1; b2]
%
%       kij  : Binary interaction parameter matrix:
%
%                  [k11  k12
%                   k21  k22]
%
%              Typically k11 = k22 = 0 and k12 = k21.
%
%   OUTPUTS
%       aij  : Matrix of cross-interaction attraction parameters:
%
%                  aij(i,j) = sqrt(ai(i)*ai(j))*(1-kij(i,j))
%
%       amix : Mixture attraction parameter calculated using the quadratic
%              mixing rule:
%
%                  amix = x'*aij*x
%
%       bmix : Mixture covolume parameter calculated using the linear
%              mixing rule:
%
%                  bmix = x'*bi
%
%   MODEL DESCRIPTION
%       For a binary mixture with mole fractions:
%
%           x = [x1; 1-x1]
%
%       the cross-interaction parameters are computed as:
%
%           aij = sqrt(ai*aj) * (1-kij)
%
%       and subsequently used to calculate the mixture attraction
%       parameter AMIX and covolume parameter BMIX.
%
%   NOTES
%       - Assumes a binary mixture.
%       - Implements the classical van der Waals one-fluid mixing rules.
%       - Intended for use with cubic equations of state such as
%         Peng-Robinson (PR) and Soave-Redlich-Kwong (SRK).
%       - Returns both the full interaction matrix and the resulting
%         mixture parameters.
%
%   EXAMPLE
%       x1 = 0.30;
%       ai = [0.45; 0.28];
%       bi = [3.0e-5; 2.5e-5];
%       kij = [0 0.10; 0.10 0];
%
%       [aij,amix,bmix] = calc_abmix(x1,ai,bi,kij);


xi = [x1;(1-x1)];

Nc = size(ai,1);
% Calculate aij 
aij = zeros(Nc, Nc);
for i = 1:Nc
    for j = 1:Nc
        aij(i,j) = sqrt(ai(i)*ai(j))*(1 - kij(i,j));
    end
end

% amix and bmix are scalars.
amix = xi'*aij*xi;
bmix = xi'*bi;

end