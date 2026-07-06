function dataPR_params_BIP_out = import_inputPR_params_BIP(inputPR_params_BIP_xlsx)

%IMPORT_INPUTPR_PARAMS_BIP Import binary interaction parameter data.
%
%   DATAPR_PARAMS_BIP_OUT =
%   IMPORT_INPUTPR_PARAMS_BIP(INPUTPR_PARAMS_BIP_XLSX)
%   imports binary interaction parameter (BIP) coefficients used in
%   Peng-Robinson equation-of-state calculations.
%
%   The imported parameters correspond to the temperature-dependent
%   Jaubert-Mutelet binary interaction parameter correlation and are
%   subsequently used to calculate kij values for fluid mixtures.
%
%   INPUT
%       inputPR_params_BIP_xlsx
%           Path to the Excel workbook containing binary interaction
%           parameter coefficients.
%
%   OUTPUT
%       dataPR_params_BIP_out
%           MATLAB table containing:
%
%               Fluid1
%               Fluid2
%               A12
%               B12
%
%   EXPECTED SPREADSHEET FORMAT
%       The workbook is expected to contain a worksheet named:
%
%           Sheet1
%
%       with data beginning on row 3 and the following columns:
%
%           Fluid1    First fluid component
%
%           Fluid2    Second fluid component
%
%           A12       Jaubert-Mutelet interaction coefficient A12
%
%           B12       Jaubert-Mutelet interaction coefficient B12
%
%   APPLICATION
%       The imported coefficients are used to calculate the binary
%       interaction parameter:
%
%           kij = f(T,A12,B12,ai,bi)
%
%       which is subsequently employed in classical mixing rules for the
%       Peng-Robinson equation of state.
%
%   TYPICAL WORKFLOW
%       1. Import pure-component properties.
%
%       2. Import BIP coefficients:
%
%              bipTable = import_inputPR_params_BIP(...)
%
%       3. Calculate EOS parameters:
%
%              ai, bi
%
%       4. Compute kij:
%
%              kij = calc_BIP(...)
%
%       5. Calculate mixture properties:
%
%              Z, density, etc.
%
%   NOTES
%       - Designed for Peng-Robinson EOS calculations.
%       - Assumes worksheet name "Sheet1".
%       - Assumes data begin on row 3.
%       - Returns coefficients exactly as stored in the spreadsheet.
%       - Typically used together with CALC_BIP,
%         CALC_AI_BI, and DENSZ_PR.
%
%   EXAMPLE
%       bipTable = ...
%           import_inputPR_params_BIP('PR_BIP_Parameters.xlsx');
%
%       disp(bipTable)
%
%   See also CALC_BIP, CALC_AI_BI,
%            DENSZ_PR, READTABLE.

opts = spreadsheetImportOptions("NumVariables", 4);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid1", "Fluid2", "A12", "B12"];
opts.VariableTypes = ["string", "string", "double","double"];
dataPR_params_BIP_out = readtable(inputPR_params_BIP_xlsx,opts);
end

