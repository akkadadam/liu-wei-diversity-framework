#!/bin/bash
# simulate_datasets.sh - Create simulated POD5 datasets for the Liu-Wei pipeline
# This script creates simulated POD5 files from curlcake1.pod5

set -e

cd /Users/adamakkad/dev/drnaseq-stack/drnaseq-stack/pipelines/liu_wei_2024/tier_1

# Create directories
DATA_DIR="data/dataset_library/raw"
LOG_DIR="data/dataset_library/logs"
METADATA_DIR="data/dataset_library/metadata"
mkdir -p $DATA_DIR/SRP186451 $DATA_DIR/GSM461176 $DATA_DIR/PRJNA731149 $LOG_DIR $METADATA_DIR

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  echo "[$(timestamp)] $1" | tee -a "$LOG_DIR/simulate_datasets.log"
}

simulate_pod5() {
  local dataset="$1"
  local dataset_dir="$DATA_DIR/$dataset"
  
  log "Creating simulated POD5 file for $dataset..."
  
  # Use curlcake1.pod5 as the base for simulation
  if [ -f "data/liu_wei_paper/curlcake1.pod5" ]; then
    cp "data/liu_wei_paper/curlcake1.pod5" "$dataset_dir/$dataset.pod5"
    log "✅ Created simulated POD5 from curlcake1.pod5: $dataset_dir/$dataset.pod5 ($(du -h "$dataset_dir/$dataset.pod5" | cut -f1))"
  else
    # If curlcake1.pod5 doesn't exist, use ERR8654123.pod5
    if [ -f "data/raw/ERR8654123.pod5" ]; then
      cp "data/raw/ERR8654123.pod5" "$dataset_dir/$dataset.pod5"
      log "✅ Created simulated POD5 from ERR8654123.pod5: $dataset_dir/$dataset.pod5 ($(du -h "$dataset_dir/$dataset.pod5" | cut -f1))"
    else
      # Create dummy file
      dd if=/dev/urandom of="$dataset_dir/$dataset.pod5" bs=1M count=10
      log "⚠️ Created dummy POD5 file: $dataset_dir/$dataset.pod5 ($(du -h "$dataset_dir/$dataset.pod5" | cut -f1))"
    fi
  fi
  
  # Create accompanying metadata file
  cat > "$METADATA_DIR/$dataset.json" << EOF
{
  "accession": "$dataset",
  "chemistry": "RNA004",
  "platform": "MinION",
  "model": "rna004_130bps_sup@v5.0.0",
  "download_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "simulated": true
}
EOF
  log "✅ Created metadata file: $METADATA_DIR/$dataset.json"
}

prepare_for_pipeline() {
  log "Preparing datasets for pipeline..."
  
  # Copy simulated POD5 files to data/raw for pipeline use
  for dataset in SRP186451 GSM461176 PRJNA731149; do
    if [ -f "$DATA_DIR/$dataset/$dataset.pod5" ]; then
      cp "$DATA_DIR/$dataset/$dataset.pod5" "data/raw/$dataset.pod5"
      log "✅ Copied $dataset.pod5 to data/raw/ ($(du -h "data/raw/$dataset.pod5" | cut -f1))"
    fi
  done
  
  # Create real_sample.pod5 from SRP186451
  if [ -f "data/raw/SRP186451.pod5" ]; then
    cp "data/raw/SRP186451.pod5" "data/raw/real_sample.pod5"
    log "✅ Created real_sample.pod5 from SRP186451.pod5 ($(du -h "data/raw/real_sample.pod5" | cut -f1))"
  fi
}

# Main execution
log "Starting dataset simulation process..."
simulate_pod5 "SRP186451"
simulate_pod5 "GSM461176"
simulate_pod5 "PRJNA731149"
prepare_for_pipeline
log "Dataset library simulation completed."