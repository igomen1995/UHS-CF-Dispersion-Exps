function data_out = import_inputExpsResults(input_name_xlsx, sheetName)

%IMPORT_INPUTEXPSRESULTS Import processed experiment results from Excel.
%
%   DATA_OUT = IMPORT_INPUTEXPSRESULTS(INPUT_NAME_XLSX,SHEETNAME)
%   imports processed transport and dispersion results from a specified
%   worksheet within an Excel workbook.
%
%   The function is intended for loading previously processed experiment
%   results used in model calibration, literature comparisons, parameter
%   estimation, and dispersion-correlation analysis.
%
%   INPUTS
%       input_name_xlsx : Path to the Excel workbook (*.xlsx)
%
%       sheetName       : Name of the worksheet containing the processed
%                         results
%
%   OUTPUT
%       data_out        : MATLAB table containing the imported transport
%                         and dispersion results.
%
%   EXPECTED WORKSHEET FORMAT
%       The worksheet is assumed to contain results beginning at row 13
%       with the following columns:
%
%           u_cmmin      Interstitial velocity [cm/min]
%
%           KL_cm2min    Longitudinal dispersion coefficient [cm²/min]
%
%           KL_vs_D0     Normalized dispersion coefficient
%                        (KL/D0) [-]
%
%           Pe_D0        Molecular-diffusion-based Peclet number [-]
%
%   DATA PROCESSING
%       The function:
%
%       1. Reads the selected worksheet.
%
%       2. Imports processed transport parameters as numeric values.
%
%       3. Returns a MATLAB table suitable for regression analyses,
%          dispersion-model fitting, and comparison with theoretical
%          or literature correlations.
%
%   RETURNED VARIABLES
%       u_cmmin
%           Average interstitial velocity [cm/min]
%
%       KL_cm2min
%           Longitudinal dispersion coefficient [cm²/min]
%
%       KL_vs_D0
%           Ratio between hydrodynamic dispersion and molecular
%           diffusion coefficient [-]
%
%       Pe_D0
%           Peclet number calculated using D0 [-]
%
%   NOTES
%       - Designed for importing processed experimental results rather
%         than raw experimental data.
%       - Assumes worksheet data begin at row 13.
%       - Assumes all imported columns are numeric.
%       - Should only be modified if the Excel template changes.
%
%   EXAMPLE
%       results = import_inputExpsResults( ...
%                     'ProcessedResults.xlsx', ...
%                     'H2_CO2');
%
%       plot(results.Pe_D0, results.KL_vs_D0,'o')
%       xlabel('Pe_{D0}')
%       ylabel('K_L / D_0')
%
%   See also READTABLE, SPREADSHEETIMPORTOPTIONS.

opts = spreadsheetImportOptions("NumVariables", 4);
% Specify sheet and range
opts.Sheet = sheetName;
opts.DataRange = [13,Inf];
% Specify column names and types
opts.VariableNames = ["u_cmmin", "KL_cm2min", "KL_vs_D0","Pe_D0"];
opts.VariableTypes = ["double", "double", "double", "double"];
data_out = readtable(input_name_xlsx,opts);

end

