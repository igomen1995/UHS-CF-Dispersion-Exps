function data_out = import_inputCal(input_name_xlsx)

%IMPORT_INPUTCAL Import calibration experiment metadata from Excel.
%
%   DATA_OUT = IMPORT_INPUTCAL(INPUT_NAME_XLSX) reads the calibration
%   experiment input spreadsheet and converts the contents into a MATLAB
%   table suitable for automated processing and analysis.
%
%   The function imports experimental metadata, operating conditions,
%   file names, and time intervals associated with calibration runs.
%
%   INPUT
%       input_name_xlsx : Path to the calibration input workbook (*.xlsx)
%
%   OUTPUT
%       data_out        : Table containing the imported experiment
%                         information and associated metadata.
%
%   EXPECTED SPREADSHEET FORMAT
%       The workbook is expected to contain a worksheet named:
%
%           Sheet1
%
%       beginning at row 3 with the following fields:
%
%           Key
%           Date
%           Fluid1
%           Fluid2
%           T_C
%           P_psig
%           x1
%           Q_mlmin
%           Run
%           workingPump
%           st
%           et
%           dt
%           path
%           pumps_data_name
%           trans_data_name
%           MFM_data_name
%           PGD1_data_name
%           PGD2_data_name
%           GMT_PGD
%
%   DATA PROCESSING
%       The function performs several preprocessing steps:
%
%       1. Imports the spreadsheet into a MATLAB table.
%
%       2. Converts start and end times:
%
%              st
%              et
%
%          into MATLAB datetime variables.
%
%       3. Converts pressure entries stored as comma-separated strings
%          into numeric arrays.
%
%       4. Converts flow-rate entries stored as comma-separated strings
%          into numeric arrays.
%
%   TIME FORMAT
%       The imported datetime variables are stored using:
%
%           MM/dd/yyyy HH:mm:ss
%
%   OUTPUT MODIFICATIONS
%       After import:
%
%           data_out.P_psig
%
%       becomes a cell array containing numeric pressure vectors.
%
%       Similarly:
%
%           data_out.Q_mlmin
%
%       becomes a cell array containing numeric flow-rate vectors.
%
%       This allows experiments with multiple flow steps or pressure
%       conditions to be represented within a single table row.
%
%   NOTES
%       - Designed for calibration experiments.
%       - Assumes the worksheet name is "Sheet1".
%       - Assumes data begin at row 3.
%       - Comma-separated pressure and flow-rate entries are
%         automatically converted to numeric arrays.
%       - Returned table is intended to serve as the main metadata input
%         for subsequent data-processing workflows.
%
%   EXAMPLE
%       data = import_inputCal('Calibration_Input.xlsx');
%
%       disp(data.Key)
%       disp(data.P_psig{1})
%
%   See also READTABLE, DATETIME, SPREADSHEETIMPORTOPTIONS.

opts = spreadsheetImportOptions("NumVariables", 19);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Key", "Date", "Fluid1", "Fluid2", "T_C", "P_psig", "x1", "Q_mlmin", "Run", "workingPump", "st", "et", "dt", "path", "pumps_data_name", "trans_data_name", "MFM_data_name", "PGD1_data_name", "PGD2_data_name","GMT_PGD"];
opts.VariableTypes = ["string", "string","string","string", "double", "string", "double", "string", "double", "string",  "datetime", "datetime", "double", "string", "string", "string", "string", "string", "string", "string"];
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

