#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: get_top & get_novel
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



def main():
    parser = argparse.ArgumentParser(
        description="Extract top variants by metric or novel variants against GWAS Catalog in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output TSV file path.")
    parser.add_argument("--action", required=True, choices=["top", "novel", "density"], help="Operation to perform.")
    parser.add_argument("--by", type=str, default="DENSITY", help="Column name to maximize for 'top' action.")
    parser.add_argument("--known", type=str, default=None, help="Path to known variants file for 'novel' action.")
    parser.add_argument("--efo", nargs="+", default=None, help="EFO / MONDO trait IDs for GWAS Catalog querying.")
    parser.add_argument("--only_novel", action="store_true", default=False, help="Return only novel variants.")
    parser.add_argument("--windowsizekb", type=int, default=500, help="Window size in kb.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        if args.action == "top":
            df = mysumstats.get_top(by=args.by, windowsizekb=args.windowsizekb)
        elif args.action == "novel":
            df = mysumstats.get_novel(
                known=args.known,
                efo=args.efo,
                only_novel=args.only_novel,
                windowsizekb=args.windowsizekb
            )
        elif args.action == "density":
            df = mysumstats.get_density(windowsizekb=args.windowsizekb)

        if df is not None:
            df.to_csv(args.out, sep="\t", index=False)
            print(f"Successfully ran {args.action} and saved results to {args.out}")
        else:
            Path(args.out).touch()
    except Exception as e:
        print(f"Error in {args.action}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
