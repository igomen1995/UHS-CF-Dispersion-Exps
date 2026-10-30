function BTC = getBTCMetrics(t,tD,C,nSmooth,Csnap)

% GETBTCMETRICS Calculate descriptive breakthrough-curve (BTC) metrics.
%
% DESCRIPTION
%   Computes characteristic arrival times, front widths, statistical
%   moments, and late-time tailing metrics from a normalized step-injection
%   breakthrough curve (BTC). Applies to both dimensional and dimensionless
%   time.
%
%   The moments are those of the residence-time density E = dC/dt (the
%   pulse response of the step), NOT of C itself. Weighting by C gives a
%   "mean" and "variance" set by where the record stops (plateau length),
%   not by dispersion: for an ADE BTC with Pe = 500, the C-weighted std is
%   ~0.29 PV for a record ending at 2 PV and ~0.58 PV ending at 3 PV, while
%   the true std is sqrt(2/Pe) = 0.063 PV. With dC/dt weights the moments
%   match the ADE: std = sqrt(2/Pe), skew = 3*sqrt(2/Pe) (inverse Gaussian).
%   This makes skewDimLess directly comparable with skewADE in
%   main_dimlessTranspNo, and with weightedMoments (CT front pulses).
%
% INPUTS
%   t       - Time vector [s].
%   tD      - Dimensionless time vector [-] (e.g. PV injected).
%   C       - Normalized concentration vector [-], 0..1, rising.
%   nSmooth - (optional) moving-median window used to clean C before
%             differentiating (default 5; 1 = no smoothing).
%   Csnap   - (optional) plateau snap level (default 0.02): after cleaning,
%             C < Csnap is set to 0 and C > 1-Csnap to 1. Without it, noise
%             on the plateaus is ratcheted up by the monotonic cleaning into
%             spurious increments far from the front, which wrecks the higher
%             moments (synthetic ADE, Pe = 500, 0.5 % noise: skew -3.4 instead
%             of +0.19). With it, std is within ~3 % of sqrt(2/Pe) for noise
%             up to 1 %; the cut tails make skew/kurt somewhat low (Pe = 50:
%             skew 0.43 vs 0.60, kurt 2.7 vs 3.6) -- compare against the ADE
%             curve processed the same way, not the analytical value, when
%             the difference matters.
%
% OUTPUT
%   BTC - Structure with:
%
%   t16, t50, t84 / tD16, tD50, tD84
%                       - Times at C = 0.16, 0.50, 0.84 (cleaned curve).
%   widthSeconds, widthDimLess
%                       - t84 - t16 (= 2 sigma for a Gaussian front).
%   tSeconds_cm, tDimLess_cm
%                       - Mean residence time, first moment of dC/dt.
%   varSecondsSquare, varDimLess, stdSeconds, stdDimLess
%                       - Second central moment of dC/dt.
%   skew, skewDimLess   - Standardized third moment (0 symmetric, >0 late tail).
%   kurt, kurtDimLess   - Standardized fourth moment, RAW (3 = Gaussian).
%   ...Central          - Same moments using only the increments with
%                         0.16 <= C <= 0.84 (less sensitive to tail/noise;
%                         a truncated Gaussian gives std ~0.54 sigma here).
%   tailSlope, tailTimeScale, tailR2
%                       - Fit of 1 - C ~ exp(m tD) for C >= 0.84,
%                         tau = -1/m.
%   Cend                - Last C of the cleaned curve; if well below 1 the
%                         tail is truncated and std/skew/kurt are biased low.

if nargin < 4 || isempty(nSmooth), nSmooth = 5; end
if nargin < 5 || isempty(Csnap),   Csnap   = 0.02; end

% ---- clean: finite, sorted in time, unique times, clipped, monotonic ----
t = double(t(:));  tD = double(tD(:));  C = double(C(:));
ok = isfinite(t) & isfinite(tD) & isfinite(C);
t = t(ok);  tD = tD(ok);  C = C(ok);
[t, o] = sort(t);  tD = tD(o);  C = C(o);
[t, iu] = unique(t);  tD = tD(iu);  C = C(iu);
C = min(max(C, 0), 1);
if nSmooth > 1, C = movmedian(C, nSmooth); end
C = cummax(C);
C(C < Csnap) = 0;  C(C > 1 - Csnap) = 1;

