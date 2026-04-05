function G = impulse_from_step(t, L, v, D)
    % Impulse response = derivative of step response
    Cstep = ob_step(t, L, v, D, 1);   % unit step
    dt = t(2) - t(1);

    G = [Cstep(1); diff(Cstep)] / dt;
    G(G < 0) = 0;   % clean numerical noise
end

