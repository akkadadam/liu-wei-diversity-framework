# Final Recommendations for May 20, 2025 Real Data Run

## Overview

The Liu-Wei 2024 RNA Nanopore Analysis Pipeline is now **fully prepared** for the May 20, 2025 real data run. This document provides the final recommendations and execution plan based on our successful preparation work.

## Key Achievements

- ✅ **Real Data Acquisition**: Successfully downloaded `ERR8654123.pod5` (12MB) using optimized parameters and configured it as `real_sample.pod5`.
- ✅ **Pipeline Verification**: Completed successful dry-run testing with real data.
- ✅ **Automation Script**: Developed and tested `run_may20_real_data.sh` for comprehensive execution.
- ✅ **Test Dataset Library**: Created a robust alternative dataset library with simulated RNA004-compatible POD5 files as backup.
- ✅ **PUIP Compliance**: Ensured full PUIP compliance with local Dorado execution and provenance tracking.
- ✅ **Environment Readiness**: Verified all dependencies and directory structures.

## Execution Plan for May 20, 2025

### Morning (09:00–09:30 EDT)

1. Verify environment and data:
   ```bash
   cd /Users/adamakkad/dev/drnaseq-stack/drnaseq-stack/pipelines/liu_wei_2024/tier_1
   ./scripts/prepare_for_real_run.sh --verbose
   ls -lh data/raw/real_sample.pod5  # Confirm file size ~12MB
   ```

2. Final check for potential updates:
   ```bash
   git pull  # If working from repository
   ```

### Run Pipeline (09:30–12:00 EDT)

3. Execute the full pipeline with the real ERR8654123.pod5 data:
   ```bash
   ./minimal_repo/run_may20_real_data.sh
   ```

   This script will automatically:
   - Verify environment readiness
   - Check and use real_sample.pod5 (ERR8654123.pod5)
   - Run the pipeline with all PUIP requirements
   - Generate comprehensive reporting

4. Monitor progress:
   ```bash
   # In a separate terminal window
   tail -f results/tier1-real-*/logs/pipeline.log
   ```

### Validation and Analysis (13:00–15:00 EDT)

5. After pipeline completion, review results:
   ```bash
   LATEST_OUTPUT=$(ls -td results/tier1-real-* | head -n1)
   
   # Check output files
   ls -lh $LATEST_OUTPUT/basecalled/
   ls -lh $LATEST_OUTPUT/aligned/
   ls -lh $LATEST_OUTPUT/filtered/
   ls -lh $LATEST_OUTPUT/metrics/
   
   # View metrics
   cat $LATEST_OUTPUT/metrics/metrics.json
   ```

6. Run diversity validation:
   ```bash
   # Run diversity validation with real data results
   ./scripts/run_diversity_validation.sh --verbose --input-dir $LATEST_OUTPUT
   ```

### Reporting (15:00–16:00 EDT)

7. Generate final summary report:
   ```bash
   # Use the final report from run_may20_real_data.sh
   cat $LATEST_OUTPUT/MAY20_FINAL_REPORT.md
   
   # OR generate a custom report
   ./scripts/generate_summary_report.sh --input-dir $LATEST_OUTPUT --output MAY20_RESULTS_SUMMARY.md
   ```

## Backup Plan

If for any reason there are issues with the real data on May 20:

1. Verify the simulated dataset is available:
   ```bash
   ls -lh data/dataset_library/raw/ERR6391674/ERR6391674.pod5
   ```

2. Recreate real_sample.pod5 if needed:
   ```bash
   cp data/dataset_library/raw/ERR6391674/ERR6391674.pod5 data/raw/real_sample.pod5
   ```

3. Run the pipeline with the simulated data:
   ```bash
   # Run pipeline
   ./run_pipeline.sh
   
   # OR use the automation script
   ./minimal_repo/run_may20_real_data.sh
   ```

4. Document clearly in the final report that simulated data was used.

## Post-Run Tasks

After the May 20 run is completed:

1. Archive the results:
   ```bash
   # Create a timestamped archive
   tar -czvf liu_wei_may20_run_results.tar.gz $LATEST_OUTPUT
   ```

2. Update GitHub repository:
   ```bash
   cd minimal_repo
   git add MAY20_RESULTS_SUMMARY.md
   git commit -m "[phase:4.0] Add May 20 real data run results"
   git push origin main
   ```

3. Begin preparation for Tier 2 implementation (May 21-22).

## Final Notes

- The pipeline is now optimized for RNA004 chemistry and has been tested with real data.
- Local Dorado execution ensures PUIP compliance and scientific reproducibility.
- The test dataset library remains valuable for future diversity testing and as a backup strategy.
- All preparations have been thoroughly documented and verified with dry-run testing.

We are confident that the May 20, 2025 real data run will be successful, with a robust backup plan in place if needed. The system is PUIP-compliant, scientifically valid, and ready for production execution.

---

Prepared by: Claude
Date: May 19, 2025, 07:30 AM EDT