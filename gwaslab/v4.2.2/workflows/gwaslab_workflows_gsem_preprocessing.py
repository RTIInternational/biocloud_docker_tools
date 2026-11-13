#!/usr/bin/env python3
"""
GWASLab Workflows: QC
"""

import argparse
import importlib.util
import json
import sys
from pathlib import Path
import gwaslab as gl

_SUMSTATS_DIR = Path(__file__).resolve().parents[1] / "sumstats"
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
        description="Run QC workflow in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument(
        "--out_prefix",
        required=True,
        type=str,
        help="Output prefix for sumstats and summary outputs."
    )
    parser.add_argument(
        "--out_sumstats_fmt",
        nargs='+',
        type=str,
        default=["gwaslab"],
        choices=["pickle", "gsf"] + gl.get_formats_list(),
        help="Output format identifiers."
    )
    parser.add_argument(
        "--basic_check_remove",
        action="store_true",
        default=False,
        help="Remove bad quality variants during basic check."
    )
    parser.add_argument(
        "--basic_check_remove_dup",
        action="store_true",
        default=False,
        help="Remove duplicate variants during basic check."
    )
    parser.add_argument(
        "--basic_check_normalize",
        action="store_true",
        default=False,
        help="Normalize indel representations during basic check."
    )
    parser.add_argument(
        "--check_ref_ref_seq",
        type=str,
        default=None,
        help="Reference FASTA file path for reference check."
    )
    parser.add_argument(
        "--check_ref_remove",
        action="store_true",
        default=False,
        help="Remove bad quality variants during reference check."
    )
    parser.add_argument(
        "--assign_rsid_vcf_path",
        type=str,
        default=None,
        help="Reference RSID VCF file path for harmonization."
    )
    parser.add_argument(
        "--threads",
        type=int,
        default=4,
        help="Number of threads to use."
    )

    args = parser.parse_args()

    try:
        # Load summary statistics
        mysumstats = load_sumstats(args)
        # Fill BETA from OR if OR is provided and BETA is missing
        cols = mysumstats.columns.tolist()
        if "OR" in cols and "BETA" not in cols:
            mysumstats.fill_data(
                to_fill="BETA",
                overwrite=True,
                verbose=True
            )
        # Run basic quality checks
        mysumstats.basic_check(
            remove=args.basic_check_remove,
            remove_dup=args.basic_check_remove_dup,
            normalize=args.basic_check_normalize,
            threads=args.threads,
            verbose=True
        )
        # Fix SNP IDs
        mysumstats.fix_id(
            fixid=True,
            forcefixid=True,
            overwrite=True,
            verbose=True
        )
        # Filter palindromic SNPs
        mysumstats.filter_palindromic(
            mode='out',
            verbose=True,
            inplace=True
        )
        # Check against ref genome
        mysumstats.check_ref(
            ref_seq=args.check_ref_ref_seq,
            remove=args.check_ref_remove,
            verbose=True
        )
        # Flip allele statistics
        mysumstats.flip_allele_stats()
        # Assign rsid to summary statistics
        mysumstats.assign_rsid2(
            path=args.assign_rsid_vcf_path,
            threads=args.threads,
            overwrite='all',
            verbose=True
        )
        # Save preprocessed summary statistics and summary JSON
        for fmt in args.out_sumstats_fmt:
            save_sumstats(mysumstats, args.out_prefix, out_fmt=fmt)
        summary_path = args.out_prefix + ".summary.json"
        Path(summary_path).parent.mkdir(parents=True, exist_ok=True)
        with open(summary_path, "w") as summary_file:
            json.dump(mysumstats.summary(), summary_file, indent=2, default=str)
        print(f"Successfully ran basic check and harmonize and saved outputs with prefix {args.out_prefix}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
