#!/usr/bin/env python3
"""
GWASLab plot_forest CLI Wrapper

Forest plot for meta-analysis study effects using gl.plot_forest().
"""

import argparse
import json
import sys
from pathlib import Path
import pandas as pd
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Forest plot for meta-analysis study effects using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--data", required=True, type=str, help="Path to input table (TSV/CSV) containing study effects.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")
    parser.add_argument("--beta_col", required=True, type=str, help="Column name for effect sizes (BETA/OR).")
    parser.add_argument("--se_col", required=True, type=str, help="Column name for standard errors.")

    # Optional styling and grouping options
    parser.add_argument("--sep", type=str, default="\t", help="Field delimiter for input data table.")
    parser.add_argument("--study_col", type=str, default=None, help="Column name for study/cohort labels.")
    parser.add_argument("--group_col", type=str, default=None, help="Column name for grouping/stratification.")
    parser.add_argument("--font_family", type=str, default="Arial", help="Font family.")
    parser.add_argument("--fontsize", type=int, default=12, help="Font size.")
    parser.add_argument("--colors", nargs="+", default=["#597FBD", "#74BAD3"], help="Color palette list.")
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")
    parser.add_argument("--save_kwargs_json", type=str, default=None, help="JSON string for save_kwargs.")

    return parser.parse_args()


def main():
    args = parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        df = pd.read_csv(args.data, sep=args.sep)
    except Exception as e:
        print(f"Error loading input data table: {e}", file=sys.stderr)
        sys.exit(1)

    kwargs = {
        "data": df,
        "beta_col": args.beta_col,
        "se_col": args.se_col,
        "font_family": args.font_family,
        "fontsize": args.fontsize,
        "colors": args.colors,
        "save": args.out
    }

    if args.study_col:
        kwargs["study_col"] = args.study_col
    if args.group_col:
        kwargs["group_col"] = args.group_col
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)
    if args.save_kwargs_json:
        kwargs["save_kwargs"] = json.loads(args.save_kwargs_json)

    try:
        gl.plot_forest(**kwargs)
        print(f"Successfully generated forest plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_forest: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
