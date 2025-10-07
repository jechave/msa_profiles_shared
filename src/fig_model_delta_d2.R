#!/usr/bin/env Rscript
# fig_model_delta_d2.R - Generate model delta D² progression figure
# Shows incremental D² contributions between successive models: m0→mm, mm→ms, ms→msa

# Load required libraries
library(tidyverse)
library(ggplot2)
library(cowplot)
library(here)

# Source configuration and data preparation
source(here("src", "config.R"))
source(here("src", "data_prep.R"))

# Function to create model delta D² progression plot
plot_model_delta_d2 <- function(model_deviance) {
  
  # Calculate delta D² values for each transition
  delta_data <- model_deviance %>%
    mutate(
      delta_d2_m0_to_mm = dev_expl_mm - 0,  # M0 baseline = 0
      delta_d2_mm_to_ms = dev_expl_ms - dev_expl_mm,
      delta_d2_ms_to_msa = dev_expl_msa - dev_expl_ms
    ) %>%
    select(mcsa_id, delta_d2_m0_to_mm, delta_d2_mm_to_ms, delta_d2_ms_to_msa) %>%
    pivot_longer(cols = c(delta_d2_m0_to_mm, delta_d2_mm_to_ms, delta_d2_ms_to_msa), 
                 names_to = "transition", 
                 values_to = "delta_d2") %>%
    mutate(
      transition = case_when(
        transition == "delta_d2_m0_to_mm" ~ "M0 %->% MM",
        transition == "delta_d2_mm_to_ms" ~ "MM %->% MS", 
        transition == "delta_d2_ms_to_msa" ~ "MS %->% MSA"
      ),
      transition = factor(transition, levels = c("M0 %->% MM", "MM %->% MS", "MS %->% MSA"))
    )
  
  # Calculate mean, sd, sem, min, and max delta D² for each transition
  transition_stats <- delta_data %>%
    group_by(transition) %>%
    summarise(
      n = n(),
      mean_delta = mean(delta_d2, na.rm = TRUE),
      sd_delta = sd(delta_d2, na.rm = TRUE),
      sem_delta = sd(delta_d2, na.rm = TRUE) / sqrt(n()),
      min_delta = min(delta_d2, na.rm = TRUE),
      max_delta = max(delta_d2, na.rm = TRUE),
      # Keep individual max for reference
      .groups = "keep"
    )
  
  # Calculate single annotation position above the highest point across all transitions
  annotation_y_position <- max(transition_stats$max_delta) + 0.05 * (max(delta_data$delta_d2, na.rm = TRUE) - min(delta_data$delta_d2, na.rm = TRUE))
  
  # Define colors for transitions
  transition_colors <- c(
    "M0 %->% MM" = "#FF8C00",
    "MM %->% MS" = "#0000CD",
    "MS %->% MSA" = "#C41E3A"
  )
  
  # Create plot
  plot <- ggplot(transition_stats, aes(x = transition, y = mean_delta, color = transition)) +
    # Add jittered points from original data with transition colors
    geom_jitter(data = delta_data, aes(x = transition, y = delta_d2, color = transition), 
                width = 0.1, alpha = ALPHA_SCATTER_POINTS, size = POINT_SIZE_DEFAULT, inherit.aes = FALSE) +
    # Add mean points only (no error bars)
    geom_point(aes(y = mean_delta), size = POINT_SIZE_LARGE) +
    # Add text annotations for mean ± sem and range
    geom_text(aes(x = transition, 
                  label = sprintf("%.2f ± %.2f\n(%.2f - %.2f)", 
                                 mean_delta, sem_delta,
                                 min_delta, max_delta)),
              y = annotation_y_position, vjust = 0, color = "black", lineheight = 0.9, size = ANNOTATION_TEXT_SIZE) +
    scale_color_manual(values = transition_colors) +
    scale_x_discrete(labels = function(x) parse(text = x)) +
    labs(x = "Model Transition", 
         y = expression(Delta~D^2)) +
    ylim(min(transition_stats$min_delta) * 0.9, 
         annotation_y_position * 1.15) +
    theme_cowplot(font_size = THEME_SIZE) +
    theme(legend.position = "none")
  
  return(plot)
}

# Main execution
if (!interactive()) {
  # Generate the figure
  fig <- plot_model_delta_d2(model_deviance)
  
  # Save the figure
  output_file <- file.path(FIG_DIR, "model_delta_d2.pdf")
  ggsave(output_file, fig, width = FIG_WIDTH, height = FIG_HEIGHT, dpi = 300)
  
  # message("Figure saved to: ", output_file)
}