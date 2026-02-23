# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Reproducible figure generation for the paper: Echave & Carpentier (2025), "Three biophysical constraints determine the variation of structural divergence among residues in enzyme evolution." The MSA (Mutation-Stability-Activity) model predicts structural divergence from sequence mutations via stability and activity selection.

## Build Commands

```bash
make              # Generate all 4 paper figures
make paper_fig1   # Figure 1: MSA vs M12 correlation
make paper_fig2   # Figure 2: Model progression (M0→MM→MS→MSA)
make paper_fig3   # Figure 3: SHAP decomposition
make paper_fig4   # Figure 4: SHAP parameter correlations
make clean        # Remove all generated figures
```

All figures are generated via `Rscript src/combine_paper_figures.R`. Individual `make paper_figN` targets still run the full script (the Makefile treats all 4 PDFs as co-outputs of a single recipe).

## Architecture

**Entry point:** `src/combine_paper_figures.R` — orchestrates all figure generation. It calls `create_paper_fig1()` through `create_paper_fig4()`, each of which:
1. `source()`s the relevant `src/fig_*.R` scripts to load plot functions
2. `source()`s `src/data_prep.R` to load prepared data objects
3. Composes panels using `patchwork` or `cowplot::plot_grid`
4. Saves to `figures/paper_fig*.pdf` via `ggsave`

**Data pipeline:**
- `src/shared_data_preparation.R` — loads CSV data, joins MSA predictions with empirical profiles, computes model performance metrics. Creates global objects: `dataset`, `profiles`, `model_dev_expl`
- `src/data_prep.R` — sources `shared_data_preparation.R`, then adds `model_deviance` (variance-based D² metrics) and `shap_results` (SHAP decomposition renaming)
- `src/config.R` — all shared constants: colors, dimensions, theme sizes, alpha values, example protein IDs

**Figure scripts** (`src/fig_*.R`) each export a single `plot_*()` function that takes data objects and returns a ggplot. They also have standalone execution blocks (`if (!interactive()) { ... }`) for individual testing.

**Key data objects flowing through the pipeline:**
- `profiles` — main tibble with per-site MSA predictions, SHAP values, empirical observations across 34 proteins
- `model_deviance` — per-protein summary of explained deviance (D²) for model variants
- `shap_results` — SHAP decomposition values (mutation, stability, activity components)

## Conventions

- R (≥ 4.0) with tidyverse ecosystem. Plotting uses ggplot2 + cowplot + patchwork.
- File paths use `here::here()` for project-relative resolution.
- Visual constants (colors, sizes, alpha) are centralized in `config.R` — use these instead of hardcoding values.
- Figure scripts define `plot_*()` functions rather than generating plots as side effects.
- The 3 example proteins for profile plots are configured in `config.R` as `EXAMPLE_PROTEINS`.

## Data Files

- `data/profiles_msa.csv` — MSA model predictions, parameters (a1, a2), and SHAP decompositions
- `data/profiles_ec2024.csv` — empirical structural divergence data (renamed as `lrmsd_obs`)
- `data/dataset_ec2024.csv` — protein metadata (PDB chains, active sites)
