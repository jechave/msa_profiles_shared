#!/usr/bin/env Rscript
# fig_shap_relative_sd.R - Generate SHAP relative SD distribution figure
# Shows distribution of relative standard deviations for SHAP components

# Load required libraries
library(tidyverse)
library(ggplot2)
library(cowplot)
library(here)

# Source configuration and data preparation
source(here("src", "config.R"))
source(here("src", "data_prep.R"))

# Function to create SHAP relative SD distribution plot
plot_shap_relative_sd <- function(profiles) {
  
  # Calculate SD of SHAP components for all proteins
  shap_mad_data <- profiles %>%
    group_by(mcsa_id, pdb_chain) %>%
    summarise(
      a1 = first(a1),
      a2 = first(a2),
      sd_phi_mut = sd(phi_mut, na.rm = TRUE),
      sd_phi_stab = sd(phi_stab, na.rm = TRUE),
      sd_phi_act = sd(phi_act, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    # Filter out any rows with missing values
    filter(!is.na(a1) & !is.na(a2) & 
           !is.na(sd_phi_mut) & !is.na(sd_phi_stab) & !is.na(sd_phi_act)) %>%
    # Calculate total SD and relative contributions
    mutate(
      total_sd = sd_phi_mut + sd_phi_stab + sd_phi_act,
      prop_mut = sd_phi_mut / total_sd,
      prop_stab = sd_phi_stab / total_sd,
      prop_act = sd_phi_act / total_sd
    )
  
  # Prepare data for distribution plot
  variance_long <- shap_mad_data %>%
    select(mcsa_id, prop_mut, prop_stab, prop_act) %>%
    pivot_longer(cols = c(prop_mut, prop_stab, prop_act), 
                 names_to = "component", values_to = "proportion") %>%
    mutate(component = recode(component,
                             "prop_mut" = "Mutation",
                             "prop_stab" = "Stability",
                             "prop_act" = "Activity"),
           component = factor(component, levels = c("Mutation", "Stability", "Activity")))
  
  # Calculate summary statistics for each SHAP component
  component_stats <- variance_long %>%
    group_by(component) %>%
    summarise(
      n = n(),
      mean_prop = mean(proportion, na.rm = TRUE),
      sd_prop = sd(proportion, na.rm = TRUE),
      sem_prop = sd(proportion, na.rm = TRUE) / sqrt(n()),
      min_prop = min(proportion, na.rm = TRUE),
      max_prop = max(proportion, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    # Filter out any rows with missing values
    filter(!is.na(mean_prop) & !is.na(sd_prop))
  
  # Create the plot
  plot <- ggplot(variance_long, aes(x = component, y = proportion)) +
    # Add jittered points with component colors
    geom_jitter(aes(color = component), width = 0.1, alpha = ALPHA_SCATTER_POINTS, size = POINT_SIZE_DEFAULT) +
    # Add large mean points (no error bars)
    geom_point(data = component_stats, 
               aes(x = component, y = mean_prop, color = component),
               size = POINT_SIZE_LARGE, inherit.aes = FALSE) +
    # Add text annotations for mean ± sem and range
    geom_text(data = component_stats,
              aes(x = component, y = 0.9,
                  label = sprintf("%.2f ± %.2f\n(%.2f - %.2f)", 
                                 mean_prop, sem_prop,
                                 min_prop, max_prop)),
              vjust = 1, color = "black", lineheight = 0.9, size = ANNOTATION_TEXT_SIZE) +
    scale_color_manual(values = SHAP_COLORS) +
    labs(x = "Component", y = "Relative SD") +
    theme_cowplot(font_size = THEME_SIZE) +
    theme(legend.position = "none") +
    ylim(0, 1)
  
  return(plot)
}

# Main execution
if (!interactive()) {
  # Generate the figure
  fig <- plot_shap_relative_sd(profiles)
  
  # Save the figure
  output_file <- file.path(FIG_DIR, "shap_relative_sd.pdf")
  ggsave(output_file, fig, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = 300)
  
  # message("Figure saved to: ", output_file)
}