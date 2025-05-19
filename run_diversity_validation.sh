#!/bin/bash
# run_diversity_validation.sh - Run diversity validation for PRJEB73868 samples
#
# This script runs the diversity validation on PRJEB73868 samples, generating
# statistical analysis reports and visualizations to validate sample diversity
# across different categories (platform, tissue, etc.)

set -eo pipefail

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE_DIR="$(dirname "${SCRIPT_DIR}")"

# Default configuration
CATALOG_DIR="${PIPELINE_DIR}/data/catalogs/current"
TEST_SETS_DIR="${PIPELINE_DIR}/data/test_sets"
METRICS_DIR="${PIPELINE_DIR}/data/metrics"
RESULTS_DIR="${PIPELINE_DIR}/results/validation"
VIS_DIR="${PIPELINE_DIR}/results/validation/visualizations"
CHEMISTRY="RNA004"
MIN_SAMPLES=3
CONFIDENCE_LEVEL=0.95
LOG_DIR="${PIPELINE_DIR}/data/logs"
LOG_FILE="${LOG_DIR}/diversity_validation_$(date +%Y%m%d_%H%M%S).log"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --catalog=*)
      CATALOG="${1#*=}"
      shift
      ;;
    --metrics-dir=*)
      METRICS_DIR="${1#*=}"
      shift
      ;;
    --results-dir=*)
      RESULTS_DIR="${1#*=}"
      shift
      ;;
    --vis-dir=*)
      VIS_DIR="${1#*=}"
      shift
      ;;
    --chemistry=*)
      CHEMISTRY="${1#*=}"
      shift
      ;;
    --min-samples=*)
      MIN_SAMPLES="${1#*=}"
      shift
      ;;
    --confidence-level=*)
      CONFIDENCE_LEVEL="${1#*=}"
      shift
      ;;
    --verbose)
      VERBOSE="--verbose"
      shift
      ;;
    --help)
      echo "Usage: run_diversity_validation.sh [options]"
      echo "Options:"
      echo "  --catalog=PATH         Path to catalog JSON file"
      echo "  --metrics-dir=DIR      Directory containing metrics JSON files"
      echo "  --results-dir=DIR      Directory to save validation results"
      echo "  --vis-dir=DIR          Directory to save visualizations"
      echo "  --chemistry=CHEM       Chemistry to filter samples by (default: RNA004)"
      echo "  --min-samples=N        Minimum samples per category (default: 3)"
      echo "  --confidence-level=N   Confidence level for tests (default: 0.95)"
      echo "  --verbose              Enable verbose logging"
      echo "  --help                 Show this help message"
      exit 0
      ;;
    *)
      echo "Error: Unknown option: $1"
      echo "Run 'run_diversity_validation.sh --help' for usage information"
      exit 1
      ;;
  esac
done

# Create directories if they don't exist
mkdir -p "${RESULTS_DIR}" "${VIS_DIR}" "${LOG_DIR}"

# Check for catalog file
if [ -z "${CATALOG}" ]; then
  # Try to find catalog file in standard locations
  if [ -f "${CATALOG_DIR}/PRJEB73868_catalog.json" ]; then
    CATALOG="${CATALOG_DIR}/PRJEB73868_catalog.json"
  elif [ -f "${TEST_SETS_DIR}/liu_wei_dataset_catalog.json" ]; then
    CATALOG="${TEST_SETS_DIR}/liu_wei_dataset_catalog.json"
  else
    echo "Error: Catalog file not found. Please specify with --catalog=" >&2
    exit 1
  fi
fi

