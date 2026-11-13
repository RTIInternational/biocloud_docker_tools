#!/usr/bin/env python3
"""
GWASLab Sumstats Core: harmonize
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
        description="Run harmonize() standard reference-based harmonization pipeline in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")
    parser.add_argument("--ref_seq", type=str, default=None, help="Reference FASTA sequence for allele alignment.")
    parser.add_argument("--ref_infer", type=str, default=None, help="Reference VCF for strand inference.")
    parser.add_argument("--ref_rsid_tsv", type=str, default=None, help="Reference TSV for rsID assignment.")
    parser.add_argument("--ref_rsid_vcf", type=str, default=None, help="Reference VCF for rsID assignment.")
    parser.add_argument("--ref_alt_freq", type=str, default=None, help="ALT frequency field name in reference VCF INFO.")
    parser.add_argument("--maf_threshold", type=float, default=0.4, help="MAF threshold for palindromic SNP strand inference.")
    parser.add_argument("--threads", type=int, default=1, help="Number of threads.")
    parser.add_argument("--sweep_mode", action="store_true", default=False, help="Use sweep mode for large reference lookups.")

    args = parser.parse_args()

    try:
        mysumstats = load_sumstats(args)
        mysumstats.harmonize(
            ref_seq=args.ref_seq,
            ref_infer=args.ref_infer,
            ref_rsid_tsv=args.ref_rsid_tsv,
            ref_rsid_vcf=args.ref_rsid_vcf,
            ref_alt_freq=args.ref_alt_freq,
            maf_threshold=args.maf_threshold,
            threads=args.threads,
            sweep_mode=args.sweep_mode
        )
        save_sumstats(mysumstats, args.out, out_fmt=args.out_fmt)
        print(f"Successfully ran harmonize and saved to {args.out}")
    except Exception as e:
        print(f"Error in harmonize: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
