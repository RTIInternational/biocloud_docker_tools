import argparse
import pandas as pd
import pprint

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--in_file",
    help="Input file containing variant IDs to convert",
    type = str
)
parser.add_argument(
    "--in_header",
    help="Number of header rows in input file",
    type = int
)
parser.add_argument(
    "--in_sep",
    help="Separator used in input file",
    type = str.lower,
    choices=["space", "tab", "comma"]
)
parser.add_argument(
    "--in_id_col",
    help="Zero-based column number of variant ID in input file",
    type = int
)
parser.add_argument(
    "--in_chr_col",
    help="Zero-based column number of variant chromosome in input file",
    type = int
)
parser.add_argument(
    "--in_pos_col",
    help="Zero-based column number of variant position in input file",
    type = int
)
parser.add_argument(
    "--in_a1_col",
    help="Zero-based column number of variant allele 1 in input file",
    type = int
)
parser.add_argument(
    "--in_a2_col",
    help="Zero-based column number of variant allele 2 in input file",
    type = int
)
parser.add_argument(
    "--in_missing_allele",
    help="Character(s) used to represent second allele for monomorphic variants in input file",
    type = str
)
parser.add_argument(
    "--in_deletion_allele",
    help="Character(s) used to represent deletion allele in input file (if applicable)",
    type = str
)
parser.add_argument(
    "--ref",
    help="Reference file containing variant IDs to be used for conversion",
    type = str
)
parser.add_argument(
    "--ref_deletion_allele",
    help="Character(s) used to represent deletion allele in ref (if applicable)",
    type = str
)
parser.add_argument(
    "--chr",
    help="Chromosome to convert",
    choices=["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "X", "Y", "25"]
)
parser.add_argument(
    "--start",
    help="Position of start of chunk to convert",
    default=-1,
    required=False,
    type = str
)
parser.add_argument(
    "--end",
    help="Position of end of chunk to convert",
    default=-1,
    required=False,
    type = str
)
parser.add_argument(
    "--out_file",
    help="Output file path for converted file",
    type = str
)
parser.add_argument(
    "--out_compression",
    help="(Optional) Type of compression to use for output file",
    type = str,
    choices = ["gzip", "bz2", "zip", "xz"],
    nargs='?',
    const=None
)
parser.add_argument(
    "--log_file",
    help="Output file path for log",
    type = str
)
args = parser.parse_args()
sep = ("\t" if args.in_sep == "tab" else (" " if args.in_sep == "space" else ","))
idCol = args.in_id_col
chrCol = args.in_chr_col
posCol = args.in_pos_col
a1Col = args.in_a1_col
a2Col = args.in_a2_col
missAllele = args.in_missing_allele
fileInDelAllele = args.in_deletion_allele
refDelAllele = args.ref_deletion_allele
chrom = args.chr
start = int(args.start)
end = int(args.end)

# Open log file
log = open(args.log_file, 'w', buffering=1)
log.write("Script: convert_variant_ids.py\n")
log.write("Arguments:\n")
# Write arguments to log file
pp = pprint.PrettyPrinter(indent = 4)
log.write(pp.pformat(vars(args)))
log.write("\n\n")

# Read input file header
if args.in_header > 0:
    dfInHeader = pd.read_csv(
        args.in_file,
        sep = sep,
        header = None,
        nrows=args.in_header
    )

# Read input file
fileInHeader = (None if args.in_header == 0 else (args.in_header - 1))
dfIn = pd.read_csv(
    args.in_file,
    sep = sep,
    header = fileInHeader
)

# Filter out variants in input file that are outside the chunk
filterChrs = {}
if chrom == "23" or chrom == "X":
    filterChrs = {
        "23",
        "25"
        "X",
        "X_PAR",
        "X_NONPAR"
    }
elif chrom == "24" or chrom == "Y":
    filterChrs = {
        "24",
        "Y"
    }
else:
    filterChrs = {chrom}
dfIn.iloc[:, chrCol] = dfIn.iloc[:, chrCol].astype(str)
dfIn = dfIn[dfIn.iloc[:, chrCol].isin(filterChrs)]

# Optionally subset to specific region
if start != -1:
    dfIn = dfIn[dfIn.iloc[:, posCol] >= start]
if end != -1:
    dfIn = dfIn[dfIn.iloc[:, posCol] <= end]

# Create table for output
dfOut = dfIn.copy()

# Update deletion allele
dfIn.iloc[:, a1Col] = dfIn.iloc[:, a1Col].replace(to_replace=fileInDelAllele, value=refDelAllele)
dfIn.iloc[:, a2Col] = dfIn.iloc[:, a2Col].replace(to_replace=fileInDelAllele, value=refDelAllele)

# Create aliases and default IDs for each variant
dfIn.iloc[:, idCol] = dfIn.iloc[:, posCol].astype(str) + "_" + dfIn.iloc[:, a1Col] + "_" + dfIn.iloc[:, a2Col]
if chrom in {"23", "X"}:
    dfIn.iloc[:, idCol] = "X"
elif chrom in {"24", "Y"}:
    dfIn.iloc[:, idCol] = "Y"
dfIn['___new_id___'] = dfIn.iloc[:, chrCol] + "_" + dfIn.iloc[:, idCol]

# Create ID dictionary from ref
ref = pd.read_csv(
    args.ref,
    sep = "\t",
    header = 0
)
ref = ref[ref.POSITION.isin(dfIn.iloc[:, posCol])]
idLookup = dict(zip(ref.ALIAS, ref.ID))

# Update IDs from ref
dfIn['___new_id___'] = dfIn.iloc[:, idCol].map(idLookup).fillna(dfIn['___new_id___'])

# Add new IDs to output table
dfOut.iloc[:, idCol] = dfIn['___new_id___']

# Write output
mode = 'w'
if fileInHeader > 0:
    dfInHeader.to_csv(
        args.out_file,
        index = False,
        compression=args.out_compression,
        sep = sep,
        header = False,
        mode = mode
    )
    mode = 'a'
dfOut.to_csv(
    args.out_file,
    index = False,
    compression=args.out_compression,
    sep = sep,
    header = False,
    mode = mode
)

log.write("Conversion complete\n")
log.close()

