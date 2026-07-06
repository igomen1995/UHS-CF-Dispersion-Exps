function [st,et] = trim_time_P_Q(Pdata,Pref,Ptol,time,Qdata,Qref,Qtol)

%TRIM_TIME_P_Q Identify time intervals matching target pressure and flow rate.
%
%   [ST,ET] = TRIM_TIME_P_Q(PDATA,PREF,PTOL,TIME,...
%                           QDATA,QREF,QTOL)
%   determines the start and end times of intervals where both pressure
%   and flow-rate measurements satisfy specified target values within
%   user-defined tolerances.
%
%   The function is intended for automatically identifying steady-state
%   operating periods in experimental datasets, allowing subsequent data
%   processing to be restricted to intervals with approximately constant
%   pressure and flow rate.
%
%   INPUTS
%       Pdata
%           Measured pressure data [psig]
%
%       Pref
%           Target or reference pressure [psig]
%
%       Ptol
%           Relative pressure tolerance [-]
%
%           Pressure is considered acceptable when:
%
%               abs(Pdata-Pref)/(Pref+14.7) < Ptol
%
%       time
%           Time vector (datetime array)
%
%       Qdata
%           Measured flow-rate data [mL/min]
%
%       Qref
%           Target or reference flow rate [mL/min]
%
%       Qtol
%           Absolute flow-rate tolerance [mL/min]
%
%           Flow rate is considered acceptable when:
%
%               abs(Qdata-Qref) < Qtol
%
%   OUTPUTS
%       st
%           Start times of intervals satisfying both pressure and
%           flow-rate criteria
%
%       et
%           End times of intervals satisfying both pressure and flow-rate
%           criteria
%
%   METHOD
%       A logical mask is first constructed:
%
%           idx = PressureCondition AND FlowCondition
%
%       where:
%
%           PressureCondition:
%
%               abs(P-Pref)/(Pref+14.7) < Ptol
%
%           FlowCondition:
%
%               abs(Q-Qref) < Qtol
%
%       The function then identifies transitions in the logical mask:
%
%           0 -> 1   Start of interval
%
%           1 -> 0   End of interval
%
%       and returns the corresponding timestamps.
%
%   PHYSICAL INTERPRETATION
%       The identified intervals represent periods where the experimental
%       system operated near specified pressure and flow-rate conditions.
%
%       Typical applications include:
%
%           - Steady-state flow analysis
%           - Experiment segmentation
%           - Data trimming
%           - Calibration-period identification
%           - Breakthrough-curve preprocessing
%
%   NOTES
%       - Pdata, Qdata, and time must have identical lengths.
%       - Multiple matching intervals may be returned.
%       - If no interval satisfies the criteria:
%
%             st = []
%             et = []
%
%       - Pressure tolerance is evaluated relative to absolute pressure:
%
%             Pref + 14.7
%
%         converting gauge pressure to an approximate absolute-pressure
%         basis.
%
%   EXAMPLE
%       [st,et] = trim_time_P_Q(P,...
%                               500,...
%                               0.05,...
%                               TimeStamp,...
%                               Q,...
%                               50,...
%                               2);
%
%       fprintf('Start: %s\n',string(st))
%       fprintf('End  : %s\n',string(et))
%
%   See also DATETIME, FIND.

idx_P_Q = (abs(Pdata - Pref)./(Pref+14.7)<Ptol)&(abs(Qdata - Qref)<Qtol);

    if any(idx_P_Q ~= 0) % if that interval exists
    
        idx_P_Q_aux1 = [0;idx_P_Q(1:end-1)];
        idx_P_Q_aux2 = [idx_P_Q(2:end);0;];
        idx_diff1 = idx_P_Q - idx_P_Q_aux1; % outputs 1 in st
        idx_diff2 = idx_P_Q - idx_P_Q_aux2; % outputs 1 in et
    
        % find time stap to trim
        st = time(idx_diff1 == 1);
        et = time(idx_diff2 == 1);
    
    else

        st = [];
        et = [];

    end

end

