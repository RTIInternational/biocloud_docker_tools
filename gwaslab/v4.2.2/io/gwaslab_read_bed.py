#!/usr/bin/env python3
"""
GWASLab I/O: read_bed
Read a BED file into a pandas DataFrame.
"""

import argparse
import sys
from pathlib import Path
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Read and parse BED interval files using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--bed", required=True, type=str, help="Path to input BED file (.bed or .bed.gz).")
    parser.add_argument("--out", required=True, type=str, help="Output TSV file path for parsed BED table.")
    parser.add_argument("--usecols", nargs="+", type=int, default=None, help="Column indices to read (0-based).")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        bed_df = gl.read_bed(
            bed_path=args.bed,
            usecols=args.usecols
        )
        bed_df.to_csv(args.out, sep="\t", index=False)
        print(f"Successfully parsed BED ({len(bed_df)} records) to {args.out}")
    except Exception as e:
        print(f"Error in read_bed: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
