function trans_data = import_trans_data(filename, dataLines)

%IMPORT_TRANS_DATA Import pressure-transducer acquisition data.
%
%   TRANS_DATA = IMPORT_TRANS_DATA(FILENAME) imports pressure-transducer
%   data from a CSV file and returns the measurements as a MATLAB table.
%
%   The function is designed for pressure monitoring during core-flooding
%   and dispersion experiments and imports measurements from two pressure
%   transducers (PT1 and PT2) together with their corresponding
%   timestamps.
%
%   TRANS_DATA = IMPORT_TRANS_DATA(FILENAME,DATALINES) specifies the rows
%   to import from the data file.
%
%   INPUTS
%       filename
%           Path to the pressure-transducer data file.
%
%       dataLines
%           Row interval(s) to import.
%
%           Default:
%
%               [12 Inf]
%
%           indicating import from row 12 to the end of the file.
%
%   OUTPUT
%       trans_data
%           MATLAB table containing imported pressure measurements and
%           timestamps.
%
%   IMPORTED VARIABLES
%       TimeStamp_PT1
%           Timestamp associated with pressure transducer PT1
%
%       PT1
%           Pressure measured by transducer PT1
%
%       TimeStamp_PT2
%           Timestamp associated with pressure transducer PT2
%
%       PT2
%           Pressure measured by transducer PT2
%
%   DATA PROCESSING
%       The function:
%
%       1. Imports pressure-transducer measurements from the CSV file.
%
%       2. Converts timestamps into MATLAB datetime variables.
%
%       3. Removes rows containing missing values.
%
%       4. Renames imported timestamp variables:
%
%              Time_PT1 -> TimeStamp_PT1
%              Time_PT2 -> TimeStamp_PT2
%
%       5. Applies the standardized display format:
%
%              MM/dd/yyyy HH:mm:ss.SSS
%
%   TIME FORMAT
%       Input timestamps are expected in the format:
%
%           yyyy-MM-dd hh:mm:ss.SSS aa
%
%       where:
%
%           aa = AM/PM indicator
%
%   APPLICATIONS
%       The imported data can be used for:
%
%           - Differential pressure calculations
%           - Core-flood monitoring
%           - Breakthrough-curve analysis
%           - Pressure-drop evaluation
%           - Permeability calculations
%           - Experimental synchronization with MFM and sensor data
%
%   NOTES
%       - Designed for the pressure-transducer logging format used in the
%         UHS-CF-Dispersion-Exps workflow.
%       - Assumes two pressure transducers are recorded.
%       - Rows containing missing values are automatically removed.
%       - Standardized timestamp names facilitate synchronization with
%         pumps, MFM, PGD1, and PGD2 datasets.
%
%   EXAMPLE


% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [12, Inf];
end

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 4);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Time_PT1", "PT1", "Time_PT2", "PT2"];
opts.VariableTypes = ["datetime", "double", "datetime", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "Time_PT1", "InputFormat", "yyyy-MM-dd hh:mm:ss.SSS aa");
opts = setvaropts(opts, "Time_PT2", "InputFormat", "yyyy-MM-dd hh:mm:ss.SSS aa");

% Import the data
trans_data = readtable(filename, opts);
trans_data = rmmissing(trans_data); % remove NaN

% Preparing time data
trans_data.Time_PT1.Format = 'MM/dd/uuuu HH:mm:ss.SSS';
trans_data.Time_PT2.Format = 'MM/dd/uuuu HH:mm:ss.SSS';

% Rename variables to TimeStamp
trans_data = renamevars(trans_data, 'Time_PT1', 'TimeStamp_PT1');
trans_data = renamevars(trans_data, 'Time_PT2', 'TimeStamp_PT2');

end