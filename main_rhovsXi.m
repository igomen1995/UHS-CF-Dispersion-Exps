%% main_rhoVsXi.m
% Author: Ianna Gomez Mendez (script assembled to extend main_DataExtract.m)
%
% PURPOSE
%   Build one combined figure with 4 density-vs-composition curves, all
%   generated with REFPROP (getMixtureProps_REFPROP), the same REFPROP
%   branch already used in main_DataExtract.m:
%
%       1) H2-CO2  @ 1160 psig, 40 C
%       2) H2-CH4  @ 1160 psig, 40 C
%       3) He-Xe   @  725 psig, 20 C
%       4) He-Xe   @  900 psig, 20 C
%
%   x-axis  : mole fraction of the lighter/injected component (H2 or He)
%   y-axis  : density normalized between the two pure-component endpoints,
%             rhoNorm = (rho - rho(x=0)) / (rho(x=1) - rho(x=0))
%             so every curve runs 0 -> 1 regardless of which pure fluid is
%             denser, the same convention used for normalized concentration
%             (CDi) elsewhere in this project.
%
%   All 4 series are legended with the ABSOLUTE pressure in MPa
%   (psig -> psia: +14.696 psi, then x 0.00689476 to MPa) and the
%   temperature in C.
%
% DEPENDENCIES
%   initREFPROP, getMixtureProps_REFPROP, fluidNameREFPROP
%
% For pure/mix property tables with error propagation (rho, Z, mu, D12 at
% x1=0, 0.5, 1), see the companion script main_fluidProps_errorProp.m.

%% INPUT

addpath('functions/');

x1 = 0:0.005:1;   % composition grid, shared by all 4 curves

% psig, T in C. psig -> MPa: (psig + 14.696) * 0.00689476
psig2MPa = @(psig) (psig + 14.696) * 0.00689476;

% NOTE: fluid strings here are the SHORT codes ("H2","He","Xe","CO2","CH4"),
% same convention as filedataExp.Fluid1/Fluid2 in main_DataExtract.m.
% fluidNameREFPROP() does the short-code -> REFPROP-library-name translation
% (H2->HYDROGEN, He->HELIUM, Xe->XENON, ...) INSIDE getFluidProps_REFPROP /
% getMixtureProps_REFPROP, so callers must NOT pass "HELIUM"/"XENON" directly.
cases = struct( ...
    'label',  {'H2-CO2', 'H2-CH4', 'He-Xe', 'He-Xe'}, ...
    'fl',     {{"H2","CO2"}, {"H2","CH4"}, {"He","Xe"}, {"He","Xe"}}, ...
    'P_psig', {1160, 1160, 725, 900}, ...
    'T_C',    {40, 40, 20, 20} );

mkdir('results/combined_rhoNorm_4curves');
pathExportAll = 'results/combined_rhoNorm_4curves/';

%% Pre-load shared inputs

RP = initREFPROP();

%% Compute rho(x1) for each case

results = struct();

for c = 1:numel(cases)

    fl    = cases(c).fl;
    P_MPa = psig2MPa(cases(c).P_psig);
    T_C   = cases(c).T_C;
    T_K   = T_C + 273.15;
    P_kPa = P_MPa*1000;

    rho = zeros(size(x1));
    Z   = zeros(size(x1));
    for i = 1:length(x1)
        z = [x1(i), 1-x1(i)];
        Mix = getMixtureProps_REFPROP(RP, {char(fl{1}), char(fl{2})}, z, T_K, P_kPa);
        rho(i) = Mix.rho;
        Z(i)   = Mix.Z;
    end

    % normalize density between the two pure-component endpoints (x1=0, x1=1)
    rho0 = rho(1);
    rho1 = rho(end);
    rhoNorm = (rho - rho0) / (rho1 - rho0);

    results(c).label   = cases(c).label;
    results(c).fl      = fl;
    results(c).P_MPa   = P_MPa;
    results(c).P_psig  = cases(c).P_psig;
    results(c).T_C     = T_C;
    results(c).x1      = x1;
    results(c).rho     = rho;
    results(c).rhoNorm = rhoNorm;
    results(c).Z       = Z;
end

%% Save table of results

