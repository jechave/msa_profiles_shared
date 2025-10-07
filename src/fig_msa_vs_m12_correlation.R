#!/usr/bin/env Rscript
# fig_msa_vs_m12_correlation.R - Generate MSA vs M12 correlation figure
# Two-panel figure: scatter plot with marginal histograms + histogram

# Load required libraries
library(tidyverse)
library(ggplot2)
library(cowplot)
library(ggExtra)
library(here)

# Source configuration and data preparation
source(here("src", "config.R"))
source(here("src", "data_prep.R"))

# Function to create MSA vs M12 correlation figure
plot_msa_vs_m12_correlation <- function(profiles) {
  
  # Normalize the data (subtract mean per protein)
  profiles_norm <- profiles %>%
    group_by(mcsa_id) %>%
    mutate(
      nlrmsd_obs = lrmsd_obs - mean(lrmsd_obs, na.rm = TRUE),
      nlrmsd_msa = lrmsd_msa - mean(lrmsd_msa, na.rm = TRUE),
      nlrmsd_fit12 = lrmsd_fit12 - mean(lrmsd_fit12, na.rm = TRUE)
    ) %>%
    ungroup()
  
  # Calculate R values per protein
  r_values_per_protein <- profiles_norm %>%
    group_by(mcsa_id) %>%
    summarise(
      r_msa_obs = cor(nlrmsd_msa, nlrmsd_obs, use = "complete.obs"),
      r_fit12_obs = cor(nlrmsd_fit12, nlrmsd_obs, use = "complete.obs"),
      r_fit12_msa = cor(nlrmsd_fit12, nlrmsd_msa, use = "complete.obs"),
      .groups = "drop"
    )
  
  # Calculate summary statistics for annotations
  r_msa_obs_stats <- r_values_per_protein %>%
    summarise(
      mean_r = mean(r_msa_obs, na.rm = TRUE),
      sem_r = sd(r_msa_obs, na.rm = TRUE) / sqrt(n()),
      min_r = min(r_msa_obs, na.rm = TRUE),
      max_r = max(r_msa_obs, na.rm = TRUE)
    ) %>%
    mutate(annotation = paste0("R(MSA,Obs): ", round(mean_r, 2), " ± ", round(sem_r, 2), 
                              " (", round(min_r, 2), "-", round(max_r, 2), ")"))
  
  r_fit12_obs_stats <- r_values_per_protein %>%
    summarise(
      mean_r = mean(r_fit12_obs, na.rm = TRUE),
      sem_r = sd(r_fit12_obs, na.rm = TRUE) / sqrt(n()),
      min_r = min(r_fit12_obs, na.rm = TRUE),
      max_r = max(r_fit12_obs, na.rm = TRUE)
    ) %>%
    mutate(annotation = paste0("R(M12,Obs): ", round(mean_r, 2), " ± ", round(sem_r, 2), 
                              " (", round(min_r, 2), "-", round(max_r, 2), ")"))
  
  r_fit12_msa_stats <- r_values_per_protein %>%
    summarise(
      mean_r = mean(r_fit12_msa, na.rm = TRUE),
      sem_r = sd(r_fit12_msa, na.rm = TRUE) / sqrt(n()),
      min_r = min(r_fit12_msa, na.rm = TRUE),
      max_r = max(r_fit12_msa, na.rm = TRUE)
    ) %>%
    mutate(annotation = paste0("R(MSA,M12): ", round(mean_r, 2), " ± ", round(sem_r, 2), 
                              " (", round(min_r, 2), "-", round(max_r, 2), ")"))
  
  # Panel 1: Scatter plot
  panel_scatter <- ggplot(r_values_per_protein, aes(x = r_fit12_obs, y = r_msa_obs)) +
    geom_point(alpha = ALPHA_CORRELATION_POINTS, size = CORRELATION_POINT_SIZE) +
    geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
    labs(x = "R(M12, Obs)", y = "R(MSA, Obs)") +
    theme_cowplot(font_size = THEME_SIZE) +
    theme(plot.margin = margin(t = 5, r = 5, b = 5, l = 5)) +
    xlim(0, 1) + ylim(0, 1) + coord_equal() +
    annotate("text", x = -Inf, y = Inf, label = r_msa_obs_stats$annotation, 
             hjust = -0.1, vjust = 1.1, size = ANNOTATION_TEXT_SIZE) +
    annotate("text", x = -Inf, y = Inf, label = r_fit12_obs_stats$annotation, 
             hjust = -0.1, vjust = 3.2, size = ANNOTATION_TEXT_SIZE)
  
  # Add marginal histograms using ggExtra
  panel1_with_margins <- ggMarginal(panel_scatter, type = "histogram", 
                                  fill = "gray", alpha = 0.7, bins = 10)
  
  # Panel 2: Histogram of R(MSA,M12)
  panel_histogram <- ggplot(r_values_per_protein, aes(x = r_fit12_msa)) +
    geom_histogram(bins = 10, fill = "gray", alpha = 0.7, color = "black") +
    geom_vline(xintercept = r_fit12_msa_stats$mean_r, color = "red", linetype = "dashed", linewidth = 1) +
    labs(x = "R(MSA, M12)", y = "Count") +
    theme_cowplot(font_size = THEME_SIZE) +
    theme(plot.margin = margin(t = 5, r = 5, b = 5, l = 5)) +
    annotate("text", x = 0.7, y = Inf, label = r_fit12_msa_stats$annotation, 
             hjust = 0, vjust = 1.2, size = ANNOTATION_TEXT_SIZE)
  
  # Combine panels side-by-side using cowplot
  combined_figure <- plot_grid(panel1_with_margins, panel_histogram, ncol = 2, 
                              rel_widths = c(1, 0.8), labels = c("A", "B"))
  
  return(combined_figure)
}

# Main execution
if (!interactive()) {
  # Generate the figure
  fig <- plot_msa_vs_m12_correlation(profiles)
  
  # Save the figure
  output_file <- file.path(FIG_DIR_INDIVIDUAL, "msa_vs_m12_correlation.pdf")
  ggsave(output_file, fig, width = FIG_WIDTH_MULTI, height = FIG_HEIGHT, dpi = 300)
  
  message("Figure saved to: ", output_file)
}