# Liu-Wei 2024 RNA Nanopore Analysis Pipeline - Diversity Validation

This repository contains the diversity validation framework for the Liu-Wei 2024 RNA Nanopore Analysis Pipeline.

## Overview

The diversity validation framework provides:
- Statistical validation of metrics across different sample categories
- ANOVA and Kruskal-Wallis tests for continuous metrics
- Chi-square and Fisher's exact tests for benchmark pass rates
- Comprehensive visualizations for metric distributions
- PUIP-compliant metadata tracking and validation

## Key Files

- `run_diversity_validation.sh`: Main script to run diversity validation
- `simple_diversity_validation.py`: Core implementation of diversity validation
- `MAY20_READINESS_REPORT.md`: Readiness status for the May 20, 2025 real data run
- `implementation_status.md`: Current status of implementation with fixed and pending issues

## May 20, 2025 Readiness

The environment is fully prepared for the May 20, 2025 real data run with:
- Fixed dry-run mode in run_pipeline.sh
- All dependencies installed and verified
- Test data prepared and validated
- PUIP compliance confirmed

## Reference

Liu-Wei et al. (2024). "Comprehensive analysis of RNA Nanopore sequencing with curlcake datasets."