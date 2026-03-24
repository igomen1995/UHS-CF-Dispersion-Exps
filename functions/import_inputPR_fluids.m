function [fl,T,P,x1,dataPR_params_BIP_out] = import_inputPR_fluids(inputPR_fluids_conds_xlsx)
%IMPORT_INPUTPR_PARAMS_BIP Summary of this function goes here
opts = spreadsheetImportOptions("NumVariables", 7);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid1", "Fluid2", "P", "T", "x1init","x1final","dx"]; % Fluids 1,2 P in MPa, T in C, x molar fraction [0,1]
opts.VariableTypes = ["string", "string", "double", "double","double","double","double"];

dataPR_params_BIP_out = readtable(inputPR_fluids_conds_xlsx);

fluid1 = dataPR_params_BIP_out.Fluid1;
fluid2 = dataPR_params_BIP_out.Fluid2;
T = dataPR_params_BIP_out.T;
P = dataPR_params_BIP_out.P;
x1init = dataPR_params_BIP_out.x1init;
x1final = dataPR_params_BIP_out.x1final;
dx = dataPR_params_BIP_out.dx;

x1 = cell(length(fluid1),1);
fl = cell(length(fluid1),1);
for i = 1:length(fluid)
    if isnan(fluid2(i))
        fl{i} = split(fluids{i},",")';
        x1{i} = x1init(i);
    else
        x1{i} = x1init(i):dx(i):x1final(i);
    end
end

end

