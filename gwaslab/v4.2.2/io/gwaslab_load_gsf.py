#!/usr/bin/env python3
"""
GWASLab I/O: load_gsf
Load GWAS sumstats from GSF (GWASLab Standard Format) file.
"""

import argparse
import sys
from pathlib import Path
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Load summary statistics from GSF format and export to TSV/other formats in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--gsf_path", required=True, type=str, help="Path to input .gsf file or partitioned directory.")
    parser.add_argument("--out", required=True, type=str, help="Output file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--columns", nargs="+", default=None, help="Columns to read (default: all).")
    parser.add_argument("--filters", type=str, default=None, help="Filter expression for predicate pushdown (e.g. 'P < 5e-8 & CHR == 1').")

    args = parser.parse_args()

    try:
        mysumstats = gl.load_gsf(path=args.gsf_path, columns=args.columns, filters=args.filters)
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        clean_path = args.out
        if clean_path.endswith(".gz"):
            clean_path = clean_path[:-3]
        if clean_path.endswith(".tsv") or clean_path.endswith(".txt") or clean_path.endswith(".csv"):
            clean_path = Path(clean_path).stem
        mysumstats.to_format(clean_path, fmt=args.out_fmt)
        print(f"Successfully loaded GSF and exported to {args.out}")
    except Exception as e:
        print(f"Error in load_gsf: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
