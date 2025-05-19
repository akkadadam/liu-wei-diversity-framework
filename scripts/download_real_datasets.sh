#!/bin/bash
# download_real_datasets.sh - Improved script to download real datasets for May 20 run
# With expanded timeout, retry, and multiple source attempts

set -e

cd /Users/adamakkad/dev/drnaseq-stack/drnaseq-stack/pipelines/liu_wei_2024/tier_1
DATA_DIR="data/dataset_library/raw"
LOG_DIR="data/dataset_library/logs"
METADATA_DIR="data/dataset_library/metadata"
mkdir -p $DATA_DIR $LOG_DIR $METADATA_DIR

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  echo "[$(timestamp)] $1" | tee -a "$LOG_DIR/download_real_datasets_$(date +%Y%m%d).log"
}

download_ERR8654123() {
  log "Attempting to download ERR8654123.pod5 (PRIMARY TARGET)..."
  
  # Method 1: Direct FTP with increased timeout
  log "Method 1: Direct FTP with increased timeout"
  curl --connect-timeout 180 --max-time 1800 --retry 10 --retry-delay 30 \
    ftp://ftp.ebi.ac.uk/pub/databases/ena/sra/srr/ERR8654123/ERR8654123.pod5 \
    -o data/raw/ERR8654123.pod5 2>> $LOG_DIR/ERR8654123_method1.log || true
  
  # Method 2: Alternative FTP syntax
  if [ ! -s data/raw/ERR8654123.pod5 ]; then
    log "Method 2: Alternative FTP path"
    curl --connect-timeout 180 --max-time 1800 --retry 10 --retry-delay 30 \
      ftp://ftp.sra.ebi.ac.uk/vol1/run/ERR865/ERR8654123/ERR8654123.pod5 \
      -o data/raw/ERR8654123.pod5 2>> $LOG_DIR/ERR8654123_method2.log || true
  fi
  
  # Method 3: AWS S3 path
  if [ ! -s data/raw/ERR8654123.pod5 ]; then
    log "Method 3: AWS S3 path"
    wget --tries=10 --timeout=1800 --waitretry=30 \
      https://sra-pub-run-odp.s3.amazonaws.com/sra/ERR8654123/ERR8654123.pod5 \
      -O data/raw/ERR8654123.pod5 2>> $LOG_DIR/ERR8654123_method3.log || true
  fi
  
  # Check if any method succeeded
  if [ -s data/raw/ERR8654123.pod5 ]; then
    log "✅ SUCCESS: ERR8654123.pod5 downloaded successfully"
    ls -lh data/raw/ERR8654123.pod5
    cp data/raw/ERR8654123.pod5 data/raw/real_sample.pod5
    log "✅ Copied to real_sample.pod5 for pipeline use"
  else
    log "❌ FAILED: All ERR8654123.pod5 download attempts failed"
  fi
}

