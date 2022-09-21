import argparse
import pandas as pd
import numpy as np
import pprint

# Define custom functions
def readInfoChunk(infoFileHandle, chunkSize, infoColXref, infoFormat):

    # Read info file chunk
    infoChunk = infoFileHandle.get_chunk(chunkSize)

    # Rename info columns
    infoChunk.rename(
        columns = infoColXref,
        inplace = True
    )

    # Normalize info file IDs to match ones created for sum stats
    if infoFormat == "info":
        def get_chr_pos(variant_id):
            return ":".join(variant_id.split(":")[0:2])
        def get_pos(variant_id):
            return int(variant_id.split(":")[1])
        infoChunk["VARIANT_ID"] = infoChunk["VARIANT_ID"].replace({'chr':''}, regex=True)
        infoChunk["VARIANT_ID"] = infoChunk["VARIANT_ID"].map(get_chr_pos)
        infoChunk["POS"] = infoChunk["VARIANT_ID"].map(get_pos)
    elif infoFormat == "mfi":
        infoChunk["VARIANT_ID"] = infoChunk["CHR"].astype(str) + ":" + infoChunk["POS"].astype(str)
    infoChunk["VARIANT_ID"] = infoChunk["VARIANT_ID"].astype(str) + ":" + infoChunk["REF"].astype(str) + ":" + infoChunk["ALT"].astype(str)

    # Recode sources if applicable
    if 'SOURCE' in infoChunk.columns:
        sourceXref = {
            'Imputed': 'IMP',
            'Genotyped': 'GEN',
            'Typed_Only': 'GEN'
        }
        infoChunk['SOURCE'] = infoChunk['SOURCE'].map(sourceXref)

    # Remove duplicates
    infoChunk.drop_duplicates(subset = "VARIANT_ID", keep = "first", inplace = True)

    return infoChunk


# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--file_in_summary_stats",
    help="summary stats file to be converted"
)
parser.add_argument(
    "--file_in_summary_stats_format",
    help="format of the summary stats file to be converted",
    type = str.lower,
    choices=["rvtests", "gem", "genesis"]
)
parser.add_argument(
    "--file_in_info",
    help="info file from genotype imputation"
)
parser.add_argument(
    "--file_in_info_format",
    help="format of the info file",
    type = str.lower,
    choices=["info", "mfi"],
    default="info"
)
parser.add_argument(
    "--file_in_pop_mafs",
    help="file containing mafs for relevant reference population"
)
parser.add_argument(
    "--population",
    help="Reference population",
    type = str.lower,
    choices=["afr", "eas", "eur", "amr", "eas", "amr"]
)
parser.add_argument(
    "--file_out_prefix",
    help="prefix for output files"
)
parser.add_argument(
    "--chunk_size",
    help="chunk size to use for reading files",
    type = int
)
args = parser.parse_args()
includePopMAFs = True if args.file_in_pop_mafs else False

# Open log file
fileLog = args.file_out_prefix + ".log"
log = open(fileLog, 'w')
log.write("Script: make_gwas_summary_stats.py\n")
log.write("Arguments:\n")
# Write arguments to log file
pp = pprint.PrettyPrinter(indent = 4)
log.write(pp.pformat(vars(args)))
log.write("\n\n")
log.flush()

# Read population MAFs if provided
if includePopMAFs:
    popMAFs = pd.read_csv(
        args.file_in_pop_mafs,
        sep = "\t"
    )
    log.write("Read " + str(popMAFs.shape[0]) + " lines from " + args.file_in_pop_mafs + "\n")
    # Rename columns
    popMAFs.columns = ["VARIANT_ID", "POP_MAF"]
    # Drop duplicates
    popMAFs.drop_duplicates(subset = "VARIANT_ID", keep = "first", inplace = True)
    log.write(str(popMAFs.shape[0]) + " remain after duplicates removal\n")

