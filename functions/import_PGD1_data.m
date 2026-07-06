function PGD1_data = import_PGD1_data(filename, dataLines)

%IMPORT_PGD1_DATA Import hydrogen detector (PGD1) data from a CSV file.
%
%   PGD1_DATA = IMPORT_PGD1_DATA(FILENAME) imports PGD1 sensor data from
%   a comma-separated text file and returns the measurements as a MATLAB
%   table.
%
%   The function is designed for hydrogen concentration measurements
%   acquired during tracer and dispersion experiments and performs basic
%   cleaning and formatting of the imported dataset.
%
%   PGD1_DATA = IMPORT_PGD1_DATA(FILENAME,DATALINES) specifies the rows
%   to import from the data file.
%
%   INPUTS
%       filename
%           Path to the PGD1 data file.
%
%       dataLines
%           Row interval(s) to import.
%
%           Default:
%
%               [10 Inf]
%
%           indicating import from row 10 to the end of the file.
%
%   OUTPUT
%       PGD1_data
%           MATLAB table containing the imported PGD1 measurements.
%
%   IMPORTED VARIABLES
%       TimeStamp
%           Measurement timestamp
%
%       H2Temperature
%           Sensor temperature
%
%       H2Humidity
%           Sensor humidity reading
%
%       H2AL1
%           Alarm level 1 status
%
%       H2AL2
%           Alarm level 2 status
%
%       H2Error
%           Sensor error flag
%
%       H2ReferenceConcentration
%           Sensor reference concentration
%
%       H2Overrange
%           Overrange indicator
%
%       H2GasConcentration
%           Measured hydrogen concentration
%
%   DATA PROCESSING
%       The function:
%
%       1. Reads the PGD1 CSV file.
%
%       2. Converts timestamps into MATLAB datetime objects.
%
%       3. Removes rows containing missing values.
%
%       4. Renames the imported time variable:
%
%              time -> TimeStamp
%
%       5. Applies the display format:
%
%              MM/dd/yyyy HH:mm:ss.SSS
%
%   APPLICATIONS
%       The imported data can be used for:
%
%           - Hydrogen breakthrough-curve analysis
%           - Sensor calibration
%           - Dispersion experiments
%           - Time-series visualization
%           - Concentration-data processing
%
%   NOTES
%       - Designed for PGD1 hydrogen detector exports.
%       - Assumes timestamps are stored as:
%
%             yyyy/MM/dd HH:mm:ss.SSS
%
%       - Removes rows containing missing values automatically.
%       - Standardizes the timestamp variable name to facilitate merging
%         with other experimental datasets.
%
%   EXAMPLE
%       PGD1 = import_PGD1_data('PGD1_Run01.csv');
%
%       plot(PGD1.TimeStamp,PGD1.H2GasConcentration)
%       xlabel('Time')
%       ylabel('H_2 Concentration')
%
%   See also READTABLE, DATETIME, RMMISSING,
%            DELIMITEDTEXTIMPORTOPTIONS, RENAMEVARS.

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [10, Inf];
end

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 9);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["time", "H2Temperature", "H2Humidity", "H2AL1", "H2AL2", "H2Error", "H2ReferenceConcentration", "H2Overrange", "H2GasConcentration"];
opts.VariableTypes = ["datetime", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "time", "InputFormat", "yyyy/MM/dd HH:mm:ss.SSS");

% Import the data
PGD1_data = readtable(filename, opts);
PGD1_data = rmmissing(PGD1_data); % Remove NaN data

% Preparing data
PGD1_data.time.Format = 'MM/dd/uuuu HH:mm:ss.SSS';

% Rename variable to TimeStamp
PGD1_data = renamevars(PGD1_data, 'time', 'TimeStamp');

end