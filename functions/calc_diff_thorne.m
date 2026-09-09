function [D12CE_cm2min,dD12CE_cm2min,chi,dchi, D12TE_cm2min,dD12TE_cm2min] = ...
    calc_diff_thorne(fluid1,fluid2,z_vector,T_C,P_psig, ...
    sigma1,sigma2,eps1,eps2,dsigma1,dsigma2,deps1,deps2)

%CALC_DIFF_THORNE Calculate binary gas diffusion coefficients using
% Chapman-Enskog and Thorne-Enskog kinetic theories.
%
% Inputs
% ------
% fluid1, fluid2 : REFPROP fluid names
%
% z_vector       : Binary mixture composition [z1 z2]
%
% T_C            : Temperature [°C]
%
% P_psig         : Pressure [psig]
%
% sigma1,sigma2  : Lennard-Jones collision diameters [Å]
%
% eps1,eps2      : Lennard-Jones energy parameters (epsilon/kB) [K]
%
% Outputs
% -------
% D12CE_cm2min   : Chapman-Enskog mutual diffusion coefficient [cm²/min]
%
% D12TE_cm2min   : Thorne-Enskog mutual diffusion coefficient [cm²/min]
%
% Method
% ------
% 1. Fluid properties are obtained from REFPROP.
% 2. Number density is calculated from:
%
%       n = rho * NA / MW
%
%    where rho is mass density, MW is molecular weight, and
%    NA is Avogadro's number.
%
% 3. Mixed Lennard-Jones parameters are calculated using:
%
%       sigma12 = (sigma1 + sigma2)/2
%
%       eps12   = sqrt(eps1*eps2)
%
% 4. The diffusion collision integral (OmegaD) is computed using the
%    Neufeld correlation.
%
% 5. The Chapman-Enskog diffusion coefficient is calculated.
%
% 6. The Thorne-Enskog correction factor (chi) is evaluated to account
%    for finite-density effects.
%
% 7. The Thorne-Enskog diffusion coefficient is computed as:
%
%       D12TE = D12CE / chi
%
% Notes
% -----
% - REFPROP must be initialized and accessible.
% - sigma values are specified in angstroms [Å].
% - epsilon values correspond to epsilon/kB [K].
% - Number density is reported in molecules/cm³.
%
% References
% ----------
% Chapman and Cowling (1990)
% Neufeld et al. (1972)
% Kobeissi et al. (2025, 2026)

% Initialize REFPROP
RP = initREFPROP();

NA = 6.02214076e23; % molecules/mol % avogadro number
T = T_C + 273.15; % K
P = (P_psig + 14.7)/145; % MPa
P_atm = (P_psig + 14.7)/14.7; % atm
P_0_atm = 1;
P_0 = P_0_atm*14.7/145;
z1 = z_vector(1);
z2 = z_vector(2);

fluid1Prop = getMixtureProps_REFPROP(RP,...
    {char(fluid1),char(fluid2)},...
    [1 0],T,P*1000);

fluid2Prop = getMixtureProps_REFPROP(RP,...
    {char(fluid1),char(fluid2)},...
    [0 1],T,P*1000);

mix = getMixtureProps_REFPROP(RP,...
    {char(fluid1), char(fluid2)},...
    z_vector,T,P*1000);

mix0 = getMixtureProps_REFPROP(RP,...
    {char(fluid1), char(fluid2)},...
    z_vector,T,P_0*1000);

MW1 = fluid1Prop.MW*1000; % g/mol
MW2 = fluid2Prop.MW*1000; % g/mol
MWmix = mix.MW*1000; % g/mol

rhomix = mix.rho/1000; % g/cm3
rhomix_0 = mix0.rho/1000; % g/cm3

rhoNmix = rhomix*NA/MWmix;
rhoNmix_0 = rhomix_0*NA/MWmix;

sigma12 = (sigma1 + sigma2)/2;
eps12 = (eps1*eps2)^(1/2);
Tr = T/eps12;
omegaD = 1.06036/(Tr^0.15610) + 0.19300/exp(0.47635*Tr) + 1.03587/exp(1.52996*Tr) + 1.76474/exp(3.89411*Tr);

