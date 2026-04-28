function KL_lines = KL_lines_taylor_aris(v, r, Dm)
    % v velocity in SI
    % r = id/2 in SI
    % Dm diffusion coeffcient in SI
    KL_lines = Dm + (v^2 * r^2) / (48 * Dm);
end