#!/usr/bin/env python3
"""
GWASLab compare_effect CLI Wrapper

Compare effect sizes between two GWAS summary statistics files using gl.compare_effect().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Compare effect sizes between two GWAS summary statistics datasets using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--path1", required=True, type=str, help="Path to first summary statistics file.")
    parser.add_argument("--path2", required=True, type=str, help="Path to second summary statistics file.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Layout & coordinate options
    parser.add_argument("--mode", type=str, default="scatter", help="Plot mode.")
    parser.add_argument("--build", type=str, default="19", help="Genome build ('19' or '38').")
    parser.add_argument("--sig_level", type=float, default=5e-8, help="Significance threshold.")
    parser.add_argument("--anno", action="store_true", default=False, help="Enable variant annotation.")
    parser.add_argument("--anno_max_rows", type=int, default=40, help="Maximum number of annotation rows.")
    parser.add_argument("--r_or_r2", type=str, default="r2", choices=["r", "r2"], help="Show r or r^2 statistic.")
    parser.add_argument("--r_se", action="store_true", default=False, help="Show regression standard error.")
    parser.add_argument("--null_beta", type=float, default=0.0, help="Null beta for hypothesis testing.")
    parser.add_argument("--legend_pos", type=str, default="upper left", help="Legend position.")
    parser.add_argument("--legend_title", type=str, default=r"$\mathregular{ P < 5 \times 10^{-8}}$ in:", help="Legend title.")
    parser.add_argument("--legend_title2", type=str, default="Heterogeneity test:", help="Second legend title.")
    parser.add_argument("--save_merged", action="store_true", default=False, help="Save merged dataset.")
    parser.add_argument("--verbose", action="store_true", default=True, help="Verbose logging.")

    # JSON kwargs for advanced customization
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")
    parser.add_argument("--scatter_kwargs_json", type=str, default=None, help="JSON string for scatter_kwargs.")
    parser.add_argument("--err_kwargs_json", type=str, default=None, help="JSON string for err_kwargs.")
    parser.add_argument("--anno_kwargs_json", type=str, default=None, help="JSON string for anno_kwargs.")

    return parser.parse_args()


def main():
    args = parse_args()

    # Ensure output parent directory exists
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    kwargs = {
        "path1": args.path1,
        "path2": args.path2,
        "mode": args.mode,
        "build": args.build,
        "sig_level": args.sig_level,
        "anno": args.anno,
        "anno_max_rows": args.anno_max_rows,
        "r_or_r2": args.r_or_r2,
        "r_se": args.r_se,
        "null_beta": args.null_beta,
        "legend_pos": args.legend_pos,
        "legend_title": args.legend_title,
        "legend_title2": args.legend_title2,
        "save_merged": args.save_merged,
        "save": args.out,
        "verbose": args.verbose
    }

    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)
    if args.scatter_kwargs_json:
        kwargs["scatter_kwargs"] = json.loads(args.scatter_kwargs_json)
    if args.err_kwargs_json:
        kwargs["err_kwargs"] = json.loads(args.err_kwargs_json)
    if args.anno_kwargs_json:
        kwargs["anno_kwargs"] = json.loads(args.anno_kwargs_json)

    try:
        gl.compare_effect(**kwargs)
        print(f"Successfully generated comparison plot: {args.out}")
    except Exception as e:
        print(f"Error generating compare_effect plot: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
