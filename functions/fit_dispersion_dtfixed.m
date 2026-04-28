function [KL,dt_fit, u_fit, Cj_fit, Ci_fit, C_fit] = fit_dispersion_dtfixed(C,t,u,Cj,Ci,L,dt,p)
%fit_dispersion solves KL (SI) given concentration and time array, interstitial velocity, 
% boundary conditions in x = 0 (Cj), initial concentration, length of the
% core, initial guess parameters
% p includes intital guess for Kl = p(1)^2 and a fixed dt = p(2);
        
% Cj, Ci, u not fitting, fitting p where Kl = p(1)^2
% Corrects BT curve due to extra volume before core

C_function = @(p,t)(Ci + (Cj/2)*erfc((L-u.*(t-dt))./(2*(max((t-dt),eps).^(1/2)).*p(1)))); % dt numerator and denominator
% C_function = @(p,t)(Ci + (Cj/2)*erfc((L-u.*(t-dt))./(2*(t.^(1/2)).*p(1)))); % dt only numerator

% full function
% C_function = @(p,t) Ci + (Cj/2) .* (erfc( (L - u.*(t - p(2))) ./ (2 * p(1) .* sqrt(max(t - p(2), eps))) ) + ...
%     exp( u*L / (p(1)^2) ) .*erfc( (L + u.*(t - p(2))) ./ (2 * p(1) .* sqrt(max(t - p(2), eps))) ));

C_fit = fitnlm(t,C,C_function,p);
p(1) = C_fit.Coefficients.Estimate(1);

KL = p(1)^2;
dt_fit = dt;
u_fit = u;
Cj_fit = Cj;
Ci_fit = Ci;
        
end