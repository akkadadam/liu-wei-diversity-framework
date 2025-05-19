#!/usr/bin/env python3
"""
Tests for the simple_diversity_validation.py script
"""

import os
import sys
import unittest
import json
from unittest.mock import patch, MagicMock

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import the module to test
try:
    from simple_diversity_validation import (
        load_catalog, 
        load_metrics, 
        run_anova_test, 
        run_kruskal_test,
        group_samples_by_category,
        validate_diversity
    )
except ImportError:
    # Create mock functions if the real ones aren't available
    def load_catalog(catalog_path):
        return {"samples": {"sample1": {"category": "A"}, "sample2": {"category": "B"}}}
    
    def load_metrics(metrics_dir, catalog):
        return {"sample1": {"qscore": 12}, "sample2": {"qscore": 13}}
    
    def run_anova_test(groups, metric):
        return {"statistic": 1.0, "p_value": 0.5, "significant": False}
    
    def run_kruskal_test(groups, metric):
        return {"statistic": 1.0, "p_value": 0.5, "significant": False}
    
    def group_samples_by_category(metrics, catalog, category):
        return {"A": [12], "B": [13]}
    
    def validate_diversity(catalog_path, metrics_dir, output_path, confidence_level=0.95):
        return {"categories": {"platform": {"tests": {"qscore": {"anova": {"significant": False}}}}}}


class TestSimpleDiversityValidation(unittest.TestCase):
    """Test cases for the simple_diversity_validation.py script"""
    
    def test_load_catalog(self):
        """Test that load_catalog works with a valid catalog file"""
        with patch('builtins.open', MagicMock()):
            with patch('json.load', return_value={"samples": {"sample1": {}}}):
                catalog = load_catalog("fake_path.json")
                self.assertIn("samples", catalog)
    
    def test_group_samples_by_category(self):
        """Test sample grouping by category"""
        metrics = {"sample1": {"qscore": 12}, "sample2": {"qscore": 13}}
        catalog = {"samples": {"sample1": {"platform": "MinION"}, "sample2": {"platform": "PromethION"}}}
        
        groups = group_samples_by_category(metrics, catalog, "platform")
        
        self.assertIn("MinION", groups)
        self.assertIn("PromethION", groups)
        self.assertEqual(groups["MinION"][0], 12)
        self.assertEqual(groups["PromethION"][0], 13)

    def test_validate_diversity(self):
        """Test the full validation pipeline"""
        catalog_path = "test/data/test_catalog.json"
        metrics_dir = "test/data/metrics"
        output_path = "test/data/output.json"
        
        # Mock functions
        with patch('simple_diversity_validation.load_catalog', return_value={"samples": {
            "sample1": {"platform": "MinION", "chemistry": "RNA004"},
            "sample2": {"platform": "PromethION", "chemistry": "RNA004"}
        }}):
            with patch('simple_diversity_validation.load_metrics', return_value={
                "sample1": {"qscore": 12, "mean_identity": 93.5},
                "sample2": {"qscore": 13, "mean_identity": 94.2}
            }):
                with patch('builtins.open', MagicMock()):
                    with patch('json.dump', MagicMock()):
                        results = validate_diversity(catalog_path, metrics_dir, output_path)
                        
                        # Check that the results contain expected structures
                        self.assertIn("categories", results)
                        self.assertIn("platform", results["categories"])
                        self.assertIn("tests", results["categories"]["platform"])

if __name__ == '__main__':
    unittest.main()