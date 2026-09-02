#!/usr/bin/env python3
"""
GWASLab Sumstats Filter: filter_region & exclude_hla
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


def parse_region(region_str):
    if not region_str:
        return None
    if region_str.upper() in ["HLA", "HIGH_LD", "PAR"]:
        return region_str.upper()
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
        description="Filter or exclude variants by genomic region/locus (including HLA and High LD) in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--region", type=str, default=None, help="Genomic region (e.g. '1:1000000-2000000', 'HLA', 'HIGH_LD', 'PAR').")
    parser.add_argument("--bed_in", type=str, default=None, help="Path to BED file to filter in variants.")
    parser.add_argument("--bed_out", type=str, default=None, help="Path to BED file to filter out variants.")
    parser.add_argument("--exclude_hla", action="store_true", default=False, help="Exclude variants in the HLA region.")
    parser.add_argument("--hla_mode", type=str, default="xmhc", choices=["xmhc", "hla", "mhc"], help="HLA exclusion mode.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        if args.exclude_hla:
            mysumstats.exclude_hla(mode=args.hla_mode, inplace=True)
        elif args.bed_in:
            mysumstats.filter_region_in(path=args.bed_in, inplace=True)
        elif args.bed_out:
            mysumstats.filter_region_out(path=args.bed_out, inplace=True)
        elif args.region:
            mysumstats.filter_region(region=parse_region(args.region), inplace=True)
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully filtered region and saved to {args.out}")
    except Exception as e:
        print(f"Error in filter_region: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
