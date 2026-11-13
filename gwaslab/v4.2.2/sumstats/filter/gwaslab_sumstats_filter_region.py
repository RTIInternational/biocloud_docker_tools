#!/usr/bin/env python3
"""
GWASLab Sumstats Filter: filter_region & exclude_hla
"""

import argparse
import importlib.util
import sys
from pathlib import Path

_SUMSTATS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_SUMSTATS_DIR))
_SUMSTATS_SPEC = importlib.util.spec_from_file_location(
    "gwaslab_sumstats_common", _SUMSTATS_DIR / "gwaslab_sumstats_common.py"
)
if _SUMSTATS_SPEC is None or _SUMSTATS_SPEC.loader is None:
    raise ImportError(f"Cannot load gwaslab_sumstats_common from {_SUMSTATS_DIR}")
_SUMSTATS_MODULE = importlib.util.module_from_spec(_SUMSTATS_SPEC)
_SUMSTATS_SPEC.loader.exec_module(_SUMSTATS_MODULE)
add_sumstats_args = _SUMSTATS_MODULE.add_sumstats_args
load_sumstats = _SUMSTATS_MODULE.load_sumstats
save_sumstats = _SUMSTATS_MODULE.save_sumstats



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
