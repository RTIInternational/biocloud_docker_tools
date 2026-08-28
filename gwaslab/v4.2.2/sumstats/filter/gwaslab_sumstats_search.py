#!/usr/bin/env python3
"""
GWASLab Sumstats Filter: search, random_variants, filter_flanking, get_proxy
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
        description="Search variants, extract flanking windows, subsample, or find LD proxies in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--action", required=True, choices=["search", "flanking", "random", "proxy"], help="Operation to perform.")
    parser.add_argument("--snplist", nargs="+", default=None, help="List of variant IDs to search or proxy.")
    parser.add_argument("--windowsizekb", type=int, default=500, help="Flanking window size in kb.")
    parser.add_argument("--n_variants", type=int, default=100, help="Number of variants to subsample for 'random'.")
    parser.add_argument("--vcf_path", type=str, default=None, help="Path to reference VCF for LD proxies.")
    parser.add_argument("--ld_threshold", type=float, default=0.8, help="LD r^2 threshold for proxies.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        if args.action == "search":
            mysumstats.search(snplist=args.snplist, inplace=True)
        elif args.action == "flanking":
            mysumstats.filter_flanking(snpid=args.snplist[0] if args.snplist else None, windowsizekb=args.windowsizekb, inplace=True)
        elif args.action == "random":
            mysumstats.random_variants(n=args.n_variants, inplace=True)
        elif args.action == "proxy":
            proxies = mysumstats.get_proxy(snplist=args.snplist, vcf_path=args.vcf_path, ld_threshold=args.ld_threshold)
            Path(args.out).parent.mkdir(parents=True, exist_ok=True)
            proxies.to_csv(args.out, sep="\t", index=False)
            print(f"Successfully generated proxies and saved to {args.out}")
            return
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully performed {args.action} and saved to {args.out}")
    except Exception as e:
        print(f"Error in {args.action}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
