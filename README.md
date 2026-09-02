# Kamp-2026-Solid-storage-biochar
Repo for paper on ammonia (NH3), methane (CH4), nitrous oxide (N2O) and CO2 emissions from stockpiled solid manure, comparing a pile covered with a biochar layer to an uncovered/no-biochar pile. Emission fluxes were derived from backward Lagrangian Stochastic (bLS) dispersion modelling combined with cavity ring-down spectroscopy (CRDS) gas concentration measurements. Measurements were conducted at Foulum in summer 2022.

# Maintainer
Jesper Kamp.
Contact information: <https://au.dk/jesper.kamp@bce.au.dk>

# Published paper
Kamp et al., 2026, Lower methane emissions from full-scale stockpiles of the solid fraction of separated digested slurry with biochar amendment. Biosystems Engineering. 
https://doi.org/10.1016/j.biosystemseng.2026.104585.

# Directory information

## scripts
`MAPI2022_calc.m`: MATLAB script that loads the pre-processed emission timetables in `data/` (already background-subtracted and QC-filtered), combines them with temperature, oxygen and weather data, computes summary statistics, and produces the emission and concentration plots. Run it directly in MATLAB; paths are resolved relative to the script's own location, so no path editing is required.

`load_Foulum_Weather_func.m`: helper function used by `MAPI2022_calc.m` to import the Foulum weather station data.

Note: this repo does not include the raw-data treatment pipeline (raw CRDS/bLS instrument output, calibration, and QC filtering) that produced the intermediate `.mat` files in `data/` — only the pre-processed data needed to reproduce the statistics and plots.

## data
- `TT_emis_N.mat`, `TT_emis_S.mat`: pre-processed, background-subtracted emission timetables for the North (no biochar) and South (biochar) piles.
- `TT_CRDS_BG_01_09_2023.mat`: background CRDS concentration timetable.
- `FoulumVejr_2305_1608.csv`: Foulum weather station data.
- `Oxygen content.xlsx`: oxygen content by depth for both piles.
- `Temperature/`: pile temperature logger files (`.dat`).

## output
Summary statistics (`stats.xlsx`) produced by `scripts/MAPI2022_calc.m`.

## plots
Figures produced by `scripts/MAPI2022_calc.m` (when `SAVE_FIG` is enabled in the script).
