#!/usr/bin/env Rscript
# combine_paper_figures.R - Combine individual figures for paper
# Creates multi-panel figures suitable for publication

library(tidyverse)
library(cowplot)
library(patchwork)
library(here)

# Source configuration
source(here("src", "config.R"))


# Paper Figure 1: MSA vs M12 Correlation
# Two-panel correlation analysis between MSA and M12 models
create_paper_fig1 <- function() {
  message("Creating Paper Figure 1: MSA vs M12 Correlation")
  
  # Source the individual figure script
  source(here("src", "fig_msa_vs_m12_correlation.R"))
  
  # Load data
  source(here("src", "data_prep.R"))
  
  # Generate the figure (already combined two-panel layout)
  combined <- plot_msa_vs_m12_correlation(profiles)
  
  # Save using config dimensions
  output_file <- file.path(FIG_DIR, "paper_fig1_msa_vs_m12.pdf")
  ggsave(output_file, combined, width = FIG_WIDTH_MULTI, height = FIG_HEIGHT, dpi = 300)
  message("Saved: ", output_file)
}

# Paper Figure 2: Model Progression Analysis
# Combines model profiles with summary statistics and correlations
create_paper_fig2 <- function() {
  message("Creating Paper Figure 2: Model Progression Analysis")
  
  # Source the individual figure scripts to get the plot objects
  source(here("src", "fig_model_profiles.R"))
  source(here("src", "fig_model_d2.R"))
  source(here("src", "fig_model_delta_d2.R"))
  
  # Load data
  source(here("src", "data_prep.R"))
  
  # Generate the panels
  panel_a <- plot_model_profiles(profiles, EXAMPLE_PROTEINS, model_deviance)
  panel_b <- plot_model_d2(model_deviance)
  panel_c <- plot_model_delta_d2(model_deviance)
  
  # Use patchwork for layout: A | B
  #                               A | C
  combined <- panel_a | (panel_b / panel_c)
  combined <- combined + plot_annotation(tag_levels = 'A')
  combined <- combined + plot_layout(widths = c(1.5, 1))
  
  # Save using config dimensions
  output_file <- file.path(FIG_DIR, "paper_fig2_model_progression.pdf")
  ggsave(output_file, combined, width = FIG_WIDTH_PAPER, height = FIG_HEIGHT_PAPER_TALL, dpi = 300)
  message("Saved: ", output_file)
}

# Paper Figure 3: SHAP Decomposition Analysis
# Combines SHAP profiles with distributions
create_paper_fig3 <- function() {
  message("Creating Paper Figure 3: SHAP Decomposition Analysis")
  
  # Source the individual figure scripts
  source(here("src", "fig_shap_profiles.R"))
  source(here("src", "fig_shap_sd.R"))
  source(here("src", "fig_shap_relative_sd.R"))
  
  # Load data
  source(here("src", "data_prep.R"))
  
  # Generate the panels
  example_families_shap <- EXAMPLE_PROTEINS
  panel_a <- plot_shap_profiles(profiles, shap_results, example_families_shap)
  panel_b <- plot_shap_sd(profiles)
  panel_c <- plot_shap_relative_sd(profiles)
  
  # Use patchwork for layout: A | B
  #                               A | C
  combined <- panel_a | (panel_b / panel_c)
  combined <- combined + plot_annotation(tag_levels = 'A')
  combined <- combined + plot_layout(widths = c(1.5, 1))
  
  # Save using config dimensions
  output_file <- file.path(FIG_DIR, "paper_fig3_shap_decomposition.pdf")
  ggsave(output_file, combined, width = FIG_WIDTH_PAPER, height = FIG_HEIGHT_PAPER_TALL, dpi = 300)
  message("Saved: ", output_file)
}

# Paper Figure 4: SHAP Parameter Correlations
# Shows correlations between SHAP components and biophysical parameters
create_paper_fig4 <- function() {
  message("Creating Paper Figure 4: SHAP Parameter Correlations")
  
  # Source the individual figure scripts
  source(here("src", "fig_shap_mut_vs_lrmsf.R"))
  source(here("src", "fig_shap_stab_vs_a1.R"))
  source(here("src", "fig_shap_act_vs_loga2.R"))
  
  # Load data
  source(here("src", "data_prep.R"))
  
  # Generate the panels
  panel_a <- plot_shap_mut_vs_lrmsf(profiles)
  panel_b <- plot_shap_stab_vs_a1(profiles)
  panel_c <- plot_shap_act_vs_loga2(profiles)
  
  # Use patchwork for horizontal layout: A | B | C
  combined <- panel_a | panel_b | panel_c
  combined <- combined + plot_annotation(tag_levels = 'A')
  
  # Save using config dimensions
  output_file <- file.path(FIG_DIR, "paper_fig4_shap_correlations.pdf")
  ggsave(output_file, combined, width = FIG_WIDTH_PAPER, height = FIG_HEIGHT_PAPER_SHORT, dpi = 300)
  message("Saved: ", output_file)
}

# Main execution
# Create output directory if it doesn't exist
if (!dir.exists(FIG_DIR)) {
  dir.create(FIG_DIR, recursive = TRUE)
}

# Generate paper figures
create_paper_fig1()
create_paper_fig2()
create_paper_fig3()
create_paper_fig4()

message("\nAll paper figures have been generated successfully!")