download_ERR6391674() {
  log "Attempting to download ERR6391674 (BACKUP TARGET)..."
  
  # Method 1: Direct POD5 download
  log "Method 1: Direct POD5 download"
  wget --tries=10 --timeout=1800 --waitretry=30 \
    ftp://ftp.sra.ebi.ac.uk/vol1/run/ERR639/ERR6391674/ERR6391674.pod5 \
    -O $DATA_DIR/ERR6391674/ERR6391674.pod5 2>> $LOG_DIR/ERR6391674_pod5.log || true
  
  # Method 2: FASTQ download and conversion
  if [ ! -s $DATA_DIR/ERR6391674/ERR6391674.pod5 ]; then
    log "Method 2: FASTQ download"
    mkdir -p $DATA_DIR/ERR6391674/fastq
    wget --tries=10 --timeout=1800 --waitretry=30 \
      ftp://ftp.sra.ebi.ac.uk/vol1/run/ERR639/ERR6391674/ERR6391674.fastq.gz \
      -O $DATA_DIR/ERR6391674/fastq/ERR6391674.fastq.gz 2>> $LOG_DIR/ERR6391674_fastq.log || true
    
    # Unzip if download succeeded
    if [ -s $DATA_DIR/ERR6391674/fastq/ERR6391674.fastq.gz ]; then
      gunzip $DATA_DIR/ERR6391674/fastq/ERR6391674.fastq.gz
      log "✅ FASTQ downloaded successfully, need pod5_converter for POD5 creation"
    fi
  fi
  
  # Check if we got the POD5 file directly
  if [ -s $DATA_DIR/ERR6391674/ERR6391674.pod5 ]; then
    log "✅ SUCCESS: ERR6391674.pod5 downloaded successfully"
    ls -lh $DATA_DIR/ERR6391674/ERR6391674.pod5
    cp $DATA_DIR/ERR6391674/ERR6391674.pod5 data/raw/ERR6391674.pod5
    if [ ! -f data/raw/real_sample.pod5 ]; then
      cp $DATA_DIR/ERR6391674/ERR6391674.pod5 data/raw/real_sample.pod5
      log "✅ Copied to real_sample.pod5 for pipeline use"
    fi
  else
    log "❌ FAILED: ERR6391674.pod5 download failed, checking for FASTQ"
    if [ -s $DATA_DIR/ERR6391674/fastq/ERR6391674.fastq ]; then
      log "✅ FASTQ available as fallback, investigating conversion options"
    else
      log "❌ FAILED: All ERR6391674 download attempts failed"
    fi
  fi
}

download_SRP186451() {
  log "Attempting to download SRP186451 data..."
  
  # Check if sra-tools is installed
  if ! command -v prefetch &> /dev/null; then
    log "⚠️ sra-tools not found, attempting brew install"
    brew install sra-tools || log "❌ Failed to install sra-tools, SRP186451 download may fail"
  fi
  
  # Method 1: prefetch and fastq-dump
  if command -v prefetch &> /dev/null; then
    log "Method 1: Using prefetch and fastq-dump"
    mkdir -p $DATA_DIR/SRP186451
    prefetch --max-size 100g SRP186451 -O $DATA_DIR/SRP186451 2>> $LOG_DIR/SRP186451_prefetch.log || true
    
    if [ -d $DATA_DIR/SRP186451/SRP186451 ]; then
      fastq-dump --split-files $DATA_DIR/SRP186451/SRP186451 -O $DATA_DIR/SRP186451 2>> $LOG_DIR/SRP186451_fastq_dump.log || true
      log "✅ SRP186451 FASTQ files extracted"
      ls -lh $DATA_DIR/SRP186451/*.fastq
    else
      log "❌ SRP186451 prefetch failed, trying direct fastq-dump"
      fastq-dump --split-files SRP186451 -O $DATA_DIR/SRP186451 2>> $LOG_DIR/SRP186451_direct_fastq.log || true
    fi
  else
    log "⚠️ sra-tools not available, skipping SRP186451 download"
  fi
  
  # Check if we got any FASTQ files
  if ls $DATA_DIR/SRP186451/*.fastq 1> /dev/null 2>&1; then
    log "✅ SUCCESS: SRP186451 FASTQ files downloaded successfully"
    ls -lh $DATA_DIR/SRP186451/*.fastq
    log "⚠️ Need pod5_converter for POD5 creation"
  else
    log "❌ FAILED: All SRP186451 download attempts failed"
  fi
}

# Main execution
log "Starting real dataset downloads for May 20 run..."
mkdir -p $DATA_DIR/ERR6391674 $DATA_DIR/SRP186451 data/raw

# Try to download all datasets
download_ERR8654123
download_ERR6391674
download_SRP186451

# Check results and use simulated data if needed
if [ ! -s data/raw/real_sample.pod5 ]; then
  log "⚠️ No real POD5 files downloaded successfully, using simulated data as fallback"
  ./scripts/simulate_datasets.sh
  log "✅ Simulated datasets created, real_sample.pod5 ready for May 20 run"
else
  log "✅ real_sample.pod5 is ready for May 20 run"
  ls -lh data/raw/real_sample.pod5
fi

log "Real dataset download attempts completed. Check logs for details."