# Set variables depending on source of summary stats
if args.file_in_summary_stats_format == "rvtests":
    dtype = {"CHROM": "category", "REF": "category", "ALT": "category"}
    sumStatsColXref = {
        'CHROM': 'CHR',
        'POS': 'POS',
        'REF': 'REF',
        'ALT': 'ALT',
        'N_INFORMATIVE': 'N',
        'SQRT_V_STAT': 'SQRT_V_STAT',
        'ALT_EFFSIZE': 'ALT_EFFECT',
        'PVALUE': 'P',
    }
    sumStatsUseCols = sumStatsColXref.keys()
    outputColumns = [
        "VARIANT_ID",
        "CHR",
        "POS",
        "REF",
        "ALT",
        "ALT_AF",
        "MAF",
        "POP_MAF",
        "SOURCE",
        "IMP_QUAL",
        "N",
        "ALT_EFFECT",
        "SE",
        "P"
    ]
elif args.file_in_summary_stats_format == "gem":
    sumStatsUseCols = list(pd.read_table(args.file_in_summary_stats, nrows=1).columns)
    dtype = {"CHR": "category", "Non_Effect_Allele": "category", "Effect_Allele": "category"}
    sumStatsColXref = {
        'SNPID': 'VARIANT_ID',
        'Non_Effect_Allele': 'REF',
        'Effect_Allele': 'ALT',
        'N_Samples': 'N',
        'AF': 'ALT_AF'
    }
    outputColumns = [
        "VARIANT_ID",
        "CHR",
        "POS",
        "REF",
        "ALT",
        "ALT_AF",
        "MAF",
        "POP_MAF",
        "IMP_QUAL",
        "N"
    ] + sumStatsUseCols[8:len(sumStatsUseCols)]
elif args.file_in_summary_stats_format == "genesis":
    sumStatsUseCols = list(pd.read_table(args.file_in_summary_stats, nrows=1).columns)
    dtype = {"chr": "category", "ref": "category", "alt": "category"}
    sumStatsColXref = {
        'variant.id': 'VARIANT_ID',
        'chr': 'CHR',
        'pos': 'POS',
        'ref': 'REF',
        'alt': 'ALT',
        'freq': 'ALT_AF',
        'n.obs': 'N'
    }
    outputColumns = [
        "VARIANT_ID",
        "CHR",
        "POS",
        "REF",
        "ALT",
        "ALT_AF",
        "MAF",
        "POP_MAF",
        "IMP_QUAL",
        "N"
    ] + sumStatsUseCols[8:len(sumStatsUseCols)]

# Set variables depending on type of info file
if args.file_in_info_format == "info":
    # Define Xref for renaming info columns
    infoColXref = {
        "SNP": 'VARIANT_ID',
        "ALT_Frq": 'ALT_AF',
        "MAF": 'MAF',
        "Rsq": 'IMP_QUAL',
        "Genotyped": 'SOURCE',
        "REF(0)": "REF",
        "ALT(1)": "ALT"
    }
    # Define columns to keep
    infoColKeep = [
        'VARIANT_ID',
        'ALT_AF',
        'MAF',
        'IMP_QUAL',
        'SOURCE'
    ]
    # Create iterator for info file
    info = pd.read_csv(
        args.file_in_info,
        sep = "\t",
        usecols = infoColXref.keys(),
        dtype = {"Genotyped": "category"},
        na_values = {"-"},
        iterator = True
    )
elif args.file_in_info_format == "mfi":
    # Define Xref for renaming info columns
    infoColXref = {
        "ID": 'VARIANT_ID',
        "CHR": 'CHR',
        "POS": 'POS',
        "MAF": 'MAF',
        "INFO": 'IMP_QUAL',
        "A1": "REF",
        "A2": "ALT"
    }
    # Define columns to keep
    infoColKeep = [
        'VARIANT_ID',
        'MAF',
        'IMP_QUAL'
    ]
    # Create iterator for info file
    info = pd.read_csv(
        args.file_in_info,
        sep = "\t",
        usecols = infoColXref.keys(),
        iterator = True
    )

