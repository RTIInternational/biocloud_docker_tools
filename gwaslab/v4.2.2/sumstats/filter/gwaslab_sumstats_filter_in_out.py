#!/usr/bin/env python3
"""
GWASLab Sumstats Filter: filter_in & filter_out
"""

import argparse
import importlib.util
import json
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
        description="Filter in or filter out variants based on thresholds in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--action", type=str, default="in", choices=["in", "out"], help="Whether to filter in (keep) or filter out (remove).")
    parser.add_argument("--lt_json", type=str, default="{}", help="JSON dict of {column: threshold} for lower bounds (< threshold).")
    parser.add_argument("--gt_json", type=str, default="{}", help="JSON dict of {column: threshold} for upper bounds (> threshold).")
    parser.add_argument("--eq_json", type=str, default="{}", help="JSON dict of {column: value} for equality checks (== value).")

    args = parser.parse_args()

    lt = json.loads(args.lt_json)
    gt = json.loads(args.gt_json)
    eq = json.loads(args.eq_json)

    try:
        mysumstats = load_sumstats(args)
        if args.action == "in":
            mysumstats.filter_in(lt=lt, gt=gt, eq=eq, inplace=True)
        else:
            mysumstats.filter_out(lt=lt, gt=gt, eq=eq, inplace=True)
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully filtered {args.action} variants and saved to {args.out}")
    except Exception as e:
        print(f"Error in filter_{args.action}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
