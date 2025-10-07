# data_prep.R - Data preparation for MSA profiles analysis
# This script loads and prepares all necessary data for figure generation

library(tidyverse)
library(here)

# Source configuration
source(here("src", "config.R"))

# Load shared data preparation
source(here("src", "shared_data_preparation.R"))

# Function to prepare model deviance data
prepare_model_deviance <- function(profiles) {
  model_deviance <- profiles %>% 
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
    summarise(
      a1 = first(a1),
      a2 = first(a2),
      # Calculate variance of lrmsf
      var_lrmsf = var(lrmsf, na.rm = TRUE),
      # Calculate variance of observations for denominator
      var_obs = var(lrmsd_obs, na.rm = TRUE),
      # Calculate variances for each model
      var_m0 = var(lrmsd_m0, na.rm = TRUE),
      var_mm = var(lrmsd_mm, na.rm = TRUE),
      var_ms = var(lrmsd_ms, na.rm = TRUE),
      var_msa = var(lrmsd_msa, na.rm = TRUE),
      # Calculate explained deviance for each model
      dev_expl_m0 = var_m0 / var_obs,
      dev_expl_mm = var_mm / var_obs,
      dev_expl_ms = var_ms / var_obs,
      dev_expl_msa = var_msa / var_obs
    ) %>%
    mutate(
      # Calculate D² improvements (positive = improvement)
      delta_mm_m0 = dev_expl_mm - dev_expl_m0,
      delta_ms_mm = dev_expl_ms - dev_expl_mm,
      delta_msa_ms = dev_expl_msa - dev_expl_ms,
      # Calculate relative D² improvements (normalized by MSA D²)
      delta_mm_m0_rel = (dev_expl_mm - dev_expl_m0) / dev_expl_msa,
      delta_ms_mm_rel = (dev_expl_ms - dev_expl_mm) / dev_expl_msa,
      delta_msa_ms_rel = (dev_expl_msa - dev_expl_ms) / dev_expl_msa,
      # Calculate D² improvements scaled by variance of observations
      delta_mm_m0_scaled = (dev_expl_mm - dev_expl_m0) * var_obs,
      delta_ms_mm_scaled = (dev_expl_ms - dev_expl_mm) * var_obs,
      delta_msa_ms_scaled = (dev_expl_msa - dev_expl_ms) * var_obs,
      # Calculate variance differences
      delta_var_mm_m0 = var_mm - var_m0,
      delta_var_ms_mm = var_ms - var_mm,
      delta_var_msa_ms = var_msa - var_ms,
      # Calculate log(a2) 
      log_a2 = log(a2)
    )
  
  return(model_deviance)
}

# Function to prepare SHAP decomposition data
prepare_shap_data <- function(profiles) {
  # SHAP values are already in the profiles data
  # Just need to rename them to match expected names
  shap_results <- profiles %>%
    mutate(
      phi_mut = shap_mut,
      phi_stab = shap_stab,
      phi_act = shap_act
    )
  
  return(shap_results)
}

# Load and prepare all data
if (!exists("profiles")) {
  stop("Profiles data not loaded. Please ensure shared_data_preparation.R has been sourced.")
}

# Prepare model deviance data
model_deviance <- prepare_model_deviance(profiles)

# Prepare SHAP data
shap_results <- prepare_shap_data(profiles)