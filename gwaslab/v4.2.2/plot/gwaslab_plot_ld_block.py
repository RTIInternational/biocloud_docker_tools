#!/usr/bin/env python3
"""
GWASLab plot_ld_block CLI Wrapper

Plot an LD block as a 45-degree rotated triangle from a VCF or LD matrix using gl.plot_ld_block().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot LD block as an inverted triangle using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--region", required=True, type=str, help="Genomic locus formatted as chr:start-end (e.g. 1:1000000-2000000) or comma-separated chr,start,end.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")
    parser.add_argument("--vcf_path", type=str, default=None, help="Reference panel VCF for computing LD r^2.")
    parser.add_argument("--ld_path", type=str, default=None, help="Precomputed LD matrix path.")
    parser.add_argument("--sumstats", type=str, default=None, help="Optional summary statistics file for regional markers.")

    # Options
    parser.add_argument("--mode", type=str, default="standalone", help="Plot layout mode ('standalone' or 'regional').")
    parser.add_argument("--anno_cell", action="store_true", default=False, help="Annotate LD matrix cells with r^2 values.")
    parser.add_argument("--anno_cell_fmt", type=str, default="{:.2f}", help="Format string for cell r^2 annotations.")
    parser.add_argument("--cbar", action="store_true", default=True, help="Draw colorbar.")
    parser.add_argument("--cbar_label", type=str, default=r"LD $\mathregular{r^2}$ with variant", help="Colorbar label.")
    parser.add_argument("--cmap", type=str, default="YlOrRd", help="Colormap name.")
    parser.add_argument("--vmin", type=float, default=0.0, help="Minimum LD r^2 for colormap.")
    parser.add_argument("--vmax", type=float, default=1.0, help="Maximum LD r^2 for colormap.")
    parser.add_argument("--ld_block_grid", action="store_true", default=False, help="Draw grid lines on LD matrix triangle.")
    parser.add_argument("--title", type=str, default=None, help="Figure title.")
    parser.add_argument("--font_family", type=str, default="Arial", help="Font family.")
    parser.add_argument("--fontsize", type=int, default=10, help="Font size.")
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")

    return parser.parse_args()


def parse_region(region_str):
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

    region = parse_region(args.region)

    kwargs = {
        "region": region,
        "mode": args.mode,
        "anno_cell": args.anno_cell,
        "anno_cell_fmt": args.anno_cell_fmt,
        "cbar": args.cbar,
        "cbar_label": args.cbar_label,
        "cmap": args.cmap,
        "vmin": args.vmin,
        "vmax": args.vmax,
        "ld_block_grid": args.ld_block_grid,
        "font_family": args.font_family,
        "fontsize": args.fontsize,
        "save": args.out
    }

    if args.vcf_path:
        kwargs["vcf_path"] = args.vcf_path
    if args.ld_path:
        kwargs["ld_path"] = args.ld_path
    if args.sumstats:
        kwargs["sumstats"] = gl.Sumstats(args.sumstats, fmt="auto")
    if args.title:
        kwargs["title"] = args.title
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        gl.plot_ld_block(**kwargs)
        print(f"Successfully generated LD block plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_ld_block: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
