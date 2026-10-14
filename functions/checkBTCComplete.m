function [ok, C, t, tD] = checkBTCComplete(C, t, tD, Cmin, Cmax, minPtsInside)
% Converts cell/empty columns to numeric, removes NaNs, sorts by time and
% checks that the BTC spans Cmin..Cmax with enough points in between.
toNum = @(x) iif(iscell(x), @() cellfun(@scalarOrNaN, x), @() double(x));
C  = toNum(C);  t = toNum(t);  tD = toNum(tD);

good = ~isnan(C) & ~isnan(t);
C = C(good); t = t(good); tD = tD(good);
[t, ord] = sort(t); C = C(ord); tD = tD(ord);

nInside = sum(C >= Cmin & C <= Cmax);
ok = ~isempty(C) && min(C) <= Cmin && max(C) >= Cmax && nInside >= minPtsInside;
end

function v = scalarOrNaN(x)
if isnumeric(x) && isscalar(x), v = double(x); else, v = NaN; end
end

function out = iif(cond, a, b)
if cond, out = a(); else, out = b(); end
end