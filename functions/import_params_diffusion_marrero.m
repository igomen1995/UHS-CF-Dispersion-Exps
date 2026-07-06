 function dataPR_params_BIP_out = import_params_diffusion_marrero(input_params_diffusion_marrero_xlsx)

%IMPORT_PARAMS_DIFFUSION_MARRERO Import diffusion-correlation parameters.
%
%   DATAPR_PARAMS_BIP_OUT =
%   IMPORT_PARAMS_DIFFUSION_MARRERO( ...
%       INPUT_PARAMS_DIFFUSION_MARRERO_XLSX)
%
%   imports the empirical coefficients required by the Marrero diffusion
%   correlation for estimating binary gas diffusion coefficients.
%
%   The imported parameters are subsequently used by
%   CALC_DIFF_MARRERO to calculate binary molecular diffusion
%   coefficients as a function of temperature and pressure.
%
%   INPUT
%       input_params_diffusion_marrero_xlsx
%           Path to the Excel workbook containing Marrero correlation
%           coefficients.
%
%   OUTPUT
%       dataPR_params_BIP_out
%           MATLAB table containing diffusion-correlation parameters for
%           one or more binary gas systems.
%
%   EXPECTED SPREADSHEET FORMAT
%       The workbook is expected to contain a worksheet named:
%
%           Sheet1
%
%       with data beginning on row 3 and the following columns:
%
%           Fluid1
%               First component of the binary system
%
%           Fluid2
%               Second component of the binary system
%
%           A
%               Marrero correlation coefficient
%
%           B
%               Marrero correlation coefficient
%
%           C
%               Marrero correlation coefficient
%
%           D
%               Marrero correlation coefficient
%
%           E
%               Marrero correlation coefficient
%
%           group
%               Correlation-group identifier
%
%           dev_pc
%               Expected model deviation [%]
%
%   APPLICATION
%       The imported coefficients are used to estimate binary diffusion
%       coefficients:
%
%           D12 = f(T,P,A,B,C,D,E)
%
%       and associated uncertainty estimates:
%
%           dD12 = dev_pc * D12 / 100
%
%       through the CALC_DIFF_MARRERO function.
%
%   RETURNED VARIABLES
%       Fluid1
%           First species in the binary diffusion pair
%
%       Fluid2
%           Second species in the binary diffusion pair
%
%       A,B,C,D,E
%           Empirical correlation coefficients
%
%       group
%           Correlation formulation identifier
%
%       dev_pc
%           Expected percent deviation of the correlation
%
%   NOTES
%       - Designed for binary-gas diffusion calculations.
%       - Assumes worksheet name "Sheet1".
%       - Assumes data begin on row 3.
%       - Returns correlation parameters exactly as stored in the
%         spreadsheet.
%       - Typically used together with CALC_DIFF_MARRERO.
%
%   EXAMPLE
%       diffTable = ...
%           import_input_params_diffusion_marrero( ...
%               'DiffusionParameters.xlsx');
%
%       disp(diffTable(:,{'Fluid1','Fluid2','group'}))
%
%   See also CALC_DIFF_MARRERO, READTABLE,
%            SPREADSHEETIMPORTOPTIONS.
opts = spreadsheetImportOptions("NumVariables", 9);
% Specify sheet and range
opts.Sheet = "Sheet1";
opts.DataRange = [3,Inf];
% Specify column names and types
opts.VariableNames = ["Fluid1", "Fluid2", "A", "B", "C", "D", "E", "group", "dev_pc"];
opts.VariableTypes = ["string", "string", "double","double", "double","double", "double", "double", "double"];
dataPR_params_BIP_out = readtable(input_params_diffusion_marrero_xlsx,opts);
end

