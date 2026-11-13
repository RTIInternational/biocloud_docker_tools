#!/usr/bin/env python3
"""
GWASLab Sumstats Filter: search, random_variants, filter_flanking, get_proxy
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
