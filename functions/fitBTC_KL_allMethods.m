function [method_results, best_method, best_row] = fitBTC_KL_allMethods(t_vals, C1_vals, dC_vals, u, Cj, Ci, L, dt_guess, Cmin, Cmax, KL0_SI)
% FITBTC_KL_ALLMETHODS  Fit KL (and dt) to one breakthrough curve with the
% CDE solution, using six methods, and pick the best valid one.
%
%   INPUTS
%       t_vals   time [s]
%       C1_vals  measured concentration [-]
%       dC_vals  concentration uncertainty (weights 1/dC^2 in the w-fits)
%       u        interstitial velocity [m/s]
%       Cj, Ci   injected / initial concentration [-]
%       L        transport distance [m]
%       dt_guess initial guess for the delay dt [s]
%       Cmin, Cmax  range for the "lim" fits
%       KL0_SI   (optional) initial guess for KL [m2/s], default 1e-6 (= 0.6 cm2/min)
%
%   The fitted parameter vector is p = [sqrt(KL_SI), dt_s].
%
%   Robustness:
%     * KL starts from KL0_SI (not 1 m2/s, which is ~6e4 cm2/min)
%     * dt-free fits are run from two starting delays (dt_guess and the
%       arrival implied by the data, t50 - L/u) and the better valid one is kept
%     * a fit is "valid" only if KL, dKL > 0 and finite, KL < KLmax, R2 > 0
%       and dt lies inside the measured time window
%     * dt-fixed fits are seeded only from valid dt-free fits
%     * the best method is chosen among valid fits only, scored on the
%       unweighted RMSE/R2 over the whole curve (same basis for all methods)

    if nargin < 11 || isempty(KL0_SI), KL0_SI = 1e-6; end
    KLmax_SI = 1e-3;                      % 600 cm2/min -- anything above is a failed fit

    methods = {'dt_free_wfit','dt_free_nwfit', ...
               'dt_fixed_wfit_lim','dt_fixed_nwfit_lim', ...
               'dt_fixed_wfit_full','dt_fixed_nwfit_full'};

    nanTemplate = struct('KL', NaN, 'dKL', NaN, 'dt', NaN, 'ddt', NaN, ...
        'KL_cm2min', NaN, 'dKL_cm2min', NaN, 'dt_min', NaN, 'ddt_min', NaN, ...
        'C_fit', NaN(size(C1_vals)), 'C_pred', NaN(size(C1_vals)), 'dC_pred', NaN(size(C1_vals)), ...
        'RMSE', NaN, 'R2', NaN, ...
        'Cfun', [], 'R', [], 'J', [], 'CovB', [], 'MSE', NaN, 'ErrorModelInfo', [], ...
        'valid', false, 'RMSE_all', NaN, 'R2_all', NaN);

    method_results = struct();
    for m = 1:length(methods)
        method_results.(methods{m}) = nanTemplate;
    end

    tWin = [min(t_vals) - (max(t_vals)-min(t_vals)), max(t_vals)];   % plausible dt range
    w1   = ones(size(C1_vals));

    % --- starting delays: the one passed in, and the one implied by the data
    [~, i50]  = min(abs(C1_vals - 0.5*(Ci + Cj)));
    dt_data   = t_vals(i50) - L/u;
    dtStarts  = unique([dt_guess, dt_data]);

    % --- dt-free fits (weighted / unweighted), best of the starting points
    method_results.dt_free_wfit  = bestOfStarts(@(p0) fit_dispersion_dt_nlinfit( ...
        C1_vals, t_vals, u, Cj, Ci, L, p0, dC_vals), KL0_SI, dtStarts);
    method_results.dt_free_nwfit = bestOfStarts(@(p0) fit_dispersion_dt_nlinfit( ...
        C1_vals, t_vals, u, Cj, Ci, L, p0, w1), KL0_SI, dtStarts);

    % --- dt-fixed fits, seeded only from valid dt-free fits
    rw = method_results.dt_free_wfit;
    if rw.valid
        p0 = sqrt(rw.KL);
        method_results.dt_fixed_wfit_lim  = safeFixed(rw.dt, p0, dC_vals, Cmin, Cmax);
        method_results.dt_fixed_wfit_full = safeFixed(rw.dt, p0, dC_vals, 0, 1);
    end
    rn = method_results.dt_free_nwfit;
    if rn.valid
        p0 = sqrt(rn.KL);
        method_results.dt_fixed_nwfit_lim  = safeFixed(rn.dt, p0, w1, Cmin, Cmax);
        method_results.dt_fixed_nwfit_full = safeFixed(rn.dt, p0, w1, 0, 1);
    end

    % --- best valid method, same scoring basis for all
    best_score  = -Inf;
    best_method = "";
    for m = 1:length(methods)
        r = method_results.(methods{m});
        if r.valid && isfinite(r.RMSE_all) && r.RMSE_all > 0
            score = r.R2_all / r.RMSE_all;
            if score > best_score
                best_score  = score;
                best_method = methods{m};
            end
        end
    end

    if best_method ~= ""
        best_row = method_results.(best_method);
    else
        best_row = nanTemplate;
    end

    % ================= nested helpers =================

    function r = bestOfStarts(fitFun, KL0, dts)
    % run the dt-free fit from each starting delay, keep the best valid one
        r = nanTemplate;
        for d = dts
            try
                rr = finish(fitFun([sqrt(KL0), d]));
            catch
                continue
            end
            if rr.valid && (~r.valid || rr.RMSE_all < r.RMSE_all)
                r = rr;
            elseif ~r.valid && ~rr.valid
                r = rr;            % keep something to inspect, still flagged invalid
            end
        end
    end

    function r = safeFixed(dtFix, p0, wv, cLo, cHi)
    % dt-fixed fit that never stops the run (e.g. too few points in the lim range)
        try
            r = finish(fit_dispersion_dtfixed_nlinfit( ...
                C1_vals, t_vals, u, Cj, Ci, L, dtFix, p0, wv, cLo, cHi));
        catch
            r = nanTemplate;
        end
    end

    function r = finish(r)
    % add missing template fields, unweighted RMSE/R2 on the whole curve, validity flag
        for fn = fieldnames(nanTemplate)'
            if ~isfield(r, fn{1}), r.(fn{1}) = nanTemplate.(fn{1}); end
        end

        yhat = [];
        if isfield(r,'C_pred') && numel(r.C_pred) == numel(C1_vals), yhat = r.C_pred(:); end
        if (isempty(yhat) || all(isnan(yhat))) && isfield(r,'C_fit') && numel(r.C_fit) == numel(C1_vals)
            yhat = r.C_fit(:);
        end
        if ~isempty(yhat)
            ok = isfinite(yhat) & isfinite(C1_vals(:));
            if nnz(ok) >= 5
                res = C1_vals(ok) - yhat(ok);
                r.RMSE_all = sqrt(mean(res.^2));
                r.R2_all   = 1 - sum(res.^2) / sum((C1_vals(ok) - mean(C1_vals(ok))).^2);
            end
        end

        dtOK  = ~isfield(r,'dt') || ~isfinite(r.dt) || (r.dt >= tWin(1) && r.dt <= tWin(2));
        dKLok = ~isfinite(r.dKL) || r.dKL > 0;      % dt-fixed fits may report dKL = NaN
        r.valid = isfinite(r.KL) && r.KL > 0 && r.KL < KLmax_SI && dKLok && ...
                  dtOK && isfinite(r.R2_all) && r.R2_all > 0;
    end
end