#!/usr/bin/env python3
"""
GWASLab Sumstats Core: summary
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



def main():
    parser = argparse.ArgumentParser(
        description="Generate QC summary metrics dictionary from GWASLab Sumstats.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output JSON file path for summary results.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        summ = mysumstats.summary()
        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        with open(args.out, "w") as f:
            json.dump(summ, f, indent=2, default=str)
        print(f"Successfully generated summary report: {args.out}")
    except Exception as e:
        print(f"Error in summary: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
