function dataPR_params_pure_out = import_inputPR_params_pure(inputPR_params_pure_xlsx)
%IMPORT_INPUT_PR_PURE_REF Summary of this function goes here
opts = spreadsheetImportOptions("NumVariables", 5);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid", "M", "Tc", "Pc", "AcentricFactor"];
opts.VariableTypes = ["string", "double", "double", "double", "double"];
dataPR_params_pure_out = readtable(inputPR_params_pure_xlsx,opts);
end

