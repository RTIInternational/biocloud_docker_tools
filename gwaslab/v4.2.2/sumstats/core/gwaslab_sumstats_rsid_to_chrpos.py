#!/usr/bin/env python3
"""
GWASLab Sumstats Core: rsid_to_chrpos
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
        description="Assign CHR and POS coordinates from rsIDs using HDF5/VCF reference in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--ref_vcf", type=str, default=None, help="Path to reference VCF containing rsID to CHR:POS mappings.")
    parser.add_argument("--ref_hdf5", type=str, default=None, help="Path to pre-generated HDF5 reference file.")
    parser.add_argument("--threads", type=int, default=4, help="Number of threads for parallel processing.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        mysumstats.rsid_to_chrpos(
            ref_rsid_to_chrpos_vcf=args.ref_vcf,
            ref_rsid_to_chrpos_hdf5=args.ref_hdf5,
            threads=args.threads
        )
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully assigned coordinates from rsIDs and saved to {args.out}")
    except Exception as e:
        print(f"Error in rsid_to_chrpos: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
