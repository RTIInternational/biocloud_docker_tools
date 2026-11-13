#!/usr/bin/env python3
"""
GWASLab Sumstats Filter: filter_snp, filter_indel, filter_palindromic, filter_hapmap3
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



def main():
    parser = argparse.ArgumentParser(
        description="Filter summary statistics by variant category (SNP, Indel, Palindromic, HapMap3) in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--filter_type", required=True, choices=["snp", "indel", "palindromic", "hapmap3"], help="Variant category filter type.")
    parser.add_argument("--mode", type=str, default="in", choices=["in", "out"], help="Filter direction ('in' to keep, 'out' to remove).")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        if args.filter_type == "snp":
            mysumstats.filter_snp(mode=args.mode, inplace=True)
        elif args.filter_type == "indel":
            mysumstats.filter_indel(mode=args.mode, inplace=True)
        elif args.filter_type == "palindromic":
            mysumstats.filter_palindromic(mode=args.mode, inplace=True)
        elif args.filter_type == "hapmap3":
            mysumstats.filter_hapmap3(inplace=True)
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully applied {args.filter_type} filter and saved to {args.out}")
    except Exception as e:
        print(f"Error in filter_{args.filter_type}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
