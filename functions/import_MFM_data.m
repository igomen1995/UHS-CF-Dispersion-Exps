function MFM_data = import_MFM_data(filename,dataLines)

%IMPORT_MFM_DATA Import mass flow meter (MFM) data from a CSV file.
%
%   MFM_DATA = IMPORT_MFM_DATA(FILENAME) imports mass flow meter data from
%   a comma-separated text file and returns the measurements as a MATLAB
%   table.
%
%   The function is configured for the data acquisition format used in
%   the UHS-CF-Dispersion-Exps workflow and retains only data associated
%   with MFM2.
%
%   MFM_DATA = IMPORT_MFM_DATA(FILENAME,DATALINES) specifies the rows to
%   import from the file.
%
%   INPUTS
%       filename
%           Path to the MFM data file.
%
%       dataLines
%           Row interval(s) to import.
%
%           Default:
%
%               [2 Inf]
%
%           indicating import from the second row to the end of the file.
%
%   OUTPUT
%       MFM_data
%           MATLAB table containing the imported MFM measurements.
%
%   IMPORTED VARIABLES
%       TimeStamp
%           Measurement timestamp
%
%       qset_MFM2
%           MFM setpoint
%
%       AnalogInput_MFM2
%           Analog input signal
%
%       ValveOutput_MFM2
%           Valve output signal
%
%       q_MFM2
%           Measured flow rate
%
%       T_MFM2
%           Measured temperature
%
%       dens_MFM2
%           Measured fluid density
%
%       freq_MFM2
%           Meter operating frequency
%
%   DATA PROCESSING
%       The function performs the following steps:
%
%       1. Reads the CSV file using predefined column formats.
%
%       2. Imports only MFM2 measurements.
%
%       3. Removes rows containing missing values.
%
%       4. Converts timestamps to MATLAB datetime objects.
%
%       5. Applies the display format:
%
%              MM/dd/yyyy HH:mm:ss.SSS
%
%   NOTES
%       - Designed for Bronkhorst MFM data exported as CSV files.
%       - Ignores additional columns beyond those explicitly defined.
%       - Rows containing missing values are automatically removed.
%       - Intended for subsequent flow-rate, density, and breakthrough-
%         curve analyses.
%
%   EXAMPLE
%       MFM = import_MFM_data('MFM_001.csv');
%
%       plot(MFM.TimeStamp,MFM.q_MFM2)
%       xlabel('Time')
%       ylabel('Flow Rate')
%
%   See also READTABLE, DATETIME,
%            DELIMITEDTEXTIMPORTOPTIONS, RMMISSING.

% If dataLines is not specified, define defaults
if nargin < 3
    dataLines = [2, Inf];
end

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 8, "Encoding", "UTF-8"); % Doesnt take the MFM1 which are the last two columns of the datafile if recorded

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TimeStamp", "qset_MFM2", "AnalogInput_MFM2", "ValveOutput_MFM2", "q_MFM2", "T_MFM2", "dens_MFM2", "freq_MFM2"];
opts.VariableTypes = ["datetime", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "TimeStamp", "InputFormat", "yyyy-MM-dd HH:mm:ss.SSS");

% Import the data
MFM_data = readtable(filename, opts);
MFM_data = rmmissing(MFM_data); % Remove Nan values

% Preparing time data
MFM_data.TimeStamp.Format = 'MM/dd/uuuu HH:mm:ss.SSS';

end