allResults = table();
for c = 1:numel(results)
    n = numel(results(c).x1);
    allResults = [allResults; table( ...
        repmat({results(c).label}, n, 1), ...
        repmat(results(c).P_psig, n, 1), ...
        repmat(results(c).P_MPa, n, 1), ...
        repmat(results(c).T_C, n, 1), ...
        results(c).x1', results(c).rho', results(c).rhoNorm', ...
        'VariableNames', {'Pair','P_psig','P_MPa','T_C','x1','rho','rhoNorm'})]; %#ok<AGROW>
end
writetable(allResults, pathExportAll + "rhoNorm_4curves.xlsx");
save(pathExportAll + "rhoNorm_4curves.mat", 'results', 'allResults');

%% Plot

figure; hold on
colours = {[0.850 0.325 0.098],[0.494 0.184 0.556],[0.466 0.674 0.188],[0 0.447 0.741]};
markers = {'o','o','o','o'};

legendStr = cell(numel(results),1);
for c = 1:numel(results)
    scatter(results(c).x1, results(c).rhoNorm, 15, colours{c}, markers{c}, 'filled');
    legendStr{c} = sprintf('%s @ %.2f MPa, %d°C', results(c).label, results(c).P_MPa, results(c).T_C);
end
hold off

%% Virial EOS overlay for He-Xe (Hurly, Schmidt, Boyes & Moldover 1997,
%  Int. J. Thermophys. 18(3), 579-634) at 725 psig (within the paper's
%  stated range) and 900 psig (EXTRAPOLATED beyond it)
%
% Density virial EOS: P = R*T*rho_m*(1 + B(T)*rho_m + C(T)*rho_m^2)
% (Eq. 1), rho_m = molar density [mol/m^3].
%
% Mixing rules (Eq. 14), x1 = He, x2 = Xe:
%   B_mix = x1^2*B11 + 2*x1*x2*B12 + x2^2*B22
%   C_mix = x1^3*C111 + 3*x1^2*x2*C112 + 3*x1*x2^2*C122 + x2^3*C222
%
% Pure He,  Eq. 10-11 (ab initio, Aziz et al. potential), valid 210-400 K:
%   B11(T)  [cm^3/mol] = 11.885370 + 6.6508722e-3*T - 3.205894e-5*T^2 + 3.1354694e-8*T^3
%   C111(T) [cm^6/mol^2] = 44.2846 + 2.379099e4/T - 1.6689669e6/T^2
%   (NOTE: the source PDF's OCR text shows the last term of C111 also as
%    T^-1; given the paper's own 1/T-power-series convention (Eq. 15) and
%    that two distinct T^-1 terms would be redundant, this is read as a
%    typesetting artifact and coded here as T^-2 - flag this if you can
%    check it against a clean copy of Eq. 11.)
%
% Pure Xe, Eq. 12-13 (hard-core square-well fit), valid 210-400 K:
%   B22(T)  = b0*(1 - (lam^3-1)*Delta),  Delta = exp(eps/kB/T) - 1
%     b0 = 5.796870e-5 m^3/mol, lam = 1.693962, eps/kB = 181.76386 K
%   C222(T) = (1/8)*b0^2*(5 - c1*Delta - c2*Delta^2 - c3*Delta^3)
%     c1 = lam^6 - 18*lam^4 + 32*lam^3 - 15
%     c2 = 2*lam^6 - 36*lam^4 + 32*lam^3 + 18*lam^2 - 16
%     c3 = 6*lam^6 - 18*lam^4 + 18*lam^2 - 6
%     b0 = 7.573128e-5 m^6/mol^2, lam = 1.554699, eps/kB = 200.88133 K
%
% He-Xe interaction, Eq. 15, polynomial in 1/T, B,C in SI (m^3/mol, m^6/mol^2):
%   B12(T)  = 2.756941e-5 + 4.617880e-3/T - 1.741538/T^2 + 1.364453e2/T^3
%   C112(T) = -2.692605e-10 + 1.340259e-7/T
%   C122(T) =  4.984636e-10 + 2.256122e-7/T
%
% VALIDITY: the paper states an overall range of 0.5-5 MPa and 210-400 K
% for the He-Xe mixture fit (Burnett p(P,T) data went up to 5 MPa).
% 725 psig = 5.10 MPa is right at/just past that edge; 900 psig = 6.31 MPa
% is clearly beyond it - both are flagged in the plot (solid vs. dashed).

