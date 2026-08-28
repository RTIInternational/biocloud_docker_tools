#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: clump
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
        description="Perform LD clumping using PLINK2 through GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output prefix for clumping results.")
    parser.add_argument("--bfile", type=str, default=None, help="Prefix to PLINK binary files (.bed/.bim/.fam).")
    parser.add_argument("--pfile", type=str, default=None, help="Prefix to PLINK2 files (.pgen/.pvar/.psam).")
    parser.add_argument("--vcf", type=str, default=None, help="Path to reference VCF.")
    parser.add_argument("--clump_p1", type=float, default=5e-8, help="Primary significance threshold.")
    parser.add_argument("--clump_p2", type=float, default=1e-5, help="Secondary significance threshold.")
    parser.add_argument("--clump_r2", type=float, default=0.1, help="LD r^2 threshold.")
    parser.add_argument("--clump_kb", type=int, default=250, help="Clumping window size in kb.")
    parser.add_argument("--threads", type=int, default=4, help="PLINK2 threads.")
    parser.add_argument("--plink2", type=str, default="plink2", help="Path to PLINK2 executable.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        clumped_sumstats, clumps_df, logstr = mysumstats.clump(
            bfile=args.bfile,
            pfile=args.pfile,
            vcf=args.vcf,
            clump_p1=args.clump_p1,
            clump_p2=args.clump_p2,
            clump_r2=args.clump_r2,
            clump_kb=args.clump_kb,
            threads=args.threads,
            plink2=args.plink2,
            out=args.out
        )
        if clumped_sumstats is not None:
            clumped_sumstats.to_csv(f"{args.out}.clumped.tsv", sep="\t", index=False)
        if clumps_df is not None:
            clumps_df.to_csv(f"{args.out}.clumps.tsv", sep="\t", index=False)
        print(f"Successfully ran clumping: {args.out}.clumped.tsv")
    except Exception as e:
        print(f"Error in clump: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
