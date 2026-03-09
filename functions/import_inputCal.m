function data_out = import_inputCal(input_name_xlsx)

%IMPORT_INPUTCAL Summary of this function goes here
% import fields for importing data of calibration experiments

opts = spreadsheetImportOptions("NumVariables", 18);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Key", "Date", "Fluid1", "Fluid2", "T_C", "P_psig", "Q_mlmin", "Run", "workingPump", "st", "et", "dt", "path", "pumps_data_name", "trans_data_name", "MFM_data_name", "PGD1_data_name", "PGD2_data_name","GMT_PGD"];
opts.VariableTypes = ["string", "string","string","string", "double", "string", "string", "double", "double",  "datetime", "datetime", "double", "string", "string", "string", "string", "string", "string", "string"];
data_out = readtable(input_name_xlsx,opts);

% Specify time format which is same for all times in different data sets
data_out.st = datetime(data_out.st,'Format','MM/dd/uuuu HH:mm:ss');
data_out.et = datetime(data_out.et,'Format','MM/dd/uuuu HH:mm:ss');

% Data of P and Q in one cell as string is converted to arrays
P_cell = cell(height(data_out),1);
Q_cell = cell(height(data_out),1);
for i = 1:height(data_out)
     P_cell{i} = str2double(split(data_out.P_psig(i,:),","));
     Q_cell{i} = str2double(split(data_out.Q_mlmin(i,:),","));
end

data_out.P_psig = P_cell;
data_out.Q_mlmin = Q_cell;

end

