#!/usr/bin/env python3
"""
Simple version of diversity_validation.py that just exports validation results to JSON
without HTML report generation to avoid f-string issues.
"""

import argparse
import json
import os
import sys
import logging
from datetime import datetime

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from scripts.diversity_validation import DiversityValidator

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Default paths
DEFAULT_CATALOG = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
    'data/catalogs/current/PRJEB73868_catalog.json'
)
if not os.path.exists(DEFAULT_CATALOG):
    # Fallback to test_sets if catalogs/current doesn't exist
    DEFAULT_CATALOG = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        'data/test_sets/liu_wei_dataset_catalog.json'
    )

DEFAULT_EXPECTED = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
    'docs/liu_wei_expected_metrics.json'
)
DEFAULT_RESULTS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
    'results/validation'
)
DEFAULT_VIS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
    'results/validation/visualizations'
)

def main():
    """Parse command line arguments and run diversity validation"""
    parser = argparse.ArgumentParser(description="Validate sample diversity across Liu-Wei 2024 dataset")
    
    parser.add_argument("--catalog", default=DEFAULT_CATALOG, help=f"Path to catalog JSON file (default: {DEFAULT_CATALOG})")
    parser.add_argument("--metrics-dir", help="Directory containing metrics JSON files")
    parser.add_argument("--expected", default=DEFAULT_EXPECTED, help=f"Path to expected metrics JSON file (default: {DEFAULT_EXPECTED})")
    parser.add_argument("--results-dir", default=DEFAULT_RESULTS_DIR, help=f"Directory to save validation results (default: {DEFAULT_RESULTS_DIR})")
    parser.add_argument("--vis-dir", default=DEFAULT_VIS_DIR, help=f"Directory to save visualizations (default: {DEFAULT_VIS_DIR})")
    parser.add_argument("--chemistry", default="RNA004", help="Chemistry to filter samples by (default: RNA004)")
    parser.add_argument("--min-samples", type=int, default=3, help="Minimum number of samples required for each category (default: 3)")
    parser.add_argument("--report", default=None, help="Path to save HTML report")
    parser.add_argument("--output", default=None, help="Path to save JSON results")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")
    parser.add_argument("--confidence-level", type=float, default=0.95, help="Confidence level for statistical tests (default: 0.95)")
    parser.add_argument("--params", help="Path to validation parameters YAML file")
    parser.add_argument("--no-graphs", action="store_true", help="Disable graph generation")
    
    args = parser.parse_args()
    
    # Set log level based on verbosity
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    # Create validator
    validator = DiversityValidator(
        catalog_file=args.catalog,
        metrics_dir=args.metrics_dir,
        expected_metrics_file=args.expected,
        results_dir=args.results_dir,
        vis_dir=args.vis_dir,
        chemistry=args.chemistry,
        min_samples=args.min_samples,
        verbose=args.verbose,
        confidence_level=args.confidence_level
    )
    
    # Run validation
    results = validator.run()
    
    # Save JSON results
    output_file = args.output
    if not output_file:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = os.path.join(args.results_dir, f"diversity_validation_{timestamp}.json")
    
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    logger.info(f"Saved validation results to {output_file}")
    
    # Generate a simple text report instead of HTML
    if args.report:
        report_path = args.report
    else:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_path = os.path.join(args.results_dir, f"diversity_report_{timestamp}.txt")

    # Create a simple text report
    with open(report_path, 'w') as f:
        f.write("Liu-Wei 2024 Sample Diversity Validation Report\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Chemistry: {args.chemistry}\n")
        f.write(f"Catalog: {args.catalog}\n\n")
        
        f.write("Summary\n")
        f.write("-" * 30 + "\n")
        f.write(f"Total samples: {results['summary']['total_samples']}\n")
        f.write(f"Samples analyzed: {results['summary']['samples_analyzed']}\n")
        f.write(f"Categories analyzed: {results['summary']['categories_analyzed']}\n")
        f.write(f"Benchmark pass rate: {results['summary']['pass_rate']:.1%}\n\n")
        
        f.write("Liu-Wei Benchmarks\n")
        f.write("-" * 30 + "\n")
        benchmarks = results.get("benchmarks", {})
        f.write(f"Alignment Rate: ≥{benchmarks.get('alignment_rate', 90.0):.1f}%\n")
        f.write(f"Mean Identity: ≥{benchmarks.get('mean_identity', 93.0):.1f}%\n")
        f.write(f"Mean Quality (Q-score): ≥{benchmarks.get('mean_quality', 11.0):.1f}\n\n")
        
        f.write("Diversity Analysis\n")
        f.write("-" * 30 + "\n")
        for category, analysis in results.get("diversity_analysis", {}).items():
            f.write(f"\n{category.upper()} DIVERSITY ANALYSIS\n")
            f.write(f"Analyzed {analysis['total_samples']} samples across {len(analysis['groups'])} {category} categories\n")
            
            f.write("\nGroup Sizes:\n")
            for group, size in analysis.get("groups", {}).items():
                f.write(f"  {group}: {size} samples\n")
            
            f.write("\nStatistical Results:\n")
            for metric, metric_analysis in analysis.get("metrics", {}).items():
                anova = metric_analysis.get("anova", {})
                f.write(f"  {metric}:\n")
                f.write(f"    Test: {anova.get('test', 'ANOVA')}\n")
                f.write(f"    Status: {anova.get('status', 'unknown')}\n")
                if anova.get("test") == "ANOVA":
                    f.write(f"    F-statistic: {anova.get('f_statistic', 'N/A')}\n")
                else:
                    f.write(f"    Statistic: {anova.get('statistic', 'N/A')}\n")
                f.write(f"    p-value: {anova.get('p_value', 'N/A')}\n")
                f.write(f"    Interpretation: {anova.get('interpretation', 'N/A')}\n")
            
            f.write("\nBenchmark Pass Rates:\n")
            benchmark_analysis = analysis.get("benchmark_pass_rates", {})
            f.write(f"  Test: {benchmark_analysis.get('test', 'chi_square')}\n")
            f.write(f"  Status: {benchmark_analysis.get('status', 'unknown')}\n")
            f.write(f"  p-value: {benchmark_analysis.get('p_value', 'N/A')}\n")
            f.write(f"  Interpretation: {benchmark_analysis.get('interpretation', 'N/A')}\n")
            
            if "contingency_table" in benchmark_analysis:
                f.write("\n  Pass Rates by Group:\n")
                for i, cat in enumerate(benchmark_analysis["contingency_table"].get("categories", [])):
                    pass_rate = benchmark_analysis["contingency_table"].get("pass_rates", [])[i]
                    f.write(f"    {cat}: {pass_rate:.1%}\n")
            
            f.write("\nVisualizations:\n")
            for vis in analysis.get("visualizations", []):
                f.write(f"  {vis}\n")
    
    logger.info(f"Generated report: {report_path}")
    
    # Create symlink to latest report
    latest_report = os.path.join(args.results_dir, "latest_diversity_report.txt")
    try:
        if os.path.exists(latest_report):
            os.remove(latest_report)
        os.symlink(report_path, latest_report)
        logger.info(f"Report is available at: {latest_report}")
    except Exception as e:
        logger.warning(f"Failed to create symlink: {e}")
    
    # Set exit code based on validation status
    if results.get("status") == "failed":
        logger.error(f"Validation failed: {results.get('message')}")
        sys.exit(1)
    else:
        logger.info(f"Validation {results.get('status')}: {results.get('message')}")
        sys.exit(0)

if __name__ == "__main__":
    main()# Add statistical tests for Kruskal-Wallis
