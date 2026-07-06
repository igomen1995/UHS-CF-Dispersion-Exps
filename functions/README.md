# Functions Directory

This folder contains all MATLAB functions used by the transport-analysis workflows.

Functions are organized according to their role within the repository.

---

# Directory Purpose

The functions contained in this folder support:

- Data import
- Peng–Robinson EOS calculations
- Molecular diffusion estimation
- Transport and dispersion calculations
- Breakthrough-curve fitting
- Mixing correction
- Utility operations

---

# Import Functions

Functions used to import experimental and configuration data.

## Experimental Configuration

```text
import_inputExp
import_inputCal
import_inputExpsParams
import_inputExpsResults
```

Used by:

```text
main_Cal
main_Validation
main_DataExtract
main_Processing
```

---

## Peng–Robinson Input Files

```text
import_inputPR_params_pure
import_inputPR_params_BIP
```

Imports:

- Critical temperature (Tc)
- Critical pressure (Pc)
- Acentric factor (ω)
- Molecular weight
- Binary interaction parameter fits

---

## Diffusion Correlation Inputs

```text
import_input_params_diffusion_marrero
```

Imports Marrero correlation coefficients for binary diffusion calculations.

---

## Instrument Data Imports

```text
import_pumps_data
import_MFM_data
import_trans_data
import_PGD1_data
import_PGD2_data
```

Imports data from:

- Quizix pumps
- Bronkhorst mass flow meters
- Omega pressure transducers
- Cosmos gas detectors

---

# Peng–Robinson EOS Functions

Used by:

```text
main_PR
main_Validation
main_DataExtract
```

---

## Pure Component Parameters

```text
calc_ai_bi
```

Calculates Peng–Robinson pure-component parameters:

```text
ai
bi
```

from:

```text
Tc
Pc
ω
```

---

## Binary Interaction Parameters

```text
calc_BIP
```

Calculates:

```text
kij(T)
```

using fitted parameters:

```text
A12
B12
```

---

## Mixture Parameters

```text
calc_abmix
```

Calculates:

```text
aij
amix
bmix
```

using Peng–Robinson mixing rules.

---

## EOS Solver

```text
calc_Z
```

Solves the Peng–Robinson cubic equation and returns:

```text
Z
ρ
```

---

## Full EOS Interface

```text
densZ_PR
```

Returns:

```text
Density
Compressibility Factor
```

for specified:

```text
Pressure
Temperature
Composition
```

conditions.

---

# Diffusion Functions

## Marrero Correlation

```text
calc_diff_marrero
```

Calculates:

```text
D12
```

for binary gas mixtures.

Outputs:

```text
D12
dD12
```

---

# Tubing Transport Functions

## Taylor–Aris Dispersion

```text
KL_lines_taylor_aris
```

Calculates tubing dispersion coefficients:

```text
KL_lines
```

using:

```text
Velocity
Tube Radius
Molecular Diffusion
```

---

# Breakthrough-Curve Models

## Ogata–Banks Solution

```text
ob_step
```

Analytical ADE solution for step-input breakthrough curves.

---

## RTD Generation

```text
impulse_from_step
```

Generates residence-time distributions (RTDs) from breakthrough curves.

---

# Dispersion Fitting Functions

Used by:

```text
main_Processing
```

---

## Free Time-Delay Fit

```text
fit_dispersion_dt_nlinfit
```

Fits:

```text
KL
dt
```

simultaneously.

---

## Fixed Time-Delay Fit

```text
fit_dispersion_dtfixed_nlinfit
```

Fits:

```text
KL
```

for a specified:

```text
dt
```

---

## Result Builder

```text
buildRow_procResults
```

Creates standardized output tables containing:

```text
KL
dt
RMSE
R²
D0
Pe
```

---

# Dispersivity and Tortuosity Functions

Used by:

```text
main_Processing
```

---

## Dispersivity Estimation

```text
fit_dispersion_params_alpha
```

Fits:

```text
α
```

from:

```text
KL
Pe
```

relationships.

---

## Dispersivity and Tortuosity Estimation

```text
fit_dispersion_params_alpha_tau
```

Fits:

```text
α
τ
```

simultaneously.

---

## Supporting Models

```text
KL_Pe_alpha_only_model
KL_Pe_alpha_tau_model
```

Model equations used during transport-property estimation.

---

# Mixing-Correction Functions

Used by:

```text
main_ProcessingMixingCorrection
```

---

## Three-Segment Transport Model

```text
three_segment_model
```

Models the experimental system as:

```text
Upstream Tubing
      →
Core
      →
Downstream Tubing
```

using ADE transport.

---

## RTD Functions

```text
impulse_from_step
```

Used to estimate:

```text
Gup(t)
Gcore(t)
Gdown(t)
```

for variance decomposition.

---

# Utility Functions

## Time Trimming

```text
trim_time_P_Q
```

Identifies experimental periods corresponding to specified:

```text
Pressure
Flow Rate
```

targets.

---

# Workflow Dependencies

```text
main_PR
 ├── import_inputPR_params_pure
 ├── import_inputPR_params_BIP
 ├── calc_ai_bi
 ├── calc_BIP
 ├── calc_abmix
 └── calc_Z
```

```text
main_Cal
 ├── import functions
 ├── trim_time_P_Q
 ├── densZ_PR
 └── calibration functions
```

```text
main_Validation
 ├── import functions
 ├── densZ_PR
 └── calibration outputs
```

```text
main_DataExtract
 ├── import functions
 ├── densZ_PR
 ├── calc_diff_marrero
 └── KL_lines_taylor_aris
```

```text
main_Processing
 ├── fit_dispersion_dt_nlinfit
 ├── fit_dispersion_dtfixed_nlinfit
 ├── fit_dispersion_params_alpha
 ├── fit_dispersion_params_alpha_tau
 └── buildRow_procResults
```

```text
main_ProcessingMixingCorrection
 ├── three_segment_model
 ├── impulse_from_step
 ├── ob_step
 └── KL_lines_taylor_aris
```

---

# Notes

- All calculations use SI units internally whenever possible.
- Input and output units are specified within each main workflow script.
- The Peng–Robinson EOS implementation supports pure fluids and binary mixtures.
- The transport-analysis workflow assumes one-dimensional flow and ADE-based transport behavior.
- Mixing-correction functions are intended for detailed analysis of experimental-system dispersion effects.

---
Author: Ianna Gomez Mendez
