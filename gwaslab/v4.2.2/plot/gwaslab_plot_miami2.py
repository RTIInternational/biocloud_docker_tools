#!/usr/bin/env python3
"""
GWASLab plot_miami2 CLI Wrapper

Mirrored Manhattan plot comparing two traits/studies using gl.plot_miami2().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Mirrored Manhattan plot comparing two traits using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Required inputs
    parser.add_argument("--path1", required=True, type=str, help="Path to first summary statistics file.")
    parser.add_argument("--path2", required=True, type=str, help="Path to second summary statistics file.")
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Titles and labels
    parser.add_argument("--titles", nargs=2, default=None, help="Titles for upper and lower panels.")
    parser.add_argument("--id1", type=str, default="Study 1", help="Identifier for study 1.")
    parser.add_argument("--id2", type=str, default="Study 2", help="Identifier for study 2.")

    # Thresholds & filtering
    parser.add_argument("--build", type=str, default="19", help="Genome build ('19' or '38').")
    parser.add_argument("--sig_level", type=float, default=5e-8, help="Significance threshold line.")
    parser.add_argument("--suggestive_sig_level", type=float, default=5e-6, help="Suggestive significance threshold.")
    parser.add_argument("--suggestive_sig_line", action="store_true", default=False, help="Draw suggestive significance line.")
    parser.add_argument("--skip", type=float, default=0.0, help="Minimum -log10(P) to display.")
    parser.add_argument("--cut", type=float, default=0.0, help="Cap variant -log10(P) above this threshold.")
    parser.add_argument("--anno", action="store_true", default=False, help="Annotate lead variants.")
    parser.add_argument("--anno_max_rows", type=int, default=40, help="Maximum number of annotations.")
    parser.add_argument("--highlight", nargs="+", default=[], help="List of variant IDs to highlight.")
    parser.add_argument("--colors", nargs="+", default=["#597FBD", "#74BAD3"], help="Alternating chromosome colors.")

    # JSON options
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")

    return parser.parse_args()


def main():
    args = parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    kwargs = {
        "path1": args.path1,
        "path2": args.path2,
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
        "id1": args.id1,
        "id2": args.id2,
        "save": args.out
    }

    if args.titles:
        kwargs["titles"] = args.titles
    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        gl.plot_miami2(**kwargs)
        print(f"Successfully generated Miami plot: {args.out}")
    except Exception as e:
        print(f"Error generating plot_miami2: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
