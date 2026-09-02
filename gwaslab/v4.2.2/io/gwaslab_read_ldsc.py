#!/usr/bin/env python3
"""
GWASLab I/O: read_ldsc
Read LDSC output files and parse heritability or genetic correlation results.
"""

import argparse
import sys
from pathlib import Path
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Parse LDSC heritability or genetic correlation log/output files in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--filelist", required=True, nargs="+", help="Paths to LDSC log or output files.")
    parser.add_argument("--out", required=True, type=str, help="Output TSV file path for parsed results table.")
    parser.add_argument("--mode", type=str, default="h2", choices=["h2", "rg"], help="Parsing mode: 'h2' for heritability, 'rg' for genetic correlation.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        results_df = gl.read_ldsc(filelist=args.filelist, mode=args.mode)
        if results_df is not None:
            results_df.to_csv(args.out, sep="\t", index=False)
            print(f"Successfully parsed LDSC {args.mode} results to {args.out}")
        else:
            print("No results parsed.", file=sys.stderr)
            Path(args.out).touch()
    except Exception as e:
        print(f"Error in read_ldsc: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