rhoN1 = z1*rhoNmix;
rhoN2 = z2*rhoNmix;

sigma1_cm = sigma1*(10^-8);
sigma2_cm = sigma2*(10^-8);
sigma12_cm = sigma12*(10^-8);

chi = 1 + (pi/12)*rhoN1*sigma1_cm^3*(8 - 3*sigma1_cm/sigma12_cm) ...
    + (pi/12)*rhoN2*sigma2_cm^3*(8 - 3*sigma2_cm/sigma12_cm);

D12CE_0 = (0.0018583*(((T^3)*((1/MW1)+(1/MW2)))^(1/2)))/(1*(sigma12^2)*omegaD); % Chapman-Enskog cm2/s P = 1 atm
D12CE_0_cm2min = D12CE_0*60; %cm2/min

D12CE = (0.0018583*(((T^3)*((1/MW1)+(1/MW2)))^(1/2)))/(P_atm*(sigma12^2)*omegaD); % Chapman-Enskog cm2/s % considering ideal gas law (low densities)
D12CE_cm2min = D12CE*60; %cm2/min

D12TE = (rhoNmix_0*D12CE_0)/(rhoNmix*chi); % Thorne-Enskog cm2/s
D12TE_cm2min = D12TE*60; %cm2/min

% % comment from here to D12TE if willing to test D thorne from D chapman (at
% % pressure using rhoNmix) divided by X
% % if including rhoNmix or rhomix the Z is included because the densitites
% % are run at high pressure
% % D12CE = (2.2646*(10^-5)*((T*((1/MW1)+(1/MW2)))^(1/2)))/(rhomix*(sigma12^2)*omegaD/MWmix); % Chapman-Enskog cm2/s % using c (number molecule in mol/cm3) = number density *NA or c = rhomix/MWmix
% % D12CE_cm2min = D12CE*60; %cm2/min
% 
% D12CE = (2.2646*(10^-5)*((T*((1/MW1)+(1/MW2)))^(1/2)))/(rhoNmix*(sigma12^2)*omegaD/NA); % Chapman-Enskog cm2/s % using number densitu (rhonNmix)
% D12CE_cm2min = D12CE*60; %cm2/min
% 
% D12TE = D12CE/chi; % Thorne-Enskog cm2/s
% D12TE_cm2min = D12TE*60; %cm2/min

% Uncertainty analysis to get uncertainty in D12
% sigma1 
sigma1_p = sigma1 + dsigma1;
sigma1_m = sigma1 - dsigma1;
[DCE_p,DTE_p,chi_p] = calc_D_local(sigma1_p,sigma2,eps1,eps2,...
    MW1,MW2,rhoNmix,rhoNmix_0,rhoN1,rhoN2,T,P_atm);
[DCE_m,DTE_m,chi_m] = calc_D_local(sigma1_m,sigma2,eps1,eps2,...
    MW1,MW2,rhoNmix,rhoNmix_0,rhoN1,rhoN2,T,P_atm);
dDCE_dsigma1 = (DCE_p - DCE_m)/(2*dsigma1);
dDTE_dsigma1 = (DTE_p - DTE_m)/(2*dsigma1);
dchi_dsigma1 = (chi_p - chi_m)/(2*dsigma1);

% sigma2 
sigma2_p = sigma2 + dsigma2;
sigma2_m = sigma2 - dsigma2;
[DCE_p,DTE_p,chi_p] = calc_D_local(sigma1,sigma2_p,eps1,eps2,...
    MW1,MW2,rhoNmix,rhoNmix_0,rhoN1,rhoN2,T,P_atm);
[DCE_m,DTE_m,chi_m] = calc_D_local(sigma1,sigma2_m,eps1,eps2,...
    MW1,MW2,rhoNmix,rhoNmix_0,rhoN1,rhoN2,T,P_atm);
