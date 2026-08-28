#!/usr/bin/env python3
"""
GWASLab plot_sankey CLI Wrapper

Plot Sankey / alluvial diagram from categorical summary statistics columns using gl.plot_sankey().
"""

import argparse
import json
import sys
from pathlib import Path
import pandas as pd
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Sankey diagram for categorical sumstats columns using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics table or file.")
    parser.add_argument("--columns", required=True, nargs="+", help="Column names defining the ordered Sankey stages.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--sep", type=str, default="\t", help="Field delimiter if input is flat file.")
    parser.add_argument("--title", type=str, default=None, help="Figure title.")
    parser.add_argument("--color_by", type=str, default="first", help="Stage color assignment mode.")
    parser.add_argument("--node_color_mode", type=str, default="stacked", help="Node color mode.")
    parser.add_argument("--node_width", type=float, default=0.025, help="Width of node blocks.")
    parser.add_argument("--gap_frac", type=float, default=0.02, help="Gap fraction between nodes.")
    parser.add_argument("--link_alpha", type=float, default=0.55, help="Alpha opacity for flow links.")
    parser.add_argument("--font_family", type=str, default="Arial", help="Font family.")
    parser.add_argument("--fontsize", type=int, default=12, help="Font size.")
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")

    return parser.parse_args()


def main():
    args = parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = gl.Sumstats(args.sumstats, fmt="auto")
    except Exception:
        mysumstats = pd.read_csv(args.sumstats, sep=args.sep)

    kwargs = {
        "data": mysumstats,
        "columns": args.columns,
        "color_by": args.color_by,
        "node_color_mode": args.node_color_mode,
        "node_width": args.node_width,
        "gap_frac": args.gap_frac,
        "link_alpha": args.link_alpha,
        "font_family": args.font_family,
        "fontsize": args.fontsize,
        "save": args.out
    }

    if args.title:
        kwargs["title"] = args.title
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        gl.plot_sankey(**kwargs)
        print(f"Successfully generated Sankey plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_sankey: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