BTC = emptyBTC();
if numel(t) < 5 || C(end) - C(1) <= 0, return, end
BTC.Cend = C(end);

% ---- characteristic times (interp on the strictly increasing part) ----
[Cu, iu] = unique(C, 'stable');
BTC.t16  = interp1(Cu, t(iu),  0.16, 'linear', NaN);
BTC.t50  = interp1(Cu, t(iu),  0.50, 'linear', NaN);
BTC.t84  = interp1(Cu, t(iu),  0.84, 'linear', NaN);
BTC.tD16 = interp1(Cu, tD(iu), 0.16, 'linear', NaN);
BTC.tD50 = interp1(Cu, tD(iu), 0.50, 'linear', NaN);
BTC.tD84 = interp1(Cu, tD(iu), 0.84, 'linear', NaN);

BTC.widthSeconds = BTC.t84 - BTC.t16;
BTC.widthDimLess = BTC.tD84 - BTC.tD16;

% ---- moments of E = dC/dt: weights = increments dC at mid-interval times ----
w   = diff(C);
tm  = 0.5*(t(1:end-1)  + t(2:end));
tDm = 0.5*(tD(1:end-1) + tD(2:end));
Cm  = 0.5*(C(1:end-1)  + C(2:end));

[BTC.tSeconds_cm, BTC.varSecondsSquare, BTC.skew, BTC.kurt] = mom(tm,  w);
[BTC.tDimLess_cm, BTC.varDimLess,       BTC.skewDimLess, BTC.kurtDimLess] = mom(tDm, w);
BTC.stdSeconds = sqrt(BTC.varSecondsSquare);
BTC.stdDimLess = sqrt(BTC.varDimLess);

% ---- central (16-84 %) moments ----
ic = Cm >= 0.16 & Cm <= 0.84;
[BTC.tSeconds_cmCentral, BTC.varSecondsCentral, BTC.skewCentral, BTC.kurtCentral] = mom(tm(ic),  w(ic));
[BTC.tDimLess_cmCentral, BTC.varDimLessCentral, BTC.skewDimLessCentral, BTC.kurtDimLessCentral] = mom(tDm(ic), w(ic));
BTC.stdSecondsCentral = sqrt(BTC.varSecondsCentral);
BTC.stdDimLessCentral = sqrt(BTC.varDimLessCentral);

% ---- tail: 1 - C ~ exp(m tD) for C >= 0.84 ----
it = C >= 0.84 & C < 1;   % (points snapped to 1 are excluded)
if nnz(it) > 5
    x = tD(it);  y = log(1 - C(it));
    p = polyfit(x, y, 1);
    BTC.tailSlope     = p(1);
    BTC.tailTimeScale = -1/p(1);
    BTC.tailR2        = 1 - sum((y - polyval(p, x)).^2)/sum((y - mean(y)).^2);
end

end

% ------------------------------------------------------------------------
function [mu, v, sk, ku] = mom(x, w)
% weighted mean, variance, skewness and raw kurtosis (discrete weights)
mu = NaN;  v = NaN;  sk = NaN;  ku = NaN;
w = max(w(:), 0);  x = x(:);
W = sum(w);
if numel(x) < 3 || W <= 0, return, end
mu = sum(x.*w)/W;
v  = sum((x - mu).^2.*w)/W;
if v <= 0, return, end
s  = sqrt(v);
sk = sum((x - mu).^3.*w)/W/s^3;
ku = sum((x - mu).^4.*w)/W/s^4;
end

function BTC = emptyBTC()
f = {'t16','t50','t84','tD16','tD50','tD84','widthSeconds','widthDimLess', ...
     'tSeconds_cm','tDimLess_cm','varSecondsSquare','varDimLess','stdSeconds','stdDimLess', ...
     'skew','skewDimLess','kurt','kurtDimLess', ...
     'tSeconds_cmCentral','tDimLess_cmCentral','varSecondsCentral','varDimLessCentral', ...
     'stdSecondsCentral','stdDimLessCentral','skewCentral','skewDimLessCentral', ...
     'kurtCentral','kurtDimLessCentral','tailSlope','tailTimeScale','tailR2','Cend'};
BTC = cell2struct(num2cell(NaN(numel(f),1)), f, 1);
end