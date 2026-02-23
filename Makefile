# Makefile for MSA Profiles Analysis
# Reproducible figure generation for publication

# R command
RSCRIPT = Rscript

# Directories
SRC_DIR = src
FIG_DIR = figures

# Paper figure files
PAPER_FIGS = $(FIG_DIR)/paper_fig1_msa_vs_m12.pdf \
             $(FIG_DIR)/paper_fig2_model_progression.pdf \
             $(FIG_DIR)/paper_fig3_shap_decomposition.pdf \
             $(FIG_DIR)/paper_fig4_shap_correlations.pdf

# Supplement
SUPP_DIR = supplement
SUPPLEMENT_TABLES = $(SUPP_DIR)/supplement_tables.pdf

# Default target - generate all paper figures
all: $(PAPER_FIGS)

# Generate all paper figures
paper: $(PAPER_FIGS)

# Generate paper figures by running the combine script
$(PAPER_FIGS): $(SRC_DIR)/combine_paper_figures.R $(SRC_DIR)/config.R $(SRC_DIR)/data_prep.R $(SRC_DIR)/shared_data_preparation.R $(wildcard $(SRC_DIR)/fig_*.R)
	@echo "Generating paper figures..."
	@$(RSCRIPT) $(SRC_DIR)/combine_paper_figures.R
	@echo "✓ All paper figures generated successfully"

# Generate specific paper figures
paper_fig1: $(FIG_DIR)/paper_fig1_msa_vs_m12.pdf
paper_fig2: $(FIG_DIR)/paper_fig2_model_progression.pdf  
paper_fig3: $(FIG_DIR)/paper_fig3_shap_decomposition.pdf
paper_fig4: $(FIG_DIR)/paper_fig4_shap_correlations.pdf

# Supplement tables
tables: $(SUPPLEMENT_TABLES)

$(SUPPLEMENT_TABLES): $(SUPP_DIR)/make_supplement_tables.Rmd data/final_dataset_table.csv $(SRC_DIR)/config.R $(SRC_DIR)/data_prep.R $(SRC_DIR)/shared_data_preparation.R
	@echo "Generating supplement tables..."
	@$(RSCRIPT) -e 'rmarkdown::render("$(SUPP_DIR)/make_supplement_tables.Rmd", output_file = "supplement_tables.pdf")'
	@echo "✓ Supplement tables generated successfully"

# Clean targets
clean:
	@rm -f $(FIG_DIR)/*.pdf
	@echo "✓ Cleaned all figures"

# Help
help:
	@echo "MSA Profiles Analysis - Reproducible Figure Generation"
	@echo "================================================="
	@echo "Main targets:"
	@echo "  make              - Generate all paper figures"
	@echo "  make all          - Generate all paper figures" 
	@echo "  make paper        - Generate all paper figures"
	@echo ""
	@echo "Specific paper figures:"
	@echo "  make paper_fig1   - MSA vs M12 correlation"
	@echo "  make paper_fig2   - Model progression analysis" 
	@echo "  make paper_fig3   - SHAP decomposition analysis"
	@echo "  make paper_fig4   - SHAP parameter correlations"
	@echo ""
	@echo "Supplement tables:"
	@echo "  make tables       - Supplement tables (S1, S2, S3)"
	@echo ""
	@echo "Clean targets:"
	@echo "  make clean        - Remove all figures"
	@echo ""
	@echo "Generated files:"
	@echo "  figures/paper_fig1_msa_vs_m12.pdf"
	@echo "  figures/paper_fig2_model_progression.pdf"
	@echo "  figures/paper_fig3_shap_decomposition.pdf"
	@echo "  figures/paper_fig4_shap_correlations.pdf"
	@echo "  supplement/supplement_tables.pdf"

.PHONY: all paper paper_fig1 paper_fig2 paper_fig3 paper_fig4 tables clean help