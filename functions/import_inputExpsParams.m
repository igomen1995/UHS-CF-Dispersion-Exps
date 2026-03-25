function data_out = import_inputExpsParams(input_name_xlsx, sheetName)

%IMPORT_INPUTCAL Summary of this function goes here
% import fields for importing data of experiments

% Do not change unless input excel format changed

opts = spreadsheetImportOptions("NumVariables", 2);
% Specify sheet and range
opts.Sheet = sheetName;
opts.DataRange = [1,9];
% Specify column names and types
opts.VariableNames = ["Params", "Vals"];
opts.VariableTypes = ["string", "string"];
data_out = readtable(input_name_xlsx,opts);

VarNames = {'Ref','Fluid2','Sample','T_C','L_cm','phi','alpha_cm','P_MPa','D0_cm2min'}; 
Vals = data_out.Vals;

S = struct();

for i = 1:numel(VarNames)
    S.(VarNames{i}) = Vals{i};
end

data_out = struct2table(S);

end

