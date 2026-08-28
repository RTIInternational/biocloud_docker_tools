#!/usr/bin/env python3
"""
GWASLab I/O: load_pickle
Load a previously saved GWASLab object from a pickle file and export or inspect.
"""

import argparse
import sys
from pathlib import Path
import gwaslab as gl


def main():
    parser = argparse.ArgumentParser(
        description="Load a GWASLab object from pickle file and export to TSV/format.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("--pickle_path", required=True, type=str, help="Path to input .pickle file.")
    parser.add_argument("--out", required=True, type=str, help="Output summary statistics file prefix/path.")
    parser.add_argument("--out_fmt", type=str, default="gwaslab", help="Output format identifier.")

    args = parser.parse_args()

    try:
        obj = gl.load_pickle(args.pickle_path)
        if obj is None:
            print(f"Error: Could not load pickle file at {args.pickle_path}", file=sys.stderr)
            sys.exit(1)

        Path(args.out).parent.mkdir(parents=True, exist_ok=True)
        clean_path = args.out
        if clean_path.endswith(".gz"):
            clean_path = clean_path[:-3]
        if clean_path.endswith(".tsv") or clean_path.endswith(".txt") or clean_path.endswith(".csv"):
            clean_path = Path(clean_path).stem

        if hasattr(obj, "to_format"):
            obj.to_format(clean_path, fmt=args.out_fmt)
        elif hasattr(obj, "data"):
            obj.data.to_csv(f"{clean_path}.tsv.gz", sep="\t", index=False, compression="gzip")
        print(f"Successfully loaded pickle and saved to {args.out}")
    except Exception as e:
        print(f"Error in load_pickle: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
