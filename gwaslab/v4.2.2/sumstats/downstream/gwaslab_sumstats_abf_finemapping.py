#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: abf_finemapping
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


def parse_region(region_str):
    if not region_str:
        return None
    if ":" in region_str and "-" in region_str:
        chrom, span = region_str.split(":", 1)
        start, end = span.split("-", 1)
        return (chrom.replace("chr", ""), int(start), int(end))
    elif "," in region_str:
        parts = region_str.split(",")
        return (parts[0].replace("chr", ""), int(parts[1]), int(parts[2]))
    return region_str


def main():
    parser = argparse.ArgumentParser(
        description="Run Approximate Bayes Factor (ABF) fine-mapping on a locus in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out_prefix", required=True, type=str, help="Output file prefix for results and credible set tables.")
    parser.add_argument("--region", type=str, default=None, help="Locus region (e.g. 1:1000000-2000000).")
    parser.add_argument("--snpid_target", type=str, default=None, help="Center variant ID.")

    args = parser.parse_args()

    Path(args.out_prefix).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        region = parse_region(args.region) if args.region else None
        region_data, credible_sets = mysumstats.abf_finemapping(
            region=region,
            snpid=args.snpid_target
        )
        if region_data is not None:
            region_data.to_csv(f"{args.out_prefix}.abf_results.tsv", sep="\t", index=False)
        if credible_sets is not None:
            credible_sets.to_csv(f"{args.out_prefix}.credible_sets.tsv", sep="\t", index=False)
        print(f"Successfully performed ABF fine-mapping: {args.out_prefix}.abf_results.tsv")
    except Exception as e:
        print(f"Error in abf_finemapping: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
