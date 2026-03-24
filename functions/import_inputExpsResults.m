function data_out = import_inputExpsResults(input_name_xlsx, sheetName)

%IMPORT_INPUTCAL Summary of this function goes here
% import fields for importing data of experiments

% Do not change unless input excel format changed

opts = spreadsheetImportOptions("NumVariables", 4);
% Specify sheet and range
opts.Sheet = sheetName;
opts.DataRange = [13,Inf];
% Specify column names and types
opts.VariableNames = ["u_cmmin", "KL_cm2min", "KL_vs_D0","Pe_D0"];
opts.VariableTypes = ["double", "double", "double", "double"];
data_out = readtable(input_name_xlsx,opts);

end

