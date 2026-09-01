
function P = getProfileMetrics(x,C)

% normalize
C = (C-min(C))/(max(C)-min(C));

L = max(x)-min(x);

% front
P.x10 = interp1(C,x,0.1,'linear','extrap');
P.x50 = interp1(C,x,0.5,'linear','extrap');
P.x90 = interp1(C,x,0.9,'linear','extrap');

P.front = P.x50;

% mixing width
P.width = abs(P.x90-P.x10);

% normalized width
P.W = P.width/L;

% center of mass
P.xcm = trapz(x,x.*C)/trapz(x,C);

% variance
P.var = trapz(x,(x-P.xcm).^2.*C)/trapz(x,C);

P.std = sqrt(P.var);

% skewness
P.skew = trapz(x,(x-P.xcm).^3.*C)/ ...
    (trapz(x,C)*P.std^3);

end
