function PGD1_data = import_PGD1_data(filename, dataLines)
%  Import PGD1 data from a text file with opts

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