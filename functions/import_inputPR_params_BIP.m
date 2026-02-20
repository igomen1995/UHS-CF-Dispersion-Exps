function dataPR_params_BIP_out = import_inputPR_params_BIP(inputPR_params_BIP_xlsx)
%IMPORT_INPUTPR_PARAMS_BIP Summary of this function goes here
opts = spreadsheetImportOptions("NumVariables", 4);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid1", "Fluid2", "A12", "B12"];
opts.VariableTypes = ["string", "string", "double","double"];
dataPR_params_BIP_out = readtable(inputPR_params_BIP_xlsx,opts);
end

