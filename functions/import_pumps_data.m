function pumps_data = import_pumps_data(filename, workingPump, confPump, cushionPump, dataLines)
% Import pumps data from a text file given opts
% Working pump must be number
% This works if pump data is excatly the one described in the variable
% names

% If dataLines is not specified, define defaults
if nargin < 5
    dataLines = [7, Inf];
end

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 39); % Modify if data of pumps changes, e.g., another pump added

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% % Specify column names and types
opts.VariableNames = ["Date", "Time", "CumMin", "CumHrs", "LogMins", "LogHrs", "P_P1A", "P_P1B", "P_P2A", "P_P2B", "P_P3A", "P_P3B", "P_P1", "P_P2", "P_P3", "q_P1A", "q_P1B", "q_P2A", "q_P2B", "q_P3A", "q_P3B", "q_P1", "q_P2", "q_P3", "V_P1A", "V_P1B", "V_P2A", "V_P2B", "V_P3A", "V_P3B", "Vcum_P1A", "Vcum_P1B", "Vcum_P2A", "Vcum_P2B", "Vcum_P3A", "Vcum_P3B", "V_P1", "V_P2", "V_P3"];
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

% Variables names of working, conf and cushion pumps
% pressure
P_Pworking_string = "P_P"+workingPump;
P_Pconf_string = "P_P"+confPump;
P_Pcushion_string = "P_P"+cushionPump;
% rate
Q_Pworking_string = "q_P"+workingPump;
Q_Pconf_string = "q_P"+confPump;
Q_Pcushion_string = "q_P"+cushionPump;
% cumulative volume
V_Pworking_string = "V_P"+workingPump; 
V_Pconf_string = "V_P"+confPump;
V_Pcushion_string = "V_P"+cushionPump;

% Adding other fields/vars: TimeStamp, P_Pworking, P_Pcushion, P_Pconf,
% Q_Pworking, Q_Pcushion, Q_Pconf, CVol_Pworking, CVol_Pcushion, CVol_Pconf
TimeStamp = pumps_data.Date + timeofday(pumps_data.Time);
P_Pworking = pumps_data.(P_Pworking_string);
Q_Pworking = pumps_data.(Q_Pworking_string);
V_Pworking = pumps_data.(V_Pworking_string);

pumps_data = addvars(pumps_data,TimeStamp,P_Pworking,Q_Pworking,V_Pworking);
pumps_data = removevars(pumps_data,["Time","Date"]); % remove Date and Time independent fields

% Set time format which is same for all other data types
pumps_data.TimeStamp.Format = 'MM/dd/uuuu HH:mm:ss.SSS';

if isstring(confPump)
    P_Pconf = pumps_data.(P_Pconf_string);
    Q_Pconf = pumps_data.(Q_Pconf_string);
    V_Pconf = pumps_data.(V_Pconf_string);
    pumps_data = addvars(pumps_data,P_Pconf,Q_Pconf,V_Pconf);
end

if isstring(cushionPump)
    P_Pcushion = pumps_data.(P_Pcushion_string);
    Q_Pcushion = pumps_data.(Q_Pcushion_string);
    V_Pcushion = pumps_data.(V_Pcushion_string);
    pumps_data = addvars(pumps_data,P_Pcushion,Q_Pcushion,V_Pcushion);
end


end