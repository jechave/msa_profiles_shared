# MSA Paper Figures - Reproducible Code

This repository contains the code and data necessary to reproduce all figures from the paper on Mutation-Stability-Activity (MSA) model analysis of neutral protein structure evolution.

## Paper Reference

*[Add your paper citation here when published]*

## Overview

The MSA model predicts structural divergence from sequence mutations by accounting for:
- **Stability selection** (via mutational ΔΔG values)  
- **Activity selection** (via mutational activation energy changes)

This repository generates **4 publication figures**:
1. **Figure 1**: MSA vs M12 correlation analysis
2. **Figure 2**: Model progression analysis (M0→MM→MS→MSA)
3. **Figure 3**: SHAP decomposition analysis 
4. **Figure 4**: SHAP parameter correlations

## Quick Start

### Prerequisites

Install required R packages:
```r
install.packages(c("tidyverse", "ggplot2", "cowplot", "patchwork", 
                  "ggExtra", "ggpubr", "here"))
```

### Generate Figures

```bash
# Generate all paper figures
make

# Or equivalently
make all
make paper
```

### View Results

Paper figures will be saved in the `figures/` directory:
- `figures/paper_fig1_msa_vs_m12.pdf`
- `figures/paper_fig2_model_progression.pdf`
- `figures/paper_fig3_shap_decomposition.pdf`
- `figures/paper_fig4_shap_correlations.pdf`

## File Structure

```
MSA-paper-figures/
├── README.md              # This file
├── Makefile               # Build system
├── requirements.txt       # R package dependencies
├── data/                  # Input data files
│   ├── profiles_msa.csv   # MSA model results
│   ├── profiles_ec2024.csv # Empirical data
│   └── dataset_ec2024.csv # Protein metadata
├── src/                   # Figure generation code
│   ├── config.R           # Configuration settings
│   ├── data_prep.R        # Data preparation
│   ├── fig_*.R            # Individual figure components
│   └── combine_paper_figures.R # Main figure generation
└── figures/               # Generated paper figures (PDF)
```

## Detailed Usage

### Generate Specific Figures

```bash
make paper_fig1    # MSA vs M12 correlation
make paper_fig2    # Model progression
make paper_fig3    # SHAP decomposition  
make paper_fig4    # SHAP correlations
```

### Customization

Edit `src/config.R` to modify:
- Color schemes
- Figure dimensions
- Text sizes
- Example proteins

### Data Description

- **profiles_msa.csv**: MSA model predictions and SHAP decompositions for 34 proteins
- **profiles_ec2024.csv**: Empirical structural divergence data from Echave & Carpentier (2024)
- **dataset_ec2024.csv**: Protein metadata including PDB chains and active sites

## System Requirements

- R (≥ 4.0)
- Required packages (see requirements.txt)
- ~50MB disk space

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make` | Generate all paper figures |
| `make all` | Generate all paper figures |
| `make paper` | Generate all paper figures |
| `make paper_figN` | Generate specific figure N |
| `make clean` | Remove all generated figures |
| `make help` | Show all available targets |

## Citation

If you use this code, please cite:

```
[Add paper citation here]
```

## Contact

[Add contact information]

## License

[Add license information]