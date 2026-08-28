#!/usr/bin/env python3
"""
GWASLab plot_gwheatmap CLI Wrapper

Genome-wide association heatmap across traits or loci using gl.plot_gwheatmap().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Genome-wide association heatmap across traits/loci using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (or 'auto').")
    parser.add_argument("--group", type=str, default="CIS/TRANS", help="Grouping column name.")
    parser.add_argument("--cis_windowsizekb", type=int, default=100, help="Cis-window half-width in kb.")
    parser.add_argument("--add_b", action="store_true", default=False, help="Add Manhattan panel below.")
    parser.add_argument("--colors", nargs="+", default=["#597FBD", "#74BAD3"], help="Chromosome color palette.")
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
        "group": args.group,
        "cis_windowsizekb": args.cis_windowsizekb,
        "add_b": args.add_b,
        "colors": args.colors,
        "save": args.out
    }

    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        mysumstats.plot_gwheatmap(**kwargs)
        print(f"Successfully generated genome-wide heatmap plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_gwheatmap: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
