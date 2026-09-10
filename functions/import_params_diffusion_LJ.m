 function dataPR_params_BIP_out = import_params_diffusion_LJ(input_params_diffusion_LennardJones_xlsx)

opts = spreadsheetImportOptions("NumVariables", 5);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid", "sigma", "dsigma", "eps", "deps"];
opts.VariableTypes = ["string", "double","double", "double","double"];
dataPR_params_BIP_out = readtable(input_params_diffusion_LennardJones_xlsx,opts);
end

