function [method_results, best_method, best_row] = fitBTC_KL_allMethods(t_vals, C1_vals, dC_vals, u, Cj, Ci, L, dt_guess, Cmin, Cmax)
% FITBTC_KL_ALLMETHODS  Fit KL to a single breakthrough curve using the
%   INPUTS
%       C      : Measured concentration data
%
%       t      : Time vector [s]
%
%       u      : Average interstitial velocity [m/s]
%
%       Cj     : Injected concentration step amplitude
%
%       Ci     : Initial/background concentration
%
%       L      : Core length or transport distance [m]

    methods = {'dt_free_wfit','dt_free_nwfit', ...
        'dt_fixed_wfit_lim','dt_fixed_nwfit_lim', ...
        'dt_fixed_wfit_full','dt_fixed_nwfit_full'};

    % full schema placeholder, matching fit_dispersion_dt_nlinfit's own
    % default struct (post your fix), so every method — run, skipped, or
    % failed — has an identical field set
    nanTemplate = struct('KL', NaN, 'dKL', NaN, 'dt', NaN, 'ddt', NaN, ...
        'KL_cm2min', NaN, 'dKL_cm2min', NaN, 'dt_min', NaN, 'ddt_min', NaN, ...
        'C_fit', NaN(size(C1_vals)), 'C_pred', NaN(size(C1_vals)), 'dC_pred', NaN(size(C1_vals)), ...
        'RMSE', NaN, 'R2', NaN, ...
        'Cfun', [], 'R', [], 'J', [], 'CovB', [], 'MSE', NaN, 'ErrorModelInfo', []);

    method_results = struct();
    for m = 1:length(methods)
        method_results.(methods{m}) = nanTemplate;
    end

    p_guess = [1, dt_guess];

    dtFree_w = fit_dispersion_dt_nlinfit(C1_vals, t_vals, u, Cj, Ci, L, p_guess, dC_vals);
    method_results.dt_free_wfit = dtFree_w;

    dtFree_nw = fit_dispersion_dt_nlinfit(C1_vals, t_vals, u, Cj, Ci, L, p_guess, ones(size(C1_vals)));
    method_results.dt_free_nwfit = dtFree_nw;

    if isfinite(dtFree_w.dt) && isfinite(dtFree_w.KL)
        p_guess_fixed = sqrt(dtFree_w.KL);
        method_results.dt_fixed_wfit_lim = fit_dispersion_dtfixed_nlinfit( ...
            C1_vals, t_vals, u, Cj, Ci, L, dtFree_w.dt, p_guess_fixed, dC_vals, Cmin, Cmax);
        method_results.dt_fixed_wfit_full = fit_dispersion_dtfixed_nlinfit( ...
            C1_vals, t_vals, u, Cj, Ci, L, dtFree_w.dt, p_guess_fixed, dC_vals, 0, 1);
    end

    if isfinite(dtFree_nw.dt) && isfinite(dtFree_nw.KL)
        p_guess_fixed = sqrt(dtFree_nw.KL);
        method_results.dt_fixed_nwfit_lim = fit_dispersion_dtfixed_nlinfit( ...
            C1_vals, t_vals, u, Cj, Ci, L, dtFree_nw.dt, p_guess_fixed, ones(size(C1_vals)), Cmin, Cmax);
        method_results.dt_fixed_nwfit_full = fit_dispersion_dtfixed_nlinfit( ...
            C1_vals, t_vals, u, Cj, Ci, L, dtFree_nw.dt, p_guess_fixed, ones(size(C1_vals)), 0, 1);
    end

    method_names = fieldnames(method_results);
    best_score = -Inf;
    best_method = "";
    for m = 1:length(method_names)
        r = method_results.(method_names{m});
        if isfinite(r.KL) && isfinite(r.R2) && isfinite(r.RMSE) && r.RMSE > 0
            score = r.R2 / r.RMSE;
            if score > best_score
                best_score = score;
                best_method = method_names{m};
            end
        end
    end

    if best_method ~= ""
        best_row = method_results.(best_method);
    else
        best_row = nanTemplate;   % same fix here — was the old 7-field struct
    end
end