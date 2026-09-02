#!/usr/bin/env python3
"""
GWASLab plot_phenogram CLI Wrapper

Karyotype-style phenogram plot using gl.plot_phenogram().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Karyotype-style phenogram plot with cytobands using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (or 'auto').")
    parser.add_argument("--build", type=str, default="19", help="Genome build ('19' or '38').")
    parser.add_argument("--sig_level", type=float, default=5e-8, help="Significance threshold for extracting leads.")
    parser.add_argument("--windowsizekb", type=int, default=500, help="Window size (kb) for lead variant extraction.")
    parser.add_argument("--anno_max_rows", type=int, default=200, help="Maximum number of annotations to show.")
    parser.add_argument("--include_sex_chr", action="store_true", default=False, help="Include chrX and chrY.")
    parser.add_argument("--show_legend", action="store_true", default=True, help="Show legend.")
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
        "build": args.build,
        "sig_level": args.sig_level,
        "windowsizekb": args.windowsizekb,
        "anno_max_rows": args.anno_max_rows,
        "include_sex_chr": args.include_sex_chr,
        "show_legend": args.show_legend,
        "save": args.out
    }

    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        mysumstats.plot_phenogram(**kwargs)
        print(f"Successfully generated phenogram plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_phenogram: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
