function pumps_data = import_pumps_data(filename, dataLines)
%  Import pumps data from a text file given opts

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [7, Inf];
end

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 39);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Date", "Time", "CumMin", "CumHrs", "LogMins", "LogHrs", "P_Cyl1A", "P_Cyl1B", "P_Cyl2A", "P_Cyl2B", "P_Cyl3A", "P_Cyl3B", "P_P1", "P_P2", "P_P3", "q_Cyl1A", "q_Cyl1B", "q_Cyl2A", "q_Cyl2B", "q_Cyl3A", "q_Cyl3B", "q_P1", "q_P2", "q_P3", "V_Cyl1A", "V_Cyl1B", "V_Cyl2A", "V_Cyl2B", "V_Cyl3A", "V_Cyl3B", "Vcum_Cyl1A", "Vcum_Cyl1B", "Vcum_Cyl2A", "Vcum_Cyl2B", "Vcum_Cyl3A", "Vcum_Cyl3B", "V_P1", "V_P2", "V_P3"];
opts.VariableTypes = ["datetime", "datetime", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "Date", "InputFormat", "MM/dd/yy");
opts = setvaropts(opts, "Time", "InputFormat", "HH:mm:ss");

% Import the data
pumps_data = readtable(filename, opts);
pumps_data = rmmissing(pumps_data); % Remove NaN values

% Preparing time data
pumps_data.Date.Format = 'MM/dd/uuuu';
pumps_data.Time.Format = 'HH:mm:ss';

% Adding time stamp field
TimeStamp = pumps_data.Date + timeofday(pumps_data.Time);
pumps_data = addvars(pumps_data,TimeStamp);
pumps_data = removevars(pumps_data,["Time","Date"]); % remove Date and Time independent fields

% Set time format which is same for all other data types
pumps_data.TimeStamp.Format = 'MM/dd/uuuu HH:mm:ss.SSS';

end