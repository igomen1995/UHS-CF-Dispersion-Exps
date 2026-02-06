%% Calculate a and b for mixtures by using the classical mixing rule.

% x1 molar fraction component 1 in a binary mixture
% ai atraction parameter pure component - 2x1
% bi covolume pure component - 2x1
% kij binary interaction parameter binary mixture - matrix 2 x 2

function [aij, amix, bmix] = calc_abmix(x1, ai, bi, kij)

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