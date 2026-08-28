#!/usr/bin/env python3
"""
GWASLab Reference: check_format
Check header conversion dictionary between a format preset and GWASLab format.
"""

import argparse
import json
import sys
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Inspect predefined header mappings for GWAS format presets in GWASLab.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--fmt", required=True, type=str, help="Format name to check (e.g. 'plink2', 'saige', 'metal', 'ldsc', etc.).")
    parser.add_argument("--out_json", type=str, default=None, help="Optional output JSON file path.")

    args = parser.parse_args()

    try:
        mapping = gl.check_format(args.fmt)
        if args.out_json:
            with open(args.out_json, "w") as f:
                json.dump(mapping, f, indent=2)
            print(f"Saved header mapping to {args.out_json}")
        else:
            print(json.dumps(mapping, indent=2))
    except Exception as e:
        print(f"Error in check_format: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
