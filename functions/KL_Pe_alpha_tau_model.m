function KL_model = KL_Pe_alpha_tau_model(Pe_fromD0,D0,p)
%KL_PE_ALPHA_ONLY_MODEL Summary of this function goes here

% Model with beta = 1 no tortuosity
KL_model = D0 * ( 1/p(2) + p(1) .* (Pe_fromD0.^1) );

end

