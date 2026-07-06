function data_out = import_inputExpsParams(input_name_xlsx, sheetName)

%IMPORT_INPUTEXPSPARAMS Import experiment-specific parameter sheet.
%
%   DATA_OUT = IMPORT_INPUTEXPSPARAMS(INPUT_NAME_XLSX,SHEETNAME)
%   reads a parameter worksheet from an Excel workbook and converts the
%   imported parameter-value pairs into a single-row MATLAB table.
%
%   This function is intended for importing experiment-specific metadata
%   and transport parameters that are stored in a compact parameter sheet
%   format.
%
%   INPUTS
%       input_name_xlsx : Path to the input Excel workbook (*.xlsx)
%
%       sheetName       : Name of the worksheet containing the parameter
%                         values to import
%
%   OUTPUT
%       data_out        : Single-row table containing the imported
%                         experiment parameters.
%
%   EXPECTED WORKSHEET FORMAT
%       The worksheet is expected to contain two columns:
%
%           Params    Parameter names
%           Vals      Parameter values
%
%       with parameter values located in rows 1 through 9.
%
%   IMPORTED PARAMETERS
%       The following parameters are extracted and assigned as table
%       variables:
%
%           Ref         Reference identifier
%           Fluid2      Secondary fluid
%           Sample      Sample identifier
%           T_C         Temperature [°C]
%           L_cm        Core length [cm]
%           phi         Porosity [-]
%           alpha_cm    Dispersivity [cm]
%           P_MPa       Pressure [MPa]
%           D0_cm2min   Molecular diffusion coefficient [cm²/min]
%
%   DATA PROCESSING
%       The function:
%
%       1. Reads the selected worksheet.
%
%       2. Imports parameter values stored in the "Vals" column.
%
%       3. Assigns values to predefined parameter names.
%
%       4. Converts the resulting structure into a single-row MATLAB
%          table for consistent downstream processing.
%
%   NOTES
%       - Designed for worksheets containing a fixed set of experiment
%         parameters.
%       - Assumes exactly nine parameter entries.
%       - Should only be modified if the Excel template format changes.
%       - Returns all values as imported from the spreadsheet.
%
%   EXAMPLE
%       params = import_inputExpsParams( ...
%                    'ExperimentParameters.xlsx', ...
%                    'Sample_A');
%
%       disp(params.Ref)
%       disp(params.alpha_cm)
%
%   See also READTABLE, STRUCT2TABLE,
%            SPREADSHEETIMPORTOPTIONS.


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

