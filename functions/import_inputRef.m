function dataRef_out = import_inputRef(inputRef_name_xlsx)
%IMPORT_INPUTREF Summary of this function goes here
opts = spreadsheetImportOptions("NumVariables", 8);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid", "T_C", "P_psig", "P_psia", "P_bar", "P_MPa", "dens", "Z", "Phase"];
opts.VariableTypes = ["string", "double","double", "double", "double", "double", "double", "double", "string"];
dataRef_out = readtable(inputRef_name_xlsx,opts);
end

