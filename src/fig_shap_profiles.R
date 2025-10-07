#!/usr/bin/env Rscript
# fig_shap_profiles.R - Generate SHAP decomposition profiles figure
# Shows mutation, stability, and activity components across residue positions

# Load required libraries
library(tidyverse)
library(ggplot2)
library(cowplot)
library(here)

# Source configuration and data preparation
source(here("src", "config.R"))
source(here("src", "data_prep.R"))

# Function to plot SHAP profiles
plot_shap_profiles <- function(profiles, shap_results, example_families) {
  
  # Filter the data for the selected families
  profiles_examples <- profiles %>%
    filter(mcsa_id %in% example_families)
  
  # Normalize SHAP components by subtracting their means and dividing by overall SD
  profiles_examples <- profiles_examples %>%
    group_by(mcsa_id) %>%
    mutate(
      overall_sd = sd(phi_mut, na.rm = TRUE) + sd(phi_stab, na.rm = TRUE) + sd(phi_act, na.rm = TRUE),
      phi_mut = (phi_mut - mean(phi_mut, na.rm = TRUE)) / overall_sd,
      phi_stab = (phi_stab - mean(phi_stab, na.rm = TRUE)) / overall_sd,
      phi_act = (phi_act - mean(phi_act, na.rm = TRUE)) / overall_sd
    ) %>%
    select(-overall_sd) %>%
    ungroup()
  
  # Ensure the mcsa_id factor levels are in the specified order
  profiles_examples <- profiles_examples %>%
    mutate(mcsa_id = factor(mcsa_id, levels = example_families))
  
  # Get active site positions (where dactive == 0)
  active_sites <- profiles_examples %>%
    filter(dactive == 0) %>%
    select(mcsa_id, site) %>%
    distinct()
  
  # Reshape the data for line plot
  profiles_long <- profiles_examples %>%
    select(mcsa_id, site, phi_mut, phi_stab, phi_act) %>%
    pivot_longer(cols = c(phi_mut, phi_stab, phi_act), 
                 names_to = "component", 
                 values_to = "shap_value") %>%
    mutate(component = recode(component,
                             "phi_mut" = "Mutation",
                             "phi_stab" = "Stability", 
                             "phi_act" = "Activity"),
           component = factor(component, levels = c("Mutation", "Stability", "Activity")))
  
  # Get unique mcsa_id and pdb_chain pairs for strip labels
  pdb_chain_map <- profiles_examples %>%
    group_by(mcsa_id) %>%
    summarise(pdb_chain = first(pdb_chain)) %>%
    mutate(mcsa_id = factor(mcsa_id, levels = example_families))
  
  # Create a labeller function for strip labels
  strip_labeller <- function(mcsa_id) {
    pdb_chain <- pdb_chain_map$pdb_chain[pdb_chain_map$mcsa_id == mcsa_id]
    paste("mcsa_id:", mcsa_id, ", pdb:", pdb_chain)
  }
  
  # Calculate annotation values for each protein
  annotation_values <- profiles_examples %>%
    group_by(mcsa_id) %>%
    summarise(
      aS = round(first(a1), 2),
      aA = round(first(a2), 2),
      sd_phi_mut = sd(phi_mut, na.rm = TRUE),
      sd_phi_stab = sd(phi_stab, na.rm = TRUE),
      sd_phi_act = sd(phi_act, na.rm = TRUE)
    ) %>%
    mutate(
      # Calculate total SD and relative proportions
      total_sd = sd_phi_mut + sd_phi_stab + sd_phi_act,
      rel_sd_mut = sd_phi_mut / total_sd,
      rel_sd_stab = sd_phi_stab / total_sd,
      rel_sd_act = sd_phi_act / total_sd,
      # Create two-line label
      label_topleft = paste0("aS=", aS, ", aA=", aA, "\n",
                            "Rel. SD: M=", round(rel_sd_mut, 2), 
                            ", S=", round(rel_sd_stab, 2), 
                            ", A=", round(rel_sd_act, 2))
    )
  
  # Create the plot
  plot <- ggplot(profiles_long, aes(x = site, y = shap_value, color = component)) +
    geom_line(linewidth = LINE_SIZE_DEFAULT) +
    geom_vline(data = active_sites, 
               aes(xintercept = site), 
               color = "red", 
               alpha = ALPHA_REFERENCE_LINES,
               linetype = "dashed") +
    geom_text(data = annotation_values,
              aes(x = -Inf, y = Inf, label = label_topleft),
              hjust = -0.05, vjust = 1.2, size = ANNOTATION_TEXT_SIZE, color = "black",
              inherit.aes = FALSE) +
    facet_wrap(~ mcsa_id, ncol = 1, scales = "free_x", 
               labeller = labeller(mcsa_id = strip_labeller)) +
    scale_color_manual(values = SHAP_COLORS) +
    labs(x = "residue", y = "nlRMSD component") +
    theme_cowplot(font_size = THEME_SIZE) +
    theme(legend.position = "bottom",
          legend.title = element_blank()) +
    panel_border()
  
  return(plot)
}

# Main execution
if (!interactive()) {
  # Use same example proteins as model_profiles.R
  
  # Generate the figure
  fig <- plot_shap_profiles(profiles, shap_results, EXAMPLE_PROTEINS)
  
  # Save the figure
  output_file <- file.path(FIG_DIR, "shap_profiles.pdf")
  ggsave(output_file, fig, width = FIG_WIDTH, height = FIG_HEIGHT_MULTI, dpi = 300)
  
  # message("Figure saved to: ", output_file)
}