#!/usr/bin/env python3
"""
GWASLab Sumstats Core: liftover
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
        description="Liftover variants to a new genome build using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--to_build", required=True, type=str, help="Target genome build (e.g. '19', '38').")
    parser.add_argument("--from_build", type=str, default=None, help="Source genome build (e.g. '19', '38').")
    parser.add_argument("--chain_path", type=str, default=None, help="Direct path to UCSC chain file.")
    parser.add_argument("--remove", action="store_true", default=True, help="Remove unmapped variants.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        mysumstats.liftover(
            to_build=args.to_build,
            from_build=args.from_build,
            chain_path=args.chain_path,
            remove=args.remove
        )
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully performed liftover to build {args.to_build} and saved to {args.out}")
    except Exception as e:
        print(f"Error in liftover: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
