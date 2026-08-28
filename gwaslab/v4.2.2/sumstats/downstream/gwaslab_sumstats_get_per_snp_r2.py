#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: get_per_snp_r2 & get_ess
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


def save_sumstats(mysumstats, out_path, out_fmt="gwaslab", gzip=True):
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    clean_path = out_path
    if clean_path.endswith(".gz"):
        clean_path = clean_path[:-3]
    if clean_path.endswith(".tsv") or clean_path.endswith(".txt") or clean_path.endswith(".csv"):
        clean_path = Path(clean_path).stem
    mysumstats.to_format(clean_path, fmt=out_fmt, gzip=gzip)


def main():
    parser = argparse.ArgumentParser(
        description="Calculate per-SNP heritability (SNPR2), F-statistics, or effective sample size (N_EFF) in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--action", default="r2", choices=["r2", "ess"], help="Calculation to perform ('r2' for SNPR2/F, 'ess' for effective sample size).")
    parser.add_argument("--mode", type=str, default="q", choices=["q", "b"], help="Trait mode ('q' for quantitative, 'b' for binary).")
    parser.add_argument("--vary", default=1.0, help="Variance of phenotype Y or 'se'.")
    parser.add_argument("--prevalence", type=float, default=None, help="Disease prevalence for binary traits.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        if args.action == "r2":
            mysumstats.get_per_snp_r2(mode=args.mode, vary=args.vary, prevalence=args.prevalence)
        elif args.action == "ess":
            mysumstats.get_ess()
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully calculated {args.action} and saved to {args.out}")
    except Exception as e:
        print(f"Error in {args.action}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
