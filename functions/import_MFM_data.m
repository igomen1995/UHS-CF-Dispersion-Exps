function MFM_data = import_MFM_data(filename,dataLines)
%  Import MFM data from a text file
%  Only keeps MFM2 data

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