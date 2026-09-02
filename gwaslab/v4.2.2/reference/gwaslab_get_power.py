#!/usr/bin/env python3
"""
GWASLab Reference: get_power
Calculate statistical power for genetic association studies using gl.get_power().
"""

import argparse
import sys
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Calculate statistical power for genetic association studies using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--mode", type=str, default="q", choices=["q", "b"], help="Mode ('q' for quantitative, 'b' for binary).")
    parser.add_argument("--n", type=int, default=None, help="Sample size (quantitative mode).")
    parser.add_argument("--beta", type=float, default=None, help="Effect size (quantitative mode).")
    parser.add_argument("--eaf", type=float, default=0.2, help="Effect allele frequency.")
    parser.add_argument("--vary", type=float, default=1.0, help="Phenotype variance (quantitative mode).")
    parser.add_argument("--ncase", type=int, default=None, help="Case count (binary mode).")
    parser.add_argument("--ncontrol", type=int, default=None, help="Control count (binary mode).")
    parser.add_argument("--genotype_or", type=float, default=None, help="Genotype Odds Ratio (binary mode).")
    parser.add_argument("--genotype_rr", type=float, default=None, help="Genotype Relative Risk (binary mode).")
    parser.add_argument("--prevalence", type=float, default=0.01, help="Disease prevalence in population (binary mode).")
    parser.add_argument("--sig_level", type=float, default=5e-8, help="Significance threshold.")

    args = parser.parse_args()

    kwargs = {
        "mode": args.mode,
        "eaf": args.eaf,
        "sig_level": args.sig_level
    }

    if args.mode == "q":
        if args.n is None or args.beta is None:
            print("Error: --n and --beta are required for quantitative mode ('q').", file=sys.stderr)
            sys.exit(1)
        kwargs["n"] = args.n
        kwargs["beta"] = args.beta
        kwargs["vary"] = args.vary
    elif args.mode == "b":
        if args.ncase is None or args.ncontrol is None:
            print("Error: --ncase and --ncontrol are required for binary mode ('b').", file=sys.stderr)
            sys.exit(1)
        kwargs["ncase"] = args.ncase
        kwargs["ncontrol"] = args.ncontrol
        kwargs["prevalence"] = args.prevalence
        if args.genotype_or is not None:
            kwargs["genotype_or"] = args.genotype_or
        if args.genotype_rr is not None:
            kwargs["genotype_rr"] = args.genotype_rr

    try:
        power = gl.get_power(**kwargs)
        print(f"Calculated statistical power: {power}")
    except Exception as e:
        print(f"Error in get_power: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
