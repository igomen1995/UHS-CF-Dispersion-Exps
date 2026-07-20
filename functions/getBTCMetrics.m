function BTC = getBTCMetrics(t,tD,C)

% GETBTCMETRICS Calculate descriptive breakthrough-curve (BTC) metrics.
%
% DESCRIPTION
%   Computes characteristic arrival times, front widths, statistical
%   moments, and late-time tailing metrics from a normalized breakthrough
%   curve (BTC). The function can be applied to both dimensional time and
%   dimensionless time coordinates.
%
% INPUTS
%   t   - Time vector [s].
%
%   tD  - Dimensionless time vector [-].
%         Examples:
%           PV injected
%           Pore-volume throughput
%           Dimensionless transport time
%
%   C   - Normalized concentration/composition vector [-].
%         Values should range from 0 to 1 and increase monotonically.
%
% OUTPUT
%   BTC - Structure containing BTC transport descriptors.
%
% CHARACTERISTIC TIMES
%   t16, t50, t84       - Times corresponding to C = 0.16, 0.50 and 0.84.
%   tD16, tD50, tD84    - Dimensionless times corresponding to
%                         C = 0.16, 0.50 and 0.84.
%
% FRONT WIDTH
%   widthSeconds        - BTC width defined as:
%
%                           t84 - t16
%
%   widthDimLess        - Dimensionless BTC width:
%
%                           tD84 - tD16
%
% CENTER OF MASS
%   tSeconds_cm         - First moment of the BTC in time.
%
%   tDimLess_cm         - First moment of the BTC in dimensionless time.
%
% VARIANCE
%   varSecondsSquare    - Full BTC variance [s²].
%
%   varDimLess          - Full dimensionless variance [-].
%
%   stdSeconds          - Standard deviation [s].
%
%   stdDimLess          - Dimensionless standard deviation [-].
%
% SKEWNESS
%   skew                - Dimensionless skewness of the BTC.
%
%   skewDimLess         - Dimensionless skewness in dimensionless time.
%
%   Interpretation:
%       skew < 0  : left-skewed BTC
%       skew = 0  : symmetric BTC
%       skew > 0  : right-skewed BTC
%
% CENTRAL MOMENTS (16-84%)
%   Statistics computed only over the central transition zone:
%
%       0.16 <= C <= 0.84
%
%   tSeconds_cmCentral
%   tDimLess_cmCentral
%   varSecondsCentral
%   varDimLessCentral
%
%   These metrics are less sensitive to late-time tailing and experimental
%   noise than the full-curve moments.
%
% TAIL METRICS
%   The late-time tail (C >= 0.84) is fitted to:
%
%       1 - C ~ exp(m * tD)
%
%   tailSlope           - Exponential decay slope.
%
%   tailTimeScale       - Characteristic tailing time:
%
%                           tau = -1/tailSlope
%
%   tailR2              - Coefficient of determination of the
%                         exponential fit.
%
% INTERPRETATION
%   widthDimLess
%       Quantifies breakthrough spreading.
%
%   skew
%       Quantifies BTC asymmetry.
%
%   varDimLessCentral
%       Quantifies spreading of the central front.
%
%   tailTimeScale
%       Quantifies persistence of the breakthrough tail.
%
% APPLICATIONS
%   Designed for:
%       - Gas breakthrough curves
%       - CT-derived concentration histories
%


% characteristic time
BTC.t16 = interp1(C,t,0.16,'linear','extrap');
BTC.t50 = interp1(C,t,0.5,'linear','extrap');
BTC.t84 = interp1(C,t,0.84,'linear','extrap');

BTC.tD16 = interp1(C,tD,0.16,'linear','extrap');
BTC.tD50 = interp1(C,tD,0.5,'linear','extrap');
BTC.tD84 = interp1(C,tD,0.84,'linear','extrap');

% BTC width
BTC.widthSeconds = BTC.t84 - BTC.t16;
BTC.widthDimLess = BTC.tD84 - BTC.tD16;

% center of mass
BTC.tSeconds_cm = trapz(t,t.*C)/trapz(t,C);
BTC.tDimLess_cm = trapz(tD,tD.*C)/trapz(tD,C);

% variance
BTC.varSecondsSquare = trapz(t,(t-BTC.tSeconds_cm).^2.*C)/trapz(t,C);
BTC.varDimLess = trapz(tD,(tD-BTC.tDimLess_cm).^2.*C)/trapz(tD,C);

BTC.stdSeconds = sqrt(BTC.varSecondsSquare);
BTC.stdDimLess = sqrt(BTC.varDimLess);

% skewness
BTC.skew = trapz(t,(t-BTC.tSeconds_cm).^3.*C)/(trapz(t,C)*BTC.stdSeconds^3);
BTC.skewDimLess = trapz(tD,(tD-BTC.tDimLess_cm).^3.*C)/(trapz(tD,C)*BTC.stdDimLess^3);

% Central variance (16-84%)

idxCentral = (C >= 0.16) & (C <= 0.84);

tCentral  = t(idxCentral);
tDCentral = tD(idxCentral);
CCentral  = C(idxCentral);

BTC.tSeconds_cmCentral = trapz(tCentral,tCentral.*CCentral)/trapz(tCentral,CCentral);
BTC.tDimLess_cmCentral = trapz(tDCentral,tDCentral.*CCentral)/trapz(tDCentral,CCentral);

BTC.varSecondsCentral = trapz(tCentral,(tCentral-BTC.tSeconds_cmCentral).^2.*CCentral)/trapz(tCentral,CCentral);
BTC.varDimLessCentral = trapz(tDCentral,(tDCentral-BTC.tDimLess_cmCentral).^2.*CCentral)/trapz(tDCentral,CCentral);

% Tail metrics

idxTail = C >= 0.84;

if nnz(idxTail) > 5

    tailTime  = tD(idxTail);
    tailConc  = 1 - C(idxTail);

    valid = tailConc > 0;

    tailTime = tailTime(valid);
    tailConc = tailConc(valid);

    p = polyfit(tailTime,log(tailConc),1);

    BTC.tailSlope = p(1);

    BTC.tailTimeScale = -1/p(1);

    BTC.tailR2 = 1 - sum((log(tailConc)-polyval(p,tailTime)).^2) /sum((log(tailConc)-mean(log(tailConc))).^2);

else

    BTC.tailSlope = NaN;
    BTC.tailTimeScale = NaN;
    BTC.tailR2 = NaN;

end

end


