#!/usr/bin/env python3
"""
GWASLab plot_mqq CLI Wrapper

Generate Manhattan, QQ, Manhattan-QQ (MQQ), Regional, or Brisbane-style SNP density plots from GWAS summary statistics.
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate Manhattan, QQ, and Regional plots from GWAS summary statistics using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input GWAS summary statistics file.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Mode selection
    parser.add_argument("--mode", type=str, default="mqq", choices=["mqq", "m", "qq", "r", "b"],
                        help="Plot mode: 'mqq' (Manhattan+QQ), 'm' (Manhattan), 'qq' (QQ), 'r' (Regional), 'b' (Brisbane density).")

    # Format / Columns
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (or 'auto').")
    parser.add_argument("--build", type=str, default="19", help="Genome build ('19' or '38').")

    # Thresholds & filters
    parser.add_argument("--sig_level", type=float, default=5e-8, help="Genome-wide significance threshold.")
    parser.add_argument("--suggestive_sig_level", type=float, default=5e-6, help="Suggestive significance threshold.")
    parser.add_argument("--suggestive_sig_line", action="store_true", default=False, help="Draw suggestive significance line.")
    parser.add_argument("--skip", type=float, default=0.0, help="Minimum -log10(P) to display.")
    parser.add_argument("--cut", type=float, default=0.0, help="Cap variant -log10(P) above this threshold.")

    # Annotation & Highlighting
    parser.add_argument("--anno", action="store_true", default=False, help="Annotate lead variants with nearest gene name.")
    parser.add_argument("--anno_max_rows", type=int, default=40, help="Maximum number of annotations to show.")
    parser.add_argument("--highlight", nargs="+", default=[], help="List of variant IDs to highlight.")
    parser.add_argument("--colors", nargs="+", default=["#597FBD", "#74BAD3"], help="Alternating chromosome colors.")

    # Regional plot options (mode='r')
    parser.add_argument("--region", type=str, default=None, help="Locus region for regional plot (e.g. 1:1000000-2000000).")
    parser.add_argument("--vcf_path", type=str, default=None, help="Reference panel VCF for LD calculation.")
    parser.add_argument("--ld_path", type=str, default=None, help="Precomputed LD matrix path.")
    parser.add_argument("--ld_block", action="store_true", default=False, help="Include LD block matrix panel.")

    # Titles & Labels
    parser.add_argument("--title", type=str, default=None, help="Figure title.")
    parser.add_argument("--mtitle", type=str, default=None, help="Manhattan panel title.")
    parser.add_argument("--qtitle", type=str, default=None, help="QQ panel title.")

    # Advanced styling via JSON
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
        "mode": args.mode,
        "build": args.build,
        "sig_level": args.sig_level,
        "suggestive_sig_level": args.suggestive_sig_level,
        "suggestive_sig_line": args.suggestive_sig_line,
        "skip": args.skip,
        "cut": args.cut,
        "anno": "GENENAME" if args.anno else False,
        "anno_max_rows": args.anno_max_rows,
        "highlight": args.highlight,
        "colors": args.colors,
        "save": args.out
    }

    if args.title:
        kwargs["title"] = args.title
    if args.mtitle:
        kwargs["mtitle"] = args.mtitle
    if args.qtitle:
        kwargs["qtitle"] = args.qtitle
    if args.region:
        kwargs["region"] = parse_region(args.region)
    if args.vcf_path:
        kwargs["vcf_path"] = args.vcf_path
    if args.ld_path:
        kwargs["ld_path"] = args.ld_path
    if args.ld_block:
        kwargs["ld_block"] = args.ld_block
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        mysumstats.plot_mqq(**kwargs)
        print(f"Successfully generated {args.mode} plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_mqq: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
