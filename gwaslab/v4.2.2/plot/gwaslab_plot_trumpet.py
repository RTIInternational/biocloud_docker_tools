#!/usr/bin/env python3
"""
GWASLab plot_trumpet CLI Wrapper

Trumpet plot for quantitative or binary GWAS summary statistics using gl.plot_trumpet().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Trumpet plot (MAF vs effect size) using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (or 'auto').")
    parser.add_argument("--mode", type=str, default="q", choices=["q", "b"], help="Trait mode ('q' for quantitative, 'b' for binary).")
    parser.add_argument("--build", type=str, default="19", help="Genome build ('19' or '38').")
    parser.add_argument("--sig_level", type=float, default=5e-8, help="Significance threshold for power lines.")
    parser.add_argument("--anno", action="store_true", default=False, help="Annotate variants.")
    parser.add_argument("--highlight", nargs="+", default=[], help="List of variant IDs to highlight.")
    parser.add_argument("--n", type=int, default=None, help="Sample size (for quantitative mode power lines).")
    parser.add_argument("--ncase", type=int, default=None, help="Case count (for binary mode).")
    parser.add_argument("--ncontrol", type=int, default=None, help="Control count (for binary mode).")
    parser.add_argument("--prevalence", type=float, default=None, help="Disease prevalence (for binary mode).")
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
        "mode": args.mode,
        "build": args.build,
        "sig_level": args.sig_level,
        "anno": "GENENAME" if args.anno else False,
        "highlight": args.highlight,
        "save": args.out
    }

    if args.n:
        kwargs["n"] = args.n
    if args.ncase:
        kwargs["ncase"] = args.ncase
    if args.ncontrol:
        kwargs["ncontrol"] = args.ncontrol
    if args.prevalence:
        kwargs["prevalence"] = args.prevalence
    if args.title:
        kwargs["title"] = args.title
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        mysumstats.plot_trumpet(**kwargs)
        print(f"Successfully generated trumpet plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_trumpet: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
