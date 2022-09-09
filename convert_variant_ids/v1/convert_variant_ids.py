import argparse
import pandas as pd
import numpy as np
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
    "--in_chunk_size",
    help="chunk size for reading in input file",
    type=int,
    default=50000,
    required=False
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
    "--ref_chunk_size",
    help="chunk size for reading in ref file",
    type=int,
    default=5000000,
    required=False
)
parser.add_argument(
    "--chr",
    help="Chromosome to convert",
    choices=["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "X", "Y", "25"]
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
    choices = ["infer", "gzip", "bz2", "zip", "xz"],
    nargs='?',
    const=None
)
parser.add_argument(
    "--log_file",
    help="Output file path for log",
    type = str
)
parser.add_argument(
    "--rescue_rsids",
    help="Boolean flag for whether to try to rescue monomorph ids by using the ids in the input file",
    action="store_true",
    required=False
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
inChunkSize = args.in_chunk_size
refChunkSize = args.ref_chunk_size
filterChrs = {}
if chrom == "23" or chrom == "X":
    filterChrs = {
        "23",
        "25",
        "X",
        "X_PAR",
        "X_NONPAR",
        "chr23",
        "chr25",
        "chrX",
        "chrX_PAR",
        "chrX_NONPAR",
        "PAR1",
        "PAR2"
    }
elif chrom == "24" or chrom == "Y":
    filterChrs = {
        "24",
        "Y"
        "chr24",
        "chrY"
    }
else:
    filterChrs = {
        chrom,
        "chr" + chrom
    }

# Open log file
log = open(args.log_file, 'w', buffering=1)
log.write("Script: convert_variant_ids.py\n")
log.write("Arguments:\n")
# Write arguments to log file
pp = pprint.PrettyPrinter(indent = 4)
log.write(pp.pformat(vars(args)))
log.write("\n\n")

def flip(allele, missingAllele, deletionAllele):
    flipMap = {
        "A": "T",
        "C": "G",
        "G": "C",
        "T": "A",
        missingAllele: missingAllele,
        deletionAllele: deletionAllele
    }
    flippedAllele = ""
    for nt in reversed(allele):
        if nt in flipMap:
            flippedAllele += flipMap[nt]
        else:
            flippedAllele = "error"
            break
    return flippedAllele

# Read input file header and write to output file
if args.in_header != 0:
    header = pd.read_csv(
        args.in_file,
        sep=sep, header=None,
        nrows=args.in_header
    )
    header.to_csv(
        args.out_file,
        index = False,
        compression=args.out_compression,
        sep = sep,
        header = False,
        mode = 'w'
    )
    # header = ''
    # with open(args.in_file) as inFile:
    #     for x in range(args.in_header):
    #         header += next(inFile)
    # inFile.close()
    # outFile = open(args.out_file, "w")
    # n = outFile.write(header)
    # outFile.close()

# Create iterator for ref
ref = pd.read_csv(
    args.ref,
    sep="\t",
    header=0,
    iterator = True
)

# Get first chunk of ref
refChunkCount = 1
print("Reading reference chunk {0} ({1} records) of chr{2}...".format(refChunkCount, refChunkSize, chrom))
prevRefChunk = ref.get_chunk(refChunkSize)
dfRef = pd.DataFrame(columns=prevRefChunk.columns)
refChunkCount += 1

# Read input file
inChunkCount = 1
mode = 'w'
for dfIn in pd.read_csv(args.in_file, sep=sep, header=None, skiprows=args.in_header, chunksize=inChunkSize):
    print("Reading input file chunk {0} ({1} records) of chr{2}...".format(inChunkCount, inChunkSize, chrom))
    inChunkCount += 1

    # Filter out variants in input file that are outside the chunk
    dfIn.iloc[:, chrCol] = dfIn.iloc[:, chrCol].astype(str)
    dfIn = dfIn[dfIn.iloc[:, chrCol].isin(filterChrs)]

    if len(dfIn.index) > 0:
        # Create table for output
        dfOut = dfIn.copy()

        # Standardize monomoroph alleles
        dfIn.iloc[:, a1Col] = dfIn.iloc[:, a1Col].replace(to_replace=missAllele, value="0")
        dfIn.iloc[:, a2Col] = dfIn.iloc[:, a2Col].replace(to_replace=missAllele, value="0")

        # Update deletion allele
        dfIn.iloc[:, a1Col] = dfIn.iloc[:, a1Col].replace(to_replace=fileInDelAllele, value=refDelAllele)
        dfIn.iloc[:, a2Col] = dfIn.iloc[:, a2Col].replace(to_replace=fileInDelAllele, value=refDelAllele)

        # Convert alleles to uppercase
        dfIn.iloc[:, a1Col] = dfIn.iloc[:, a1Col].str.upper()
        dfIn.iloc[:, a2Col] = dfIn.iloc[:, a2Col].str.upper()

        # Get reverse complement of alleles
        dfIn["___a1_rc___"] = dfIn.iloc[:, a1Col]
        dfIn["___a1_rc___"] = dfIn["___a1_rc___"].apply(flip, args=["0", refDelAllele])
        dfIn["___a2_rc___"] = dfIn.iloc[:, a2Col]
        dfIn["___a2_rc___"] = dfIn["___a2_rc___"].apply(flip, args=["0", refDelAllele])

        # Create aliases and default IDs for each variant
        conditions = [
            (dfIn.iloc[:, a1Col] <= dfIn.iloc[:, a2Col]) & (dfIn.iloc[:, a1Col] <= dfIn["___a1_rc___"]) & (dfIn.iloc[:, a1Col] <= dfIn["___a2_rc___"]),
            (dfIn.iloc[:, a2Col] <= dfIn.iloc[:, a1Col]) & (dfIn.iloc[:, a2Col] <= dfIn["___a1_rc___"]) & (dfIn.iloc[:, a2Col] <= dfIn["___a2_rc___"]),
            (dfIn["___a1_rc___"] <= dfIn.iloc[:, a1Col]) & (dfIn["___a1_rc___"] <= dfIn.iloc[:, a2Col]) & (dfIn["___a1_rc___"] <= dfIn["___a2_rc___"]),
            (dfIn["___a2_rc___"] <= dfIn.iloc[:, a1Col]) & (dfIn["___a2_rc___"] <= dfIn.iloc[:, a2Col]) & (dfIn["___a2_rc___"] <= dfIn["___a1_rc___"]),
        ]
        choices = [
            dfIn.iloc[:, posCol].astype(str) + "_" + dfIn.iloc[:, a1Col] + "_" + dfIn.iloc[:, a2Col],
            dfIn.iloc[:, posCol].astype(str) + "_" + dfIn.iloc[:, a2Col] + "_" + dfIn.iloc[:, a1Col],
            dfIn.iloc[:, posCol].astype(str) + "_" + dfIn["___a1_rc___"] + "_" + dfIn["___a2_rc___"],
            dfIn.iloc[:, posCol].astype(str) + "_" + dfIn["___a2_rc___"] + "_" + dfIn["___a1_rc___"]
        ]
        dfIn.iloc[:, idCol] = np.select(conditions, choices)
        idChr = chrom
        if idChr in {"23", "X"}:
            idChr = "X"
        elif idChr in {"24", "Y"}:
            idChr = "Y"
        dfIn['___new_id___'] = idChr + "_" + dfIn.iloc[:, idCol]

        # Optionally attempt to rescue rsids from SNPs that can't be fetched from dbSNP
        # Includes monomorphs (e.g. 1 rs24455 1111204 . C)
        # And indels where ref or alt allele is just the deletionAllele (e.g. 1 rs123123 23341 C -)
        if args.rescue_rsids:
            # Get list of snps that won't be searchable in dbSNP
            unfetchable = (dfIn.iloc[:,a1Col] == "0") | \
                        (dfIn.iloc[:,a1Col] == refDelAllele) | \
                        (dfIn.iloc[:,a2Col] == refDelAllele)

            # Get subset of those that contain an rsid in the input file
            rescuable = dfOut[unfetchable & (dfOut.iloc[:, idCol].str.contains("rs"))].index

            # Set the ids for those SNPs to be the original ids and not the POS_A1_A2 format
            dfIn.loc[rescuable, '___new_id___'] = dfOut.loc[rescuable, :].iloc[:, idCol]
            print("Able to rescue {0} out of {1} unfetchable rsids...".format(len(rescuable),
                                                                            len(dfIn[unfetchable])))

        # Read relevant chunks of ref
        maxDfInPos = dfIn.iloc[:, posCol].max()
        dfRef = dfRef.append(prevRefChunk)
        maxDfRefPos = dfRef.POSITION.max()
        while (maxDfRefPos <= maxDfInPos) and len(prevRefChunk.index):
            try:
                print("Reading reference chunk {0} ({1} records) of chr{2}...".format(refChunkCount, refChunkSize, chrom))
                prevRefChunk = ref.get_chunk(refChunkSize)
                if len(prevRefChunk.index):
                    dfRef = dfRef.append(prevRefChunk)
                maxDfRefPos = dfRef.POSITION.max()
                dfRef = dfRef[dfRef.POSITION.isin(dfIn.iloc[:, posCol])]
                refChunkCount += 1
            except:
                break

        idLookup = dict(zip(dfRef.ALIAS, dfRef.ID))
        dfIn['___new_id___'] = dfIn.iloc[:, idCol].map(idLookup).fillna(dfIn['___new_id___'])

        # Add new IDs to output table
        dfOut.iloc[:, idCol] = dfIn['___new_id___']

        # Replace hyphens with colons
        dfOut.iloc[:,idCol] = dfOut.iloc[:,idCol].str.replace("_", ":")

        # Write output
        dfOut.to_csv(
            args.out_file,
            index = False,
            compression=args.out_compression,
            sep = sep,
            header = False,
            mode = 'a',
            float_format='%g',
            na_rep = 'NA'
        )

log.write("Conversion complete\n")
log.close()
