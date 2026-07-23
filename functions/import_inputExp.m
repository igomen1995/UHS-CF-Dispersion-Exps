function data_out = import_inputExp(input_name_xlsx)

%IMPORT_INPUTEXP Import experimental metadata from an Excel workbook.
%
%   DATA_OUT = IMPORT_INPUTEXP(INPUT_NAME_XLSX) reads the experiment
%   input spreadsheet and converts the contents into a MATLAB table
%   containing experimental conditions, core properties, operating
%   parameters, acquisition times, and data-file references.
%
%   The imported table serves as the primary metadata source for
%   processing and analyzing core-flood and dispersion experiments.
%
%   INPUT
%       input_name_xlsx : Path to the experiment input workbook (*.xlsx)
%
%   OUTPUT
%       data_out        : MATLAB table containing all imported
%                         experimental metadata.
%
%   EXPECTED SPREADSHEET FORMAT
%       The workbook is expected to contain a worksheet named:
%
%           Sheet1
%
%       starting at row 3 with the following columns:
%
%           Key
%           Date
%           Type
%           Fluid1
%           Fluid2
%           T
%           P
%           Q
%           C1init
%           C1j
%           Run
%           D
%           L
%           phi
%           K
%           Vcore
%           setupVersion
%           IDlines_cm
%           Vlinesbefore
%           Vlinesafter
%           Vtotal
%           Comments
%           workingPump
%           cushionPump
%           confiningPump
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
%       The function:
%
%       1. Imports experimental metadata from the spreadsheet.
%
%       2. Converts experiment start and end times:
%
%              st
%              et
%
%          into MATLAB datetime objects.
%
%       3. Preserves experimental operating conditions, physical
%          properties, and file references required for automated
%          data processing.
%
%   TIME FORMAT
%       Imported datetime variables are formatted as:
%
%           MM/dd/yyyy HH:mm:ss
%
%   KEY VARIABLES
%       Experimental Conditions:
%           T         Temperature
%           P         Pressure
%           Q         Flow rate
%
%       Core Properties:
%           D         Core diameter
%           L         Core length
%           phi       Porosity
%           K         Permeability
%           Vcore     Core pore volume
%
%       Concentration Conditions:
%           C1init    Initial concentration
%           C1j       Injected concentration
%
%       Data Sources:
%           pumps_data_name
%           trans_data_name
%           MFM_data_name
%           PGD1_data_name
%           PGD2_data_name
%
%   NOTES
%       - Designed for tracer and dispersion core-flood experiments.
%       - Assumes worksheet name "Sheet1".
%       - Assumes data begin on row 3.
%       - Should only be modified if the spreadsheet format changes.
%       - Returns a fully formatted metadata table ready for subsequent
%         processing, analysis, and fitting workflows.
%
%   EXAMPLE
%       expTable = import_inputExp('Input_Experiments.xlsx');
%
%       disp(expTable.Key)
%       disp(expTable.Fluid1)
%       disp(expTable.st)
%
%   See also READTABLE, DATETIME, SPREADSHEETIMPORTOPTIONS.

opts = spreadsheetImportOptions("NumVariables", 36);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Key", "Date", "Type","Fluid1", "Fluid2", ...
    "T", "P", "Angle", "Q", "C1init", "C1j", "Run", "D", "L", "phi", "K", "Vcore", ...
    "setupVersion", "IDlines_cm", "Vlinesbefore", "Vlinesafter", "Vtotal", "Comments", "workingPump", "cushionPump", "confiningPump", "st", "et", "dt", ...
    "path", "pumps_data_name", "trans_data_name", "MFM_data_name", "PGD1_data_name", "PGD2_data_name","GMT_PGD"];
opts.VariableTypes = ["string", "string","string", "string", "string", ...
    "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", ...
    "string", "double","double", "double", "double","string", "string","string","string","datetime", "datetime", "double", ...
    "string", "string", "string", "string", "string", "string", "string"];
data_out = readtable(input_name_xlsx,opts);

data_out.st = datetime(data_out.st,'Format','MM/dd/uuuu HH:mm:ss');
data_out.et = datetime(data_out.et,'Format','MM/dd/uuuu HH:mm:ss');

end

