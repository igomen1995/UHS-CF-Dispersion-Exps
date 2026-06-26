function row = buildRow_procResults(filedataExp, expProcData, KL_out, i)

    % takes filedatExp table and expProcData structure that contains the
    % following fields

    u = expProcData.(filedataExp.Key(i)).exp_params.u_SI;
    L = expProcData.(filedataExp.Key(i)).exp_params.L_SI;

    % exp params for table
    row = table();
    row.Key = filedataExp.Key(i);
    row.Fluid1 = filedataExp.Fluid1(i);
    row.Fluid2 = filedataExp.Fluid2(i);
    row.T_C = filedataExp.T(i);
    row.P_psig = filedataExp.P(i);
    row.Q_mlmin = filedataExp.Q(i);
    row.Run = filedataExp.Run(i);
    row.C1init_molpc = filedataExp.C1init(i);
    row.C1j_molpc = filedataExp.C1j(i);
    row.D_in = filedataExp.D(i);
    row.L_in = filedataExp.L(i);
    row.phi = filedataExp.phi(i);
    row.K_mD = filedataExp.K(i);
    % exp params for table
    row.T_mean = mean(expProcData.(filedataExp.Key(i)).BT.T_MFM);
    row.T_std = std(expProcData.(filedataExp.Key(i)).BT.T_MFM);
    row.u_cmmin = u*60*(10^2);
    row.L_cm = L*100;
    row.D0_SI = expProcData.(filedataExp.Key(i)).exp_params.D12_cm2min/(60*10^4);
    row.dD0_SI = expProcData.(filedataExp.Key(i)).exp_params.dD12_cm2min/(60*10^4); % error
    row.D0_cm2min = row.D0_SI*60*10^4;
    row.dD0_cm2min = row.dD0_SI*60*10^4;
    row.Pe_D0 = u*L/row.D0_SI;
    row.dPe_D0 = (((-u*L/(row.D0_SI^2))^2)*(row.dD0_SI^2))^(1/2); % error
    row.v_lines = expProcData.(filedataExp.Key(i)).exp_params.v_lines_SI;
    row.KL_lines = expProcData.(filedataExp.Key(i)).exp_params.KL_lines_SI;

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
    row.Pe = u*L/row.KL_SI; 
    row.dPe = (((-u*L*((row.KL_SI)^-2))^2)*(row.dKL_SI^2))^(1/2); 
    row.dtD = u*row.dt_SI/L;  % respect to Vcore
    row.d_dtD = (((u/L)^2)*(row.d_dt_SI^2))^(1/2); 
    row.L_lines = row.v_lines*row.dt_SI; 
    row.dL_lines = ((row.v_lines^2)*(row.d_dt_SI^2))^(1/2); 
    row.L_lines_cm = row.L_lines*100;
    row.d_L_lines_cm = row.dL_lines*100;
    row.V_lines_cc = row.Q_mlmin*row.dt_SI/60; 
    row.dV_lines_cc = row.Q_mlmin*row.d_dt_SI/60; 
    row.V_lines_SI = row.V_lines_cc*(10^-6);
    row.d_V_lines_SI = row.dV_lines_cc*(10^-6);
    row.C_fit = {KL_out.C_fit}; 
    
end

