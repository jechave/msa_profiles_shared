# SHARED DATA PREPARATION FOR MSA ANALYSIS
#
# This script contains common data preparation steps used by both
# msa_analysis.Rmd and msa_vs_fit12_comparison.Rmd
#
# It loads and prepares:
# - Dataset with mcsa_id and pdb_chain information
# - Combined profiles tibble (MSA + empirical data)
# - Model performance metrics (deviance explained)

# Load required libraries
library(here)
library(tidyverse)

# Load Dataset
dataset <- read_csv(here("data", "dataset_ec2024.csv"), 
                   col_types = cols(
                     mcsa_id = col_character(),
                     pdb_chain = col_character(),
                     pdb_site_active = col_character(),
                     site_active = col_character()
                   ))

# Get unique mcsa_ids to process
mcsa_ids <- unique(dataset$mcsa_id)

# Create Profiles Tibble
# Check if MSA profiles file exists
msa_profiles_file <- here("data", "profiles_msa.csv")
if (!file.exists(msa_profiles_file)) {
  stop("MSA profiles file not found: ", msa_profiles_file, "\n",
       "Please run scripts/make_profiles_msa.R first to generate the MSA profiles data.")
}

# Load MSA profiles (parameters, predictions, and SHAP decompositions)
cat("Loading MSA profiles from:", msa_profiles_file, "\n")
profiles_msa <- read_csv(msa_profiles_file, col_types = cols())

# Load empirical profiles
profiles_empirical <- read_csv(here("data", "profiles_ec2024.csv")) %>% 
  rename(lrmsd_obs = lrmsd)

# Combine MSA and empirical profiles
profiles <- profiles_msa %>% 
  inner_join(profiles_empirical, by = c("mcsa_id", "site", "pdb_chain")) %>%
  mutate(
    lrmsd_fit12 = lrmsd.fit12,
    # Add sequential decomposition for paper analysis (M0 -> MM -> MS -> MSA progression)
    phi_mut = lrmsd_mm,
    phi_stab = lrmsd_ms - lrmsd_mm,
    phi_act = lrmsd_msa - lrmsd_ms
  ) 

cat("Combined profiles for", length(unique(profiles$mcsa_id)), "proteins with", nrow(profiles), "total sites\n")

# Calculate Model Performance Metrics
# Calculation of RMSE and deviance explained for MSA, MM, MS, MA, M0 model variants
model_dev_expl <- profiles %>% 
  group_by(mcsa_id) %>% 
  mutate(shift = mean(lrmsd_obs, na.rm = TRUE) - mean(lrmsd_msa, na.rm = TRUE)) %>%
  mutate(
    lrmsd_msa = lrmsd_msa + shift,
    lrmsd_mm = lrmsd_mm + shift,
    lrmsd_ms = lrmsd_ms + shift,
    lrmsd_m0 = mean(lrmsd_mm, na.rm = TRUE)  # Calculate m0 as the mean of mm
  ) %>% 
  summarise(
    a1 = first(a1),
    a2 = first(a2),
    aS = first(a1),
    aA = first(a2),
    rmse_m0 = sqrt(mean((lrmsd_m0 - lrmsd_obs)^2, na.rm = TRUE)),
    rmse_mm = sqrt(mean((lrmsd_mm - lrmsd_obs)^2, na.rm = TRUE)),
    rmse_ms = sqrt(mean((lrmsd_ms - lrmsd_obs)^2, na.rm = TRUE)),
    rmse_ma = sqrt(mean((lrmsd_ma - lrmsd_obs)^2, na.rm = TRUE)),
    rmse_msa = sqrt(mean((lrmsd_msa - lrmsd_obs)^2, na.rm = TRUE)),
    dev.expl_m0 = 1 - (rmse_m0/rmse_m0)^2,
    dev.expl_mm = 1 - (rmse_mm/rmse_m0)^2,
    dev.expl_ms = 1 - (rmse_ms/rmse_m0)^2,
    dev.expl_ma = 1 - (rmse_ma/rmse_m0)^2,
    dev.expl_msa = 1 - (rmse_msa/rmse_m0)^2,
  )

# Data objects created:
# - dataset: Original dataset with mcsa_id and pdb_chain information
# - profiles: Main tibble with all protein data
# - model_dev_expl: Model deviance explained metrics