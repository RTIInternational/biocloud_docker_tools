#!/usr/bin/env python3
"""
GWASLab scatter CLI Wrapper

Scatter plot comparing two columns from sumstats using gl.scatter().
"""

import argparse
import json
import sys
from pathlib import Path
import pandas as pd
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Scatter plot comparing two summary statistics columns using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file.")
    parser.add_argument("--x", required=True, type=str, help="Column name for x-axis.")
    parser.add_argument("--y", required=True, type=str, help="Column name for y-axis.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--sep", type=str, default="\t", help="Field delimiter if flat file.")
    parser.add_argument("--title", type=str, default=None, help="Figure title.")
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
        "df": mysumstats,
        "x": args.x,
        "y": args.y,
        "save": args.out
    }

    if args.title:
        kwargs["title"] = args.title
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        gl.scatter(**kwargs)
        print(f"Successfully generated scatter plot: {args.out}")
    except Exception as e:
        print(f"Error generating scatter plot: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
