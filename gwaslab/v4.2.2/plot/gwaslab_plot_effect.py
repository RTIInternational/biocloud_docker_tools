#!/usr/bin/env python3
"""
GWASLab plot_effect CLI Wrapper

Plot effect sizes with optional EAF and SNP r^2 side panels using gl.plot_effect().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot effect sizes with optional EAF and SNPR2 panels using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")
    parser.add_argument("--x", required=True, type=str, help="Column name for effect size (e.g. BETA, OR).")
    parser.add_argument("--y", required=True, type=str, help="Column name for variants or labels.")

    # Options
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (or 'auto').")
    parser.add_argument("--se", type=str, default="SE", help="Standard error column name.")
    parser.add_argument("--eaf", type=str, default="EAF", help="Effect allele frequency column.")
    parser.add_argument("--eaf_panel", action="store_true", default=False, help="Include EAF side panel.")
    parser.add_argument("--snpvar_panel", action="store_true", default=False, help="Include SNP variance panel.")
    parser.add_argument("--title", type=str, default=None, help="Figure title.")
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
        "x": args.x,
        "y": args.y,
        "se": args.se,
        "eaf": args.eaf,
        "save": args.out
    }

    if args.eaf_panel:
        kwargs["eaf_panel"] = args.eaf_panel
    if args.snpvar_panel:
        kwargs["snpvar_panel"] = args.snpvar_panel
    if args.title:
        kwargs["title"] = args.title
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        mysumstats.plot_effect(**kwargs)
        print(f"Successfully generated effect plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_effect: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
