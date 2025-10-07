#!/usr/bin/env Rscript
# fig_shap_sd.R - Generate SHAP absolute SD distribution figure
# Shows distribution of absolute standard deviations for SHAP components

# Load required libraries
library(tidyverse)
library(ggplot2)
library(cowplot)
library(here)

# Source configuration and data preparation
source(here("src", "config.R"))
source(here("src", "data_prep.R"))

# Function to create SHAP absolute SD distribution plot
plot_shap_sd <- function(profiles) {
  
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
    # Keep absolute SD values (no additional calculations needed)
    identity()
  
  # Prepare data for distribution plot
  variance_long <- shap_mad_data %>%
    select(mcsa_id, sd_phi_mut, sd_phi_stab, sd_phi_act) %>%
    pivot_longer(cols = c(sd_phi_mut, sd_phi_stab, sd_phi_act), 
                 names_to = "component", values_to = "sd_value") %>%
    mutate(component = recode(component,
                             "sd_phi_mut" = "Mutation",
                             "sd_phi_stab" = "Stability",
                             "sd_phi_act" = "Activity"),
           component = factor(component, levels = c("Mutation", "Stability", "Activity")))
  
  # Calculate summary statistics for each SHAP component
  component_stats <- variance_long %>%
    group_by(component) %>%
    summarise(
      n = n(),
      mean_sd = mean(sd_value, na.rm = TRUE),
      sd_sd = sd(sd_value, na.rm = TRUE),
      sem_sd = sd(sd_value, na.rm = TRUE) / sqrt(n()),
      min_sd = min(sd_value, na.rm = TRUE),
      max_sd = max(sd_value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    # Filter out any rows with missing values
    filter(!is.na(mean_sd) & !is.na(sd_sd))
  
  # Calculate annotation position above the highest data point (not just error bars)
  max_data_value <- max(variance_long$sd_value, na.rm = TRUE)
  data_range <- max(variance_long$sd_value, na.rm = TRUE) - min(variance_long$sd_value, na.rm = TRUE)
  annotation_y_position <- max_data_value + 0.1 * data_range
  
  # Create the plot
  plot <- ggplot(variance_long, aes(x = component, y = sd_value)) +
    # Add jittered points with component colors
    geom_jitter(aes(color = component), width = 0.1, alpha = ALPHA_SCATTER_POINTS, size = POINT_SIZE_DEFAULT) +
    # Add large mean points (no error bars)
    geom_point(data = component_stats, 
               aes(x = component, y = mean_sd, color = component),
               size = POINT_SIZE_LARGE, inherit.aes = FALSE) +
    # Add text annotations for mean ± sem and range
    geom_text(data = component_stats,
              aes(x = component,
                  label = sprintf("%.2f ± %.2f\n(%.2f - %.2f)", 
                                 mean_sd, sem_sd,
                                 min_sd, max_sd)),
              y = annotation_y_position, vjust = 0, color = "black", lineheight = 0.9, size = ANNOTATION_TEXT_SIZE) +
    scale_color_manual(values = SHAP_COLORS) +
    labs(x = "Component", y = "SD") +
    ylim(min(variance_long$sd_value, na.rm = TRUE) * 0.9, 
         annotation_y_position * 1.15) +
    theme_cowplot(font_size = THEME_SIZE) +
    theme(legend.position = "none")
  
  return(plot)
}

# Main execution
if (!interactive()) {
  # Generate the figure
  fig <- plot_shap_sd(profiles)
  
  # Save the figure
  output_file <- file.path(FIG_DIR_INDIVIDUAL, "shap_sd.pdf")
  ggsave(output_file, fig, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = 300)
  
  message("Figure saved to: ", output_file)
}