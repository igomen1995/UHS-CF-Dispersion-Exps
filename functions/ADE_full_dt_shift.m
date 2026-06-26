function C = ADE_full_dt_shift(p,t,u,Cj,Ci,L)

    % Model functions
    % Cj, Ci, u not fitting, fitting p where Kl = p(1)^2 and dt = p(2)
    % Corrects BT curve due to extra volume before core

    % C_function = @(p,tvals)(Ci + (Cj/2)*erfc((L-u.*(tvals-p(2)))./(2*(max((tvals-p(2)),eps).^(1/2)).*p(1)))); % dt numerator and denominator

    % enforce safe parameters
    dt = p(2);
    denom = 2.*(max(t - dt,eps).^(1/2)).* p(1);

    % Arg two erfc terms
    arg1 = (L - u.*(t - dt)) ./ denom;
    arg2 = (L + u.*(t - dt)) ./ denom;

    % exp term
    % KL = p1^2 → u*L/KL = u*L/p1^2
    exp_term = exp(u*L/(p(1)^2)); 

    % full ADE function
    C = Ci + (Cj/2) .* (erfc(arg1) + exp_term .* erfc(arg2));
end
