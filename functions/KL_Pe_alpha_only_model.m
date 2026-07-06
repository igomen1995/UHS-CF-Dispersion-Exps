function KL_model = KL_Pe_alpha_only_model(Pe_fromD0,D0,p)
%KL_PE_ALPHA_ONLY_MODEL Summary of this function goes here

% alpha = p * Dp; % Alpha (dispersivity) Dp is L

% Model with beta = 1 no tortuosity
KL_model = D0 * ( p .* Pe_fromD0 );

end

