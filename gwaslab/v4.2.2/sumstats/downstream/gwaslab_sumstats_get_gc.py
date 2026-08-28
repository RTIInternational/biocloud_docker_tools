#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: get_gc
"""

import argparse
import sys
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
        description="Calculate the Genomic Inflation Factor (Lambda GC) in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--mode", type=str, default="P", choices=["P", "MLOG10P", "Z", "CHISQ"], help="Input metric to use for calculation.")
    parser.add_argument("--include_chrXYMT", action="store_true", default=False, help="Include sex/MT chromosomes.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        lambda_gc = mysumstats.get_gc(mode=args.mode, include_chrXYMT=args.include_chrXYMT)
        print(f"Genomic Inflation Factor (Lambda GC): {lambda_gc}")
    except Exception as e:
        print(f"Error in get_gc: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
