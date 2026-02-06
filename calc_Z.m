%% Z-factor calculation for Peng-Robinson EOS
% For PR-EOS, z-factor is calculated as the real roots of
% Z^3 - (1-B)Z^2 + (A-3B^2-2B)Z - (AB-B^2-B^3) = 0
% R = 8.314Jmol-1K-1
% x1 molar fraction comp 1 scalar
% M molar mass - 2 x 1 (kg/mol)

function [Zall, Zvap, rhomix] = calc_Z(P, T, amix, bmix, x1, M)

R = 8.314; %Jmol-1K-1
xi = [x1;(1-x1)];

% Calculate A and B
A = amix*P/((R^2)*(T^2));
B = bmix*P/(R*T);

% Calculate the coefficients of cubic equation.
m3 = 1;
m2 = -(1-B);
m1 = A-3*(B^2)-2*B ;
m0 = -(A*B-(B^2)-(B^3));

% Solve the cubic equation.
Zroots = roots([m3 m2 m1 m0]);

% Choose the real roots.
Z = [];
for i = 1:3
    if imag( Zroots(i) ) == 0
        Zreal = real(Zroots(i));
        Z = cat(1, Z, Zreal);
    end
end

Zall = sort(Z);
Zvap = max(Z);

% calculate rho mixture
Mmix = xi'*M;
rhomix = P*Mmix/(Zvap*R*T);

end
