function C = ob_step(t, L, v, D, C0)
    % Ogata–Banks step solution at x = L
    C = zeros(size(t));
    idx = t > 0;
    tt  = t(idx);

    term1 = erfc((L - v*tt) ./ (2*sqrt(D*tt)));
    % term2 = exp(v*L/D) .* erfc((L + v*tt) ./ (2*sqrt(D*tt)));

    C(idx) = C0 * 0.5 .* (term1);
end