R = 8.314462618; % J/(mol.K)
MW_He = 4.002602e-3; % kg/mol
MW_Xe = 131.293e-3;  % kg/mol

B11_Hurly  = @(T) (11.885370 + 6.6508722e-3*T - 3.205894e-5*T.^2 + 3.1354694e-8*T.^3)*1e-6; % m3/mol
C111_Hurly = @(T) (44.2846 + 2.379099e4./T - 1.6689669e6./T.^2)*1e-12; % m6/mol2

B22_Hurly = @(T) local_B22_Xe(T);
C222_Hurly = @(T) local_C222_Xe(T);

B12_Hurly  = @(T) 2.756941e-5 + 4.617880e-3./T - 1.741538./T.^2 + 1.364453e2./T.^3;
C112_Hurly = @(T) -2.692605e-10 + 1.340259e-7./T;
C122_Hurly = @(T) 4.984636e-10 + 2.256122e-7./T;

virialCases = struct( ...
    'P_psig',   {725,        900}, ...
    'inRange',  {true,       false}, ...   % 725 psig = 5.10 MPa (~paper's 5 MPa limit); 900 psig = 6.31 MPa (extrapolated)
    'style',    {'-',        '--'}, ...
    'marker',   {'d',        '^'});

x1_virial = 0:0.05:1;   % coarser grid - a handful of overlay points, not the full density
T_C_HeXe  = 20;
T_K_HeXe  = T_C_HeXe + 273.15;

virialResults = struct();
hold on
for v = 1:numel(virialCases)
    P_MPa = psig2MPa(virialCases(v).P_psig);
    P_Pa  = P_MPa*1e6;

    rho_m = zeros(size(x1_virial));
    for k = 1:numel(x1_virial)
        x1v = x1_virial(k); x2v = 1 - x1v;
        Bmix = x1v^2*B11_Hurly(T_K_HeXe) + 2*x1v*x2v*B12_Hurly(T_K_HeXe) + x2v^2*B22_Hurly(T_K_HeXe);
        Cmix = x1v^3*C111_Hurly(T_K_HeXe) + 3*x1v^2*x2v*C112_Hurly(T_K_HeXe) ...
             + 3*x1v*x2v^2*C122_Hurly(T_K_HeXe) + x2v^3*C222_Hurly(T_K_HeXe);
        rho_m(k) = local_solve_virial_rho(P_Pa, T_K_HeXe, R, Bmix, Cmix);
    end

    MWmix = x1_virial*MW_He + (1-x1_virial)*MW_Xe;
    rho_mass = rho_m.*MWmix; % kg/m3
    Z_virial = P_Pa ./ (rho_m*R*T_K_HeXe); % compressibility, diagnostic only

    rhoNorm_v = (rho_mass - rho_mass(1)) / (rho_mass(end) - rho_mass(1));

    virialResults(v).P_psig   = virialCases(v).P_psig;
    virialResults(v).P_MPa    = P_MPa;
    virialResults(v).inRange  = virialCases(v).inRange;
    virialResults(v).x1       = x1_virial;
    virialResults(v).rho      = rho_mass;
    virialResults(v).rhoNorm  = rhoNorm_v;
    virialResults(v).Z        = Z_virial;

    % DIAGNOSTIC: the virial series (truncated at B,C) breaks down badly
    % near Xe's critical point (Tc=16.6 C, Pc=5.84 MPa), which sits right
    % on top of these He-Xe conditions (20 C, 5.1-6.3 MPa) on the Xe-rich
    % side (x1 -> 0). Z far from ~1 is the signature of that breakdown -
    % flag it instead of silently trusting the curve there.
    badIdx = find(Z_virial < 0.5 | Z_virial > 1.5);
    if ~isempty(badIdx)
        fprintf(['WARNING: virial EOS at P=%.0f psig gives Z outside [0.5,1.5] ' ...
            'for x1 in [%.2f, %.2f] (Xe-rich / near-critical region). ' ...
            'These points (and the x1=0 normalization endpoint they corrupt) ' ...
            'are NOT reliable - Xe''s critical point (16.6 C, 5.84 MPa) sits ' ...
            'right on top of this condition.\n'], ...
            virialCases(v).P_psig, min(x1_virial(badIdx)), max(x1_virial(badIdx)));
    end

    tag = '';
    if ~virialCases(v).inRange
        tag = ' (extrapolated)';
    end
    plot(x1_virial, rhoNorm_v, ['k' virialCases(v).style virialCases(v).marker], ...
        'MarkerFaceColor', 'k', 'MarkerSize', 5, 'LineWidth', 1);
    legendStr{end+1} = sprintf('Virial (Hurly 1997) He-Xe @ %.2f MPa%s', P_MPa, tag); %#ok<SAGROW>
end
hold off

save(pathExportAll + "virial_HeXe_Hurly1997.mat", 'virialResults');

%% Compare REFPROP vs. Hurly virial: percent deviation (uncertainty estimate)
%
% For each He-Xe pressure, interpolate the REFPROP rho(x1) curve (the fine
% x1 grid in `results`) onto the virial's coarser x1 grid, then compute the
% percent difference. This quantifies how much REFPROP's He-Xe density
% (computed with its default/unfitted combining rule - no departure
% function exists for He-Xe in HMX.BNC) differs from the independent
% Hurly et al. virial EOS - i.e., an empirical bound on the He-Xe
% mixing-rule uncertainty, the same comparison your advisor's
% recommendation was aimed at.
%
% Points where the virial Z falls outside [0.5, 1.5] (the Xe-rich,
% near-critical breakdown flagged above) are marked unreliable and
% excluded from the summary statistics, but still reported in the table
% so you can see where they are.

compareRows = table();

for v = 1:numel(virialResults)
    P_psig_v = virialResults(v).P_psig;

    % find the matching REFPROP (results) case at the same P_psig
    refIdx = find([results.P_psig] == P_psig_v & strcmp({results.label}, 'He-Xe'));
    if isempty(refIdx)
        warning('No matching REFPROP case found for P=%d psig - skipping comparison.', P_psig_v);
        continue
    end
    refIdx = refIdx(1);

    % interpolate REFPROP's fine-grid rho onto the virial's x1 grid
    rho_REFPROP_interp = interp1(results(refIdx).x1, results(refIdx).rho, virialResults(v).x1, 'linear');

    rho_virial = virialResults(v).rho;
    pctDiff = 100*(rho_REFPROP_interp - rho_virial) ./ rho_REFPROP_interp;

    reliable = virialResults(v).Z >= 0.5 & virialResults(v).Z <= 1.5;

    compareRows = [compareRows; table( ...
        repmat(P_psig_v, numel(virialResults(v).x1), 1), ...
        repmat(virialResults(v).P_MPa, numel(virialResults(v).x1), 1), ...
        repmat(virialResults(v).inRange, numel(virialResults(v).x1), 1), ...
        virialResults(v).x1', rho_REFPROP_interp', rho_virial', pctDiff', ...
        virialResults(v).Z', reliable', ...
        'VariableNames', {'P_psig','P_MPa','inRange','x1', ...
        'rho_REFPROP','rho_virial','pctDiff','Z_virial','reliable'})]; %#ok<AGROW>

    relRows = reliable;
    fprintf('\n--- REFPROP vs. Hurly virial, P = %d psig (%.2f MPa) ---\n', P_psig_v, virialResults(v).P_MPa);
    if any(relRows)
        fprintf('  reliable points (x1 in [%.2f, %.2f], Z in [0.5,1.5]): mean |%%diff| = %.2f%%, max |%%diff| = %.2f%%\n', ...
            min(virialResults(v).x1(relRows)), max(virialResults(v).x1(relRows)), ...
            mean(abs(pctDiff(relRows))), max(abs(pctDiff(relRows))));
    end
    if any(~relRows)
        fprintf('  UNRELIABLE points (near-critical Xe breakdown), x1 in [%.2f, %.2f]: %%diff ranges %.1f%% to %.1f%% (not meaningful, shown for reference only)\n', ...
            min(virialResults(v).x1(~relRows)), max(virialResults(v).x1(~relRows)), ...
            min(pctDiff(~relRows)), max(pctDiff(~relRows)));
    end
end

disp(compareRows)
writetable(compareRows, pathExportAll + "REFPROP_vs_Hurly_pctDiff.xlsx");
save(pathExportAll + "REFPROP_vs_Hurly_pctDiff.mat", 'compareRows');

%% Plot: percent deviation REFPROP vs. Hurly virial, vs. composition

figure; hold on
pColours = {[0.466 0.674 0.188], [0 0.447 0.741]}; % match He-Xe colours above
pLegend = cell(numel(virialResults),1);
for v = 1:numel(virialResults)
    rows_v = compareRows(compareRows.P_psig == virialResults(v).P_psig, :);
    rel = rows_v.reliable;
    unrel = ~rel;
    plot(rows_v.x1(rel), rows_v.pctDiff(rel), '-o', 'Color', pColours{v}, ...
        'MarkerFaceColor', pColours{v}, 'LineWidth', 1.3);
    plot(rows_v.x1(unrel), rows_v.pctDiff(unrel), ':o', 'Color', pColours{v}, ...
        'MarkerFaceColor', 'w', 'LineWidth', 1.0, 'HandleVisibility','off'); % dotted/hollow = unreliable, no separate legend entry
    pLegend{v} = sprintf('He-Xe @ %.2f MPa%s', virialResults(v).P_MPa, ...
        ternary_str(~virialResults(v).inRange, ' (extrapolated P)', ''));
end
yline(0, 'k-', 'HandleVisibility', 'off');
hold off
xlabel('x_1 (mole fraction He) [-]');
ylabel('% difference: (\rho_{REFPROP} - \rho_{virial}) / \rho_{REFPROP} \times 100');
title('REFPROP vs. Hurly (1997) virial EOS: density deviation (solid = reliable, dotted/hollow = near-critical breakdown)');
legend(pLegend, 'Location', 'best');
grid on
saveas(gcf, pathExportAll + "REFPROP_vs_Hurly_pctDiff", 'png');

%% Finish plot

xlabel('x_1 (mole fraction H_2 or He) [-]');
ylabel('\rho_{norm} [-]  (normalized between x_1=0 and x_1=1)');
title('Density vs. composition (REFPROP vs. Hurly 1997 virial): H_2-CO_2, H_2-CH_4, He-Xe');
legend(legendStr, 'Location', 'southeast');
grid on
saveas(gcf, pathExportAll + "rhoNorm_vs_x1_4curves", 'png');

%% local helpers

function C = local_C222_Xe(T)
b0 = 7.573128e-5; lam = 1.554699; epsk = 200.88133;
Delta = exp(epsk./T) - 1;
c1 = lam.^6 - 18*lam.^4 + 32*lam.^3 - 15;
c2 = 2*lam.^6 - 36*lam.^4 + 32*lam.^3 + 18*lam.^2 - 16;
c3 = 6*lam.^6 - 18*lam.^4 + 18*lam.^2 - 6;
C = (1/8)*b0.^2.*(5 - c1.*Delta - c2.*Delta.^2 - c3.*Delta.^3);
end

function B = local_B22_Xe(T)
b0 = 5.796870e-5; lam = 1.693962; epsk = 181.76386;
Delta = exp(epsk./T) - 1;
B = b0.*(1 - (lam.^3-1).*Delta);
end

function s = ternary_str(cond, strTrue, strFalse)
if cond
    s = strTrue;
else
    s = strFalse;
end
end

function rho_m = local_solve_virial_rho(P, T, R, B, C)
% Solve P = R*T*rho*(1 + B*rho + C*rho^2) for rho [mol/m3], i.e.
% R*T*C*rho^3 + R*T*B*rho^2 + R*T*rho - P = 0, picking the real root
% closest to the ideal-gas estimate.
coeffs = [R*T*C, R*T*B, R*T, -P];
r = roots(coeffs);
r = r(abs(imag(r)) < 1e-8);
r = real(r);
rho_ideal = P/(R*T);
[~, idx] = min(abs(r - rho_ideal));
rho_m = r(idx);
end