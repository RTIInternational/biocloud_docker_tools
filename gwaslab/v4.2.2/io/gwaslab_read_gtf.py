#!/usr/bin/env python3
"""
GWASLab I/O: read_gtf
Fast GTF file reader using Polars/Pandas.
"""

import argparse
import sys
from pathlib import Path
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Parse and filter GTF gene annotation files using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--gtf", required=True, type=str, help="Path to input GTF file (.gtf or .gtf.gz).")
    parser.add_argument("--out", required=True, type=str, help="Output TSV file path for parsed GTF table.")
    parser.add_argument("--chrom", type=str, default=None, help="Filter by chromosome early (e.g. '1', 'chr1', 'X').")
    parser.add_argument("--features", nargs="+", default=None, help="Filter features (e.g. 'gene', 'transcript', 'exon').")
    parser.add_argument("--usecols", nargs="+", default=None, help="Restrict columns to load.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    features_set = set(args.features) if args.features else None

    try:
        gtf_df = gl.read_gtf(
            filepath_or_buffer=args.gtf,
            chrom=args.chrom,
            features=features_set,
            usecols=args.usecols
        )
        gtf_df.to_csv(args.out, sep="\t", index=False)
        print(f"Successfully parsed GTF ({len(gtf_df)} records) to {args.out}")
    except Exception as e:
        print(f"Error in read_gtf: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
