#!/usr/bin/env Rscript
# fig_model_profiles.R - Generate model progression profiles figure
# Shows observed vs predicted lRMSD profiles for example proteins

# Load required libraries
library(tidyverse)
library(ggplot2)
library(cowplot)
library(here)

# Source configuration and data preparation
source(here("src", "config.R"))
source(here("src", "data_prep.R"))

# Function to plot LRMSD profiles for MM, MS, MSA models vs Observed
plot_model_profiles <- function(profiles, example_families, model_deviance) {
  
  # Filter the data for the selected families
  profiles_examples <- profiles %>%
    filter(mcsa_id %in% example_families)
  
  # Apply two-step shifting
  profiles_examples <- profiles_examples %>%
    group_by(mcsa_id) %>%
    mutate(
      # Step 1: Shift observations to align with MSA mean
      shift1 = mean(lrmsd_msa, na.rm = TRUE) - mean(lrmsd_obs, na.rm = TRUE),
      lrmsd_obs = lrmsd_obs + shift1,
      # Step 2: Shift all variables by mean(MM) to make M0 = 0
      shift2 = mean(lrmsd_mm, na.rm = TRUE),
      lrmsd_obs = lrmsd_obs - shift2,
      lrmsd_mm = lrmsd_mm - shift2,
      lrmsd_ms = lrmsd_ms - shift2,
      lrmsd_msa = lrmsd_msa - shift2,
      # M0 is now 0 everywhere
      lrmsd_m0 = 0
    ) %>%
    ungroup()
  
  # Ensure the mcsa_id factor levels are in the specified order
  profiles_examples <- profiles_examples %>%
    mutate(mcsa_id = factor(mcsa_id, levels = example_families))
  
  # Get active site positions (where dactive == 0)
  active_sites <- profiles_examples %>%
    filter(dactive == 0) %>%
    select(mcsa_id, site) %>%
    distinct()
  
  # Retrieve explained deviance values, a1, and a2 values from model_deviance
  dev_values <- model_deviance %>%
    filter(mcsa_id %in% example_families) %>%
    select(mcsa_id, a1, a2, dev_expl_m0, dev_expl_mm, dev_expl_ms, dev_expl_msa) %>%
    mutate(mcsa_id = factor(mcsa_id, levels = example_families)) %>%
    group_by(mcsa_id) %>%
    summarise(
      a_S = round(first(a1), 2),
      a_A = round(first(a2), 2),
      dev_m0 = round(first(dev_expl_m0), 2),
      dev_mm = round(first(dev_expl_mm), 2),
      dev_ms = round(first(dev_expl_ms), 2),
      dev_msa = round(first(dev_expl_msa), 2),
      max_site = max(profiles_examples$site[profiles_examples$mcsa_id == mcsa_id], na.rm = TRUE),
      max_lrmsd = max(c(profiles_examples$lrmsd_obs[profiles_examples$mcsa_id == mcsa_id],
                        profiles_examples$lrmsd_m0[profiles_examples$mcsa_id == mcsa_id],
                        profiles_examples$lrmsd_mm[profiles_examples$mcsa_id == mcsa_id],
                        profiles_examples$lrmsd_ms[profiles_examples$mcsa_id == mcsa_id],
                        profiles_examples$lrmsd_msa[profiles_examples$mcsa_id == mcsa_id]), na.rm = TRUE),
      min_lrmsd = min(c(profiles_examples$lrmsd_obs[profiles_examples$mcsa_id == mcsa_id],
                        profiles_examples$lrmsd_m0[profiles_examples$mcsa_id == mcsa_id],
                        profiles_examples$lrmsd_mm[profiles_examples$mcsa_id == mcsa_id],
                        profiles_examples$lrmsd_ms[profiles_examples$mcsa_id == mcsa_id],
                        profiles_examples$lrmsd_msa[profiles_examples$mcsa_id == mcsa_id]), na.rm = TRUE),
      y_upper = max_lrmsd * 1.2,
      y_lower = min_lrmsd * 1.2
    ) %>%
    mutate(
      label = paste0("aS=", a_S, ", aA=", a_A, "\n",
                     "D²: MM=", dev_mm, ", MS=", dev_ms, ", MSA=", dev_msa),
      x_pos = max_site * 0.99,
      y_pos = max_lrmsd * 1.15
    )
  
  # Reshape the data for plotting (long format)
  profiles_long <- profiles_examples %>%
    select(mcsa_id, site, lrmsd_obs, lrmsd_mm, lrmsd_ms, lrmsd_msa) %>%
    pivot_longer(cols = c(lrmsd_obs, lrmsd_mm, lrmsd_ms, lrmsd_msa), 
                 names_to = "source", 
                 values_to = "lrmsd") %>%
    mutate(source = recode(source,
                           "lrmsd_obs" = "Observed",
                           "lrmsd_mm" = "MM",
                           "lrmsd_ms" = "MS",
                           "lrmsd_msa" = "MSA"),
           source = factor(source, levels = c("Observed", "MM", "MS", "MSA")),
           mcsa_id = factor(mcsa_id, levels = example_families))
  
  # Get unique mcsa_id and pdb_chain pairs
  pdb_chain_map <- profiles_examples %>%
    group_by(mcsa_id) %>%
    summarise(pdb_chain = first(pdb_chain)) %>%
    mutate(mcsa_id = factor(mcsa_id, levels = example_families))
  
  # Create a labeller function for strip labels including pdb_chain
  strip_labeller <- function(mcsa_id) {
    pdb_chain <- pdb_chain_map$pdb_chain[pdb_chain_map$mcsa_id == mcsa_id]
    paste("mcsa_id:", mcsa_id, ", pdb:", pdb_chain)
  }
  
  # Create the line plot, faceted by protein family (vertically)
  plot <- ggplot(profiles_long, aes(x = site, y = lrmsd, color = source)) +
    # Add vertical lines at active sites
    geom_vline(data = active_sites, 
               aes(xintercept = site), 
               color = "red", 
               alpha = ALPHA_REFERENCE_LINES) +
    # Add horizontal grid line at zero
    geom_hline(yintercept = 0, 
               color = "gray80", linewidth = 0.3, alpha = 0.7) +
    # Add all lines using the color aesthetic for proper legend appearance
    geom_line(aes(linetype = source), linewidth = LINE_SIZE_DEFAULT) +
    # Add dev.expl annotations
    geom_text(data = dev_values,
              aes(x = -Inf, y = Inf, label = label),
              hjust = -0.05, vjust = 1.2, size = ANNOTATION_TEXT_SIZE, color = "black",
              inherit.aes = FALSE) +
    # Extend y-range by 20% at the top and bottom
    geom_blank(data = dev_values, 
               aes(y = y_upper), 
               inherit.aes = FALSE) +
    geom_blank(data = dev_values, 
               aes(y = y_lower), 
               inherit.aes = FALSE) +
    # Facet by mcsa_id with free scales, preserving order
    facet_wrap(~ mcsa_id, ncol = 1, scales = "free_x", 
               labeller = labeller(mcsa_id = strip_labeller)) +
    scale_color_manual(values = MODEL_COLORS) +
    scale_linetype_manual(values = c("Observed" = "dotted", "MM" = "solid", "MS" = "solid", "MSA" = "solid")) +
    labs(x = "Residue", y = "nlRMSD") +
    theme_cowplot(font_size = THEME_SIZE) +
    theme(legend.position = "bottom",
          legend.title = element_blank()) +
    panel_border() +
    guides(color = guide_legend(override.aes = list(linetype = c("dotted", "solid", "solid", "solid"))),
           linetype = "none")
  
  return(plot)
}

# Main execution
if (!interactive()) {
  # Generate the figure
  fig <- plot_model_profiles(profiles, EXAMPLE_PROTEINS, model_deviance)
  
  # Save the figure
  output_file <- file.path(FIG_DIR, "model_profiles.pdf")
  ggsave(output_file, fig, width = FIG_WIDTH, height = FIG_HEIGHT_MULTI, dpi = 300)
  
  # message("Figure saved to: ", output_file)
}