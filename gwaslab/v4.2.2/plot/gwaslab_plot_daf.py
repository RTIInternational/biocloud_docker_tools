#!/usr/bin/env python3
"""
GWASLab plot_daf CLI Wrapper

Plot Discovery Allele Frequency (DAF) or EAF vs reference allele frequency using gl.plot_daf().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot allele frequency comparisons (DAF/EAF vs RAF) using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (or 'auto').")
    parser.add_argument("--eaf", type=str, default="EAF", help="Effect allele frequency column.")
    parser.add_argument("--raf", type=str, default="RAF", help="Reference allele frequency column.")
    parser.add_argument("--daf", type=str, default="DAF", help="Discovery allele frequency column.")
    parser.add_argument("--r2", action="store_true", default=False, help="Show R-squared statistic.")
    parser.add_argument("--is_45_helper_line", action="store_true", default=True, help="Draw 45-degree helper line.")
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")

    return parser.parse_args()


def main():
    args = parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = gl.Sumstats(args.sumstats, fmt=args.fmt)
    except Exception as e:
        print(f"Error loading summary statistics: {e}", file=sys.stderr)
        sys.exit(1)

    kwargs = {
        "eaf": args.eaf,
        "raf": args.raf,
        "daf": args.daf,
        "r2": args.r2,
        "is_45_helper_line": args.is_45_helper_line,
        "save": args.out
    }

    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        mysumstats.plot_daf(**kwargs)
        print(f"Successfully generated DAF plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_daf: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
