function [st,et] = trim_time_P_Q(Pdata,Pref,Ptol,time,Qdata,Qref,Qtol)
% outputs st and et to trim data

% input:
% Pdata (psig) and total
% Pref is P unique
% P tol is in relative values
% time is time stamp
% Qdata (ml/min) and total
% Qref is Q unique
% Qtol is in absolute values

% Pdata, time and Qdata must have same length 

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

