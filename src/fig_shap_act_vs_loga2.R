#!/usr/bin/env Rscript
# fig_shap_act_vs_loga2.R - Generate SD(activity) vs log(aA) figure
# Shows relationship between activity constraint variation and activity parameter

# Load required libraries
library(tidyverse)
library(ggplot2)
library(cowplot)
library(ggpubr)
library(here)

# Source configuration and data preparation
source(here("src", "config.R"))
source(here("src", "data_prep.R"))

# Function to create activity vs log(a2) plot
plot_shap_act_vs_loga2 <- function(profiles) {
  
  # Calculate constraint variability metrics for each enzyme
  constraint_summary <- profiles %>%
    group_by(mcsa_id) %>%
    summarise(
      # MSA parameters
      log_aA = log(first(a2)),
      
      # Constraint SDs
      sd_phi_mut = sd(phi_mut, na.rm = TRUE),
      sd_phi_stab = sd(phi_stab, na.rm = TRUE),
      sd_phi_act = sd(phi_act, na.rm = TRUE),
      
      .groups = "drop"
    )
  
  # Determine common y-axis scale for all constraint variation panels
  y_min <- min(c(constraint_summary$sd_phi_mut, 
                 constraint_summary$sd_phi_stab, 
                 constraint_summary$sd_phi_act), na.rm = TRUE)
  y_max <- max(c(constraint_summary$sd_phi_mut, 
                 constraint_summary$sd_phi_stab, 
                 constraint_summary$sd_phi_act), na.rm = TRUE)
  
  # Create the plot
  plot <- ggplot(constraint_summary, aes(x = log_aA, y = sd_phi_act)) +
    geom_point(size = CORRELATION_POINT_SIZE, alpha = ALPHA_CORRELATION_POINTS, color = SHAP_COLORS["Activity"]) +
    geom_smooth(method = "gam", se = TRUE, color = SHAP_COLORS["Activity"], 
                linewidth = 1.2, alpha = ALPHA_REFERENCE_LINES) +
    stat_cor(method = "spearman", size = ANNOTATION_TEXT_SIZE, label.x.npc = 0.05, label.y.npc = 0.95,
             cor.coef.name = "rho", aes(label = paste(after_stat(r.label)))) +
    labs(x = "log(aA)", y = "SD(activity)") +
    ylim(y_min, y_max) +
    theme_cowplot(font_size = THEME_SIZE) +
    theme(plot.margin = margin(15, 15, 15, 15))
  
  return(plot)
}

# Main execution
if (!interactive()) {
  # Generate the figure
  fig <- plot_shap_act_vs_loga2(profiles)
  
  # Save the figure
  output_file <- file.path(FIG_DIR_INDIVIDUAL, "shap_act_vs_loga2.pdf")
  ggsave(output_file, fig, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = 300)
  
  message("Figure saved to: ", output_file)
}