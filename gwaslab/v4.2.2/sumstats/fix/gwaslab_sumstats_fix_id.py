#!/usr/bin/env python3
"""
GWASLab Sumstats Fix: fix_id
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
        description="Fix SNPID and rsID formatting and consistency in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--fixprefix", action="store_true", default=False, help="Remove 'chr' prefix in SNPID.")
    parser.add_argument("--fixchrpos", action="store_true", default=False, help="Fix chromosome and position from SNPID.")
    parser.add_argument("--fixid", action="store_true", default=False, help="Generate new SNPID from available CHR/POS/EA/NEA.")
    parser.add_argument("--fixsep", action="store_true", default=False, help="Standardize separators in SNPID.")
    parser.add_argument("--overwrite", action="store_true", default=False, help="Overwrite existing values.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        mysumstats.fix_id(
            fixprefix=args.fixprefix,
            fixchrpos=args.fixchrpos,
            fixid=args.fixid,
            fixsep=args.fixsep,
            overwrite=args.overwrite
        )
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully fixed IDs and saved to {args.out}")
    except Exception as e:
        print(f"Error in fix_id: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
