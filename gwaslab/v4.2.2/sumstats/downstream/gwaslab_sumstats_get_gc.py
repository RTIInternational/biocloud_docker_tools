#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: get_gc
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
        description="Calculate the Genomic Inflation Factor (Lambda GC) in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--mode", type=str, default="P", choices=["P", "MLOG10P", "Z", "CHISQ"], help="Input metric to use for calculation.")
    parser.add_argument("--include_chrXYMT", action="store_true", default=False, help="Include sex/MT chromosomes.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        lambda_gc = mysumstats.get_gc(mode=args.mode, include_chrXYMT=args.include_chrXYMT)
        print(f"Genomic Inflation Factor (Lambda GC): {lambda_gc}")
    except Exception as e:
        print(f"Error in get_gc: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
