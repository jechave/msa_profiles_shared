# Makefile for MSA Paper Figures
# Reproducible figure generation for publication

# R command
RSCRIPT = Rscript

# Directories
SRC_DIR = src
FIG_DIR = figures/individual
COMBINED_DIR = figures/combined

# Individual figure targets
INDIVIDUAL_FIGS = model_profiles model_d2 model_delta_d2 \
                  shap_profiles shap_relative_sd shap_sd \
                  shap_mut_vs_lrmsf shap_stab_vs_a1 shap_act_vs_loga2 \
                  msa_vs_m12_correlation

# Paper figure targets
PAPER_FIGS = paper_fig1_model_progression paper_fig2_shap_decomposition \
             paper_fig3_shap_correlations paper_suppl_fig_msa_vs_m12

# Default target
all: individual paper

# Generate all individual figures
individual: $(addprefix $(FIG_DIR)/, $(addsuffix .pdf, $(INDIVIDUAL_FIGS)))

# Generate all paper figures  
paper: individual
	@echo "Generating paper figures..."
	@$(RSCRIPT) $(SRC_DIR)/combine_paper_figures.R
	@echo "✓ Paper figures complete"

# Pattern rule for individual figures
$(FIG_DIR)/%.pdf: $(SRC_DIR)/fig_%.R $(SRC_DIR)/config.R $(SRC_DIR)/data_prep.R $(SRC_DIR)/shared_data_preparation.R
	@echo "Generating $@..."
	@$(RSCRIPT) $<
	@echo "✓ $@ complete"

# Generate specific paper figures
paper_fig1: $(COMBINED_DIR)/paper_fig1_model_progression.pdf
paper_fig2: $(COMBINED_DIR)/paper_fig2_shap_decomposition.pdf  
paper_fig3: $(COMBINED_DIR)/paper_fig3_shap_correlations.pdf
paper_suppl: $(COMBINED_DIR)/paper_suppl_fig_msa_vs_m12.pdf

$(COMBINED_DIR)/%.pdf: individual
	@echo "Generating $@..."
	@$(RSCRIPT) $(SRC_DIR)/combine_paper_figures.R
	@echo "✓ $@ complete"

# Generate specific individual figure (usage: make fig_model_profiles)
fig_%:
	@$(MAKE) $(FIG_DIR)/$*.pdf

# Clean targets
clean:
	@rm -f $(FIG_DIR)/*.pdf
	@rm -f $(COMBINED_DIR)/*.pdf
	@echo "✓ Cleaned all figures"

clean-individual:
	@rm -f $(FIG_DIR)/*.pdf
	@echo "✓ Cleaned individual figures"

clean-combined:
	@rm -f $(COMBINED_DIR)/*.pdf
	@echo "✓ Cleaned combined figures"

# Help
help:
	@echo "MSA Paper Figures - Reproducible Figure Generation"
	@echo "================================================="
	@echo "Main targets:"
	@echo "  make              - Generate all individual figures"
	@echo "  make all          - Generate everything (individual + paper)"
	@echo "  make individual   - Generate all individual figures"
	@echo "  make paper        - Generate paper figure combinations"
	@echo ""
	@echo "Specific paper figures:"
	@echo "  make paper_fig1   - Model progression analysis"
	@echo "  make paper_fig2   - SHAP decomposition analysis" 
	@echo "  make paper_fig3   - SHAP parameter correlations"
	@echo "  make paper_suppl  - MSA vs M12 correlation"
	@echo ""
	@echo "Specific individual figures:"
	@echo "  make fig_NAME     - Generate specific figure (e.g., make fig_model_profiles)"
	@echo ""
	@echo "Available individual figures:"
	@for fig in $(INDIVIDUAL_FIGS); do echo "  - $$fig"; done
	@echo ""
	@echo "Clean targets:"
	@echo "  make clean        - Remove all figures"
	@echo "  make clean-individual - Remove individual figures only"
	@echo "  make clean-combined   - Remove combined figures only"

.PHONY: all individual paper paper_fig1 paper_fig2 paper_fig3 paper_suppl clean clean-individual clean-combined help