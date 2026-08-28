#!/usr/bin/env python3
"""
GWASLab plot_rg CLI Wrapper

Genetic correlation heatmap from LDSC results using gl.plot_rg().
"""

import argparse
import json
import sys
from pathlib import Path
import pandas as pd
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot genetic correlation (rg) heatmap from LDSC results using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--ldscrg", required=True, type=str, help="Path to LDSC genetic correlation log or parsed table.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--p", type=str, default="p", help="P-value column name.")
    parser.add_argument("--rg", type=str, default="rg", help="rg correlation column name.")
    parser.add_argument("--p1", type=str, default="p1", help="Trait 1 column name.")
    parser.add_argument("--p2", type=str, default="p2", help="Trait 2 column name.")
    parser.add_argument("--cmap", type=str, default="RdBu_r", help="Colormap name.")
    parser.add_argument("--fdr_method", type=str, default="bh", choices=["bh", "by", "bonferroni"], help="FDR correction method.")
    parser.add_argument("--fontsize", type=int, default=12, help="Font size.")
    parser.add_argument("--asize", type=int, default=10, help="Annotation text size.")
    parser.add_argument("--square", action="store_true", default=False, help="Force square cells.")
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")

    return parser.parse_args()


def main():
    args = parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    kwargs = {
        "ldscrg": args.ldscrg,
        "p": args.p,
        "rg": args.rg,
        "p1": args.p1,
        "p2": args.p2,
        "cmap": args.cmap,
        "fdr_method": args.fdr_method,
        "fontsize": args.fontsize,
        "asize": args.asize,
        "square": args.square,
        "save": args.out
    }

    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        gl.plot_rg(**kwargs)
        print(f"Successfully generated rg heatmap: {args.out}")
    except Exception as e:
        print(f"Error generating plot_rg: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