# Log file setup
echo "Starting Liu-Wei PRJEB73868 diversity validation at $(date)" | tee "${LOG_FILE}"
echo "Configuration:" | tee -a "${LOG_FILE}"
echo "- Catalog: ${CATALOG}" | tee -a "${LOG_FILE}"
echo "- Metrics directory: ${METRICS_DIR}" | tee -a "${LOG_FILE}"
echo "- Results directory: ${RESULTS_DIR}" | tee -a "${LOG_FILE}"
echo "- Visualization directory: ${VIS_DIR}" | tee -a "${LOG_FILE}"
echo "- Chemistry: ${CHEMISTRY}" | tee -a "${LOG_FILE}"
echo "- Minimum samples per category: ${MIN_SAMPLES}" | tee -a "${LOG_FILE}"
echo "- Confidence level: ${CONFIDENCE_LEVEL}" | tee -a "${LOG_FILE}"

# Generate HTML report filename with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_PATH="${RESULTS_DIR}/diversity_report_${TIMESTAMP}.html"
JSON_OUTPUT="${RESULTS_DIR}/diversity_validation_${TIMESTAMP}.json"

# Run diversity validation
echo "Running diversity validation... this may take a few minutes" | tee -a "${LOG_FILE}"
python3 "${SCRIPT_DIR}/simple_diversity_validation.py" \
  --catalog="${CATALOG}" \
  --metrics-dir="${METRICS_DIR}" \
  --results-dir="${RESULTS_DIR}" \
  --vis-dir="${VIS_DIR}" \
  --chemistry="${CHEMISTRY}" \
  --min-samples="${MIN_SAMPLES}" \
  --confidence-level="${CONFIDENCE_LEVEL}" \
  --report="${REPORT_PATH}" \
  --output="${JSON_OUTPUT}" \
  ${VERBOSE} | tee -a "${LOG_FILE}"

# Check execution status
if [ ${PIPESTATUS[0]} -eq 0 ]; then
  echo "Diversity validation completed successfully!" | tee -a "${LOG_FILE}"
  echo "HTML report: ${REPORT_PATH}" | tee -a "${LOG_FILE}"
  echo "JSON results: ${JSON_OUTPUT}" | tee -a "${LOG_FILE}"
  
  # Add to execution history
  echo "$(date +%Y-%m-%dT%H:%M:%S%z),diversity_validation,success,${CHEMISTRY},${REPORT_PATH}" >> "${PIPELINE_DIR}/data/logs/validation_history.csv"
  
  # Create a symlink to the latest report
  ln -sf "${REPORT_PATH}" "${RESULTS_DIR}/latest_diversity_report.html"
  ln -sf "${JSON_OUTPUT}" "${RESULTS_DIR}/latest_diversity_validation.json"
  
  echo "Report is available at: ${RESULTS_DIR}/latest_diversity_report.html" | tee -a "${LOG_FILE}"
  
  # If this is part of a CI/CD pipeline, add a status indicator file
  if [ -n "${CI}" ]; then
    echo "summary: success" > "${RESULTS_DIR}/diversity_validation_status.yaml"
    echo "timestamp: $(date +%Y-%m-%dT%H:%M:%S%z)" >> "${RESULTS_DIR}/diversity_validation_status.yaml"
    echo "report_path: ${REPORT_PATH}" >> "${RESULTS_DIR}/diversity_validation_status.yaml"
  fi
  
  exit 0
else
  echo "Error: Diversity validation failed" | tee -a "${LOG_FILE}"
  echo "Check log file for details: ${LOG_FILE}" | tee -a "${LOG_FILE}"
  
  # Add to execution history
  echo "$(date +%Y-%m-%dT%H:%M:%S%z),diversity_validation,failure,${CHEMISTRY},${LOG_FILE}" >> "${PIPELINE_DIR}/data/logs/validation_history.csv"
  
  # If this is part of a CI/CD pipeline, add a status indicator file
  if [ -n "${CI}" ]; then
    echo "summary: failure" > "${RESULTS_DIR}/diversity_validation_status.yaml"
    echo "timestamp: $(date +%Y-%m-%dT%H:%M:%S%z)" >> "${RESULTS_DIR}/diversity_validation_status.yaml"
    echo "log_path: ${LOG_FILE}" >> "${RESULTS_DIR}/diversity_validation_status.yaml"
  fi
  
  exit 1
fi