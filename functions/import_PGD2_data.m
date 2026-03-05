function PGD2_data = import_PGD2_data(filename, dataLines)
%  Import PGD2 data from a text file with opts

% Input handling

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