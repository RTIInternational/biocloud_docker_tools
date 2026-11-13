#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: estimate_h2_by_ldsc & estimate_rg_by_ldsc
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

import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Estimate SNP heritability (h2) or genetic correlation (rg) via LDSC in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output TSV file path for LDSC results.")
    parser.add_argument("--action", default="h2", choices=["h2", "rg"], help="LDSC analysis mode ('h2' or 'rg').")
    parser.add_argument("--ref_ld_chr", required=True, type=str, help="Path/prefix to reference LD score files (e.g. eur_w_ld_chr/).")
    parser.add_argument("--w_ld_chr", required=True, type=str, help="Path/prefix to LD weights files.")
    parser.add_argument("--other_sumstats", nargs="+", default=None, help="Paths to other summary statistics files for rg.")
    parser.add_argument("--samp_prev", type=float, default=None, help="Sample prevalence for binary traits.")
    parser.add_argument("--pop_prev", type=float, default=None, help="Population prevalence for binary traits.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        if args.action == "h2":
            mysumstats.estimate_h2_by_ldsc(
                ref_ld_chr=args.ref_ld_chr,
                w_ld_chr=args.w_ld_chr,
                samp_prev=args.samp_prev,
                pop_prev=args.pop_prev
            )
            if hasattr(mysumstats, "ldsc_h2_results") and mysumstats.ldsc_h2_results is not None:
                mysumstats.ldsc_h2_results.to_csv(args.out, sep="\t", index=False)
        elif args.action == "rg":
            other_objs = [gl.Sumstats(f, fmt="auto") for f in args.other_sumstats] if args.other_sumstats else []
            mysumstats.estimate_rg_by_ldsc(
                other_traits=other_objs,
                ref_ld_chr=args.ref_ld_chr,
                w_ld_chr=args.w_ld_chr
            )
            if hasattr(mysumstats, "ldsc_rg") and mysumstats.ldsc_rg is not None:
                mysumstats.ldsc_rg.to_csv(args.out, sep="\t", index=False)
        print(f"Successfully ran LDSC {args.action} and saved results to {args.out}")
    except Exception as e:
        print(f"Error in estimate_{args.action}_by_ldsc: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
