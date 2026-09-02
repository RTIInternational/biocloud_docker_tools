#!/usr/bin/env python3
"""
GWASLab plot_power CLI Wrapper

Generate theoretical GWAS power curves using gl.plot_power() or gl.plot_power_x().
"""

import argparse
import json
import sys
from pathlib import Path
import gwaslab as gl


def parse_args():
    parser = argparse.ArgumentParser(
        description="Plot theoretical GWAS power curves using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    # Output file
    parser.add_argument("--out", required=True, type=str, help="Output image file path (e.g. out.png, out.pdf).")

    # Mode & parameters
    parser.add_argument("--mode", type=str, default="q", choices=["q", "b"], help="Trait mode: 'q' for quantitative or 'b' for binary.")
    parser.add_argument("--extended", action="store_true", default=False, help="Use extended power grid (plot_power_x).")
    parser.add_argument("--ns", nargs="+", type=int, default=[10000, 20000, 50000], help="Sample sizes to plot.")
    parser.add_argument("--ncases", nargs="+", type=int, default=None, help="Case counts for binary traits.")
    parser.add_argument("--ncontrols", nargs="+", type=int, default=None, help="Control counts for binary traits.")
    parser.add_argument("--prevalences", nargs="+", type=float, default=None, help="Prevalences for binary traits.")
    parser.add_argument("--sig_levels", nargs="+", type=float, default=[5e-8], help="Significance levels.")
    parser.add_argument("--font_family", type=str, default="Arial", help="Font family.")
    parser.add_argument("--fontsize", type=int, default=12, help="Font size.")
    parser.add_argument("--fig_kwargs_json", type=str, default=None, help="JSON string for fig_kwargs.")

    return parser.parse_args()


def main():
    args = parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    kwargs = {
        "mode": args.mode,
        "sig_levels": args.sig_levels[0] if len(args.sig_levels) == 1 else args.sig_levels,
        "font_family": args.font_family,
        "fontsize": args.fontsize,
        "save": args.out
    }

    if args.mode == "q":
        kwargs["ns"] = args.ns
    elif args.mode == "b":
        if args.ncases:
            kwargs["ncases"] = args.ncases
        if args.ncontrols:
            kwargs["ncontrols"] = args.ncontrols
        if args.prevalences:
            kwargs["prevalences"] = args.prevalences

    if args.fig_kwargs_json:
        kwargs["fig_kwargs"] = json.loads(args.fig_kwargs_json)

    try:
        if args.extended:
            gl.plot_power_x(**kwargs)
        else:
            gl.plot_power(**kwargs)
        print(f"Successfully generated power plot: {args.out}")
    except Exception as e:
        print(f"Error generating power plot: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
