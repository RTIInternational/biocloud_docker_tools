#!/usr/bin/env python3
"""
GWASLab Reference: get_path
Retrieve the local file path for a specified reference file using keywords.
"""

import argparse
import sys
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Retrieve local file path for a specified reference keyword in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--name", required=True, type=str, help="Reference file keyword identifier (e.g. 'fasta38', '1kg_eur_vcf', etc.).")

    args = parser.parse_args()

    try:
        ref_path = gl.get_path(args.name)
        if ref_path:
            print(f"Reference path for '{args.name}': {ref_path}")
        else:
            print(f"Reference '{args.name}' not found locally.", file=sys.stderr)
            sys.exit(1)
    except Exception as e:
        print(f"Error in get_path: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
