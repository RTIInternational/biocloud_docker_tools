#!/usr/bin/env python3
"""
GWASLab plot_stacked_mqq CLI Wrapper

Stacked Manhattan, QQ, or regional association plots across multiple Sumstats using gl.plot_stacked_mqq().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Stacked Manhattan/QQ/regional association plots using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats_files", required=True, nargs="+", help="Paths to summary statistics files to stack.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Options
    parser.add_argument("--titles", nargs="+", default=None, help="Titles for each stacked panel.")
    parser.add_argument("--mode", type=str, default="m", choices=["m", "qq", "mqq", "r"], help="Plot mode ('m', 'qq', 'mqq', 'r').")
    parser.add_argument("--region", type=str, default=None, help="Genomic locus (e.g. 1:1000000-2000000) for regional mode.")
    parser.add_argument("--vcf_path", type=str, default=None, help="VCF path for LD computation in regional mode.")
    parser.add_argument("--build", type=str, default="19", help="Genome build ('19' or '38').")
    parser.add_argument("--sig_level", type=float, default=5e-8, help="Significance threshold line.")
    parser.add_argument("--skip", type=float, default=0.0, help="Minimum -log10(P) to display.")
    parser.add_argument("--cut", type=float, default=0.0, help="Cap variant -log10(P) above this value.")
    parser.add_argument("--colors", nargs="+", default=["#597FBD", "#74BAD3"], help="Chromosome color palette.")
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

    objects = [gl.Sumstats(f, fmt="auto") for f in args.sumstats_files]

    kwargs = {
        "objects": objects,
        "mode": args.mode,
        "build": args.build,
        "sig_level": args.sig_level,
        "skip": args.skip,
        "cut": args.cut,
        "colors": args.colors,
        "save": args.out
    }

    if args.region:
        kwargs["region"] = parse_region(args.region)
    if args.vcf_path:
        kwargs["vcf_path"] = args.vcf_path
    if args.titles:
        kwargs["titles"] = args.titles
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        gl.plot_stacked_mqq(**kwargs)
        print(f"Successfully generated stacked MQQ plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_stacked_mqq: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
