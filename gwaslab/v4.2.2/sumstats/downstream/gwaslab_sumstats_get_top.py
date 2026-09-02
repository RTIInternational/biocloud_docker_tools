#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: get_top & get_novel
"""

import argparse
import sys
from pathlib import Path
import gwaslab as gl


def add_sumstats_args(parser):
    parser.add_argument("--sumstats", required=True, type=str, help="Path to input summary statistics file.")
    parser.add_argument("--fmt", type=str, default="auto", help="Input format identifier (e.g. 'auto', 'plink2', 'vcf', etc.).")
    parser.add_argument("--snpid", type=str, default=None, help="Column name for variant ID.")
    parser.add_argument("--rsid", type=str, default=None, help="Column name for rsID.")
    parser.add_argument("--chrom", type=str, default=None, help="Column name for chromosome.")
    parser.add_argument("--pos", type=str, default=None, help="Column name for position.")
    parser.add_argument("--ea", type=str, default=None, help="Column name for effect allele.")
    parser.add_argument("--nea", type=str, default=None, help="Column name for non-effect allele.")
    parser.add_argument("--eaf", type=str, default=None, help="Column name for effect allele frequency.")
    parser.add_argument("--beta", type=str, default=None, help="Column name for beta.")
    parser.add_argument("--se", type=str, default=None, help="Column name for standard error.")
    parser.add_argument("--p", type=str, default=None, help="Column name for p-value.")
    parser.add_argument("--mlog10p", type=str, default=None, help="Column name for -log10(p).")
    parser.add_argument("--n", type=str, default=None, help="Column name or constant for sample size.")
    parser.add_argument("--build", type=str, default="99", help="Genome build version (e.g. '19', '38', '99').")


def load_sumstats(args):
    init_kwargs = {"sumstats": args.sumstats, "fmt": args.fmt, "build": args.build}
    for col in ["snpid", "rsid", "chrom", "pos", "ea", "nea", "eaf", "beta", "se", "p", "mlog10p", "n"]:
        val = getattr(args, col, None)
        if val is not None:
            init_kwargs[col] = val
    return gl.Sumstats(**init_kwargs)


def main():
    parser = argparse.ArgumentParser(
        description="Extract top variants by metric or novel variants against GWAS Catalog in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output TSV file path.")
    parser.add_argument("--action", required=True, choices=["top", "novel", "density"], help="Operation to perform.")
    parser.add_argument("--by", type=str, default="DENSITY", help="Column name to maximize for 'top' action.")
    parser.add_argument("--known", type=str, default=None, help="Path to known variants file for 'novel' action.")
    parser.add_argument("--efo", nargs="+", default=None, help="EFO / MONDO trait IDs for GWAS Catalog querying.")
    parser.add_argument("--only_novel", action="store_true", default=False, help="Return only novel variants.")
    parser.add_argument("--windowsizekb", type=int, default=500, help="Window size in kb.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        if args.action == "top":
            df = mysumstats.get_top(by=args.by, windowsizekb=args.windowsizekb)
        elif args.action == "novel":
            df = mysumstats.get_novel(
                known=args.known,
                efo=args.efo,
                only_novel=args.only_novel,
                windowsizekb=args.windowsizekb
            )
        elif args.action == "density":
            df = mysumstats.get_density(windowsizekb=args.windowsizekb)

        if df is not None:
            df.to_csv(args.out, sep="\t", index=False)
            print(f"Successfully ran {args.action} and saved results to {args.out}")
        else:
            Path(args.out).touch()
    except Exception as e:
        print(f"Error in {args.action}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
