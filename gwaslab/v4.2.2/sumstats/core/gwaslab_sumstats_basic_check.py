#!/usr/bin/env python3
"""
GWASLab Sumstats Core: basic_check
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
        description="Run basic_check() all-in-one quality control pipeline in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out_prefix", required=True, type=str, help="Output prefix for sumstats and summary outputs.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--remove", action="store_true", default=False, help="Remove bad quality variants.")
    parser.add_argument("--remove_dup", action="store_true", default=False, help="Remove duplicate variants.")
    parser.add_argument("--no-normalize", action="store_false", help="Do not normalize indel representations.")
    parser.add_argument("--threads", type=int, default=1, help="Number of threads.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        mysumstats.basic_check(
            remove=args.remove,
            remove_dup=args.remove_dup,
            normalize=not args.no_normalize,
            threads=args.threads
        )
        save_sumstats(mysumstats, args.out_prefix, out_fmt=args.out_fmt)
        summary_path = args.out_prefix + ".summary.json"
        Path(summary_path).parent.mkdir(parents=True, exist_ok=True)
        with open(summary_path, "w") as summary_file:
            json.dump(mysumstats.summary(), summary_file, indent=2, default=str)
        print(f"Successfully ran basic_check and saved outputs with prefix {args.out_prefix}")
    except Exception as e:
        print(f"Error in basic_check: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
