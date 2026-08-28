#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: get_lead
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
        description="Extract lead variants by P-value using sliding window approach in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output TSV file path for lead variants table.")
    parser.add_argument("--windowsizekb", type=int, default=500, help="Window size in kb for lead variant extraction.")
    parser.add_argument("--sig_level", type=float, default=5e-8, help="Significance threshold for lead variants.")
    parser.add_argument("--anno", action="store_true", default=False, help="Annotate lead variants with nearest gene names.")
    parser.add_argument("--wc_correction", action="store_true", default=False, help="Apply Winner's Curse correction to effect sizes.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        lead_df = mysumstats.get_lead(
            windowsizekb=args.windowsizekb,
            sig_level=args.sig_level,
            anno=args.anno,
            wc_correction=args.wc_correction
        )
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        if lead_df is not None:
            lead_df.to_csv(args.out, sep="\t", index=False)
            print(f"Extracted {len(lead_df)} lead variants to {args.out}")
        else:
            print("No significant lead variants identified.", file=sys.stderr)
            Path(args.out).touch()
    except Exception as e:
        print(f"Error in get_lead: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
