%% CALCULATE DIMENSIONLESS ATTRACTION AND COVOLUME, ai & bi
% The Definition of Variables.
% press   : pressure Pa
% temp    : temperature K
% pressc  : critical pressure Pa
% tempc   : critical temperature K
% acentric: acentric factor
% ncomp   : the number of components
% R = 8.314Jmol-1K-1

function [ai,bi] = calc_ai_bi(temp, pressc, tempc, acentric)

omegaa = 0.45724;
omegab = 0.0778;
R = 8.314; %Jmol-1K-1

% Calculate m
m=0.37464+1.54226*acentric-0.26992*acentric.^2;

% Calculate reduced temperature
tempr = temp./tempc;

% Calculate alpha.
alpha = (1+m.*(1-sqrt(tempr))).^2;

% Calculate ai and bi
ai_tempc = omegaa*(R^2)*(tempc.^2)./(pressc);
ai = ai_tempc.*alpha;
bi = omegab*R*tempc./pressc;

end
% 

% 

% 
% 
% 
% end
