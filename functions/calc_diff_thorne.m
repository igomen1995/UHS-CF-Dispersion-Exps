function [D12CE_cm2min,D12TE_cm2min] = calc_diff_thorne(fluid1,fluid2,z_vector,T_C,P_psig,eps1,eps2,sigma1,sigma2)
% First solve Champman enskog
% Then solve X
% Then solve Thorne
% be sure to have refprop initiated before
% eps is in eps/kb
% kb is boltzman constant
% rhoN is number density (molecules/cm3)
% for uncertainty analysis deps1,deps2,dsigma1,dsigma2

NA = 6.02214076e23; % molecules/mol % avogadro number
T = T_C + 273.15; % K
P = (P_psig + 14.7)/145; % MPa

fluid1Prop = getMixtureProps_REFPROP(RP,...
    {char(fluid1),char(fluid2)},...
    [1 0],T,P*1000);

fluid2Prop = getMixtureProps_REFPROP(RP,...
    {char(fluid1),char(fluid2)},...
    [0 1],T,P*1000);

mix = getMixtureProps_REFPROP(RP,...
    {char(fluid1), char(fluid2)},...
    z_vector,T,P*1000);

MW1 = fluid1Prop.MW*1000; % g/mol
MW2 = fluid2Prop.MW*1000; % g/mol
MWmix = mix.MW*1000; % g/mol

rho1 = fluid1Prop.rho/1000; % g/cm3
rho2 = fluid2Prop.rho*1000; % g/cm3
rhomix = mix.rho*1000; % g/cm3

rhoN1 = rho1*NA/MW1; % number density [molecules/cm3]
rhoN2 = rho2*NA/MW2;
rhoNmix = rhomix*NA/MWmix;

sigma12 = (sigma1 + sigma2)/2;
eps12 = (eps1*eps2)^(1/2);
Tr = T/eps12;
omegaD = 1.06036/(Tr^0.15610) ...
    + 0.19300/exp(0.47635*Tr) ...
    + 1.03587/exp(1.52996*Tr) ...
    + 1.76474/exp(3.89411*Tr);

D12CE = (2.2646*(10^-5)*((T*((1/MW1)+(1/MW2)))^(1/2)))/(rhoNmix*(sigma12^2)*omegaD/NA); % Chapman-Enskog cm2/s
D12CE_cm2min = D12CE*60; %cm2/min

chi = 1 + (pi/12)*rhoN1*(sigma1*(10^-8))^3*(8 - 3*(sigma1*(10^-8))/(sigma12*(10^-8))) ...
    + (pi/12)*rhoN2*(sigma2*(10^-8))^3*(8 - 3*(sigma2*(10^-8))/(sigma12*(10^-8)));

D12TE = D12CE/chi; % Thorne-Enskog cm2/s
D12TE_cm2min = D12TE*60; %cm2/min