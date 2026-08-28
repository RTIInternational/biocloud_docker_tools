#!/usr/bin/env python3
"""
GWASLab Sumstats Core: to_format
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
        description="Export summary statistics to target software format in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output file path prefix.")
    parser.add_argument("--to_fmt", required=True, type=str, help="Target format identifier (e.g. 'ldsc', 'plink', 'metal', 'saige', 'gwas-ssf', 'vcf', 'bed', 'magma', etc.).")
    parser.add_argument("--tab_fmt", type=str, default="tsv", choices=["tsv", "csv", "parquet"], help="Tabular storage format.")
    parser.add_argument("--gzip", action="store_true", default=True, help="Gzip compress output.")
    parser.add_argument("--bgzip", action="store_true", default=False, help="BGzip compress output.")
    parser.add_argument("--tabix", action="store_true", default=False, help="Generate tabix index.")
    parser.add_argument("--md5sum", action="store_true", default=False, help="Emit MD5 checksum file.")
    parser.add_argument("--ssfmeta", action="store_true", default=False, help="Emit GWAS-SSF sidecar metadata JSON.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    clean_path = args.out
    if clean_path.endswith(".gz"):
        clean_path = clean_path[:-3]
    if clean_path.endswith(".tsv") or clean_path.endswith(".txt") or clean_path.endswith(".csv"):
        clean_path = Path(clean_path).stem

    try:
        mysumstats = load_sumstats(args)
        mysumstats.to_format(
            path=clean_path,
            fmt=args.to_fmt,
            tab_fmt=args.tab_fmt,
            gzip=args.gzip,
            bgzip=args.bgzip,
            tabix=args.tabix,
            md5sum=args.md5sum,
            ssfmeta=args.ssfmeta
        )
        print(f"Successfully converted sumstats to {args.to_fmt} format at {clean_path}")
    except Exception as e:
        print(f"Error in to_format: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
