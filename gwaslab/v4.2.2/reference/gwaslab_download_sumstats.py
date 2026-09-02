#!/usr/bin/env python3
"""
GWASLab Reference: download_sumstats
Download GWAS Catalog summary statistics for a given GCST accession.
"""

import argparse
import sys
from pathlib import Path
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Download GWAS Catalog summary statistics by GCST study accession using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--gcst_id", required=True, type=str, help="GWAS Catalog accession (e.g. 'GCST90002446').")
    parser.add_argument("--out_dir", type=str, default="./", help="Directory to store downloaded summary statistics.")
    parser.add_argument("--filename", type=str, default=None, help="Output filename.")
    parser.add_argument("--harmonised", action="store_true", default=True, help="Prioritize harmonised summary statistics.")
    parser.add_argument("--raw", action="store_false", dest="harmonised", help="Download raw files directly.")
    parser.add_argument("--overwrite", action="store_true", default=False, help="Overwrite existing output files.")

    args = parser.parse_args()

    Path(args.out_dir).mkdir(parents=True, exist_ok=True)

    try:
        downloaded = gl.download_sumstats(
            gcst_id=args.gcst_id,
            output_dir=args.out_dir,
            filename=args.filename,
            harmonised=args.harmonised,
            overwrite=args.overwrite
        )
        print(f"Successfully downloaded summary statistics to: {downloaded}")
    except Exception as e:
        print(f"Error in download_sumstats: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
