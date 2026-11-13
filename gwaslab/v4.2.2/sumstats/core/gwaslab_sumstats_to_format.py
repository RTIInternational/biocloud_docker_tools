#!/usr/bin/env python3
"""
GWASLab Sumstats Core: to_format
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
        description="Export summary statistics to target software format in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output file path prefix.")
    parser.add_argument("--to_fmt", required=True, type=str, help="Target format identifier (e.g. 'ldsc', 'plink', 'metal', 'saige', 'gwas-ssf', 'vcf', 'bed', 'magma', etc.).")
    parser.add_argument("--tab_fmt", type=str, default="tsv", choices=["tsv", "csv", "parquet"], help="Tabular storage format.")
    parser.add_argument("--gzip", action="store_true", default=True, help="Gzip compress output.")
    parser.add_argument("--bgzip", action="store_true", default=False, help="BGzip compress output.")
    parser.add_argument("--tabix", action="store_true", default=False, help="Generate tabix index.")
    parser.add_argument("--md5sum", action="store_true", default=False, help="Emit MD5 checksum file.")
    parser.add_argument("--ssfmeta", action="store_true", default=False, help="Emit GWAS-SSF sidecar metadata JSON.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    clean_path = args.out
    if clean_path.endswith(".gz"):
        clean_path = clean_path[:-3]
    if clean_path.endswith(".tsv") or clean_path.endswith(".txt") or clean_path.endswith(".csv"):
        clean_path = Path(clean_path).stem

    try:
        mysumstats = load_sumstats(args)
        mysumstats.to_format(
            path=clean_path,
            fmt=args.to_fmt,
            tab_fmt=args.tab_fmt,
            gzip=args.gzip,
            bgzip=args.bgzip,
            tabix=args.tabix,
            md5sum=args.md5sum,
            ssfmeta=args.ssfmeta
        )
        print(f"Successfully converted sumstats to {args.to_fmt} format at {clean_path}")
    except Exception as e:
        print(f"Error in to_format: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
