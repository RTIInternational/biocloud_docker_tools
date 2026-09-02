#!/usr/bin/env python3
"""
GWASLab Sumstats Core: report
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
        description="Generate a comprehensive HTML QC report for summary statistics in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output HTML report file path (e.g. qc_report.html).")
    parser.add_argument("--report_title", type=str, default="GWAS Quality Control Report", help="Title for the report.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        mysumstats.report(
            output_path=args.out,
            report_title=args.report_title
        )
        print(f"Successfully generated QC report: {args.out}")
    except Exception as e:
        print(f"Error in report: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
