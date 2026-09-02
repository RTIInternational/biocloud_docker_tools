#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: estimate_h2_by_ldsc & estimate_rg_by_ldsc
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
        description="Estimate SNP heritability (h2) or genetic correlation (rg) via LDSC in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output TSV file path for LDSC results.")
    parser.add_argument("--action", default="h2", choices=["h2", "rg"], help="LDSC analysis mode ('h2' or 'rg').")
    parser.add_argument("--ref_ld_chr", required=True, type=str, help="Path/prefix to reference LD score files (e.g. eur_w_ld_chr/).")
    parser.add_argument("--w_ld_chr", required=True, type=str, help="Path/prefix to LD weights files.")
    parser.add_argument("--other_sumstats", nargs="+", default=None, help="Paths to other summary statistics files for rg.")
    parser.add_argument("--samp_prev", type=float, default=None, help="Sample prevalence for binary traits.")
    parser.add_argument("--pop_prev", type=float, default=None, help="Population prevalence for binary traits.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        if args.action == "h2":
            mysumstats.estimate_h2_by_ldsc(
                ref_ld_chr=args.ref_ld_chr,
                w_ld_chr=args.w_ld_chr,
                samp_prev=args.samp_prev,
                pop_prev=args.pop_prev
            )
            if hasattr(mysumstats, "ldsc_h2_results") and mysumstats.ldsc_h2_results is not None:
                mysumstats.ldsc_h2_results.to_csv(args.out, sep="\t", index=False)
        elif args.action == "rg":
            other_objs = [gl.Sumstats(f, fmt="auto") for f in args.other_sumstats] if args.other_sumstats else []
            mysumstats.estimate_rg_by_ldsc(
                other_traits=other_objs,
                ref_ld_chr=args.ref_ld_chr,
                w_ld_chr=args.w_ld_chr
            )
            if hasattr(mysumstats, "ldsc_rg") and mysumstats.ldsc_rg is not None:
                mysumstats.ldsc_rg.to_csv(args.out, sep="\t", index=False)
        print(f"Successfully ran LDSC {args.action} and saved results to {args.out}")
    except Exception as e:
        print(f"Error in estimate_{args.action}_by_ldsc: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
