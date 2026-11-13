#!/usr/bin/env python3
"""
GWASLab Sumstats Core: check_af & infer_af
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
        description="Check difference in allele frequency (DAF) against reference VCF in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--ref_infer", required=True, type=str, help="Path to reference VCF file.")
    parser.add_argument("--ref_alt_freq", type=str, default="AF", help="Allele frequency field in reference VCF INFO.")
    parser.add_argument("--maf_threshold", type=float, default=0.4, help="MAF threshold for filtering.")
    parser.add_argument("--column_name", type=str, default="DAF", help="Output column name for frequency difference.")
    parser.add_argument("--threads", type=int, default=1, help="Number of threads.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        mysumstats.check_af(
            ref_infer=args.ref_infer,
            ref_alt_freq=args.ref_alt_freq,
            maf_threshold=args.maf_threshold,
            column_name=args.column_name,
            threads=args.threads
        )
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully checked AF and saved to {args.out}")
    except Exception as e:
        print(f"Error in check_af: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
