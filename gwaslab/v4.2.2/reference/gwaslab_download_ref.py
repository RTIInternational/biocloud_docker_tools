#!/usr/bin/env python3
"""
GWASLab Reference: download_ref
Download a reference file based on its identifier from reference.json.
"""

import argparse
import sys
from pathlib import Path
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Download a reference file (HapMap3, 1000G, FASTA, chain, etc.) using GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--name", required=True, type=str, help="Reference file identifier (e.g. '1kg_eur_vcf', 'fasta38', 'hm3', etc.).")
    parser.add_argument("--out_dir", type=str, default=None, help="Optional directory to save the reference file.")

    args = parser.parse_args()

    if args.out_dir:
        Path(args.out_dir).mkdir(parents=True, exist_ok=True)

    try:
        saved_path = gl.download_ref(name=args.name)
        if saved_path:
            print(f"Successfully downloaded reference '{args.name}' to: {saved_path}")
        else:
            print(f"Failed to download reference '{args.name}'.", file=sys.stderr)
            sys.exit(1)
    except Exception as e:
        print(f"Error in download_ref: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
