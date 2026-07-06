function C = ADE_short_dt_shift(p,t,u,Cj,Ci,L)

    % Model functions
    % Cj, Ci, u not fitting, fitting p where Kl = p(1)^2 and dt = p(2)
    % Corrects BT curve due to extra volume before core

    % C = @(p,tvals)(Ci + (Cj/2)*erfc((L-u.*(tvals-p(2)))./(2*(max((tvals-p(2)),eps).^(1/2)).*p(1)))); % dt numerator and denominator

    % enforce safe parameters
    dt = p(2);
    denom = 2.*(max(t - dt,eps).^(1/2)).* p(1);
    arg = (L-u.*(t - dt))./ denom;

    % short ADE function
    C = Ci + (Cj/2) * erfc(arg);
end
