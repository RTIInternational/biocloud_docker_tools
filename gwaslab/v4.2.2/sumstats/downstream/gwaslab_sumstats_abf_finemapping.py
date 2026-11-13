#!/usr/bin/env python3
"""
GWASLab Sumstats Downstream: abf_finemapping
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



def parse_region(region_str):
    if not region_str:
        return None
    if ":" in region_str and "-" in region_str:
        chrom, span = region_str.split(":", 1)
        start, end = span.split("-", 1)
        return (chrom.replace("chr", ""), int(start), int(end))
    elif "," in region_str:
        parts = region_str.split(",")
        return (parts[0].replace("chr", ""), int(parts[1]), int(parts[2]))
    return region_str


def main():
    parser = argparse.ArgumentParser(
        description="Run Approximate Bayes Factor (ABF) fine-mapping on a locus in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out_prefix", required=True, type=str, help="Output file prefix for results and credible set tables.")
    parser.add_argument("--region", type=str, default=None, help="Locus region (e.g. 1:1000000-2000000).")
    parser.add_argument("--snpid_target", type=str, default=None, help="Center variant ID.")

    args = parser.parse_args()

    Path(args.out_prefix).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        region = parse_region(args.region) if args.region else None
        region_data, credible_sets = mysumstats.abf_finemapping(
            region=region,
            snpid=args.snpid_target
        )
        if region_data is not None:
            region_data.to_csv(f"{args.out_prefix}.abf_results.tsv", sep="\t", index=False)
        if credible_sets is not None:
            credible_sets.to_csv(f"{args.out_prefix}.credible_sets.tsv", sep="\t", index=False)
        print(f"Successfully performed ABF fine-mapping: {args.out_prefix}.abf_results.tsv")
    except Exception as e:
        print(f"Error in abf_finemapping: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
