#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: clump
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
        description="Perform LD clumping using PLINK2 through GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output prefix for clumping results.")
    parser.add_argument("--bfile", type=str, default=None, help="Prefix to PLINK binary files (.bed/.bim/.fam).")
    parser.add_argument("--pfile", type=str, default=None, help="Prefix to PLINK2 files (.pgen/.pvar/.psam).")
    parser.add_argument("--vcf", type=str, default=None, help="Path to reference VCF.")
    parser.add_argument("--clump_p1", type=float, default=5e-8, help="Primary significance threshold.")
    parser.add_argument("--clump_p2", type=float, default=1e-5, help="Secondary significance threshold.")
    parser.add_argument("--clump_r2", type=float, default=0.1, help="LD r^2 threshold.")
    parser.add_argument("--clump_kb", type=int, default=250, help="Clumping window size in kb.")
    parser.add_argument("--threads", type=int, default=4, help="PLINK2 threads.")
    parser.add_argument("--plink2", type=str, default="plink2", help="Path to PLINK2 executable.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        clumped_sumstats, clumps_df, logstr = mysumstats.clump(
            bfile=args.bfile,
            pfile=args.pfile,
            vcf=args.vcf,
            clump_p1=args.clump_p1,
            clump_p2=args.clump_p2,
            clump_r2=args.clump_r2,
            clump_kb=args.clump_kb,
            threads=args.threads,
            plink2=args.plink2,
            out=args.out
        )
        if clumped_sumstats is not None:
            clumped_sumstats.to_csv(f"{args.out}.clumped.tsv", sep="\t", index=False)
        if clumps_df is not None:
            clumps_df.to_csv(f"{args.out}.clumps.tsv", sep="\t", index=False)
        print(f"Successfully ran clumping: {args.out}.clumped.tsv")
    except Exception as e:
        print(f"Error in clump: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
