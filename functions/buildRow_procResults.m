function row = buildRow_procResults(filedataExp, expProcData, KL_out, i)

    %BUILDROW_PROCRESULTS Build a summary table row for a processed experiment.
    %
    %   ROW = BUILDROW_PROCRESULTS(FILEDATAEXP, EXPPROCDATA, KL_OUT, I)
    %   creates a one-row table containing the experimental metadata,
    %   processed experimental parameters, fitted dispersion results, and
    %   derived transport metrics for experiment I.
    %
    %   This utility function consolidates information from the experimental
    %   design table, processed breakthrough-curve data structure, and ADE
    %   fitting results into a standardized format suitable for result
    %   aggregation, statistical analysis, and export.
    %
    %   INPUTS
    %       filedataExp : Table containing experiment metadata and operating
    %                     conditions.
    %
    %       expProcData : Structure containing processed experimental data,
    %                     breakthrough curves, and calculated experimental
    %                     parameters. Fields are indexed using the experiment
    %                     key stored in FILEDATAEXP.Key.
    %
    %       KL_out      : Structure containing fitted ADE parameters and
    %                     fitting statistics, including:
    %                       - KL      : Longitudinal dispersion coefficient
    %                       - dKL     : Dispersion coefficient uncertainty
    %                       - dt      : Time-shift correction
    %                       - ddt     : Time-shift uncertainty
    %                       - RMSE    : Root mean square error
    %                       - R2      : Coefficient of determination
    %                       - C_fit   : Fitted concentration profile
    %
    %       i           : Experiment index corresponding to the row of
    %                     FILEDATAEXP being processed.
    %
    %   OUTPUT
    %       row         : Single-row table containing:
    %                       - Experimental metadata in exp_params (which
    %                       includes metadata of filedataExp)
    %                       - Core properties
    %                       - Flow conditions
    %                       - Diffusion coefficients
    %                       - Peclet numbers
    %                       - Fitted ADE parameters
    %                       - Parameter uncertainties
    %                       - Derived line volumes and lengths
    %                       - Fit quality metrics
    %                       - Fitted breakthrough curve
    %
    %   DERIVED PARAMETERS
    %       The function computes several transport quantities including:
    %
    %           Pe_upump_L_KL   = upump*L/KL
    %           Pe_uMFM_L_KL   = uMFM*L/KL
    %           Pe_upump_L_D0  = upump*L/D0
    %           Pe_uMFM_L_D0   = uMFM*L/D0
    %           dtD        = u*dt/L
    %           L_lines    = v_lines*dt
    %           V_lines    = Q*dt
    %
    %       together with propagated uncertainties where available.
    %
    %   NOTES
    %       - Unit conversions between SI and laboratory units are performed
    %         automatically.
    %       - The resulting table row is designed to be vertically
    %         concatenated with rows from other experiments.
    %       - Intended for post-processing and reporting of tracer dispersion
    %         core-flood experiments.
    %
    %   EXAMPLE
    %       row = buildRow_procResults(filedataExp,...
    %                                  expProcData,...
    %                                  KL_out,...
    %                                  i);
    %
    %   See also TABLE, STRUCT, VERTCAT.

    row = expProcData.(filedataExp.Key(i)).exp_params;

    L = expProcData.(filedataExp.Key(i)).exp_params.L_SI;
    uMFM = expProcData.(filedataExp.Key(i)).exp_params.uavg_MFM_SI;
    duMFM = expProcData.(filedataExp.Key(i)).exp_params.ustd_MFM_SI;
    upump = expProcData.(filedataExp.Key(i)).exp_params.u_SI;
    dupump = 0.1*upump;
    D12_SI = expProcData.(filedataExp.Key(i)).exp_params.D12_SI;
    dD12_SI = expProcData.(filedataExp.Key(i)).exp_params.dD12_SI;

    % results 
    row.KL_SI = KL_out.KL;
    row.dKL_SI = KL_out.dKL;
    row.dt_SI = KL_out.dt;
    row.d_dt_SI = KL_out.ddt;
    row.RMSE = KL_out.RMSE; 
    row.R2 = KL_out.R2;
    row.KL_cm2min = row.KL_SI*60*10^4;
    row.dKL_cm2min = (row.dKL_SI)*60*10^4;
    row.dt_min = row.dt_SI/60;
    row.d_dt_min = row.d_dt_SI/60;
    row.Pe_upump_L_KL = upump*L/row.KL_SI;
    row.dPe_upump_L_KL = row.Pe_upump_L_KL*(((dupump/upump)^2+(dD12_SI/D12_SI)^2)^(1/2));
    row.dtD = upump*row.dt_SI/L;  % respect to Vcore
    row.d_dtD = (((upump/L)^2)*(row.d_dt_SI^2))^(1/2); 
    row.L_lines = row.v_lines_SI*row.dt_SI; 
    row.dL_lines = ((row.v_lines_SI^2)*(row.d_dt_SI^2))^(1/2); 
    row.L_lines_cm = row.L_lines*100;
    row.d_L_lines_cm = row.dL_lines*100;
    row.V_lines_cc = row.Q_mlmin*row.dt_SI/60; 
    row.dV_lines_cc = row.Q_mlmin*row.d_dt_SI/60; 
    row.V_lines_SI = row.V_lines_cc*(10^-6);
    row.d_V_lines_SI = row.dV_lines_cc*(10^-6);
    row.C_fit = {KL_out.C_fit}; 
    row.Pe_uMFM_L_KL = uMFM*L/row.KL_SI;
    row.dPe_uMFM_L_KL = row.Pe_uMFM_L_KL*(((duMFM/uMFM)^2+(dD12_SI/D12_SI)^2)^(1/2));
    
end

