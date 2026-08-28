#!/usr/bin/env python3
"""
GWASLab plot_lead_overlap CLI Wrapper

Venn or UpSet plot of lead variant / loci overlap across studies using gl.plot_lead_overlap().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Venn/UpSet diagram of lead variant overlap across studies using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats_files", required=True, nargs="+", help="List of summary statistics files to compare.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--titles", nargs="+", default=None, help="Labels/titles for each study.")
    parser.add_argument("--mode", type=str, default="auto", choices=["auto", "venn", "upset"], help="Plot mode ('venn', 'upset', or 'auto').")
    parser.add_argument("--build", type=str, default="19", help="Genome build ('19' or '38').")
    parser.add_argument("--sig_level", type=float, default=5e-8, help="Significance threshold for lead variants.")
    parser.add_argument("--windowsizekb", type=int, default=500, help="Window size (kb) for lead variant extraction.")
    parser.add_argument("--windowsizekb_for_overlap", type=int, default=1000, help="Window size (kb) for locus overlap determination.")
    parser.add_argument("--show_genes", action="store_true", default=True, help="Show annotated gene names.")
    parser.add_argument("--show_counts", action="store_true", default=True, help="Show counts in overlap regions.")
    parser.add_argument("--sort_by", type=str, default="count", choices=["count", "degree"], help="Sorting mode for UpSet plot.")
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")

    return parser.parse_args()


def main():
    args = parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    objects = [gl.Sumstats(f, fmt="auto") for f in args.sumstats_files]

    kwargs = {
        "objects": objects,
        "mode": args.mode,
        "build": args.build,
        "sig_level": args.sig_level,
        "windowsizekb": args.windowsizekb,
        "windowsizekb_for_overlap": args.windowsizekb_for_overlap,
        "show_genes": args.show_genes,
        "show_counts": args.show_counts,
        "sort_by": args.sort_by,
        "save": args.out
    }

    if args.titles:
        kwargs["titles"] = args.titles
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        gl.plot_lead_overlap(**kwargs)
        print(f"Successfully generated lead overlap plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_lead_overlap: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
