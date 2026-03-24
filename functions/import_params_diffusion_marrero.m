 function dataPR_params_BIP_out = import_input_params_diffusion_marrero(input_params_diffusion_marrero_xlsx)
%IMPORT_INPUTPR_PARAMS_BIP Summary of this function goes here
opts = spreadsheetImportOptions("NumVariables", 9);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid1", "Fluid2", "A", "B", "C", "D", "E", "group", "dev_pc"];
opts.VariableTypes = ["string", "string", "double","double", "double","double", "double", "double", "double"];
dataPR_params_BIP_out = readtable(input_params_diffusion_marrero_xlsx,opts);
end

