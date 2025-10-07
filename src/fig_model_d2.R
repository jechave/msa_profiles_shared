#!/usr/bin/env Rscript
# fig_model_d2.R - Generate model D² summary figure
# Shows mean D² values with individual data points for MM, MS, MSA models

# Load required libraries
library(tidyverse)
library(ggplot2)
library(cowplot)
library(here)

# Source configuration and data preparation
source(here("src", "config.R"))
source(here("src", "data_prep.R"))

# Function to create model D² summary plot
plot_model_d2 <- function(model_deviance) {
  
  # Prepare explained deviance data (remove M0)
  progression_data <- model_deviance %>%
    select(mcsa_id, dev_expl_mm, dev_expl_ms, dev_expl_msa) %>%
    pivot_longer(cols = c(dev_expl_mm, dev_expl_ms, dev_expl_msa), 
                 names_to = "model", 
                 values_to = "dev_expl") %>%
    mutate(
      model = str_remove(model, "dev_expl_") %>% str_to_upper(),
      model = factor(model, levels = c("MM", "MS", "MSA"))
    )
  
  # Calculate mean, sd, sem, min, and max explained deviance for each model
  model_stats <- progression_data %>%
    group_by(model) %>%
    summarise(
      n = n(),
      mean_dev = mean(dev_expl, na.rm = TRUE),
      sd_dev = sd(dev_expl, na.rm = TRUE),
      sem_dev = sd(dev_expl, na.rm = TRUE) / sqrt(n()),
      min_dev = min(dev_expl, na.rm = TRUE),
      max_dev = max(dev_expl, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Calculate single annotation position above the highest point across all models
  # Use the maximum of all individual data points, not just means
  max_value <- max(progression_data$dev_expl, na.rm = TRUE)
  min_value <- min(progression_data$dev_expl, na.rm = TRUE)
  annotation_y_position <- max_value + 0.05 * (max_value - min_value)
  
  # Define colors (remove M0)
  model_colors_subset <- c(
    "MM" = "#FF8C00",
    "MS" = "#0000CD",
    "MSA" = "#C41E3A"
  )
  
  # Create plot
  plot <- ggplot(model_stats, aes(x = model, y = mean_dev, color = model)) +
    # Add jittered points from original data with model colors
    geom_jitter(data = progression_data, aes(x = model, y = dev_expl, color = model), 
                width = 0.1, alpha = ALPHA_SCATTER_POINTS, size = POINT_SIZE_DEFAULT, inherit.aes = FALSE) +
    # Add mean points only (no error bars)
    geom_point(aes(y = mean_dev), size = POINT_SIZE_LARGE) +
    # Add text annotations for mean ± sem (no range)
    geom_text(aes(x = model, 
                  label = sprintf("%.2f ± %.2f", mean_dev, sem_dev)),
              y = annotation_y_position, vjust = 0, color = "black", size = ANNOTATION_TEXT_SIZE) +
    scale_color_manual(values = model_colors_subset) +
    labs(x = "Model", 
         y = expression(D^2)) +
    # Use dynamic y-limits based on data
    ylim(min_value * 0.9, 
         annotation_y_position * 1.1) +
    theme_cowplot(font_size = THEME_SIZE) +
    theme(legend.position = "none")
  
  return(plot)
}

# Main execution
if (!interactive()) {
  # Generate the figure
  fig <- plot_model_d2(model_deviance)
  
  # Save the figure
  output_file <- file.path(FIG_DIR, "model_d2.pdf")
  ggsave(output_file, fig, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = 300)
  
  # message("Figure saved to: ", output_file)
}