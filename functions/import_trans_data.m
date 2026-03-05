function trans_data = import_trans_data(filename, dataLines)
%  Import pressure trans data from a text file given opts

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

% Preparing time data
trans_data.Time_PT1.Format = 'MM/dd/uuuu HH:mm:ss.SSS';
trans_data.Time_PT2.Format = 'MM/dd/uuuu HH:mm:ss.SSS';

% Rename variables to TimeStamp
trans_data = renamevars(trans_data, 'Time_PT1', 'TimeStamp_PT1');
trans_data = renamevars(trans_data, 'Time_PT2', 'TimeStamp_PT2');

end