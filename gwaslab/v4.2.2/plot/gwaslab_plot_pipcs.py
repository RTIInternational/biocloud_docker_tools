#!/usr/bin/env python3
"""
GWASLab plot_pipcs CLI Wrapper

Plot fine-mapping credible sets and PIPs in a regional view using gl.plot_pipcs().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot fine-mapping credible sets (CS) and PIP values using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file with finemapping results.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (or 'auto').")
    parser.add_argument("--region", type=str, default=None, help="Genomic locus (e.g. 1:1000000-2000000).")
    parser.add_argument("--locus", type=str, default=None, help="Locus label for credible sets.")
    parser.add_argument("--pip", type=str, default="PIP", help="PIP column name.")
    parser.add_argument("--cs", type=str, default="CREDIBLE_SET_INDEX", help="Credible set index column name.")
    parser.add_argument("--onlycs", action="store_true", default=False, help="Plot only variants assigned to a credible set.")
    parser.add_argument("--title", type=str, default=None, help="Figure title.")
    parser.add_argument("--font_family", type=str, default="Arial", help="Font family.")
    parser.add_argument("--fontsize", type=int, default=12, help="Font size.")
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")

    return parser.parse_args()


def parse_region(region_str):
    if not region_str:
        return None
    if ":" in region_str and "-" in region_str:
        chrom, span = region_str.split(":", 1)
        start, end = span.split("-", 1)
        return (chrom.replace("chr", ""), int(start), int(end))
    elif "," in region_str:
        parts = region_str.split(",")
        return (parts[0].replace("chr", ""), int(parts[1]), int(parts[2]))
    return region_str


def main():
    args = parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = gl.Sumstats(args.sumstats, fmt=args.fmt)
    except Exception as e:
        print(f"Error loading summary statistics: {e}", file=sys.stderr)
        sys.exit(1)

    kwargs = {
        "pip": args.pip,
        "cs": args.cs,
        "onlycs": args.onlycs,
        "font_family": args.font_family,
        "fontsize": args.fontsize,
        "save": args.out
    }

    if args.region:
        kwargs["region"] = parse_region(args.region)
    if args.locus:
        kwargs["locus"] = args.locus
    if args.title:
        kwargs["title"] = args.title
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        mysumstats.plot_pipcs(**kwargs)
        print(f"Successfully generated PIP-CS plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_pipcs: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
