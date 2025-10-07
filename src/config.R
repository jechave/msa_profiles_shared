# config.R - Shared configuration for MSA profiles analysis
# This file contains all shared settings used across figure generation scripts

# Example proteins for profile plots
EXAMPLE_PROTEINS <- c(858, 15, 908)

# Color schemes
MODEL_COLORS <- c(
  "Observed" = "grey50",
  "MM" = "#FFA500",    # Matches Mutation (last component in MM)
  "MS" = "#4169E1",    # Matches Stability (last component in MS) 
  "MSA" = "#DC143C"    # Matches Activity (last component in MSA)
)

SHAP_COLORS <- c(
  "Mutation" = "#FFA500",   # Orange
  "Stability" = "#4169E1",  # Royal Blue
  "Activity" = "#DC143C"    # Crimson
)

# Plot dimensions (inches)
FIG_WIDTH <- 7
FIG_HEIGHT <- 5

# For multi-panel figures (paper figures)
FIG_WIDTH_PAPER <- 10
FIG_HEIGHT_PAPER_TALL <- 9
FIG_HEIGHT_PAPER_SHORT <- 5

# For individual multi-panel figures
FIG_WIDTH_MULTI <- 12
FIG_HEIGHT_MULTI <- 4

# Common theme settings
THEME_SIZE <- 14
ANNOTATION_TEXT_SIZE <- 4.2

# Specialized sizes for elements that override theme scaling
CORRELATION_POINT_SIZE <- 3.5       # Point size in correlation plots (was 2.5)

# Visual element sizes  
LINE_SIZE_DEFAULT <- 0.8           # Default line thickness
LINE_SIZE_THIN <- 0.4             # Thin reference lines
POINT_SIZE_DEFAULT <- 1.0          # Default point size
POINT_SIZE_LARGE <- 3.0            # Large emphasis points

# Alpha transparency values
ALPHA_SCATTER_POINTS <- 0.6        # Scatter/jitter points in distributions
ALPHA_CORRELATION_POINTS <- 0.7    # Main data points in correlations  
ALPHA_REFERENCE_LINES <- 0.2       # Reference lines (active sites, smooths)
ALPHA_OBSERVED_DATA <- 0.5         # Observed data lines
ALPHA_LEGEND_OBSERVED <- 0.5       # Legend transparency for observed
ALPHA_LEGEND_OPAQUE <- 1.0         # Legend transparency for models

# Output directories
FIG_DIR_INDIVIDUAL <- here::here("figures", "individual")
FIG_DIR_COMBINED <- here::here("figures", "combined")

# Ensure output directories exist
if (!dir.exists(FIG_DIR_INDIVIDUAL)) dir.create(FIG_DIR_INDIVIDUAL, recursive = TRUE)
if (!dir.exists(FIG_DIR_COMBINED)) dir.create(FIG_DIR_COMBINED, recursive = TRUE)