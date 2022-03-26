import argparse
import pandas as pd
import pprint as pp
import sys

# Define arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--in-file",
    dest = "in_file",
    type = str,
    help = "File to sort"
)
parser.add_argument(
    "--in-file-sep",
    dest = "in_sep",
    default = "tab",
    type = str.lower,
    choices = ["whitespace", "tab", "space", "comma"],
    help = "Field separator in input file"
)
parser.add_argument(
    "--cols",
    dest = "cols",
    type = str,
    help = "Comma-separated list of columns to sort by"
)
parser.add_argument(
    "--out-prefix",
    dest = "out_prefix",
    type = str,
    help = "Output file"
)
parser.add_argument(
    "--out-file-compression",
    dest = "compression",
    default = None,
    type = str.lower,
    choices = ["zip", "gzip", "bz2", "zstd"],
    help = "Compression to use for output file"
)
sortGroup = parser.add_mutually_exclusive_group()
sortGroup.add_argument(
    "--ascending",
    dest="ascending",
    action="store_true",
    help = "Sort in ascending order"
)
sortGroup.add_argument(
    "--descending",
    dest="ascending",
    action="store_false",
    help = "Sort in descending order"
)
parser.set_defaults(ascending=True)

# Retrieve arguments
args = parser.parse_args()

# Open log file and write arguments
fileLog = args.out_prefix + ".log"
logHandle = open(fileLog, 'w')
logHandle.write("Script: rti-tsv-utils-sort.py\n")
logHandle.write("Arguments:\n")
logText = pp.PrettyPrinter(indent = 4)
logHandle.write(logText.pformat(vars(args)))
logHandle.write("\n\n")
logHandle.flush()

# Set separators
sepRegex = {
    "whitespace": r'\s+',
    "tab": r'\t',
    "space": ' ',
    "comma": ','
}
args.in_sep = sepRegex[args.in_sep]

# Get list of columns
cols = args.cols.split(",")

logHandle.write("Reading " + args.in_file + "\n")
logHandle.flush()

# Read input file
df = pd.read_csv(
    args.in_file,
    sep=args.in_sep,
    header=0,
    engine='python'
)

# Check if specified columns exist
if not set(df.columns) >= set(cols):
    sys.exit("One or more sort columns does not exist in dataset")

logHandle.write("Sorting\n")
logHandle.flush()

# Sort
df.sort_values(
    by=cols,
    ascending=args.ascending,
    inplace=True
)

# Define output suffixes based on arguments
compressionSuffix = {
    None: "",
    "zip": ".zip",
    "gzip": ".gz",
    "bz2": ".bz2",
    "zstd": ".zst"
}
out = args.out_prefix + ".tsv" + compressionSuffix[args.compression]

logHandle.write("Writing " + out + "\n")
logHandle.flush()

# Write output file
df.to_csv(
    out,
    index = False,
    compression=args.compression,
    sep = '\t',
    na_rep = 'NA',
    float_format='%g'
)

logHandle.write("Sort complete\n")
logHandle.close()
