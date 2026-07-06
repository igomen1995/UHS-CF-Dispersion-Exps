function dataPR_params_pure_out = import_inputPR_params_pure(inputPR_params_pure_xlsx)

%IMPORT_INPUTPR_PARAMS_PURE Import pure-component properties for PR EOS.
%
%   DATAPR_PARAMS_PURE_OUT =
%   IMPORT_INPUTPR_PARAMS_PURE(INPUTPR_PARAMS_PURE_XLSX)
%   imports pure-component thermodynamic properties required for
%   Peng-Robinson equation-of-state (PR EOS) calculations.
%
%   The imported data include molecular weight, critical properties,
%   and acentric factors used to calculate the pure-component
%   attraction and covolume parameters of the PR EOS.
%
%   INPUT
%       inputPR_params_pure_xlsx
%           Path to the Excel workbook containing pure-component
%           thermodynamic properties.
%
%   OUTPUT
%       dataPR_params_pure_out
%           MATLAB table containing:
%
%               Fluid
%               M
%               Tc
%               Pc
%               AcentricFactor
%
%   EXPECTED SPREADSHEET FORMAT
%       The workbook is expected to contain a worksheet named:
%
%           Sheet1
%
%       with data beginning on row 3 and the following columns:
%
%           Fluid
%               Fluid name
%
%           M
%               Molecular weight [kg/mol]
%
%           Tc
%               Critical temperature [K]
%
%           Pc
%               Critical pressure [MPa]
%
%           AcentricFactor
%               Pitzer acentric factor [-]
%
%   APPLICATION
%       The imported properties are used to calculate the
%       pure-component Peng-Robinson parameters:
%
%           ai(T)
%           bi
%
%       which are subsequently combined through mixing rules for
%       mixture-property calculations.
%
%   TYPICAL WORKFLOW
%       1. Import pure-component properties:
%
%              pureTable = ...
%                  import_inputPR_params_pure(...)
%
%       2. Calculate Peng-Robinson parameters:
%
%              [ai,bi] = calc_ai_bi(...)
%
%       3. Calculate binary interaction parameters:
%
%              kij = calc_BIP(...)
%
%       4. Compute mixture properties:
%
%              Z, density, etc.
%
%   RETURNED VARIABLES
%       Fluid
%           Component name
%
%       M
%           Molecular weight [kg/mol]
%
%       Tc
%           Critical temperature [K]
%
%       Pc
%           Critical pressure [MPa]
%
%       AcentricFactor
%           Acentric factor [-]
%
%   NOTES
%       - Designed for Peng-Robinson EOS calculations.
%       - Assumes worksheet name "Sheet1".
%       - Assumes data begin at row 3.
%       - Returns properties exactly as stored in the spreadsheet.
%       - Typically used together with CALC_AI_BI,
%         CALC_BIP, CALC_ABMIX, and DENSZ_PR.
%
%   EXAMPLE
%       pureTable = ...
%           import_inputPR_params_pure('PR_Pure_Properties.xlsx');
%
%       disp(pureTable(:,{'Fluid','Tc','Pc'}))
%
%   See also CALC_AI_BI, CALC_BIP,
%            CALC_ABMIX, CALC_Z, DENSZ_PR,
%            READTABLE.

opts = spreadsheetImportOptions("NumVariables", 5);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid", "M", "Tc", "Pc", "AcentricFactor"];
opts.VariableTypes = ["string", "double", "double", "double", "double"];
dataPR_params_pure_out = readtable(inputPR_params_pure_xlsx,opts);
end
