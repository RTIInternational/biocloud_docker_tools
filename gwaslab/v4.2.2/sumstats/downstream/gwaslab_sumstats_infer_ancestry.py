#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: infer_ancestry
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
        description="Infer ancestry based on Fst values from effective allele frequencies in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--ancestry_af", type=str, default=None, help="Path to allele frequency file (or '1kg_hm3_hg19_eaf' / '1kg_hm3_hg38_eaf').")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        ancestry = mysumstats.infer_ancestry(ancestry_af=args.ancestry_af)
        print(f"Closest inferred ancestry: {ancestry}")
    except Exception as e:
        print(f"Error in infer_ancestry: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
