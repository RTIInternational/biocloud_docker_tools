#!/usr/bin/env python3
"""
Genomic SEM Preprocessing Script

This script reads a summary statistics file and extracts/renames columns
based on provided column name mappings. It also extracts rsID from variant_id
columns and outputs a gzipped TSV file.
"""

import argparse
import pandas as pd
import re
import sys
from pathlib import Path


def extract_rsid(variant_id):
    r"""
    Extract rsID from variant_id string.
    
    If the variant_id contains an rsID in the format /rs\d+/, extract it.
    Otherwise, return the value unchanged.
    
    Args:
        variant_id: String containing variant identifier
        
    Returns:
        rsID if found, otherwise the original value
    """
    if pd.isna(variant_id):
        return variant_id
    
    variant_id_str = str(variant_id)
    match = re.search(r'rs\d+', variant_id_str)
    
    if match:
        return match.group(0)
    else:
        return variant_id_str


def main():
    parser = argparse.ArgumentParser(
        description="Preprocess summary statistics for GenomicSEM analysis",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    # Required arguments
    parser.add_argument(
        '--sumstats_file',
        required=True,
        help='Path to the summary statistics file'
    )
    parser.add_argument(
        '--col_variant_id',
        required=True,
        help='Column name for variant ID'
    )
    parser.add_argument(
        '--col_effect_allele',
        required=True,
        help='Column name for effect allele'
    )
    parser.add_argument(
        '--col_non_effect_allele',
        required=True,
        help='Column name for non-effect allele'
    )
    parser.add_argument(
        '--col_effect',
        required=True,
        help='Column name for effect size'
    )
    parser.add_argument(
        '--col_p',
        required=True,
        help='Column name for p-value'
    )
    parser.add_argument(
        '--out_file',
        required=True,
        help='Output file path (will be gzipped)'
    )
    
    # Optional arguments
    parser.add_argument(
        '--sumstats_sep',
        default='\s+',
        help='Separator for the summary statistics file (optional)'
    )
    parser.add_argument(
        '--col_z',
        default=None,
        help='Column name for Z-score (optional)'
    )
    parser.add_argument(
        '--col_se',
        default=None,
        help='Column name for standard error (optional)'
    )
    parser.add_argument(
        '--col_n',
        default=None,
        help='Column name for sample size (optional)'
    )
    parser.add_argument(
        '--col_effect_allele_freq',
        default=None,
        help='Column name for effect allele frequency (optional)'
    )
    parser.add_argument(
        '--col_info',
        default=None,
        help='Column name for info score (optional)'
    )
    parser.add_argument(
        '--col_direction',
        default=None,
        help='Column name for direction (optional)'
    )
    
    args = parser.parse_args()
    
    # Read the summary statistics file
    try:
        df = pd.read_csv(
            args.sumstats_file,
            sep=args.sumstats_sep
        )
    except FileNotFoundError:
        print(f"Error: File '{args.sumstats_file}' not found.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Build list of columns to extract and their new names
    column_mappings = {}
    col_params = {
        'col_variant_id': args.col_variant_id,
        'col_effect_allele': args.col_effect_allele,
        'col_non_effect_allele': args.col_non_effect_allele,
        'col_effect': args.col_effect,
        'col_p': args.col_p,
        'col_z': args.col_z,
        'col_se': args.col_se,
        'col_n': args.col_n,
        'col_effect_allele_freq': args.col_effect_allele_freq,
        'col_info': args.col_info,
        'col_direction': args.col_direction,
    }
    
    # Process column mappings
    for param_name, col_name in col_params.items():
        if col_name is not None:
            # New column name is param_name minus "col_" prefix
            new_col_name = param_name[4:]  # Remove "col_" prefix
            column_mappings[col_name] = new_col_name
    
    # Verify all required columns exist in the dataframe
    missing_cols = [col for col in column_mappings.keys() if col not in df.columns]
    if missing_cols:
        print(f"Error: Missing columns in input file: {missing_cols}", file=sys.stderr)
        print(f"\nAvailable columns in input file:", file=sys.stderr)
        for col in df.columns:
            print(f"  - {col}", file=sys.stderr)
        print(f"\nNote: Check that --sumstats_sep matches your file's delimiter (default is whitespace).", file=sys.stderr)
        sys.exit(1)
    
    # Extract and rename columns
    df_subset = df[list(column_mappings.keys())].copy()
    df_subset.rename(columns=column_mappings, inplace=True)
    
    # Extract rsID from variant_id column
    if 'variant_id' in df_subset.columns:
        df_subset['variant_id'] = df_subset['variant_id'].apply(extract_rsid)
    
    # Handle output file path
    out_file = args.out_file
    if not out_file.endswith('.gz'):
        out_file = out_file + '.gz'
    
    # Ensure output directory exists
    output_dir = Path(out_file).parent
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Write gzipped TSV
    try:
        df_subset.to_csv(
            out_file,
            sep='\t',
            index=False,
            compression='gzip'
        )
        print(f"Successfully wrote output to {out_file}")
    except Exception as e:
        print(f"Error writing output file: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
