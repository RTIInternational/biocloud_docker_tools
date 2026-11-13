#!/usr/bin/env python3
"""
GWASLab Sumstats Core: report
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
        description="Generate a comprehensive HTML QC report for summary statistics in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    add_sumstats_args(parser)
    parser.add_argument("--out", required=True, type=str, help="Output HTML report file path (e.g. qc_report.html).")
    parser.add_argument("--report_title", type=str, default="GWAS Quality Control Report", help="Title for the report.")

    args = parser.parse_args()

    Path(args.out).parent.mkdir(parents=True, exist_ok=True)

    try:
        mysumstats = load_sumstats(args)
        mysumstats.report(
            output_path=args.out,
            report_title=args.report_title
        )
        print(f"Successfully generated QC report: {args.out}")
    except Exception as e:
        print(f"Error in report: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
