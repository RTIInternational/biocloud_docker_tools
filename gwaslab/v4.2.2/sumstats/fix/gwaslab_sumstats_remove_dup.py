#!/usr/bin/env python3
"""
GWASLab Sumstats Fix: remove_dup
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
        description="Remove duplicate and multiallelic variants in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--mode", type=str, default="ds", help="Deduplication mode ('ds': by SNPID, 'dr': by rsID, 'dc': by CHR:POS:EA:NEA, 'm': multiallelic).")
    parser.add_argument("--keep", type=str, default="first", choices=["first", "last", "False"], help="Which record to retain.")
    parser.add_argument("--keep_col", type=str, default=None, help="Column to sort by prior to deduplication (e.g. 'P').")
    parser.add_argument("--remove_na", action="store_true", default=False, help="Remove rows with missing values in key columns.")

    args = parser.parse_args()

    keep_val = False if args.keep == "False" else args.keep

    try:
        mysumstats = load_sumstats(args)
        mysumstats.remove_dup(
            mode=args.mode,
            keep=keep_val,
            keep_col=args.keep_col,
            remove_na=args.remove_na
        )
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully removed duplicates and saved to {args.out}")
    except Exception as e:
        print(f"Error in remove_dup: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
