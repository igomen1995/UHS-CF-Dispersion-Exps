function Cout = three_segment_model(t, Dcore, ...
                                    Q, Aup, Acore, phi, Adown, ...
                                    Lup, Lc, Ldown, ...
                                    Dup, Ddown, C0)

    dt = t(2) - t(1);

    % Velocities
    v_up   = Q / Aup;
    v_core = Q / (Acore * phi);
    v_down = Q / Adown;

    % --- 1) Upstream system step response ---
    Cup = ob_step(t, Lup, v_up, Dup, C0);

    % --- 2) Core impulse response ---
    Gcore = impulse_from_step(t, Lc, v_core, Dcore);

    % Convolution: upstream → core
    Ccore_in = conv(Cup, Gcore) * dt;
    Ccore_in = Ccore_in(1:numel(t));

    % --- 3) Downstream impulse response ---
    Gdown = impulse_from_step(t, Ldown, v_down, Ddown);

    % Convolution: core outlet → downstream
    Cfull = conv(Ccore_in, Gdown) * dt;
    Cout = Cfull(1:numel(t));
end

