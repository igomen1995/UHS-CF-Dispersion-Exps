%% main_PlotsIntegration.m
% Author: Ianna Gomez Mendez
%
% PURPOSE
%   Integrate and compare longitudinal dispersion measurements obtained
%   in the present study with previously published literature data.
%
%   The workflow generates transport-scaling plots commonly used in
%   porous-media transport studies and evaluates whether dispersion
%   behavior observed in the current experiments is consistent with
%   previously reported trends.
%
% -------------------------------------------------------------------------
% OBJECTIVE
% -------------------------------------------------------------------------
%
%   Compare:
%
%       Longitudinal dispersion coefficient
%
%           KL
%
%   and
%
%       Dimensionless dispersion
%
%           KL / D0
%
%   as functions of:
%
%       Interstitial velocity
%
%           ux
%
%   and
%
%       Peclet number
%
%           Pe
%
%   across multiple experimental studies.
%
% -------------------------------------------------------------------------
% INPUT
% -------------------------------------------------------------------------
%
% Literature database:
%
%       input_expsAll_results.xlsx
%
% The workbook contains one worksheet for each experimental study
% or dataset.
%
% -------------------------------------------------------------------------
% DATA IMPORT
% -------------------------------------------------------------------------
%
% For each worksheet:
%
%       Experimental transport results
%
%       Experimental conditions
%
% are imported using:
%
%       import_inputExpsResults
%
%       import_inputExpsParams
%
% -------------------------------------------------------------------------
% EXPERIMENTAL PARAMETERS
% -------------------------------------------------------------------------
%
% For each dataset:
%
%       Reference
%       Fluid system
%       Sample
%       Temperature
%       Pressure
%       Porosity
%       Dispersivity
%       Molecular diffusivity
%
% are stored.
%
% -------------------------------------------------------------------------
% VISUALIZATION STRATEGY
% -------------------------------------------------------------------------
%
% Symbols represent:
%
%       Sample type
%
% Colors represent:
%
%       Reference + Fluid system
%
% Transparency represents:
%
%       Pressure level
%
% allowing multiple studies to be compared within a single figure.
%
% -------------------------------------------------------------------------
% FIGURE 1:
% -------------------------------------------------------------------------
%
%       KL vs ux
%
% where:
%
%       KL   = longitudinal dispersion coefficient
%
%       ux   = interstitial velocity
%
% Units:
%
%       KL  [cm²/min]
%       ux  [cm/min]
%
% Purpose:
%
%       Evaluate dispersivity-controlled transport behavior.
%
%       Identify velocity-dependent dispersion trends.
%
%       Compare measured transport coefficients between studies.
%
% -------------------------------------------------------------------------
% FIGURE 2:
% -------------------------------------------------------------------------
%
%       KL/D0 vs Pe
%
% where:
%
%       D0 = molecular diffusion coefficient
%
%       Pe = ux*alpha/D0
%
% Purpose:
%
%       Collapse transport data onto a dimensionless framework.
%
%       Compare experiments conducted with different:
%
%           fluids
%           pressures
%           temperatures
%           porous media
%
% -------------------------------------------------------------------------
% DIMENSIONLESS ANALYSIS
% -------------------------------------------------------------------------
%
% The Peclet number is defined as:
%
%       Pe = ux alpha / D0
%
% and represents the ratio of:
%
%       advective transport
%
% to
%
%       diffusive transport
%
% -------------------------------------------------------------------------
%
% The dimensionless dispersion coefficient:
%
%       KL / D0
%
% quantifies enhancement of transport relative to molecular diffusion.
%
% -------------------------------------------------------------------------
% COLOR CODING
% -------------------------------------------------------------------------
%
% Color groups:
%
%       Ref + Fluid2
%
% Example:
%
%       H2–CO2
%       H2–N2
%       H2–CH4
%
% from different publications.
%
% -------------------------------------------------------------------------
% SYMBOL CODING
% -------------------------------------------------------------------------
%
% Marker shape identifies:
%
%       Rock sample
%
% Examples:
%
%       Bentheimer
%       Berea
%       Carbonate
%       Sandpack
%
% -------------------------------------------------------------------------
% TRANSPARENCY CODING
% -------------------------------------------------------------------------
%
% Marker transparency is scaled using:
%
%       Pressure
%
% allowing visual identification of pressure effects while preserving
% color grouping.
%
% -------------------------------------------------------------------------
% OUTPUT FIGURES
% -------------------------------------------------------------------------
%
% KL versus velocity:
%
%       KLvsVel-alpha_allLit.png
%
%       KLvsVel-alpha_allLit.fig
%
% -------------------------------------------------------------------------
%
% Dimensionless transport:
%
%       KLD0vsPe_allLit.png
%
%       KLD0vsPe_allLit.fig
%
% -------------------------------------------------------------------------
% SCIENTIFIC APPLICATIONS
% -------------------------------------------------------------------------
%
% Typical uses:
%
%       - Benchmarking new transport measurements
%
%       - Comparing dispersivities across porous media
%
%       - Evaluating pressure effects
%
%       - Evaluating fluid-composition effects
%
%       - Testing transport-scaling relationships
%
%       - Preparing publication-quality comparison figures
%
% -------------------------------------------------------------------------
% DEPENDENCIES
% -------------------------------------------------------------------------
%
% Import functions:
%
%       import_inputExpsResults
%
%       import_inputExpsParams
%
% -------------------------------------------------------------------------
% OUTPUT
% -------------------------------------------------------------------------
%
% Figures only
%
% No fitting or parameter estimation is performed.
%
% The script is intended exclusively for:
%
%       visualization
%       comparison
%       benchmarking
%
% of transport parameters obtained from multiple studies.
%
% -------------------------------------------------------------------------
% NOTES
% -------------------------------------------------------------------------
%
%   This script represents the final integration stage of the workflow:
%
%       main_PR
%           ↓
%       main_Cal
%           ↓
%       main_Validation
%           ↓
%       main_DataExtract
%           ↓
%       main_Processing
%           ↓
%       main_ProcessingMixingCorrection
%           ↓
%       main_PlotsIntegration
%
%   allowing direct comparison between internally generated transport
%   parameters and literature-reported datasets.