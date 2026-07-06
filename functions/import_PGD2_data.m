function PGD2_data = import_PGD2_data(filename, dataLines)

%IMPORT_PGD2_DATA Import carbon dioxide detector (PGD2) data from a CSV file.
%
%   PGD2_DATA = IMPORT_PGD2_DATA(FILENAME) imports PGD2 sensor data from
%   a comma-separated text file and returns the measurements as a MATLAB
%   table.
%
%   The function is designed for CO2 concentration measurements acquired
%   during core-flooding, tracer, and dispersion experiments. Imported
%   data are cleaned and formatted for subsequent analysis.
%
%   PGD2_DATA = IMPORT_PGD2_DATA(FILENAME,DATALINES) specifies the rows
%   to import from the data file.
%
%   INPUTS
%       filename
%           Path to the PGD2 data file.
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
%       PGD2_data
%           MATLAB table containing the imported PGD2 measurements.
%
%   IMPORTED VARIABLES
%       TimeStamp
%           Measurement timestamp
%
%       CO2Temperature
%           Sensor temperature
%
%       CO2Humidity
%           Sensor humidity reading
%
%       CO2AL1
%           Alarm level 1 status
%
%       CO2AL2
%           Alarm level 2 status
%
%       CO2Error
%           Sensor error flag
%
%       CO2ReferenceConcentration
%           Sensor reference concentration
%
%       CO2Overrange
%           Overrange indicator
%
%       CO2GasConcentration
%           Measured CO2 concentration
%
%   DATA PROCESSING
%       The function:
%
%       1. Reads the PGD2 CSV data file.
%
%       2. Converts timestamps into MATLAB datetime objects.
%
%       3. Removes rows containing missing values.
%
%       4. Renames the imported variable:
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
%           - CO2 breakthrough-curve analysis
%           - Sensor validation and calibration
%           - Core-flood transport studies
%           - Dispersion experiments
%           - Time-series visualization
%
%   NOTES
%       - Designed for PGD2 carbon dioxide detector exports.
%       - Assumes timestamps are stored in the format:
%
%             yyyy/MM/dd HH:mm:ss.SSS
%
%       - Removes rows containing missing values automatically.
%       - Standardizes timestamp naming to facilitate synchronization
%         with MFM, pressure-transducer, and other experimental datasets.
%
%   EXAMPLE
%       PGD2 = import_PGD2_data('PGD2_Run01.csv');
%
%       plot(PGD2.TimeStamp, PGD2.CO2GasConcentration)
%       xlabel('Time')
%       ylabel('CO_2 Concentration')
%
%   See also IMPORT_PGD1_DATA, READTABLE, DATETIME,
%            RMMISSING, DELIMITEDTEXTIMPORTOPTIONS, RENAMEVARS.

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
opts.VariableNames = ["time", "CO2Temperature", "CO2Humidity", "CO2AL1", "CO2AL2", "CO2Error", "CO2ReferenceConcentration", "CO2Overrange", "CO2GasConcentration"];
opts.VariableTypes = ["datetime", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "time", "InputFormat", "yyyy/MM/dd HH:mm:ss.SSS");

% Import the data
PGD2_data = readtable(filename, opts);
PGD2_data = rmmissing(PGD2_data); % Remove NaN data

% Preparing data
PGD2_data.time.Format = 'MM/dd/uuuu HH:mm:ss.SSS';

% Rename variable to TimeStamp
PGD2_data = renamevars(PGD2_data,'time','TimeStamp');

end