# Read first chunk of info file
infoChunkCount = 1
print("Reading info chunk {0}...".format(infoChunkCount))
prevInfoChunk = readInfoChunk(info, args.chunk_size, infoColXref, args.file_in_info_format)
dfInfo = pd.DataFrame(columns=prevInfoChunk.columns)
infoChunkCount += 1

# Read summary stats file
firstChunk = True
for sumStats in pd.read_table(
    args.file_in_summary_stats,
    usecols = sumStatsUseCols, \
    dtype = dtype, \
    comment = "#", \
    chunksize = args.chunk_size
):

    log.write("Read " + str(sumStats.shape[0]) + " lines from " + args.file_in_summary_stats + "\n")

    # Rename sum stats columns
    sumStats.rename(
        columns = sumStatsColXref,
        inplace = True
    )

    # Remove "chr" and "0" from start of CHR if there
    sumStats.CHR = sumStats.CHR.astype(str).replace({'chr':''}, regex=True)
    sumStats.CHR = sumStats.CHR.astype(str).replace({'^0':''}, regex=True)

    # Create VARIANT_ID field
    if args.file_in_summary_stats_format == "genesis":
        sumStats['VARIANT_ID'] = sumStats['CHR'].astype(str) + ':' + sumStats['POS'].astype(str) + ':' + \
            sumStats['ALT'].astype(str) + ':' + sumStats['REF'].astype(str)
    else:
        sumStats['VARIANT_ID'] = sumStats['CHR'].astype(str) + ':' + sumStats['POS'].astype(str) + ':' + \
            sumStats['REF'].astype(str) + ':' + sumStats['ALT'].astype(str)

    # Add SE to rvtests summary stats
    if args.file_in_summary_stats_format == "rvtests":
        sumStats['SE'] = 1 / sumStats['SQRT_V_STAT']

    # Remove duplicates
    sumStats.drop_duplicates(subset = "VARIANT_ID", keep = "first", inplace = True)
    log.write(str(sumStats.shape[0]) + " remain after duplicates removal\n")

    # Read relevant chunks of ref
    maxSumStatsPos = sumStats.POS.max()
    dfInfo = dfInfo.append(prevInfoChunk)
    maxInfoPos = dfInfo.POS.max()
    while (maxInfoPos <= maxSumStatsPos) and len(prevInfoChunk.index):
        try:
            print("Reading info chunk {0}...".format(infoChunkCount))
            prevInfoChunk = readInfoChunk(info, args.chunk_size, infoColXref, args.file_in_info_format)
            if len(prevInfoChunk.index):
                dfInfo = dfInfo.append(prevInfoChunk)
            maxInfoPos = dfInfo.POS.max()
            dfInfo = dfInfo[dfInfo.VARIANT_ID.isin(sumStats.VARIANT_ID)]
            infoChunkCount += 1
        except:
            break

    # Filter out unneeded info columns
    dfInfo = dfInfo[infoColKeep]

    # Merge info into summary stats
    sumStats = pd.merge(
        left = sumStats,
        right = dfInfo,
        how = 'left',
        left_on = 'VARIANT_ID',
        right_on = 'VARIANT_ID'
    )

    # Merge population MAFs into summary stats
    if includePopMAFs:
        sumStats = pd.merge(
            left = sumStats,
            right = popMAFs,
            how = 'left',
            left_on = 'VARIANT_ID',
            right_on = 'VARIANT_ID'
        )
    else:
        sumStats['POP_MAF'] = np.nan
        
    # Write summary stats to output file
    if firstChunk:
        mode = 'w'
        header = True
        firstChunk = False
    else:
        mode = 'a'
        header = False
    sumStats.to_csv(
        args.file_out_prefix + ".tsv.gz",
        columns = outputColumns,
        index = False,
        compression='gzip',
        sep = '\t',
        na_rep = 'NA',
        mode = mode,
        header = header,
        float_format='%g'
    )
    log.write("Wrote " + str(sumStats.shape[0]) + " lines to " + args.file_out_prefix + ".tsv.gz\n")
    log.flush()

    # Reset dfInfo
    dfInfo = pd.DataFrame(columns=prevInfoChunk.columns)


log.close()
