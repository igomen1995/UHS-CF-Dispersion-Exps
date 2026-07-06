function [fl,T,P,x1,dataPR_params_BIP_out] = import_inputPR_fluids(inputPR_fluids_conds_xlsx)

%IMPORT_INPUTPR_FLUIDS Import fluid compositions and conditions for PR EOS.
%
%   [FL,T,P,X1,DATAPR_PARAMS_BIP_OUT] =
%   IMPORT_INPUTPR_FLUIDS(INPUTPR_FLUIDS_CONDS_XLSX)
%   imports fluid-system definitions, operating conditions, and
%   composition ranges from an Excel spreadsheet for Peng-Robinson (PR)
%   equation-of-state calculations.
%
%   The function reads fluid identities, pressure, temperature, and
%   composition information and generates composition vectors that can be
%   used for mixture-property calculations such as density, compressibility
%   factor, and phase-behavior analyses.
%
%   INPUT
%       inputPR_fluids_conds_xlsx
%           Path to the Excel workbook containing the fluid definitions
%           and thermodynamic conditions.
%
%   OUTPUTS
%       fl
%           Cell array containing fluid-system definitions.
%
%           Example:
%
%               {'H2','CO2'}
%
%       T
%           Temperature values [°C]
%
%       P
%           Pressure values [MPa]
%
%       x1
%           Cell array containing mole-fraction vectors for component 1.
%
%       dataPR_params_BIP_out
%           Complete imported input table.
%
%   EXPECTED SPREADSHEET FORMAT
%       The workbook is expected to contain a worksheet named:
%
%           Sheet1
%
%       with data beginning on row 3 and the following columns:
%
%           Fluid1      Primary component
%           Fluid2      Secondary component
%           P           Pressure [MPa]
%           T           Temperature [°C]
%           x1init      Initial mole fraction of component 1
%           x1final     Final mole fraction of component 1
%           dx          Composition increment
%
%   DATA PROCESSING
%       For binary mixtures, composition vectors are generated as:
%
%           x1 = x1init : dx : x1final
%
%       allowing thermodynamic properties to be evaluated across a
%       composition range.
%
%       For pure-component calculations, a single composition value is
%       retained.
%
%   APPLICATIONS
%       The imported data are intended for:
%
%           - Peng-Robinson EOS calculations
%           - Compressibility-factor predictions
%           - Density calculations
%           - Binary-mixture property estimation
%           - Binary interaction parameter (BIP) studies
%
%   NOTES
%       - Assumes worksheet name "Sheet1".
%       - Assumes data begin at row 3.
%       - Supports both pure fluids and binary mixtures.
%       - Designed as a preprocessing utility for PR EOS workflows.
%
%   EXAMPLE
%       [fl,T,P,x1,inputTable] = ...
%           import_inputPR_fluids('PR_Input.xlsx');
%
%       disp(fl{1})
%       disp(x1{1})
%
%   See also DENSZ_PR, READTABLE,
%            SPREADSHEETIMPORTOPTIONS.

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

