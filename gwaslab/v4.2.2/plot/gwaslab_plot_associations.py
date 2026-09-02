#!/usr/bin/env python3
"""
GWASLab plot_associations CLI Wrapper

Plot trait associations as a heatmap using gl.plot_associations().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot trait associations as a heatmap using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (or 'auto').")
    parser.add_argument("--values", type=str, default="Beta", help="Value column to plot in heatmap (e.g. Beta, OR).")
    parser.add_argument("--sort", type=str, default="P_GCV2", help="Sorting key or method.")
    parser.add_argument("--cmap", type=str, default="RdBu", help="Colormap name.")
    parser.add_argument("--title", type=str, default=None, help="Figure title.")
    parser.add_argument("--font_family", type=str, default="Arial", help="Font family.")
    parser.add_argument("--fontsize", type=int, default=12, help="Font size.")
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
        "values": args.values,
        "sort": args.sort,
        "cmap": args.cmap,
        "font_family": args.font_family,
        "fontsize": args.fontsize,
        "save": args.out
    }

    if args.title:
        kwargs["title"] = args.title
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        mysumstats.plot_associations(**kwargs)
        print(f"Successfully generated associations heatmap: {args.out}")
    except Exception as e:
        print(f"Error generating plot_associations: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