dDCE_dsigma2 = (DCE_p - DCE_m)/(2*dsigma2);
dDTE_dsigma2 = (DTE_p - DTE_m)/(2*dsigma2);
dchi_dsigma2 = (chi_p - chi_m)/(2*dsigma2);

% eps1
eps1_p = eps1 + deps1;
eps1_m = eps1 - deps1;
[DCE_p,DTE_p] = calc_D_local(sigma1,sigma2,eps1_p,eps2,...
    MW1,MW2,rhoNmix,rhoNmix_0,rhoN1,rhoN2,T,P_atm);
[DCE_m,DTE_m] = calc_D_local(sigma1,sigma2,eps1_m,eps2,...
    MW1,MW2,rhoNmix,rhoNmix_0,rhoN1,rhoN2,T,P_atm);
dDCE_deps1 = (DCE_p - DCE_m)/(2*deps1);
dDTE_deps1 = (DTE_p - DTE_m)/(2*deps1);

% eps2
eps2_p = eps2 + deps2;
eps2_m = eps2 - deps2;
[DCE_p,DTE_p] = calc_D_local(sigma1,sigma2,eps1,eps2_p,...
    MW1,MW2,rhoNmix,rhoNmix_0,rhoN1,rhoN2,T,P_atm);
[DCE_m,DTE_m] = calc_D_local(sigma1,sigma2,eps1,eps2_m,...
    MW1,MW2,rhoNmix,rhoNmix_0,rhoN1,rhoN2,T,P_atm);
dDCE_deps2 = (DCE_p - DCE_m)/(2*deps2);
dDTE_deps2 = (DTE_p - DTE_m)/(2*deps2);

% Propagate uncertainty
dD12CE = sqrt( ...
    (dDCE_dsigma1*dsigma1)^2 + ...
    (dDCE_dsigma2*dsigma2)^2 + ...
    (dDCE_deps1*deps1)^2 + ...
    (dDCE_deps2*deps2)^2 );

dD12TE = sqrt( ...
    (dDTE_dsigma1*dsigma1)^2 + ...
    (dDTE_dsigma2*dsigma2)^2 + ...
    (dDTE_deps1*deps1)^2 + ...
    (dDTE_deps2*deps2)^2 );

dchi = sqrt( ...
    (dchi_dsigma1*dsigma1)^2 + ...
    (dchi_dsigma2*dsigma2)^2);


dD12CE_cm2min = dD12CE*60;
dD12TE_cm2min = dD12TE*60;

function [D12CE,D12TE,chi] = calc_D_local(sigma1,sigma2,eps1,eps2,...
    MW1,MW2,rhoNmix,rhoNmix_0,rhoN1,rhoN2,T,P_atm)

sigma12 = (sigma1 + sigma2)/2;
eps12 = sqrt(eps1*eps2);

Tr = T/eps12;

omegaD = 1.06036/(Tr^0.15610) + 0.19300/exp(0.47635*Tr) + 1.03587/exp(1.52996*Tr) + 1.76474/exp(3.89411*Tr);

% Chapman-Enskog at 1 atm
D12CE_0 = (0.0018583*(((T^3)*((1/MW1)+(1/MW2)))^(1/2)))/(1*(sigma12^2)*omegaD); % Chapman-Enskog cm2/s P = 1 atm

% Chapman-Enskog at P atm
D12CE = (0.0018583*(((T^3)*((1/MW1)+(1/MW2)))^(1/2)))/(P_atm*(sigma12^2)*omegaD); % Chapman-Enskog cm2/s P = 1 atm

sigma1_cm = sigma1*1e-8;
sigma2_cm = sigma2*1e-8;
sigma12_cm = sigma12*1e-8;

chi = 1 + (pi/12)*rhoN1*sigma1_cm^3*(8 - 3*sigma1_cm/sigma12_cm) ...
    + (pi/12)*rhoN2*sigma2_cm^3*(8 - 3*sigma2_cm/sigma12_cm);

% Berry / Thorne

D12TE = (rhoNmix_0*D12CE_0)/(rhoNmix*chi);

end
end